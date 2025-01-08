#!/bin/bash
VOLUME_PATH="/container/volumes"
. /container/envfiles/hass.env

# initialize influxdb on new installation
if [ ! -d $VOLUME_PATH/_data/influxdb-config ]; then 
    podman run -d \
        --volume hass-influxdb-config:/etc/influxdb2\
        --volume hass-influxdb-data:/var/lib/influxdb2 \
        -p 8086:8086 \
        --name influxdb-init \
        --rm \
        -e DOCKER_INFLUXDB_INIT_MODE=setup \
        -e DOCKER_INFLUXDB_INIT_USERNAME=$INFLUXDB_USERNAME \
        -e DOCKER_INFLUXDB_INIT_PASSWORD=$INFLUXDB_PASSWORD \
        -e DOCKER_INFLUXDB_INIT_ORG=$INFLUXDB_ORG_NAME \
        -e DOCKER_INFLUXDB_INIT_BUCKET=$INFLUXDB_BUCKET_NAME \
        docker.io/influxdb:2
    sleep 60
    podman stop influxdb-init
fi

# install quadlets
mkdir -p "~/.config/containers/systemd/hass"
cp /container/apps/hass/quadlet/* ~/.config/containers/systemd/hass/
systemctl --user daemon-reload
if
mqtt:
  broker: "BROKER_IP"
  port: 1883
  username: "YOUR_USERNAME"
  password: "YOUR_PASSWORD"
systemctl --user start hass

# configure home-assistant
podman exec -it hass-hass hass --script auth add $HASS_USERNAME $HASS_PASSWORD --admin
if ! podman exec -it hass-hass grep -qF "mqtt:" /config/configuration.yaml; then
    podman exec -it hass-hass echo "mqtt:" >> /config/configuration.yaml
    podman exec -it hass-hass echo "  broker: \"($hostname -i)\"" >> /config/configuration.yaml
    podman exec -it hass-hass echo "  port: 1883" >> /config/configuration.yaml
    podman exec -it hass-hass echo "  username: \"$MOSQUITTO_USERNAME\"" >> /config/configuration.yaml
    podman exec -it hass-hass echo "  password: \"$MOSQUITTO_PASSWORD\"" >> /config/configuration.yaml
fi
podman exec -it hass-hass bash -c 'grep -qF "http:" /config/configuration.yaml || echo "http:" >> /config/configuration.yaml'
podman exec -it hass-hass bash -c 'grep -qF "  use_x_forwarded_for: true" /config/configuration.yaml || echo "  use_x_forwarded_for: true" >> /config/configuration.yaml'
podman exec -it hass-hass bash -c 'grep -qF "  trusted_proxies: 10.0.1.0" /config/configuration.yaml || echo "  trusted_proxies: 10.0.1.0" >> /config/configuration.yaml'
systemctl --user restart hass-hass

# create mosquitto password on new installation
sleep 10
podman exec -it hass-mosquitto test -f /mosquitto/config/password.txt #check if password was already created
if [ $? -eq 1 ]; then
    podman cp ./mosquitto.conf hass-mosquitto:/mosquitto/config/mosquitto.conf
    podman exec -it hass-mosquitto ash -c "yes '$MOSQUITTO_PASSWORD' | mosquitto_passwd -c /mosquitto/config/password.txt $MOSQUITTO_USERNAME"
    podman exec -it hass-mosquitto sed -i 's:#allow_anonymous:allow_anonymous false:g' /mosquitto/config/mosquitto.conf
    podman exec -it hass-mosquitto sed -i 's:#password_file:password_file /mosquitto/config/password.txt:g' /mosquitto/config/mosquitto.conf
    podman restart hass-mosquitto
fi

systemctl --user start esphome
