
#!/bin/bash
# log function (will just highlight the output in blue) 
log () {
   blue=$(tput setaf 4)
   normal=$(tput sgr0)
   text="$1"
   printf "${blue}${text}${normal}\n"
}

update_check () {
   podman exec -it nextcloud-php php82 /nextcloud/web/occ update:check | sed -r 's/\x1B\[[0-9;]*[mK]//g' | tr -d '\r\n'
}

while [ "$(update_check)" != "Everything up to date" ]
    $occ maintenance:mode --on
    while [ "$(update_check)" ]
    do
        log "# nextcloud update found - installing update"
        $occ upgrade
    done
    $occ maintenance:mode --off
done
