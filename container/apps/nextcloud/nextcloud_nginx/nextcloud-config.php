<?php
$CONFIG = array (
  'datadirectory' => '/nextcloud/data',
  'trusted_proxies'   => ['127.0.0.1','10.0.1.0'],
  #overwrite#'overwritehost'     => 'localhost',
  #overwrite#'overwrite.cli.url' => 'https://localhost/nextcloud',
  #overwrite#'overwriteprotocol' => 'https',
  #overwrite#'overwritewebroot'  => '/nextcloud',
  'apps_paths' => [
    [
      'path'=> '/nextcloud/web/apps',
      'url' => '/apps',
      'writable' => true,
    ],
  ],
  'updatechecker' => true,
  'check_for_working_htaccess' => false,

  'installed' => false,
  'default_phone_region' => 'DE',
  'default_language' => 'de',
  'default_locale' => 'de_DE',

  'memcache.local' => '\OC\Memcache\APCu',
  'memcache.distributed' => '\OC\Memcache\Redis',
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => [
    'host'     => 'nextcloud-redis',
    'port'     => 6379,
    'dbindex'  => 0,
    #overwrite#'password' => 'secret',
    'timeout'  => 1.5,
  ],
  'filelocking.enabled' => 'true',
  'dbhost' => 'nextcloud-postgres:5432',
  #overwrite#'dbname' => 'nextcloud',
  #overwrite#'dbuser' => 'nextcloud',
  #overwrite#'dbpassword' => 'nextcloud',
  'maintenance_window_start' => 1,
);
