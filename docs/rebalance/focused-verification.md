# Focused verification · Rev8CraftingProgression 0.2.0

## Disabled Crossmod content

Old DLC Recreation 0.49 runs `DLCRecipeChangesCalamity.PostAddRecipes`. With `FargowiltasCrossmod` loaded and `DisableOfficialFargoDLCEnchantments` true, it calls `DisableRecipe` for every recipe resulting in the 13 named Crossmod items. The installed config omits the setting, and the installed assembly supplies `DefaultValue(true)`. It disables crafting recipes while leaving the items and accessory hooks registered. Avoiding overlap appears to be the design intent. The selector is a fixed ID list and does not compare item effects.

[Comparison CSV](disabled-crossmod.csv) lists all 11 disabled enchantments, both Forces, and 11 related Old DLC items. It gives full IDs, ingredients, tiles, effect keys, observed hook methods and direct registered recipe consumers. Crossmod hook methods include their delegated effect callbacks where inspected. Old DLC rows show the accessory entry point and effect registrations. None of the compared pairs can be treated as a drop-in functional duplicate. Several share a theme or Calamity armor and have overlapping behavior.

| Crossmod enchantment | Distinction relevant to a rebalance |
|---|---|
| Aerospec | Jump-driven scaling. Old DLC includes distinct toggles, a minion and accessory effects. |
| Daedalus | Crossmod has equip, extra-attack and hurt hooks, including an arrow projectile. Old DLC adds a minion and several independently registered accessories. |
| Desert Prowler | Crossmod has a dive and extra-jump interaction. Old DLC registers its own effects and Tesla's Amulet. |
| Hydrothermic | Crossmod has endurance and vent shots plus a hurt hook. The same-armor Old DLC counterpart is Ataxia, with different ingredients and effect registrations. |
| Reaver | Crossmod registers an active skill with hurt, regeneration and speed effects. Old DLC also has separate Bloom Stone, glove and Bee effects. |
| Snow Ruffian | Crossmod has a separate equip and draw hook. Old DLC also grants separately registered jewel, bangle and Frozen Cube behavior. |
| Statigel | Crossmod scales damage with speed and has specific Gale behavior. Old DLC grants its own set and accessory effects. |
| Sulphur | Crossmod enables its Sulphur jump and extra-attack effect. Old DLC Sulphurous adds several separately toggled accessories. |
| Titan Heart | Crossmod adds Stress Pills and adrenaline-scaled mitigation. Old DLC activates the armor set flag and adds rogue stealth and knockback immunity. |
| Victide | Crossmod fires spike volleys. Old DLC also invokes Luxor's Gift and Shield of the Ocean. |
| Wulfrum | Crossmod spawns a single scanner for the local owner. Old DLC registers Wulfrum Acrobatics behavior. |

**Gale** consumes the five exact Crossmod IDs for Desert Prowler, Snow Ruffian, Statigel, Sulphur and Victide. Its jumps, slow fall and spine projectile are separate effects. The installed spine path scales from 800 base damage. Pre-Hardmode ingredients alone are insufficient evidence that the full Force belongs that early. **Elements** consumes the Crossmod Aerospec, Daedalus, Reaver and Hydrothermic items and has its own active skill and equip bonuses. Titan Heart and Wulfrum sit outside these two direct ingredient lists. The CSV includes the actual registered consumers, including later chains.

No enabled alternate recipe was found for the disabled IDs in the saved registry. A targeted IL reference search found no direct loot, shop, starter or reward method references to those IDs in the two integration assemblies. This does not rule out indirect grants by other code, other mods, or legacy inventory items. There is no verified alternate legitimate acquisition route for those Crossmod IDs in this profile.

**Resolution:** Preserve the current setting. For a future opt-in, enable only verified unique content with a specific gate and test conflicts between the two families. Start with Gale's active effects and power gate before considering its five ingredients. Keep original IDs and progression-specific routes. Avoid substituting same-name Old DLC ingredients without measuring the equipped effects. No Crossmod recipe was enabled in this update.

## Woodland and stations

- Woodland keeps the `Rev8CraftingProgression/WoodlandBundle` ID and is now an accessory derived from Fargo's `BaseEnchant`. It registers the six original effect keys through Fargo, including Wood's equipped discount. The effect loader maintains one active slot per key and uses its native toggle, minion, extra-attack and boss-presence logic. The `BaseEnchant` source classification is essential for Boreal and the Palmwood active skill. The original Timber upgrade still uses Woodland plus Pearlwood at the Crystal Ball in Hardmode. Woodland and Timber are mutually exclusive via the normal accessory equipment hook.
- Tier 4 keeps Tier 3's adjacency and adds Autohammer. Plant-era crafting requires Tier 3, Autohammer and Plantera defeated. No Lunar material is required. No other station addition was needed for this scope. In particular, a Jungle Temple furniture station would add a separate acquisition requirement and is already represented by the furniture line used in the Final Tier.
- The guarded Final Tier recipe upgrades Tier 4 instead of separately consuming Tier 3 and Autohammer. It retains Furniture Tier 2, Ancient Manipulator, Golden Dipping Vat, ten lava buckets and ten honey buckets. The original output ID and tile remain. A tile hook adds Tier 4 recognition while preserving every existing Final Tier capability. The Crucible upgrade and unrelated recipes are outside the override.
- The installed Magic Storage 0.7.0.11 crafting analyzer recognizes station items through `createTile` and calls `TileLoader.AdjTiles` on that tile. Both tier items use this route. Static source verification and the engine adjacency probe cover the integration seam. A live Crafting Access UI craft is still pending.

## Validation results

- **Build:** candidate and probe each compiled with zero errors and warnings on the isolated tModLoader 2026.9.3.1 instance. An earlier probe needed Fargo's toggle namespace and a populated toggle dictionary for its synthetic player. That probe did not exercise a normally initialized game character.
- **Dedicated recipe registry:** passed. Checked Woodland, Timber, Terra, Tier 4, the exact Tier 5 upgrade, the two Snow Enchantment alternatives, and the continued disablement of the 13 Crossmod outputs.
- **Dedicated hook probe:** passed. With a synthetic player and native Fargo toggle entries, all six effects activated. Adding the six individual accessories did not increase the active effect count. Toggling one effect off left the other five active. Checked native enchantment classification for Boreal and Palmwood and the Woodland/Timber equip guard in both directions.
- **Engine adjacency:** passed via `TileLoader.AdjTiles`, the method also called by Magic Storage. Tier 4 inherited Tier 3 and Autohammer without Lunar adjacency. Tier 5 retained its existing adjacency and recognized Tier 4.
- **Gameplay:** no world, physical placement, live storage crafting or client connection was tested. The isolated mod artifact, test source and final logs are under `workbench/fargo-rebalance-audit-20261115`. No installed profile, original binary or existing save was changed.

## Minimal manual checks

Use an isolated save directory with the 71 baseline mods and candidate only. Disable the `FargoRecipeAudit` probe before opening the client. Make a fresh world and character.

1. Equip Woodland, trigger a Boreal and Palmwood action, then toggle each off in Fargo's menu. Try an individual wood enchant together with Woodland and confirm the effect fires once. Try the Timber accessory alongside Woodland and check the equip restriction.
2. With the audited ingredients, check late Pre-Hardmode Terra at Tier 2 and check that Timber remains unavailable until Hardmode. Complete the Timber craft at a Crystal Ball.
3. In a disposable progressed world, place and recover Tier 4. Craft an Autohammer recipe and a Tier 3 recipe beside it. Insert it into Magic Storage Crafting Access and repeat the two recipes. Confirm Lunar recipes are unavailable until swapping to the Final Tier. Upgrade Tier 4 to Final Tier using the saved recipe.
4. Repeat Woodland equip and toggles and one storage craft on an isolated dedicated server with both endpoints running the same candidate. Reconnect and verify the equipped accessory survives.
