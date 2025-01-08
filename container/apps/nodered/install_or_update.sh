#!/bin/bash
# ## test
# systemctl --user stop nodered
# podman volume rm nodered-data
# podman-quadlet-create /tmp/usb/podman_install/container/apps/nodered
# podman cp /tmp/usb/podman_install/container/apps/nodered/flows.json nodered:/data/
# systemctl --user start nodered
# ## test

# install quadlets
mkdir -p "~/.config/containers/systemd/nodered"
cp /container/apps/nodered/quadlet/* ~/.config/containers/systemd/nodered/
systemctl --user daemon-reload
systemctl --user start nodered

podman exec -it nodered ash -c "cd /data && npm install node-red-contrib-knx-ultimate"
podman exec -it nodered ash -c "cd /data && npm install node-red-dashboard"
podman exec -it nodered ash -c "cd /data && npm install node-red-contrib-cron-plus"
podman exec -it nodered sed -i "/\/\/httpAdminRoot/c\    httpAdminRoot: '/nodered/'," /data/settings.js
podman exec -it nodered sed -i "/\/\/httpNodeRoot/c\    httpNodeRoot: '/nodered/'," /data/settings.js
podman exec -it nodered sed -i "/\/\/httpStaticRoot/c\    httpStaticRoot: '/nodered/'," /data/settings.js
systemctl --user restart nodered
