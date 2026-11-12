# Relatório de recuperação e port

Este relatório registra a primeira entrega, com os testes de servidor dedicado. Consulte a [revisão do cliente de 05/11/2026](REVISAO-CLIENTE.md) para as correções posteriores e os resultados gráficos.

O tModLoader estável publicado e instalado na máquina durante os testes era 2026.9.3.1 para Terraria 1.4.4.9. A referência são as 60 entradas do documento de continuidade. A Rev8 representa 59 dessas entradas no perfil TodosRecuperados, com as equivalências detalhadas no inventário. O Ampliado representa 56. Os demais mods ativos são integrações, bibliotecas e correções locais.

## Identidades e substituições

- **Calamity Mage Addon**, Workshop 3415536524. O SteamCMD retornou `File Not Found` e a publicação não forneceu um binário. A entrada continua registrada sem port.
- **Calamity Entropy**. Foi usada a linha Legacy 3.39, recuperada na Workshop 3800924812, com o patch 3.39.1. A publicação original mudou de linha para Call of Void.
- **Calamity Magic Storage**. O binário experimental 0.3 é o backup da Workshop 3499799348. A fonte original encontrada é da versão 0.1. A inspeção do backup mostrou validação do tile contra o Storage Unit base e mais de um caminho de consumo do upgrade. O teste de reabertura do mundo não exercita essas operações.
- **Convergence**. O REDUX 1.0 carrega com os outros mods. O ID da publicação histórica exata não consta na lista original.
- **readability**. O nome interno do binário usado é `AbilityToRead` e o servidor registra o título `readAbility`. A equivalência é a adotada pela auditoria anterior.

## Testes dedicados

Os ensaios foram executados em cópias locais do runtime e em diretórios de dados isolados. A configuração do servidor contém `difficulty=1` e a criação registra `IsExpert: True`. Todos os testes de servidor usaram loopback.

| Ensaio | Perfil | Resultado |
|---|---|---|
| Todos os binários recuperados, antes dos ports | 69 | Carregou, gerou mundo Large Expert, iniciou e salvou ao encerrar |
| Ampliado, com ports | 67 | Carregou, gerou mundo Large Expert, iniciou e salvou ao encerrar |
| TodosRecuperados, com ports | 70 | Reabriu uma cópia do mundo Expert do primeiro teste, iniciou com a lista inteira ativa e salvou ao encerrar |

O launcher preparou os dois perfis no Windows PowerShell 5.1 e verificou a integridade de cada .tmod e das dependências. O [resumo de testes](evidence/resumo-testes.json) reúne os resultados registrados nos logs.

Comparação das ocorrências registradas no primeiro ensaio e no Ampliado:

| Sinal no log | Antes | Ampliado |
|---|---:|---:|
| Census `TownNPCCondition`, registros de nível ERROR | 2 | 0 |
| InnoVault `OutlineShader` sem setter | 1 | 0 |
| Construtores ausentes de `PRT_Light` e `PRT_Spark` | 2 | 0 |
| Calamity rejeitando `SetDamageReductionSpecific` | 21 | 0 |
| Banner inconsistente de `ScraperOfStarsTail` | 1 | 0 |
| Registros de nível ERROR do GodSmith no Overhaul | 5 | 5 |

O ajuste de SelfRig foi compilado e carregado. A seleção pelo cursor e os efeitos no personagem precisam de teste em jogo. Os cinco registros do GodSmith envolvem peças compartilhadas de Beetle e Spectre. O registro mantém a primeira associação e exige validação das variantes de conjunto e dos efeitos herdados.

O log também mostra hooks do Inheritance e de Ragnarok que não encadeiam a chamada anterior em certos métodos. Isso aponta locais para testar armas, acessórios e efeitos. A geração do mundo não exercita essas funções. Os avisos de clonagem de itens e outros avisos dos mods base também continuam.

O ensaio paralelo encontrou uma falha de Subworld Library. A segunda instância do servidor tentou abrir um canal de submundos já ocupado pela primeira. O tModLoader desativou a biblioteca e seus dependentes e encontrou um registro duplicado em Fables ao recarregar. Interrompi o ensaio, restaurei o mundo de teste da cópia e reativei a lista de 70 mods para repetir com um servidor por vez. O launcher verifica processos de servidor e usa um mutex para evitar dois servidores da Rev8 simultâneos. A tentativa de iniciar um segundo servidor pelo launcher foi recusada como esperado.

## Antes de uma campanha

O Ampliado separa o DLC oficial do Fargo, Infernum e o backup do Calamity Magic Storage. O primeiro ensaio mostrou que a combinação completa pode carregar e gerar mundo. As restrições de IA declaradas pelo DLC e a falta de suporte multiplayer do Infernum continuam pertinentes durante lutas. O perfil TodosRecuperados serve para validar essas combinações sem misturar seus saves com os do Ampliado.

O teste dedicado não exercitou um cliente gráfico nem a entrada de dois jogadores. O InnoVault informou que seu diretor de cenários permanece inativo em multiplayer. Ainda faltam lutas, submundos, equipamentos em loadouts, uso concorrente de armazenamento, verificação visual de estruturas e medição de FPS. Para testar Ore Excavator, confira drops e sincronização antes de misturá-lo com o BAM na campanha. Para verificar os slots adicionais, teste a persistência de personagens e os efeitos de acessórios. O preset de More Accessories usa três slots e suporte a loadouts desligado.

Fontes principais sobre o alvo e as restrições:

- [tModLoader 2026.09.3.1](https://github.com/tModLoader/tModLoader/releases/tag/v2026.09.3.1)
- [DLC oficial Calamity–Fargo](https://steamcommunity.com/sharedfiles/filedetails/?id=3044249615)
- [Aviso de multiplayer do Infernum](https://raw.githubusercontent.com/InfernumTeam/InfernumMode/master/Localization/en-US.hjson)
- [Backup do Calamity Magic Storage](https://steamcommunity.com/sharedfiles/filedetails/?id=3499799348)
- [Issue de SelfRig do Overhaul](https://github.com/hocha113/CalamityOverhaul/issues/121)
