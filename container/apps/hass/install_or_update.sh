#!/bin/bash
# log function (will just highlight the output in blue) 
log () {
   blue=$(tput setaf 4)
   normal=$(tput sgr0)
   text="$1"
   printf "${blue}${text}${normal}\n"
}

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
CON_DIR="$SCRIPT_DIR/../.."
if [ ! -f "$CON_DIR/envfiles/hass.env" ]; then
    cp "$CON_DIR"/envfiles/example.hass.env "$CON_DIR"/envfiles/hass.env
fi
cp "$CON_DIR"/envfiles/hass.env "$HOME"/.podman_home_server/hass.env
. "$HOME"/.podman_home_server/hass.env

log "## stop home-assistant (if running)"
systemctl --user stop hass &> /dev/null
systemctl --user stop esphome &> /dev/null
sleep 5
# podman image rm home-assistant:stable &> /dev/null
# sleep 3

log "## install home-assistant quadlets"
mkdir -p ~/.config/containers/systemd/hass
rm ~/.config/containers/systemd/hass/*
cp "$CON_DIR"/apps/hass/quadlet/* ~/.config/containers/systemd/hass/
for file in "$CON_DIR"/apps/hass/quadlet/*; do
    # Check if it is a regular file
    if [ -f "$file" ]; then
        # Use sed to replace literal '$HOME' with the value of the $HOME variable
        sed -i "s|\$HOME|$HOME|g" "$file"
    fi
done
systemctl --user daemon-reload

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
systemctl --user restart hass-hass

log "## check if mosquitto is running"
CONTAINER_NAME=hass-mosquitto
if ! podman ps --filter "name=$CONTAINER_NAME" --filter "status=running" --format "{{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
    echo "Error: Mosquitto container failed to start." >&2
    exit 1
fi

log "## create mosquitto password on new installation"
podman exec -it hass-mosquitto test -f /mosquitto/config/password.txt #check if password was already created
if [ $? -eq 1 ]; then
    podman cp "$SCRIPT_DIR/mosquitto.conf" hass-mosquitto:/mosquitto/config/mosquitto.conf
    podman exec -it hass-mosquitto ash -c "yes '$MOSQUITTO_PASSWORD' | mosquitto_passwd -c /mosquitto/config/password.txt $MOSQUITTO_USERNAME"
    podman exec -it hass-mosquitto sed -i 's:#allow_anonymous:allow_anonymous false:g' /mosquitto/config/mosquitto.conf
    podman exec -it hass-mosquitto sed -i 's:#password_file:password_file /mosquitto/config/password.txt:g' /mosquitto/config/mosquitto.conf
    podman restart hass-mosquitto
fi

log "## start esphome"
systemctl --user start esphome
