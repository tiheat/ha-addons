# LLDAP

Servidor LDAP leve com interface web para gerenciar usuarios e grupos. Serve
de base de usuarios para o Authelia (e para qualquer app que fale LDAP).

## Primeira inicializacao

1. Preencha as opcoes e inicie:
   - `domain` (ex.: `home.example.com`): vira o base DN `dc=home,dc=example,dc=com`
     e a URL publica `https://lldap.<domain>`;
   - `admin_user` / `admin_email` (opcionais): usuario pessoal criado no grupo
     `admin_group`;
   - `admin_group` (padrao `admins`).
2. O add-on cria em `/addon_configs/08ac8ee6_lldap`:
   - `lldap_config.toml` (modelo oficial; dominio, banco e segredos vem de
     variaveis de ambiente);
   - `users.db` (SQLite);
   - `secrets/`: `jwt_secret`, `key_seed`, `admin_password` (usuario `admin`
     da interface), `authelia_bind_password` e
     `initial_password_<admin_user>`.
3. Bootstrap (so uma vez, marcado por `.bootstrap_done`): grupo `admin_group`,
   conta de servico `authelia` no grupo `lldap_strict_readonly` (so leitura) e
   o `admin_user`, se informado.

Publique a interface pelo Nginx Proxy Manager em `https://lldap.<domain>`,
apontando para `http://08ac8ee6-lldap:17170`. Recomendado: **fora** do
Authelia, com o login proprio do LLDAP, para nao perder o acesso a ferramenta
que corrige usuarios caso o Authelia ou o LDAP falhem.

Troque as senhas iniciais pela interface e apague os arquivos
`initial_password_*`.

## Authelia

```yaml
authentication_backend:
  password_reset:
    disable: true
  ldap:
    implementation: lldap
    address: ldap://08ac8ee6-lldap:3890
    base_dn: dc=home,dc=example,dc=com
    user: uid=authelia,ou=people,dc=home,dc=example,dc=com
```

A senha da conta de servico vai por arquivo, com
`AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE` apontando para uma copia
de `authelia_bind_password`. Os grupos do LLDAP aparecem como `group:<nome>`
nas regras de `access_control`.

## Notas

- O LLDAP guarda em `/app/server_key` a chave derivada de `key_seed` e se
  recusa a subir quando os dois existem; o `run.sh` apaga esse cache antes de
  iniciar. A fonte da verdade e `secrets/key_seed`: nao a perca, ou todas as
  senhas deixam de valer.
- Admin perdido: grave a nova senha em `secrets/admin_password`, adicione
  `force_ldap_user_pass_reset = true` em `lldap_config.toml`, reinicie e
  remova a linha.
