# Terraria Modpack Rev8

O pacote usa Terraria 1.4.4.9 e tModLoader estável 2026.9.3.1. Os binários usados nesta revisão estão em `payload`, com SHA-256, versões e dependências registrados nos quatro manifests. A extensão de Mundos Titânicos preserva os manifests e saves dos dois perfis originais; consulte [MUNDOS-TITANICOS.md](MUNDOS-TITANICOS.md) para testes, limites e instruções.

A [revisão do cliente de 05/11/2026](REVISAO-CLIENTE.md) corrige a falha de carregamento do Munchies e os registros duplicados do GodSmith. Os dois perfis foram testados até a entrada em um mundo Expert.

| Perfil | Mods ativos | Uso |
|---|---:|---|
| Ampliado | 67 | Conjunto com os ports, para validar uma nova campanha |
| TodosRecuperados | 70 | Experimento com o DLC oficial do Fargo, Infernum e o backup do Calamity Magic Storage, além dos 67 do Ampliado |
| Ampliado-Titanico | 68 | Os mesmos 67 do Ampliado, mais Mundos Titânicos com correção local de criação no servidor dedicado |
| TodosRecuperados-Titanico | 71 | Os mesmos 70 do TodosRecuperados, mais Mundos Titânicos; conjunto mais experimental |
| TodosRecuperados-Titanico-Desempenho | 71 | TerrariaPackCompat 1.2.0; clona a campanha com o jogo fechado. Ganho medido modesto; veja [DESEMPENHO.md](DESEMPENHO.md) e os [ensaios de 120 FPS](DESEMPENHO-120FPS.md). |

Execute `Jogar-Ampliado.bat`, `Jogar-TodosRecuperados.bat`, `Jogar-Ampliado-Titanico.bat` ou `Jogar-TodosRecuperados-Titanico.bat` para preparar e abrir o perfil correspondente. A preparação leva algum tempo porque copia e confere os mods. Cada perfil tem uma pasta própria em `saves` para mundos, personagens e configurações. Crie um personagem e um mundo novos para experimentar. Os mundos `Rev8-Expert` dos perfis titânicos são ensaios descartáveis, não campanhas existentes.

Em PowerShell, na pasta desta revisão, os comandos equivalentes são:

```powershell
.\Executar-Perfil.ps1 -Perfil Ampliado -Modo Preparar
.\Executar-Perfil.ps1 -Perfil Ampliado -Modo Verificar
.\Executar-Perfil.ps1 -Perfil Ampliado -Modo Cliente
.\Executar-Perfil.ps1 -Perfil Ampliado -Modo Servidor
```

Se a instalação não for encontrada, informe `-PastaTml` com a pasta que contém `tModLoader.dll`. O launcher passa `-Endereco 127.0.0.1` por padrão; confira a interface realmente aberta antes de disponibilizar o servidor em rede. O cliente usa conexão por IP com a opção `-nosteam`. Antes de uma campanha em rede, use o mesmo perfil e os mesmos binários em todos os participantes, valide a conexão e teste salvamento e reconexão. Faça uma cópia completa da pasta do perfil com o jogo e o servidor fechados antes de qualquer alteração.

O [inventário original](inventario-original.json) relaciona cada uma das 60 entradas aos binários que puderam ser recuperados. Os [patches](patches/README.md) documentam as alterações e as origens. O [relatório](RESULTADOS.md) indica o que passou nos ensaios e os riscos que exigem testes no jogo.
