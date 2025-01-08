FROM docker.io/alpine:3.20
RUN apk add --update \
    imagemagick-svg \
    php82 php82-fpm php82-ftp php82-redis php82-apcu php82-opcache php82-pecl-imagick php82-bcmath php82-ctype php82-curl php82-dom php82-gd php82-fileinfo php82-gmp \
    php82-iconv php82-intl php82-json php82-mbstring php82-openssl php82-pcntl php82-posix php82-session php82-simplexml php82-xml php82-xmlreader php82-xmlwriter \
    php82-zip php82-pgsql php82-pdo php82-pdo_pgsql php82-sysvsem php82-exif php82-sodium
RUN addgroup php && adduser -S -G php php
WORKDIR /etc/php82
COPY . .
RUN mv www.conf /etc/php82/php-fpm.d/www.conf &&\
    chown -R php:php /etc/php82 &&\
    chown -R php:php /var/log/php82
USER php
ENTRYPOINT ["php-fpm82","--nodaemonize"]

# build:
# podman build --tag nextcloud_php:latest -f nextcloud_php/Dockerfile nextcloud_php

# test:
# podman run -it --rm --env-file /container/envfiles/nextcloud.env nextcloud_php
