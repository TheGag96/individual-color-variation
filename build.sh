#!/bin/bash

set -e

original_arm9bin=arm9_vanilla.bin
patched_arm9bin=arm9_patched.bin

original_overlay12bin=overlay12_vanilla.bin
patched_overlay12bin=overlay12_patched.bin

original_overlay16bin=overlay16_vanilla.bin
patched_overlay16bin=overlay16_patched.bin

# compile asm and C files
function compile_c {
  eval $DEVKITARM/bin/arm-none-eabi-gcc -Wall -Os -march=armv5te -mtune=arm946e-s -fomit-frame-pointer -ffast-math -mthumb -mthumb-interwork -I/opt/devkitpro/libnds/include -DARM9 -c $1 -o $(basename $1 .c).o
}

function compile_asm {
  eval $DEVKITARM/bin/arm-none-eabi-as -march=armv5te -mthumb -mthumb-interwork -c $1 -o $(basename $1 .s).o
}

compile_c   hueshift.c
compile_asm Hijack_HueShift.s
compile_asm Hijack_PersonalitySave.s
compile_asm Hijack_PersonalityClearPokedex.s
compile_asm Hijack_BattleSprite.s
compile_asm Hijack_BattleSprite2.s
compile_asm Hijack_PersonalityTableBuild.s
compile_asm Hijack_PersonalityTableBuild2.s
compile_asm Hijack_GbaPal.s
compile_asm Hijack_BattleDataPtrSave.s
compile_asm Hijack_BattleStart.s
compile_asm Hijack_BattleEnd.s
compile_asm Hijack_BattleEndCaught.s
compile_asm Hijack_MiscSprite.s

# compile binary patch tool
dmd binpatch.d

# prepare patched output .bin file
cp $original_arm9bin $patched_arm9bin
cp $original_overlay12bin $patched_overlay12bin
cp $original_overlay16bin $patched_overlay16bin

# extract compiled machine code and patch them to specific locations

function patch_code {
  eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text $1.o temp_bin
  od -An -t x1 temp_bin | ./binpatch $patched_arm9bin $2
}

patch_code Hijack_HueShift                5023C
patch_code hueshift                       500BC
patch_code Hijack_PersonalitySave         50204
patch_code Hijack_PersonalityClearPokedex 50280
patch_code Hijack_BattleSprite            502A0
patch_code Hijack_GbaPal                  502E0
patch_code Hijack_BattleSprite2           50320
patch_code Hijack_PersonalityTableBuild   50380
patch_code Hijack_BattleDataPtrSave       50400
patch_code Hijack_BattleStart             50420
patch_code Hijack_BattleEnd               50440
patch_code Hijack_BattleEndCaught         50460
patch_code Hijack_PersonalityTableBuild2  50480
patch_code Hijack_MiscSprite              504E0

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

# hijack stuff related to in-battle GBA-styled sprites
echo 2C F6 B7 FD | ./binpatch $patched_overlay12bin 3B0E # Hijack_BattleSprite.s (on change sprite during switchout)
echo 2E F6 FB FD | ./binpatch $patched_overlay12bin 1B06 # Hijack_BattleSprite2.s (on change sprite during move animation)
echo 2C F6 B4 FE | ./binpatch $patched_overlay12bin 39F4 # Hijack_PersonalityTableBuild.s (on change sprite during switchout)
echo 4D F0 54 F9 | ./binpatch $patched_arm9bin      3034 # Hijack_GbaPal.s (on any GBA-styled sprite palette load)
echo 12 F6 27 FA | ./binpatch $patched_overlay16bin 2E6E # Hijack_BattleDataPtrSave.s (GetMainBattleData_GetAdrOfPkmnInParty)

# hijack stuff needed to get in-battle normal sprites working
echo 15 F6 4D F9 | ./binpatch $patched_overlay16bin 42   # Hijack_BattleStart.s
echo 15 F6 D4 F8 | ./binpatch $patched_overlay16bin 154  # Hijack_BattleEnd.s
echo 06 F6 9E FA | ./binpatch $patched_overlay16bin EDE0 # Hijack_BattleEndCaught.s
echo 12 F6 2A FE | ./binpatch $patched_overlay16bin 26E8 # Hijack_PersonalityTableBuild2.s

# hijack stuff needed to get misc sprite loads working (HM use, introduction)
echo 3C F0 26 FF | ./binpatch $patched_arm9bin 13690 # Hijack_MiscSprite.s

rm temp_bin