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

set_server_name_80() {
    # This variable is expected from -e SERVER_NAME=<your_server_name>
    # docker run ... cli
    local server_name=$SERVER_NAME_80

    if [ -z "$server_name" ]; then
        cat >&2 <<-'EOERR'
            ********************************************************************************
            ERROR: SERVER_NAME_80 variable has not been defined.

                   use docker run ... -e SERVER_NAME_80=<your_server_name> ...
            ********************************************************************************
EOERR
        exit 1
    fi

    sed -i "/^[ ,\t]*# SERVER_NAME_80/a \    server_name $server_name;" /etc/nginx/conf.d/blog.conf
}

set_server_name_443() {
    # This variable is expected from -e SERVER_NAME=<your_server_name>
    # docker run ... cli
    local server_name=$SERVER_NAME_443

    if [ -z "$server_name" ]; then
        cat >&2 <<-'EOERR'
            ********************************************************************************
            ERROR: SERVER_NAME_443 variable has not been defined.

                   use docker run ... -e SERVER_NAME_443=<your_server_name> ...
            ********************************************************************************
EOERR
    else
        sed -i "/^[ ,\t]*# SERVER_NAME_443/a \    server_name $server_name;" /etc/nginx/conf.d/blog.conf
    fi

}

update_dns() {
    local external_ip=$SERVER_EXTERNAL_IP
    local token='03dd6332-ff49-4ed6-8771-0f96a8ed87c7'

    if [ -z "$external_ip" ]; then
        cat >&2 <<-'EOWARN'
            ********************************************************************************
            ERROR: No external ip has been defined

                   use docker run ... -e SERVER_EXTERNAL_IP=<your_server_ip> ...
            ********************************************************************************
EOWARN
    else
        wget -O- "https://www.duckdns.org/update?domains=blog-celero&token=$token&ip=$external_ip&verbose=true"
    fi

}


if [ "$1" = 'runserver' ]; then
    shift
    set_server_name_80
    set_server_name_443
    update_dns
    servers=`parse_servers`
    set_upstream_servers "$servers"

    exec nginx -g "daemon off;" "$@"
fi

exec "$@"
