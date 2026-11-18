# Torrent Indexer (Home Assistant Add-on)

Converted from felipemarinho97/torrent-indexer's docker-compose.yml.

## How it works

The compose file runs two containers: `torrent-indexer` and `redis`. A Home
Assistant add-on is a single container, so this Dockerfile:

1. Rebuilds `torrent-indexer` from its own source (same multi-stage build
   the project itself uses: `golang:1.24` builder → `alpine:latest` runtime),
   instead of just reusing the published image, so Redis can be added into
   the same final image.
2. Installs `redis-server` in that Alpine runtime stage.
3. Uses `run.sh` as the container's entrypoint: it starts
   `redis-server --daemonize yes` bound to `127.0.0.1:6379`, then `exec`s
   `/root/app` (the compiled binary, passed through as the Dockerfile's
   `CMD`).
4. `REDIS_HOST` is set to `127.0.0.1` instead of `redis`, since both now run
   in the same container rather than on the compose network.
5. Port `7006` (the app's internal port) is exposed and mapped to host port
   `8080` in `config.yaml`, matching the original `8080:7006`.

## Not included

- **FlareSolverr**: `FLARESOLVERR_ADDRESS=http://flaresolverr:8191` is kept
  as an env var, but FlareSolverr itself isn't bundled here (it wasn't
  active in your compose file either — it's referenced but never defined
  as a service). Point it at a FlareSolverr instance elsewhere on your
  network, or run one as a separate add-on/container.
- **Meilisearch** and **Magnet Metadata API**: both were commented out in
  the compose file, so they're left out here too. If you want them, they'd
  need to be added as separate add-ons (or additional processes started
  from `run.sh`), since a HA add-on is one container.

## Installing in Home Assistant

1. Copy this folder into `/addons/torrent-indexer-addon` on your Home
   Assistant host (via Samba, SSH, or the Studio Code Server add-on), or
   put it in a local add-ons Git repository.
2. **Settings → Add-ons → Add-on Store → ⋮ → Repositories**, add the repo
   (or just refresh if using the local `/addons` folder).
3. Install "Torrent Indexer" under Local add-ons, then start it.
4. `log_level` in the add-on's Configuration tab maps to `LOG_LEVEL`
   (0=debug, 1=info, 2=warn, 3=error).
5. Open it at `http://<home-assistant-ip>:8080`.
