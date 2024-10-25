.thumb

Hijack_LoadPal: @ hook at 0x795E, in GfGfxLoader_GXLoadPalWithSrcOffset
  push {r4, r5, lr}

  @ r1 should contain the "memberNo" parameter passed to this function, which has our hue shift index squirreled away in the uppermost byte.
  @ extract the hue shift index and remove it from the parameter
  lsr r5, r1, #24
  lsl r1, #8
  lsr r1, #8

  @ call GfGfxLoader_LoadFromNarc like the code was about to do
  ldr r4, =0x02007A45
  blx r4

  @ save return value of GfGfxLoader_LoadFromNarc!
  push {r0}

  @ r0 should contain a pointer to the NCLR file that just got loaded.

  @ skip hue shifting if the index was 0 anyway
  cmp r5, #0
  beq .end

  @ the actual palette data is just a bit ahead in the file.
  add r0, #0x28
  mov r1, r5
  mov r2, #1  @ r1 contians only a hue shift table index.

  ldr r4, =0x023C8081 @ location of code from hueshift.c
  blx r4

  .end:

  @ restore return value of GfGfxLoader_LoadFromNarc
  pop {r0}
  pop {r4, r5, pc}
