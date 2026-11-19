# Authelia

Portal de login unico (SSO) com passkey. O Nginx Proxy Manager pergunta ao
Authelia, a cada requisicao, se o usuario esta autenticado (forward auth);
sem sessao, o navegador e levado para `https://auth.<dominio>`.

## Primeira inicializacao

1. Preencha `domain` (ex.: `home.example.com`) e `admin_user` e inicie.
2. O add-on cria em `/addon_configs/08ac8ee6_authelia`:
   - `configuration.yml` a partir do modelo, com o dominio aplicado;
   - `users_database.yml` com o usuario admin no grupo `admins`;
   - `secrets/` com os segredos de JWT, sessao e criptografia do banco;
   - `secrets/initial_password`, a senha inicial do admin.
3. Publique `auth.<dominio>` no Nginx Proxy Manager apontando para
   `http://08ac8ee6-authelia:9091` (com WebSockets).
4. Entre em `https://auth.<dominio>` com a senha inicial, registre um passkey
   em **Settings → Two-Factor Authentication** e apague
   `secrets/initial_password`.

Sem SMTP, os codigos de verificacao (pedidos ao registrar um passkey) sao
gravados em `/addon_configs/08ac8ee6_authelia/notification.txt`.

As opcoes `domain` e `admin_user` so valem na primeira inicializacao. Depois,
edite os arquivos em `/addon_configs/08ac8ee6_authelia` e reinicie o add-on
(mudancas em `users_database.yml` sao recarregadas sozinhas).

## Proteger um proxy host no Nginx Proxy Manager

Crie `/addon_configs/a0d7b954_nginxproxymanager/nginx/snippets/authelia.conf`:

```nginx
location = /internal/authelia/authz {
    internal;
    auth_request off;
    set $authelia_upstream http://08ac8ee6-authelia:9091;
    proxy_pass $authelia_upstream/api/authz/auth-request;
    proxy_pass_request_body off;
    proxy_http_version 1.1;
    proxy_set_header X-Original-Method $request_method;
    proxy_set_header X-Original-URL $scheme://$http_host$request_uri;
    proxy_set_header X-Forwarded-For $remote_addr;
    proxy_set_header Content-Length "";
    proxy_set_header Connection "";
    # Nunca repasse credenciais Basic guardadas pelo navegador (ex.: de uma
    # access list antiga): o Authelia as trata como tentativas de login e
    # bloqueia o usuario apos algumas falhas.
    proxy_set_header Authorization "";
    proxy_set_header Proxy-Authorization "";
}

auth_request /internal/authelia/authz;
auth_request_set $redirection_url $upstream_http_location;
error_page 401 =302 $redirection_url;
```

e, na aba **Advanced** do proxy host (sem access list):

```nginx
include /config/nginx/snippets/authelia.conf;
```

O upstream fica numa variavel para o nginx resolve-lo em tempo de requisicao:
se o Authelia estiver parado, so os hosts protegidos falham, e o nginx
continua subindo.

## Usuario bloqueado

Apos 5 falhas em 2 minutos o usuario fica bloqueado por 10 minutos. Para
liberar antes:

```bash
sudo docker exec -e AUTHELIA_STORAGE_ENCRYPTION_KEY_FILE=/config/secrets/storage \
  app_08ac8ee6_authelia authelia storage bans user revoke <usuario> \
  --config /config/configuration.yml
```

## Usuarios e grupos

```yaml
users:
  fulano:
    displayname: Fulano
    password: '<hash>'   # authelia crypto hash generate argon2
    groups: [familia]
```

As regras de `access_control` em `configuration.yml` liberam dominios por
grupo; o que nao casa com nenhuma regra e negado.
