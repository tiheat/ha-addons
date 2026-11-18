#!/bin/sh
set -e

echo "[run.sh] starting redis-server..."
redis-server --bind 127.0.0.1 --port 6379 --daemonize yes

echo "[run.sh] starting torrent-indexer..."
# "$@" is the Dockerfile's CMD (/root/app)
exec "$@"
