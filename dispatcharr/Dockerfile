FROM ghcr.io/dispatcharr/dispatcharr:latest

# Modo all-in-one: nginx, postgres, redis e celery sobem dentro do proprio
# container. O Home Assistant ja monta um volume persistente em /data, que e
# exatamente onde o Dispatcharr guarda banco, cache e configuracao.
ENV DISPATCHARR_ENV=aio \
    REDIS_HOST=localhost \
    CELERY_BROKER_URL=redis://localhost:6379/0 \
    DISPATCHARR_LOG_LEVEL=info \
    TZ=America/Bahia \
    DISPATCHARR_TRUSTED_PROXIES=172.30.32.0/23

# Atras de proxy reverso: informe o IP ou CIDR do proxy para que Network
# Access, Stats e os limites de taxa enxerguem o IP real do cliente em vez do
# IP do proxy. Use `none` para ignorar cabecalhos encaminhados.
#ENV DISPATCHARR_TRUSTED_PROXIES=192.168.31.0/24

# Em maquina apertada, reduza os workers (padrao: 4 uWSGI e ate 6 Celery).
#ENV UWSGI_WORKERS=2 \
#    CELERY_MAX_WORKERS=2
