#!/bin/bash
set -e

PASSWD=${BLOG_PASSWORD:-123mudar}


warning_passwd() {
    cat >&2 <<-'EOWARN'
        *******************************************************
        WARNING: the password for the user 'blog' has got the
                 default pass '123mudar', CHANGE IT.

        docker run ... -e BLOG_PASSWORD=<your password> ...
        *******************************************************
EOWARN
}

create_db() {
    echo
    echo "*** Creating user and database 'blog'... ***"
    echo
    psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
         CREATE DATABASE blog;
         CREATE USER blog WITH PASSWORD '$PASSWD';
         ALTER ROLE blog SET client_encoding TO 'utf8';
         ALTER ROLE blog SET timezone TO 'America/Sao_Paulo';
         GRANT ALL PRIVILEGES ON DATABASE blog TO blog;
EOSQL
}

[ -v $BLOG_PASSWORD ] &&  warning_passwd
create_db

exit 0
