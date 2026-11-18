# Changelog

## 1.9.3
- Installed from the `tiheat/ha-addons` GitHub repository instead of `/addons`:
  the default `playlist_url` now points to `08ac8ee6-dispatcharr`, the
  hostname of the Dispatcharr add-on installed from that repository.

## 1.9.2
- `playlist_url`, `epg_gen_args`, `cron_schedule`, `run_at_startup`, `days`,
  `max_connections`, `delay` e `tz` viraram opções na aba **Configuration**
  do add-on: o `pm2.config.js` lê `/data/options.json` e as aplica como ENV
  antes de montar os processos. Mudar essas variáveis não exige mais editar
  `Dockerfile` nem subir versão nova — só um **Restart**. O `Dockerfile`
  mantém o mesmo `ENV` como fallback pra quem roda fora do Home Assistant.
- `PLAYLIST_URL` passa a apontar para o próprio Dispatcharr
  (`http://local-dispatcharr:9191/output/m3u?tvg_id_source=tvg_id`) em vez da
  lista estática do iptv-org: o `channels.xml` agora acompanha os canais que
  existem lá. O `tvg_id_source=tvg_id` é obrigatório — sem ele o Dispatcharr
  exporta o número do canal como `tvg-id` (padrão dele, pensado pro Jellyfin)
  e nenhum canal casa com o catálogo do iptv-org.
- Removido o modo `SITES` do `grab.sh`, que ignorava silenciosamente o
  `channels.xml` e buscava só os sites listados nele — indocumentado e foi a
  causa de um grab que só tentava `tv.mail.ru` (site com o scraper quebrado a
  montante, 404 em toda página) e nunca usava a lista curada de canais.
- `tv.mail.ru` entrou em `EXCLUIDOS_PADRAO` do `gerar-channels.mjs`: mesmo
  fora do modo `SITES`, ele podia ser escolhido como única fonte de algum
  canal do Dispatcharr sem cobertura em outro site, e travava o grab inteiro
  porque o 404 nunca sinaliza fim de paginação.

## 1.8.1
- `webui` apontando para a listagem de `public/`, habilitando o botão "Abrir
  interface web".

## 1.8.0
- Descrição reescrita, `url` para o projeto upstream, `icon.png` e `logo.png`.
- Opção de fechar a porta do host documentada no `config.yaml`.

## 1.7.1
- `watchdog: tcp://[HOST]:[PORT:3000]`. Sem a chave, o watchdog agia apenas
  pelo estado do container, o que provavelmente causou o kill com código 137
  no meio de um grab.
- Corrigido comentário do Dockerfile que atribuía a redução de `DAYS` a
  economia de memória. O log do host não tinha registro de OOM.

## 1.7.0
- `DAYS=3`, `MAX_CONNECTIONS=2`, `DELAY=500`: menos requisição desperdiçada e
  menos exposição a 429. Com a lista completa, `DAYS=7` gerava 819 pedidos por
  ciclo, e o Pluto TV — a maior fatia — só entrega grade cheia no dia corrente.
- `sat.tv` na lista de sites excluídos.

## 1.6.0
- `meuguia.tv` excluído por padrão e o parser remendado removido. Nenhum
  arquivo do upstream é mais sobrescrito por correção. Custo: a Band perde
  guia, por não existir feed nacional no mi.tv.

## 1.5.0
- `channels.xml` passa a ser gerado antes de cada grab, a partir de
  `PLAYLIST_URL`. Fim da etapa manual.
- `grab.sh`: a sequência ficou num script porque o pm2 executa o comando sem
  shell, e `||` e `;` viravam argumento literal.

## 1.4.0
- `tvg-logo` na playlist, a partir do `logos.csv` do iptv-org/database.

## 1.3.0
- `channels.xml` com mi.tv, meuguia.tv e pluto.tv convivendo; de 8 para 11
  canais com guia.
- Corrigido o `tvg-id` da TVE RS, que o iptv-org rotulava como TVE Bahia.

## 1.2.0
- A playlist passa a ser servida junto com o guia em `public/`.

## 1.1.0
- Correção do parser do meuguia.tv (mês sem zero à esquerda).

## 1.0.0
- Primeira versão: iptv-org/epg com `channels.xml` fixo.
