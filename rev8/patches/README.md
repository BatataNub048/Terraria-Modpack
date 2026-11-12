# Alterações locais

| Mod | Alteração | Versão local |
|---|---|---|
| Census | Mantém o registro já feito pelo caminho legado de `TownNPCCondition` e retorna sucesso ao LuiAFK | 0.5.2.9 |
| Calamity’s Vanities | Usa o nome `SetDRSpecific` e passa a instância do NPC nas chamadas de redução e defesa | 11.4.2.1 |
| Calamity Entropy Legacy | Transforma o acesso a `OutlineShader` em método para evitar injeção de um asset já carregado manualmente. Adiciona os construtores que o carregador de partículas procura | 3.39.1 |
| Calamity Overhaul | Ajusta a prioridade de SelfRig e trata as peças compartilhadas das variantes Beetle e Spectre no GodSmith, incluindo suas prévias de conjunto | 0.9209.2 |
| Munchies Calamity Addon | Registra os consumíveis atuais de vida e usa a API de consumíveis permanentes do Calamity 2.2.4 | 1.3.1.1 |
| TerrariaPackCompat | No Whips 1.2.2, retira a associação órfã da cauda de Scraper of Stars com um banner cujo NPC representante não registra item | 1.0.0 |

Os diffs têm repositório e commit em `origens.json`. Cada build foi feito com o tModLoader 2026.9.3.1. O código do TerrariaPackCompat está em `source/TerrariaPackCompat`.

Para reconstruir um port, obtenha o commit indicado numa pasta com o nome interno do mod, aplique seu diff com `git apply` e prepare um diretório de dados de compilação separado contendo os mods requeridos em `Mods`. A partir da pasta do tModLoader, execute o runtime local com:

```powershell
.\dotnet\dotnet.exe .\tModLoader.dll -server -nosteam -tmlsavedirectory "<dados-de-compilacao>" -build "<pasta-do-codigo>" -unsafe true
```

Use uma pasta de tModLoader cujo caminho não contenha um componente começando em `runtime`. A busca de referências desta versão filtra caminhos que contêm `/runtime` e pode descartar também FNA e ReLogic se o nome for usado numa pasta ancestral. O build gravará o .tmod em `Mods` dentro dos dados de compilação. Uma recompilação produz um arquivo novo que deve passar pelos testes e pelo cálculo de hash antes de substituir o conteúdo deste pacote.
