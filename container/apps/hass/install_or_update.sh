#!/bin/bash
# log function (will just highlight the output in blue) 
log () {
   blue=$(tput setaf 4)
   normal=$(tput sgr0)
   text="$1"
   printf "${blue}${text}${normal}\n"
}

SCRIPTDIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &> /dev/null && pwd)
CONDIR=$(realpath "$SCRIPTDIR/../..")

# check if first installation
HASS_CONF_FIRST_INSTALL=1
if podman volume inspect hass-hassconf &>/dev/null; then
    HASS_CONF_FIRST_INSTALL=0
fi

if [ ! -f "$CONDIR/envfiles/hass.env" ]; then
    cp "$CONDIR"/envfiles/example.hass.env "$CONDIR"/envfiles/hass.env
fi
cp "$CONDIR"/envfiles/hass.env "$HOME"/.podman_home_server/hass.env
. "$HOME"/.podman_home_server/hass.env
. "$HOME"/.podman_home_server/proxy.env

log "## stop home-assistant (if running)"
systemctl --user stop hass &> /dev/null
systemctl --user stop esphome &> /dev/null
sleep 5
# podman image rm home-assistant:stable &> /dev/null
# sleep 3

log "## install home-assistant quadlets"
mkdir -p ~/.config/containers/systemd/hass
rm ~/.config/containers/systemd/hass/*
cp "$CONDIR"/apps/hass/quadlet/* ~/.config/containers/systemd/hass/
for file in ~/.config/containers/systemd/hass/*; do
    if [ -f "$file" ]; then
        sed -i "s|\$HOME|$HOME|g" "$file"
    fi
done
systemctl --user daemon-reload

log "## start esphome"
systemctl --user start esphome

log "## start home-assistant"
systemctl --user start hass

log "## waiting until home-assistant has started..."
elapsed_time=0
container_running=false
CONTAINER_NAME=hass-hass

while [ $elapsed_time -lt 120 ]; do
    # Check if the container is running
    if podman ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
        echo "Container '$CONTAINER_NAME' is running."
        container_running=true
        break
    fi

    # Wait for the interval
    sleep 3
    elapsed_time=$((elapsed_time + 3))
done

if [ "$container_running" = false ]; then
    echo "Error: Home-Assistant container did not start in 120 seconds." >&2
    exit 1
fi

log "## configure home-assistant"
sleep 60
podman exec -it hass-hass bash -c 'grep -qF "http:" /config/configuration.yaml || echo "http:" >> /config/configuration.yaml'
podman exec -it hass-hass bash -c 'grep -qF "  use_x_forwarded_for: true" /config/configuration.yaml || echo "  use_x_forwarded_for: true" >> /config/configuration.yaml'
podman exec -it hass-hass bash -c 'grep -qF "  trusted_proxies: 10.0.1.0" /config/configuration.yaml || echo "  trusted_proxies: 10.0.1.0" >> /config/configuration.yaml'
podman exec -it hass-hass test -f /config/.storage/lovelace.dashboard_esphome
if [ $? -eq 1 ]; then
    podman exec -it hass-hass mkdir -p /config/.storage
    podman cp "$SCRIPTDIR/lovelace.dashboard_esphome" hass-hass:/config/.storage/lovelace.dashboard_esphome
    podman exec -it hass-hass sed -i "s|\$HOSTNAME|$HOSTNAME|g" "/config/.storage/lovelace.dashboard_esphome"
    podman cp "$SCRIPTDIR/lovelace.dashboard_hass-conf" hass-hass:/config/.storage/lovelace.dashboard_hass-conf
    podman exec -it hass-hass sed -i "s|\$HOSTNAME|$HOSTNAME|g" "/config/.storage/lovelace.dashboard_hass-conf"
    podman cp "$SCRIPTDIR/lovelace.dashboard_nextcloud" hass-hass:/config/.storage/lovelace.dashboard_nextcloud
    podman exec -it hass-hass sed -i "s|\$HOSTNAME|$HOSTNAME|g" "/config/.storage/lovelace.dashboard_nextcloud"
    podman cp "$SCRIPTDIR/lovelace.dashboard_nodered" hass-hass:/config/.storage/lovelace.dashboard_nodered
    podman exec -it hass-hass sed -i "s|\$HOSTNAME|$HOSTNAME|g" "/config/.storage/lovelace.dashboard_nodered"
    podman cp "$SCRIPTDIR/lovelace.dashboard_nodered-ui" hass-hass:/config/.storage/lovelace.dashboard_nodered-ui
    podman exec -it hass-hass sed -i "s|\$HOSTNAME|$HOSTNAME|g" "/config/.storage/lovelace.dashboard_nodered-ui"
    podman cp "$SCRIPTDIR/lovelace.map" hass-hass:/config/.storage/lovelace.map
    podman exec -it hass-hass cp /config/.storage/lovelace_dashboards /config/.storage/lovelace_dashboards.bak &> /dev/null
    podman cp "$SCRIPTDIR/lovelace_dashboards" hass-hass:/config/.storage/lovelace_dashboards
fi

### hass-conf ###
if [ "$HASS_CONF_FIRST_INSTALL" == "1" ]; then
    log "## configure hass-conf on new installation"
    podman cp "$SCRIPT_DIR"/hass-conf_settings.conf hass-conf:/config/settings.conf
fi
### hass-conf ###

log "## restart hass && hass-conf"
systemctl --user restart hass
systemctl --user restart hass-conf

### mosquitto ###
log "## check if mosquitto is running"
CONTAINER_NAME=hass-mosquitto
if ! podman ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Error: Mosquitto container failed to start." >&2
    exit 1
fi

log "## create mosquitto password on new installation"
podman exec -it hass-mosquitto test -f /mosquitto/config/password.txt #check if password was already created
if [ $? -eq 1 ]; then
    podman cp "$SCRIPTDIR/mosquitto.conf" hass-mosquitto:/mosquitto/config/mosquitto.conf
    podman exec -it hass-mosquitto ash -c "yes '$MOSQUITTO_PASSWORD' | mosquitto_passwd -c /mosquitto/config/password.txt $MOSQUITTO_USERNAME"
    podman exec -it hass-mosquitto sed -i 's:#allow_anonymous:allow_anonymous false:g' /mosquitto/config/mosquitto.conf
    podman exec -it hass-mosquitto sed -i 's:#password_file:password_file /mosquitto/config/password.txt:g' /mosquitto/config/mosquitto.conf
    podman restart hass-mosquitto
fi
### mosquitto ###
