# Multiplayer privado e Vanity experimental

Esta alteração mantém o servidor solo `127.0.0.1:17789` e seus launchers. As novas campanhas são cópias independentes, sem transferência automática de progresso. Não faça merge na main enquanto os ensaios pendentes não forem concluídos.

| Opção | Mods | Save independente | Porta |
|---|---:|---|---:|
| Servidor local existente | 71 | `ServidorLocal-Desempenho` | 17789 |
| Amigos, base preservada | 71 | `Amigos-Desempenho` | 17790 |
| Amigos, Vanity experimental | 72 | `Experimental-Multiplayer-Vanity` | 17791 |

Todos exigem Terraria 1.4.4.9 / tModLoader 2026.9.3.1. Os clientes são configurados para 1920 × 1080 e zoom 0,85, com Better Zoom 5.3.0 preservado. Cada inicialização confere nomes, versões, hashes e dependências dos mods.

## Preparar o anfitrião

Feche todos os clientes e servidores, inclusive submundos. Na pasta da Rev8:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Servidor-Amigos.ps1 -Modo Preparar -Perfil Base
powershell -NoProfile -ExecutionPolicy Bypass -File .\Servidor-Amigos.ps1 -Modo Preparar -Perfil Vanity
```

A origem é a campanha `ServidorLocal-Desempenho`, copiada uma única vez. Prepare a origem com um único mundo e um único personagem local. Depois, cada opção continua seu próprio progresso. A preparação verifica a cópia antes de publicar a pasta final. O `.wld`, `.twld`, `.plr`, `.tplr`, identidade do mundo e dados auxiliares são preservados. Não copie apenas o `.wld` para transferir uma campanha.

## Tailscale

1. Anfitrião e amigo instalam o Tailscale pelo [site oficial](https://tailscale.com/download/windows) e entram em suas próprias contas.
2. No console administrativo, o anfitrião compartilha **somente a máquina do servidor** com o amigo. O amigo aceita o convite. A [documentação oficial para servidores de jogos privados](https://tailscale.com/docs/use-cases/personal-or-at-home-use/share-private-game-server) descreve esse fluxo.
3. Revise a política de acesso do Tailscale para permitir ao amigo apenas TCP 17790 ou 17791 nessa máquina, conforme o perfil escolhido. O compartilhamento da máquina não é, por si só, uma restrição a uma única porta. Não use uma regra ampla como substituição de sua política existente.
4. Não configure port forwarding, DMZ, Funnel ou acesso público. Os scripts não instalam VPN, não enviam convites e não alteram firewall, roteador ou regras do Tailscale.

O launcher consulta o cliente Tailscale local, exige estado conectado e confirma que o IPv4 informado pelo serviço está atribuído ao PC. O servidor recebe `-ip <IPv4-Tailscale> -noupnp`, nunca `0.0.0.0`. Se não houver Tailscale conectado, ele aborta sem fallback.

Inicie o servidor escolhido:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Servidor-Amigos.ps1 -Modo Servidor -Perfil Base
# Ou, para o experimento:
powershell -NoProfile -ExecutionPolicy Bypass -File .\Servidor-Amigos.ps1 -Modo Servidor -Perfil Vanity
```

Aguarde `Listening`. Em outro terminal, o anfitrião abre seu cliente:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Servidor-Amigos.ps1 -Modo Cliente -Perfil Base
# Use -Perfil Vanity nos dois comandos para o experimento.
```

O anfitrião também conecta pelo IP do Tailscale. O cliente local confere endereço, porta e processo do servidor antes de conectar. Há no máximo dois jogadores. Não execute simultaneamente outro servidor Rev8: Subworld Library usa canais compartilhados.

Para teste somente neste PC, acrescente `-Rede Local` ao servidor e ao cliente. Isso mantém a nova cópia em loopback; não altera o servidor solo antigo.

O launcher gera uma única opção `secure` por perfil. Vanity usa `secure=0` na porta 17791 para evitar a expulsão por `Projectile spam` em rajadas legítimas do pacote. Base mantém `secure=1`. O ajuste de Vanity desativa as verificações de spam vanilla vinculadas a essa opção, incluindo blocos e líquidos. Use essa configuração somente no servidor privado. Reinicie pelo launcher para que ele regenere `serverconfig-amigos.txt` antes de carregar o mundo.

## Instalação do amigo

1. Instale Terraria e **tModLoader 2026.9.3.1 para Terraria 1.4.4.9** pela distribuição oficial. Não substitua por uma versão mais nova só porque a Steam a recomenda. O launcher recusará versões diferentes. Para uma instalação oficial arquivada, use a [release v2026.09.3.1 do tModLoader](https://github.com/tModLoader/tModLoader/releases/tag/v2026.09.3.1) e informe sua pasta com `-PastaTml`.
2. Extraia o pacote base Rev8 auditado em uma pasta própria. A atualização de scripts é uma sobreposição para esse pacote: ela não inclui Terraria, tModLoader, mundos ou personagens do anfitrião, nem uma nova redistribuição dos mods de terceiros.
3. Copie os arquivos da atualização para essa pasta. O pacote base deve conter `payload`, `lib`, `profiles` e `configuracoes`. Preserve os arquivos de correções que já acompanham a Rev8.
4. Feche o jogo e execute uma das opções:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Cliente-Amigo.ps1 -Modo Preparar -Perfil Base
powershell -NoProfile -ExecutionPolicy Bypass -File .\Cliente-Amigo.ps1 -Modo Preparar -Perfil Vanity
```

Use somente o perfil combinado com o anfitrião. O modo Vanity baixa o Antisocial diretamente da Workshop via SteamCMD se ele estiver ausente do pacote. Só aceita o hash auditado; se a Workshop atualizar o arquivo, interrompe e exige nova auditoria. Não instala HERO's Mod nem outro mod adicional. Não habilite duplicatas pela Workshop ou mods fora do manifest.

5. Com Tailscale conectado, abra:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\Cliente-Amigo.ps1 -Perfil Base -IpTailscale 100.64.0.1
# Substitua pelo IPv4 que o Tailscale mostra para a máquina do anfitrião.
# Para o experimento, use -Perfil Vanity.
```

6. Crie seu próprio personagem, com nome diferente do anfitrião. Entre em **Multiplayer → Join via IP**, selecione o personagem, informe o IP do Tailscale do anfitrião e a porta **17790 (Base)** ou **17791 (Vanity)**. Para reconectar, repita o mesmo procedimento com o mesmo perfil e personagem.

O instalador cria `saves/ClienteAmigo-Base` ou `saves/ClienteAmigo-Vanity`; não usa os saves normais do usuário. Se houver erro de hash, versão ou dependência, não substitua arquivos aleatoriamente: use o mesmo pacote auditado do anfitrião.

## Configuração de Vanity

Antisocial **1.7**, autor **jopojelly/javidpack**, [Workshop 2564872136](https://steamcommunity.com/sharedfiles/filedetails/?id=2564872136), build tModLoader 2025.6.3.0, 95.782 bytes:

```text
SHA-256 2924fe769d02b427a849a3554c7ee96cc37b6f584513773e8f7d2e6421499a00
```

Metadados do `.tmod`: dependências obrigatórias e opcionais vazias. O pacote inclui `lib/0Harmony.dll`; isso não é um mod adicional a instalar. O binário oficial foi mantido intacto. O [código do autor](https://github.com/JavidPack/Antisocial/blob/1.4/Antisocial.cs) mostra o processamento de slots sociais e a [configuração](https://github.com/JavidPack/Antisocial/blob/1.4/Config.cs) distingue acessórios, armaduras e slots de mods.

```json
{
  "SocialAccessories": -1,
  "SocialArmor": false,
  "ModdedAccessorySlots": true
}
```

`-1` afeta os slots sociais vanilla desbloqueados e utilizáveis, respeitando as condições normais de dificuldade/progressão. Os três slots extras de More Accessories permanecem funcionais, com sua coluna social:

```json
{
  "SlotCount": 3,
  "VanitySlotCount": 0,
  "EnableLoadoutSupport": false,
  "AnyAccessorySocial": true
}
```

Em More Accessories 1.5.1, `VanitySlotCount` converte slots em exclusivamente sociais. Não deve ser configurado para 3 neste perfil. `AnyAccessorySocial` só permite colocar acessórios na coluna social; não concede bônus. Antisocial é o único mecanismo novo de ativação desses bônus.

TooManySlots/Fargo's Equipable Inventory continua instalado, porém `Inventory`, `Piggy`, `Safe` e `Forge` ficam explicitamente `false` apenas no experimento. Isso elimina fontes adicionais de bônus de itens guardados. Atributos nativos de informação de itens vanilla, como relógios no inventário, não são removidos por esta alteração.

Não há uma promessa de eliminar todas as interações entre cópias e acessórios de mods. Evite equipar duas cópias do mesmo acessório ou acessórios mutuamente exclusivos em colunas diferentes até testar essa combinação. Os ensaios medem aplicação duplicada de uma única instância, não reescrevem as regras de balanceamento dos mods.

## Salvamento e encerramento

Antes de iniciar o servidor, há backup verificado por hash dos saves e dados auxiliares em `backups/servidor-amigos/<perfil>/<data>`. O cliente do amigo também faz backup antes de abrir. Backups não são apagados automaticamente.

1. Ambos usam **Save & Exit** e fecham os clientes.
2. No console do servidor, digite **exit** e aguarde o salvamento e o encerramento.
3. Não use `exit-nosave` nem feche o processo à força durante a gravação.

Se a conexão falhar, confirme o IP no Tailscale, perfil/porta, estado `Listening`, política de acesso e versões. `Test-NetConnection <IP-Tailscale> -Port 17790` (ou 17791) verifica somente TCP, não compatibilidade de gameplay. Se o firewall bloquear, avalie manualmente uma regra restrita à rede/interface privada e ao amigo; este pacote não cria regras.

A análise e os resultados do teste do erro de projéteis estão em [PROJECTILE-SPAM-VANITY.md](PROJECTILE-SPAM-VANITY.md).
