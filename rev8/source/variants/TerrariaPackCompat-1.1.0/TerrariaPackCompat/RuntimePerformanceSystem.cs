using System;
using System.Collections.Generic;
using System.Reflection;
using Microsoft.Xna.Framework;
using Mono.Cecil.Cil;
using MonoMod.Cil;
using MonoMod.RuntimeDetour;
using Terraria;
using Terraria.ModLoader;

namespace TerrariaPackCompat;

public sealed class RuntimePerformanceSystem : ModSystem
{
    private readonly List<ILHook> hooks = new();
    private readonly NearbyTileCache<Vector2> nearbyCache = new();
    private Dictionary<int, List<Vector2>> activeMusicTiles;
    private FieldInfo jellyHookField, scouterHookField, jellyConfigField, scouterConfigField;
    private object bossConfig;
    private Func<bool> isRevengeance, isBossRush;
    private MethodInfo shouldLoadBoss;
    private readonly HookStatePolicy jellyPolicy = new(), scouterPolicy = new();
    private int ragnarokTicks;
    private bool ragnarokFailed;

    public override void PostSetupContent()
    {
        InstallMusicPool();
        InstallCandleGuard();
        InstallRagnarokLifecycle();
    }

    private bool ExactMod(string name, string version, out Mod mod)
    {
        if (!ModLoader.TryGetMod(name, out mod)) return false;
        if (mod.Version == Version.Parse(version)) return true;
        Mod.Logger.Warn($"Performance patch skipped for unreviewed {name} {mod.Version}.");
        return false;
    }

    private void InstallMusicPool()
    {
        if (Main.dedServ || !ExactMod("UnCalamityModMusic", "2.1.3", out Mod music)) return;
        Type type = music.Code.GetType("UnCalamityModMusic.Common.WorkshopDetection", true);
        activeMusicTiles = (Dictionary<int, List<Vector2>>)type.GetField("tileCenters", BindingFlags.Static | BindingFlags.NonPublic)!.GetValue(null)!;
        MethodInfo method = type.GetMethod("NearbyEffects", BindingFlags.Public | BindingFlags.Instance)!;
        CheckVoidSignature(method, typeof(int), typeof(int), typeof(int), typeof(bool));
        hooks.Add(new ILHook(method, il =>
        {
            var cursor = new ILCursor(il);
            cursor.Emit(OpCodes.Ldarg_1);
            cursor.Emit(OpCodes.Ldarg_2);
            cursor.Emit(OpCodes.Ldarg_3);
            cursor.Emit(OpCodes.Ldarg_S, (byte)4);
            cursor.EmitDelegate<Action<int,int,int,bool>>(RecordMusicTile);
            cursor.Emit(OpCodes.Ret);
        }));
        Mod.Logger.Info("Performance: vanilla Calamity music nearby-tile lists pooled; original distance queries retained.");
    }

    private void RecordMusicTile(int i, int j, int type, bool closer)
    {
        if (closer)
            nearbyCache.Add(activeMusicTiles, type, new Vector2(i * 16 + 8, j * 16 + 8));
        else
            nearbyCache.Reset(activeMusicTiles);
    }

    private void InstallCandleGuard()
    {
        if (!ExactMod("FargowiltasCrossmod", "1.2.0.28", out Mod crossmod)
            || !ExactMod("CalamityMod", "2.2.4", out Mod calamity)) return;
        int blue=calamity.Find<ModTile>("BlueCandle").Type;
        int purple=calamity.Find<ModTile>("PurpleCandle").Type;
        int pink=calamity.Find<ModTile>("PinkCandle").Type;
        int yellow=calamity.Find<ModTile>("YellowCandle").Type;
        Type type=crossmod.Code.GetType("FargowiltasCrossmod.Core.Calamity.Globals.CalDLCTileChanges",true);
        MethodInfo method=type.GetMethod("BuffStationEffect",BindingFlags.Public|BindingFlags.Static)!;
        CheckVoidSignature(method,typeof(int),typeof(int),typeof(int),typeof(bool));
        hooks.Add(new ILHook(method,il=>
        {
            var cursor=new ILCursor(il);
            var original=cursor.DefineLabel();
            cursor.Emit(OpCodes.Ldarg_2);
            cursor.EmitDelegate<Func<int,bool>>(tile => tile==blue || tile==purple || tile==pink || tile==yellow);
            cursor.Emit(OpCodes.Brtrue,original);
            cursor.Emit(OpCodes.Ret);
            cursor.MarkLabel(original);
        }));
        Mod.Logger.Info("Performance: Fargo candle checks restricted to their four original tile types; buffs, sounds and configuration unchanged.");
    }

    private void InstallRagnarokLifecycle()
    {
        if (!ExactMod("RagnarokMod", "1.6.0.10", out Mod ragnarok)) return;
        Type edits=ragnarok.Code.GetType("RagnarokMod.ILEditing.ThoriumEdits",true);
        Type flags=ragnarok.Code.GetType("RagnarokMod.Utils.CalamityGamemodeCheck",true);
        Type compatibility=ragnarok.Code.GetType("RagnarokMod.Common.ModSystems.OtherModsCompat",true);
        Type config=ragnarok.Code.GetType("RagnarokMod.Common.Configs.BossConfig",true);
        jellyHookField=edits.GetField("qjellyhook",BindingFlags.Static|BindingFlags.NonPublic)!;
        scouterHookField=edits.GetField("scouterhook",BindingFlags.Static|BindingFlags.NonPublic)!;
        jellyConfigField=config.GetField("jelly")!;
        scouterConfigField=config.GetField("scouter")!;
        bossConfig=typeof(ModContent).GetMethod("GetInstance",BindingFlags.Public|BindingFlags.Static)!.MakeGenericMethod(config).Invoke(null,null)!;
        isRevengeance=(Func<bool>)flags.GetProperty("isRevengeance")!.GetMethod!.CreateDelegate(typeof(Func<bool>));
        isBossRush=(Func<bool>)flags.GetProperty("isBossrush")!.GetMethod!.CreateDelegate(typeof(Func<bool>));
        shouldLoadBoss=compatibility.GetMethod("shouldRagnarokBossAILoad",BindingFlags.Public|BindingFlags.Static)!;
        MethodInfo method=edits.GetMethod("PostUpdateEverything",BindingFlags.Public|BindingFlags.Instance)!;
        CheckVoidSignature(method);
        hooks.Add(new ILHook(method,il=>
        {
            var cursor=new ILCursor(il);
            var original=cursor.DefineLabel();
            cursor.EmitDelegate<Func<bool>>(TryUpdateRagnarokHooks);
            cursor.Emit(OpCodes.Brfalse,original);
            cursor.Emit(OpCodes.Ret);
            cursor.MarkLabel(original);
        }));
        Mod.Logger.Info("Performance: Ragnarok boss-render hooks retained between difficulty/configuration transitions; original 1800-tick polling cadence retained.");
    }

    private bool TryUpdateRagnarokHooks()
    {
        if(ragnarokFailed) return false;
        if(ragnarokTicks++<1800) return true;
        ragnarokTicks=1;
        try
        {
            bool active=isRevengeance() || isBossRush();
            bool jelly=active && (bool)shouldLoadBoss.Invoke(null,new[]{jellyConfigField.GetValue(bossConfig)})!;
            bool scouter=active && (bool)shouldLoadBoss.Invoke(null,new[]{scouterConfigField.GetValue(bossConfig)})!;
            ILHook j=(ILHook)jellyHookField.GetValue(null)!;
            ILHook s=(ILHook)scouterHookField.GetValue(null)!;
            jellyPolicy.Synchronize(jelly,j.IsApplied,j.Undo,j.Apply);
            scouterPolicy.Synchronize(scouter,s.IsApplied,s.Undo,s.Apply);
            return true;
        }
        catch(Exception error)
        {
            ragnarokFailed=true;
            Mod.Logger.Warn("Ragnarok lifecycle optimization failed; resuming its original update method.",error);
            return false;
        }
    }

    private static void CheckVoidSignature(MethodInfo method,params Type[] parameters)
    {
        if(method==null || method.ReturnType!=typeof(void)) throw new MissingMethodException("Performance target changed.");
        var actual=method.GetParameters();
        if(actual.Length!=parameters.Length) throw new MissingMethodException(method.Name);
        for(int i=0;i<actual.Length;i++) if(actual[i].ParameterType!=parameters[i]) throw new MissingMethodException(method.Name);
    }

    public override void OnWorldUnload()
    {
        if(activeMusicTiles!=null) nearbyCache.Reset(activeMusicTiles);
        nearbyCache.Clear();
    }

    public override void Unload()
    {
        foreach(var hook in hooks) hook.Dispose();
        hooks.Clear();
        nearbyCache.Clear();
        activeMusicTiles=null;
        jellyHookField=scouterHookField=jellyConfigField=scouterConfigField=null;
        bossConfig=null;
        isRevengeance=isBossRush=null;
        shouldLoadBoss=null;
    }
}
