#!/bin/bash -e

#
# By default this script just build those images
#

# by default run images, unless explicit deny
RUN=0
# by default build images, unless user deny
BUILD=0

IMG_POSTGRES="gcr.io/celerodevops/postgres-12.2-alpine-3.11"
TAG_POSTGRES="blog-0.0.10"
IMG_APP="gcr.io/celerodevops/ubuntu-18.04.4-lts"
TAG_APP="blog-0.0.10"
IMG_NGINX="gcr.io/celerodevops/ngix-alpine-3.11"
TAG_NGINX="blog-0.0.10"


perror() {
    echo -e "$@" >&2
}

help() {
    cat <<-EOINFO
Usage: ./$(basename $0) [-a|-b|-r|-h]
    Build and run docker images do deploy the application
    Blog-API-with-Django-Rest-Framework.
    The following images will be build and or run:
    - PostgreSQL
    - Blog-API-with-Django-Rest-Framework.
    - Nginx

    [-a] - build and run images
    [-b] - just build images
    [-r] - just run images
    [-h] - this help

    If no parameters has been assigned, -a is implied.
    If you wish to change the name and tag of those images:
        - $IMG_POSTGRES:$TAG_POSTGRES
        - $IMG_APP:$TAG_APP
        - $IMG_NGINX:$TAG_NGINX

    Edit those varriables:
    IMG_POSTGRES, TAG_POSTGRES, IMG_APP, TAG_APP, IMG_NGINX, TAG_NGINX"
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




while getopts ":abrh" opt; do
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
# If user requeste, build docker images
#
[ $BUILD -eq 0 ] && build

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
