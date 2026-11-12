# Modpack Terraria — revisão 7 ampliada

Atualizado em 03/11/2026 para a versão encontrada no PC de destino. **49 mods ativos: 48 da Workshop + a correção local de worldgen.** Terraria 1.4.4.9 / tModLoader stable 2026.9.3.1.

A revisão 7 atualiza o alvo do tModLoader para 2026.9.3.1 e conserva os 49 mods, hashes e presets da revisão 6. O bloqueio da imagem era diferença de versão, não caminho errado. As duas versões anteriores do pacote foram preservadas. Leia [VERSAO-DO-TMODLOADER.txt](VERSAO-DO-TMODLOADER.txt).

Este perfil atende single-player e prepara o mesmo conjunto para multiplayer. Recupera **25 entradas em relação ao perfil padrão de 25 mods** e retira Census por um erro reproduzido com LuiAFK. Extras e Wing Slot, antes opcionais, entram no padrão. O pacote anterior foi preservado.

Por que faltavam mods? A seleção anterior também os excluía por escopo, balanceamento e redundância; isso não demonstrava conflito. O critério foi revisto. Agora as exclusões têm motivo técnico identificado, relato específico ainda não reproduzido ou impossibilidade de obter/verificar o mod. Não é possível garantir ausência de todos os bugs. Leia [MODS-E-COMPATIBILIDADE.md](MODS-E-COMPATIBILIDADE.md) antes de interpretar uma inclusão como certificação.

O More Accessories informado (2825583251) foi identificado corretamente, mas ficou fora provisoriamente por relatos de lag/falha na seleção de personagem. Desligar loadouts contorna outro problema reconhecido pelo autor, não esses relatos.

Abra [COMO-INSTALAR-E-JOGAR.txt](COMO-INSTALAR-E-JOGAR.txt) para instalar e [TESTE-INICIAL-MULTIPLAYER.txt](TESTE-INICIAL-MULTIPLAYER.txt) para testar. O BAT pede a pasta do jogo; mods e saves pertencem à pasta de dados do usuário. No caso das cópias duplicadas mostradas nas imagens, use a **opção 7**, que faz backup verificado antes de substituir as cópias conflitantes. Informar a pasta do jogo sozinho não resolve duplicação de mods.

O ZIP contém o instalador e a documentação; baixa os mods oficiais via SteamCMD. Não é um ZIP com todos os grandes arquivos de música/conteúdo embutidos. Internet é necessária na primeira instalação. Se a Workshop atualizar um arquivo, o lock pode recusá-lo: revisar a nova versão, nunca ignorar hash divergente.

Veja [CONFIGURACOES.md](CONFIGURACOES.md), [VERIFICACAO.md](VERIFICACAO.md) e [CONTINUIDADE.md](CONTINUIDADE.md). Lista exata: [manifest.lock.json](manifest.lock.json). Valores aplicados: [config-preset.json](config-preset.json). Histórico de backup: pasta backups criada ao executar; preserve-a para restauração.

## Inventário completo

| Mod | Versão | Lado | Dependências obrigatórias declaradas |
|---|---|---|---|
| [Calamity Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2824688072) | 2.2.4 | Both | CalamityModMusic |
| [Calamity Mod Music](https://steamcommunity.com/sharedfiles/filedetails/?id=2824688266) | 2.1 | Both | — |
| [Subworld Library](https://steamcommunity.com/sharedfiles/filedetails/?id=2785100219) | 2.3.0.1 | Both | — |
| [The Stars Above](https://steamcommunity.com/sharedfiles/filedetails/?id=2563862309) | 2.1.8.4 | Both | SubworldLibrary |
| [Thorium Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2909886416) | 1.7.2.8 | Both | — |
| [Fargo's Music Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2782337219) | 0.1.7.3 | Client | FargowiltasSouls@1.4 |
| [Fargo's Mutant Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2570931073) | 3.3.6.7 | Both | — |
| [Fargo's Souls Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2815540735) | 1.7.3.9 | Both | Fargowiltas@3.3.6, Luminance@1.0.3 |
| [Luminance](https://steamcommunity.com/sharedfiles/filedetails/?id=3222493606) | 1.0.14 | Both | — |
| [Terraria Pack - Worldgen Guard (local)](source/TerrariaPackGuard/TerrariaPackGuard.cs) | 1.0.0 | Both | ThoriumMod@1.7.2.8, FargowiltasSouls@1.7.3.9 |
| [Fargos Souls Mod Old DLC Recreation](https://steamcommunity.com/sharedfiles/filedetails/?id=3437488846) | 0.49 | Both | Fargowiltas@3.3.6.1, FargowiltasSouls@1.7.2.4 |
| [Ragnarok Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=3114886209) | 1.6.0.10 | Both | ThoriumMod, CalamityMod |
| [Unofficial Calamity Bard & Healer](https://steamcommunity.com/sharedfiles/filedetails/?id=3142064272) | 0.13.10 | Both | ThoriumMod, CalamityMod |
| [Fargo's Soul Mod Extras](https://steamcommunity.com/sharedfiles/filedetails/?id=2906451681) | 0.6.2 | Both | FargowiltasSouls@1.6 |
| [AlchemistNPC Lite](https://steamcommunity.com/sharedfiles/filedetails/?id=2599842771) | 1.9.9 | Both | — |
| [Angler Shop](https://steamcommunity.com/sharedfiles/filedetails/?id=2563082541) | 3.2.0.5 | Both | — |
| [Magic Storage](https://steamcommunity.com/sharedfiles/filedetails/?id=2563309347) | 0.7.0.11 | Both | SerousCommonLib@1.0.6.2 |
| [Shop Expander](https://steamcommunity.com/sharedfiles/filedetails/?id=2828370879) | 1.8.1 | Both | — |
| [Unofficial Fargo's x Shop Expander](https://steamcommunity.com/sharedfiles/filedetails/?id=3460220112) | 0.2 | Both | Fargowiltas, ShopExpander |
| [absoluteAquarian Utilities (SerousCommonLib)](https://steamcommunity.com/sharedfiles/filedetails/?id=2908170107) | 1.0.6.2 | Both | — |
| [Auto Trash](https://steamcommunity.com/sharedfiles/filedetails/?id=2565540604) | 0.8.1.1 | Both | — |
| [Basic Automated (Vein) Mining](https://steamcommunity.com/sharedfiles/filedetails/?id=2838188064) | 1.3.1 | Both | — |
| [Better Zoom](https://steamcommunity.com/sharedfiles/filedetails/?id=2562953970) | 5.3.0 | Client | — |
| [Boss Checklist](https://steamcommunity.com/sharedfiles/filedetails/?id=2669644269) | 2.2.4 | Both | — |
| [Recipe Browser](https://steamcommunity.com/sharedfiles/filedetails/?id=2619954303) | 0.12.0.3 | Both | — |
| [Wing Slot Extra](https://steamcommunity.com/sharedfiles/filedetails/?id=2597324266) | 1.4.9 | Both | — |
| [Which Mod Is This From? (WMITF)](https://steamcommunity.com/sharedfiles/filedetails/?id=2563851005) | 2.7.1 | Client | — |
| [Fargo's Best of Both Worlds](https://steamcommunity.com/sharedfiles/filedetails/?id=2802867430) | 0.5.3 | Both | — |
| [Shared World Map](https://steamcommunity.com/sharedfiles/filedetails/?id=2815010161) | 0.1.5.1 | Both | — |
| [Vanilla Calamity Mod Music](https://steamcommunity.com/sharedfiles/filedetails/?id=2816188633) | 2.1.3 | Both | — |
| [Boss Cursor](https://steamcommunity.com/sharedfiles/filedetails/?id=2816694149) | 3.0.1 | Client | — |
| [LuiAFK Reborn](https://steamcommunity.com/sharedfiles/filedetails/?id=2831752947) | 1.2.5 | Both | — |
| [Calamity Mod Extra Music](https://steamcommunity.com/sharedfiles/filedetails/?id=2835214226) | 2.0.0 | Client | — |
| [Catalyst Mod](https://steamcommunity.com/sharedfiles/filedetails/?id=2838015851) | 1.1.8 | Both | CalamityMod |
| [Calamity Rarities](https://steamcommunity.com/sharedfiles/filedetails/?id=2853817477) | 1.2.2 | Both | CalamityMod |
| [Calamity Ranger Expansion](https://steamcommunity.com/sharedfiles/filedetails/?id=2860270524) | 1.2.2.1 | Both | CalamityMod@2.2 |
| [Craftable Calamity Items](https://steamcommunity.com/sharedfiles/filedetails/?id=2891420130) | 4.7.12 | Both | CalamityMod |
| [Starter Bags](https://steamcommunity.com/sharedfiles/filedetails/?id=2947735494) | 0.1.4.4 | Both | — |
| [Pets Overhaul](https://steamcommunity.com/sharedfiles/filedetails/?id=2982195397) | 3.9.5 | Both | — |
| [Better Boss Health Bar for 1.4.4+](https://steamcommunity.com/sharedfiles/filedetails/?id=3018447913) | 0.9.2.4 | NoSync | — |
| [Better Zenith in Calamity](https://steamcommunity.com/sharedfiles/filedetails/?id=3024992349) | 0.6 | Both | CalamityMod |
| [Magic Storage Starter Bag](https://steamcommunity.com/sharedfiles/filedetails/?id=3281576339) | 3.2 | Both | MagicStorage |
| [Munchies - Consumables Checklist](https://steamcommunity.com/sharedfiles/filedetails/?id=3310041861) | 1.4.2 | Client | — |
| [Munchies - Calamity Addon](https://steamcommunity.com/sharedfiles/filedetails/?id=3312725122) | 1.3.1 | Client | Munchies@1.4, CalamityMod@2.0.4.3 |
| [Pets Overhaul: Calamity Addon](https://steamcommunity.com/sharedfiles/filedetails/?id=3352461632) | 1.5.1.3 | Both | PetsOverhaul@3.9, CalamityMod@2.2 |
| [Ability To Read](https://steamcommunity.com/sharedfiles/filedetails/?id=3408499520) | 0.1 | Both | — |
| [Calamity Fables](https://steamcommunity.com/sharedfiles/filedetails/?id=3449156562) | 0.1.24 | Both | — |
| [Infernum Mode Music](https://steamcommunity.com/sharedfiles/filedetails/?id=3458992153) | 2.0.1.8 | Both | — |
| [Calamity: Wrath of the Machines](https://steamcommunity.com/sharedfiles/filedetails/?id=3486967746) | 1.0.5 | Both | CalamityMod, Luminance |

Referências fracas/condicionais estão no manifest; não são automaticamente novas dependências. Mods Client não são executados pelo servidor dedicado. Nenhum FPS foi medido no outro PC e não houve conexão de jogadores reais nesta auditoria.
