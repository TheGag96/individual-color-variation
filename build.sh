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

original_overlay14bin=overlay14_hg_vanilla.bin
patched_overlay14bin=overlay14_hg_patched.bin

original_overlay63bin=overlay63_hg_vanilla.bin
patched_overlay63bin=overlay63_hg_patched.bin

original_overlay64bin=overlay64_hg_vanilla.bin
patched_overlay64bin=overlay64_hg_patched.bin

original_overlay74bin=overlay74_hg_vanilla.bin
patched_overlay74bin=overlay74_hg_patched.bin

original_overlay96bin=overlay96_hg_vanilla.bin
patched_overlay96bin=overlay96_hg_patched.bin

original_overlay97bin=overlay97_hg_vanilla.bin
patched_overlay97bin=overlay97_hg_patched.bin

original_overlay98bin=overlay98_hg_vanilla.bin
patched_overlay98bin=overlay98_hg_patched.bin

original_overlay112bin=overlay112_hg_vanilla.bin
patched_overlay112bin=overlay112_hg_patched.bin

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
compile_asm Hijack_BoxSprite1.s
compile_asm Hijack_BoxSprite2.s
compile_asm Hijack_HofRegisterSetup.s
compile_asm Hijack_LoadPal.s
compile_asm Hijack_HofViewSetup.s
compile_asm Hijack_Ov74Setup.s
compile_asm Hijack_Ov98Setup.s
compile_asm Hijack_Ov112.s
compile_asm Hijack_PersonalityStore.s
compile_asm Hijack_HofRegisterOw.s
compile_asm Hijack_HofViewOw.s

# compile binary patch and hijack branch maker tools
dmd binpatch.d
dmd makebl.d

# prepare patched output .bin files
cp $original_arm9bin $patched_arm9bin
cp $original_overlay1bin $patched_overlay1bin
cp $original_overlay7bin $patched_overlay7bin
cp $original_overlay12bin $patched_overlay12bin
cp $original_overlay14bin $patched_overlay14bin
cp $original_overlay63bin $patched_overlay63bin
cp $original_overlay64bin $patched_overlay64bin
cp $original_overlay74bin $patched_overlay74bin
cp $original_overlay96bin $patched_overlay96bin
cp $original_overlay97bin $patched_overlay97bin
cp $original_overlay98bin $patched_overlay98bin
cp $original_overlay112bin $patched_overlay112bin

# use Mikelan98's and Nomura's patches to load file a/0/2/8/0.nclr at startup, which can be used as a place for free code space
# see https://pokehacking.com/tutorials/ramexpansion/
echo FC B5 05 48 C0 46 1C 21 00 22 02 4D A8 47 00 20 03 21 FC BD 09 75 00 02 00 80 3C 02 | ./binpatch $patched_arm9bin 110334
echo 0F F1 30 FB | ./binpatch $patched_arm9bin CD0

# create blank file to put code into
# fallocate -l $customoverlay_size tmp_custom_overlay

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
patch_code Hijack_BoxSprite1              544
patch_code Hijack_BoxSprite2              564
patch_code Hijack_HofRegisterSetup        5A4
patch_code Hijack_LoadPal                 5C4
patch_code Hijack_HofViewSetup            5F4
patch_code Hijack_Ov74Setup               614
patch_code Hijack_Ov98Setup               634
patch_code Hijack_Ov112                   654
patch_code Hijack_PersonalityStore        674
patch_code Hijack_HofRegisterOw           684
patch_code Hijack_HofViewOw               6A4

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
cp ../tmp_custom_overlay extracted/$extracted_folder/0.nclr
echo -e "$extracted_folder\n../$patched_customoverlaynarc" | java -jar PokEditor.jar narc pack
rm -rf extracted/$extracted_folder
cd ../

# hijack palette load function to jump to Hijack_HueShift.s
./makebl 0200999C 023C8200 | ./binpatch $patched_arm9bin 999C

# hijack GetPkmnData to jump to Hijack_PersonalitySave.s
./makebl 0206E542 023C81C8 | ./binpatch $patched_arm9bin 6E542 # GetPkmnData
./makebl 0206E642 023C81C8 | ./binpatch $patched_arm9bin 6E642 # GetBoxPkmnData

# hijack stuff related to in-battle GBA-styled sprites
./makebl 0221FDC6 023C8264 | ./binpatch $patched_overlay7bin  3FA6 # Hijack_BattleSprite.s (on change sprite during switchout)
./makebl 0221D9EA 023C82E4 | ./binpatch $patched_overlay7bin  1BCA # Hijack_BattleSprite2.s (on change sprite during move animation)
./makebl 0221FCAC 023C8344 | ./binpatch $patched_overlay7bin  3E8C # Hijack_PersonalityTableBuild.s (on change sprite during switchout)
./makebl 020031E4 023C82A4 | ./binpatch $patched_arm9bin      31E4 # Hijack_GbaPal.s (on any GBA-styled sprite palette load)
./makebl 0223A882 023C83C4 | ./binpatch $patched_overlay12bin 2FC2 # Hijack_BattleDataPtrSave.s (GetMainBattleData_GetAdrOfPkmnInParty)

# hijack stuff needed to get in-battle normal sprites working
./makebl 02237902 023C83E4 | ./binpatch $patched_overlay12bin 42   # Hijack_BattleStart.s
./makebl 02237A26 023C8404 | ./binpatch $patched_overlay12bin 166  # Hijack_BattleEnd.s
./makebl 02246950 023C8424 | ./binpatch $patched_overlay12bin F090 # Hijack_BattleEndCaught.s
./makebl 0223A0FC 023C8444 | ./binpatch $patched_overlay12bin 283C # Hijack_PersonalityTableBuild2.s

# hijack stuff needed to get misc sprite loads working (HM use, introduction)
./makebl 02014480 023C84A4 | ./binpatch $patched_arm9bin 14480 # Hijack_MiscSprite.s

# hijack stuff needed to hue shift walking/following Pokemon
./makebl 021FA4D6 023C84C4 | ./binpatch $patched_overlay1bin 14BD6 # Hijack_WalkingPokemon.s
./makebl 021E64A8 023C8524 | ./binpatch $patched_overlay1bin BA8   # Hijack_WalkingPokemonDetect.s

# hijack stuff needed to get PC box sprites working
./makebl 021F36C2 023C8544 | ./binpatch $patched_overlay14bin DDC2 # Hijack_BoxSprite1.s (on pc box pokemon palette load)
./makebl 02007E96 023C8564 | ./binpatch $patched_arm9bin      7E96 # Hijack_BoxSprite2.s (general palette upload)

# hijack stuff needed to get Hall of Fame registration working
./makebl 020701F8 023C8674 | ./binpatch $patched_arm9bin      701F8 # Hijack_PersonalityStore.s (on determining pokemon sprite and palette)
./makebl 0207059E 023C8674 | ./binpatch $patched_arm9bin      7059E # Hijack_PersonalityStore.s (on determining pokemon sprite and palette)
./makebl 0221C942 023C85A4 | ./binpatch $patched_overlay63bin B22   # Hijack_HofRegisterSetup.s (on HoF register pokemon palette load)
./makebl 0221CC64 023C8684 | ./binpatch $patched_overlay63bin E44   # Hijack_HofRegisterOw.s (on HoF register pokemon OW sprite palette load)
./makebl 0200795E 023C85C4 | ./binpatch $patched_arm9bin      795E  # Hijack_LoadPal.s (on HoF register pokemon palette load)

# hijack stuff needed to get Hall of Fame viewing working
./makebl 021E6902 023C85F4 | ./binpatch $patched_overlay64bin 1002 # Hijack_HofViewSetup.s (on HoF pokemon palette load)
./makebl 021E6E04 023C86A4 | ./binpatch $patched_overlay64bin 1504 # Hijack_HofViewOw.s (on HoF view pokemon OW sprite palette load)

# unknown hijacks?
./makebl 02235BC0 023C8614 | ./binpatch $patched_overlay74bin  EB60  # Hijack_Ov74Setup.s
./makebl 0221E88A 023C8634 | ./binpatch $patched_overlay98bin  2CA   # Hijack_Ov98Setup.s
./makebl 021F0CF2 023C8654 | ./binpatch $patched_overlay112bin B3F2  # Hijack_Ov112.s (Pokewalker)
./makebl 0221FC42 023C8654 | ./binpatch $patched_overlay97bin  1682  # Hijack_Ov112.s

rm temp_bin