#! /usr/bin/env bash

set -xeuo pipefail

if [ -z "$(cat "${KRB5_CONFIG}")" ]; then
  cat <<EOF >"${KRB5_CONFIG}"
[libdefaults]
  dns_lookup_realm = false
  ticket_lifetime = 24h
  renew_lifetime = 7d
  forwardable = true
  rdns = true
  default_realm = ${KRB5_REALM}

[realms]
  ${KRB5_REALM} = {
EOF
  if [ -n "${KRB5_KDC:-}" ]; then
    echo "    kdc = ${KRB5_KDC}" >>/etc/krb5.conf
  fi
  if [ -n "${KRB5_ADMINSERVER:-}" ]; then
    echo "    admin_server = ${KRB5_ADMINSERVER}" >>/etc/krb5.conf
  fi
  echo "  }" >>/etc/krb5.conf
fi

if [ -z "$(cat "${KRB5_KDC_PROFILE}")" ]; then
  cat <<EOF >"${KRB5_KDC_PROFILE}"
[kdcdefaults]
  kdc_listen = "${KRB5_KDC_PORT:-8888}"
  kdc_listen_tcp = "${KRB5_KDC_PORT:-8888}"

[realms]
  ${KRB5_REALM} = {
    database_name = "${KRB5_DATA_DIR}/principal"
    acl_file = "${KRB5_DATA_DIR}/kadm5.acl"
    key_stash_file = ${KRB5_DATA_DIR}/stash
    max_life = 24h 0m 0s
    kdc_listen = "${KRB5_KDC_PORT:-8888}"
    kdc_listen_tcp = "${KRB5_KDC_PORT:-8888}"
    kpasswd_listen = "${KRB5_KPASSWD_PORT:-8464}"
    kadmind_listen = "${KRB5_KADMIN_PORT:-8749}"
    max_renewable_life = 2d 0h 0m 0s
    master_key_type = aes256-cts-hmac-sha384-192
    # norealm chosen to allow for easier realm renaming
    supported_enctypes = aes256-sha1:norealm aes128-sha1:norealm aes256-sha2:norealm aes128-sha2:norealm
    default_principal_flags = +preauth
  }

[logging]
  kdc = STDERR
  admin_server = STDERR
  default = STDERR
EOF
fi

if ! [ -f "${KRB5_DATA_DIR}/kadm5.acl" ]; then
  echo "*/admin@${KRB5_REALM} *" >"${KRB5_DATA_DIR}/kadm5.acl"
fi

if ! [ -f "${KRB5_DATA_DIR}/principal" ]; then
  echo "Database not initialized"
  echo "Initializing now..."
  if [ -z "${KRB5_KDC_MASTER_PASSWORD_FILE:-}" ]; then
    KRB5_KDC_MASTER_PASSWORD_FILE="${KRB5_DATA_DIR}/master.pass"
    echo "WARNING: You have not defined a file in which to find the KDC Master password"
    echo "WARNING: One will be created for you and stored at ${KRB5_KDC_MASTER_PASSWORD_FILE}"
    echo "WARNING: You should copy the contents of that file to a secure secrets storage solution and delete it"
    pwgen -cny 64 1 >"${KRB5_KDC_MASTER_PASSWORD_FILE}"
  fi
  cat "${KRB5_KDC_MASTER_PASSWORD_FILE}" "${KRB5_KDC_MASTER_PASSWORD_FILE}" | kdb5_util create -r "${KRB5_REALM}" -s
  echo "Database initialized"
fi

if [ -n "${INIT_ONLY:-}" ]; then
  exit 0
fi

if [ "$#" -eq 0 ]; then
  command="krb5kdc"
elif [ "${1}" = "kdc" ] || [ "${1}" = "krb5kdc" ]; then
  command="krb5kdc"
elif [ "${1}" = "kadmind" ]; then
  command="kadmind"
fi

case "${command:-}" in
krb5kdc)
  set -- /usr/sbin/krb5kdc -n
  ;;
kadmind)
  set -- /usr/sbin/kadmind -nofork
  ;;
esac

exec "$@"
