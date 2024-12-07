#!/bin/bash

set -e

original_arm9bin=arm9_vanilla.bin
patched_arm9bin=arm9_patched.bin

original_overlay5bin=overlay5_vanilla.bin
patched_overlay5bin=overlay5_patched.bin

original_overlay12bin=overlay12_vanilla.bin
patched_overlay12bin=overlay12_patched.bin

original_overlay16bin=overlay16_vanilla.bin
patched_overlay16bin=overlay16_patched.bin

original_overlay86bin=overlay86_vanilla.bin
patched_overlay86bin=overlay86_patched.bin

original_overlay87bin=overlay87_vanilla.bin
patched_overlay87bin=overlay87_patched.bin

original_overlay119bin=overlay119_vanilla.bin
patched_overlay119bin=overlay119_patched.bin

original_weathersys065bin=weather_sys_065_vanilla.bin
patched_weathersys065bin=weather_sys_065_patched.bin

# compile asm and C files
function compile_c {
  eval $DEVKITARM/bin/arm-none-eabi-gcc -Wall -Os -march=armv5te -mtune=arm946e-s -fomit-frame-pointer -ffast-math \
    -mthumb -mthumb-interwork "-I$DEVKITPRO/libnds/include" "-I$DEVKITPRO/calico/include" -D__NDS__ -DARM9 \
    -c $1 -o $(basename $1 .c).o
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
compile_asm Hijack_HallOfFame.s
compile_asm Hijack_PaletteUpload.s
compile_asm Hijack_EggHatching.s
compile_asm Hijack_AnimPal.s
compile_asm Hijack_WalkingPokemon.s
compile_asm Hijack_WalkingPokemonDetect.s
compile_asm Hijack_WalkingPokemonDetect2.s

# compile binary patch tool and hijack branch maker tools
dmd binpatch.d
dmd makebl.d

# prepare patched output .bin file
cp $original_arm9bin           $patched_arm9bin
cp $original_overlay5bin       $patched_overlay5bin
cp $original_overlay12bin      $patched_overlay12bin
cp $original_overlay16bin      $patched_overlay16bin
cp $original_overlay86bin      $patched_overlay86bin
cp $original_overlay87bin      $patched_overlay87bin
cp $original_overlay119bin     $patched_overlay119bin
cp $original_weathersys065bin  $patched_weathersys065bin

# extract compiled machine code and patch them to specific locations

function patch_code {
  eval $DEVKITARM/bin/arm-none-eabi-objcopy -O binary -j .text $1.o temp_bin
  od -An -t x1 temp_bin | ./binpatch $2 $3
}

patch_code Hijack_HueShift                $patched_arm9bin          5023C
patch_code hueshift                       $patched_arm9bin          500BC
patch_code Hijack_PersonalitySave         $patched_arm9bin          50204
patch_code Hijack_PersonalityClearPokedex $patched_arm9bin          50280
patch_code Hijack_BattleSprite            $patched_arm9bin          502A0
patch_code Hijack_GbaPal                  $patched_arm9bin          502E0
patch_code Hijack_BattleSprite2           $patched_arm9bin          50320
patch_code Hijack_PersonalityTableBuild   $patched_arm9bin          50380
patch_code Hijack_BattleDataPtrSave       $patched_arm9bin          50400
patch_code Hijack_BattleStart             $patched_arm9bin          50420
patch_code Hijack_BattleEnd               $patched_arm9bin          50440
patch_code Hijack_BattleEndCaught         $patched_arm9bin          50460
patch_code Hijack_PersonalityTableBuild2  $patched_arm9bin          50480
patch_code Hijack_MiscSprite              $patched_arm9bin          504E0
patch_code Hijack_HallOfFame              $patched_arm9bin          50500
patch_code Hijack_PaletteUpload           $patched_arm9bin          50520
patch_code Hijack_EggHatching             $patched_arm9bin          50550
patch_code Hijack_AnimPal                 $patched_arm9bin          50570
patch_code Hijack_WalkingPokemon          $patched_weathersys065bin 14200
patch_code Hijack_WalkingPokemonDetect    $patched_weathersys065bin 14260
patch_code Hijack_WalkingPokemonDetect2   $patched_weathersys065bin 14280

# geneate sin/cos table and patch to its location
dmd tableprinter.d
./tableprinter | ./binpatch $patched_arm9bin 5003C

# hijack palette load function to jump to Hijack_HueShift.s
./makebl 9018 5023C | ./binpatch $patched_arm9bin 9018

# hijack GetPkmnData to jump to Hijack_PersonalitySave.s
./makebl 74472 50204 | ./binpatch $patched_arm9bin 74472
./makebl 74572 50204 | ./binpatch $patched_arm9bin 74572

# hijack some pokedex routine to jump to Hijack_PersonalityClearPokedex.s
./makebl 2756E 50280 | ./binpatch $patched_arm9bin 2756E

# hijack stuff related to in-battle GBA-styled sprites
./makebl 0222372E 020502A0 | ./binpatch $patched_overlay12bin 3B0E # Hijack_BattleSprite.s (on change sprite during switchout)
./makebl 02221726 02050320 | ./binpatch $patched_overlay12bin 1B06 # Hijack_BattleSprite2.s (on change sprite during move animation)
./makebl 02223614 02050380 | ./binpatch $patched_overlay12bin 39F4 # Hijack_PersonalityTableBuild.s (on change sprite during switchout)
./makebl 02003034 020502E0 | ./binpatch $patched_arm9bin      3034 # Hijack_GbaPal.s (on any GBA-styled sprite palette load)
./makebl 0223DFAE 02050400 | ./binpatch $patched_overlay16bin 2E6E # Hijack_BattleDataPtrSave.s (GetMainBattleData_GetAdrOfPkmnInParty)

# hijack stuff needed to get in-battle normal sprites working
./makebl 0223B182 02050420 | ./binpatch $patched_overlay16bin 42   # Hijack_BattleStart.s
./makebl 0223B294 02050440 | ./binpatch $patched_overlay16bin 154  # Hijack_BattleEnd.s
./makebl 02249F20 02050460 | ./binpatch $patched_overlay16bin EDE0 # Hijack_BattleEndCaught.s
./makebl 0223D828 02050480 | ./binpatch $patched_overlay16bin 26E8 # Hijack_PersonalityTableBuild2.s

# hijack stuff needed to get misc sprite loads working (HM use, introduction)
./makebl 02013690 020504E0 | ./binpatch $patched_arm9bin 13690 # Hijack_MiscSprite.s

# hijack stuff needed to get hall of fame sprites working
./makebl 0223BC58 02050500 | ./binpatch $patched_overlay86bin B18  # Hijack_HallOfFame.s (viewing in actual HoF)
./makebl 021D1A22 02050500 | ./binpatch $patched_overlay87bin CA2  # Hijack_HallOfFame.s (viewing in PC)
./makebl 020073DA 02050520 | ./binpatch $patched_arm9bin      73DA # Hijack_PaletteUpload.s

# hijack stuff needed to get the egg hatching animation working
./makebl 021D1564 02050550 | ./binpatch $patched_overlay119bin 7E4  # Hijack_EggHatching.s 
./makebl 0200CCD8 02050570 | ./binpatch $patched_arm9bin       CCD8 # Hijack_AnimPal.s

# hijack stuff needed to hue shift walking/following Pokemon
./makebl 021EDF9E 023DC200 | ./binpatch $patched_overlay5bin      1D21E # Hijack_WalkingPokmemon.s
./makebl 021EE05C 023DC200 | ./binpatch $patched_overlay5bin      1D2DC # Hijack_WalkingPokmemon.s
./makebl 021D187E 023DC260 | ./binpatch $patched_overlay5bin      AFE   # Hijack_WalkingPokmemonDetect.s
./makebl 023C8050 023DC280 | ./binpatch $patched_weathersys065bin 50    # Hijack_WalkingPokmemonDetect2.s
./makebl 023C9050 023DC280 | ./binpatch $patched_weathersys065bin 1050  # Hijack_WalkingPokmemonDetect2.s
./makebl 023CA3A6 023DC280 | ./binpatch $patched_weathersys065bin 23A6  # Hijack_WalkingPokmemonDetect2.s

rm temp_bin