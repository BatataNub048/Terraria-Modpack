# Ensaios de CPU, renderização e chefes — 7 de novembro de 2026

**A meta de manter no mínimo 120 FPS durante chefes não foi atingida.** Foram testados renderização acima de 60 FPS, dois renderizadores, caches, um limitador corrigido, servidor local, resolução reduzida e uma nova política de históricos de projéteis. Os 71 mods de conteúdo e utilidades foram mantidos. As opções de FPS alto e o laboratório ficaram fora das campanhas jogáveis.

## O que está disponível para jogar

O perfil `TodosRecuperados-Titanico-Desempenho` usa **TerrariaPackCompat 1.2.0**, com fonte, payload fixado por hash e launcher próprio. Ele contém as seis otimizações descritas em [DESEMPENHO.md](DESEMPENHO.md), além da correção anterior do Whips. A comparação repetida na mesma sessão mostrou aproximadamente **49,1 → 51,1 FPS** na base, com os mesmos ajustes e posição. É uma melhoria modesta, não uma solução para 120 FPS.

O launcher é `Jogar-TodosRecuperados-Titanico-Desempenho.bat`. A cópia independente já foi preparada. Os quatro perfis anteriores continuam disponíveis e seus manifests não foram modificados. Nenhum ensaio de chefe foi executado na campanha original ou na cópia jogável desse perfil.

Não foi selecionado um novo perfil de campanha com High FPS Support, Overperformance, Vulkan ou TerrariaPackCompat 1.3.0. O melhor resultado experimental exige mudanças visuais e multiplayer local, e ainda tem limitações de sincronização e conteúdo.

## Máquina e limites medidos

- Ryzen 5 5600X, seis núcleos/doze threads; GeForce RTX 5070; aproximadamente 32 GB de RAM.
- tModLoader **2026.9.3.1**, Terraria **1.4.4.9**, runtime .NET 8.0.0. As conclusões valem para esses binários e mods auditados, não para qualquer versão futura.
- Mundo Titânico **16800 × 4800**, quatro vezes a área de um mundo Grande; modo Mestre, Infernum desativado.
- Windows informou 1920 × 1080 a **100 Hz**. Nenhuma frequência global do monitor foi alterada. Renderizar 120 FPS não equivale a apresentar 120 atualizações completas por segundo nesse ajuste.
- A thread principal concentra atualização e desenho. Há outras threads ativas; os outros núcleos não estão desabilitados. O trace anterior repartiu o custo principalmente entre atualização (~52,8%) e desenho (~44,5%), com categorias aninhadas. O crescimento de tiles do Calamity foi ~4,3%, não a causa única.

Para renderizar 120 FPS, o orçamento médio é de aproximadamente **8,33 ms por quadro**. Os cenários testados excederam esse orçamento repetidamente. Aumentar o teto, prioridade ou afinidade não elimina o trabalho. Executar hooks de mundo, entidades e efeitos em paralelo sem revisar os acessos compartilhados pode corromper estado ou alterar a luta.

## Método e limites dos ensaios

O mod próprio **TerrariaPerformanceLab** só se ativa em uma pasta de laboratório específica, com marcador explícito. Em multiplayer, o servidor cria o chefe e o cliente mede chamadas reais de desenho; a partir da versão 0.4 o servidor registra também seus próprios ticks. Os dados são gravados por fase, evitando escrita a cada quadro.

Cada fase tem aquecimento. As medições válidas exigem cliente ativo em primeiro plano, chefe presente e, nas versões que registram esse campo, jogador vivo. Há proteção contra morte e vida do chefe mantida numa fração escolhida. **Não há ataques de arma automatizados do jogador.** Portanto, isto não representa todo o custo de uma luta normal, especialmente builds com muitos lacaios/projéteis e quatro jogadores. Yharon foi testado na floresta, fora da selva; a possível condição de enrage faz parte deste cenário.

“Mínimo” nas tabelas significa **menor FPS de uma janela de aproximadamente um segundo registrada**, não garantia de mínimo instantâneo ou “1% low” global. Os percentis no CSV são percentis por lote; seu pior valor não é o percentil global da sessão. Fases com chefes recriados e aleatoriedade diferente não são comparações causais perfeitas.

No primeiro ensaio o laboratório era 0.1 e não registrava o campo de morte, embora a proteção estivesse ativa. Nas versões seguintes houve ajustes de limpeza de entidades e controle multiplayer. Não atribua toda diferença entre baterias a uma única otimização.

## Resultados completos das primeiras quatro configurações

Os valores abaixo são **média / menor janela de aproximadamente 1 s**, em FPS. Os dados completos estão em `evidence/fps-20261107/boss-summary.csv` e nos JSONL correspondentes.

| Cenário | High FPS, D3D11, 1080p | Overperformance original, D3D11, 1080p | Overperformance corrigido, Vulkan, 1080p | High FPS, servidor local, 720p |
|---|---:|---:|---:|---:|
| Base | 40,5 / 37,0 | 30,9 / 28,7 | 35,6 / 29,6 | 69,5 / 66,1 |
| Olho de Cthulhu, vida cheia | 36,9 / 28,7 | — | — | 63,5 / 51,2 |
| Destruidor | 27,7 / 24,6 | 15,3 / 12,6 | 14,7 / 12,3 | 53,4 / 49,3 |
| Yharon, 25% de vida | 30,7 / 17,5 | 26,3 / 19,9 | 31,2 / 19,0 | 66,6 / 57,9 |
| Devorador de Deuses | 41,0 / 23,5 | 28,9 / 19,0 | 35,9 / 20,4 | 65,1 / 51,0 |
| Mutant | 34,9 / 19,3 | 20,4 / 11,2 | 29,0 / 18,5 | 55,8 / 39,2 |

As colunas Overperformance usam as fases de cache ativado. Há também controles sem cache no CSV. Uma fase do Devorador no Overperformance original teve 12 lotes descartados pelos critérios de validade.

A coluna de servidor local combina **D3D11 + 1280 × 720 + fundo desativado + zoom 125% + High FPS sem teto**, com simulação configurada para 60. O zoom reduz a área visível e pode prejudicar a leitura de ataques. No ensaio da base com zoom 85%, a média foi 64,7 FPS. Essa combinação muda mais de uma variável; não é prova de que reduzir a resolução isoladamente produziu o ganho.

Mesmo nessa configuração, os ticks do **cliente** caíram para ~53 em Destruidor e Mutant. Servidor local pode deslocar parte da simulação para outro processo/núcleo, mas não remove o processamento de entidades, efeitos, rede e desenho do cliente.

## Correções adicionais investigadas

**Limitador do Overperformance.** Foi identificado um caminho que acrescentava uma espera inteira quando o quadro já estava atrasado. A correção local retorna imediatamente quando o prazo já passou, mantendo a espera apenas para quadros adiantados. Testes de primeiro quadro, atraso, limite exato, adiantamento e mil quadros sobrecarregados/leves passaram. O binário privado 1.2.0.1 compilou com zero erros e 230 avisos CS1701. Isso não implica melhora suficiente de FPS: a bateria Vulkan continuou abaixo da meta. Backend e limitador mudaram juntos; não é um A/B isolado de Vulkan.

O projeto Overperformance possui licença restrita a uso pessoal/build privado nos termos consultados. Seu binário e fonte modificados permanecem no workbench privado; não foram incluídos no payload distribuído.

**Históricos do Entropy Legacy.** O candidato próprio TerrariaPackCompat **1.3.0**, experimental, evita atualizar três listas de posições/rotações apenas para projéteis hostis maduros, não pertencentes ao Legacy e sem seus indicadores de rastro. Preserva projéteis do próprio Legacy, amigáveis, neutros, efeitos sinalizados, as primeiras 32 atualizações, o contador e o restante da IA. Isso é mais conservador que copiar o filtro de três indicadores de uma implementação voltada ao Entropy moderno: o Legacy possui outros consumidores desses históricos.

A política passou por **19.200 casos**, compilou com zero erros/avisos e instalou os hooks no cliente e servidor com Legacy 3.39.1. A primeira rodada alternando original/candidato mediu:

| Cenário, 720p MP | Históricos originais | Política experimental | Ticks do servidor, aproximadamente |
|---|---:|---:|---:|
| Base | 75,1 / 65,6 | 76,1 / 67,8 | 60 |
| Destruidor | 52,8 / 46,3 | 57,7 / 53,7 | 60 |
| Yharon | 70,9 / 59,7 | 71,9 / 58,9 | 60 |
| Mutant | 58,3 / 47,6 | 64,7 / 49,5 | 60 |

Há sinal de ganho, principalmente em Destruidor e Mutant, mas as quantidades de projéteis diferem: no Mutant, o máximo observado foi 274 no controle e 175 no candidato. Essa rodada não prova que toda a diferença veio da política. A repetição em ordem inversa será registrada junto aos resultados, e o candidato permanece separado do perfil jogável.

Atribuição tardia dos indicadores de rastro e eventuais consumidores externos das listas ainda exigem testes visuais. O conjunto de 19.200 casos verifica a decisão de conservar históricos, não demonstra equivalência visual de todos os efeitos do pack.

## Compatibilidade que continua exigindo atenção

- Uma tentativa inicial com High FPS Support falhou durante a montagem de hooks do Calamity Hunt, antes da ativação dos hooks de FPS. A falha não se repetiu no carregamento seguinte; não foi estabelecida uma incompatibilidade permanente. O log foi preservado.
- High FPS Support 0.6.6.5 carregou, separou renderização/simulação e manteve a configuração de 60 ticks, mas não entregou 120 FPS neste pack. O autor alerta para artefatos em desenhos personalizados. O ensaio com teto 240 renderizou apenas ~40 FPS na base: o teto não era a solução do custo.
- No multiplayer local apareceu uma falha de reconstrução de `CalamityOverhaul/LaserEnergyTransTP` pelo InnoVault e leitura incompleta de um pacote. O cliente continuou no mundo. O laboratório foi restaurado incluindo os dados auxiliares do Vault para conferir repetição; não foi estabelecida perda de dados da campanha original.
- InnoVault declara que seu diretor de cenários permanece desligado em multiplayer. Por isso, multiplayer local não é uma substituição neutra do single-player para todo o conteúdo.
- O servidor também registrou pacote do `calamityzeith` sem tratamento adequado. Esta advertência já existia na investigação; não foi apresentada como correção concluída.
- Infernum estava desligado. A combinação de seu modo de chefes com o DLC oficial Fargo continua sem suporte integral, assim como multiplayer do Infernum. Carregar todos os mods não certifica todas as combinações de IA.
- A integração Calamity Magic Storage 0.3 tem pendências anteriores de API/capacidade e persistência. Os testes de FPS não as resolveram.

## Opções consideradas e não aprovadas

**Nitrate 0.4.2:** fonte inspecionado, não compilado ou executado. Depende de Daybreak e contém caminhos experimentais de renderização/varredura assíncrona. Seria necessário portar e validar os acessos globais antes de habilitar no pack. Não foi chamado de incompatível com base apenas nessa inspeção.

**Tempest HighFPS/Performance:** página consultada; não instalado/testado. Opções que congelam ou reduzem IA fora da tela alteram a simulação e não foram usadas como atalho para o número desejado.

**OpenGL:** mais lento na cena anterior e captura preta; não selecionado. A captura preta por si só não prova tela preta para o usuário. **Vulkan:** carregou na RTX 5070, porém não atingiu a meta. Não houve troca de driver ou ajuste global do Windows.

## Reprodução, backup e próximos limites

`Reconstruir-Compat-Desempenho.ps1` foi executado de ponta a ponta contra o tModLoader instalado. Produziu um pacote novo 1.2.0, verificou versão/metadados e não substituiu nenhum perfil. A auditoria do perfil conferiu os 71 mods. `preservation-checks.json` registra os quatro manifests originais e 78 verificações de arquivos das duas campanhas, todas aprovadas.

Os planos por fase, dados brutos, fonte do laboratório 0.4, fonte experimental 1.3 e logs relevantes estão em `evidence/fps-20261107`. `summarize_bosses.py` recalcula JSON/CSV a partir dos dados copiados. As versões de laboratório anteriores têm seu comportamento descrito acima; os artefatos de terceiros não foram redistribuídos como uma suposta solução pronta.

Para buscar novos ganhos grandes, os alvos restantes são o custo do cliente em atualização de entidades e desenho durante combate, com medições por subsistema; mudanças mais invasivas exigem regressões de colisão, rastro, rede e sincronização. Interpolação visual não deve aumentar a velocidade da simulação. Reduzir um mundo já existente não foi proposto como operação automática segura: um mundo menor exigiria campanha nova e comparação independente. Trocar hardware tampouco foi apresentado como garantia de 120 FPS.

## Referências primárias consultadas

- [FAQ oficial de tModLoader: Low FPS](https://github.com/tModLoader/tModLoader/wiki/Basic-tModLoader-Usage-FAQ#low-fps).
- [High FPS Support — página do autor](https://steamcommunity.com/sharedfiles/filedetails/?id=3119712528), Workshop verificado; artefato usado 0.6.6.5, compilado para tModLoader 2025.3.3.1.
- [Overperformance — código e licença](https://github.com/overclarity/Overperformance), commit examinado `016235e7c24d5f8b72f2f595c9a068986c67c7aa`.
- [Nitrate — código e advertências do projeto](https://github.com/terraria-catalyst/nitrate-mod), commit examinado `ccff15dd781f0e35af36d864a59b05d3b864693e`.
- [Tempest HighFPS/Performance — página do autor](https://steamcommunity.com/sharedfiles/filedetails/?id=3810573860).
