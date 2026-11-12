# Revisão do servidor local da Rev8

A implementação local foi comparada com `main` após a importação da Rev8. O launcher e os três `.bat` ainda não estavam no repositório. Os cinco manifests Rev8 conferiram byte a byte. O leitor de mundo passou a expor o GUID já presente no `.wld`. A versão publicável seleciona mundo e personagem entre os arquivos locais e guarda a seleção na cópia da campanha.

## Testes da implementação

| Verificação | Resultado observado |
|---|---|
| PowerShell 5.1 | Sintaxe aprovada. `tests/Test-Titanico.ps1` passou para GUID, mundos normais e Titânicos, arquivo truncado, herança dos mods e presets. |
| Perfil auditado | Preparação de uma cópia nova e auditoria de nome interno, versão, SHA-256, dependências e lista ativa dos 71 mods. Os mods declarados como exclusivos de cliente ficam no lado gráfico. |
| Processos e conexão | Servidor e cliente em processos separados. A conexão ocorreu após `Server started`. Durante a sessão, o único listener TCP dos processos do jogo foi `127.0.0.1:17789`. |
| Gráficos | A configuração comparada antes e após o launcher divergiu apenas no zoom, ajustado para 0,85. A resolução já estava em 1920 × 1080. O ensaio de desempenho confirmou a escala efetiva da câmera em ambos os modos. |
| Proteções | Recusou segunda sessão com tModLoader aberto, porta já ocupada, mundo de outro perfil e junção dentro dos dados auxiliares. A cópia e o backup concluído são promovidos de uma pasta de preparação. |
| Backups | 102 arquivos do backup conferiram com o snapshot anterior ao jogo. Os 57 arquivos de campanha conferidos na instalação de origem mantiveram os hashes. |
| Encerramento | `exit` gravou `.wld` e `.twld`, manteve o GUID e fechou o servidor e o auxiliar de Subworld Library. O cliente registrou o backup do personagem ao desconectar. |
| Launcher de um clique | O `.bat` reabriu a cópia salva no ensaio anterior, abriu o cliente depois de `Server started` e entrou automaticamente no mundo com os 71 mods selecionados. Havia um servidor principal, um cliente gráfico e um auxiliar de Subworld Library. O listener permaneceu em loopback. |

No ensaio de abertura em processos separados, o diagnóstico registrou cerca de 22 FPS até o jogo ser ativado em primeiro plano. A medição retornou a cerca de 60 FPS após a ativação. O indicador interno de foco ficou em 1 inclusive nas amostras iniciais, portanto a validação de abertura fica separada das medições de desempenho. O teste de `exit` usou o console da primeira sessão. O segundo ensaio verificou abertura e reconexão, e seus processos descartáveis foram encerrados após confirmar a entrada.

O Better Zenith in Calamity voltou a registrar falha de leitura de pacote na conexão. O mundo carregou, e nenhum conflito de canal de Subworld Library ocorreu no ensaio. A transição para submundos e a sincronização integral de dados de mods continuam pendentes, incluindo máquinas do Overhaul/InnoVault. O Infernum apresentou o aviso de multiplayer sem suporte. Os processos compartilham a pasta da cópia, e o backup protege o estado anterior à sessão. A auditoria da cópia e do backup não certifica que todos os mods coordenem corretamente suas escritas em multiplayer.

## Comparação de desempenho

Reanálise das medições controladas de 12/11/2026. Ryzen 5 5600X, RTX 5070, 32 GB de RAM, Terraria 1.4.4.9, tModLoader 2026.9.3.1, Compat 1.2.0 e os mesmos 71 mods em ambos os modos. As cópias partiram do mesmo mundo, personagem e opções de vídeo. A instrumentação, presente nos dois modos, registrou **1920 × 1080 e zoom efetivo de 85%**. Os chefes foram criados por um roteiro, com vida controlada e proteção contra morte do personagem. Ataques, posição e contagem de projéteis variaram entre passagens.

Cada célula comparativa usa a ordem **solo → cliente do servidor local**. O 1% low corresponde a 1000 dividido pela média do 1% de intervalos mais longos. Para cada salvamento, entram os lotes de quadros e ticks que intersectaram a gravação. Cada fase de Mutant teve cerca de 34 segundos válidos por modo.

| Cenário | FPS médio | 1% low | Pior janela de ~1 s (FPS) | Frametime p95 (ms) | Pior intervalo (ms) | TPS servidor (médio / mínimo em lote) |
|---|---:|---:|---:|---:|---:|---:|
| Mutant 1 | 49,55 → 58,63 | 25,92 → 23,48 | 40,90 → 49,32 | 25,18 → 22,56 | 62,40 → 176,95 | 60,00 / 59,42 |
| Mutant 2 | 49,00 → 55,70 | 27,90 → 33,94 | 41,22 → 43,29 | 26,82 → 25,52 | 59,97 → 32,72 | 59,81 / 57,46 |
| Salvamento na base | 46,75 → 59,48 | 10,80 → 36,80 | 23,74 → 56,16 | 31,93 → 22,56 | 99,76 → 30,45 | 60,00 / 59,33 |
| Salvamento na recuperação | 50,94 → 59,31 | 12,91 → 28,09 | 28,65 → 54,93 | 27,85 → 21,27 | 93,47 → 54,54 | 59,66 / 58,63 |

A gravação da base levou 6,55 s no solo e 7,46 s no servidor. Na recuperação, foram 5,98 s e 6,80 s. A separação melhorou a fluidez do cliente durante as duas gravações. No primeiro Mutant, a média subiu e o 1% low caiu por causa dos intervalos mais longos. A meta de 60 FPS estáveis em combate segue pendente.

| Cenário | Processo solo | Processo gráfico no servidor local | Processo dedicado |
|---|---:|---:|---:|
| Mutant 1 | 1,25 / 97,6% | 1,31 / 96,8% | 0,58 / 57,6% |
| Mutant 2 | 1,29 / 97,4% | 1,38 / 98,0% | 0,70 / 67,4% |
| Salvamento na base | 2,36 / 88,5% | 1,45 / 98,2% | 1,51 / 78,9% |
| Salvamento na recuperação | 2,34 / 90,3% | 1,50 / 95,7% | 1,93 / 76,8% |

Cada célula de CPU informa o consumo médio do processo em equivalentes de processadores lógicos e a média da thread mais ocupada em porcentagem de um processador lógico. O Mutant teve 11–12 amostras por passagem. Cada gravação teve 2–3 amostras de hardware, então os números de CPU durante saves são aproximados. A thread dominante do servidor variou durante as gravações. O auxiliar de Subworld Library foi identificado separadamente e registrou consumo arredondado a zero durante essas janelas. A GPU no Mutant ficou perto de 19–20%. O servidor manteve a simulação perto de 60 TPS, enquanto o cliente permaneceu próximo da saturação de uma thread.

O contador de chamadas de atualização no cliente inclui espera entre ticks. Por isso, a comparação de combate usa os intervalos entre quadros e o contador real de ticks. A causa do quadro de 177 ms e a queda após exploração prolongada permanecem abertas. O lançamento preserva o escalonamento padrão do Windows e a mesma versão dos mods.
