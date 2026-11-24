#!/bin/bash
# Keeps one `claude remote-control` running per workspace listed in
# /run/claude-workspaces (written by run.sh: one "<dir>\t<name>" per line).
# Each workspace shows up as its own environment in claude.ai/code. Until the
# claude.ai login exists it only waits, so the container stays up for the
# one-time `claude auth login` (see DOCS.md).
WORKSPACES=/run/claude-workspaces

serve() {
  local dir=$1 name=$2
  local args=(--permission-mode "$CLAUDE_PERMISSION_MODE")
  [ -n "$name" ] && args+=(--name "$name")
  cd "$dir" || return

  while true; do
    if ! claude auth status >/dev/null 2>&1; then
      echo "[claude-code] not logged in. From the HA host (ssh) run:"
      echo "[claude-code]   sudo docker exec -it -u claude \$(sudo docker ps -qf name=_claude_code) claude auth login"
      sleep 60
      continue
    fi

    echo "[claude-code] starting remote-control in $dir (permission mode: $CLAUDE_PERMISSION_MODE)"
    claude remote-control "${args[@]}" </dev/null
    echo "[claude-code] remote-control in $dir exited with code $?; restarting in 10s"
    sleep 10
  done
}

while IFS=$'\t' read -r dir name; do
  [ -n "$dir" ] && serve "$dir" "$name" &
done <"$WORKSPACES"
wait
