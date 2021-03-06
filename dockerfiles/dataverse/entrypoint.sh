#!/bin/bash

# Entrypoint script for Dataverse web application. This script waits
# for dependent services (Rserve, Postgres, Solr) to start before
# initializing Glassfish.



set -e

if [ "$1" = 'dataverse' ]; then

    export GLASSFISH_DIRECTORY=/usr/local/glassfish4
    export HOST_DNS_ADDRESS=localhost

    TIMEOUT=30

    if [ -n "$RSERVE_SERVICE_HOST" ]; then
        RSERVE_HOST=$RSERVE_SERVICE_HOST
    elif [ -n "$RSERVE_PORT_6311_TCP_ADDR" ]; then
        RSERVE_HOST=$RSERVE_PORT_6311_TCP_ADDR
    elif [ -z "$RSERVE_HOST" ]; then
        RSERVE_HOST="localhost"
    fi
    export RSERVE_HOST
    
    if [ -n "$RSERVE_SERVICE_PORT" ]; then
        RSERVE_PORT=$RSERVE_SERVICE_PORT
    elif [ -n "$RSERVE_PORT_6311_TCP_PORT" ]; then
        RSERVE_PORT=$RSERVE_PORT_6311_TCP_PORT
    elif [ -z "$RSERVE_PORT" ]; then
        RSERVE_PORT="6311"
    fi
    export RSERVE_PORT

    echo "Using Rserve at $RSERVE_HOST:$RSERVE_PORT"
    
    if ncat $RSERVE_HOST $RSERVE_PORT -w $TIMEOUT --send-only < /dev/null > /dev/null 2>&1 ; then 
        echo Rserve running; 
    else
        echo Optional service Rserve not running. 
    fi
    
    
    # postgres
    if [ -n "$POSTGRES_SERVICE_HOST" ]; then
        POSTGRES_HOST=$POSTGRES_SERVICE_HOST
    elif [ -n "$POSTGRES_PORT_5432_TCP_ADDR" ]; then
        POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    elif [ -z "$POSTGRES_HOST" ]; then
        POSTGRES_HOST="localhost"
    fi
    export POSTGRES_HOST
    
    if [ -n "$POSTGRES_SERVICE_PORT" ]; then
        POSTGRES_PORT=$POSTGRES_SERVICE_PORT
    elif [ -n "$POSTGRES_PORT_5432_TCP_PORT" ]; then
        POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
    else
        POSTGRES_PORT=5432
    fi 
    export POSTGRES_PORT

    echo "Using Postgres at $POSTGRES_HOST:$POSTGRES_PORT"
    
    if ncat $POSTGRES_HOST $POSTGRES_PORT -w $TIMEOUT --send-only < /dev/null > /dev/null 2>&1 ; then 
        echo Postgres running; 
    else
        echo Required service Postgres not running. Have you started the required services?
        exit 1 
    fi
    
    # solr
    if [ -n "$SOLR_SERVICE_HOST" ]; then
        SOLR_HOST=$SOLR_SERVICE_HOST
    elif [ -n "$SOLR_PORT_8983_TCP_ADDR" ]; then
        SOLR_HOST=$SOLR_PORT_8983_TCP_ADDR
    elif [ -z "$SOLR_HOST" ]; then
        SOLR_HOST="localhost"
    fi
    export SOLR_HOST
    
    if [ -n "$SOLR_SERVICE_PORT" ]; then
        SOLR_PORT=$SOLR_SERVICE_PORT
    elif [ -n "$SOLR_PORT_8983_TCP_PORT" ]; then
        SOLR_PORT=$SOLR_PORT_8983_TCP_PORT
    else
        SOLR_PORT=8983
    fi 
    export SOLR_PORT
    
    echo "Using Solr at $SOLR_HOST:$SOLR_PORT"

    if ncat $SOLR_HOST $SOLR_PORT -w $TIMEOUT --send-only < /dev/null > /dev/null 2>&1 ; then 
        echo Solr running; 
    else
        echo Required service Solr not running. Have you started the required services?
        exit 1 
    fi
    
    cd ~/dvinstall
    ./init-dataverse

    if [ -n "$DVICAT_PORT_1247_TCP_PORT" ]; then
        ./setup-irods.sh
    fi

    echo -e "\n\nDataverse started"

    sleep infinity
else
    exec "$@"
fi

