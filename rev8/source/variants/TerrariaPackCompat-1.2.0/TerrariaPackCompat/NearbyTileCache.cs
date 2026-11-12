using System.Collections.Generic;

namespace TerrariaPackCompat;

// Keeps the original active dictionary, keys, ordering and point sequences.
// Only backing lists are reused after the original reset boundary.
public sealed class NearbyTileCache<T>
{
    private readonly Dictionary<int, List<T>> lists = new();

    public void Add(Dictionary<int, List<T>> active, int type, T point)
    {
        if (!active.TryGetValue(type, out List<T> list))
        {
            if (!lists.TryGetValue(type, out list))
                lists[type] = list = new List<T>();
            active[type] = list;
        }
        list.Add(point);
    }

    public void Reset(Dictionary<int, List<T>> active)
    {
        foreach (var entry in active)
        {
            entry.Value.Clear();
            lists[entry.Key] = entry.Value;
        }
        active.Clear();
    }

    public void Clear() => lists.Clear();
}
