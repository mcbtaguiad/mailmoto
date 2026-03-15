#!/bin/bash
set -e

# Domain config from environment
MAIL_DOMAIN=${MAIL_DOMAIN:-example.com}
MAIL_HOSTNAME=${MAIL_HOSTNAME:-mail.example.com}

DATA_DIR=/data

echo "[INIT] Setting up domain: $MAIL_DOMAIN"

# Create  dir
mkdir -p "$DATA_DIR/mail/$MAIL_DOMAIN"
mkdir -p "$DATA_DIR/dkim/$MAIL_DOMAIN"

# Create DKIM keys if not exist
if [ ! -f "$DATA_DIR/dkim/$MAIL_DOMAIN/mail.private" ]; then
  echo "[INIT] Generating DKIM keys for $MAIL_DOMAIN"
  opendkim-genkey -b 1024 -D "$DATA_DIR/dkim/$MAIL_DOMAIN" -d "$MAIL_DOMAIN" -s mail
fi

# Setup DKIM tables
cat > "$DATA_DIR/dkim/key.table" <<EOF
mail._domainkey.$MAIL_DOMAIN $MAIL_DOMAIN:mail:$DATA_DIR/dkim/$MAIL_DOMAIN/mail.private
EOF

cat > "$DATA_DIR/dkim/signing.table" <<EOF
*@$MAIL_DOMAIN mail._domainkey.$MAIL_DOMAIN
EOF

cat > "$DATA_DIR/dkim/trusted.hosts" <<EOF
127.0.0.1
::1
localhost
*.${MAIL_DOMAIN}
EOF



echo "[INIT] Domain $MAIL_DOMAIN setup complete."
