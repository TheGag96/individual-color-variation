void main(string[] args) {
  import std.algorithm : each;
  import std.bitmanip  : nativeToLittleEndian;
  import std.conv      : to;
  import std.stdio     : writeln, writef;

  if (args.length != 3) {
    writeln("Usage: makebl from to");
  }

  uint fromAddr = args[1].to!uint(16), toAddr = args[2].to!uint(16);

  (toAddr-fromAddr)
    .makeBl
    .nativeToLittleEndian
    .each!(x => writef("%02X ", x));

  writeln;
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
  uint offset = (Value - 4) >> 1;
  uint signBit = (offset & 0x800000) >> 23;
  uint I1Bit = (offset & 0x400000) >> 22;
  uint J1Bit = (I1Bit ^ 0x1) ^ signBit;
  uint I2Bit = (offset & 0x200000) >> 21;
  uint J2Bit = (I2Bit ^ 0x1) ^ signBit;
  uint imm10Bits = (offset & 0x1FF800) >> 11;
  uint imm11Bits = (offset & 0x000007FF);

  uint FirstHalf = ((cast(ushort)signBit << 10) | cast(ushort)imm10Bits);
  uint SecondHalf = ((cast(ushort)J1Bit << 13) | (cast(ushort)J2Bit << 11) |
                         cast(ushort)imm11Bits);

  FirstHalf  |= 0b1111000000000000;
  SecondHalf |= 0b1111100000000000;

  return FirstHalf | (SecondHalf << 16);
}

