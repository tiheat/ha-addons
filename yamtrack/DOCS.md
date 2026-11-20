# Yamtrack

Empacota o [Yamtrack](https://github.com/FuzzyGrim/Yamtrack) — rastreador de
filmes, séries, animes, mangás, jogos, livros e quadrinhos — como add-on, a
partir da imagem oficial `ghcr.io/fuzzygrim/yamtrack`.

O compose oficial usa dois containers (Yamtrack + Redis); aqui o Redis roda
dentro do mesmo container, só como cache e broker do Celery, sem persistência.

## Onde ficam os dados

Tudo no volume persistente `/data` do add-on, incluído nos backups do Home
Assistant:

| Caminho | Conteúdo |
| --- | --- |
| `/data/db/db.sqlite3` | Banco SQLite (contas, histórico, listas) |
| `/data/secrets/secret` | `SECRET_KEY` do Django, gerada na primeira inicialização |

Não apague `/data/secrets/secret`: trocar a chave derruba todas as sessões.

## Primeiro uso

1. Inicie o add-on e abra `http://<host>:8000`.
2. Clique em **Sign up** e crie sua conta.
3. Desligue a opção `registration` e reinicie, para ninguém mais se cadastrar.

## Opções

| Opção | Para que serve |
| --- | --- |
| `urls` | Endereços públicos pelos quais o Yamtrack é acessado via proxy reverso, separados por vírgula (ex.: `https://yamtrack.example.com`). Vira a variável `URLS`, que preenche `CSRF_TRUSTED_ORIGINS` e `ALLOWED_HOSTS`. Sem ela, login e formulários falham com erro 403 (CSRF) pelo domínio publicado. |
| `registration` | Permite criar contas novas. Deixe ligado só até criar a sua. |
| `tmdb_lang` | Idioma dos metadados de filmes e séries (ex.: `pt-BR`, `en`). Os metadados ficam em cache no Redis por algumas horas; reiniciar o add-on limpa o cache. |
| `steam_api_key` | Chave da [Steam Web API](https://steamcommunity.com/dev/apikey), necessária só para importar a biblioteca da Steam (vira `STEAM_API_KEY`). Opcional. |

## Importando da Steam

1. Gere a chave em <https://steamcommunity.com/dev/apikey> (o domínio pedido
   não é validado) e preencha `steam_api_key`; reinicie o add-on.
2. Em **Settings → Import → Steam**, informe o **Steam ID 64** (número de 17
   dígitos que começa com `7656…`, na página de detalhes da conta), não o
   nome de usuário.

Com uma chave da sua própria conta o perfil não precisa ser público. A
importação traz os jogos da biblioteca com o tempo jogado e busca cada um no
IGDB; a chave padrão do IGDB tem limite baixo, então bibliotecas grandes podem
precisar de uma segunda importação.

O fuso horário (`TZ=America/Bahia`) está no `Dockerfile`. Outras variáveis do
Yamtrack (chaves próprias de IGDB/Hardcover, `TRACK_TIME`, OIDC etc.) estão em
[env-variables](https://github.com/FuzzyGrim/Yamtrack/blob/main/docs/env-variables.md)
e podem ser adicionadas como `ENV` no `Dockerfile`.

## Publicando pelo Nginx Proxy Manager

- **Forward Hostname/IP:** `08ac8ee6-yamtrack`, porta `8000`, esquema `http`
  (rede interna dos add-ons; dispensa a porta publicada).
- Ative **Websockets Support** e **Block Common Exploits**.
- Preencha a opção `urls` com o endereço público.

O Yamtrack já tem login próprio. Colocar o Authelia na frente via forward auth
funciona, mas exige logar duas vezes; o caminho para login único é configurar o
Authelia como provedor OIDC
([social-auth](https://github.com/FuzzyGrim/Yamtrack/blob/main/docs/social-auth.md)).

## Fechar a porta do host

`ports: 8000/tcp: null` tira a porta do host e deixa o serviço só na rede
interna, em `http://08ac8ee6-yamtrack:8000`. Remova junto as chaves `webui` e
`watchdog` do `config.yaml`.

## Atualizando

Troque a tag em `FROM ghcr.io/fuzzygrim/yamtrack:<versão>` no `Dockerfile` e a
`version` no `config.yaml`. As migrações do banco rodam sozinhas na
inicialização — faça um backup do add-on antes de pular versões.
