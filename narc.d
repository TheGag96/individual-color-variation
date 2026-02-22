module narc;

import arena, util;
import std.bitmanip;

// Thank you Mr. No$ man!!
// http://problemkaputt.de/gbatek-ds-cartridge-nitrorom-and-nitroarc-file-systems.htm
struct NarcHeader {
  char[4] name = "NARC";
  ushort byteOrder = 0xFFFE;
  ushort ver = 0x0100;
  uint fileSize;  // from "NARC" ID to end of file
  ushort chunkSize = 0x0010;
  ushort numChunks = 0x0003;
}

struct ChunkHeader {
  char[4] name;
  uint size;
}

struct BtafChunkExtra {
  ushort numFiles;
  ushort reserved;  // I wonder if this is really just a 4-byte field?
}

struct FatEntry {
  uint start; // originated at IMG base
  uint end;   // Start + Len
}

struct FntMainTableEntry {
  uint subTableOffset; // originated at FNT base
  ushort subTableFirstFile;
  ushort numDirsOrParent;  // In the first entry, it means total number of directories; in subsequent, it means parent ID
}

enum Chunk {
  fat,  // File Allocation Table
  fnt,  // File Name Table
  img, // File Data
}

immutable char[4][Chunk.max+1] CHUNK_TAGS = [
  Chunk.fat : "BTAF",
  Chunk.fnt : "BTNF",
  Chunk.img : "GMIF",
];

struct NarcParseResult {
  Narc* narc;
  NarcError* errors;
  Severity highestSeverity;
}

enum Severity {
  debugging,
  info,
  warning,
  error,
}

struct NarcError {
  NarcError* next;
  uint pos;
  Severity severity;
  const(char)[] message;
}

void addError(Arena* arena, NarcParseResult* result, uint pos, Severity severity, const(char)[] message) {
  auto newOne     = push!NarcError(arena);
  newOne.pos      = pos;
  newOne.severity = severity;
  newOne.message  = message;

  if (severity > result.highestSeverity) {
    result.highestSeverity = severity;
  }

  if (result.errors == null) {
    result.errors = newOne;
  }
  else {
    result.errors.next = newOne;
  }
}

struct NarcFile {
  NarcFile* parent, first, last, next, prev;
  ushort id;
  uint offset;
  char[] name;
  ubyte[] data;

  bool isNull() {
    return &this == null || &this == &gNullFile;
  }
}

bool isDirectory(in NarcFile file) {
  return (file.id & 0xF000) != 0;
}

__gshared const NarcFile gNullFile = {
  first: cast(NarcFile*) &gNullFile, last: cast(NarcFile*) &gNullFile, next: cast(NarcFile*) &gNullFile, prev: cast(NarcFile*) &gNullFile, parent: cast(NarcFile*) &gNullFile,
};

struct Narc {
  NarcFile* root;
  NarcFile[] files, directories;
}

pragma(inline, true)
private T* consume(T)(ubyte[] bytes, uint* index) {
  if (bytes.length - *index >= T.sizeof) {
    auto result = &bytes[*index];
    *index += T.sizeof;
    return cast(T*) result;
  }
  else {
    return null;
  }
}

NarcParseResult parseNarc(Arena* arena, ubyte[] bytes) {
  NarcParseResult result;

  result.narc = push!Narc(arena);

  uint index = 0;

  auto header = consume!NarcHeader(bytes, &index);
  if (!header) {
    addError(
      arena, &result, index, Severity.error,
      "The file is too small to even contain a NARC header."
    );
    return result;
  }

  if (header.name != "NARC") {
    addError(
      arena, &result, index, Severity.error,
      "This doesn't look like a NARC file - didn't see the 'NARC' tag at the beginning."
    );
    return result;
  }

  if (header.numChunks != 3) {
    addError(
      arena, &result, index, Severity.warning,
      aprintf(arena, "There should be 3 chunks reported, not %u.", header.numChunks)
    );
  }

  // Chunks immediately follow

  // Parse FAT

  uint fatHeaderStart = index;
  auto fatChunkHeader = consume!ChunkHeader(bytes, &index);
  if (!fatChunkHeader) {
    addError(
      arena, &result, index, Severity.error,
      "Unexpected end of file looking for FAT chunk header."
    );
    return result;
  }

  if (fatChunkHeader.name != CHUNK_TAGS[Chunk.fat]) {
    addError(
      arena, &result, cast(uint) (fatHeaderStart + fatChunkHeader.name.offsetof), Severity.error,
      "Expected the 'BTAF' tag to begin the FAT chunk."
    );
    return result;
  }

  if (fatChunkHeader.size > bytes.length - index - fatChunkHeader.name.sizeof) {
    addError(
      arena, &result, cast(uint) (fatHeaderStart + fatChunkHeader.size.offsetof), Severity.error,
      aprintf(arena, "FAT chunk size %u is too big to fit into this file.", fatChunkHeader.size)
    );
    return result;
  }

  auto fatChunkExtra = consume!BtafChunkExtra(bytes, &index);
  if (!fatChunkExtra) {
    addError(
      arena, &result, index, Severity.error,
      "Unexpected end of file looking for second part of FAT chunk header."
    );
    return result;
  }

  import std.stdio;
  uint fatBase = index;

  // This should be safe since we've bounds checked above.
  uint fatSize = cast(uint) (fatChunkHeader.size - fatChunkHeader.name.sizeof - fatChunkHeader.size.sizeof);
  FatEntry[] fatEntries = (cast(FatEntry*) &bytes[index])[0 .. fatSize / FatEntry.sizeof];

  index = cast(uint) (fatBase + fatChunkHeader.size - ChunkHeader.sizeof - BtafChunkExtra.sizeof);

  // Parse FNT

  uint fntHeaderStart = index;
  auto fntChunkHeader = consume!ChunkHeader(bytes, &index);
  if (!fntChunkHeader) {
    addError(
      arena, &result, index, Severity.error,
      "Unexpected end of file looking for FNT chunk header."
    );
    return result;
  }

  if (fntChunkHeader.name != CHUNK_TAGS[Chunk.fnt]) {
    addError(
      arena, &result, cast(uint) (fntHeaderStart + fntChunkHeader.name.offsetof), Severity.error,
      "Expected the 'BTNF' tag to begin the FNT chunk."
    );
    return result;
  }

  if (fntChunkHeader.size > bytes.length - index - fntChunkHeader.name.sizeof) {
    addError(
      arena, &result, cast(uint) (fntHeaderStart + fntChunkHeader.size.offsetof), Severity.error,
      aprintf(arena, "FNT chunk size %u is too big to fit into this file.", fntChunkHeader.size)
    );
    return result;
  }

  uint fntBase = index, fntTmp = fntBase;
  uint fntSize = cast(uint) (fntChunkHeader.size - fntChunkHeader.name.sizeof - fntChunkHeader.size.sizeof);

  auto firstFntEntry = consume!FntMainTableEntry(bytes, &fntTmp);  // Don't advance index here
  if (!firstFntEntry) {
    addError(
      arena, &result, index, Severity.error,
      "Unexpected end of file looking for FNT."
    );
    return result;
  }

  if (firstFntEntry.numDirsOrParent * FntMainTableEntry.sizeof > fntSize) {
    addError(
      arena, &result, cast(uint) (index + firstFntEntry.numDirsOrParent.offsetof), Severity.error,
      aprintf(arena, "FNT reports %u directories are present, but that's too many to fit in the FNT chunk of size %u.", firstFntEntry.numDirsOrParent, fntChunkHeader.size)
    );
    return result;
  }

  FntMainTableEntry[] mainEntries = (cast(FntMainTableEntry*) &bytes[index])[0..firstFntEntry.numDirsOrParent];

  import std.stdio;

  index = fntBase + fntSize;

  // Parse IMG

  uint imgHeaderStart = index;
  auto imgChunkHeader = consume!ChunkHeader(bytes, &index);
  if (!imgChunkHeader) {
    addError(
      arena, &result, index, Severity.error,
      "Unexpected end of file looking for IMG chunk header."
    );
    return result;
  }

  if (imgChunkHeader.name != CHUNK_TAGS[Chunk.img]) {
    addError(
      arena, &result, cast(uint) (imgHeaderStart + imgChunkHeader.name.offsetof), Severity.error,
      "Expected the 'BTNF' tag to begin the IMG chunk."
    );
    return result;
  }

  if (imgChunkHeader.size > bytes.length - index + (*imgChunkHeader).sizeof) {
    addError(
      arena, &result, cast(uint) (imgHeaderStart + imgChunkHeader.size.offsetof), Severity.error,
      aprintf(arena, "IMG chunk size %u is too big to fit into this file.", imgChunkHeader.size)
    );
    return result;
  }

  uint imgBase = index;
  uint imgSize = cast(uint) (imgChunkHeader.size - ChunkHeader.sizeof);

  index += imgSize;

  if (index != bytes.length) {
    addError(
      arena, &result, index, Severity.warning,
      "There appears to be junk at the end of the file."
    );
    return result;
  }

  // Create file entries

  result.narc.files       = pushArray!(NarcFile, false)(arena, fatEntries.length);
  result.narc.directories = pushArray!(NarcFile, false)(arena, mainEntries.length);
  result.narc.files[]       = cast(NarcFile) gNullFile;
  result.narc.directories[] = cast(NarcFile) gNullFile;

  foreach (i, ref fatEntry; fatEntries) {
    NarcFile* file = &result.narc.files[i];

    file.id = cast(ushort) i;
    file.offset = fatEntry.start;

    if (fatEntry.end < fatEntry.start) {
      addError(
        arena, &result, cast(uint) (cast(ubyte*) &fatEntry.end - bytes.ptr), Severity.error,
        aprintf(arena, "File %zu's end offset is greater than its start offset: 0x%X > 0xX.", i, fatEntry.end, fatEntry.start)
      );
      return result;
    }

    if (fatEntry.start > imgSize) {
      addError(
        arena, &result, cast(uint) (cast(ubyte*) &fatEntry.start - bytes.ptr), Severity.error,
        aprintf(arena, "File %zu's start offset is out of bounds of the IMG section: 0x%X > 0xX.", i, fatEntry.start, imgSize)
      );
      return result;
    }

    if (fatEntry.end > imgSize) {
      addError(
        arena, &result, cast(uint) (cast(ubyte*) &fatEntry.end - bytes.ptr), Severity.error,
        aprintf(arena, "File %zu's end offset is out of bounds of the IMG section: 0x%X > 0xX.", i, fatEntry.end, imgSize)
      );
      return result;
    }

    file.data = bytes[imgBase + fatEntry.start..imgBase + fatEntry.end];

    // name and pointers to be filled in later...
  }

  // Using this name to call the pattern of a NARC that only contains nameless files under a single root directory -
  // see below.
  bool flat = false;

  foreach (dirId, ref mainEntry; mainEntries) {
    bool isRoot = dirId == 0;
    uint runner = fntBase + mainEntry.subTableOffset;
    uint fileId = mainEntry.subTableFirstFile;

    if (runner >= fntBase+fntSize) {
      addError(
        arena, &result, runner, Severity.error,
        aprintf(arena, "FNT main entry 0x04X: Sub-table offset would be at 0xX, which is out of bounds of the FNT chunk.", 0xF000 + dirId, runner)
      );
      return result;
    }

    NarcFile* parent = &result.narc.directories[dirId];

    parent.id = cast(ushort) (0xF000 + dirId);

    int subCount = 0;
    NarcFile* lastFile = null;
    while (true) {
      auto subEntryBase = runner;

      if (runner >= fntBase+fntSize) {
        addError(
          arena, &result, runner, Severity.error,
          aprintf(arena, "Unexpected end of chunk while reading FNT main entry 0x%04X", parent.id)
        );
        return result;
      }

      // 01h..7Fh File Entry          (Length=1..127, without ID field)
      // 81h..FFh Sub-Directory Entry (Length=1..127, plus ID field)
      // 00h      End of Sub-Table
      // 80h      Reserved
      ubyte typeOrLength = bytes[runner];
      if (typeOrLength == 0) {
        // List terminated

        // In some NARCs, there's a hack where the FNT contains a single main root entry with no filenames,
        // accomplished using a sub-table offset to a zero byte WITHIN the main table entry's space!
        // Trying to capture that here. Detection for this is squirrled away here to take advantage
        // of the bounds checking for reading into that weird sub-table already done here.
        if (dirId == 0 && mainEntries.length == 1 && subCount == 0) {
          flat = true;
        }

        break;
      }

      bool  isDir     = (typeOrLength & 0b10000000) != 0;
      ubyte strLength = (typeOrLength & 0b01111111);

      size_t expectedSize = 1 + strLength + (isDir * 2);

      if (fntBase+fntSize - runner < expectedSize) {
        addError(
          arena, &result, runner, Severity.error,
          aprintf(arena, "FNT main entry 0x%04X, sub-entry #%d: Chunk not large enough to hold entry and name string of length %d.", parent.id, subCount, strLength)
        );
        return result;
      }

      runner += 1;
      char[] name = cast(char[]) bytes[runner..runner+strLength];
      runner += strLength;

      NarcFile* file;
      ushort subDirId = 0;
      if (isDir) {
        subDirId = littleEndianToNative!ushort(bytes[runner..runner+2][0..2]);

        if (!(subDirId >= 0xF000 && subDirId <= 0xFFFF) || (subDirId & 0xFFF) >= result.narc.directories.length) {
          addError(
            arena, &result, runner, Severity.error,
            aprintf(arena, "FNT main entry 0x%04X, sub-entry #%d: Directory ID 0x%04X is invalid.", parent.id, subCount, subDirId)
          );
          return result;
        }

        runner += 2;
        file = &result.narc.directories[subDirId & 0xFFF];
      }
      else {
        if (fileId >= result.narc.files.length) {
          addError(
            arena, &result, subEntryBase, Severity.error,
            aprintf(arena, "FNT main entry 0x%04X, sub-entry #%d: This file would have ID 0x04X, but there are in fact fewer files than that.", parent.id, subCount, fileId)
          );
          return result;
        }

        file = &result.narc.files[fileId];
      }

      file.name   = name;
      file.parent = &result.narc.directories[dirId];

      if (lastFile) {
        lastFile.next = file;
        file.prev     = lastFile;
      }
      else {
        parent.first = file;
      }
      lastFile = file;

      if (!isDir) fileId++;
      subCount++;
    }

    parent.last = lastFile;
  }

  // If we found out the NARC is flat, we need to manually fix up the file hierarchy now, because it didn't get done
  // in the loop above.
  if (flat) {
    foreach (i, ref file; result.narc.files) {
      file.parent = &result.narc.directories[0];
      if (i > 0)                          file.prev = &result.narc.files[i-1];
      if (i < result.narc.files.length-1) file.next = &result.narc.files[i+1];
    }

    result.narc.directories[0].first = &result.narc.files[0];
    result.narc.directories[0].last  = &result.narc.files[$-1];
  }

  result.narc.root = &result.narc.directories[0];

  return result;
}

// @Speed: This is an O(n) search.
NarcFile* fileByName(Narc* narc, const(char)[] name) {
  foreach (ref file; narc.files) {
    if (file.name == name) return &file;
  }
  foreach (ref file; narc.directories) {
    if (file.name == name) return &file;
  }
  return cast(NarcFile*) &gNullFile;
}

NarcFile* fileById(Narc* narc, ushort id) {
  // Should I return gNullFile on bounds error?

  if (id < 0xF000) {
    return &narc.files[id];
  }
  else {
    return &narc.directories[id & 0x0FFF];
  }
}

ubyte[] packNarc(Arena* arena, Narc* narc) {
  auto header      = push!NarcHeader(arena);
  ubyte* narcStart = cast(ubyte*) header;

  ubyte* fatStart        = arena.index;
  auto fatChunkHeader    = push!ChunkHeader(arena);
  auto fatChunkExtra     = push!BtafChunkExtra(arena);
  fatChunkHeader.name    = CHUNK_TAGS[Chunk.fat];
  fatChunkExtra.numFiles = cast(ushort) narc.files.length;

  auto fatEntries = pushArray!FatEntry(arena, narc.files.length);

  fatChunkHeader.size = cast(uint) (arena.index - fatStart);

  ubyte* fntStart     = arena.index;
  auto fntChunkHeader = push!ChunkHeader(arena);
  ubyte* fntBase      = arena.index;
  fntChunkHeader.name = CHUNK_TAGS[Chunk.fnt];

  auto mainEntries = pushArray!FntMainTableEntry(arena, narc.directories.length);

  // Detect whether this NARC is "flat" (single root directory, empty filenames).
  // @TODO: It's not really good if any of the files have empty names in a non-flat NARC. Maybe check/assert for that?
  bool flat = () {
    if (mainEntries.length > 1) return false;

    foreach (ref file; narc.files) {
      if (file.name.length) return false;
    }

    return true;
  }();

  if (flat) {
    // Hack that I've seen in officially-packed "flat" NARCs: This subTableOffset of 4 will point to a zero-byte within
    // this very entry!
    mainEntries[0] = FntMainTableEntry(subTableOffset : 4, subTableFirstFile : 0, numDirsOrParent : 1);
  }
  else {
    foreach (dirId, ref file; narc.directories) {
      bool wroteFirstFile = false;

      mainEntries[dirId].subTableOffset = cast(uint) (arena.index - fntBase);

      if (dirId == 0) {
        mainEntries[dirId].numDirsOrParent = cast(ushort) mainEntries.length;
      }
      else {
        mainEntries[dirId].numDirsOrParent = file.parent.id;
      }

      foreach (subFile; linkedRange(file.first)) {
        auto typeOrLength = push!ubyte(arena);
        *typeOrLength = cast(ubyte) subFile.name.length;
        if (isDirectory(*subFile)) {
          *typeOrLength |= 0b10000000;
        }

        copyArray(arena, subFile.name);
        if (!isDirectory(*subFile) && !wroteFirstFile) {
          wroteFirstFile = true;
          mainEntries[dirId].subTableFirstFile = subFile.id;
        }

        if (isDirectory(*subFile)) {
          *push!ushort(arena) = subFile.id;
        }
      }

      pushBytes(arena, 1);  // 0 byte to end table
    }
  }

  void padTo4Alignment() {
    auto padding = pushBytesNoZero(arena, -(arena.index - narcStart) & (4-1));
    padding[] = 0xFF;
  }

  // GBATEK says we need to pad 0xFFs to the nearest 4 bytes at the end of this chunk.
  padTo4Alignment();

  fntChunkHeader.size = cast(uint) (arena.index - fntStart);

  ubyte* imgStart     = arena.index;
  auto imgChunkHeader = push!ChunkHeader(arena);
  ubyte* imgBase      = arena.index;
  imgChunkHeader.name = CHUNK_TAGS[Chunk.img];

  foreach (i, ref file; narc.files) {
    fatEntries[i].start = cast(uint) (arena.index - imgBase);
    fatEntries[i].end   = cast(uint) (fatEntries[i].start + file.data.length);
    copyArray(arena, file.data);

    // Pad to the nearest 4 bytes with 0xFFs, which seems to be how official NARCs are packed
    padTo4Alignment();
  }

  imgChunkHeader.size = cast(uint) (arena.index - imgStart);

  header.fileSize = cast(uint) (arena.index-narcStart);

  return narcStart[0..header.fileSize];
}
