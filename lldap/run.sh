#!/usr/bin/env bash
# Prepares /config on first boot, starts LLDAP with secrets read from files and
# bootstraps the admin group, the Authelia service account and an optional
# admin user once. No secret is ever printed or stored in the image.
set -euo pipefail

CONFIG=/config
SECRETS="$CONFIG/secrets"
CONF_FILE="$CONFIG/lldap_config.toml"
BOOTSTRAP_DONE="$CONFIG/.bootstrap_done"
OPTIONS=/data/options.json

option() { jq -r --arg k "$1" '.[$k] // ""' "$OPTIONS"; }
# tr gets SIGPIPE when head exits; that is expected, so ignore it here.
random() { (set +o pipefail; LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$1"); }

DOMAIN=$(option domain)
if [[ -z "$DOMAIN" ]]; then
  echo "[lldap] set the 'domain' option (e.g. home.example.com) and restart" >&2
  exit 1
fi
BASE_DN=$(sed 's/^/dc=/; s/\./,dc=/g' <<<"$DOMAIN")

mkdir -p "$SECRETS"
chmod 700 "$SECRETS"
for name in jwt_secret key_seed admin_password authelia_bind_password; do
  if [[ ! -s "$SECRETS/$name" ]]; then
    random 48 >"$SECRETS/$name"
    chmod 600 "$SECRETS/$name"
    echo "[lldap] generated secret: $name"
  fi
done

if [[ ! -f "$CONF_FILE" ]]; then
  cp /app/lldap_config.docker_template.toml "$CONF_FILE"
  echo "[lldap] created lldap_config.toml"
fi

export LLDAP_LDAP_BASE_DN="$BASE_DN"
export LLDAP_HTTP_URL="https://lldap.$DOMAIN"
export LLDAP_DATABASE_URL="sqlite://$CONFIG/users.db?mode=rwc"
export LLDAP_JWT_SECRET_FILE="$SECRETS/jwt_secret"
export LLDAP_KEY_SEED
LLDAP_KEY_SEED=$(cat "$SECRETS/key_seed")
export LLDAP_LDAP_USER_PASS_FILE="$SECRETS/admin_password"

cd /app
# LLDAP caches the key derived from key_seed in ./server_key and then refuses
# to start when both exist. The seed is the source of truth, so drop the cache.
rm -f /app/server_key
/app/lldap run --config-file "$CONF_FILE" &
PID=$!
trap 'kill -TERM "$PID" 2>/dev/null; wait "$PID"' TERM INT

if [[ ! -f "$BOOTSTRAP_DONE" ]]; then
  for _ in $(seq 1 60); do
    curl -sf http://127.0.0.1:17170/health >/dev/null && break
    sleep 1
  done

  WORK=$(mktemp -d)
  mkdir -p "$WORK/users" "$WORK/groups"
  ADMIN_GROUP=$(option admin_group)
  jq -n --arg g "$ADMIN_GROUP" '{name: $g}' >"$WORK/groups/admin.json"
  jq -n --arg p "$(cat "$SECRETS/authelia_bind_password")" \
    '{id: "authelia", email: "authelia@localhost", displayName: "Authelia (service)", password: $p, groups: ["lldap_strict_readonly"]}' \
    >"$WORK/users/authelia.json"

  ADMIN_USER=$(option admin_user)
  if [[ -n "$ADMIN_USER" ]]; then
    PASS_FILE="$SECRETS/initial_password_$ADMIN_USER"
    [[ -s "$PASS_FILE" ]] || { random 24 >"$PASS_FILE"; chmod 600 "$PASS_FILE"; }
    jq -n --arg u "$ADMIN_USER" --arg e "$(option admin_email)" --arg g "$ADMIN_GROUP" --arg p "$(cat "$PASS_FILE")" \
      '{id: $u, email: (if $e == "" then "\($u)@localhost" else $e end), displayName: $u, password: $p, groups: [$g]}' \
      >"$WORK/users/admin.json"
  fi

  if LLDAP_URL=http://127.0.0.1:17170 LLDAP_ADMIN_USERNAME=admin \
     LLDAP_ADMIN_PASSWORD_FILE="$SECRETS/admin_password" \
     USER_CONFIGS_DIR="$WORK/users" GROUP_CONFIGS_DIR="$WORK/groups" \
     USER_SCHEMAS_DIR="$WORK/none" GROUP_SCHEMAS_DIR="$WORK/none" \
     /app/bootstrap.sh >"$WORK/bootstrap.log" 2>&1; then
    grep -viE 'password' "$WORK/bootstrap.log" || true
    touch "$BOOTSTRAP_DONE"
    echo "[lldap] bootstrap done: group '$ADMIN_GROUP', service user 'authelia'${ADMIN_USER:+, user '$ADMIN_USER'}"
  else
    grep -viE 'password' "$WORK/bootstrap.log" >&2 || true
    echo "[lldap] bootstrap failed; it will run again on the next start" >&2
  fi
  rm -rf "$WORK"
fi

wait "$PID"
