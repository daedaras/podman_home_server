FROM docker.io/alpine:3.20
RUN addgroup redis && adduser -S -G redis redis
RUN apk add --update redis
WORKDIR /etc/redis
COPY . .
RUN mkdir -p /run/redis &&\
    touch /run/redis/redis.pid &&\
    chown -R redis:redis /etc/redis &&\
    chown -R redis:redis /run/redis &&\
    # entrypoint
    chmod +x entrypoint.sh &&\
    mv entrypoint.sh /usr/local/bin/entrypoint

USER redis

ENTRYPOINT ["entrypoint"]

# build:
# podman build --tag nextcloud_redis:latest -f nextcloud_redis/Dockerfile nextcloud_redis

# test:
# podman run -it --rm --env-file /container/envfiles/nextcloud.env nextcloud_redis

