FROM ghcr.io/iptv-org/epg:master

# Estas ENV so valem como default/fallback: dentro do Home Assistant, a aba
# Configuration do add-on (config.yaml -> options) manda mais — o
# pm2.config.js le /data/options.json e sobrescreve o que estiver definido
# ali antes de montar os processos. Editar aqui e fazer rebuild so importa
# pra quem roda este Dockerfile fora do Home Assistant (docker-compose etc.),
# onde options.json nao existe.
#
# DAYS/MAX_CONNECTIONS/DELAY sao lidos pelo proprio grabber via commander
# (.env('DAYS') etc). Com a lista completa da br.m3u sao 117 canais: DAYS=7
# dava 819 requisicoes por ciclo, DAYS=3 derruba para ~350 e quase nao se
# perde grade, porque o Pluto TV — a maior fatia — so entrega programacao
# cheia no dia corrente. DELAY e MAX_CONNECTIONS espacam as requisicoes para
# reduzir 429. (Isto e economia de requisicao, nao de memoria: o kill com
# codigo 137 que investigamos em 14/09 nao foi OOM — o log do host nao tinha
# "Out of memory: Killed process".)
ENV TZ=America/Bahia \
    CRON_SCHEDULE="0 6 * * *" \
    RUN_AT_STARTUP=true \
    DAYS=3 \
    MAX_CONNECTIONS=2 \
    DELAY=500 \
    PLAYLIST_URL="http://local-dispatcharr:9191/output/m3u?tvg_id_source=tvg_id"

# PLAYLIST_URL aponta para o proprio Dispatcharr, na rede interna dos add-ons
# (hostname derivado do slug dele, com _ virando -): o channels.xml passa a
# refletir exatamente os canais e tvg-id que existem no Dispatcharr agora, sem
# precisar editar os dois lados quando um canal muda. Requer o add-on
# Dispatcharr deste repositorio, com ao menos uma playlist ja importada.
#
# tvg_id_source=tvg_id e obrigatorio aqui: o padrao do Dispatcharr e
# channel_number (pensado pro Jellyfin, que casa o guia pelo numero do canal
# HDHomeRun, nao pelo tvg-id — ver dispatcharr/DOCS.md). Com channel_number o
# gerar-channels.mjs nao casa nada contra o catalogo do iptv-org, porque
# numero de canal nao e um id de canal. Isso so funciona se o tvg-id que ficou
# gravado em cada canal do Dispatcharr for compativel com o esquema do
# iptv-org (ex. "AmazonSat.br"), o que vale se a playlist importada la foi a
# br.m3u do iptv-org ou algo com os mesmos ids.
#
# Sem o Dispatcharr (ou rodando em outro host), volte para a lista estatica do
# iptv-org ou aponte para a M3U do seu proprio provedor:
#ENV PLAYLIST_URL="https://iptv-org.github.io/iptv/countries/br.m3u"

# Regera o channels.xml a partir da playlist antes de cada grab.
COPY gerar-channels.mjs /epg/gerar-channels.mjs
COPY pm2.config.js /epg/pm2.config.js
COPY grab.sh /epg/grab.sh

# Semente: se a geracao falhar na primeira execucao, o grab ainda tem o que ler.
COPY channels.xml /epg/public/channels.xml
