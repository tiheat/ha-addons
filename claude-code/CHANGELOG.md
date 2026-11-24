# Changelog

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
