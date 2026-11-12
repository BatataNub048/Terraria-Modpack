# Rev8 — extensão de Mundos Titânicos

Auditoria local em 05/11/2026. Terraria 1.4.4.9; tModLoader estável 2026.9.3.1. Os perfis novos estão instalados e isolados. A validação é parcial: gerar e abrir um mundo não certifica uma campanha, os combates ou todas as integrações multiplayer.

O funcionamento básico dos dois perfis titânicos foi confirmado: geração, gravação, reabertura e entrada/saída de um cliente local. O conjunto completo permanece mais arriscado: há falhas reproduzidas nas APIs do Calamity Magic Storage e restrições de IA declaradas pelos autores. A criação dos perfis não representa correção dessas integrações.

## Os quatro perfis

| Perfil | Mods | Inicializador | Situação |
|---|---:|---|---|
| Ampliado | 67 | `Jogar-Ampliado.bat` | Manifest, binários e saves originais preservados |
| TodosRecuperados | 70 | `Jogar-TodosRecuperados.bat` | Manifest, binários e saves originais preservados; experimental |
| Ampliado-Titanico | 68 | `Jogar-Ampliado-Titanico.bat` | Os mesmos 67, acrescidos somente de TitanWorlds |
| TodosRecuperados-Titanico | 71 | `Jogar-TodosRecuperados-Titanico.bat` | Os mesmos 70, acrescidos somente de TitanWorlds; mais experimental |

Cada inicializador seleciona `profiles/<nome>.lock.json`, valida versão e SHA-256 dos mods e usa `saves/<nome>` para mundos, personagens e configurações. Não há atualização silenciosa dos 70 mods. LuiAFK Reborn 1.2.5 continua nos quatro conjuntos. Não foi acrescentado mod para combinar os bancos pessoais.

Os três exclusivos de TodosRecuperados permanecem: FargowiltasCrossmod 1.2.0.28, InfernumMode 2.0.1.35 e CalamityMagicStorage 0.3. Os DLCs antigos que já pertenciam ao Ampliado também foram preservados; a soma das integrações não foi declarada compatível por isso.

## Origem e correção do mod novo

[Mundos Titânicos, Workshop 3792079909](https://steamcommunity.com/sharedfiles/filedetails/?id=3792079909) foi obtido via SteamCMD. O arquivo escolhido do ramo 2026.7 era TitanWorlds **1.15.16**, compilado com 2026.7.3.0, lado Both, sem dependências obrigatórias ou opcionais declaradas no cabeçalho.

Essa versão falhou no primeiro ensaio dedicado: com a opção de forçar tamanho expandido ligada, criou **8400 × 2400**, seed 1828740039, em 1min49,612s. Não contei esse mundo como titânico. O caminho de criação dedicado não passava pelo callback no qual o mod ativava seu escopo de redimensionamento.

A versão local **1.15.16.1**, compilada com **2026.9.3.1**, acrescenta um hook antes da criação dedicada de um arquivo inexistente. A correção preserva o tratamento de arquivos existentes e submundos. Código, diff, metadados, logs e script de reconstrução estão em [patches/TitanWorlds](patches/TitanWorlds/README.md). SHA-256 instalado: `2623e133d3a304d07565053ae1eb96083c4feee2cffcc87d634db926a908232b`.

O tamanho real definido nessa origem é **16800 × 4800**, totalizando 80.640.000 blocos: quatro vezes a área de um mundo Large 8400 × 2400. A descrição pública ainda menciona 16000 × 8000; os testes e esta configuração seguem o binário efetivamente baixado e seu código, não essa descrição antiga.

## Preservação e arquivos

O backup anterior às alterações está em `evidence/titanico-20261105-185838/before`. Os relatórios `preservation.json` e `preservation-final.json` nesse diretório de evidências registram a comparação por SHA-256: os dois manifests originais e `Jogar-Ampliado.bat` idênticos; 70 binários de payload conferidos contra o lock original; 218 arquivos dos saves antigos sem modificação, remoção ou inclusão.

Arquivos criados: dois manifests `*-Titanico.lock.json`, os dois `.bat` titânicos, `Jogar-TodosRecuperados.bat`, `payload/TitanWorlds.tmod`, `lib/WorldSafety.psm1`, `tests/Test-Titanico.ps1`, a pasta do patch TitanWorlds, este relatório e as evidências. Os dois diretórios novos em `saves` contêm instalações isoladas e mundos descartáveis de ensaio.

Arquivos compartilhados modificados: `Executar-Perfil.ps1`, para aceitar os quatro nomes e conferir a segurança dos mundos, e `README.md`, para apresentar os quatro perfis. As cópias anteriores foram preservadas. Os presets dos perfis novos são os mesmos dos respectivos originais, com apenas `TitanWorlds_TitanWorldServerConfig.json` acrescentado e `ForceTitanWorldOnDedicatedServer=true`.

O launcher lê o cabeçalho `.wld` antes de iniciar o jogo. Em perfis sem TitanWorlds, bloqueia mundos cuja largura excede 8400 ou altura excede 2400. No servidor também confere o mundo indicado em `serverconfig-rev8.txt`; os servidores titânicos devem usar um arquivo dentro de sua própria pasta `Worlds`. Cabeçalhos inválidos ou formatos desconhecidos interrompem a execução. A proteção não modifica mundos e não examina submundos em subpastas. Ela vale ao usar os launchers: abrir o executável diretamente, mover saves para outra instalação ou desativar mods pelo menu contorna essa verificação.

## Resultados dos testes

### Ampliado-Titanico

- Carregamento dos 68 mods e criação dedicada passaram com o patch local. Mundo Expert/Crimson, seed **1190245610**, **16800 × 4800**, geração em **5min58,538s**. Dimensões conferidas no `.wld`, além do log.
- O `.twld` contém `TitanWorld=true`, registros dos seis laboratórios do Calamity e tipos de blocos efetivamente colocados de Abyss, Sulphurous Sea e Sunken Sea. O fundo do Abyss registrado está em Y=4450. Há Navystone, EutrophicSand, SeaPrism, AbyssGravel e SmoothVoidstone, entre outros.
- Centros dos seis laboratórios são diferentes de zero e ficam dentro do mundo, em coordenadas de pixels: Sunken Sea (154992,48032), planetoide (134328,2072), selva (197784,40016), inferno (235440,75120), gelo (63408,43288), caverna (103904,47616).
- Thorium salvou Blood Chamber (8543,3172,87,35), Aquatic Depths (16367,1027,422,318) e Graveyard (472,793,128,53), em blocos, dentro dos limites. O catálogo salvo contém BloodAltar, BloodstainedSlab, DepthChestTile e minerais de Aquatic Depths. Isso comprova dados de geração e presença de blocos; não comprova visualmente que cada estrutura esteja íntegra, acessível e com todo o loot.
- Um cliente gráfico com os mesmos 68 binários entrou por TCP em 127.0.0.1:17781 e permaneceu no mundo por cerca de dois minutos. A entrada e a saída constam no servidor. O cliente mostrou o cenário e minimapa. Não houve luta nem dois clientes simultâneos.
- O servidor salvou e encerrou normalmente. Uma segunda execução carregou o mesmo mundo **16800 × 4800** e voltou a iniciar o servidor. Salvou novamente ao encerrar.
- Houve um aviso de pacote não consumido de `calamityzeith`, detalhado abaixo. Portanto, o resultado não é “multiplayer sem problemas”.

### TodosRecuperados-Titanico

- Os 71 mods carregaram. O segundo mundo Expert/Crimson, seed **547373613**, terminou em **9min31,338s**, com **16800 × 4800** conferidos no `.wld`. O Abyss customizado do Infernum levou aproximadamente 2min38s na etapa correspondente; a demora teve progressão posterior e não foi classificada como travamento.
- O `.twld` contém os seis centros de laboratórios do Calamity, diferentes de zero e dentro do mundo: Sunken Sea (162848,51904), planetoide (134168,2104), selva (194136,44544), inferno (204640,75264), gelo (80288,45720), caverna (171680,44192), em pixels. Há blocos dos biomas nos dados salvos, e o fundo do Abyss ficou em Y=4558.
- Thorium registrou Blood Chamber (9537,3428,87,35), Aquatic Depths (16367,1021,422,316) e Graveyard (1253,848,111,34), em blocos, dentro dos limites.
- Infernum salvou a arena de Providence em **(15682,4567), 1076 × 191** blocos. O validador do TitanWorlds conferiu limites e uma amostra de ocupação de blocos, sem precisar reconstruir a arena. O save registra o templo e a entrada do Colosseum como gerados; contém ColosseumPortal, ProvidenceSummoner, ProvidenceRoomDoorPedestal, GuardiansPlaque e decorações do Abyss. O jardim ficou em (12327,2436). Essas evidências não equivalem a testar o portal, a luta de Providence ou todas as arenas.
- Um cliente gráfico com os mesmos 71 binários entrou em 127.0.0.1:17782 e mostrou o mundo e minimapa. O aviso de `calamityzeith` repetiu-se, sem impedir a entrada. O teste usou Expert e as configurações iniciais; não ativou nem combinou modos especiais de IA para certificar lutas.
- Nos dois mundos, `saveModDataErrors` estava vazio na primeira gravação inspecionada.
- O servidor de 71 mods foi encerrado com salvamento e iniciado novamente: carregou **16800 × 4800** e voltou a escutar em 17782. A saída do cliente também ficou registrada.

Após as duas sessões de cada mundo, comparei novamente os dados salvos: os sistemas de estruturas do Calamity, do Thorium e a marca TitanWorld ficaram idênticos aos da primeira gravação nos dois perfis. O `WorldSaveSystem` do Infernum também permaneceu idêntico no perfil completo. Nenhum erro de salvamento de dados de mods foi registrado nesses cabeçalhos. O arquivo `reopen-moddata-integrity.json` detalha as comparações; não é uma comparação integral de todos os itens e NPCs do mundo.

Foram gerados **dois mundos titânicos reais**, com seeds distintas, um por perfil. A tentativa inicial de tamanho padrão foi arquivada como falha. Isso é uma repetição entre os dois conjuntos, não uma bateria estatística de várias seeds por perfil; essa cobertura ainda falta.

### Verificações de segurança e reprodução

`tests/Test-Titanico.ps1` passou no Windows PowerShell 5.1: cabeçalho normal permitido; titânico permitido com mod; formatos 16800 × 4800 e 16000 × 8000 recusados sem mod; arquivo truncado recusado; herança exata dos mods e presets originais; LuiAFK presente. Os dois manifests novos acrescentam exatamente um mod.

O script `patches/TitanWorlds/Recompilar.ps1` também foi executado com sucesso. Não instala o resultado automaticamente. Uma nova compilação pode mudar o SHA do pacote; os locks fixam o artefato auditado desta entrega.

A proteção também foi exercitada com o arquivo titânico real gerado: recusado sem o mod, aceito com ele e SHA-256 do mundo idêntico antes/depois da leitura. As quatro execuções de `-Modo Verificar` passaram; seus logs e o resumo de contagens estão nas evidências.

### Calamity Magic Storage: diagnóstico separado

Executei um ensaio de API em `workbench/titan-storage-audit`, usando uma cópia descartável do primeiro mundo de tamanho padrão. A instalação de diagnóstico tinha os 71 mods e **um auxiliar temporário**, StorageProbe, totalizando 72 somente nesse laboratório. Ele não foi adicionado a payload, manifests ou saves dos quatro perfis. A versão local de TitanWorlds também preservou 8400 × 2400 ao carregar esse arquivo existente.

O comando cria programaticamente uma unidade sintética `TECalamityStorageUnit`, com quatro blocos do tipo CalamityStorageUnit e estilo Uelibloom, registra-a temporariamente nas tabelas de entidades e chama as APIs reais. É um teste em processo, sem jogadores conectados. Não reproduz colocação pelo jogador, rede, ligação a um Storage Heart ou reabertura integral de um armazenamento de campanha.

| Verificação | Resultado observado |
|---|---|
| Depósito | 1234 blocos de pedra e 7 Life Crystals entraram; nada sobrou nas pilhas de entrada |
| Retirada | 234 blocos retirados; restaram 1000 pedras e 7 cristais na unidade |
| Capacidade | `CalamityCapacity=720`, mas a capacidade consultada pela API base de Magic Storage foi `0` |
| Validade do bloco | `ValidTile=false` para o tipo de bloco do próprio addon no fixture |
| Upgrade Uelibloom → Cosmilite | O método retornou sucesso e alterou o estilo, mas a pilha de upgrades caiu de 10 para 7: consumiu 3 |
| Serialização / tentativa de reabrir NBT | Falhou em `SaveData`: chave `Items` duplicada. Nenhum roundtrip de itens foi aprovado |

A primeira execução registrou a exceção. Ajustei o coletor de diagnóstico para capturar os resultados anteriores a ela, reconstruí apenas o auxiliar e repeti; o erro de serialização se repetiu. `storage-probe.json`, o código do coletor e os dois logs de servidor estão nas evidências. Nenhum item de uma campanha foi envolvido.

Há causas identificáveis no código 0.3: o addon mantém sua própria lista de itens e propriedades ocultando as do pai; consulta `base.Capacity` em caminhos que deveriam reconhecer seu tier; `ValidTile` compara com o bloco base; o upgrade possui múltiplos decrementos; `SaveData` chama o pai, que já escreve `Items`, e tenta inserir a mesma chave com `replace=false`.

É possível portar essas partes para a API atual de tiers do Magic Storage, usar uma única fonte de itens/capacidade, acertar o tipo de bloco, consumir um upgrade por operação e rever a sincronização. A substituição de `tag.Set(..., false)` por uma atribuição que permita atualizar a chave resolve aquela exceção específica; a revisão completa também precisa tratar os demais problemas e a leitura de saves anteriores. Isso requer um fork auditado e testes com Storage Heart, UI, metadados de itens, upgrades, save/reabertura e dois clientes.

Mantive o **CalamityMagicStorage 0.3 original** conforme a preservação solicitada. O ensaio fornece motivo técnico para não confiar nele em armazenamento de campanha neste estado. O Magic Storage base continua presente em todos os perfis; a falha observada foi nessa classe do addon. Não recomendo contornar o problema com um patch isolado e assumir que os itens estão seguros.

### Memória e desempenho

Foram coletadas amostras a cada cinco segundos, em Windows com 31,9 GB de RAM informados pelo tML e 12 processadores lógicos. O monitor distingue o processo principal dos filhos de Subworld Library. São picos amostrados de working set (memória residente), não garantias de máximo nem requisitos mínimos universais.

| Ensaio | Pico residente amostrado |
|---|---:|
| Ampliado-Titanico, servidor principal | 6,98 GiB |
| Ampliado-Titanico, servidor + filho de submundo | 9,00 GiB |
| Ampliado-Titanico, cliente gráfico | 6,56 GiB |
| TodosRecuperados-Titanico, servidor + filho de submundo | 9,21 GiB |
| TodosRecuperados-Titanico, cliente gráfico | 6,41 GiB |

O cliente de 68 mods chegou a aproximadamente **14,12 GiB de memória privada comprometida**, maior que seu working set. A menor RAM física livre amostrada foi 6,18 GiB enquanto os ensaios rodavam. Não se deve dimensionar esse conjunto apenas pelo working set ou pelo limite de memória que o código do mod aceita. Hospedar e jogar na mesma máquina demanda mais margem que executar só o servidor.

No conjunto de 71, o cliente chegou a **14,73 GiB privados comprometidos**, e a menor RAM física livre ficou em **4,91 GiB** durante o ensaio combinado. Os picos de cada processo não precisam coincidir. As amostras brutas e `memory-summary.json` permitem conferir essa diferença.

O contador visual do cliente passou de cerca de 20 FPS na entrada para 54–60 FPS nas observações seguintes, parado perto do spawn em 800 × 720. Isso não é benchmark de exploração, mapa completo ou batalhas. Não medi VRAM, latência externa ou percentis de tempo de quadro. A geração mede a fase do mundo e não inclui todo o tempo de carregamento dos mods.

Para este conjunto, 32 GB na máquina que hospeda e joga é uma referência prática a partir do ensaio, sem promessa de suficiência para toda a campanha. Separar servidor e cliente ajuda. Preserve margem de memória, evite dois servidores locais, mantenha os hashes fixos e repita o teste com a quantidade real de jogadores antes de escolher uma seed de campanha. Não alterei configurações globais de memória, paginação, firewall ou do sistema.

## Problemas e alcance das soluções

| Problema | Evidência e efeito | Solução ou encaminhamento |
|---|---|---|
| TitanWorlds original cria mundo padrão no dedicado | Reproduzido com opção ligada, tamanho gravado 8400 × 2400 | Corrigido localmente no mod novo; tamanho titânico confirmado em arquivo e reabertura |
| `calamityzeith 0.6` não trata seu pacote | Na entrada do cliente: `Read underflow 0 of 5 bytes caused by calamityzeith in HandlePacket`. `ZenithPlayer.SyncPlayer` escreve índice do jogador em um byte e `sealsUsed` em um inteiro; a classe Mod não implementa `HandlePacket` | A conexão continuou. É necessário receber, validar e redistribuir esses dados, além de testar atualizações dos selos após entrar. Não alterei seu binário, preservando os 70 originais |
| Subworld Library deixa processo filho após o servidor principal sair | Um filho `-subworld 0` permaneceu após a reabertura do ensaio. O launcher recusou iniciar o próximo servidor | O bloqueio evitou colisão de canais. Registrei e encerrei apenas o filho descartável identificado, com pai já fechado. Não há limpeza automática de processos ou saves de campanha |
| DLC oficial Fargo com Thorium, Infernum e Overhaul | A [página dos autores](https://steamcommunity.com/sharedfiles/filedetails/?id=3044249615) declara essas combinações incompatíveis, especialmente modificações de IA | Preservados no perfil experimental solicitado. Exige arbitrar os hooks e testar chefe por chefe antes de afirmar correção; carregar/gerar não resolve IA concorrente |
| Infernum no multiplayer | O [texto oficial](https://raw.githubusercontent.com/InfernumTeam/InfernumMode/master/Localization/en-US.hjson) avisa que multiplayer não é suportado | Não tratado como combinação estável; padrões, projéteis, fases e reconexões em lutas continuam pendentes |
| Calamity Magic Storage 0.3 com Magic Storage 0.7.0.11 | O [backup publicado](https://steamcommunity.com/sharedfiles/filedetails/?id=3499799348) reconhece problema em upgrades por clique direito. O ensaio local reproduziu capacidade base zero, validade falsa, consumo triplo e falha ao serializar `Items` na unidade sintética | Manter armazenamentos reais fora do experimento. Portar para a API atual de tiers e testar colocação, UI, persistência e rede; o binário 0.3 foi preservado |
| Hooks de Inheritance/Ragnarok sem encadear o anterior | Avisos do carregador ao instalar determinados hooks | Indicam pontos de inspeção; não são, isoladamente, prova de defeito em toda a combinação. Testar as armas/acessórios e chefes envolvidos |
| InnoVault mantém diretor de cenários offline em multiplayer | Mensagem explícita do próprio mod no cliente | Conteúdo desse sistema não passa a funcionar em rede por aumentar o mundo; requer implementação de rede no componente |
| Hotkeys ausentes | Ore Excavator e Quality of Terraria avisaram no personagem descartável | Configurar teclas em Controles > Controles dos mods. Não é incompatibilidade nem motivo para retirar os mods |

## Como jogar e criar um mundo

1. Com os outros jogos/servidores fechados, escolha um dos quatro `.bat`. Use o mesmo perfil em todos os participantes.
2. Nos perfis titânicos, crie personagem e mundo novos. Na tela de criação do cliente, selecione o botão de tamanho **Titânico/Titanic** acrescentado pelo mod. O tamanho Large continua sendo uma opção diferente.
3. Para um ensaio dedicado, na pasta da Rev8 execute:

```powershell
.\Executar-Perfil.ps1 -Perfil Ampliado-Titanico -Modo Verificar
.\Executar-Perfil.ps1 -Perfil Ampliado-Titanico -Modo Servidor -PastaTml 'E:\SteamLibrary\steamapps\common\tModLoader' -Porta 17781
# Para o conjunto completo, troque o perfil por TodosRecuperados-Titanico.
```

O preset força o tamanho titânico na criação dedicada de arquivo novo. `autocreate=3` é o pedido base Large ao Terraria; o mod o expande. Um arquivo já existente é carregado, não expandido retroativamente. Os `Rev8-Expert.wld` já entregues são mundos de teste. Para criar sua campanha, com tudo fechado, faça backup de toda a pasta do perfil e ajuste `world=` e `worldname=` no `serverconfig-rev8.txt` para um **nome novo ainda inexistente dentro de Worlds desse perfil**. Não sobrescreva um mundo de campanha para tentar expandi-lo.

Para verificar tamanho sem abrir o mundo:

```powershell
Import-Module .\lib\WorldSafety.psm1
Get-PackWorldHeader '.\saves\Ampliado-Titanico\Worlds\Rev8-Expert.wld'
```

Para multiplayer, distribua a mesma pasta auditada, incluindo o TitanWorlds local; assinar apenas a versão da Workshop não fornece o patch. Mantenha os mesmos hashes e tML 2026.9.3.1 nos clientes. Conecte por IP e porta; Steam Host & Play não foi testado. Não rode dois servidores locais ao mesmo tempo; aguarde também a saída dos filhos de Subworld Library. Ao terminar, use `exit` no console para salvar. Faça backup conjunto de `.wld` e `.twld`, personagens `.plr`/`.tplr` e configurações, com todos os processos fechados.

O parâmetro `-Endereco` é passado como `-ip`, mas no primeiro ensaio a consulta de sockets mostrou listener `0.0.0.0`, apesar do argumento loopback. O teste comprovou conexão local, não isolamento da interface. Não alterei firewall ou roteador; confira a interface efetivamente aberta antes de hospedar fora da máquina.

Os presets são aplicados na preparação inicial. Ajustes posteriores de cada perfil ficam em sua própria pasta; o launcher não redefine silenciosamente todas as preferências. Nos perfis titânicos ele exige explicitamente a opção de forçar a criação dedicada.

## O que ainda não foi certificado

Permanecem pendentes a campanha completa; inspeção visual e loot de todas as estruturas; todos os chefes e interações de IA; dificuldades Infernum/Eternity combinadas; dois jogadores simultâneos, latência e quedas em rede externa; viagens de ida e volta de The Stars Above e outros submundos; slots/loadouts e acessórios avançados; integridade de um sistema de armazenamento real em upgrades, concorrência e reabertura completa; longa duração, mapa totalmente explorado e hardmode.

A criação manual pelo menu do cliente também não foi executada: a geração validada nesta rodada foi dedicada. O procedimento do botão Titânico segue a implementação presente no mod. Os launchers foram conferidos pelos modos de preparação/verificação e pelos servidores; os testes gráficos utilizaram instalações descartáveis com cópias dos mesmos binários.

The Stars Above, Ragnarok e Fargo's Souls carregaram com o conjunto e participaram dos registros/configurações normais, mas isso é **teste parcial**, não validação de todas as funções. Não há patch prometido para sincronização de todos os chefes. Nenhum save real foi usado para testes arriscados.

Os logs, cabeçalhos, extrações de NBT, hashes, consumo de memória e resultados dos scripts ficam em `evidence/titanico-20261105-185838`. O leitor `inspect_twld.py` é somente leitura: as listas `tileMap` de tML registram tipos realmente encontrados ao salvar, mas não substituem exploração do mapa.

Todos os processos de tModLoader usados nos ensaios foram encerrados ao concluir. O laboratório de armazenamento permanece fora dos quatro perfis e não deve ser usado como campanha.
