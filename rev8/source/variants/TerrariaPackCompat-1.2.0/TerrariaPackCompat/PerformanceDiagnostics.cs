using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text.Json;
using Microsoft.Xna.Framework;
using Terraria;
using Terraria.ModLoader;
using Terraria.Enums;

namespace TerrariaPackCompat;

// Opt-in, local A/B measurement. Absent control file means no profiling hooks or I/O.
public sealed class PerformanceDiagnostics : ModSystem
{
    public static bool PatchesEnabled { get; private set; } = true;
    private string controlPath, outputPath, label = "patched";
    private bool enabled;
    private long start;
    private double updateMs, drawMs;
    private int updates, draws, focusedDraws;
    private readonly List<double> intervals = new(500);
    private long previousDraw;
    private ulong startSimulationTicks;

    public override void Load()
    {
        PatchesEnabled = true;
        controlPath = Path.Combine(Main.SavePath, "pack-performance-diagnostics.json");
        if (Main.dedServ || !File.Exists(controlPath)) return;
        outputPath = Path.Combine(Main.SavePath, "pack-performance-measurements.jsonl");
        enabled = true;
        ReadControl();
        On_Main.Update += MeasureUpdate;
        On_Main.Draw += MeasureDraw;
        Mod.Logger.Info("Performance diagnostics enabled locally; measured batches exclude menus and report focus.");
    }

    public override void OnWorldLoad() => Reset();

    private void Reset()
    {
        start = Stopwatch.GetTimestamp();
        startSimulationTicks = Main.GameUpdateCount;
        updateMs = drawMs = 0;
        updates = draws = focusedDraws = 0;
        intervals.Clear();
        previousDraw = 0;
    }

    private void MeasureUpdate(On_Main.orig_Update orig, Main self, GameTime time)
    {
        long before = Stopwatch.GetTimestamp();
        orig(self, time);
        if (!enabled || Main.gameMenu) return;
        updateMs += Stopwatch.GetElapsedTime(before).TotalMilliseconds;
        updates++;
    }

    private void MeasureDraw(On_Main.orig_Draw orig, Main self, GameTime time)
    {
        long before = Stopwatch.GetTimestamp();
        orig(self, time);
        if (!enabled || Main.gameMenu) return;
        drawMs += Stopwatch.GetElapsedTime(before).TotalMilliseconds;
        draws++;
        if (Main.hasFocus) focusedDraws++;
        if (previousDraw != 0) intervals.Add(Stopwatch.GetElapsedTime(previousDraw, before).TotalMilliseconds);
        previousDraw = before;
        double elapsed = Stopwatch.GetElapsedTime(start).TotalSeconds;
        if (elapsed < 5) return;
        try
        {
            intervals.Sort();
            double p95 = intervals.Count == 0 ? 0 : intervals[Math.Min(intervals.Count - 1, (int)(intervals.Count * .95))];
            File.AppendAllText(outputPath, JsonSerializer.Serialize(new {
                utc = DateTime.UtcNow, label, patches = PatchesEnabled,
                elapsedSeconds = elapsed, updates, draws,
                updatesPerSecond = updates / elapsed, framesPerSecond = draws / elapsed,
                simulationTicksPerSecond = (Main.GameUpdateCount - startSimulationTicks) / elapsed,
                averageUpdateMs = updateMs / Math.Max(1, updates),
                averageDrawMs = drawMs / Math.Max(1, draws),
                p95FrameIntervalMs = p95, focusFraction = focusedDraws / (double)Math.Max(1, draws),
                inventory = Main.playerInventory, zoom = Main.GameZoomTarget,
                width = Main.screenWidth, height = Main.screenHeight,
                worldWidth = Main.maxTilesX, worldHeight = Main.maxTilesY,
                frameSkip = (int)Main.FrameSkipMode, background = Main.BackgroundEnabled,
                playerX = Main.LocalPlayer.position.X, playerY = Main.LocalPlayer.position.Y
            }) + Environment.NewLine);
            ReadControl();
        }
        catch (Exception error)
        {
            enabled = false;
            Mod.Logger.Warn("Local performance diagnostics stopped after an I/O failure.", error);
        }
        Reset();
    }

    private void ReadControl()
    {
        using var document = JsonDocument.Parse(File.ReadAllText(controlPath));
        var root = document.RootElement;
        if (root.TryGetProperty("patches", out var patches)) PatchesEnabled = patches.GetBoolean();
        if (root.TryGetProperty("label", out var phase)) label = phase.GetString() ?? "measurement";
        if (root.TryGetProperty("zoom", out var zoom)) Main.GameZoomTarget = Math.Clamp(zoom.GetSingle(), .75f, 2f);
        if (root.TryGetProperty("frameSkip", out var frameSkip)) Main.FrameSkipMode = (FrameSkipMode)Math.Clamp(frameSkip.GetInt32(), 0, 2);
        if (root.TryGetProperty("background", out var background)) Main.BackgroundEnabled = background.GetBoolean();
    }

    public override void Unload()
    {
        On_Main.Update -= MeasureUpdate;
        On_Main.Draw -= MeasureDraw;
        PatchesEnabled = true;
        enabled = false;
        intervals.Clear();
    }
}
