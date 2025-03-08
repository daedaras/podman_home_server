
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

log "## stop nextcloud (if running)"
systemctl --user stop nextcloud &> /dev/null
sleep 5

log "## update nextcloud quadlets && restart nextcloud"
mkdir -p ~/.config/containers/systemd/nextcloud
rm -rf ~/.config/containers/systemd/nextcloud
mkdir -p ~/.config/containers/systemd/nextcloud
cp "$CONDIR"/apps/nextcloud/quadlet/* ~/.config/containers/systemd/nextcloud/
for file in ~/.config/containers/systemd/nextcloud/*; do
    if [ -f "$file" ]; then
        sed -i "s|\$HOME|$HOME|g" "$file"
        sed -i "s|\$CONDIR|$CONDIR|g" "$file"
    fi
done
systemctl --user daemon-reload
systemctl --user start nextcloud
sleep 10

log "## install updates if available"
occ="podman exec -it nextcloud-php php82 /nextcloud/web/occ"
upgrade () {
   $occ upgrade | sed -r 's/\x1B\[[0-9;]*[mK]//g' | tr -d '\r\n'
}
$occ maintenance:mode --on
runs=0
result=""
while [ "$result" != "Nextcloud is already latest version" ] && [ $runs -lt 6 ]; do
    result="$(upgrade)"
    runs=$((runs + 1))
    sleep 10
done
$occ db:add-missing-indices
sleep 20
$occ maintenance:mode --off
