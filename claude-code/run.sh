#!/bin/sh
# Prepares the persistent home/workspace, writes the managed policy for the
# selected mode and hands over to supervise.sh, which keeps one
# `claude remote-control` running per workspace (/data/workspace plus the
# `workspaces` option).
#
# Controlled mode: Claude runs as the unprivileged `claude` user (uid 1000)
# with a clean environment (no SUPERVISOR_TOKEN). /homeassistant,
# /addon_configs and /share are root-owned, so it can read but not write
# them; the managed deny rules are only a second layer, since permission
# rules don't cover shell redirects.
# Free mode: Claude runs as root with the Supervisor token.
set -e

OPTIONS=/data/options.json
opt() { jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS"; }

CONTROLLED=$(opt controlled_mode)
PERMISSION_MODE=$(opt permission_mode)
PREFIX=$(opt session_name_prefix)
SESSION_NAME=$(opt session_name)
MACHINE_NAME=$(opt machine_name)

HOME_DIR=/data/home
WORKSPACE=/data/workspace
POLICY_DIR=/etc/claude-code

WORKSPACES=/run/claude-workspaces

mkdir -p "$HOME_DIR/.claude" "$WORKSPACE"

# One "<dir>\t<name>" line per remote-control: the main workspace first, then
# each entry of `workspaces` (paths relative to /data/workspace).
printf '%s\t%s\n' "$WORKSPACE" "$SESSION_NAME" >"$WORKSPACES"
jq -r '.workspaces[]? | [.path, (.name // "")] | @tsv' "$OPTIONS" |
  while IFS="$(printf '\t')" read -r path name; do
    case "/$path/" in
      */../*) echo "[claude-code] ignoring workspace '$path': '..' is not allowed"; continue ;;
    esac
    dir="$WORKSPACE/${path%/}"
    if [ ! -d "$dir" ]; then
      echo "[claude-code] ignoring workspace '$path': $dir does not exist (clone it first)"
      continue
    fi
    printf '%s\t%s\n' "$dir" "$name" >>"$WORKSPACES"
  done
chmod 644 "$WORKSPACES"

# Pre-trust the workspaces: with no terminal the trust prompt can't be
# answered and remote-control exits with "Workspace not trusted".
STATE="$HOME_DIR/.claude.json"
[ -s "$STATE" ] || echo '{}' >"$STATE"
tmp=$(mktemp)
cut -f1 "$WORKSPACES" | jq -R . | jq -s --slurpfile s "$STATE" \
  'reduce .[] as $d ($s[0]; .projects[$d].hasTrustDialogAccepted = true)' >"$tmp"
cat "$tmp" >"$STATE"
rm -f "$tmp"

# Files root created while in free mode go back to the claude user, so the
# login and the repos keep working after switching modes.
chown -R claude:claude "$HOME_DIR" "$WORKSPACE"
chmod 700 "$HOME_DIR"

mkdir -p "$POLICY_DIR"
if [ "$CONTROLLED" = "true" ]; then
  MODE_TEXT="CONTROLADO: somente leitura de /homeassistant, /addon_configs e /share; sem token do Supervisor."
  cat >"$POLICY_DIR/managed-settings.json" <<'EOF'
{
  "permissions": {
    "deny": [
      "Edit(//homeassistant/**)",
      "Edit(//config/**)",
      "Edit(//addon_configs/**)",
      "Edit(//share/**)",
      "Read(//homeassistant/secrets.yaml)"
    ]
  }
}
EOF
else
  MODE_TEXT="LIVRE: root, leitura e escrita em /homeassistant, /addon_configs e /share, com SUPERVISOR_TOKEN (CLI \`ha\` e API do Supervisor/Core)."
  echo '{}' >"$POLICY_DIR/managed-settings.json"
fi

cat >"$POLICY_DIR/CLAUDE.md" <<EOF
# Ambiente: add-on Claude Code do Home Assistant

Modo atual: $MODE_TEXT
O modo so muda pela opcao \`controlled_mode\` do add-on (feita pelo usuario na UI
do Home Assistant, seguida de restart). Nao tente contornar o modo controlado.

- /homeassistant: configuracao do Home Assistant (configuration.yaml, .storage).
- /addon_configs: configuracoes dos add-ons.
- /share: pasta compartilhada do Home Assistant.
- /data/workspace: pasta de trabalho persistente (clone repositorios aqui).
- No modo livre, \`ha\` (CLI do Supervisor) e \`curl -H "Authorization: Bearer \$SUPERVISOR_TOKEN" http://supervisor/core/api/...\` acessam o Home Assistant.
- Sempre valide a configuracao (\`ha core check\`) antes de reiniciar o Core.
EOF
chmod 644 "$POLICY_DIR/managed-settings.json" "$POLICY_DIR/CLAUDE.md"

if [ "$CONTROLLED" != "true" ] && [ "$PERMISSION_MODE" = "bypassPermissions" ]; then
  echo "[claude-code] bypassPermissions is refused as root; using 'default' in free mode"
  PERMISSION_MODE=default
fi

BASE_ENV="HOME=$HOME_DIR PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
TZ=${TZ:-UTC} LANG=C.UTF-8 TERM=xterm-256color DISABLE_AUTOUPDATER=1 DISABLE_UPDATES=1 \
CLAUDE_PERMISSION_MODE=$PERMISSION_MODE CLAUDE_REMOTE_CONTROL_SESSION_NAME_PREFIX=$PREFIX"

# The container hostname can't be changed from inside, so the machine name
# shown in claude.ai/code is overridden at the libc level instead.
if [ -n "$MACHINE_NAME" ]; then
  BASE_ENV="$BASE_ENV LD_PRELOAD=/usr/local/lib/libhostname.so HOSTNAME_OVERRIDE=$MACHINE_NAME"
fi

if [ "$CONTROLLED" = "true" ]; then
  echo "[claude-code] controlled mode: running as 'claude' (read-only configs, no Supervisor token)"
  # shellcheck disable=SC2086
  exec env -i $BASE_ENV USER=claude su-exec claude /usr/local/bin/supervise.sh
else
  echo "[claude-code] FREE mode: running as root with write access and the Supervisor token"
  # shellcheck disable=SC2086
  exec env -i $BASE_ENV USER=root SUPERVISOR_TOKEN="$SUPERVISOR_TOKEN" /usr/local/bin/supervise.sh
fi
