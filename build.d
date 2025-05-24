import std.algorithm, std.bitmanip, std.conv, std.file, std.math, std.path, std.process, std.range, std.stdio, std.string;
import arena, narc, util;

version (BigEndian) static assert(0, "Sorry, can't run this on big-endian machines right now!");

immutable string[] CODE_FILE_NAMES = [
  "arm9",
  "overlay1",
  "overlay7",
  "overlay12",
  "overlay14",
  "overlay63",
  "overlay64",
  "overlay74",
  "overlay96",
  "overlay97",
  "overlay98",
  "overlay112",
];
string codeFilePath(string codeFile, bool patched) {
  string suffix = patched ? "patched" : "vanilla";
  return codeFile ~ "_hg_" ~ suffix ~ ".bin";
}

struct FilePair {
  string original, patched;
}
immutable FilePair CUSTOM_OVERLAY_FILE = { "custom_overlay_hg_vanilla.narc", "custom_overlay_hg.narc" };
immutable size_t   CUSTOM_OVERLAY_SIZE = 32 * 1024;

enum SourceKind {
  assembly,
  c,
}
struct Source {
  string file;
  SourceKind kind;
}

Source[] SOURCES = [
  { "hueshift.c",                    SourceKind.c },   // Must be first
  { "Hijack_HueShift.s",             SourceKind.assembly },
  { "Hijack_PersonalitySave.s",      SourceKind.assembly },
  { "Hijack_BattleSprite.s",         SourceKind.assembly },
  { "Hijack_BattleSprite2.s",        SourceKind.assembly },
  { "Hijack_GbaPal.s",               SourceKind.assembly },
  { "Hijack_MiscSprite.s",           SourceKind.assembly },
  { "Hijack_WalkingPokemon.s",       SourceKind.assembly },
  { "Hijack_WalkingPokemonDetect.s", SourceKind.assembly },
  { "Hijack_BoxSprite1.s",           SourceKind.assembly },
  { "Hijack_BoxSprite2.s",           SourceKind.assembly },
  { "Hijack_HofRegisterSetup.s",     SourceKind.assembly },
  { "Hijack_LoadPal.s",              SourceKind.assembly },
  { "Hijack_HofViewSetup.s",         SourceKind.assembly },
  { "Hijack_Ov74Setup.s",            SourceKind.assembly },
  { "Hijack_Ov98Setup.s",            SourceKind.assembly },
  { "Hijack_Ov112.s",                SourceKind.assembly },
  { "Hijack_PersonalityStore.s",     SourceKind.assembly },
  { "Hijack_HofRegisterOw.s",        SourceKind.assembly },
  { "Hijack_HofViewOw.s",            SourceKind.assembly },
  { "Hijack_PokewalkerStatus.s",     SourceKind.assembly },
];

immutable FilePair OW_SPRITES_FILE = { "ow_sprites.narc", "ow_sprites_patched.narc" };
immutable string PALETTE_CHANGES_FOLDER = "./ShinyChanges/FollowPals";

string gDevkitproPath, gDevkitarmPath;

int main() {
  writeln("Building...");

  gDevkitproPath = environment.get("DEVKITPRO");
  gDevkitarmPath = environment.get("DEVKITARM");

  if (!gDevkitproPath || !gDevkitarmPath) {
    stderr.writeln("Error: DEVKITPRO and DEVKITARM must be in your PATH.\n",
                   "Ensure DevkitARM is installed and try again.");
    return 1;
  }

  size_t[string] compiledLocations;
  ubyte[] customOverlay; // = new ubyte[](CUSTOM_OVERLAY_SIZE);
  enum CO_START_ADDR = 0x023C8000;
  enum CO_FREE_RAM_SIZE = 0x30;

  writeln("Inserting ", CO_FREE_RAM_SIZE, " bytes of space in the custom overlay to use as free RAM...");
  customOverlay.length = CO_FREE_RAM_SIZE;

  // The hue shift table and shiftPalette() function must be in fixed locations for now because
  // the various hijacks must assume where it is. Putting off making that dynamic for the moment...
  writeln("Inserting hue shift table to custom overlay @ 0x", customOverlay.length.to!string(16), " (0x", (CO_START_ADDR + customOverlay.length).to!string(16), ")");
  customOverlay ~= cast(ubyte[]) generateHueShiftTable();
  assert(customOverlay.length == CO_FREE_RAM_SIZE + 128);

  foreach (source; SOURCES) {
    writeln("Compiling ", source.file, "...");
    ubyte[] compiledBinary = compile(source);

    // Functions must be aligned to a 4-byte boundary!
    customOverlay.length = (customOverlay.length + 4 - 1) & ~(4 - 1);

    compiledLocations[source.file] = customOverlay.length;
    writeln("  Inserting to custom overlay @ 0x", customOverlay.length.to!string(16), " (0x", (CO_START_ADDR + customOverlay.length).to!string(16), ")");
    customOverlay ~= compiledBinary;
  }

  ubyte[][string] codeFileBytes;
  foreach (codeFile; CODE_FILE_NAMES) {
    codeFileBytes[codeFile] = cast(ubyte[]) read(codeFilePath(codeFile, patched : false));
  }

  immutable ubyte[] CUSTOM_OVERLAY_PATCH_1 = [0xFC, 0xB5, 0x05, 0x48, 0xC0, 0x46, 0x1C, 0x21, 0x00, 0x22, 0x02, 0x4D, 0xA8, 0x47, 0x00, 0x20, 0x03, 0x21, 0xFC, 0xBD, 0x09, 0x75, 0x00, 0x02, 0x00, 0x80, 0x3C, 0x02];
  immutable ubyte[] CUSTOM_OVERLAY_PATCH_2 = [0x0F, 0xF1, 0x30, 0xFB];

  patch(codeFileBytes["arm9"], 0x110334, CUSTOM_OVERLAY_PATCH_1);
  patch(codeFileBytes["arm9"], 0xCD0,    CUSTOM_OVERLAY_PATCH_2);

  // hijack palette load function to jump to Hijack_HueShift.s
  patchBl(0x999C,  0x0200999C, CO_START_ADDR, compiledLocations["Hijack_HueShift.s"],             codeFileBytes["arm9"]);

  // hijack GetPkmnData to jump to Hijack_PersonalitySave.s
  patchBl(0x6E542, 0x0206E542, CO_START_ADDR, compiledLocations["Hijack_PersonalitySave.s"],      codeFileBytes["arm9"]); // GetPkmnData
  patchBl(0x6E642, 0x0206E642, CO_START_ADDR, compiledLocations["Hijack_PersonalitySave.s"],      codeFileBytes["arm9"]); // GetBoxPkmnData

  // hijack stuff related to in-battle GBA-styled sprites
  patchBl(0x3FA6,  0x0221FDC6, CO_START_ADDR, compiledLocations["Hijack_BattleSprite.s"],         codeFileBytes["overlay7"]); // on change sprite during switchout
  patchBl(0x1BCA,  0x0221D9EA, CO_START_ADDR, compiledLocations["Hijack_BattleSprite2.s"],        codeFileBytes["overlay7"]); // on change sprite during move animation
  patchBl(0x31E4,  0x020031E4, CO_START_ADDR, compiledLocations["Hijack_GbaPal.s"],               codeFileBytes["arm9"],   ); // on any GBA-styled sprite palette load

  // hijack stuff needed to get misc sprite loads working (HM use, introduction)
  patchBl(0x14480, 0x02014480, CO_START_ADDR, compiledLocations["Hijack_MiscSprite.s"],           codeFileBytes["arm9"]);

  // hijack stuff needed to hue shift walking/following Pokemon
  patchBl(0x14BD6, 0x021FA4D6, CO_START_ADDR, compiledLocations["Hijack_WalkingPokemon.s"],       codeFileBytes["overlay1"]);
  patchBl(0xBA8,   0x021E64A8, CO_START_ADDR, compiledLocations["Hijack_WalkingPokemonDetect.s"], codeFileBytes["overlay1"]);

  // hijack stuff needed to get PC box sprites working
  patchBl(0xDDC2,  0x021F36C2, CO_START_ADDR, compiledLocations["Hijack_BoxSprite1.s"],           codeFileBytes["overlay14"]); // on pc box pokemon palette load
  patchBl(0x7E00,  0x02007E00, CO_START_ADDR, compiledLocations["Hijack_BoxSprite2.s"],           codeFileBytes["arm9"],    ); // general palette upload

  // hijack stuff needed to get Hall of Fame registration working
  patchBl(0x701F8, 0x020701F8, CO_START_ADDR, compiledLocations["Hijack_PersonalityStore.s"],     codeFileBytes["arm9"],    ); // on determining pokemon sprite and palette
  patchBl(0x7059E, 0x0207059E, CO_START_ADDR, compiledLocations["Hijack_PersonalityStore.s"],     codeFileBytes["arm9"],    ); // on determining pokemon sprite and palette
  patchBl(0xB22,   0x0221C942, CO_START_ADDR, compiledLocations["Hijack_HofRegisterSetup.s"],     codeFileBytes["overlay63"]); // on HoF register pokemon palette load
  patchBl(0xE44,   0x0221CC64, CO_START_ADDR, compiledLocations["Hijack_HofRegisterOw.s"],        codeFileBytes["overlay63"]); // on HoF register pokemon OW sprite palette load
  patchBl(0x795E,  0x0200795E, CO_START_ADDR, compiledLocations["Hijack_LoadPal.s"],              codeFileBytes["arm9"],    ); // on HoF register pokemon palette load

  // hijack stuff needed to get Hall of Fame viewing working
  patchBl(0x1002,  0x021E6902, CO_START_ADDR, compiledLocations["Hijack_HofViewSetup.s"],         codeFileBytes["overlay64"]); // on HoF pokemon palette load
  patchBl(0x1504,  0x021E6E04, CO_START_ADDR, compiledLocations["Hijack_HofViewOw.s"],            codeFileBytes["overlay64"]); // on HoF view pokemon OW sprite palette load

  // Pokewalker
  patchBl(0xB3F2,  0x021F0CF2, CO_START_ADDR, compiledLocations["Hijack_Ov112.s"],                codeFileBytes["overlay112"]);  // Choosing Pokemon for Pokewalker stroll
  patchBl(0x39DE,  0x021E92DE, CO_START_ADDR, compiledLocations["Hijack_PokewalkerStatus.s"],     codeFileBytes["overlay112"]);  // Showing Pokewalker stroll status

  // unknown hijacks?
  patchBl(0xEB60,  0x02235BC0, CO_START_ADDR, compiledLocations["Hijack_Ov74Setup.s"],            codeFileBytes["overlay74"]);
  patchBl(0x2CA,   0x0221E88A, CO_START_ADDR, compiledLocations["Hijack_Ov98Setup.s"],            codeFileBytes["overlay98"]);
  patchBl(0x1682,  0x0221FC42, CO_START_ADDR, compiledLocations["Hijack_Ov112.s"],                codeFileBytes["overlay97"]);

  foreach (codeFile; CODE_FILE_NAMES) {
    std.file.write(codeFilePath(codeFile, patched : true), codeFileBytes[codeFile]);
  }

  customOverlay.length = CUSTOM_OVERLAY_SIZE;

  auto narcArena                = arenaMake(8 * 1024 * 1024);
  auto coBytes                  = cast(ubyte[]) read(CUSTOM_OVERLAY_FILE.original);
  writeln("Unpacking the NARC that will hold the custom overlay...");
  auto narcUnpack               = parseNarc(&narcArena, coBytes);

  bool bail = false;
  foreach (error; linkedRange(narcUnpack.errors)) {
    writeln("NARC parse error: severity = ", error.severity, " | ", error.message);
    bail = bail || error.severity >= Severity.error;
  }
  if (bail) throw new Exception("There were errors parsing the custom overlay NARC!");

  narcUnpack.narc.files[0].data = customOverlay;


  writeln("Repacking the custom overlay NARC...");
  auto repackedNarc             = packNarc(&narcArena, narcUnpack.narc);
  std.file.write(CUSTOM_OVERLAY_FILE.patched, repackedNarc);

  clear(&narcArena);

  writeln("Unpacking the OW sprites NARC...");
  auto owNarcBytes = cast(ubyte[]) read(OW_SPRITES_FILE.original);
  narcUnpack       = parseNarc(&narcArena, owNarcBytes);

  bail = false;
  foreach (error; linkedRange(narcUnpack.errors)) {
    writeln("NARC parse error: severity = ", error.severity, " | ", error.message);
    bail = bail || error.severity >= Severity.error;
  }
  if (bail) throw new Exception("There were errors parsing the OW sprites NARC!");

  // Loop for all pokemon OW sprite narc IDs
  foreach (subfileId; 297..862+1) {
    string palFilenameBase      = PALETTE_CHANGES_FOLDER ~ "/" ~ subfileId.to!string;
    string palFilenameBtx       = palFilenameBase ~ ".btx";
    string palFilenameTxtNormal = palFilenameBase ~ "_normal.txt";
    string palFilenameTxtShiny  = palFilenameBase ~ "_shiny.txt";

    // If a whole btx was provided, use that. Otherwise, patch just the palette using the txts.
    if (exists(palFilenameBtx)) {
      writeln("Patching OW palettes with file ", palFilenameBtx, "...");
      narcUnpack.narc.files[subfileId].data = cast(ubyte[]) read(palFilenameBtx);
    }
    else {
      ubyte[] palSubfile = narcUnpack.narc.files[subfileId].data;

      // The value at 0x38 will either be either 0x116C or 0x416C depending on whether or not the sprite is
      // large. This offset plus 0x14 will get us to the palette data.
      // Thanks, BluRosie!
      size_t palDataOffset = littleEndianToNative!ushort(palSubfile[0x38..0x38+2]) + 0x14;
      if (palDataOffset != 0x1180 && palDataOffset != 0x4180) {
        writeln("Warning: Palette data offset in BTX subfile ", subfileId, " is ", palDataOffset, ", which is not typical! (This may be okay.)");
      }

      if (exists(palFilenameTxtNormal)) {
        writeln("Patching normal OW palette with file ", palFilenameTxtNormal, "...");
        ubyte[] palNormal = palSubfile[palDataOffset+0..palDataOffset+32];
        writePalBinary(readText(palFilenameTxtNormal), palNormal);
      }
      if (exists(palFilenameTxtShiny)) {
        writeln("Patching shiny OW palette with file ", palFilenameTxtShiny, "...");
        ubyte[] palShiny  = palSubfile[palDataOffset+32..palDataOffset+64];
        writePalBinary(readText(palFilenameTxtShiny), palShiny);
      }
    }
  }

  writeln("Repacking the OW sprites NARC...");
  repackedNarc = packNarc(&narcArena, narcUnpack.narc);
  std.file.write(OW_SPRITES_FILE.patched, repackedNarc);

  writeln("Done!");

  return 0;
}

ubyte[] compile(Source source) {
  string objFilename = source.file.baseName ~ ".o";

  string[] cmdLine;
  final switch (source.kind) {
    case SourceKind.assembly:
      cmdLine = [
        gDevkitarmPath ~ "/bin/arm-none-eabi-as",
        "-march=armv5te", "-mthumb", "-mthumb-interwork",
        "-c", source.file, "-o", objFilename
      ];
      break;
    case SourceKind.c:
      cmdLine = [
        gDevkitarmPath ~ "/bin/arm-none-eabi-gcc",
        "-Wall", "-Os", "-march=armv5te", "-mtune=arm946e-s", "-fomit-frame-pointer", "-ffast-math",
        "-mthumb", "-mthumb-interwork", "-fshort-enums",
        "-I" ~ gDevkitproPath ~ "/calico/include",
        "-I" ~ gDevkitproPath ~ "/libnds/include",
        "-D__NDS__", "-DARM9",
        "-c", source.file, "-o", objFilename
      ];
      break;
  }

  auto compileResult = execute(cmdLine);

  if (compileResult.status != 0) {
    throw new Exception("Compilation failed: " ~ compileResult.output);
  }

  // @TODO: Replace this with an actual ELF parser...?
  auto objcopyResult = execute([gDevkitarmPath ~ "/bin/arm-none-eabi-objcopy", "-O", "binary", "-j", ".text", objFilename, "temp_bin"]);
  if (compileResult.status != 0) {
    throw new Exception("Extraction of compiled source binary failed: " ~ compileResult.output);
  }

  return cast(ubyte[]) read("temp_bin");
}

void patch(ubyte[] fileBytes, size_t address, const(ubyte)[] data) {
  fileBytes[address..address+data.length] = data;
}

uint makeBl(int Value) {
  // Taken from: https://github.com/keystone-engine/keystone/blob/e1547852d9accb9460573eb156fc81645b8e1871/llvm/lib/Target/ARM/MCTargetDesc/ARMAsmBackend.cpp#L497-L523

  // The value doesn't encode the low bit (always zero) and is offset by
  // four. The 32-bit immediate value is encoded as
  //   imm32 = SignExtend(S:I1:I2:imm10:imm11:0)
  // where I1 = NOT(J1 ^ S) and I2 = NOT(J2 ^ S).
  // The value is encoded into disjoint bit positions in the destination
  // opcode. x = unchanged, I = immediate value bit, S = sign extension bit,
  // J = either J1 or J2 bit
  //
  //   BL:  xxxxxSIIIIIIIIII xxJxJIIIIIIIIIII
  //
  // Note that the halfwords are stored high first, low second; so we need
  // to transpose the fixup value here to map properly.
  uint offset    = (Value  - 4)           >> 1;
  uint signBit   = (offset & 0x800000)    >> 23;
  uint I1Bit     = (offset & 0x400000)    >> 22;
  uint J1Bit     = (I1Bit  ^ 0x1)         ^  signBit;
  uint I2Bit     = (offset & 0x200000)    >> 21;
  uint J2Bit     = (I2Bit  ^ 0x1)         ^  signBit;
  uint imm10Bits = (offset & 0x1FF800)    >> 11;
  uint imm11Bits = (offset & 0x000007FF);

  uint FirstHalf = ((cast(ushort)signBit << 10) | cast(ushort)imm10Bits);
  uint SecondHalf = ((cast(ushort)J1Bit << 13) | (cast(ushort)J2Bit << 11) |
                         cast(ushort)imm11Bits);

  FirstHalf  |= 0b1111000000000000;
  SecondHalf |= 0b1111100000000000;

  return FirstHalf | (SecondHalf << 16);
}

void patchBl(size_t srcAddrInFile, size_t srcAddrInRam, size_t coStartAddr, size_t destAddrInCo, ubyte[] fileBytes) {
  // @TODO: It would be nice to just read the overlay locations up front so that I don't need to do manual math
  //        to list both source locations.

  size_t destAddrInRam = coStartAddr + destAddrInCo;
  ubyte[4] blBytes = nativeToLittleEndian(makeBl((cast(int) destAddrInRam)-(cast(int) srcAddrInRam)));

  patch(fileBytes, srcAddrInFile, blBytes[]);
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

void writePalBinary(string inTxt, ubyte[] outBytes) {
  outBytes[] =
    inTxt
    .lineSplitter
    .filter!(x => x.startsWith("#"))
    .map!(x => x.dropOne.to!uint(16))
    .map!rgb888To555
    .map!(x => nativeToLittleEndian(x)[].dup)
    .joiner
    .array;
}

//////////////

enum HUE_SHIFT_DEG_MIN = 0, HUE_SHIFT_DEG_MAX = 20.0, HUE_SHIFT_VALS = 32;

alias fixed = int;
enum FIX_SHIFT = 10;

fixed toFixed(float f) {
  return cast(fixed)(f * (2^^FIX_SHIFT));
}

float toFloat(fixed f) {
  return ((f & ~((1 << FIX_SHIFT)-1))>>FIX_SHIFT) + (f & ((1 << FIX_SHIFT)-1)) / (2.0^^FIX_SHIFT);
}

ushort[] generateHueShiftTable() {
  int shiftAmount = 16;

  ushort[] result;

  foreach (func; [&cos, &sin]) {
    foreach (x; 0..HUE_SHIFT_VALS) {
      auto angle = (HUE_SHIFT_DEG_MIN + x*(HUE_SHIFT_DEG_MAX-HUE_SHIFT_DEG_MIN)/(HUE_SHIFT_VALS-1.0));
      auto fixedVal = func( angle *PI/180 ).toFixed;

      result ~= cast(ushort) fixedVal;
      //fixedVal.nativeToLittleEndian.each!(a => writefln("%02X", a));
      //write("    (", fixedVal.toFloat, ")");
      //writeln;
      //writefln("%d - 0x%08X - %f, %f", x, fixedVal, angle, func( angle *PI/180) );
    }
    //writeln;
  }

  return result;
}

/*
current values (in little endian):

cos:
0004
FF03
FF03
FF03
FE03
FE03
FD03
FC03
FB03
FA03
F903
F803
F603
F503
F303
F103
EF03
ED03
EB03
E803
E603
E303
E003
DD03
DA03
D703
D403
D103
CD03
C903
C603
C203

sin:
0000
0B00
1700
2200
2E00
3900
4500
5000
5C00
6700
7300
7E00
8900
9500
A000
AC00
B700
C200
CE00
D900
E400
EF00
FB00
0601
1101
1C01
2701
3201
3D01
4801
5301
5E01

*/