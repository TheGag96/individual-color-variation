#!/bin/bash

set -e

original_arm9bin=arm9_vanilla.bin
patched_arm9bin=arm9_patched.bin

original_overlay12bin=overlay12_vanilla.bin
patched_overlay12bin=overlay12_patched.bin

original_overlay16bin=overlay16_vanilla.bin
patched_overlay16bin=overlay16_patched.bin

# compile asm and C files
eval $DEVKITARM/bin/arm-none-eabi-gcc -Wall -Os -march=armv5te -mtune=arm946e-s -fomit-frame-pointer -ffast-math -mthumb -mthumb-interwork -I/opt/devkitpro/libnds/include -DARM9 -c hueshift.c -o hueshift.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_HueShift.s -o Hijack_HueShift.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_PersonalitySave.s -o Hijack_PersonalitySave.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_PersonalityClearPokedex.s -o Hijack_PersonalityClearPokedex.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_BattleSprite.s -o Hijack_BattleSprite.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_BattleSprite2.s -o Hijack_BattleSprite2.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_BattleSprite3.s -o Hijack_BattleSprite3.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_GbaPal.s -o Hijack_GbaPal.o
eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c Hijack_BattleDataPtrSave.s -o Hijack_BattleDataPtrSave.o

# compile binary patch tool
dmd binpatch.d

# prepare patched output .bin file
cp $original_arm9bin $patched_arm9bin
cp $original_overlay12bin $patched_overlay12bin
cp $original_overlay16bin $patched_overlay16bin

# extract compiled machine code and patch them to specific locations
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_HueShift.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 5023C
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text hueshift.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 500BC
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_PersonalitySave.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 50204
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_PersonalityClearPokedex.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 50280
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_BattleSprite.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 502A0
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_GbaPal.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 502E0
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_BattleSprite2.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 50320
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_BattleSprite3.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 50380
eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text Hijack_BattleDataPtrSave.o temp_bin
od -An -t x1 temp_bin | ./binpatch $patched_arm9bin 50400

# geneate sin/cos table and patch to its location
dmd tableprinter.d
./tableprinter | ./binpatch $patched_arm9bin 5003C

# hijack palette load function to jump to Hijack_HueShift.s
echo 47 F0 10 F9 | ./binpatch $patched_arm9bin 9018

# hijack GetPkmnData to jump to Hijack_PersonalitySave.s
echo DB F7 C7 FE | ./binpatch $patched_arm9bin 74472 # GetPkmnData
echo DB F7 47 FE | ./binpatch $patched_arm9bin 74572 # GetBoxPkmnData

# hijack some pokedex routine to jump to Hijack_PersonalityClearPokedex.s
echo 28 F0 87 FE | ./binpatch $patched_arm9bin 2756E


echo 2C F6 B7 FD | ./binpatch $patched_overlay12bin 3B0E
echo 2E F6 FB FD | ./binpatch $patched_overlay12bin 1B06
echo 2C F6 B4 FE | ./binpatch $patched_overlay12bin 39F4
echo 4D F0 54 F9 | ./binpatch $patched_arm9bin 3034
echo 12 F6 27 FA | ./binpatch $patched_overlay16bin 2E6E

rm temp_bin