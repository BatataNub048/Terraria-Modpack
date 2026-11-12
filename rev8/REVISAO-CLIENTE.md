# Revisão do cliente gráfico de 05/11/2026

## Correções instaladas

- **Munchies Calamity Addon 1.3.1.1.** A versão 1.3.1 tentava acessar os campos `bOrange`, `eBerry` e `dFruit`, ausentes no Calamity 2.2.4. O addon agora registra Sanguine Tangerine, Miracle Fruit, Tainted Cloudberry e Sacred Strawberry e consulta a API `HasPermanentPowerup` para ler o progresso dos consumíveis. O patch também faz o log incluir a exceção original caso a integração falhe no futuro.
- **Calamity Overhaul 0.9209.2.** O GodSmith reconhece as peças compartilhadas das variantes Beetle e Spectre e inclui as duas prévias de conjunto. A associação primária usada na herança de elmos continua determinística, e disputas de outras peças continuam aparecendo no log.
- **Configuração do Calamity Inheritance.** Os perfis usam `TurnOffFirstText=false` para desativar o texto introdutório que cobriu parte da tela nos ensaios. Confirmei a condição no binário da versão instalada. Os testes abaixo exercitaram os binários corrigidos antes desse ajuste visual.

A atualização inclui os dois manifests e os perfis já preparados. O tModLoader tinha desativado o Munchies Calamity Addon no Ampliado após a falha original. A atualização reativou essa entrada e guardou cópias verificadas dos arquivos substituídos em `backups`.

## Evidências

Os dois perfis passaram pelo JIT e pelo carregamento de mods no cliente gráfico em português com tModLoader 2026.9.3.1. Em cada perfil, selecionei ou reabri um personagem descartável e entrei em uma cópia de um mundo Expert. Nenhum mod foi desativado e não houve registro de nível ERROR nos logs finais.

| Perfil | Mods | Log |
|---|---:|---|
| Ampliado | 67 | [Cliente com as duas correções](evidence/ampliado-hotfix-client.log) |
| TodosRecuperados | 70 | [Cliente com as duas correções](evidence/todos-recuperados-hotfix-client.log) |

## Pendências identificadas

- O **Ore Excavator** avisou que o atalho de escavação está vazio. O **Quality of Terraria** abriu o aviso de atalho para seu painel. Para usar essas funções, escolha teclas livres em **Configurações → Controles → Controles de Mods**. Nenhum atalho pessoal foi sobrescrito.
- No perfil **TodosRecuperados**, o DLC oficial do Fargo exibiu no mundo o aviso de incompatibilidade com **Infernum**. O teste de entrada não certifica lutas ou progressão dessa combinação. O **Ampliado** continua sendo o perfil indicado para testar a campanha.
- A checagem gráfica cobriu abertura, carregamento e entrada no mundo. A confirmação do estado de cada consumível após uso, o SelfRig em combate, multiplayer e operações concorrentes no armazenamento precisam de ensaios específicos.
