#!/bin/bash

# prevent execution as root
if [ $(/usr/bin/id -u) -eq 0 ]; then
    echo "The script should not be run as root"
    exit
fi

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")

# log function (will just highlight the output in blue) 
log () {
   blue=$(tput setaf 4)
   normal=$(tput sgr0)
   text="$1"
   printf "${blue}${text}${normal}\n"
}

log "# stop nginx proxy"
sudo systemctl stop nginx

log "# install or update node-red"
"$SCRIPT_DIR"/container/apps/nodered/install_or_update.sh

log "# install or update home-assistant"
"$SCRIPT_DIR"/container/apps/hass/install_or_update.sh

log "# install or update nextcloud"
"$SCRIPT_DIR"/container/apps/nextcloud/update.sh

log "# start nginx proxy"
sudo systemctl start nginx
