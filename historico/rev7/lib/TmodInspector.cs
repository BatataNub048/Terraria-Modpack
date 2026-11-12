// Read-only inspection of the documented tModLoader TMOD/Info binary format.
// No mod assemblies are loaded or executed. Compatible with Windows PowerShell 5.1.
using System;
using System.IO;
using System.Text;
using System.IO.Compression;
using System.Security.Cryptography;
using System.Collections.Generic;

public sealed class PackModInfo {
    public string Path, Name, Version, BuildTml, Sha256;
    public long Size;
    public string[] Required = new string[0], Weak = new string[0];
    public int Side;
}
public static class PackTmodReader {
    public static void AtomicReplace(string source, string target) { File.Replace(source,target,null); }
    public static string FileSha256(string path) {
        using(var f=File.OpenRead(path)) using(var sha=SHA256.Create()) return Hex(sha.ComputeHash(f));
    }
    static string Hex(byte[] bytes) { return BitConverter.ToString(bytes).Replace("-", "").ToLowerInvariant(); }
    static string Str(BinaryReader r) {
        int size=0, shift=0;
        for(int i=0;i<5;i++) {
            byte b=r.ReadByte(); size |= (b&127)<<shift;
            if((b&128)==0) {
                if(size<0 || size>16*1024*1024) throw new InvalidDataException("Invalid string size");
                byte[] value=r.ReadBytes(size);
                if(value.Length!=size) throw new EndOfStreamException();
                return new UTF8Encoding(false,true).GetString(value);
            }
            shift+=7;
        }
        throw new InvalidDataException("Invalid string prefix");
    }
    static string[] List(BinaryReader r) {
        var result=new List<string>(); string s;
        while((s=Str(r)).Length>0) {
            if(result.Count>10000) throw new InvalidDataException("Too many references");
            result.Add(s);
        }
        return result.ToArray();
    }
    public static PackModInfo Read(string path) {
        var info=new PackModInfo(); info.Path=System.IO.Path.GetFullPath(path);
        using(var f=File.OpenRead(path)) using(var r=new BinaryReader(f)) {
            info.Size=f.Length;
            if(Encoding.ASCII.GetString(r.ReadBytes(4))!="TMOD") throw new InvalidDataException("Invalid TMOD header");
            info.BuildTml=Str(r); new Version(info.BuildTml);
            byte[] hash=r.ReadBytes(20);
            if(r.ReadBytes(256).Length!=256) throw new EndOfStreamException();
            int size=r.ReadInt32(); long start=f.Position;
            if(size!=f.Length-start || size<0) throw new InvalidDataException("Truncated or oversized TMOD payload");
            using(var sha=SHA1.Create()) if(Hex(hash)!=Hex(sha.ComputeHash(f))) throw new InvalidDataException("TMOD payload SHA1 mismatch");
            f.Position=start; info.Name=Str(r); info.Version=Str(r); new Version(info.Version);
            if(!System.Text.RegularExpressions.Regex.IsMatch(info.Name,@"^[A-Za-z][A-Za-z0-9_]*$")) throw new InvalidDataException("Invalid internal mod name");
            int count=r.ReadInt32();
            if(count<1 || count>500000) throw new InvalidDataException("Invalid file count");
            long offset=0, infoOffset=-1; int rawSize=0, storedSize=0;
            var names=new HashSet<string>(StringComparer.Ordinal);
            for(int i=0;i<count;i++) {
                string name=Str(r); int raw=r.ReadInt32(), stored=r.ReadInt32();
                if(raw<0 || stored<0 || !names.Add(name)) throw new InvalidDataException("Invalid file table");
                if(name=="Info") {infoOffset=offset;rawSize=raw;storedSize=stored;}
                offset+=stored;
            }
            long filesStart=f.Position;
            if(filesStart+offset!=f.Length || infoOffset<0 || rawSize>16*1024*1024 || storedSize>16*1024*1024) throw new InvalidDataException("Invalid Info entry or file bounds");
            f.Position=filesStart+infoOffset; byte[] data=r.ReadBytes(storedSize);
            if(rawSize!=storedSize) {
                using(var input=new MemoryStream(data)) using(var inflate=new DeflateStream(input,CompressionMode.Decompress)) using(var output=new MemoryStream()) {
                    byte[] buffer=new byte[8192]; int n;
                    while((n=inflate.Read(buffer,0,buffer.Length))>0) {
                        if(output.Length+n>rawSize) throw new InvalidDataException("Info decompression overflow");
                        output.Write(buffer,0,n);
                    }
                    data=output.ToArray();
                }
            }
            if(data.Length!=rawSize) throw new InvalidDataException("Info decompression size mismatch");
            using(var ms=new MemoryStream(data)) using(var ir=new BinaryReader(ms)) {
                string key;
                while((key=Str(ir)).Length>0) {
                    switch(key) {
                        case "modReferences": info.Required=List(ir); break;
                        case "weakReferences": info.Weak=List(ir); break;
                        case "dllReferences": case "sortAfter": case "sortBefore": List(ir); break;
                        case "side": info.Side=ir.ReadByte(); break;
                        case "author": case "version": case "displayName": case "homepage": case "description": case "eacPath": case "buildVersion": case "modSource": Str(ir); break;
                        case "noCompile": case "!playableOnPreview": case "translationMod": case "libraryMod": case "!hideCode": case "!hideResources": case "includeSource": case "beta": break;
                        default: throw new InvalidDataException("Unknown Info tag; reader update required: "+key);
                    }
                }
            }
            f.Position=0;
            using(var sha=SHA256.Create()) info.Sha256=Hex(sha.ComputeHash(f));
        }
        return info;
    }
}
