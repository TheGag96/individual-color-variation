.thumb

Hijack_BoxSprite1: @ hook at overlay 14, 0xDDC2 (0x021F36C2)
  push {lr}
  push {r0, r1, r2}

  @ Store 0xB0C5 to be seen downstream of GfGfxLoader_GXLoadPal, in GfGfxLoader_GXLoadPalWithSrcOffsetInternal.
  @ The hue shift is actually performed by Hijack_BoxSprite2.s.
  ldr r1, =0x023C81A4 @ location of "free ram" area
  ldr r2, =0xB0C5
  str r2, [r1, #0x1C] 

  pop {r0, r1, r2}
  ldrh r1, [r1, #0x14]
  mov r2, #5

  pop {pc}