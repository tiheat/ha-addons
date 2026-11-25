# Claude Code

Roda o [Claude Code](https://code.claude.com/docs) sempre ligado no Home
Assistant em modo [Remote Control](https://code.claude.com/docs/en/remote-control):
as sessões rodam aqui e você as abre e conversa com elas pelo
<https://claude.ai/code> ou pelo app do Claude no celular.

O Remote Control só faz conexões de saída (HTTPS): nenhuma porta é aberta e
não passa pelo Nginx Proxy Manager nem pelo Authelia.

## Requisitos

- Assinatura do claude.ai (Pro, Max, Team ou Enterprise). Chave de API e o
  token de `claude setup-token` **não** servem para o Remote Control.

## Primeiro uso (login)

O login é interativo e feito uma vez só; ele fica salvo em `/data/home`.

1. Instale e inicie o add-on. O log mostra `not logged in` e o comando abaixo.
2. Pelo SSH do host:

   ```bash
   sudo docker exec -it -u claude $(sudo docker ps -qf name=_claude_code) claude auth login
   ```

3. Abra a URL exibida, autorize e cole o código de volta no terminal.
4. Em até um minuto o add-on inicia o `claude remote-control`. A sessão
   aparece no claude.ai/code e no app com o prefixo `session_name_prefix`.

Reiniciar o add-on (ou atualizar) cria uma sessão nova em cada ambiente; as
anteriores continuam no histórico do claude.ai/code. Uma tarefa em andamento no
momento do restart é interrompida.

O login pode expirar; se as sessões sumirem, confira com
`claude auth status --text` (mesmo `docker exec`) e repita o passo 2.

## Modo controlado

| | Controlado (`controlled_mode: true`, padrão) | Livre (`controlled_mode: false`) |
| --- | --- | --- |
| Usuário do processo | `claude` (uid 1000) | `root` |
| `/homeassistant`, `/addon_configs`, `/share` | Somente leitura | Leitura e escrita |
| `/media` (com `media_access: true`) | Somente leitura | Leitura e escrita |
| Token do Supervisor (CLI `ha`, API do Core) | Não recebe | Recebe |
| `/data/workspace` (repositórios) | Leitura e escrita | Leitura e escrita |

A trava do modo controlado é do sistema operacional, não do Claude: os
arquivos montados pertencem ao root com permissão 644 e o processo roda sem
privilégios, sem binários setuid e com a senha do root bloqueada. Por cima disso
há regras `deny` em `/etc/claude-code/managed-settings.json`, que o Claude não
consegue sobrescrever, e um `CLAUDE.md` gerenciado explicando o modo atual.
Nenhuma dessas camadas impede **leitura**: no modo controlado o Claude ainda vê
a configuração (inclusive `secrets.yaml` via shell).

Trocar de modo: mude a opção na UI do add-on e reinicie. As sessões abertas
caem e voltam já no novo modo. Arquivos criados pelo root no modo livre dentro
de `/data` voltam para o usuário `claude` no próximo início controlado.

## Opções

| Opção | Para que serve |
| --- | --- |
| `controlled_mode` | Liga/desliga o modo controlado (acima). |
| `media_access` | Libera `/media` (gravações do Frigate etc.) para o Claude (padrão desligado; veja abaixo). |
| `permission_mode` | Modo de permissão das sessões (`default`, `acceptEdits`, `auto`, `plan`, `dontAsk`, `bypassPermissions`). No modo livre `bypassPermissions` cai para `default`, porque o Claude Code recusa esse modo como root. |
| `machine_name` | Nome da máquina no claude.ai/code (padrão `home-assistant`; vazio usa o hostname do container). |
| `session_name_prefix` | Prefixo dos nomes das sessões no claude.ai/code. |
| `session_name` | Nome fixo da sessão do `/data/workspace` (opcional). |
| `workspaces` | Pastas extras dentro de `/data/workspace`, cada uma como um ambiente separado no claude.ai/code (veja abaixo). |

### Acesso a `/media` (`media_access`)

O Home Assistant não deixa uma opção mudar as pastas montadas no add-on, então
`/media` está sempre montada. Com `media_access: true` o Claude a usa com o
mesmo acesso das outras pastas (somente leitura no modo controlado, escrita no
modo livre). Desligada (padrão), regras `deny` gerenciadas bloqueiam leitura e
edição ali e o `CLAUDE.md` avisa para não usar. Esse bloqueio é do Claude, não
do sistema operacional: um comando de shell ainda alcança a pasta. Mude a opção
e reinicie o add-on.

### Ambientes extras (`workspaces`)

Cada item roda seu próprio `claude remote-control` na pasta indicada, então
ela aparece como um ambiente à parte no claude.ai/code e as sessões abertas
nele começam já dentro dela. `path` é relativo a `/data/workspace` e a pasta
precisa existir (clone o repositório antes, por exemplo de uma sessão do
ambiente principal); pastas inexistentes são ignoradas com um aviso no log.

```yaml
workspaces:
  - path: ha-addons
    name: ha-addons
```

O nome da **máquina** exibido no claude.ai/code vem da opção `machine_name`
(padrão `home-assistant`). O hostname real do container (`<hash>-claude-code`)
é definido pelo Supervisor e não pode ser trocado de dentro dele, então o
add-on sobrescreve o valor que o Claude Code lê da libc (`uname`/`gethostname`)
via `LD_PRELOAD`. Deixe a opção vazia para voltar ao hostname. Ao trocar o
nome, o claude.ai/code pode passar a mostrar um ambiente novo; o antigo fica
offline e pode ser ignorado.

## Onde ficam os dados

Tudo em `/data`, incluído nos backups do add-on:

| Caminho | Conteúdo |
| --- | --- |
| `/data/home/.claude/.credentials.json` | Login do claude.ai |
| `/data/home/.claude.json` | Estado do Claude Code (pasta de trabalho já marcada como confiável) |
| `/data/workspace` | Pasta de trabalho das sessões; clone repositórios aqui (e aponte `workspaces` para eles) |

## Atualizando

O auto-update está desligado. Para subir de versão, troque
`ARG CLAUDE_CODE_VERSION` no `Dockerfile` e a `version` no `config.yaml`.
