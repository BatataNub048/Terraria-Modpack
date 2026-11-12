# Verificação — revisão 7 — 03/11/2026

**Alvo: tModLoader stable 2026.9.3.1 / Terraria 1.4.4.9.** A versão oficial foi baixada para uma pasta de teste separada e seu SHA256 conferido contra o digest publicado no GitHub: 5aaed81b245044286c3ade200f8bac9162ef932ee8ff11a31e05da49a186c07b. O tModLoader instalado no PC do usuário não foi alterado. Fonte: https://github.com/tModLoader/tModLoader/releases/tag/v2026.09.3.1 .

## Resultado novo desta revisão

- 49 mods instalados e conferidos: mesmos nomes, versões, hashes e presets da rev6. Nenhum mod trocado para fazer o teste passar.
- 42 mods carregados pelo servidor dedicado; 7 client-side não exercitados graficamente.
- Mundo Large / Expert, seed codex-20261102, gerado e gravado; arquivos WLD/TWLD existentes. Servidor chegou a Server started.
- Mundo salvo reaberto em uma segunda execução com 2026.9.3.1; servidor chegou novamente a Server started.
- 21 verificações de código, 8 de portabilidade/backup/restauração e 9 do BAT/prompt aprovadas novamente com o alvo novo.
[Referência local omitida.]
- Prompt aceita a versão nova; pasta errada, versão divergente, cancelamento e caminhos com aspas/símbolos continuam tratados antes de alterar mods/saves.
- Nenhum registro de nível ERROR nos logs finais de geração e reabertura. CRC e SHA256 de cada entrada do ZIP conferidos no empacotamento.

Evidências em evidence: server.log, reopen-server.log, consoles, world-files.json, install-release, installer-tests.json, portability-tests.json, path-prompt-tests.json, verification-inventory.csv e tml-official-release.json. Os registros selection-history-rev6 explicam exclusões anteriores; não são resultados de tModLoader 2026.9.3.1. Recibos de download são da obtenção dos mesmos binários na auditoria anterior; a nova instalação usou esse cache e repetiu a integridade.

## Limites reais

Avisos de clonagem de referências e chamada obsoleta de cooldown continuam nos mods base. O console redirecionado do ensaio registra IOException / Identificador inválido; o servidor chega ao estado iniciado, mas não processa exit por stdin. O processo de teste foi encerrado após 15 segundos nesse estado. Não foi certificado encerramento gracioso. A reabertura valida os arquivos gerados, não todas as operações futuras de salvamento.

Não houve cliente gráfico, personagem criado pela UI, jogadores conectados, campanha, combate completo, viagens Stars Above ou medição de FPS no PC de destino. O servidor de teste usa loopback e não abre portas do roteador. Siga TESTE-INICIAL-MULTIPLAYER.txt no outro PC. Este teste não garante ausência de bugs nem ganho de desempenho.

O erro mostrado pelo usuário era uma recusa de versão na rev6, antes da instalação, e não evidência de conflito entre os mods. A rev7 mantém validação estrita para 2026.9.3.1; atualizações futuras requerem nova revisão.
