# syntax=docker/dockerfile:1

FROM debian:12

ARG GIT_BUILD_HASH
ARG VERSION

LABEL org.opencontainers.image.url https://github.com/authentik-community/krb5-docker
LABEL org.opencontainers.image.description Run an MIT Kerberos 5 KDC in a container
LABEL org.opencontainers.image.source https://github.com/authentik-community/krb5-docker.git
LABEL org.opencontainers.image.version ${VERSION}
LABEL org.opencontainers.image.revision ${GIT_BUILD_HASH}

ENV KRB5_CONFIG=/etc/krb5.conf \
  KRB5_KDC_PROFILE=/etc/krb5kdc/kdc.conf \
  KRB5_DATA_DIR=/var/lib/krb5kdc

RUN apt-get update && \
  apt-get install -y --no-install-recommends pwgen krb5-kdc krb5-admin-server krb5-kdc-ldap krb5-k5tls krb5-otp krb5-pkinit krb5-strength && \
  apt-get clean && \
  rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/ && \
  adduser --system --no-create-home --uid 1000 --group --home /var/lib/krb5kdc krb5kdc && \
  mkdir -p /var/lib/krb5kdc && \
  rm -rf /var/lib/krb5kdc/* && \
  echo > /etc/krb5.conf && \
  echo > /etc/krb5kdc/kdc.conf && \
  chown -R krb5kdc:krb5kdc /var/lib/krb5kdc /etc/krb5.conf /etc/krb5kdc

COPY ./entrypoint.sh /entrypoint.sh

USER 1000

WORKDIR /var/lib/krb5kdc

ENTRYPOINT [ "/entrypoint.sh" ]
