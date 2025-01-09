#!/bin/bash
# log function (will just highlight the output in blue) 
log () {
   blue=$(tput setaf 4)
   normal=$(tput sgr0)
   text="$1"
   printf "${blue}${text}${normal}\n"
}

log "## stop nodered (if running)"
systemctl --user stop nodered &> /dev/null
sleep 5

log "## install nodered quadlets"
mkdir -p ~/.config/containers/systemd/nodered
cp /container/apps/nodered/quadlet/* ~/.config/containers/systemd/nodered/
systemctl --user daemon-reload
systemctl --user start nodered

log "## configure nodered"
podman exec -it nodered ash -c "cd /data && npm install node-red-contrib-knx-ultimate"
podman exec -it nodered ash -c "cd /data && npm install node-red-dashboard"
podman exec -it nodered ash -c "cd /data && npm install node-red-contrib-cron-plus"
podman exec -it nodered sed -i "/\/\/httpAdminRoot/c\    httpAdminRoot: '/nodered/'," /data/settings.js
podman exec -it nodered sed -i "/\/\/httpNodeRoot/c\    httpNodeRoot: '/nodered/'," /data/settings.js
podman exec -it nodered sed -i "/\/\/httpStaticRoot/c\    httpStaticRoot: '/nodered/'," /data/settings.js
systemctl --user restart nodered
