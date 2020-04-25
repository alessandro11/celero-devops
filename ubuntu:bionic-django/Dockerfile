FROM ubuntu:bionic

# Manage dependencies
RUN apt-get update --yes && \
    apt-get install --yes python3 python3-pip python3-venv libjpeg9-dev zlib1g-dev git vim \
    && pip3 install --upgrade pip


# Create an non privilege user; security purpose
# also setup the virtual environment
# Get source code of the application and install dependencies
RUN set -ex; \
    useradd -m -d /home/app -s /bin/bash app \
    && su - app -c 'python3 -m venv venv \
    source $HOME/venv/bin/activate; \
    git clone https://github.com/alessandro11/Blog-API-with-Django-Rest-Framework.git blog \
    && cd blog/; \
    pip install --no-cache-dir -r requirements.txt

COPY migration.sh /home/app/migration.sh

