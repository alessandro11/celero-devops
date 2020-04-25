#!/bin/sh
set -e

run_migrations() {
    /home/app/migration.sh
}

if [ "$1" = 'runserver' ]; then
    run_migrations

    shift
    procs=$(nproc)
    echo "[INFO] Starting gunicorn"
    echo "[INFO] Listening at: http://$8 for $procs worker(s)."

    exec gosu app /home/app/.venv/bin/gunicorn --workers "$procs" "$@"
fi

exec "$@"
