using System;

namespace TerrariaPackCompat;

public sealed class HookStatePolicy
{
    private bool? lastDesired;

    public void Synchronize(bool desired, bool isApplied, Action undo, Action apply)
    {
        // The first call rebuilds even an applied hook: its original manipulator
        // may have observed menu difficulty flags instead of the loaded world.
        if (lastDesired == desired && isApplied == desired)
            return;
        undo();
        if (desired) apply();
        lastDesired = desired;
    }
}
