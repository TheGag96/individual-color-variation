void main(string[] args) {
  import std.algorithm : canFind, map, each, filter, startsWith, joiner;
  import std.array     : array;
  import std.bitmanip  : littleEndianToNative, nativeToLittleEndian;
  import std.conv      : to;
  import std.file      : read, readText, write, exists, isFile;
  import std.range     : chunks, dropOne;
  import std.stdio     : writeln, File;
  import std.path      : baseName, stripExtension;

  if (args.length != 4 || ["unpack", "pack"].canFind(args[2])) {
    writeln("Usage: palette unpack sprites.btx outfolder || palette pack sprites.btx infolder");
    return;
  }

  uint rgb555To888(ushort color) {
    uint result = 0;

    foreach (i; 0..3) {
      result = result << 8;
      result |= (color & 0x1F) << 3;
      color = color >> 5;
    }

    return result;
  }

  ushort rgb888To555(uint color) {
    ushort result = 0;

    foreach (i; 0..3) {
      result = cast(ushort) (result << 5);
      result |= (color & 0xFF) >> 3;
      color = color >> 8;
    }

    return result;
  }

  auto btxBytes = cast(ubyte[]) (read(args[2]));
  auto btxFilenameBase = args[2].baseName.stripExtension;
  auto normalPalPath = args[3] ~ "/" ~ btxFilenameBase ~ "_normal.txt";
  auto shinyPalPath  = args[3] ~ "/" ~ btxFilenameBase ~ "_shiny.txt";
  
  if (args[1] == "unpack") {
    void writePalText(File f, ubyte[] bytes) {
      bytes
        .chunks(2)
        .map!(x => littleEndianToNative!(ushort, 2)(x[0..2]))
        .map!rgb555To888
        .each!(x => f.writefln("#%06X", x));
    }


    auto normalFile = File(normalPalPath, "w");
    auto shinyFile  = File(shinyPalPath,  "w");
    scope(exit) {
      normalFile.close();
      shinyFile.close();
    }

    writePalText(normalFile, btxBytes[0x1180   ..0x1180+32]);
    writePalText(shinyFile,  btxBytes[0x1180+32..0x1180+64]);
  }
  else { //pack
    void writePalBinary(File inTxt, ubyte[] outBytes) {
      outBytes[] =
        inTxt
        .byLine
        .filter!(x => x.startsWith("#"))
        .map!(x => x.dropOne.to!uint(16))
        .map!rgb888To555
        .map!(x => nativeToLittleEndian(x)[].dup)
        .joiner
        .array;
    }

    if (normalPalPath.exists && normalPalPath.isFile) {
      auto normalFile = File(normalPalPath, "r");
      scope(exit) normalFile.close();
      writePalBinary(normalFile, btxBytes[0x1180   ..0x1180+32]);
    }

    if (shinyPalPath.exists && shinyPalPath.isFile) {
      auto shinyFile = File(shinyPalPath, "r");
      scope(exit) shinyFile.close();
      writePalBinary(shinyFile,  btxBytes[0x1180+32..0x1180+64]);
    }

    write(args[2], btxBytes);
  }
}