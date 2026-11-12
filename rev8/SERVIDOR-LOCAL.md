# Servidor dedicado no mesmo computador

Este modo utiliza os 71 mods auditados do perfil de desempenho e TerrariaPackCompat 1.2.0. O laboratório de medição não faz parte do perfil jogável. O servidor escuta apenas em 127.0.0.1:17789: serve para jogar neste PC, sem abrir acesso pela internet ou alterar firewall/roteador.

## Abrir

1. Salve e feche todos os clientes e servidores de tModLoader.
2. Execute `INICIAR-SERVIDOR-LOCAL.bat`.
3. Na primeira execução, o launcher cria uma cópia independente de `TodosRecuperados-Titanico-Desempenho` em `saves/ServidorLocal-Desempenho`, conferindo os arquivos copiados. Nas próximas, usa essa cópia com seu progresso, sem copiá-la novamente por cima.
4. Aguarde o console mostrar `Listening on port 17789` / `Server started`.
[Referência local omitida.]

Deixe a janela do servidor aberta, podendo minimizá-la, e mantenha o jogo em primeiro plano. Uma janela de console de submundo pode aparecer por causa de Subworld Library; volte à janela do jogo para evitar a redução de FPS em segundo plano. Não inicie outra instância de servidor: Subworld Library possui canais compartilhados que já causaram conflito em testes anteriores.

## Encerrar salvando

1. No cliente, use Save & Exit e feche o jogo.
2. Na janela do servidor, digite `exit` e pressione Enter.
3. Aguarde o salvamento e o encerramento completo. Não desligue o computador nem feche à força a janela durante o salvamento. Não use `exit-nosave`.

O autosave permanece ativo. Antes de cada inicialização do servidor, o launcher copia os mundos, personagens, dados auxiliares do Vault e configurações para `backups/servidor-local/<data>`. Esses backups não são removidos automaticamente e ocupam espaço.

## Progresso e compatibilidade

A campanha do servidor e a campanha single-player original passam a ter progressos separados. Jogar no launcher antigo não transfere o progresso do servidor. Para uma transferência futura, feche todos os processos e preserve juntos Worlds, Players, VaultSave e demais dados auxiliares; não substitua apenas o .wld.

O servidor local reduz a disputa entre o cliente e algumas tarefas de mundo, mas o cliente ainda atualiza entidades e desenha. Não há garantia de 60 FPS em todas as cenas. O InnoVault desativa seu diretor de cenários em multiplayer; também foram identificadas pendências de sincronização em integrações. O modo Infernum estava desativado na campanha usada nos testes. Não há certificação de multiplayer de todos os chefes, submundos e máquinas.

O script exige a versão exata do tModLoader do manifest e verifica os mods antes de iniciar. Não altera BIOS, afinidade da CPU, drivers nem configurações globais do Windows.

Os resultados do ensaio de salvamentos serão registrados em `RESULTADOS-SALVAMENTO.md` após a comparação.
