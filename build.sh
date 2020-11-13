#!/bin/bash

set -e

original_arm9bin=arm9_vanilla.bin
patched_arm9bin=arm9_patched.bin

# compile asm and C files
eval $DEVKITARM/bin/arm-none-eabi-gcc -Wall -Os -march=armv5te -mtune=arm946e-s -fomit-frame-pointer -ffast-math -mthumb -mthumb-interwork -I/opt/devkitpro/libnds/include -DARM9 -c hueshift.c -o hueshift.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack.s -o Hijack.o

# compile binary patch tool
dmd binpatch.d

# prepare patched output .bin file
cp $original_arm9bin $patched_arm9bin

# extract compiled machine code and patch them to specific locations
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 5023C
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text hueshift.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 500BC

# geneate sin/cos table and patch to its location
dmd tableprinter.d
./tableprinter | ./binpatch $patched_arm9bin 5003C

# hijack palette load function to jump to Hijack.s
echo 47 F0 10 F9 | ./binpatch $patched_arm9bin 9018

rm temp_bin