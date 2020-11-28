# Invidiually-Unique Pokémon Colors (+ Improved Shiny Colors) for Pokémon Platinum

This Platinum hack aims to make it so each individual Pokémon has a slight color variation based on its personality value. This is inspired by a [similar feature](https://guidesmedia.ign.com/guides/9846/images/pikacolors.jpg) from the Pokémon Stadium games that does just this but based on the Pokémon's nickname. The ROM hack [Pokémon Polished Crystal](https://github.com/Rangi42/polishedcrystal) implements a very similar feature based on IV values. This implementation performs a hue shift on the Pokémon's palette on load.


## Improved Shiny Colors

Some Pokémon have shiny colors that are very close to their non-shiny colors, or at least close enough that the simple hue shift performed by this hack may make a normal Pokémon look shiny. To remedy this, many Pokémon have been given revamped shiny colors. In additon, the opportunity has been taken to revamp Pokémon that seem to have obviously "bad" shiny palettes even if there's no ambiguity issue.

List of changed Pokémon (so far):

![Pichu](ShinyChanges/pichu_shiny.png) ![Pikachu](ShinyChanges/pikachu_shiny.png) ![Raichu](ShinyChanges/raichu_shiny.png)

**Pichu, Pikachu, Raichu** - Tried to make visually distinct instead of the slight orange tint. A bit of a gradient from pale yellow to pale orange throughout the evolutionary line.

![Nidoqueen](ShinyChanges/nidoqueen_shiny.png)

**Nidoqueen** - Colors made to look like Nidoking, which matches the pattern set by all other members of the Nidoran lines.

![Seel](ShinyChanges/seel_shiny.png) ![Dewgong](ShinyChanges/dewgong_shiny.png)

**Seel, Dewgong** - Made to look more visibly gold.

![Haunter](ShinyChanges/haunter_shiny.png) ![Gengar](ShinyChanges/gengar_shiny.png)

**Haunter, Gengar** - Tried to make a sensible gradient from Gastly to Mega Gengar (purple -> white with blue highlights).

![Scyther](ShinyChanges/scyther_shiny.png)

**Scyther** - Made to be red-orange, which makes shiny Scyther and Scizor effectively be a loose swap of their normal colors.

![Elekid](ShinyChanges/elekid_shiny.png) ![Electabuzz](ShinyChanges/electabuzz_shiny.png) ![Electivire](ShinyChanges/electivire_shiny.png)

**Elekid, Electabuzz, Electivire** - Light blue, with Elekid being slightly more Cyan. Electivire has gold tips.

![Articuno](ShinyChanges/articuno_shiny.png)

**Articuno** - Lavender.

![Zapdos](ShinyChanges/zapdos_shiny.png)

**Zapdos** - Brown.

![Espeon](ShinyChanges/espeon_shiny.png)

**Espeon** - Less overly saturated.

![Magcargo](ShinyChanges/magcargo_shiny.png)

**Magcargo** - Lava part matches shiny Slugma.

![Combusken](ShinyChanges/combusken_shiny.png)

**Combusken** - Changed to match the color change made in Sword/Shield.

![Piplup](ShinyChanges/piplup_shiny.png) ![Prinplup](ShinyChanges/prinplup_shiny.png) ![Empoleon](ShinyChanges/empoleon_shiny.png)

**Piplup, Prinplup, Empoleon** - Based off of [this post](https://imgur.com/t/shinypokemon/LMnl0Jx) from cjgart2000. Intended to give the "emporer penguin" look.

![Gabite](ShinyChanges/gabite_shiny.png) ![Garchomp](ShinyChanges/garchomp_shiny.png)

**Gabite, Garchomp** - Tried to make them consistent with shiny Gible (deeper blue, yellow/orange belly).

![Dusknoir](ShinyChanges/dusknoir_shiny.png)

**Dusknoir** - Red to match shiny Duskull and Dusclops.


## Building

1. Install [devkitARM](https://devkitpro.org/wiki/Getting_Started).
2. Install a [D compiler](https://dlang.org/download.html).
3. Use a program like Nitro Explorer 3 to extract `arm9.bin`, `overlay9-12.bin`, and `overlay9-16.bin` from your Platinum ROM.
4. Place them in the root folder of this repo, and name them to `arm9_vanilla.bin`, `overlay12_vanilla.bin`, and `overlay16_vanilla.bin`, respectively.
5. Run `./build.sh`.
6. Inject `arm9_patched.bin`, `overlay12_patched.bin`, and `overlay16_patched.bin` back into `arm9.bin`, `overlay9-12.bin`, and `overlay9-16.bin`, respectively.
7. Extract `pl_pokegra.narc`.
8. For each image in the `ShinyChanges` folder, insert that image to the proper place using "Pokemon Ds/Pic Platinum". (Note that some Pokémon might have changes to the base sprite.)
9. If you want to be really thorough, extract `pokegra.narc` and replace each changed palette entry (only the palette ones, not the image ones!).


## Credits

* [MKHT](https://twitter.com/mkht_real) - Lots of help choosing shiny colors.
* cjgart2000 - [This post](https://imgur.com/t/shinypokemon/LMnl0Jx) inspired some of the new shiny colors.