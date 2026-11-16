using System;
using System.Linq;
using FargowiltasSouls.Content.Items.Accessories.Enchantments;
using FargowiltasSouls.Core.AccessoryEffectSystem;
using Terraria;
using Terraria.ID;
using Terraria.ModLoader;
using Terraria.ObjectData;

namespace Rev8CraftingProgression;

internal sealed class CraftingSystem : ModSystem
{
    internal static int Tier(int tier) => ModContent.Find<ModTile>($"MagicStorage/CombinedStations{tier}Tile").Type;
    internal static int[] WoodEnchants() => Items("FargowiltasSouls",
        "Wood BorealWood RichMahogany Ebonwood Shadewood PalmWood");
    private static int[] Items(string mod, string names) => names.Split(' ')
        .Select(name => ModContent.Find<ModItem>($"{mod}/{name}Enchant").Type).ToArray();

    public override void PostAddRecipes()
    {
        int pearlwood = Items("FargowiltasSouls", "Pearlwood")[0];
        // The Tier 3 tile emulates the Crystal Ball but takes later stations to assemble.
        ReplaceGate("FargowiltasSouls/TimberForce", WoodEnchants().Append(pearlwood).ToArray(),
            new[] { ModContent.ItemType<WoodlandBundle>(), pearlwood }, TileID.CrystalBall, Condition.Hardmode);
        var terra = Items("FargowiltasSouls", "Copper Tin Iron Lead Silver Tungsten Obsidian");
        ReplaceGate("FargowiltasSouls/TerraForce", terra, terra, Tier(2));
        UpgradeFinalStation();
        AddWoodlandTierOneRoutes();
        AddTierOneRoute("AshWood", "AshWoodHelmet AshWoodBreastplate AshWoodGreaves Fireblossom SpicyPepper Gel", stackIndex: 5, stack: 50);
        AddTierOneRoute("Cactus", "CactusHelmet CactusBreastplate CactusLeggings Waterleaf Flounder SecretoftheSands");
        AddTierOneRoute("Iron", "IronHelmet IronChainmail IronGreaves IronHammer IronAnvil Apricot");
        AddTierOneRoute("Lead", "LeadHelmet LeadChainmail LeadGreaves LeadShortsword GrayPaint Peach", stackIndex: 4, stack: 100);
        AddTierOneRoute("Platinum", "PlatinumHelmet PlatinumChainmail PlatinumGreaves GardenGnome GemSquirrelDiamond LadyBug");
        AddTierOneRoute("Rain", "RainHat RainCoat UmbrellaHat FloatingTube Umbrella WaterGun");
        AddTierOneRoute("Snow", "EskimoHood EskimoCoat EskimoPants IceBoomerang FrostMinnow AtlanticCod");
        AddTierOneRoute("Snow", "EskimoHood EskimoCoat EskimoPants IceBlade FrostMinnow AtlanticCod");
        AddTierOneRoute("Tungsten", "TungstenHelmet TungstenChainmail TungstenGreaves TungstenBroadsword Ruler Katana");
        AddTierOneRoute("Copper", "CopperHelmet CopperChainmail CopperGreaves CopperShortsword WandofSparking ThunderStaff");
        AddTierOneRoute("Tin", "TinHelmet TinChainmail TinGreaves TinBow Revolver TopazStaff");
        AddTierOneRoute("Silver", "SilverHelmet SilverChainmail SilverGreaves EmptyBucket SilverBroadsword BlandWhip");
        AddTierOneRoute("Gold", "GoldHelmet GoldChainmail GoldGreaves PharaohsMask Goldfish GoldenDelight");
        AddTierOneRoute("Fossil", "FossilHelm FossilShirt FossilPants BoneDagger AmberStaff AntlionClaw", stackIndex: 3, stack: 120);
        AddTierOneRoute("Gladiator", "GladiatorHelmet GladiatorBreastplate GladiatorLeggings Spear Gladius BoneJavelin", stackIndex: 5, stack: 300);
        AddTierOneRoute("Jungle", "JungleHat JungleShirt JunglePants ThornChakram IvyWhip JungleRose");
        AddTierOneRoute("Pumpkin", "PumpkinHelmet PumpkinBreastplate PumpkinLeggings MolotovCocktail Sickle PumpkinPie", stackIndex: 3, stack: 50);
    }

    private void AddWoodlandTierOneRoutes()
    {
        var audits = new[] {
            ("Wood", "WoodHelmet WoodBreastplate WoodGreaves Daybloom Apple Squirrel", 1, true),
            ("BorealWood", "BorealWoodHelmet BorealWoodBreastplate BorealWoodGreaves Shiverthorn Plum Snowball", 300, false),
            ("RichMahogany", "RichMahoganyHelmet RichMahoganyBreastplate RichMahoganyGreaves Moonglow Pineapple GrapplingHook", 1, false),
            ("Ebonwood", "EbonwoodHelmet EbonwoodBreastplate EbonwoodGreaves VileMushroom BlackCurrant LightlessChasms", 1, false),
            ("Shadewood", "ShadewoodHelmet ShadewoodBreastplate ShadewoodGreaves ViciousMushroom BloodOrange DeadlandComesAlive", 1, false),
            ("PalmWood", "PalmWoodHelmet PalmWoodBreastplate PalmWoodGreaves Coral Banana Coconut", 1, false)
        };
        bool allAvailable = true;
        foreach (var (name, ingredientNames, lastStack, squirrelGroup) in audits)
            allAvailable &= AddTierOneRoute(name, ingredientNames, 5, lastStack, squirrelGroup);

        if (allAvailable)
        {
            var bundle = Main.recipe.Take(Recipe.numRecipes).Single(r => r.Mod == Mod
                && r.createItem.type == ModContent.ItemType<WoodlandBundle>());
            bundle.RemoveTile(Tier(2));
            bundle.AddTile(Tier(1));
        }
    }

    private bool AddTierOneRoute(string name, string ingredientNames, int stackIndex = -1, int stack = 1,
        bool squirrelGroup = false)
    {
        int tierOne = Tier(1);
        var item = ModContent.Find<ModItem>($"FargowiltasSouls/{name}Enchant");
        var expected = ingredientNames.Split(' ')
            .Select((value, index) => (ItemID.Search.GetId(value), index == stackIndex ? stack : 1))
            .OrderBy(value => value.Item1).ToArray();
        var candidates = Main.recipe.Take(Recipe.numRecipes)
            .Where(r => !r.Disabled && r.createItem.type == item.Type).ToArray();
        var matches = candidates.Where(r => r.Mod == item.Mod && r.createItem.stack == 1
            && r.requiredTile.SequenceEqual(new[] { (int)TileID.DemonAltar }) && r.Conditions.Count == 0
            && Ingredients(r).SequenceEqual(expected)
            && (squirrelGroup
                ? r.acceptedGroups.Count == 1 && RecipeGroup.recipeGroups[r.acceptedGroups[0]].ValidItems.Contains(ItemID.Squirrel)
                : r.acceptedGroups.Count == 0)).ToArray();
        if (matches.Length != 1 || candidates.Any(r => r.requiredTile.Contains(tierOne)
            && Ingredients(r).SequenceEqual(expected)))
        {
            Mod.Logger.Warn($"Skipped Tier 1 route for {item.FullName}: recipe mismatch or competing route.");
            return false;
        }

        var alternate = matches[0].Clone();
        alternate.RemoveTile(TileID.DemonAltar);
        alternate.AddTile(tierOne);
        // Keep the original Fargo recipe as the sole Shimmer decrafting route.
        alternate.DisableDecraft();
        alternate.Register();
        return true;
    }

    private void UpgradeFinalStation()
    {
        var final = ModContent.Find<ModItem>("MagicStorage/CombinedStations4Item");
        int tierThree = ModContent.Find<ModItem>("MagicStorage/CombinedStations3Item").Type;
        int tierFour = ModContent.ItemType<CombinedStationsTier4>();
        var original = new[] {
            (tierThree, 1),
            (ModContent.Find<ModItem>("MagicStorage/CombinedFurnitureStations2Item").Type, 1),
            (ItemID.Autohammer, 1), (ItemID.LunarCraftingStation, 1),
            (ModContent.Find<ModItem>("Fargowiltas/GoldenDippingVat").Type, 1),
            (ItemID.LavaBucket, 10), (ItemID.HoneyBucket, 10)
        };
        var baseline = original.OrderBy(p => p.Item1).ToArray();
        var replacement = original.Where(p => p.Item1 != tierThree && p.Item1 != ItemID.Autohammer)
            .Append((tierFour, 1)).OrderBy(p => p.Item1).ToArray();
        var candidates = Main.recipe.Take(Recipe.numRecipes)
            .Where(r => !r.Disabled && r.createItem.type == final.Type).ToArray();
        var matches = candidates.Where(r => r.Mod == final.Mod && r.createItem.stack == 1 &&
            r.requiredTile.Count == 0 && r.acceptedGroups.Count == 0 && r.Conditions.Count == 0 &&
            Ingredients(r).SequenceEqual(baseline)).ToArray();
        if (matches.Length != 1 || candidates.Any(r => Ingredients(r).SequenceEqual(replacement)))
        {
            Mod.Logger.Warn("Skipped Final Tier upgrade: expected one audited recipe and no competing replacement.");
            return;
        }

        var recipe = matches[0];
        recipe.RemoveIngredient(tierThree);
        recipe.RemoveIngredient(ItemID.Autohammer);
        recipe.AddIngredient(tierFour);
    }

    private void ReplaceGate(string output, int[] original, int[] replacement, int tile, Condition condition = null)
    {
        var item = ModContent.Find<ModItem>(output);
        int crucible = ModContent.Find<ModTile>("Fargowiltas/CrucibleCosmosSheet").Type;
        int geode = ModContent.Find<ModItem>("CalamityMod/DivineGeode").Type;
        var candidates = Main.recipe.Take(Recipe.numRecipes)
            .Where(r => !r.Disabled && r.createItem.type == item.Type).ToArray();
        var baseline = original.Select(id => (id, 1)).Append((geode, 4)).OrderBy(p => p.Item1).ToArray();
        var wanted = replacement.Select(id => (id, 1)).OrderBy(p => p.Item1).ToArray();
        var matches = candidates.Where(r => r.Mod == item.Mod && r.createItem.stack == 1 &&
            r.requiredTile.SequenceEqual(new[] { crucible }) && r.acceptedGroups.Count == 0 &&
            r.Conditions.Count == 0 && Ingredients(r).SequenceEqual(baseline)).ToArray();
        if (matches.Length != 1 || candidates.Any(r => Ingredients(r).SequenceEqual(wanted)))
        {
            Mod.Logger.Warn($"Skipped {output}: expected one audited recipe and no competing replacement.");
            return;
        }

        var recipe = matches[0];
        foreach (var ingredient in recipe.requiredItem.ToArray())
            if (!replacement.Contains(ingredient.type))
                recipe.RemoveIngredient(ingredient.type);
        foreach (int ingredient in replacement.Except(original))
            recipe.AddIngredient(ingredient);
        recipe.RemoveTile(crucible);
        recipe.AddTile(tile);
        if (condition != null)
            recipe.AddCondition(condition);
        Mod.Logger.Info($"Rebalanced {output}.");
    }

    private static (int, int)[] Ingredients(Recipe recipe) => recipe.requiredItem
        .Select(i => (i.type, i.stack)).OrderBy(i => i.type).ToArray();
}

public sealed class WoodlandBundle : BaseEnchant
{
    public override string Texture => $"Terraria/Images/Item_{ItemID.Wood}";
    public override Microsoft.Xna.Framework.Color nameColor => Microsoft.Xna.Framework.Color.ForestGreen;

    public override void SetDefaults()
    {
        base.SetDefaults();
        Item.rare = ItemRarityID.Green;
    }

    public override bool CanAccessoryBeEquippedWith(Item equippedItem, Item incomingItem, Player player)
        => equippedItem.ModItem?.FullName != "FargowiltasSouls/TimberForce" &&
           incomingItem.ModItem?.FullName != "FargowiltasSouls/TimberForce";

    public override void UpdateAccessory(Player player, bool hideVisual)
    {
        // Use Fargo's original effect keys so toggles, gating and deduplication stay native.
        WoodEnchant.WoodEffect(player, Item);
        player.AddEffect<BorealEffect>(Item);
        player.AddEffect<MahoganyEffect>(Item);
        player.AddEffect<EbonwoodEffect>(Item);
        player.AddEffect<ShadewoodEffect>(Item);
        player.AddEffect<PalmwoodEffect>(Item);
    }

    public override void AddRecipes()
    {
        var recipe = CreateRecipe();
        foreach (int enchantment in CraftingSystem.WoodEnchants())
            recipe.AddIngredient(enchantment);
        recipe.AddTile(CraftingSystem.Tier(2)).Register();
    }
}

public sealed class FinalTierAdjacency : GlobalTile
{
    public override int[] AdjTiles(int type)
    {
        int tierOne = ModContent.TileType<MagicStorage.Stations.CombinedStations1Tile>();
        int tierFour = ModContent.TileType<CombinedStationsTier4Tile>();
        if (type == ModContent.TileType<MagicStorage.Stations.CombinedStations4Tile>())
            return new[] { tierFour, tierOne };
        if (type == tierFour || type == ModContent.TileType<MagicStorage.Stations.CombinedStations2Tile>()
            || type == ModContent.TileType<MagicStorage.Stations.CombinedStations3Tile>())
            return new[] { tierOne };
        return Array.Empty<int>();
    }
}

public sealed class CombinedStationsTier4 : ModItem
{
    public override string Texture => $"Terraria/Images/Item_{ItemID.Autohammer}";

    public override void SetDefaults()
    {
        Item.DefaultToPlaceableTile(ModContent.TileType<CombinedStationsTier4Tile>());
        Item.rare = ItemRarityID.Yellow;
    }

    public override void AddRecipes() => CreateRecipe()
        .AddIngredient(ModContent.Find<ModItem>("MagicStorage/CombinedStations3Item").Type)
        .AddIngredient(ItemID.Autohammer)
        .AddTile(CraftingSystem.Tier(3))
        .AddCondition(Condition.DownedPlantera)
        .Register();
}

public sealed class CombinedStationsTier4Tile : ModTile
{
    public override string Texture => $"Terraria/Images/Tiles_{TileID.WorkBenches}";

    public override void SetStaticDefaults()
    {
        Main.tileFrameImportant[Type] = true;
        Main.tileNoAttach[Type] = true;
        TileObjectData.newTile.CopyFrom(TileObjectData.Style2x1);
        TileObjectData.addTile(Type);
        AdjTiles = TileLoader.GetTile(CraftingSystem.Tier(3)).AdjTiles
            .Append(TileID.Autohammer).Distinct().ToArray();
        AddMapEntry(new Microsoft.Xna.Framework.Color(151, 107, 75),
            ModContent.GetInstance<CombinedStationsTier4>().DisplayName);
    }
}
