#!/bin/bash
set -e

PASSWD=123mudar

echo "*** Creating user and database blog... ***"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE DATABASE blog;
    CREATE USER blog WITH PASSWORD '$PASSWD';
    ALTER ROLE blog SET client_encoding TO 'utf8';
    ALTER ROLE blog SET timezone TO 'America/Sao_Paulo';
    GRANT ALL PRIVILEGES ON DATABASE blog TO blog;
EOSQL
