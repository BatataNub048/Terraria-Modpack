# Investigação de CPU e candidato de desempenho — atualizado em 07/11/2026

O perfil de desempenho distribuído usa TerrariaPackCompat **1.2.0**. A comparação repetida na mesma sessão mostrou cerca de **49,1 → 51,1 FPS**, aproximadamente 4%, na cena da base. A meta posterior de 120 FPS em chefes **não foi atingida**. Os ensaios de renderização desacoplada, servidor local e combate estão detalhados em [DESEMPENHO-120FPS.md](DESEMPENHO-120FPS.md); esses experimentos não foram instalados na campanha.

O jogo apresentou cerca de 45 FPS na captura e o usuário informou 48–51 FPS fora de chefes grandes. A thread principal saturou aproximadamente um núcleo. Há outras threads em uso: o processo consumiu cerca de 1,3 núcleo equivalente na amostra. Os demais núcleos não estavam desabilitados. A atualização principal e boa parte dos callbacks de mods são sequenciais e compartilham dados de mundo; transformar tudo em tarefas paralelas exige uma revisão de sincronização, não uma opção do Windows.

## Medições

- Ryzen 5 5600X, seis núcleos/doze threads; GeForce RTX 5070.
- Perfil ativo TodosRecuperados-Titanico, 71 mods, resolução configurada 1920 × 1080, zoom 85%.
- Aproximadamente 13 GiB de RAM física livre no início; processo com cerca de 8 GiB residentes e 16 GiB privados comprometidos. Não havia evidência inicial de esgotamento de RAM.
- Um motor 3D da GPU associado ao jogo marcou 9% numa leitura. Não é média de uma batalha nem uma medição de VRAM.
- Duas interfaces de armazenamento estavam abertas na primeira captura. Elas eram uma hipótese inicial, não uma causa comprovada.
- Uma pilha instantânea mostrou Calamity `HandleTileGrowth` via o hook de proteção do Overhaul. A amostragem posterior mostrou que esse caminho ocupa apenas parte do problema.

Foi coletado um trace de aproximadamente dez segundos com o profiler oficial do .NET. A análise da thread principal apresentou as seguintes participações inclusivas na janela amostrada:

| Caminho | Janela amostrada |
|---|---:|
| Atualização do jogo | 52,8% |
| Desenho do jogo | 44,5% |
| Atualização de jogador, dentro da atualização | 16,8% |
| Atualização interna de mundo | 10,0% |
| Desenho de tiles | 7,3% |
| Interface | 7,3% |
| Varredura de métricas do cenário | 7,0% |
| NearbyEffects, dentro da varredura | 5,9% |
| Crescimento de tiles do Calamity | 4,3% |
| Detecção de tiles da música vanilla Calamity | 1,7% |
| Checagem de velas do DLC Fargo | 1,2% |

As linhas são aninhadas e se sobrepõem; não devem ser somadas. Um wrapper no stack inclui o tempo da função original encadeada, por isso sua presença não prova que todo esse custo pertence ao mod do wrapper. Não atribuí todo o custo aos mods que apenas encaminham a chamada.

O trace bruto e a conversão estão em `workbench/fps-review-20261106` na pasta de trabalho, fora da distribuição principal. O resumo está em `evidence/fps-20261106/baseline-summary.json`.

## Alterações do candidato

Foi criado TerrariaPackCompat **1.2.0**, preservando a correção de banner do Whips 1.2.2 já existente. Acrescenta seis otimizações para versões explicitamente verificadas:

1. **Vanilla Calamity Mod Music 2.1.3:** reutiliza as listas de coordenadas de tiles entre resets. Mantém o dicionário ativo, suas chaves, a ordem dos pontos, os limites de reset e os métodos originais de cálculo de distância. Evita alocar listas novas em cada varredura.
2. **DLC oficial Fargo 1.2.0.28 + Calamity 2.2.4:** antes dos cálculos de buff/som, confere se o tile é uma das quatro velas atendidas pelo método. Para esses quatro tipos, executa o método original completo. Os outros tipos não produziam efeitos nesse método.
3. **Ragnarok 1.6.0.10:** conserva os dois hooks de desenho de Queen Jellyfish e Star Scouter enquanto a condição desejada permanece igual. Mantém a cadência original de consulta a cada 1800 ticks e reaplica quando dificuldade/configuração muda. O original desfazia e recriava esses hooks periodicamente; os logs da sessão confirmaram a repetição mesmo fora dessas lutas.
4. **Calamity 2.2.4:** evita alternar o SpriteBatch para desenho aditivo quando a lista de pulsos de polaridade de um NPC está vazia. Efeitos existentes continuam pelo caminho original.
5. **Vanilla Calamity Mod Music 2.1.3:** conserva o delegate do getter de início da faixa. O valor continua sendo consultado ao vivo; evita procurar a propriedade por reflexão repetidamente.
6. **Infernum Mode Music 2.0.1.8:** conserva o delegate do getter de disponibilidade do céu dos Exo Mechs, também sem congelar seu valor.

Não altera taxa de crescimento de plantas, geração, biomas, drops, IA ou conteúdo de armazenamento. Não desloca escrita de mundo para threads concorrentes. As versões originais desses mods permanecem intactas; as mudanças são hooks no mod de compatibilidade. Versões futuras desconhecidas são recusadas para cada otimização.

## Testes executados e limites

- Compilado com tModLoader 2026.9.3.1: zero erros e zero avisos de compilação.
- Testes de 25 mil operações mistas confirmaram as mesmas chaves, ordem e coordenadas do algoritmo original de listas, incluindo resets repetidos e reutilização sem dados antigos.
- Testes da política de hooks cobriram ativação inicial, dez mil consultas estáveis, desativação, reativação e recuperação de estado externo. Estado estável não reconstruiu hooks.
- Benchmark sintético de 2500 varreduras: 58.884.544 bytes alocados no modelo original contra 32.640 bytes com reuso. Esse resultado mede alocações no fixture, **não ganho de FPS**.
- O candidato carregou em servidor separado e em cliente com os 71 mods e uma cópia de mundo descartável. Os seis caminhos foram instalados nas versões esperadas. A reconstrução pelo script distribuído também produziu um pacote novo com metadados 1.2.0, em 07/11, com zero erros e zero avisos.
- A/B na mesma sessão, mesma posição e gráficos, em cinco fases de aproximadamente 35 segundos: comportamento original ~49,1 FPS; otimizações ~51,1 FPS. A melhoria é modesta e específica dessa cena; não certifica todas as lutas.
- Com cliente em primeiro plano e servidor local separado, a base no teste nativo aproximou-se de 59–60 FPS em amostras; a média ponderada de uma janela de cerca de 95 segundos ficou em ~56,9 FPS. As primeiras leituras de 22 FPS estavam afetadas pela execução em segundo plano.
- OpenGL ficou mais lento nesta máquina (~43–44 FPS na cena avaliada); não foi selecionado. Vulkan e as opções de FPS acima de 60 foram testados posteriormente no laboratório, com os resultados do relatório específico.

As otimizações tratam partes medidas do custo e uma fonte comprovada de reconstrução de hooks. Não garantem um mínimo de 60 ou 120 FPS. Interações completas de IA entre Infernum e Fargo continuam fora dessa validação. O modo Infernum estava desativado no mundo usado nos ensaios.

## Como testar preservando a campanha

O perfil novo **TodosRecuperados-Titanico-Desempenho** mantém 71 mods e substitui somente TerrariaPackCompat pelo candidato. Os quatro manifests anteriores permanecem inalterados. O binário antigo permanece no payload padrão; o candidato usa um caminho de variante fixado por SHA-256 no novo manifest.

1. Salve e feche Terraria e seus servidores. O código já carregado não pode ser trocado com segurança durante a partida, e o par `.wld`/`.twld` precisa de uma cópia consistente.
2. Execute `Jogar-TodosRecuperados-Titanico-Desempenho.bat`.
3. Na primeira execução, `Preparar-Desempenho.ps1` copia personagens, mundos, configurações e demais dados para uma pasta independente, monta os 71 mods auditados e compara hashes dos dados copiados antes de publicar o perfil.
4. Nas execuções seguintes, reaproveita essa cópia e nunca sobrescreve progresso dela com dados do perfil de origem.

Não há clone de campanha enquanto o jogo estiver aberto. O laboratório usa cópias descartáveis da campanha; seus chefes automáticos, proteção contra morte e arquivos de teste ficam fora dos perfis jogáveis. Não copie o mod TerrariaPerformanceLab para uma campanha.

Para voltar ao perfil anterior, use `Jogar-TodosRecuperados-Titanico.bat`. Os progressos das duas cópias divergem após começar a jogar; voltar ao perfil antigo não transfere automaticamente as alterações da campanha de desempenho. Não alterne versões diferentes de TerrariaPackCompat entre clientes de uma mesma sessão multiplayer.

O launcher compartilhado ganhou apenas a opção de perfil novo e resolução segura de arquivos de payload por variante; os padrões anteriores continuam iguais. As cópias anteriores do launcher e do README estão em `evidence/fps-20261106/before`.

O fonte de 1.2.0 está em `source/variants/TerrariaPackCompat-1.2.0/TerrariaPackCompat`. `Reconstruir-Compat-Desempenho.ps1` exige o tModLoader exato do manifest, verifica os 71 arquivos de entrada e compila em uma pasta nova. O pacote de entrada é retirado da pasta de saída antes de compilar, para não confundir uma falha com um binário antigo. O script não instala o resultado automaticamente. Versões compiladas novamente devem ter seus hashes e testes conferidos antes de atualizar o lock.

Referência de diagnóstico: [FAQ oficial de tModLoader, Low FPS](https://github.com/tModLoader/tModLoader/wiki/Basic-tModLoader-Usage-FAQ#low-fps). Nenhuma afinidade de CPU, driver, serviço ou configuração global do Windows foi alterada.
