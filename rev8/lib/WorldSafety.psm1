Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

if (-not ('PackWorldHeaderReader' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.IO;
using System.Text;

public sealed class PackWorldHeader {
    public string Name;
    public int Width, Height, GameMode, Version;
}

public static class PackWorldHeaderReader {
    private static string ReadString(BinaryReader reader) {
        int length = 0;
        for (int shift = 0; shift < 35; shift += 7) {
            byte value = reader.ReadByte();
            length |= (value & 127) << shift;
            if ((value & 128) == 0) {
                if (length < 0 || length > 1048576)
                    throw new InvalidDataException("World header string is too large.");
                byte[] bytes = reader.ReadBytes(length);
                if (bytes.Length != length) throw new EndOfStreamException();
                return new UTF8Encoding(false, true).GetString(bytes);
            }
        }
        throw new InvalidDataException("Invalid world string length.");
    }

    public static PackWorldHeader Read(string path) {
        using (var stream = File.OpenRead(path))
        using (var reader = new BinaryReader(stream)) {
            int version = reader.ReadInt32();
            if (version < 209 || version > 279)
                throw new InvalidDataException("Unsupported world format for this safety check: " + version);
            byte[] metadata = reader.ReadBytes(8);
            if (metadata.Length != 8 || Encoding.ASCII.GetString(metadata, 0, 7) != "relogic" || metadata[7] != 2)
                throw new InvalidDataException("Invalid Terraria world metadata.");
            reader.ReadUInt32();
            reader.ReadUInt64();
            if (reader.ReadInt16() < 1) throw new InvalidDataException("Missing world sections.");
            int headerOffset = reader.ReadInt32();
            if (headerOffset < stream.Position || headerOffset > stream.Length - 64)
                throw new InvalidDataException("Invalid world header offset.");
            stream.Position = headerOffset;
            string name = ReadString(reader);
            ReadString(reader); // seed
            reader.ReadUInt64(); // world generator version
            if (reader.ReadBytes(16).Length != 16) throw new EndOfStreamException();
            for (int i = 0; i < 5; i++) reader.ReadInt32(); // ID and world boundaries
            int height = reader.ReadInt32();
            int width = reader.ReadInt32();
            int mode = reader.ReadInt32();
            if (width <= 0 || height <= 0 || width > 65535 || height > 65535 || mode < 0 || mode > 3)
                throw new InvalidDataException("Invalid world dimensions or game mode.");
            return new PackWorldHeader { Name = name, Width = width, Height = height, GameMode = mode, Version = version };
        }
    }
}
'@
}

function Get-PackWorldHeader([string]$Path) {
    [PackWorldHeaderReader]::Read([IO.Path]::GetFullPath($Path))
}

function Assert-PackWorldFile([string]$Path, [bool]$HasTitanWorlds) {
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return }
    try { $header = Get-PackWorldHeader $Path }
    catch { throw "Nao foi possivel conferir o mundo '$Path': $($_.Exception.Message)" }
    if (-not $HasTitanWorlds -and ($header.Width -gt 8400 -or $header.Height -gt 2400)) {
        throw "Mundo expandido bloqueado neste perfil: '$Path' ($($header.Width) x $($header.Height)). Abra-o em um perfil Titanico com TitanWorlds."
    }
}

function Assert-PackWorldSafety([string]$ProfileRoot, [bool]$HasTitanWorlds) {
    $worlds = Join-Path $ProfileRoot 'Worlds'
    # Subworlds in nested directories are managed by their owning mods.
    foreach ($world in @(Get-ChildItem -LiteralPath $worlds -Filter '*.wld' -File -ErrorAction SilentlyContinue)) {
        Assert-PackWorldFile $world.FullName $HasTitanWorlds
    }
}

Export-ModuleMember -Function Get-PackWorldHeader,Assert-PackWorldFile,Assert-PackWorldSafety
