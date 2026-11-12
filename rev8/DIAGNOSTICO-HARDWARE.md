# Diagnóstico durante combate — 08/11/2026

**O gargalo de uma thread do cliente continua presente.** A coleta sincronizada encontrou 51,24 FPS no Destruidor com a thread dominante a 99,2% de um processador lógico e a GPU a apenas 14%. Isso identifica o limite imediato como trabalho de CPU no cliente; não identifica sozinho um mod culpado ou um defeito de hardware.

## Amostra correspondente à queda

| Medida | Resultado |
|---|---:|
| FPS, janela de ~1 s | 51,24 |
| Thread dominante do cliente | 99,2% de um processador lógico |
| GPU, utilização global | 14% |
| Temperatura da GPU | 43,4 °C |
| VRAM utilizada globalmente | 8344 MiB de 12227 MiB |
| RAM física disponível | 11090 MiB |
| Memória comprometida global | 35,31 GiB de limite de 37,93 GiB |
| Memória privada comprometida do cliente | 15,81 GiB |
| Memória residente do cliente | 6,76 GiB |
| Entrada de páginas de memória naquela amostra | 0 |
| Tempo médio na atualização do cliente | 9,32 ms |
| Tempo médio no desenho do cliente | 9,87 ms |
| NPCs presentes, incluindo segmentos | 109 |

Atualização e desenho somaram aproximadamente 19,2 ms por quadro nesse lote, acima do orçamento de 16,67 ms para 60 FPS. O tempo de desenho medido é tempo decorrido na chamada do cliente, não um cronômetro exclusivo de execução da GPU. A baixa utilização da GPU junto à saturação da thread aponta para custo de preparação/desenho na CPU, além da atualização de entidades.

## CPU e núcleos

A afinidade do cliente era 4095, permitindo os 12 processadores lógicos, com prioridade Normal e cerca de 80 threads. O uso total da CPU numa leitura durante combate foi 24%, enquanto a thread dominante do cliente saturava um processador lógico. Essas medidas não se contradizem: os demais processadores podem ficar disponíveis enquanto o quadro espera pelo trabalho sequencial de uma thread. A thread também pode migrar entre núcleos; por isso a coleta acompanha tempo de CPU por thread, não apenas o gráfico de um núcleo fixo.

No Destruidor, a mediana da thread dominante foi 98,1%, chegando a 99,2%; GPU entre 13% e 16%. O Windows estava no plano Alto desempenho com boost Agressivo habilitado. O contador do Windows informou aproximadamente 4,23 GHz e 114% do desempenho nominal numa amostra, sem indicadores de limite de desempenho. Não foi obtida temperatura confiável do pacote da CPU; não se deve declarar ausência absoluta de throttling térmico da CPU com base nisso. Não houve medição de falhas de cache nem justificativa para atribuir a queda a cache defeituoso.

## GPU, RAM e memória virtual

A RTX 5070 tinha folga de utilização e aproximadamente 3,8 GiB de VRAM disponível. A temperatura ficou perto de 44 °C; consultas pontuais não indicaram limitação térmica nem de potência da GPU. O XMP continuava a 3200 MT/s. A memória física não estava esgotada.

O arquivo de paginação estava alocado em 6 GiB, com uso observado de apenas 26 MiB. Houve pequenas entradas de páginas em algumas amostras, mas nenhuma na amostra de menor FPS. O contador inclui páginas vindas de arquivos mapeados, não apenas do pagefile. Não apareceu evidência de paginação intensa responsável pela queda.

Existe uma preocupação distinta: o comprometimento global de memória ficou perto de 35,3 GiB para um limite de 37,9 GiB, deixando cerca de 2,6 GiB de margem. É um risco de estabilidade sob crescimento de carga, mesmo havendo RAM física livre. Não é prova de que tenha causado a queda observada. Nenhuma configuração de memória virtual foi alterada neste diagnóstico. Os ~15,8 GiB privados do cliente são memória comprometida, não equivalem a 15,8 GiB de RAM física residente.

## Reprodução e limitações

Configuração: cópia descartável do mundo Titânico, servidor local, D3D11, 1280×720, zoom 125%, fundo desligado, High FPS sem teto, simulação configurada para 60 ticks e política experimental do Entropy desativada. As mesmas restrições do laboratório anterior se aplicam: vida de chefes controlada, proteção contra morte e ausência de ataques automatizados do jogador.

| Fase | FPS médio das amostras válidas correlacionadas | Menor janela de ~1 s |
|---|---:|---:|
| Base | 80,93 | 73,98 |
| Mutant | 79,60 | 70,79 |
| Destruidor | 58,93 | 51,24 |
| Após retirar o chefe | 87,40 | 82,85 |

**A queda anterior do Mutant não foi reproduzida nesta rodada:** ele apresentou no máximo 15 projéteis nas amostras válidas. Não é equivalente à rodada anterior com muito mais projéteis. O Destruidor, por outro lado, reproduziu uma queda clara com saturação da thread. Isso também mostra por que um teste isolado acima de 60 FPS não certifica todas as lutas.

A telemetria de hardware foi coletada aproximadamente a cada três segundos, enquanto os quadros foram agregados em lotes de cerca de um segundo. O cruzamento usa a amostra temporal mais próxima, no máximo quatro segundos distante. A instrumentação tem custo próprio, e não identifica pausas individuais de GC. Nenhuma exclusividade de CPU/GPU para o jogo foi presumida: utilização da GPU e memória do sistema são globais. Os processos de laboratório e a coleta foram encerrados ao terminar.

## Conclusão prática

O conjunto de hardware não está demonstrando falta de potência gráfica nem falta de RAM física nesta cena. Um pack com 71 mods, mundo Titânico e muitas entidades pode exceder a capacidade de processamento sequencial do cliente mesmo com essa GPU. Usar todos os núcleos não é uma opção simples de configuração: os callbacks compartilham estado e precisam preservar ordem e sincronização.

O alvo técnico seguinte são os custos de atualização de NPCs/projéteis e preparação do desenho no cliente, medidos por callback e por mod, além de verificar alocações/GC. A investigação anterior encontrou custos distribuídos e não demonstrou que um único hook de Calamity ou Fargo explique tudo. Não há justificativa, com estes dados, para recomendar compra de GPU ou prometer que trocar hardware resolverá todas as quedas.

Evidências: `evidence/hardware-20261108/hardware.jsonl`, `analysis.json`, `boss-frame-measurements.jsonl`, `server-tick-measurements.jsonl`, `boost-pagefile.json`, plano e coletor PowerShell.
