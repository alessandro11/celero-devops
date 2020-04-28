FROM ubuntu:bionic

# Manage dependencies
RUN apt-get update --yes && apt-get install --yes python3 \
    python3-pip python3-venv libjpeg9-dev zlib1g-dev gosu git vim \
    && pip3 install --upgrade pip

RUN useradd -l -m -d /home/app -s /bin/bash app
USER app
WORKDIR /home/app

RUN set -e; python3 -m venv .venv \
    && . $HOME/.venv/bin/activate; \
    git clone https://github.com/alessandro11/Blog-API-with-Django-Rest-Framework.git blog \
    && cd blog/; \
    pip install --no-cache-dir -r requirements.txt

COPY --chown=app:app ./migration.sh /home/app/migration.sh

USER root
RUN set -e; install -o app -g app -d /var/log/gunicorn \
    && install -o app -g app /dev/null /var/log/gunicorn/error.log \
    && install -o app -g app /dev/null /var/log/gunicorn/access.log

COPY ./docker-entrypoint.sh /
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 8080
CMD ["runserver", "--log-level", "warning", "--error-logfile", \
    "/var/log/gunicorn/error.log", "--access-logfile", \
    "/var/log/gunicorn/access.log", "--bind", "0.0.0.0:8080", \
    "--pythonpath", "/home/app/blog/src,/home/app/venv/lib,/home/app/venv/lib64", "blog.wsgi"]
