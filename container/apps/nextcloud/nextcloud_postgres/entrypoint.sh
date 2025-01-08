#!/bin/ash

#ensure correct access rights
chmod 0700 /postgres/data

export PGDATA="/postgres/data"
POSTGRES_DB=${POSTGRES_DB:-"data"}
POSTGRES_USER=${POSTGRES_USER:-"postgres"}
POSTGRES_PASSWORD=${POSTGRES_PASSWORD:-"postgres"}

if ! $(psql -lqt | cut -d \| -f 1 | grep -qw $POSTGRES_DB) ; then
    echo ""
    echo "### INITIALIZING POSTGRES ###"

    echo "POSTGRES_DB=$POSTGRES_DB"
    echo "POSTGRES_USER=$POSTGRES_USER"

    # initialize postgres
    pg_ctl start
    if [ "$POSTGRES_USER" = "postgres" ]; then
        echo "ALTER USER postgres WITH PASSWORD '\$POSTGRES_PASSWORD'"
        psql -d postgres -c "ALTER USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD'"
    else
        echo "CREATE USER \$POSTGRES_USER WITH PASSWORD '\$POSTGRES_PASSWORD'"
        psql -d postgres -c "CREATE USER $POSTGRES_USER WITH PASSWORD '$POSTGRES_PASSWORD'"
    fi
    echo "CREATE DATABASE \$POSTGRES_DB WITH OWNER \$POSTGRES_USER"
    psql -d postgres -c "CREATE DATABASE $POSTGRES_DB WITH OWNER $POSTGRES_USER"
    pg_ctl stop
    
    echo "### INITIALIZATION DONE ###"
    echo ""
fi

#exec postgres -c log_statement=all -c log_destination=stderr
exec postgres -c log_destination=stderr
