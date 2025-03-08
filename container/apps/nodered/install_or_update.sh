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

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
CON_DIR="$SCRIPT_DIR/../.."

# check if first installation
FIRST_INSTALL=1
if podman volume inspect nodered-data &>/dev/null; then
    FIRST_INSTALL=0
fi

log "## install nodered quadlets"
mkdir -p ~/.config/containers/systemd/nodered
rm ~/.config/containers/systemd/nodered/*
cp "$CON_DIR"/apps/nodered/quadlet/* ~/.config/containers/systemd/nodered/
systemctl --user daemon-reload
systemctl --user start nodered

log "## waiting until nodered has started..."
elapsed_time=0
container_running=false
CONTAINER_NAME=nodered

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
    echo "Error: nodered container did not start in 120 seconds." >&2
    exit 1
fi

log "## configure nodered"
podman exec -it nodered ash -c "cd /data && npm install node-red-contrib-knx-ultimate"
podman exec -it nodered ash -c "cd /data && npm install node-red-dashboard"
podman exec -it nodered ash -c "cd /data && npm install node-red-contrib-cron-plus"
podman exec -it nodered sed -i "/\/\/httpAdminRoot/c\    httpAdminRoot: '/nodered/'," /data/settings.js
podman exec -it nodered sed -i "/\/\/httpNodeRoot/c\    httpNodeRoot: '/nodered/'," /data/settings.js
podman exec -it nodered sed -i "/\/\/httpStaticRoot/c\    httpStaticRoot: '/nodered/'," /data/settings.js
# add template flows
if [ "$FIRST_INSTALL" == "1" ]; then
    log "## first installation: adding simple flow testing"
    podman cp "$SCRIPT_DIR"/flows.json nodered:/data/flows.json
fi
systemctl --user restart nodered 
