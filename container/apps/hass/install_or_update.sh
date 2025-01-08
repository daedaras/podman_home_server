#!/bin/bash
VOLUME_PATH="/container/volumes"
. /container/envfiles/hass.env

# install quadlets
mkdir -p "~/.config/containers/systemd/hass"
cp /container/apps/hass/quadlet/* ~/.config/containers/systemd/hass/
systemctl --user daemon-reload

# start home-assistant
systemctl --user start hass
sleep 10

# configure home-assistant
podman exec -it hass-hass hass --script auth add $HASS_USERNAME $HASS_PASSWORD --admin
if ! podman exec -it hass-hass grep -qF "mqtt:" /config/configuration.yaml; then
    podman exec -it hass-hass echo "mqtt:" >> /config/configuration.yaml
    podman exec -it hass-hass echo "  broker: \"127.0.0.1\"" >> /config/configuration.yaml
    podman exec -it hass-hass echo "  port: 1883" >> /config/configuration.yaml
    podman exec -it hass-hass echo "  username: \"$MOSQUITTO_USERNAME\"" >> /config/configuration.yaml
    podman exec -it hass-hass echo "  password: \"$MOSQUITTO_PASSWORD\"" >> /config/configuration.yaml
fi
podman exec -it hass-hass bash -c 'grep -qF "http:" /config/configuration.yaml || echo "http:" >> /config/configuration.yaml'
podman exec -it hass-hass bash -c 'grep -qF "  use_x_forwarded_for: true" /config/configuration.yaml || echo "  use_x_forwarded_for: true" >> /config/configuration.yaml'
podman exec -it hass-hass bash -c 'grep -qF "  trusted_proxies: 10.0.1.0" /config/configuration.yaml || echo "  trusted_proxies: 10.0.1.0" >> /config/configuration.yaml'
systemctl --user restart hass-hass

# create mosquitto password on new installation
podman exec -it hass-mosquitto test -f /mosquitto/config/password.txt #check if password was already created
if [ $? -eq 1 ]; then
    podman cp ./mosquitto.conf hass-mosquitto:/mosquitto/config/mosquitto.conf
    podman exec -it hass-mosquitto ash -c "yes '$MOSQUITTO_PASSWORD' | mosquitto_passwd -c /mosquitto/config/password.txt $MOSQUITTO_USERNAME"
    podman exec -it hass-mosquitto sed -i 's:#allow_anonymous:allow_anonymous false:g' /mosquitto/config/mosquitto.conf
    podman exec -it hass-mosquitto sed -i 's:#password_file:password_file /mosquitto/config/password.txt:g' /mosquitto/config/mosquitto.conf
    podman restart hass-mosquitto
fi

# start esphome
systemctl --user start esphome
