using Terraria;
using Terraria.ModLoader;

namespace TerrariaPackGuard;

public sealed class TerrariaPackGuard : Mod
{
    public override void Load()
    {
        On_WorldGen.KillTile_ShouldDropSeeds += GuardSeedDrops;
    }

    public override void Unload()
    {
        On_WorldGen.KillTile_ShouldDropSeeds -= GuardSeedDrops;
        PackGenerationState.Generating = false;
    }

    private static bool GuardSeedDrops(On_WorldGen.orig_KillTile_ShouldDropSeeds orig, int x, int y)
    {
        if (Main.dedServ && PackGenerationState.Generating)
            return false;
        return orig(x, y);
    }
}

// Strong mod dependencies ensure these world-generation callbacks execute after
// Fargo/Thorium, so the flag remains set during Fargo's PostWorldGen callback.
public sealed class PackGenerationState : ModSystem
{
    internal static bool Generating;
    public override void PreWorldGen() => Generating = true;
    public override void PostWorldGen() => Generating = false;
    public override void OnWorldLoad() => Generating = false;
    public override void OnWorldUnload() => Generating = false;
}
