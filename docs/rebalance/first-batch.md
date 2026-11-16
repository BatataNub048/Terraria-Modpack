# Crafting progression first batch

This page records the 0.1.0 baseline. See [focused verification](focused-verification.md) for the 0.2.0 Woodland accessory and Tier 5 upgrade.

Local implementation in `rev8/source/Rev8CraftingProgression` for Terraria 1.4.4.9 / tModLoader 2026.9.3.1. The approved 71-mod lock is the baseline. The candidate adds one compatibility mod. The installed profiles, original binaries and campaigns were left alone.

| Item | Candidate |
|---|---|
| Woodland Enchantment Bundle | One each of the six original timber enchantments at Magic Storage Combined Stations Tier 2. The bundle is a crafting component. |
| Force of Timber | Bundle + Pearlwood Enchantment at a Crystal Ball, with an explicit Hardmode condition. Tier 3 and the higher stations that emulate the Crystal Ball can also satisfy this station. Using the Crystal Ball means obtaining Pearlwood Enchantment already proves access to the required station. The previous four Divine Geodes are removed. |
| Force of Terra | Original seven enchantments at Combined Stations Tier 2, with the four Divine Geodes removed. Late Pre-Hardmode route relies on access to both ore variants, the Revolver's Shadow Orb/Crimson Heart gate, the Goblin Tinkerer for Ruler and Tinkerer's Workshop, and Underworld materials for Obsidian Enchantment's Molten Skull Rose. The audited Thunder Zapper accepts a Pre-Hardmode Oasis Crate route. |
| Force of Gale | Deferred. Installed Old DLC 0.49 explicitly disables Gale and the five Crossmod ingredient recipes in `DLCRecipeChangesCalamity.PostAddRecipes` under `DisableOfficialFargoDLCEnchantments`, which defaults to true. Old DLC offers some similarly named items under different IDs. Re-enabling those six recipes selectively would change the profile's overlap policy. Disabled crafting entries leave open other acquisition routes. |
| Combined Stations Tier 4 | Tier 3 + Autohammer, crafted at Tier 3 after Plantera. Provides the Tier 3 adjacency set plus Autohammer. Uses a vanilla workbench visual. Existing Tiers 1–3 and the existing Final Tier (design tier 5) retain their recipes and functionality. Tier 4 is an independent upgrade option. The Crucible remains untouched. |

The Timber and Terra overrides edit the existing recipes in place only when their owner, exact ingredient counts, station, conditions and absence of recipe groups match the audited signatures. An already competing replacement or ambiguous original causes a skip. Existing Force item IDs, effects, drops and other recipe variants are unaffected by these edits.

The nested audit registers cross-evil transmutations for the wood, mushrooms, tree fruit and paintings used in the six woodland enchantments. These recipes still require access to one side of each pair. Verify the recipe path from your world's shops and biomes before relying on one world's supply. Combined Tier 2 retains its Alchemy Table, Hellforge and Tinkerer's Workshop gates. [Terraria Tinkerer's Workshop](https://terraria.wiki.gg/wiki/Tinkerers)

## Validation

- Reused the audited disposable loadout. The compatibility mod and assertion probe each compiled with zero errors and warnings on tModLoader 2026.9.3.1.
- The dedicated runtime reached `PostSetupRecipes` with the 71 baseline mods, candidate and probe. `REV8_REBALANCE_TEST_PASS` confirmed exact quantities, one enabled recipe each for the bundle, Timber, Terra and Tier 4, the correct tile and condition bindings, Tier 4 adjacency, both Snow Enchantment alternatives, and unchanged disabled Gale recipes. The process stopped before opening a world.
- The private workspace directory `workbench/fargo-rebalance-audit-20261115` contains the candidate under `Mods/Rev8CraftingProgression.tmod`, the test source under `FargoRecipeAudit/Audit.cs`, and the build and server logs. The assertion probe is for testing only. Nothing was installed in the campaign or pushed.

## Pending checks

- Verify the actual placement and recipes through the client and Magic Storage UI. The isolated dedicated test validates the recipe table, tile adjacency and condition bindings. Physical crafting and remote multiplayer remain separate tests.
- Inspect and exercise the six original accessory hooks before making the bundle equippable. Check toggles, stacking with individual enchantments, Force-level upgrades, and effect source identity in multiplayer. Original accessory behavior is preserved.
- Decide whether to opt into the six Crossmod Gale recipes despite the overlap policy. Leave the global Old DLC option enabled unless intentionally changing its broader scope. Confirm acquisition of each ingredient and check the original Gale movement and combat effects before publishing the earlier progression.
