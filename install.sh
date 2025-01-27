#!/bin/bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# prerequisites: 
# - nginx with brotli support
# - podman

# prevent execution as root
if [ $(/usr/bin/id -u) -eq 0 ]; then
    echo "The script should not be run as root"
    exit
fi

# log function (will just highlight the output in blue) 
log () {
   blue=$(tput setaf 4)
   normal=$(tput sgr0)
   text="$1"
   printf "${blue}${text}${normal}\n"
}

log "# allow podman user containers to run without login"
sudo loginctl enable-linger $(id -u)

log "# Copy files"
USER_ID="$(id -u)"
sudo mkdir -p /container
sudo chown $USER_ID:$USER_ID /container
sudo chown $USER_ID:$USER_ID /container/apps &> /dev/null
sudo chown -R $USER_ID:$USER_ID /container/envfiles &> /dev/null
sudo rm -r /container/apps/nextcloud &> /dev/null
sudo rm -r /container/apps/hass &> /dev/null
sudo rm -r /container/apps/nodered &> /dev/null
cp -r "$SCRIPT_DIR"/container/* /container/

log "# Link volumes"
ln -s ~/.local/share/containers/storage/volumes /container/volumes

log "# configure nginx proxy"
. /container/envfiles/proxy.env
sudo systemctl stop nginx &> /dev/null
if [ ! -f "/etc/nginx/nginx.conf.bak" ]; then
    sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
fi
sudo cp -rf "$SCRIPT_DIR/nginx"/* /etc/nginx/
sudo mkdir -p /var/www/html
sudo mv /etc/nginx/index.html /var/www/html/index.html
sudo mkdir -p /etc/nginx/ssl
if [ ! -f "/etc/nginx/ssl/$HOSTNAME.crt" ]; then
    sudo openssl req -x509 -nodes -days 36500 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/$HOSTNAME.key \
        -out /etc/nginx/ssl/$HOSTNAME.crt \
        -subj "/C=DE/ST=None/L=None/O=None/OU=None/CN=$HOSTNAME" \
        -addext "subjectAltName=DNS:$HOSTNAME"
    sudo chmod 640 /etc/nginx/ssl/$HOSTNAME.key
    sudo chown root:http /etc/nginx/ssl/$HOSTNAME.key
fi
sudo sed -i "s:#ssl_certificate     /etc/nginx/ssl/localhost.crt;:ssl_certificate     /etc/nginx/ssl/$HOSTNAME.crt;:g" /etc/nginx/nginx.conf
sudo sed -i "s:#ssl_certificate_key /etc/nginx/ssl/localhost.key;:ssl_certificate_key /etc/nginx/ssl/$HOSTNAME.key;:g" /etc/nginx/nginx.conf

log "# install & start home-assistant"
/container/apps/hass/install_or_update.sh
# ./container/apps/hass/install_or_update.sh

log "# install & start node-red"
/container/apps/nodered/install_or_update.sh
# ./container/apps/nodered/install_or_update.sh

log "# install & start nextcloud"
/container/apps/nextcloud/install.sh
# ./container/apps/nextcloud/install.sh

log "# start nginx proxy"
sudo systemctl start nginx
