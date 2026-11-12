using System;
using System.Reflection;
using Mono.Cecil.Cil;
using MonoMod.Cil;
using MonoMod.RuntimeDetour;
using Terraria.ModLoader;

namespace TerrariaPackCompat;

public sealed class TerrariaPackCompat : Mod
{
    private ILHook tailBannerHook;

    public override void Load()
    {
        if (!ModLoader.TryGetMod("UnofficialCalamityWhips", out var whips))
            return;

        if (whips.Version != new Version(1, 2, 2))
            throw new InvalidOperationException("The Whips banner patch needs review for this version.");

        var tail = whips.Code.GetType("UnofficialCalamityWhips.NPCs.ScraperOfStarsTail", throwOnError: true);
        var defaults = tail.GetMethod(nameof(ModNPC.SetDefaults),
            BindingFlags.Public | BindingFlags.Instance | BindingFlags.DeclaredOnly)
            ?? throw new MissingMethodException(tail.FullName, nameof(ModNPC.SetDefaults));

        tailBannerHook = new ILHook(defaults, il =>
        {
            var cursor = new ILCursor(il);
            if (!cursor.TryGotoNext(MoveType.Before, instruction =>
                instruction.MatchCallOrCallvirt<ModNPC>("set_Banner")))
                throw new InvalidOperationException("The Whips tail banner assignment has changed.");

            // In 1.2.2 the tail points to the head, which has no banner item.
            // Remove that orphaned link while preserving all other NPC defaults.
            cursor.Emit(OpCodes.Pop);
            cursor.Emit(OpCodes.Ldc_I4_0);
        });
    }

    public override void Unload()
    {
        tailBannerHook?.Dispose();
        tailBannerHook = null;
    }
}
