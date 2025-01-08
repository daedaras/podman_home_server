FROM docker.io/alpine:3.20
RUN apk add --update postgresql postgresql-client
RUN mkdir -p /postgres/data &&\
    rm -r /postgres/data &&\
    mkdir -p /postgres/data &&\
    chmod 0700 /postgres/data &&\
    mkdir -p /run/postgresql &&\
    chown -R postgres:postgres /postgres &&\
    chown -R postgres:postgres /run/postgresql
COPY entrypoint.sh .
RUN chmod +x entrypoint.sh &&\
    mv entrypoint.sh /usr/local/bin/entrypoint
USER postgres
RUN initdb -D /postgres/data &&\
    echo "host all  all    0.0.0.0/0  md5" >> /postgres/data/pg_hba.conf &&\
    echo "listen_addresses='0.0.0.0'" >> /postgres/data/postgresql.conf
WORKDIR /postgres
ENTRYPOINT ["entrypoint"]

# build:
# podman build --tag nextcloud_postgres:latest -f nextcloud_postgres/Dockerfile nextcloud_postgres

# test:
# podman run -it --rm --env-file /container/envfiles/nextcloud.env nextcloud_postgres
