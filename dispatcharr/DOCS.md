# Dispatcharr

Empacota o [Dispatcharr](https://github.com/Dispatcharr/Dispatcharr) em modo
all-in-one como add-on local: nginx, postgres, redis, celery e uwsgi sobem
dentro do mesmo container.

O Home Assistant monta um volume persistente em `/data`, que é exatamente onde
o Dispatcharr guarda banco, cache e configuração — então os dados sobrevivem a
restart e a rebuild.

## Primeiro uso

Abra a interface em `http://<host>:9191` e crie a conta de administrador. Em
seguida, em **M3U & EPG Manager**, adicione a playlist e a fonte de EPG.

Se o EPG Grabber deste mesmo repositório estiver instalado, a fonte é
`http://local-epg-grabber:3000/guide.xml` — os dois add-ons se enxergam pela
rede interna, sem depender de porta publicada.

## Ligando no Jellyfin

Em **Channels → Links**, copie as URLs do perfil:

- **HDHR** → Jellyfin, em Sintonizadores → Adicionar → HDHomeRun
- **EPG** → Jellyfin, em Provedores de Dados do Guia → XMLTV

Os endpoints diretos são `/hdhr` e `/output/epg`, com `/<perfil>` opcional.

O parâmetro `tvg_id_source` aceita `channel_number` (padrão), `tvg_id` e
`gracenote`. Mantenha o padrão: o Jellyfin casa o guia com o tuner HDHomeRun
pelo número do canal do `lineup.json`, não pelo `tvg-id`. E use **o mesmo
perfil (ou nenhum) nas duas URLs** — se a numeração divergir, o guia aparece
vazio.

## Variáveis úteis

Estão comentadas no `Dockerfile`:

| Variável | Para que serve |
| --- | --- |
| `DISPATCHARR_TRUSTED_PROXIES` | Atrás de proxy reverso, informa o IP/CIDR do proxy para que Network Access, Stats e limites de taxa vejam o IP real do cliente |
| `UWSGI_WORKERS` | Workers uWSGI (padrão 4) |
| `CELERY_MAX_WORKERS` | Workers Celery (padrão 6) |

Os dois últimos ajudam em máquina apertada — o modo all-in-one não é modesto
nos padrões.

## Fechar a porta do host

`ports: 9191/tcp: null` tira a porta do host e deixa o serviço só na rede
interna, em `http://local-dispatcharr:9191`. **Atenção:** isso também tira a
interface web do navegador. Só faz sentido se houver um proxy reverso na mesma
rede publicando o serviço. Nesse caso remova também as chaves `webui` e
`watchdog`, que dependem da porta publicada.

## Rodando fora do Home Assistant

`docker-compose.example.yml` traz o equivalente pra um NAS ou outro host com
Docker. Vale considerar: o all-in-one é a peça mais pesada de um homelab
pequeno, e tirá-lo do mesmo host que roda o Home Assistant costuma ser um bom
negócio.
