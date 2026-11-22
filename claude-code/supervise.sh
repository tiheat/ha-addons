#!/bin/bash
# Keeps `claude remote-control` running in /data/workspace. Until the claude.ai
# login exists it only waits, so the container stays up for the one-time
# `claude auth login` (see DOCS.md).
cd /data/workspace

while true; do
  if ! claude auth status >/dev/null 2>&1; then
    echo "[claude-code] not logged in. From the HA host (ssh) run:"
    echo "[claude-code]   sudo docker exec -it -u claude \$(sudo docker ps -qf name=_claude_code) claude auth login"
    sleep 60
    continue
  fi

  echo "[claude-code] starting remote-control (permission mode: $CLAUDE_PERMISSION_MODE)"
  claude remote-control --permission-mode "$CLAUDE_PERMISSION_MODE" </dev/null
  echo "[claude-code] remote-control exited with code $?; restarting in 10s"
  sleep 10
done
