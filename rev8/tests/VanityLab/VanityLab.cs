using System;
using System.IO;
using System.Linq;
using System.Collections.Generic;
using System.Text.Json;
using Terraria;
using Terraria.ID;
using Terraria.ModLoader;
using Terraria.ModLoader.Default;
using Terraria.IO;

namespace VanityLab;

public sealed class VanityLab : Mod
{
    public static bool Active;
    public static string Role;
    public override void Load() {
        string marker=Path.Combine(Main.SavePath,"vanity-lab-only.json");
        Active=Path.GetFullPath(Main.SavePath).Contains("rev8-vanity-lab",StringComparison.OrdinalIgnoreCase) && File.Exists(marker);
        if(!Active)return;
        Role=JsonDocument.Parse(File.ReadAllText(marker)).RootElement.GetProperty("role").GetString();
        On_Player.LoadPlayer += Rename;
    }
    private PlayerFileData Rename(On_Player.orig_LoadPlayer orig,string path,bool cloud) {
        var data=orig(path,cloud);
        if(Active && Role!="server" && Path.GetFullPath(path).StartsWith(Path.GetFullPath(Main.SavePath)+Path.DirectorySeparatorChar,StringComparison.OrdinalIgnoreCase))data.Player.name="Rev8Lab-"+Role;
        return data;
    }
    public override void Unload(){if(Active)On_Player.LoadPlayer-=Rename;Active=false;}
    public override void HandlePacket(BinaryReader r,int whoAmI) {
        if(!Active)return;
        string phase=r.ReadString();
        if(Main.netMode==NetmodeID.Server){
            LabSystem.Write(new {kind="received-report",phase,whoAmI,players=LabSystem.Players()});
        }
    }
}

public sealed class LabSystem : ModSystem
{
    private int frames;
    private bool exiting;
    public static void Write(object value) => File.AppendAllText(Path.Combine(Main.SavePath,"vanity-results.jsonl"),JsonSerializer.Serialize(value)+Environment.NewLine);
    public static object[] Players()=>Main.player.Where(p=>p.active).Select(p=>(object)new {p.name,p.whoAmI,armor=p.armor.Select(i=>i.type).ToArray(),extra=Extras(p)}).ToArray();
    public static object[] Extras(Player p){
        using var current=new Main.CurrentPlayerOverride(p);
        var loader=LoaderManager.Get<AccessorySlotLoader>();
        return Enumerable.Range(0,p.GetModPlayer<ModAccessorySlotPlayer>().SlotCount).Select(k=>loader.Get(k,p)).Where(s=>s!=null && s.Mod.Name=="MoreAccessories" && s.IsEnabled()).Select(s=>(object)new {s.Name,functional=s.FunctionalItem.type,vanity=s.VanityItem.type,loadouts=s.HasEquipmentLoadoutSupport}).ToArray();
    }
    public override void PostSetupContent(){
        if(!VanityLab.Active)return;
        var items=ModLoader.Mods.SelectMany(m=>m.GetContent<ModItem>()).Where(m=>m.Item.accessory).Select(m=>new {mod=m.Mod.Name,m.Name,m.Type}).ToArray();
        File.WriteAllText(Path.Combine(Main.SavePath,"accessory-catalogue.json"),JsonSerializer.Serialize(items));
    }
    public override void PostUpdateEverything(){
        if(!VanityLab.Active || Main.gameMenu)return;
        if(!Main.dedServ && !exiting && File.Exists(Path.Combine(Main.SavePath,"disconnect.request"))){exiting=true;WorldGen.SaveAndQuit(()=>Main.instance.Exit());return;}
        if(++frames%180==0)Write(new {kind="presence",net=Main.netMode,players=Players()});
    }
}

public sealed class CountCalls : GlobalItem
{
    public override void UpdateAccessory(Item item,Player player,bool hideVisual){
        if(VanityLab.Active && !item.IsAir && item.accessory && player.whoAmI==Main.myPlayer)player.GetModPlayer<LabPlayer>().Calls++;
    }
}

public sealed class LabPlayer : ModPlayer
{
    public int Calls;
    private int tick,index=-1;
    private bool done;
    private readonly List<(string name,int type,string location,int slot)> plan=new();
    private string completion;
    public override void OnEnterWorld(){
        if(!VanityLab.Active || Player.whoAmI!=Main.myPlayer)return;
        completion=Path.Combine(Main.SavePath,"vanity-complete.json");
        LabSystem.Write(new {kind="enter",Player.name,players=LabSystem.Players(),savedArmor=Player.armor.Select(i=>i.type).ToArray(),savedExtra=LabSystem.Extras(Player)});
        if(File.Exists(completion)){done=true;return;}
        plan.Add(("baseline",0,"empty",0));
        var list=new List<(string,int)>{("Terraria/ObsidianShield",ItemID.ObsidianShield),("Terraria/Shackle",ItemID.Shackle),("Terraria/AvengerEmblem",ItemID.AvengerEmblem)};
        foreach(var spec in new[]{("CalamityMod","LuxorsGift"),("CalamityMod","StressPills"),("FargowiltasSouls","CopperEnchant"),("ThoriumMod","RubyRing"),("CalamityInheritance","DaedalusEmblem")}){
            if(ModContent.TryFind<ModItem>(spec.Item1,spec.Item2,out var item))list.Add((spec.Item1+"/"+spec.Item2,item.Type));
            else LabSystem.Write(new {kind="missing-candidate",mod=spec.Item1,item=spec.Item2});
        }
        foreach(var (name,type) in list){
            plan.Add((name,type,"functional",3));plan.Add((name,type,"social",13));plan.Add((name,type,"extra",0));plan.Add((name,type,"inventory",0));plan.Add((name,type,"empty",0));
        }
        for(int slot=13;slot<20;slot++)plan.Add(("Terraria/Shackle",ItemID.Shackle,"social",slot));
        for(int slot=0;slot<3;slot++)plan.Add(("Terraria/Shackle",ItemID.Shackle,"extra",slot));
        plan.Add(("Terraria/IronHelmet",ItemID.IronHelmet,"armor-functional",0));
        plan.Add(("Terraria/IronHelmet",ItemID.IronHelmet,"armor-social",10));
        plan.Add(("baseline",0,"empty",0));
        plan.Add(("Terraria/Shackle",ItemID.Shackle,"extra",0));
    }
    public override void PreUpdate(){
        if(!VanityLab.Active || Player.whoAmI!=Main.myPlayer || Main.netMode!=1)return;
        Player.statLife=Player.statLifeMax2;Player.immune=true;Player.immuneTime=60;
        Calls=0;
        if(done)return;
        if(++tick%90==1){
            if(++index>=plan.Count){done=true;File.WriteAllText(completion,"{\"completed\":true}");Player.SavePlayer(Main.ActivePlayerFileData);LabSystem.Write(new {kind="saved-player",path=Main.ActivePlayerFileData.Path});return;}
            Apply(plan[index]);
        }
    }
    private void Apply((string name,int type,string location,int slot) c){
        foreach(var oldItem in Player.armor)oldItem.TurnToAir();
        foreach(var oldItem in Player.inventory)oldItem.TurnToAir();
        Array.Clear(Player.buffType);Array.Clear(Player.buffTime);
        var loader=LoaderManager.Get<AccessorySlotLoader>();
        var slots=Enumerable.Range(0,Player.GetModPlayer<ModAccessorySlotPlayer>().SlotCount).Select(k=>loader.Get(k,Player)).Where(s=>s!=null).ToArray();
        foreach(var s in slots){s.FunctionalItem.TurnToAir();s.VanityItem.TurnToAir();}
        if(c.type==0 || c.location=="empty")return;
        var item=new Item(c.type);
        if(c.type==ItemID.Shackle)item.Prefix(PrefixID.Warding);
        if(c.location=="inventory")Player.inventory[c.slot]=item;
        else if(c.location=="extra"){
            var extra=slots.Where(s=>s.Mod.Name=="MoreAccessories" && s.IsEnabled()).OrderBy(s=>s.Name).ToArray();
            if(extra.Length!=3)throw new InvalidOperationException("Expected 3 enabled MoreAccessories slots");
            extra[c.slot].VanityItem=item;
        }else Player.armor[c.slot]=item;
    }
    public override void PostUpdate(){
        if(!VanityLab.Active || Player.whoAmI!=Main.myPlayer || done || index<0 || tick%90!=60)return;
        var c=plan[index];
        LabSystem.Write(new {kind="sample",index,c.name,c.location,c.slot,c.type,Calls,defense=Player.statDefense,life=Player.statLifeMax2,mana=Player.statManaMax2,damage=Player.GetDamage(DamageClass.Generic).Additive,melee=Player.GetDamage(DamageClass.Melee).Additive,Player.noKnockback,Player.fireWalk,Player.moveSpeed,Player.accRunSpeed,unlocked=c.location!="social" || Player.IsItemSlotUnlockedAndUsable(c.slot),extras=LabSystem.Extras(Player),peers=LabSystem.Players()});
        var packet=Mod.GetPacket();packet.Write(index+":"+c.name+":"+c.location+":"+c.slot);packet.Send();
    }
}
