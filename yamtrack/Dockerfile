FROM ghcr.io/fuzzygrim/yamtrack:0.26.3

# Redis (cache e broker do Celery) roda dentro do proprio container, em vez
# do segundo container do docker-compose oficial.
RUN apk add --no-cache redis

# O SQLite fica em /yamtrack/db; apontado para o volume persistente /data que
# o Home Assistant monta, os dados sobrevivem a restart, rebuild e update.
RUN rm -rf /yamtrack/db && ln -s /data/db /yamtrack/db

ENV TZ=America/Bahia \
    REDIS_URL=redis://127.0.0.1:6379

COPY run.sh /run.sh
RUN chmod +x /run.sh

CMD ["/run.sh"]
