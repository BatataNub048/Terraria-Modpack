# Terraria-Modpack
Modpack personalizado de Terraria/tModLoader, incluindo lista de mods, versões, configurações, compatibilidade e histórico de alterações.

O projeto tem como alvo **Terraria 1.4.4.9 e tModLoader 2026.9.3.1 estável**. A Rev8 reúne cinco perfis, com listas de mods fixadas por versão e SHA-256. A Rev7 fica arquivada para consulta e reprodução histórica.

| Perfil Rev8 | Mods | Propósito |
|---|---:|---|
| Ampliado | 67 | Conteúdo ampliado e correções locais |
| TodosRecuperados | 70 | Integrações e mods recuperados em avaliação |
| Ampliado-Titanico | 68 | Ampliado com Mundos Titânicos |
| TodosRecuperados-Titanico | 71 | TodosRecuperados com Mundos Titânicos |
| TodosRecuperados-Titanico-Desempenho | 71 | Variante com TerrariaPackCompat 1.2.0 |

As listas e hashes ficam em [rev8/profiles](rev8/profiles). As [configurações JSON por perfil](rev8/configuracoes) registram os ajustes existentes e servem de referência para aplicação deliberada. Os presets definidos nos manifests continuam sendo o que os launchers aplicam na preparação padrão.

Para preparar uma instalação, obtenha os artefatos exatos pelos meios autorizados de cada mod, incluindo as variantes locais que o manifest exige, e organize-os em `rev8/payload` conforme `payloadFile` ou o nome interno do mod. Os launchers conferem esses arquivos antes de preparar o perfil. O clone contém documentação, código próprio e metadados. Os binários precisam ser fornecidos separadamente. A disponibilidade de uma versão na Workshop não garante que seu hash coincida com o manifest.

- [Versões e histórico](docs/VERSOES.md)
- [Guia original da Rev8](rev8/README.md)
- [Relatório de compatibilidade](rev8/RESULTADOS.md)
- [Desempenho e limites dos ensaios](rev8/DESEMPENHO-POS-XMP.md)
- [Rev7 arquivada](historico/rev7/README.md)
- [Instruções para manutenção](AGENTS.md)
