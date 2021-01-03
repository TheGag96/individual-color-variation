#!/bin/bash

set -e

ow_sprites_narc=ow_sprites.narc
patched_ow_sprites_narc=ow_sprites_patched.narc
input_folder=./ShinyChanges/FollowPals

mkdir -p $input_folder

dmd followpal.d

cd PokEditor # PokeEditor doesn't work unless you run it from its containing directory

extracted_folder=$(basename -s .narc $ow_sprites_narc)
rm -rf extracted/$extracted_folder   # just in case - PokEditor will complain if it exists
rm -f  ../$patched_ow_sprites_narc # ditto
echo ../$ow_sprites_narc | java -jar PokEditor.jar narc unpack

# loop for all pokemon OW sprite narc IDs
for i in $(seq 297 862)
do
  # if whole btx was provided, use that. otherwise, patch just the palette using the txts
  if [[ -f "../$input_folder/$i.btx" ]]
  then
    cp "../$input_folder/$i.btx" "extracted/$extracted_folder/$i.bin"
  else
    ../followpal pack "extracted/$extracted_folder/$i.bin" "../$input_folder"
  fi
done

echo -e "$extracted_folder\n../$patched_ow_sprites_narc" | java -jar PokEditor.jar narc pack
rm -rf extracted/$extracted_folder

cd ../