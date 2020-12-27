#!/bin/bash

set -e

original_arm9bin=arm9_hg_vanilla.bin
patched_arm9bin=arm9_hg_patched.bin

original_overlay1bin=overlay1_hg_vanilla.bin
patched_overlay1bin=overlay1_hg_patched.bin

original_overlay7bin=overlay7_hg_vanilla.bin
patched_overlay7bin=overlay7_hg_patched.bin

original_overlay12bin=overlay12_hg_vanilla.bin
patched_overlay12bin=overlay12_hg_patched.bin

original_customoverlaynarc=custom_overlay_hg_vanilla.narc
patched_customoverlaynarc=custom_overlay_hg.narc
customoverlay_size=$((32*1024))

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
compile_asm Hijack_WalkingPokemon.s
compile_asm Hijack_WalkingPokemonDetect.s

# compile binary patch tool
dmd binpatch.d

# prepare patched output .bin file
cp $original_arm9bin $patched_arm9bin
cp $original_overlay1bin $patched_overlay1bin
cp $original_overlay7bin $patched_overlay7bin
cp $original_overlay12bin $patched_overlay12bin

# use Mikelan98's and Nomura's patches to load file a/0/2/8/0.nclr at startup, which can be used as a place for free code space
# see https://pokehacking.com/tutorials/ramexpansion/
echo FC B5 05 48 C0 46 1C 21 00 22 02 4D A8 47 00 20 03 21 FC BD 09 75 00 02 00 80 3C 02 | ./binpatch $patched_arm9bin 110334
echo 0F F1 30 FB | ./binpatch $patched_arm9bin CD0

# create blank file to put code into
fallocate -l $customoverlay_size tmp_custom_overlay

# extract compiled machine code and patch them to specific locations

function patch_code {
  eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text $1.o temp_bin
  od -An -t x1 temp_bin | ./binpatch tmp_custom_overlay $2
}

# patch custom overlay (code will load at these addresses + 0x023C8000)
patch_code Hijack_HueShift                200
patch_code hueshift                       80
patch_code Hijack_PersonalitySave         1C8
patch_code Hijack_BattleSprite            264
patch_code Hijack_GbaPal                  2A4
patch_code Hijack_BattleSprite2           2E4
patch_code Hijack_PersonalityTableBuild   344
patch_code Hijack_BattleDataPtrSave       3C4
patch_code Hijack_BattleStart             3E4
patch_code Hijack_BattleEnd               404
patch_code Hijack_BattleEndCaught         424
patch_code Hijack_PersonalityTableBuild2  444
patch_code Hijack_MiscSprite              4A4
patch_code Hijack_WalkingPokemon          4C4
patch_code Hijack_WalkingPokemonDetect    524

# geneate sin/cos table and patch to its location
dmd tableprinter.d
./tableprinter | ./binpatch tmp_custom_overlay 0

# put custom overlay file into the narc that will contain it
# this involves unpacking the vanilla narc file, putting in our file into the extracted folder, and repacking
cd PokEditor # PokeEditor doesn't work unless you run it from its containing directory
extracted_folder=$(basename -s .narc $original_customoverlaynarc)
rm -rf extracted/$extracted_folder   # just in case - PokEditor will complain if it exists
rm -f  ../$patched_customoverlaynarc # ditto
echo ../$original_customoverlaynarc | java -jar PokEditor.jar narc unpack
mv ../tmp_custom_overlay extracted/$extracted_folder/0.nclr
echo -e "$extracted_folder\n../$patched_customoverlaynarc" | java -jar PokEditor.jar narc pack
rm -rf extracted/$extracted_folder
cd ../

# hijack palette load function to jump to Hijack_HueShift.s
echo BE F3 30 FC | ./binpatch $patched_arm9bin 999C

# hijack GetPkmnData to jump to Hijack_PersonalitySave.s
echo 59 F3 41 FE | ./binpatch $patched_arm9bin 6E542 # GetPkmnData
echo 59 F3 C1 FD | ./binpatch $patched_arm9bin 6E642 # GetBoxPkmnData

# # hijack stuff related to in-battle GBA-styled sprites
echo A8 F1 4D FA | ./binpatch $patched_overlay7bin  3FA6 # Hijack_BattleSprite.s (on change sprite during switchout)
echo AA F1 7B FC | ./binpatch $patched_overlay7bin  1BCA # Hijack_BattleSprite2.s (on change sprite during move animation)
echo A8 F1 4A FB | ./binpatch $patched_overlay7bin  3E8C # Hijack_PersonalityTableBuild.s (on change sprite during switchout)
echo C5 F3 5E F8 | ./binpatch $patched_arm9bin      31E4 # Hijack_GbaPal.s (on any GBA-styled sprite palette load)
echo 8D F1 9F FD | ./binpatch $patched_overlay12bin 2FC2 # Hijack_BattleDataPtrSave.s (GetMainBattleData_GetAdrOfPkmnInParty)

# # hijack stuff needed to get in-battle normal sprites working
echo 90 F1 6F FD | ./binpatch $patched_overlay12bin 42   # Hijack_BattleStart.s
echo 90 F1 ED FC | ./binpatch $patched_overlay12bin 166  # Hijack_BattleEnd.s
echo 81 F1 68 FD | ./binpatch $patched_overlay12bin F090 # Hijack_BattleEndCaught.s
echo 8E F1 A2 F9 | ./binpatch $patched_overlay12bin 283C # Hijack_PersonalityTableBuild2.s

# hijack stuff needed to get misc sprite loads working (HM use, introduction)
echo B4 F3 10 F8 | ./binpatch $patched_arm9bin 14480 # Hijack_MiscSprite.s

# hijack stuff needed to hue shift walking/following Pokemon
echo CD F1 F5 FF | ./binpatch $patched_overlay1bin 14BD6 # Hijack_WalkingPokemon.s
echo E2 F1 3C F8 | ./binpatch $patched_overlay1bin BA8 #  11C0E # Hijack_WalkingPokemonDetect.s

rm temp_bin