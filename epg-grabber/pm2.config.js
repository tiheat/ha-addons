// Substitui o pm2.config.js da imagem para que cada grab seja precedido pela
// regeracao do channels.xml (ver grab.sh). O resto e igual ao original: um
// processo servindo public/ e um cron chamando o grab.

// Opcoes do add-on (config.yaml -> options) viram /data/options.json quando
// o Home Assistant sobe o container. Aqui elas viram ENV antes de montar os
// apps, entao mudar playlist, cron, etc. pela aba Configuration do add-on e
// so precisa de um Restart — sem editar Dockerfile nem subir versao nova. As
// ENV do Dockerfile continuam valendo como default e como fallback pra quem
// roda fora do Home Assistant (docker-compose etc.), onde options.json nao
// existe.
try {
  const options = JSON.parse(require('fs').readFileSync('/data/options.json', 'utf8'))
  const mapa = {
    playlist_url: 'PLAYLIST_URL', epg_gen_args: 'EPG_GEN_ARGS', tz: 'TZ',
    cron_schedule: 'CRON_SCHEDULE', run_at_startup: 'RUN_AT_STARTUP',
    days: 'DAYS', max_connections: 'MAX_CONNECTIONS', delay: 'DELAY'
  }
  for (const [chave, env] of Object.entries(mapa)) {
    if (options[chave] !== undefined && options[chave] !== null) process.env[env] = String(options[chave])
  }
} catch { /* sem options.json: segue só com o ENV do Dockerfile */ }

const grab = 'sh /epg/grab.sh'

const apps = [
  { name: 'serve', script: 'npx serve -- public', instances: 1, watch: false, autorestart: true },
  {
    name: 'grab',
    script: `npx chronos -e "${grab}" -p "${process.env.CRON_SCHEDULE}" -l`,
    instances: 1,
    watch: false,
    autorestart: true
  }
]

if (process.env.RUN_AT_STARTUP === 'true') {
  apps.push({ name: 'grab-at-startup', script: grab, instances: 1, autorestart: false, watch: false, max_restarts: 1 })
}

module.exports = { apps }
