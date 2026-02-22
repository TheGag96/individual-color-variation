module arena;

struct Arena {
  ubyte[] data;
  ubyte* index;

  debug size_t watermark, highWatermark;
}

Arena arenaMake(ubyte[] buffer) {
  Arena result;

  result.data  = buffer;
  result.index = buffer.ptr;

  return result;
}

Arena arenaMake(size_t bytes) {
  // Allocate the backing buffer on the GC (for now) to ensure the GC doesn't prematurely free things, since it won't
  // scan for pointers in buffers allocated from elsewhere by default.
  return arenaMake(new ubyte[](bytes));
}

void arenaFree(Arena* arena) {
  import core.stdc.stdlib : free;
  free(arena.data.ptr);
  *arena = Arena.init;
}

void clear(Arena* arena) {
  arena.index = arena.data.ptr;
  debug arena.watermark = 0;
}

struct ScopedArenaRestore {
  @nogc: nothrow:

  Arena* arena;
  ubyte* oldIndex;
  @disable this();

  pragma(inline, true)
  this(Arena* arena) {
    this.arena    = arena;
    this.oldIndex = arena.index;
  }

  pragma(inline, true)
  ~this() {
    arena.index = oldIndex;
  }
}

// Internal.
ubyte* alignBumpIndex(Arena* arena, size_t amount, size_t alignment) { with (arena) {
  ubyte* toReturn = cast(ubyte*) ((cast(size_t)index + alignment - 1) & ~(alignment - 1));
  ubyte* newIndex = toReturn + amount;

  debug {
    if (newIndex > data.ptr + watermark) {
      watermark = cast(size_t) (newIndex - data.ptr);

      if (watermark > highWatermark) highWatermark = watermark;
    }
  }

  if (newIndex > data.ptr + data.length) {
    assert(0, "Arena allocation failed!");  // @TODO: Consider chained arenas
    return null;
  }
  else {
    index = newIndex;
    return toReturn;
  }
}}

ubyte[] pushBytes(Arena* arena, size_t bytes, size_t aligning = 1) {
  import core.stdc.string : memset;

  auto result = pushBytesNoZero(arena, bytes, aligning);
  memset(result.ptr, 0, result.length);
  return result;
}

ubyte[] pushBytesNoZero(Arena* arena, size_t bytes, size_t aligning = 1) {
  ubyte* result = alignBumpIndex(arena, bytes, aligning);
  return (cast(ubyte*) result)[0..bytes];
}

T* push(T, bool init = true)(Arena* arena) {
  import core.lifetime : emplace;

  T* result = cast(T*) alignBumpIndex(arena, T.sizeof, T.alignof);
  static if (init && __traits(compiles, () { auto test = T.init; })) {
    emplace!T(result, T.init);
  }

  return result;
}

T[] pushArray(T, bool init = true)(Arena* arena, size_t size) {
  import core.lifetime : emplace;

  T* result = cast(T*) alignBumpIndex(arena, size*T.sizeof, T.alignof);
  static if (init && __traits(compiles, () { auto test = T.init; })) {
    foreach (i; 0..size) {
      emplace!T(result + i, T.init);
    }
  }

  return result[0..size];
}

Arena pushArena(Arena* parent, size_t bytes, size_t aligning = 16) {
  Arena result;

  result.data  = pushBytesNoZero(parent, bytes, aligning);
  result.index = result.data.ptr;

  return result;
}

T* copy(T)(Arena* arena, in T thing) {
  auto result = push!(T, false)(arena);
  *result = thing;
  return result;
}

T[] copyArray(T)(Arena* arena, const(T)[] arr) {
  import core.stdc.string : memcpy;
  auto result = pushArray!(T, false)(arena, arr.length);
  memcpy(result.ptr, arr.ptr, T.sizeof * arr.length);
  return result;
}

void expandArray(T, bool init = true)(Arena* arena, T[]* arr, size_t count) {
  // @TODO: This function will probably need to be changed a bit if I support growing arenas.

  // @Optimization: expand the array in place if it was the last thing allocated
  if (cast(ubyte*) (arr.ptr + arr.length) != arena.index) {
    // Otherwise, have to waste memory by copying it...
    *arr = copyArray(*arr);
  }

  pushArray!(T, init)(arena, count);
  *arr = arr.ptr[0..arr.length + count];
}

void appendArray(T)(Arena* arena, T[]* arr, const(T)[] other) {
  expandArray(T, false)(arena, arr, other.length);
  memcpy(arr.ptr + arr.length - other.length, other.ptr, T.sizeof * other.length);
}

pragma(printf)
extern(C) char[] aprintf(Arena* arena, const(char)* spec, ...) {
  import core.stdc.stdio  : vsnprintf;
  import core.stdc.stdarg : va_list, va_start, va_end;

  va_list args;
  va_start(args, spec);
  scope (exit) va_end(args);

  int spaceRemaining = cast(int) (arena.data.length - (arena.index-arena.data.ptr));

  int length = vsnprintf(cast(char*) arena.index, spaceRemaining, spec, args);

  assert(length >= 0); //no idea what to do if length comes back negative

  // Plus one because of the null character
  char* result = cast(char*)alignBumpIndex(arena, length+1, 1);

  return result[0..length];
}

pragma(inline, true)
bool owns(Arena* arena, void* thing) {
  return thing >= arena.data.ptr && thing < arena.data.ptr + arena.data.length;
}
