# Builds felipemarinho97/torrent-indexer from source (same as its own Dockerfile)
# and adds Redis into the same image/container so it can run as a single
# Home Assistant add-on, instead of the two containers in the compose file.
FROM golang:1.24 AS builder

WORKDIR /go/src/app
RUN git clone --depth 1 --branch feature/fix-broken-br-indexers https://github.com/tiheat/torrent-indexer.git .

RUN go get -d -v ./...
RUN go install -v ./...
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

FROM alpine:latest
LABEL maintainer="felipevm97@gmail.com"

# ca-certificates: kept from the original Dockerfile (needed for outbound HTTPS)
# redis: added so REDIS_HOST=127.0.0.1 works inside this same container
RUN apk --no-cache add ca-certificates redis

WORKDIR /root/
COPY --from=builder /go/src/app/app .
COPY run.sh /run.sh
RUN chmod +x /run.sh

# Same environment variables as the docker-compose file, adjusted for a
# single-container setup (REDIS_HOST now points to localhost)
ENV LOG_LEVEL=0 \
    REDIS_HOST=127.0.0.1 \
    FLARESOLVERR_ADDRESS=http://app_db21ed7f_flaresolverr:8191 \
    LONG_LIVED_CACHE_EXPIRATION=24h \
    FALLBACK_TITLE_ENABLED=true \
    INDEXER_BLUDV_URL=https://bludvfilmes2.xyz/ \
    INDEXER_COMANDO_URL=https://comando1.com/ \
    INDEXER_STARCK_FILMES_URL=https://starckfilmes-v30.com/ \
    INDEXER_REDE_TORRENT_URL=https://redestorrents.com/ \
    INDEXER_VACA_TORRENT_URL=https://vaqueirofilmes.com/

EXPOSE 7006

ENTRYPOINT ["/run.sh"]
CMD ["/root/app"]
