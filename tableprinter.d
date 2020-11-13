import std.stdio, std.math, std.conv, std.range, std.bitmanip;

enum MIN = 0, MAX = 20.0, VALS = 32;

alias fixed = int;
enum FIX_SHIFT = 10;

fixed toFixed(float f) {
  return cast(fixed)(f * 2^^FIX_SHIFT);
}

float toFloat(fixed f) {
  return ((f & ~((1 << FIX_SHIFT)-1))>>FIX_SHIFT) + (f & ((1 << FIX_SHIFT)-1)) / (2.0^^FIX_SHIFT);
}

void main(string[] args) {
  int shiftAmount = 16; 
  if (args.length >= 2) args[1].to!int;

  foreach (func; [&cos, &sin]) {
    foreach (x; 0..VALS) {
      auto angle = (MIN + x*(MAX-MIN)/(VALS-1.0));
      auto fixedVal = func( angle *PI/180 ).toFixed;

      writef("%04X", (cast(ushort) fixedVal).swapEndian);
      //fixedVal.nativeToLittleEndian.each!(a => writefln("%02X", a));
      //write("    (", fixedVal.toFloat, ")");
      writeln;
      //writefln("%d - 0x%08X - %f, %f", x, fixedVal, angle, func( angle *PI/180) );
    }
    writeln;
  }
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