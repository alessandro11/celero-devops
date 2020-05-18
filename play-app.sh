#!/bin/bash -e

#
# By default this script just build those images
#

# by default run images, unless explicit deny
RUN=0
# by default build images, unless user deny
BUILD=0
PUSH=0

PROJECT_ID="env-test-0002"
IMG_POSTGRES="gcr.io/$PROJECT_ID/postgres-12.2-alpine-3.11"
TAG_POSTGRES="blog-0.0.10"
IMG_APP="gcr.io/$PROJECT_ID/ubuntu-18.04.4-lts"
TAG_APP="blog-0.0.10"
IMG_NGINX="gcr.io/$PROJECT_ID/ngix-alpine-3.11"
TAG_NGINX="blog-0.0.10"


perror() {
    echo -e "$@" >&2
}

help() {
    cat <<-EOINFO
Usage: ./$(basename $0) [-a|-b|-p|-r|-h]
    Build and run docker images do deploy the application
    Blog-API-with-Django-Rest-Framework.
    The following images will be build and or run:
    - PostgreSQL
    - Blog-API-with-Django-Rest-Framework.
    - Nginx

    [-a] - build and run images
    [-b] - just build images
    [-p] - push the images built
    [-r] - just run images
    [-h] - this help

    If no parameters has been assigned, -a is implied.
    If you wish to change the name and tag of those images:
        - $IMG_POSTGRES:$TAG_POSTGRES
        - $IMG_APP:$TAG_APP
        - $IMG_NGINX:$TAG_NGINX

    Edit those varriables:
    PROJECT_ID, IMG_POSTGRES, TAG_POSTGRES, IMG_APP, TAG_APP, IMG_NGINX, TAG_NGINX
EOINFO
}

build() {
    if [ -d "postgres-alpine/" ]; then
        pushd "postgres-alpine"
        docker build . -t "$IMG_POSTGRES:$TAG_POSTGRES"
        popd
    else
        perror "Dir 'postgres-alpine/' could not be found at $(pwd)"
        exit 1
    fi

    if [ -d "django-app-ubuntu/" ]; then
        pushd "django-app-ubuntu"
        docker build . -t "$IMG_APP:$TAG_APP"
        popd
    else
        perror "Dir 'django-app-ubuntu/' could not be found at $(pwd)"
        exit 1
    fi

    if [ -d "nginx-alpine/" ]; then
        pushd nginx-alpine
        docker build . -t "$IMG_NGINX:$TAG_NGINX"
        popd
    else
        perror "Dir 'nginx-alpine/' could not be found at $(pwd)"
        exit 1
    fi
}


get_container_ip() {
    local container_name=$1

    ip=$(docker ps -q | xargs -n 1 docker inspect --format \
        '{{ .Name }} {{range .NetworkSettings.Networks}} {{.IPAddress}}{{end}}'\
        | grep $container_name | awk '{print $2}')

    echo $ip
}

#
# Since we are guessing that docker will assign the
# subsequent ip address, check if that is in fact.
#
ips_sanity_check() {
    local container_name=$1 ip_guessed=$2

    ip_assigned=$(docker inspect --format \
         '{{ .Name }} {{range .NetworkSettings.Networks}} {{.IPAddress}}{{end}}' \
         "$container_name" | awk '{print $2}')

    if [ "$ip_assigned" != "$ip_guessed" ]; then
        cat >&2 <<-EOWARN
            *********************************************************
            WARNING:
                IP guessed ($ip_guessed) differ from IP assinged for
                $container_name ($ip_assigned)!

                The web server may not work correctly.
            *********************************************************
EOWARN
        return 1
    fi

    return 0
}

run() {
    #
    # This parameter is passed by reference, the
    # web server ip guessed is returned to the caller
    #
    # docker echo many chars to stdout, we want to avoid
    # using echo "$nginx_ip" as return, since it could messed up
    #
    local -n nginx_ip=$1
    local db_server_ip="" blog1_ip="" blog2_ip="" host=""

    echo
    docker run --rm -d --name postgres -e BLOG_PASSWORD=mypasswd \
                -e POSTGRES_PASSWORD_FILE=/var/lib/postgresql/.postgres_pass \
                "$IMG_POSTGRES:$TAG_POSTGRES"
    [ $? -ne 0 ] && exit 1

    # wait for postgres to be up.
    # TODO: this is a race condition, it may failed
    #       improve the way to wait for port 5432, perhaps psql
    #
    echo "Waiting for postgres..."
    sleep 3
    db_server_ip=$(get_container_ip postgres)
    docker run --rm -d --name blog1 -e DB_PASSWD=mypasswd -e "DB_SERVER=$db_server_ip" \
                "$IMG_APP:$TAG_APP"
    [ $? -ne 0 ] && exit 1
    docker run --rm -d --name blog2 -e DB_PASSWD=mypasswd -e "DB_SERVER=$db_server_ip" \
                "$IMG_APP:$TAG_APP"
    [ $? -ne 0 ] && exit 1

    blog1_ip=$(get_container_ip blog1)
    blog2_ip=$(get_container_ip blog2)

    host=$(awk -F'.' '{print $4}' <<<"$blog2_ip")
    host=$(($host+1))
    #
    # This assignment is by reference
    # return to the caller the ip guessed
    nginx_ip="$(grep -Eo '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' <<<$blog2_ip).${host}"
    docker run --rm -d --name nginx -e SERVER_NAME="$nginx_ip" -e SERVERS="$blog1_ip,$blog2_ip" \
                "$IMG_NGINX:$TAG_NGINX"
    [ $? -ne 0 ] && exit 1
    # little trick to get back the stout, the container
    # redirect it and some messages could be lost
    set -x; set +x
}

push() {
    docker push "$IMG_POSTGRES:$TAG_POSTGRES"
    docker push "$IMG_APP:$TAG_APP"
    docker push "$IMG_NGINX:$TAG_NGINX"
}

while getopts ":abrph" opt; do
    case $opt in
        a)
            RUN=0
            BUILD=0
            ;;

        b)
            RUN=1
            BUILD=0
            ;;

        r)
            RUN=0
            BUILD=1
            ;;
        p)
            RUN=1
            BUILD=1
            PUSH=0
            ;;

        h)
            help
            exit 0
        ;;
        \?)
            echo "Invalid option -$OPTARG" >&2
            exit 1
    esac
done

#
# If no parameters has been passed, interact with user
#
if [ $# -eq 0 ]; then
    help
    echo -n "Continue to build and run (y|N)? "
    wrong_answer=0
    while [ $wrong_answer -eq 0 ]; do
        read answer
        case $answer in
            n|N|NO|"")
                exit 1
                ;;

            y|Yes|YES)
                wrong_answer=1
                ;;

            *)
                echo "Answer not reconized! correct answers: n, N, NO"
                ;;
        esac
    done
fi


#
# If user request; build docker images
#
[ $BUILD -eq 0 ] && build
#
# If user request; push those images
[ $PUSH -eq 0 ] && push

#
# Run all images built, if user requested
#
if [ $RUN -eq 0 ]; then
    webserver_ip=""
    #
    # webserver_ip is passed by reference
    # the webserver ip will be returned.
    #
    run webserver_ip
    if ips_sanity_check "nginx" "$webserver_ip"; then
        cat <<-EOINFO
           [INFO] - Application Blog-API-with-Django-Rest-Framework
                    running.
           visit the link http://$webserver_ip
EOINFO
    fi
fi

exit 0
