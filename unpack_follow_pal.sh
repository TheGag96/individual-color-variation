#!/bin/bash

set -e

ow_sprites_narc=ow_sprites.narc
output_folder=./ShinyChanges/FollowPalsExtracted

mkdir -p $output_folder

dmd followpal.d

cd PokEditor # PokeEditor doesn't work unless you run it from its containing directory
extracted_folder=$(basename -s .narc $ow_sprites_narc)
rm -rf extracted/$extracted_folder   # just in case - PokEditor will complain if it exists
echo ../$ow_sprites_narc | java -jar PokEditor.jar narc unpack

for i in $(seq 471 1324)
do
  ../followpal unpack "extracted/$extracted_folder/$i.bin" "../$output_folder"
done

cd ../