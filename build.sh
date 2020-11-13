#!/bin/bash

set -e

# compile asm and C files
eval $DEVKITARM/bin/arm-none-eabi-gcc -Wall -Os -march=armv5te -mtune=arm946e-s -fomit-frame-pointer -ffast-math -mthumb -mthumb-interwork -I/opt/devkitpro/libnds/include -DARM9 -c hueshift.c -o hueshift.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack.s -o Hijack.o

# compile binary patch tool
dmd binpatch.d

# prepare patched output .bin file
cp arm9_vanilla.bin arm9_patched.bin

# extract compiled machine code and patch them to specific locations
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack.o temp_bin
od -An -t x1 temp_bin | ./binpatch arm9_patched.bin 5023C
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text hueshift.o temp_bin

# geneate sin/cos table and patch to its location
dmd tableprinter.d
./tableprinter | ./binpatch arm9_patched.bin 500BC

rm temp_bin