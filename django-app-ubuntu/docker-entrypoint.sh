#!/bin/sh
set -e

DBNAME=${DB_NAME:-blog}
DBUSER=${DB_USER:-blog}
DBPASSWD=${DB_PASSWD:-123mudar}
DBSERVER=${DB_SERVER:-localhost}

run_migrations() {
    /home/app/migration.sh
}

db_settings() {
    sed -i "93s/DBNAME/$DBNAME/" /home/app/blog/src/blog/settings.py
    sed -i "94s/LOGIN/$DBUSER/" /home/app/blog/src/blog/settings.py
    sed -i "95s/PASSWD/$DBPASSWD/" /home/app/blog/src/blog/settings.py
    sed -i "96s/DBSERVER/$DBSERVER/" /home/app/blog/src/blog/settings.py
}


if [ "$1" = 'runserver' ]; then
    db_settings
    run_migrations

    shift
    procs=$(nproc)
    echo "[INFO] Starting gunicorn"
    echo "[INFO] Listening at: http://$8 for $procs worker(s)."

    exec gosu app /home/app/.venv/bin/gunicorn --workers "$procs" "$@"
fi

exec "$@"
