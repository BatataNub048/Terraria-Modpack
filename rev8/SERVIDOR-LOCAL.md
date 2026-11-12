# Servidor dedicado no mesmo computador

Este modo usa os 71 mods do perfil `TodosRecuperados-Titanico-Desempenho`, incluindo TerrariaPackCompat 1.2.0. O servidor dedicado escuta somente em `127.0.0.1:17789`, para uso no próprio PC. Prepare o perfil e tenha um mundo e um personagem locais com os respectivos arquivos de dados de mods (`.twld` e `.tplr`). O GitHub distribui os scripts e manifests. Os binários dos mods e a campanha vêm da instalação local.

## Abrir

1. Salve e feche todos os clientes e servidores de tModLoader.
2. Execute `Jogar-Desempenho-Servidor-Local.bat`. Se houver mais de um mundo ou personagem, rode pelo terminal com `-Mundo "Nome do mundo.wld" -Personagem "Nome do personagem.plr"`. Use os nomes dos arquivos sem caminho.
3. Na primeira execução, o launcher verifica os mods e cria `saves/ServidorLocal-Desempenho`. As próximas execuções reabrem essa cópia com o mesmo mundo e personagem. O launcher verifica o GUID do mundo e rejeita um caminho de mundo fora da cópia.
4. O servidor abre em console próprio. O cliente abre quando a porta estiver escutando e pertencer ao processo esperado. A conexão usa o personagem da cópia, em 1920 × 1080 e zoom de 85% pelo Better Zoom. O ajuste do launcher só grava resolução e zoom no `config.json` da cópia.

`INICIAR-SERVIDOR-LOCAL.bat` abre só o servidor. Para reconectar, execute `JOGAR-NO-SERVIDOR-LOCAL.bat` ou use Multiplayer → Join via IP no cliente do mesmo perfil. Informe `127.0.0.1` e porta `17789`.

Deixe a janela do servidor aberta, podendo minimizá-la, e mantenha o jogo em primeiro plano. Uma janela de console de submundo pode aparecer por causa de Subworld Library; volte à janela do jogo para evitar a redução de FPS em segundo plano. Não inicie outra instância de servidor: Subworld Library possui canais compartilhados que já causaram conflito em testes anteriores.

## Encerrar salvando

1. No cliente, use Save & Exit e feche o jogo.
2. Na janela do servidor, digite `exit` e pressione Enter.
3. Aguarde o salvamento e o encerramento completo. Não desligue o computador nem feche à força a janela durante o salvamento. Não use `exit-nosave`.

O autosave permanece ativo. Antes de cada inicialização do servidor, o launcher copia os mundos, personagens, dados auxiliares do Vault e Calamity, preferências e configurações para `backups/servidor-local/<data>`. Uma pasta com `.preparando-` no nome representa uma cópia incompleta. Preserve os backups concluídos enquanto avalia a sessão.

## Progresso e compatibilidade

A campanha do servidor e a campanha single-player original passam a ter progressos separados. Jogar no launcher antigo não transfere o progresso do servidor. Para uma transferência futura, feche todos os processos e preserve juntos Worlds, Players, VaultSave e demais dados auxiliares; não substitua apenas o .wld.

O servidor local reduz a disputa entre o cliente e algumas tarefas de mundo, mas o cliente ainda atualiza entidades e desenha. Não há garantia de 60 FPS em todas as cenas. O InnoVault desativa seu diretor de cenários em multiplayer; também foram identificadas pendências de sincronização em integrações. O modo Infernum estava desativado na campanha usada nos testes. Não há certificação de multiplayer de todos os chefes, submundos e máquinas.

O script exige a versão exata do tModLoader do manifest e verifica os mods antes de iniciar. Consulte a [revisão e os resultados medidos](REVISAO-SERVIDOR-LOCAL.md).
