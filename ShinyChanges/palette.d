void main(string[] args) {
  import std.algorithm : canFind, map, each, filter, startsWith, joiner;
  import std.array     : array;
  import std.bitmanip  : littleEndianToNative, nativeToLittleEndian;
  import std.conv      : to;
  import std.file      : read, readText, write;
  import std.range     : chunks, dropOne;
  import std.stdio     : writeln, File;

  if (args.length != 4 || ["unpack", "pack"].canFind(args[2])) {
    writeln("Usage: palette unpack pal.bin out.txt || palette pack pal.bin in.txt");
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

  auto palBytes = cast(ubyte[]) (read(args[2]));
  
  if (args[1] == "unpack") {
    auto outTxt = File(args[3], "w");

    palBytes[0x28..$]
      .chunks(2)
      .map!(x => littleEndianToNative!(ushort, 2)(x[0..2]))
      .map!rgb555To888
      .each!(x => outTxt.writefln("#%06X", x));

    outTxt.close();
  }
  else { //pack
    auto inTxt = File(args[3], "r");

    palBytes[0x28..$] =
      inTxt
      .byLine
      .filter!(x => x.startsWith("#"))
      .map!(x => x.dropOne.to!uint(16))
      .map!rgb888To555
      .map!(x => nativeToLittleEndian(x)[].dup)
      .joiner
      .array;

    write(args[2], palBytes);

    inTxt.close();
  }
}