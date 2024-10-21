FROM debian:12.7

ARG GIT_BUILD_HASH
ARG VERSION
ARG S6_VERSION=3.2.0.2

LABEL org.opencontainers.image.url https://github.com/authentik-community/krb5-docker
LABEL org.opencontainers.image.description Run an MIT Kerberos 5 KDC in a container
LABEL org.opencontainers.image.source https://github.com/authentik-community/krb5-docker.git
LABEL org.opencontainers.image.version ${VERSION}
LABEL org.opencontainers.image.revision ${GIT_BUILD_HASH}

ENV KRB5_CONFIG=/etc/krb5.conf \
  KRB5_KDC_PROFILE=/etc/krb5kdc/kdc.conf \
  KRB5_DATA_DIR=/var/lib/krb5kdc \
  DEBIAN_FRONTEND=noninteractive \
  S6_READ_ONLY_ROOT=1 \
  S6_KEEP_ENV=1

RUN apt update && \
  apt install -y --no-install-recommends --no-install-suggests xz-utils ca-certificates curl procps iproute2 pwgen krb5-kdc krb5-admin-server krb5-kdc-ldap krb5-k5tls krb5-otp krb5-pkinit krb5-strength && \
  apt autoremove -y && \
  apt clean && \
  rm -rf /tmp/* /var/lib/apt/lists/* /var/tmp/*

RUN curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-noarch.tar.xz" | tar Jpxf - -C / && \
  curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-$(uname -m).tar.xz" | tar Jpxf - -C / && \
  curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-symlinks-noarch.tar.xz" | tar Jpxf - -C / && \
  curl -fsSL "https://github.com/just-containers/s6-overlay/releases/download/v${S6_VERSION}/s6-overlay-symlinks-arch.tar.xz" | tar Jpxf - -C /

RUN adduser --system --no-create-home --uid 1673 --group --home /var/lib/krb5kdc krb5kdc && \
  mkdir -p /var/lib/krb5kdc && \
  rm -rf /var/lib/krb5kdc/* && \
  echo > /etc/krb5.conf && \
  echo > /etc/krb5kdc/kdc.conf && \
  chown -R krb5kdc:krb5kdc /var/lib/krb5kdc /etc/krb5.conf /etc/krb5kdc

COPY ./etc/s6-overlay/ /etc/s6-overlay/

USER 1673

WORKDIR /var/lib/krb5kdc

ENTRYPOINT [ "/init" ]
