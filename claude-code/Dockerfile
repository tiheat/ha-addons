FROM alpine:3.22 AS hostname
RUN apk add --no-cache gcc musl-dev
COPY hostname/hostname.c /src/
RUN gcc -shared -fPIC -O2 -o /libhostname.so /src/hostname.c

FROM alpine:3.22

# bash e curl sao os requisitos documentados do instalador no Alpine;
# libgcc/libstdc++ cobrem o runtime C++ do binario musl. su-exec derruba os
# privilegios no modo controlado.
RUN apk add --no-cache \
      bash ca-certificates coreutils curl git github-cli jq less libgcc \
      libstdc++ openssh-client procps python3 ripgrep su-exec tzdata yq

# Versao fixa do Claude Code: atualize trocando o ARG e a `version` do
# config.yaml. O instalador oficial baixa o binario e confere o checksum; o
# binario vai para /usr/local/bin e o auto-update fica desligado.
ARG CLAUDE_CODE_VERSION=2.1.314
RUN HOME=/tmp/claude-install bash -c \
      'curl -fsSL https://claude.ai/install.sh | bash -s "$0"' "$CLAUDE_CODE_VERSION" \
 && install -m 0755 "$(readlink -f /tmp/claude-install/.local/bin/claude)" /usr/local/bin/claude \
 && rm -rf /tmp/claude-install \
 && /usr/local/bin/claude --version

# CLI `ha` do Supervisor (so funciona no modo livre, que recebe o token).
ARG HA_CLI_VERSION=5.6.0
RUN case "$(apk --print-arch)" in \
      x86_64) arch=amd64 ;; aarch64) arch=aarch64 ;; *) exit 1 ;; \
    esac \
 && curl -fsSL -o /usr/local/bin/ha \
      "https://github.com/home-assistant/cli/releases/download/${HA_CLI_VERSION}/ha_${arch}" \
 && chmod 0755 /usr/local/bin/ha

# Usuario sem privilegios do modo controlado. Root sem senha e nenhum binario
# setuid, para nao haver caminho de volta ao root dentro do container.
RUN adduser -D -u 1000 -h /data/home -s /bin/bash claude \
 && passwd -l root \
 && find / -xdev -perm -4000 -type f -exec chmod u-s {} + 2>/dev/null; true

ENV TZ=America/Bahia \
    DISABLE_AUTOUPDATER=1 \
    DISABLE_UPDATES=1

# Shim do LD_PRELOAD que troca o nome da maquina (opcao machine_name).
COPY --from=hostname /libhostname.so /usr/local/lib/libhostname.so

COPY run.sh /run.sh
COPY supervise.sh /usr/local/bin/supervise.sh
RUN chmod +x /run.sh /usr/local/bin/supervise.sh

CMD ["/run.sh"]
