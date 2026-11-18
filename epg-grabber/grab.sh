#!/bin/sh
# Regera o channels.xml a partir da playlist e em seguida roda o grab.
# Fica num script proprio porque o pm2 executa o comando sem shell, entao
# operadores como || e ; nao funcionariam direto no pm2.config.js.
set -u
cd /epg || exit 1

if [ -n "${PLAYLIST_URL:-}" ]; then
  # shellcheck disable=SC2086
  node /epg/gerar-channels.mjs "$PLAYLIST_URL" -o /epg/public/channels.xml ${EPG_GEN_ARGS:-} \
    || echo "[gerar-channels] falhou; seguindo com o channels.xml anterior"
fi

exec npm run grab -- --channels=public/channels.xml --output=public/guide.xml
