int main(string[] args) {
  import std.stdio     : File, stdin, writeln;
  import std.exception : enforce;
  import std.conv      : to;
  import std.algorithm : joiner, filter, map;
  import std.array     : array;
  import std.range     : chunks;

  if (args.length < 3) {
    writeln("Usage: binpatch file address");
    return 1;
  }

  auto filename = args[1];
  auto address  = args[2].to!ulong(16);

  auto bytes = stdin
    .byLine
    .joiner
    .filter!(x => (x >= 'a' && x <= 'f') || (x >= 'A' && x <= 'F') || (x >= '0' && x <= '9') )
    .chunks(2)
    //.map!((x) { enforce(x.length == 2); return x; })
    .map!(x => x.to!ubyte(16))
    .array;

  if (!bytes.length) {
    writeln("No bytes to write from stdin...");
    return 1;
  }

  auto file = File(args[1], "r+");
  file.seek(address);
  file.rawWrite(bytes);

  file.close();

  return 0;
}