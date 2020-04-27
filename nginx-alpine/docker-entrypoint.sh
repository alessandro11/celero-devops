#!/bin/sh
set -e

parse_servers() {
    # This variable is expected from -e SERVERS=<ip1,ip2...>
    # docker run ... cli
    local servers=$SERVERS

    if [ -z "$servers" ]; then
        cat >&2 <<-'EOERR'
            ********************************************************************************
            ERROR: SERVERS variable has not been defined.

                   use docker run ... -e SERVERS=<ip1,ip2...> ...
            ********************************************************************************
EOERR
        exit 1
    fi

    IFS_BAK=$IFS
    IFS=",\n"

    servers_str=""
    for server in $SERVERS; do
        servers_str="    $servers_str\n    server $server:8080;"
    done
    IFS=$IFS_BAK

    echo $servers_str
}

set_upstream_servers() {
    local servers=$1

    sed -i "/^[ ,\t]*# SERVERS/a \ $servers" /etc/nginx/conf.d/blog.conf
}

set_server_name() {
    # This variable is expected from -e SERVER_NAME=<your_server_name>
    # docker run ... cli
    local server_name=$SERVER_NAME

    if [ -z "$server_name" ]; then
        cat >&2 <<-'EOERR'
            ********************************************************************************
            ERROR: SERVER_NAME variable has not been defined.

                   use docker run ... -e SERVER_NAME=<your_server_name> ...
            ********************************************************************************
EOERR
        exit 1
    fi

    sed -i "/^[ ,\t]*# SERVER_NAME/a \    server_name $server_name;" /etc/nginx/conf.d/blog.conf
}

if [ "$1" = 'runserver' ]; then
    shift
    set_server_name
    servers=`parse_servers`
    set_upstream_servers "$servers"

    exec nginx -g "daemon off;" "$@"
fi

exec "$@"
