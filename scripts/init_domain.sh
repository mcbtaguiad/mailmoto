#!/bin/bash
set -e

# Domain config from environment
DOMAIN=${MAIL_DOMAIN:-example.com}
HOSTNAME=${MAIL_HOSTNAME:-mail.example.com}


DATA_DIR=/data

echo "[INIT] Setting up domain: $DOMAIN"

# 1. Create mail and DKIM directories
mkdir -p "$DATA_DIR/mail/$DOMAIN"
mkdir -p "$DATA_DIR/dkim/$DOMAIN"

# 2. Create DKIM keys if not exist
if [ ! -f "$DATA_DIR/dkim/$DOMAIN/mail.private" ]; then
  echo "[INIT] Generating DKIM keys for $DOMAIN"
  opendkim-genkey -D "$DATA_DIR/dkim/$DOMAIN" -d "$DOMAIN" -s mail
  chown -R 5000:5000 "$DATA_DIR/dkim/$DOMAIN"
fi

# 3. Setup DKIM tables
cat > "$DATA_DIR/dkim/key.table" <<EOF
mail._domainkey.$DOMAIN $DOMAIN:mail:$DATA_DIR/dkim/$DOMAIN/mail.private
EOF

cat > "$DATA_DIR/dkim/signing.table" <<EOF
*@${DOMAIN} mail._domainkey.$DOMAIN
EOF

cat > "$DATA_DIR/dkim/trusted.hosts" <<EOF
127.0.0.1
localhost
EOF



echo "[INIT] Domain $DOMAIN setup complete."
