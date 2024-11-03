.thumb

Hijack_PokewalkerStatus: @ hook at overlay 112, 0x39DE (0x021E92DE)
  push {lr}

  @ Store 0xB0C5 to be seen downstream of GfGfxLoader_GXLoadPal, in GfGfxLoader_GXLoadPalWithSrcOffsetInternal.
  @ The hue shift is actually performed by Hijack_BoxSprite2.s.
  ldr r0, =0x023C81A4 @ location of "free ram" area
  ldr r1, =0xB0C5
  str r1, [r0, #0x1C] 

  @ restore old code
  mov r1, #0x32
  mov r0, r5

  pop {pc}
