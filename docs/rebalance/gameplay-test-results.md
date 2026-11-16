# Rev8CraftingProgression 0.2.0 gameplay validation

Tested with the installed tModLoader 2026.9.3.1 / Terraria 1.4.4.9 and the existing audited Rev8 mod set. Used a temporary gameplay test mod to supply exact ingredients, place fixtures, drive the real game update and craft methods, and record outputs. The test mod is local to the disposable runs. No new mod inventory audit was performed.

The first full-profile small-world generator stalled at Desertification (21.4%) with the process continuing to use CPU. I stopped the disposable generator. A separate tModLoader process generated a fresh small world with content mods disabled. Independent copies of that world then loaded with the full test profile. The run therefore tests active gameplay and crafting in a fresh world. Full-profile world generation remains unresolved, and the stall was not attributed to the recipe compatibility mod. I created two new local characters in the test save directory.

## First live runs

| Check | Observed outcome |
|---|---|
| Tier 2, Woodland and Terra | Placed the actual Tier 2 tile. The active player detected adjacency. The standard recipe list exposed both recipes in Pre-Hardmode with the supplied ingredients. The game crafted each one and consumed the exact quantities. |
| Timber | Placed a real Crystal Ball. With identical ingredients, Timber stayed hidden before Hardmode and was craftable after switching the disposable world's Hardmode flag. Verified the exact consumption and original Timber output. |
| Woodland effects, toggle and stacking | Equipped the crafted item on the live player. All six Fargo effects activated. Invoking the native Palmwood skill spawned a real player-owned Palm Tree sentry. Adding an individual Boreal Enchantment preserved a single native effect source. Turning off Boreal suppressed both equipped sources while keeping Palmwood active. The focus was effective registration, toggle response and a live Palmwood projectile. |
| Tier 4 and Tier 5 | The standard crafting list blocked Tier 4 before Plantera's flag and allowed it after the flag changed. Physically placed Tier 4 and observed Tier 3 + Autohammer adjacency without Lunar adjacency. Crafted and placed Tier 5, then observed the Lunar and Tier 4 adjacency flags. Verified ingredient consumption for both crafts. |
| Magic Storage Tier 4 | Built a functional Storage Heart, Storage Unit and Crafting Access. The first scripted invocation through an access wrapper did not deposit Shroomite. The visible craft interface, opened through the placed Crafting Access, recognized Tier 4 as Autohammer. Clicking **Craft** consumed the stored Chlorophyte Bar and Glowing Mushrooms. The linked Storage Heart displayed one Shroomite Bar afterward. |
| Local dedicated multiplayer | Bound to `127.0.0.1:17832`. The server observed both separately launched clients connected concurrently. Both real clients logged six active Woodland effects on their local characters. |

An existing Crossmod/Infernum compatibility warning appeared in-game. The local server also logged one `calamityzeith` packet read underflow while clients joined. Both clients completed the first multiplayer gameplay check. This test makes no general compatibility claim about those other mods.

Evidence is in `workbench/fargo-rebalance-audit-20261115/gameplay`, including the per-process gameplay result and console files. The Magic Storage output was independently observed in the live Windows UI. Progression checks set flags on disposable worlds to test recipe availability and did not play through the corresponding boss fights.

## Storage retest

On a new single-player copy, the test opened the actual Crafting Access UI on the placed tile and used the same craft method as its Craft button. Tier 4 produced Shroomite and consumed the exact stored ingredients. With Lunar Ore already in the heart, the recipe remained unavailable with Tier 4. After swapping the stored station to Tier 5, the recipe became available and produced a Lunar Bar in the heart, consuming the stored ore. This retest passed without changes to `Rev8CraftingProgression`. The changes to instrumentation are recorded in the disposable `CraftingGameplayLab` source. Evidence is in `gameplay-retest/single/gameplay-results.txt` under the audit workbench.

## Two-client storage retest

Windows rebooted during the first attempt at the extended multiplayer test. I relaunched the isolated session on `127.0.0.1:17833`. The dedicated server placed and stocked a real Magic Storage network with Tier 4. Both separately launched clients joined concurrently. Each equipped Woodland, activated all six effects, and toggled Boreal off while Palmwood remained active. The first client opened Crafting Access and issued a Shroomite craft through Magic Storage's client method. The server recorded receiving and applying the request and observed the resulting Shroomite in its Storage Heart.

The server and client log markers are under `gameplay-retest/server`, `gameplay-retest/first`, and `gameplay-retest/second`. The first multiplayer attempt and the retest both logged the unrelated `calamityzeith` read underflow during join. No mod binaries or gameplay profiles outside the disposable environment were changed. Nothing was pushed.

**Reconnect passed.** The second client saved its disposable character, exited, and launched again from the same file. The server logged the leave and rejoin. The client verified that Woodland was already equipped before touching the equipment slot. All six effects and the Boreal toggle passed again after reconnect.

## Live Magic Storage retest

Repeated the tests on another copy of the fresh world. The disposable driver now opens the physical Crafting Access through the native tile interaction and uses the same crafting method as the UI button. That path crafted and deposited Shroomite using the stored Tier 4 and consumed the exact stored ingredients. With Lunar Ore stocked, Tier 4 did not expose the Lunar Bar recipe. Swapping the stored station to Tier 5 exposed the recipe, crafted and deposited the Lunar Bar, and consumed the ore. The original crafting and Woodland checks passed again. No change to `Rev8CraftingProgression` was needed.

The retest client evidence is `gameplay-retest/single/gameplay-results.txt` under the same workspace. The temporary driver was updated for the retest. Original mod binaries and normal profiles stayed outside these runs.
