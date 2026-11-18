#!/bin/sh
# Prepares /config on first boot and starts Authelia with secrets read from
# files, so no secret ever lives in configuration.yml or in the image.
set -e

CONFIG=/config
SECRETS="$CONFIG/secrets"
OPTIONS=/data/options.json

# Flat string fields only; the image has no jq.
option() {
  sed -n "s/.*\"$1\" *: *\"\([^\"]*\)\".*/\1/p" "$OPTIONS"
}

random() {
  tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$1"
}

mkdir -p "$SECRETS"
chmod 700 "$SECRETS"

for name in jwt session storage; do
  if [ ! -s "$SECRETS/$name" ]; then
    random 64 >"$SECRETS/$name"
    chmod 600 "$SECRETS/$name"
    echo "[authelia] generated secret: $name"
  fi
done

if [ ! -f "$CONFIG/configuration.yml" ]; then
  DOMAIN=$(option domain)
  if [ -z "$DOMAIN" ]; then
    echo "[authelia] set the 'domain' option (e.g. home.example.com) and restart" >&2
    exit 1
  fi
  sed "s/__DOMAIN__/$DOMAIN/g" /defaults/configuration.yml >"$CONFIG/configuration.yml"
  echo "[authelia] created configuration.yml for $DOMAIN"
fi

if [ ! -f "$CONFIG/users_database.yml" ]; then
  USER=$(option admin_user)
  PASSWORD=$(random 24)
  HASH=$(authelia crypto hash generate argon2 --password "$PASSWORD" | sed -n 's/^Digest: //p')
  cat >"$CONFIG/users_database.yml" <<EOF
users:
  $USER:
    disabled: false
    displayname: $USER
    password: '$HASH'
    groups:
      - admins
EOF
  printf '%s\n' "$PASSWORD" >"$SECRETS/initial_password"
  chmod 600 "$SECRETS/initial_password"
  echo "[authelia] created user '$USER'; initial password in $SECRETS/initial_password (delete it after the first login)"
fi

export AUTHELIA_IDENTITY_VALIDATION_RESET_PASSWORD_JWT_SECRET_FILE="$SECRETS/jwt"
export AUTHELIA_SESSION_SECRET_FILE="$SECRETS/session"
export AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE="$SECRETS/storage"

exec /app/entrypoint.sh --config "$CONFIG/configuration.yml"
