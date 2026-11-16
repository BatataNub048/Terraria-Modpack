# T1-A · Woodland

Baseline Rev8CraftingProgression 0.2.0. Candidate 0.3.0. Scope is the six `FargowiltasSouls/*Enchant` IDs below and `Rev8CraftingProgression/WoodlandBundle` on the existing 71-mod profile.

| Item ID suffix | Earliest legitimate inputs |
|---|---|
| WoodEnchant | Craft the three forest-wood armor pieces. Pick Daybloom, shake forest trees for Apple, and catch a squirrel with the Merchant's Bug Net. The original squirrel recipe group remains usable. |
| BorealWoodEnchant | Craft Boreal armor from Snow biome trees. Harvest Shiverthorn, shake Boreal trees for Plum, and craft 300 Snowballs from Snow Blocks. |
| RichMahoganyEnchant | Craft Rich Mahogany armor. Harvest Jungle Moonglow, shake Mahogany trees for Pineapple, and make the Grappling Hook from three Chain plus a Hook at an anvil. A Jungle Piranha can drop the Hook before any boss. The Goblin Tinkerer's purchase route is optional. |
| EbonwoodEnchant | Ebonwood armor, Vile Mushroom, Blackcurrant, and the Painter's Lightless Chasms in Corruption. On Crimson worlds, Fargo's installed recipes convert all four material families at an Altar. |
| ShadewoodEnchant | Shadewood armor, Vicious Mushroom, Blood Orange, and the Painter's Deadland Comes Alive in Crimson. On Corruption worlds, the same Fargo conversions work in reverse. |
| PalmWoodEnchant | Craft Palm Wood armor, collect ocean Coral, and shake ocean palm trees for Banana and Coconut. |

The installed registry contains eight enabled 1:1 Fargo Altar conversions covering wood, mushrooms, fruit, and paintings in both directions. The installed Painter shop code gives the two paintings only their respective evil biome conditions. Single-evil play needs a natural Altar and the native side's materials. It does not require Hardmode, spreading the other evil, or a seeded world with both evils. The station recipe uses only early basic workstations. Exploration, housing and the Painter's arrival, and fruit/drop RNG still matter. [Painter](https://terraria.wiki.gg/wiki/Painter) · [Terraria fruit sources](https://terraria.wiki.gg/wiki/Fruits) · [Hook](https://terraria.wiki.gg/wiki/Hook)

## Changes

- `rev8/source/Rev8CraftingProgression/Crafting.cs` clones each audited enabled Fargo recipe when its owner, exact counted inputs, station, groups and conditions match. The alternate uses the actual Tier 1 tile. It inherits the original crafting callbacks and groups. Shimmer decrafting remains with the original recipe. A recipe mismatch or existing competing Tier 1 recipe prevents cloning.
- Woodland moves to Tier 1 when all six alternates register. Each higher tier recognizes the Tier 1 tile requirement without emulating an Altar. No changes to the Timber Hardmode condition, Terra, the Tier 2–5 upgrade recipes, the Crucible, or disabled Crossmod outputs.
- `rev8/source/Rev8CraftingProgression/build.txt` sets the candidate version. Test code, binaries and raw logs live under the disposable `workbench/fargo-rebalance-audit-20261115/tier1-woodland`. This report is the only added repository document.

## Executed checks

- Candidate and gameplay probe compiled with zero errors and warnings on tModLoader 2026.9.3.1.
- The real client loaded an existing disposable world template. With boss flags and Hardmode off, it crafted all six outputs at a physically placed Tier 1 using supplied legitimate ingredients. All six original routes worked at a separate physical Altar. Red Squirrel satisfied Wood's original group. All eight original cross-evil conversions crafted at the Altar with boss flags off.
- Woodland crafted at Tier 1. Timber stayed unavailable at a Crystal Ball before Hardmode and crafted there after enabling the disposable world's Hardmode flag.
- Each higher physical tier crafted the Tier 1 Wood recipe without granting Altar adjacency. Magic Storage consumed ingredients and stored Wood Enchantment at Tier 1 and again after switching its station to Tier 5.
- One real client joined the disposable loopback dedicated server on port 17834. Woodland activated all six effects and honored the Boreal toggle. The client requested a Wood Enchantment craft, and the server stored the output. The client probe retained a stale “Tier 4” label from its previous use. The fixture deposited `MagicStorage/CombinedStations1Item`, selected the Tier 1 Wood recipe, and the server independently logged the Tier 1 setup. The existing `calamityzeith` join warning did not stop the test.
- Ingredient sources were checked against the installed registry, installed shop code and Terraria references. This was a recipe and availability test using supplied inputs, without grinding each random drop or playing through bosses. The disposable single-player console also logged an InnoVault world-load timeout after the gameplay assertions finished.

Production profiles, saves, the 71-mod lock and third-party binaries were left untouched. Nothing was pushed.
