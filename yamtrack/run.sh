#!/bin/sh
# Maps the add-on options to Yamtrack's environment, keeps the database and the
# Django secret in /data, starts the bundled Redis and hands over to the
# upstream entrypoint (migrations + supervisord with nginx, gunicorn, celery).
set -e

OPTIONS=/data/options.json

# Booleans print as True/False, which Yamtrack's settings parse.
option() {
  python -c 'import json, sys; print(json.load(open(sys.argv[1]))[sys.argv[2]])' "$OPTIONS" "$1"
}

mkdir -p /data/db

# Yamtrack loads every file in SECRET_FILE's directory, so the secret needs a
# directory of its own (next to db/ it fails on the directory).
mkdir -p /data/secrets
chmod 700 /data/secrets
if [ ! -s /data/secrets/secret ]; then
  (umask 077; tr -dc 'A-Za-z0-9' </dev/urandom | head -c 64 >/data/secrets/secret)
  echo "[yamtrack] generated Django secret in /data/secrets/secret"
fi
# gunicorn and celery run as the unprivileged user and read it at startup.
chown -R "${PUID:-1000}:${PGID:-1000}" /data/secrets
export SECRET_FILE=/data/secrets/secret

URLS=$(option urls)
[ -n "$URLS" ] && export URLS
export REGISTRATION="$(option registration)"
export TMDB_LANG="$(option tmdb_lang)"

echo "[yamtrack] starting redis-server..."
redis-server --bind 127.0.0.1 --port 6379 --save '' --appendonly no --daemonize yes

# The upstream entrypoint migrates as root and then chowns `db`, which here is
# a symlink the chown may not follow. Migrate first and hand the real directory
# to the app user; the entrypoint's own migrate is then a no-op.
python manage.py migrate --noinput
chown -R "${PUID:-1000}:${PGID:-1000}" /data/db

exec /entrypoint.sh
