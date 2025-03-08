
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
log "## stop nextcloud (if running)"
systemctl --user stop nextcloud &> /dev/null
sleep 5
log "## update nextcloud quadlets"
mkdir -p ~/.config/containers/systemd/nextcloud
rm ~/.config/containers/systemd/nextcloud/*
cp "$CON_DIR"/apps/nextcloud/quadlet/* ~/.config/containers/systemd/nextcloud/
systemctl --user daemon-reload
systemctl --user start nextcloud
sleep 10

update_check () {
   podman exec -it nextcloud-php php82 /nextcloud/web/occ update:check | sed -r 's/\x1B\[[0-9;]*[mK]//g' | tr -d '\r\n'
}

while [ "$(update_check)" != "Everything up to date" ]
do
    $occ maintenance:mode --on
    while [ "$(update_check)" ]
    do
        log "# nextcloud update found - installing update"
        $occ upgrade
        sleep 3
        $ooc db:add-missing-indices
        sleep 3
    done
    $occ maintenance:mode --off
done
