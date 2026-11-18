# EPG Grabber (XMLTV)

Empacota o [iptv-org/epg](https://github.com/iptv-org/epg) e acrescenta a etapa
que falta nele: descobrir sozinho **quais** canais buscar.

## Como funciona

A cada execução, antes do grab:

1. Baixa a playlist indicada em `PLAYLIST_URL` e extrai os `tvg-id`.
2. Consulta o catálogo `guides.json` da API do iptv-org, que diz qual site de
   programação cobre cada canal.
3. Escreve o `channels.xml` com o mapeamento, usando o `tvg-id` da playlist
   como `xmltv_id` — assim o casamento no cliente é por igualdade, não por
   similaridade.
4. Roda o grab e publica o `guide.xml`.

Se a geração falhar, o `channels.xml` anterior é preservado e o grab roda com
ele, em vez de a execução ser pulada.

## Sincronizando com o Dispatcharr

Por padrão, `PLAYLIST_URL` aponta para a própria M3U que o Dispatcharr exporta
(`/output/m3u?tvg_id_source=tvg_id`), na rede interna dos add-ons. Assim o
`channels.xml` sempre reflete os canais e `tvg-id` que existem no Dispatcharr
agora — adicionar, remover ou renomear um canal lá já é o suficiente, sem
editar nada aqui.

O `?tvg_id_source=tvg_id` é obrigatório: o padrão do Dispatcharr é
`channel_number` (pensado pro Jellyfin, que casa pelo número do canal
HDHomeRun — veja `dispatcharr/DOCS.md`), e número de canal não é um id que o
catálogo do iptv-org reconhece. Sem esse parâmetro, todo canal sai sem fonte
de EPG, mesmo com o Dispatcharr respondendo normalmente.

Isso também só funciona se o `tvg-id` gravado em cada canal do Dispatcharr for
compatível com o esquema do iptv-org (ex. `AmazonSat.br`), o que vale quando a
playlist importada lá foi a `br.m3u` do iptv-org ou outra com os mesmos ids.
Se os canais do Dispatcharr usam outro esquema de `tvg-id`, a geração continua
achando 0 canais com fonte — nesse caso volte para a lista estática do
iptv-org ou aponte para a M3U do seu provedor, como no exemplo comentado no
`Dockerfile`.

Isso exige o add-on Dispatcharr deste mesmo repositório, com ao menos uma
playlist importada.

## Endereços

Com a porta publicada:

- `http://<host>:3000/guide.xml` — o guia
- `http://<host>:3000/channels.xml` — o mapeamento gerado, útil pra conferir
- `http://<host>:3000/` — listagem do diretório

Na rede interna dos add-ons: `http://08ac8ee6-epg-grabber:3000/…`

## Configuração

Todas as variáveis abaixo ficam na aba **Configuration** do add-on, na
interface do Home Assistant — não precisa mais editar `Dockerfile` nem fazer
rebuild para mudar playlist, horário do cron, etc. Depois de salvar, um
**Restart** já aplica (o `pm2.config.js` lê `/data/options.json` antes de
montar os processos).

| Opção | Padrão | Para que serve |
| --- | --- | --- |
| `playlist_url` | `http://08ac8ee6-dispatcharr:9191/output/m3u?tvg_id_source=tvg_id` | Playlist de origem. Vazio desativa a geração e usa o `channels.xml` do disco |
| `epg_gen_args` | — | Argumentos extras do gerador, ex. `--sites mi.tv` ou `--incluir-ip-nu` |
| `cron_schedule` | `0 6 * * *` | Quando coletar |
| `run_at_startup` | `true` | Coletar também ao iniciar |
| `days` | `3` | Dias de grade por canal |
| `max_connections` | `2` | Requisições simultâneas |
| `delay` | `500` | Espera entre requisições, em ms |
| `tz` | `America/Bahia` | Fuso |

`days`, `max_connections`, `delay`, `TIMEOUT` e `PROXY` são lidos pelo próprio
grabber via `commander` (`.env('DAYS')` etc) — os dois últimos não têm opção
na UI ainda, só dá pra setar direto no `Dockerfile` se precisar.

O `Dockerfile` mantém as mesmas variáveis em maiúsculo como `ENV`: elas só
valem como fallback para quem roda a imagem fora do Home Assistant (por
exemplo via `docker-compose`), onde não existe `/data/options.json`.

## O gerador

`gerar-channels.mjs` roda sozinho, sem dependências:

```sh
node gerar-channels.mjs <url-ou-arquivo.m3u> -o channels.xml \
  [--sites a,b] [--excluir a,b] [--lang pt] [--incluir-ip-nu]
```

Por padrão descarta entradas cujo stream é servido por IP nu (retransmissões
não autorizadas) e exclui três sites: `meuguia.tv`, cujo parser devolve
"Invalid time value" de janeiro a setembro por causa do mês sem zero à
esquerda; `sat.tv`, que responde 403 e depois 429; e `tv.mail.ru`, cujo
endpoint de agenda devolve 404 em toda página e nunca sinaliza fim de
paginação — se algum canal ficar sem outra fonte, o grab trava tentando essa
pra sempre.

Quando o mesmo canal aparece em vários sites, a ordem de preferência põe o
`mi.tv` na frente — nele a data vai na URL e os horários vêm em UTC, o que o
torna bem mais robusto que os que raspam cabeçalho em português.

## Limitações

- O `guide.xml` vive no filesystem do container. **Todo rebuild zera o
  arquivo**, e ele só reaparece ao fim de um grab bem-sucedido.
- Canais sem cobertura em nenhum dos sites do projeto ficam sem grade. Para
  esses, use o Dummy EPG do Dispatcharr.
