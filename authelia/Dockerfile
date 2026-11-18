FROM authelia/authelia:4.39.28

COPY configuration.yml /defaults/configuration.yml
COPY run.sh /run.sh
RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]
