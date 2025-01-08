#!/bin/bash

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

# log "# install podman-quadlet-create help script"
# sudo cp podman-quadlet-create.sh /usr/local/bin/podman-quadlet-create

log "# Copy files"
if [ ! -d "/container" ]; then
    sudo cp -r ./container /container
    sudo chown -R 1000:1000 /container
fi

log "# Link volumes"
ln -s ~/.local/share/containers/storage/volumes /container/volumes

log "# configure nginx proxy"
. /container/envfiles/proxy.env
sudo systemctl stop nginx &> /dev/null
if [ ! -f "/etc/nginx/nginx.conf.bak" ]; then
    sudo mv /etc/nginx/nginx.conf /etc/nginx/nginx.conf.bak
fi
sudo cp -rf ./nginx/* /etc/nginx/
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
sudo sed -i 's:#ssl_certificate     /etc/nginx/ssl/localhost.crt;:ssl_certificate     /etc/nginx/ssl/$HOSTNAME.crt;:g' /etc/nginx/nginx.conf
sudo sed -i 's:#ssl_certificate_key /etc/nginx/ssl/localhost.key;:ssl_certificate_key /etc/nginx/ssl/$HOSTNAME.key;:g' /etc/nginx/nginx.conf

log "# install & start home-assistant"
cd /container/apps/hass && ./install_or_update.sh

log "# install & start nextcloud"
cd /container/apps/nextcloud && ./install_or_update.sh

log "# install & start node-red"
/container/apps/nodered/install_or_update.sh

log "# start nginx proxy"
sudo systemctl start nginx
