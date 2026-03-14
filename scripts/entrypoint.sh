#!/bin/bash

# Default values
MAIL_DOMAIN=${MAIL_DOMAIN:-example.com}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-mail.example.com}
DATA_DIR=/data


export MAIL_DOMAIN
export MAIL_HOSTNAME
export RSPAMD

printf '\n
                            ███  ████                            █████            
                           ░░░  ░░███                           ░░███             
 █████████████    ██████   ████  ░███  █████████████    ██████  ███████    ██████ 
░░███░░███░░███  ░░░░░███ ░░███  ░███ ░░███░░███░░███  ███░░███░░░███░    ███░░███
 ░███ ░███ ░███   ███████  ░███  ░███  ░███ ░███ ░███ ░███ ░███  ░███    ░███ ░███
 ░███ ░███ ░███  ███░░███  ░███  ░███  ░███ ░███ ░███ ░███ ░███  ░███ ███░███ ░███
 █████░███ █████░░████████ █████ █████ █████░███ █████░░██████   ░░█████ ░░██████ 
░░░░░ ░░░ ░░░░░  ░░░░░░░░ ░░░░░ ░░░░░ ░░░░░ ░░░ ░░░░░  ░░░░░░     ░░░░░   ░░░░░░  
'

# Run domain init if first start
if [ ! -f /data/.initialized ]; then
  /init_domain.sh
  touch /data/.initialized
fi

if [ "${RSPAMD_ENABLE:-false}" = "true" ]; then
  echo "[RSPAMD] Enabled"

  # Generate postfix config
  envsubst < /etc/postfix/main.cf.rspamd.template > /etc/postfix/main.cf
  sed -i 's|^mailbox_command =.*|mailbox_command = /usr/lib/dovecot/deliver -d \${recipient}|' /etc/postfix/main.cf

  # Generate dovecot config
  envsubst < /etc/dovecot/dovecot.conf.template > /etc/dovecot/dovecot.conf

  # Generate rspamd config
  envsubst < /etc/rspamd/local.d/dkim_signing.conf.template > /etc/rspamd/local.d/dkim_signing.conf
  envsubst < /etc/rspamd/local.d/dmarc.conf.template > /etc/rspamd/local.d/dmarc.conf
  
  chown -R _rspamd:_rspamd "$DATA_DIR/dkim/$MAIL_DOMAIN"
  chmod 600 "$DATA_DIR/dkim/$MAIL_DOMAIN/mail.private"
  chmod 644 "$DATA_DIR/dkim/$MAIL_DOMAIN/mail.txt"

  echo "[REDIS] Starting"
  service redis-server start
  echo "[RSPAMD] Starting"
  service rspamd start
  echo "[DOVECOT] Starting"
  service dovecot start
  echo "[POSTFIX] Starting"
  service postfix start
else
  echo "[RSPAMD] Disabled"

  # Generate postfix config
  envsubst < /etc/postfix/main.cf.template > /etc/postfix/main.cf
  sed -i 's|^mailbox_command =.*|mailbox_command = /usr/lib/dovecot/deliver -d \${recipient}|' /etc/postfix/main.cf

  # Generate dovecot config
  envsubst < /etc/dovecot/dovecot.conf.template > /etc/dovecot/dovecot.conf

  # Generate opendkim config
  envsubst < /etc/opendkim.conf.template > /etc/opendkim.conf

  # Generate opendmarc config
  envsubst < /etc/opendmarc.conf.template > /etc/opendmarc.conf 

  # Postgrey config
  echo $MAIL_HOSTNAME >> /etc/postgrey/whitelist_clients
  sed -i 's|POSTGREY_OPTS="--inet=10023"|POSTGREY_OPTS="--delay=120 --max-age=35 --inet=127.0.0.1:10023"|' /etc/default/postgrey

  chown -R opendkim:opendkim "$DATA_DIR/dkim/$MAIL_DOMAIN" 
  
  echo "[OPENDKIM] Starting"
  service opendkim start
  echo "[OPENDMARD] Starting"
  service opendmarc start
  echo "[POSTGRAY] Starting"
  service postgrey start
  echo "[DOVECOT] Starting"
  service dovecot start
  echo "[POSTFIX] Starting"
  service postfix start
fi

touch /var/log/mail.log
tail -f /var/log/mail.log

exec "$@"
