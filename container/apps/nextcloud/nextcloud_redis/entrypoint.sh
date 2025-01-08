#!/bin/sh
sed -i "/#requirepass/ c\requirepass $REDIS_PASSWORD" /etc/redis/redis.conf
exec redis-server /etc/redis/redis.conf
