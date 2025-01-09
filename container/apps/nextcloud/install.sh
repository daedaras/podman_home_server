#!/bin/bash
# log function (will just highlight the output in blue) 
log () {
   blue=$(tput setaf 4)
   normal=$(tput sgr0)
   text="$1"
   printf "${blue}${text}${normal}\n"
}

. /container/envfiles/nextcloud.env

log "## stop nextcloud (if running)"
systemctl --user stop nextcloud &> /dev/null
sleep 5

log "## install nextcloud quadlets"
mkdir -p ~/.config/containers/systemd/nextcloud
cp /container/apps/nextcloud/quadlet/* ~/.config/containers/systemd/nextcloud/
systemctl --user daemon-reload
systemctl --user start nextcloud

log "## configure optional settings"
sleep 10
if [ "$COLLABORA_WEBROOT" != "" ]; then
    podman exec -it nextcloud-collabora sed -i "s:this path.\"></service_root>:this path.\">$COLLABORA_WEBROOT</service_root>:g" /etc/coolwsd/coolwsd.xml
fi
if [ "$NEXTCLOUD_WEBROOT" != "" ]; then
    podman exec -it nextcloud-nginx sed -i "/#overwrite#'overwritewebroot'/ c\  'overwritewebroot' => '$NEXTCLOUD_WEBROOT'," /nextcloud/web/config/config.php
    #podman exec -u root -it nextcloud-nginx sed -i "s:/remote.php/dav/:$NEXTCLOUD_WEBROOT/remote.php/dav/:g" /etc/nginx/nginx.conf
    #podman exec -u root -it nextcloud-nginx sed -i "s:/index.php/.well-known/webfinger:$NEXTCLOUD_WEBROOT/index.php/.well-known/webfinger:g" /etc/nginx/nginx.conf
    #podman exec -u root -it nextcloud-nginx sed -i "s:/index.php/.well-known/nodeinfo:$NEXTCLOUD_WEBROOT/index.php/.well-known/nodeinfo:g" /etc/nginx/nginx.conf
    podman exec -it nextcloud-nginx nginx -s reload
fi

log "## configure settings"
podman exec -it nextcloud-nginx sed -i "/#overwrite#'overwriteprotocol'/ c\  'overwriteprotocol' => 'https'," /nextcloud/web/config/config.php
podman exec -it nextcloud-nginx sed -i "/#overwrite#'overwrite.cli.url'/ c\  'overwrite.cli.url' => 'https://$HOSTNAME/nextcloud'," /nextcloud/web/config/config.php
podman exec -it nextcloud-nginx sed -i "/#overwrite#'password'/ c\    'password' => '$REDIS_PASSWORD'," /nextcloud/web/config/config.php
podman exec -it nextcloud-nginx sed -i "/#overwrite#'overwritehost'/ c\  'overwritehost' => '$HOSTNAME'," /nextcloud/web/config/config.php

log "## add alias for occ"
grep -qF "alias occ=" ~/.bashrc || echo "alias occ='podman exec -it nextcloud-php php82 /nextcloud/web/occ'" >> ~/.bashrc
if which fish > /dev/null ; then
    fish -c "alias --save occ='podman exec -it nextcloud-php php82 /nextcloud/web/occ'"
fi

log "## initialize nextcloud"
podman exec -it nextcloud-php php82 /nextcloud/web/occ maintenance:install \
  --database='pgsql' \
  --database-host='nextcloud-postgres' \
  --database-port='5432' \
  --database-name="$POSTGRES_DB" \
  --database-user="$POSTGRES_USER" \
  --database-pass="$POSTGRES_PASSWORD" \
  --admin-user="$NEXTCLOUD_ADMIN_USER" \
  --admin-pass="$NEXTCLOUD_ADMIN_PASSWORD" \
  --data-dir='/nextcloud/data'
occ="podman exec -it nextcloud-php php82 /nextcloud/web/occ"
$occ maintenance:repair --include-expensive
$occ app:install richdocuments
$occ app:install mail
$occ app:install notes
$occ app:install contacts
$occ app:install calendar
$occ app:install spreed
$occ db:add-missing-indices
$occ config:app:set richdocuments wopi_url --value "https://$HOSTNAME$COLLABORA_WEBROOT"
$occ config:app:set richdocuments disable_certificate_verification --value "yes"
$occ config:app:set richdocuments public_wopi_url --value "https://$HOSTNAME"
# $occ config:app:set richdocuments wopi_allowlist --value "$(hostname -i)"
