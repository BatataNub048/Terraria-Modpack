# Desconexão por Projectile spam no servidor Vanity

Perfil experimental com 72 mods, porta 17791, Terraria 1.4.4.9 e tModLoader 2026.9.3.1. A análise usou os logs da sessão afetada e o código decompilado do binário instalado.

## Causa

O servidor registrou que desconectou o jogador por `Cheating attempt detected: Projectile spam`. O cliente recebeu a mesma mensagem. Em `Terraria.MessageBuffer.GetData`, o pacote 27 (`SyncProjectile`) incrementa `RemoteClient.SpamProjectile` quando cria ou reinicializa um projétil no servidor. `Terraria.RemoteClient.SpamUpdate` aplica o limite padrão de 100 e expulsa com a chave `Net.CheatingProjectileSpam` quando o contador passa do limite e `Terraria.Netplay.SpamCheck` está ligado. Essa é a proteção de Terraria incluída no runtime do tModLoader, não uma detecção do Antisocial ou de outro mod. Os logs antigos não identificam a arma ou o mod que gerou o volume de projéteis naquela sessão.

O arquivo indicado por `-config` no log continha `secure=0` e `secure=1`. O método `Terraria.Main.LoadDedConfig` só trata o valor `1`, ativando `Netplay.SpamCheck`. A linha com `0` é ignorada. O campo inicia como `false` em cada processo e também pode ser ativado por `-secure`. O servidor principal não recebeu `-secure` na linha de comando. O filho de Subworld Library recebeu a flag na execução anterior, após a ativação no servidor principal.

## Correção

`Servidor-Amigos.ps1` escreve somente `secure=0` para Vanity e somente `secure=1` para Base. O arquivo é regenerado a cada inicialização do servidor. A correção não exige editar o arquivo gerado, recompilar mods ou modificar o binário do tModLoader. O bind privado, o limite de jogadores e a desativação de UPnP permanecem como antes. `secure=0` deixa inativas as verificações vanilla de spam de projéteis, blocos e líquidos nessa instância Vanity. Use somente com jogadores de confiança na rede privada.

## Teste A/B em cópias descartáveis

O servidor usou a porta 17791 em `127.0.0.1`, com os 72 mods auditados nos dois ensaios. O mundo e os dados auxiliares do servidor foram restaurados da mesma origem antes de B. Cada cliente partiu de uma cópia do personagem. Um módulo temporário, exclusivo dos clientes de teste, equipou uma Chain Gun e gerou uma rajada de balas vanilla pelo caminho normal de sincronização. O módulo não integra o perfil. O consumo de munição não foi confirmado separadamente.

| Caso | Opção gerada | Resultado |
|---|---|---|
| A, launcher anterior | `secure=0` e `secure=1` | Cliente entrou. O servidor expulsou por `Projectile spam` durante a rajada. |
| B, launcher corrigido | `secure=0` | Cliente entrou, gerou 1.440 projéteis em 240 ticks, continuou conectado até o tick 1.080 e saiu normalmente. Nenhum registro de expulsão por `Projectile spam`. |

O filho de Subworld Library em B iniciou sem `-secure`. O servidor corrigido encerrou via `exit` e gravou o mundo e os dados de mods. A auditoria de produção confirmou os 72 mods e o teste `Test-PrivateNetwork.ps1` passou nas 17 verificações em Windows PowerShell 5.1. Os 199 arquivos originais do perfil Vanity conferiram por SHA-256. Os dados de laboratório ficam em `workbench/rev8-vanity-lab-projectile`, fora do Git.

A correção está validada para a desconexão reproduzida em loopback. O ensaio não incluiu um segundo PC via Tailscale. O aviso pré-existente de leitura de pacote do Better Zenith in Calamity também apareceu na rodada corrigida e não impediu a conexão.
