FROM docker.io/alpine:3.20
WORKDIR /nextcloud
RUN addgroup nextcloud && adduser -S -G nextcloud nextcloud
RUN apk add --update curl
RUN curl https://download.nextcloud.com/server/releases/latest.tar.bz2 --output /nextcloud/nextcloud.tar.bz2 &&\
    tar -xf /nextcloud/nextcloud.tar.bz2 &&\
    mv /nextcloud/nextcloud /nextcloud/web &&\
    rm /nextcloud/nextcloud.tar.bz2 &&\
    chown -R nextcloud:nextcloud /nextcloud
RUN apk add --update \
    # nginx
    nginx \
    # lftp for backups
    lftp \
    # brotli for nginx
    brotli-libs nghttp2-libs nginx-mod-http-brotli \
    # other libraries (to be honest I don't know the use of them)
    libcurl libxau libbsd libxdmcp libxcb libx11 libxext libice libuuid libsm libxt libxpm libbz2 libpng freetype libjpeg-turbo libwebp oniguruma libzip gmp
COPY . /nextcloud
# nginx
RUN chown -R nextcloud:nextcloud /var/lib/nginx &&\
    chown -R nextcloud:nextcloud /run/nginx &&\
    touch /run/nginx/nginx.pid &&\
    mkdir -p /var/cache/nginx &&\
    chown -R nextcloud:nextcloud /var/cache/nginx &&\
    chown -R nextcloud:nextcloud /run/nginx &&\
    mv nginx.conf /etc/nginx/nginx.conf &&\
    mv mime.types /etc/nginx/mime.types &&\
    mkdir /etc/nginx/ssl &&\
    mv localhost.crt  /etc/nginx/ssl/localhost.crt &&\
    mv localhost.key  /etc/nginx/ssl/localhost.key
# nextcloud
RUN mv /nextcloud/nextcloud-config.php /nextcloud/web/config/config.php &&\
    chown nextcloud:nextcloud /nextcloud/web/config/config.php
# entrypoint
RUN chmod +x entrypoint.sh &&\
    mv entrypoint.sh /usr/local/bin/entrypoint
# log to stdout
RUN mkdir -p /var/log/nginx &&\
    ln -sf /dev/stdout /var/log/nginx/access.log &&\  
    ln -sf /dev/stderr /var/log/nginx/error.log &&\
    chown -R nextcloud:nextcloud /var/log/nginx

USER nextcloud
ENTRYPOINT ["nginx", "-g", "daemon off;"]

# build:
# podman build --tag nextcloud_nginx:latest -f nextcloud_nginx/Dockerfile nextcloud_nginx

# test:
# podman run -it --rm --env-file /container/envfiles/nextcloud.env nextcloud_nginx