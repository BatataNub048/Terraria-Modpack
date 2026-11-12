# Reavaliação após XMP — 08/11/2026

Meta atual: manter pelo menos 60 FPS em chefes. **Ainda não atingida em todos os cenários testados.** Os quatro DIMMs foram confirmados pelo Windows a 3200 MT/s. Resizable BAR e as demais mudanças de BIOS foram informados pelo usuário; não foram reconfirmados por este ensaio.

Foi restaurada uma cópia descartável da campanha com seus dados auxiliares. Configuração: servidor local, D3D11, 1280×720, fundo desligado, zoom 125%, High FPS Support sem teto e simulação configurada em 60 ticks. Os 71 mods foram mantidos, além do suporte de FPS e do laboratório. TerrariaPackCompat 1.3 estava presente, mas sua política experimental de históricos foi desativada pelo controlador; as seis otimizações anteriores continuaram ativas.

| Fase | FPS médio válido | Menor janela válida de aproximadamente 1 segundo |
|---|---:|---:|
| Base | 79,69 | 75,97 |
| Destruidor | 82,51 | 75,78 |
| Yharon | 81,00 | 74,12 |
| Mutant | 70,53 | 46,85 |

Foram descartadas seis amostras do Destruidor e dez de Yharon por foco, ausência do chefe ou estado inválido. Essas exclusões reduzem a cobertura; os resultados válidos não certificam uma luta completa. O Mutant teve todas as amostras válidas e ainda apresentou queda abaixo de 60.

Os chefes tiveram vida controlada, o jogador estava protegido contra morte e não houve ataques de arma automatizados. Yharon foi testado fora da selva. Não é uma medição de quatro jogadores, arsenal completo ou todas as fases de todos os chefes. Os resultados não permitem atribuir todo o ganho ao XMP: há variação de entidades, projéteis e condições entre rodadas.

Não foi instalado esse conjunto experimental na campanha jogável. O perfil de desempenho existente permanece em Compat 1.2.0. A configuração multiplayer tem pendências de sincronização identificadas nos ensaios, e a política adicional do Entropy não apresentou ganho consistente na repetição em ordem inversa realizada anteriormente.

O limite restante está no processamento e desenho do cliente sob carga. Uma média acima de 60 não garante um mínimo de 60; limitar a 60 também não corrige os quadros que já excedem 16,67 ms. A próxima correção precisa partir de medições detalhadas do Mutant e de seus projéteis, acompanhadas de validação de efeitos, colisão e rede. A meta não foi marcada como concluída.

Dados brutos, plano, ticks do servidor e resumo estão em `evidence/fps-20261108-xmp`. Os testes foram encerrados após a coleta, sem promover o laboratório a perfil de campanha.
