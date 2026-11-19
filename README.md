# tiheat Home Assistant Add-ons

Custom Home Assistant add-ons, previously kept as local add-ons in `/addons`.

| Add-on | Folder | Upstream |
| --- | --- | --- |
| Torrent Indexer (with bundled Redis) | [`br-torrent-indexer`](br-torrent-indexer) | [felipemarinho97/torrent-indexer](https://github.com/felipemarinho97/torrent-indexer) |
| Dispatcharr | [`dispatcharr`](dispatcharr) | [Dispatcharr/Dispatcharr](https://github.com/Dispatcharr/Dispatcharr) |
| EPG Grabber (XMLTV) | [`epg-grabber`](epg-grabber) | [iptv-org/epg](https://github.com/iptv-org/epg) |
| Authelia (SSO com passkey) | [`authelia`](authelia) | [authelia/authelia](https://github.com/authelia/authelia) |
| LLDAP (usuarios e grupos) | [`lldap`](lldap) | [lldap/lldap](https://github.com/lldap/lldap) |

## Installation

[![Add repository](https://my.home-assistant.io/badges/supervisor_add_addon_repository.svg)](https://my.home-assistant.io/redirect/supervisor_add_addon_repository/?repository_url=https%3A%2F%2Fgithub.com%2Ftiheat%2Fha-addons)

Or: **Settings → Add-ons → Add-on Store → ⋮ → Repositories** and add
`https://github.com/tiheat/ha-addons`.

Add-ons are built locally on the Home Assistant host from each folder's `Dockerfile`.
Bump `version` in the add-on's `config.yaml` to make Home Assistant offer the update.
