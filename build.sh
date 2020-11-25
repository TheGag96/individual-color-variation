#!/bin/bash

set -e

original_arm9bin=arm9_vanilla.bin
patched_arm9bin=arm9_patched.bin

# compile asm and C files
eval $DEVKITARM/bin/arm-none-eabi-gcc -Wall -Os -march=armv5te -mtune=arm946e-s -fomit-frame-pointer -ffast-math -mthumb -mthumb-interwork -I/opt/devkitpro/libnds/include -DARM9 -c hueshift.c -o hueshift.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack.s -o Hijack.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_PersonalitySave.s -o Hijack_PersonalitySave.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_PersonalityClearPokedex.s -o Hijack_PersonalityClearPokedex.o

# compile binary patch tool
dmd binpatch.d

# prepare patched output .bin file
cp $original_arm9bin $patched_arm9bin

# extract compiled machine code and patch them to specific locations
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 5023C
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text hueshift.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 500BC
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_PersonalitySave.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 50204
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_PersonalityClearPokedex.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 50280

# geneate sin/cos table and patch to its location
dmd tableprinter.d
./tableprinter | ./binpatch $patched_arm9bin 5003C

# hijack palette load function to jump to Hijack.s
echo 47 F0 10 F9 | ./binpatch $patched_arm9bin 9018

# hijack GetPkmnData to jump to Hijack_PersonalitySave.s
echo DB F7 C7 FE | ./binpatch $patched_arm9bin 74472 # GetPkmnData
echo DB F7 47 FE | ./binpatch $patched_arm9bin 74572 # GetBoxPkmnData

# hijack some pokedex routine to jump to Hijack_PersonalityClearPokedex.s
echo 28 F0 87 FE | ./binpatch $patched_arm9bin 2756E

rm temp_bin