# Fargo crafting station audit

The installed Magic Storage 0.7.0.11 has **four** Combined Stations items. The approved rebalance has **five** progression tiers. Its current Final Tier is the Lunar station, despite the internal suffix `4`. A separate Post-Plantera/Golem tier requires a new station or a deliberate split of the existing chain.

| Approved tier | Verified current recipe gate | Implementation proposal |
|---|---|---|
| Tier 1 · early Pre-Hardmode | `MagicStorage/CombinedStations1Item` combines eight basic stations. | Use the existing tile for verified early recipes. Check its full furniture requirements before selecting it for starter wood. |
| Tier 2 · late Pre-Hardmode | Succeeds Tier 1. The Alchemy Table, Hellforge and Tinkerer's Workshop can impose Dungeon, Underworld and Goblin progression. | Use the existing tile if all three gates fit. Give earlier recipes an appropriate native station where this tier would delay them. |
| Tier 3 · early Hardmode | Succeeds Tier 2 and needs the Hardmode anvil, forge, Crystal Ball, Blend-O-Matic and other stations. | Use the existing tile after reviewing the profile's Calamity ore unlocks and Wizard access. Use an earlier Hardmode station and explicit Hardmode condition if the desired recipe predates the current tier. |
| Tier 4 · Post-Plantera/Golem | No dedicated installed Combined Stations tier at this stage. | Add a compatibility-mod station with Autohammer and appropriate Temple or other verified parts. Keep this tier independent of Ancient Manipulator and Luminite. |
| Tier 5 · Lunar/Moon Lord | `MagicStorage/CombinedStations4Item`, called Final Tier, combines Tier 3, Furniture Stations Tier 2, Autohammer, Ancient Manipulator, Golden Dipping Vat, lava and honey. | Map this existing Final Tier to tier 5. Retain its original recipe for unrelated crafting. |
| Crucible of the Cosmos | Fargo Mutant recipe has two routes. Both consume Luminite Bar. One uses Final Tier. The other uses individual stations. The Fargo boss drop is a separate acquisition path. | Reserve for final combinations, retaining more restrictive stations such as Draedon's Forge where dropping them could bypass a progression gate. |

Exact ingredient quantities, recipe groups and tile IDs for the station chain are in [recipe-dependencies.json](recipe-dependencies.json). Tile proximity and station-in-storage availability require separate gameplay checks. Requiring a specific Combined Stations tile is different from requiring a vanilla station which that tile emulates. The audit found both Tier 2 and Tier 3 omit Demon Altar adjacency, while Fargo's Elemental Assembler supplies it.

References for station behavior and the boss drop. [Magic Storage source](https://github.com/blushiemagic/MagicStorage) · [Eridanus](https://fargosmods.wiki.gg/wiki/Eridanus,_Champion_of_Cosmos)
