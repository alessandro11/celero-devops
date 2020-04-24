# vim:set ft=dockerfile:
FROM postgres:12.2-alpine

# make the "pt_BR.UTF-8" locale so postgres will be utf-8 enabled by default
# alpine doesn't require explicit locale-file generation
ENV LANG en_US.UTF-8

# Set the correct timezone
RUN ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime

# Generate a random password for postgres user.
# Note: you must pass the -e POSTGRES_PASSWORD_FILE=/var/lib/postgresql/.postgres_pass
RUN set -ex \
    && PASSWORD=$(mkpasswd -m sha-512 'mypassword') \
    && echo ${PASSWORD::15} | tee /var/lib/postgresql/.postgres_pass

COPY 01-initdb.sh /docker-entrypoint-initdb.d/
ENTRYPOINT ["docker-entrypoint.sh"]

EXPOSE 5432
CMD ["postgres"]
