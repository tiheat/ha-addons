# Changelog

## 2.1.314.4
- Corrige ambientes que apareciam online no claude.ai/code mas não aceitavam
  sessões: o `claude remote-control --continue` reconectava só uma sessão e,
  se ela falhasse, ficava reiniciando em loop. Agora cada ambiente sempre sobe
  o `claude remote-control` normal; após um restart, uma sessão nova é criada
  (as anteriores continuam no histórico).

## 2.1.314.3
- `/media` passa a ser montada no add-on (gravações do Frigate etc.).
- Opção `media_access` (padrão desligada): libera `/media` para o Claude.
  Desligada, regras gerenciadas do Claude bloqueiam a pasta.
- Ao reiniciar, cada ambiente reconecta a sessão que estava aberta
  (`claude remote-control --continue`, até cerca de 4 horas depois) em vez de
  criar uma nova.

## 2.1.314.2
- Opção `machine_name` (padrão `home-assistant`): nome da máquina exibido no
  claude.ai/code no lugar do hostname `<hash>-claude-code`.

## 2.1.314.1
- Opção `session_name`: nome fixo da sessão do `/data/workspace` no
  claude.ai/code.
- Opção `workspaces`: pastas extras dentro de `/data/workspace` (por exemplo
  um repositório clonado), cada uma com seu próprio Remote Control e,
  portanto, um ambiente separado no claude.ai/code.

## 2.1.314
- Primeira versão: Claude Code 2.1.314 em `claude remote-control`, sempre
  ligado, com login e pasta de trabalho persistidos em `/data`.
- Modo controlado (padrão): processo sem privilégios, configurações somente
  leitura e sem token do Supervisor. Modo livre: root com escrita e CLI `ha`.
