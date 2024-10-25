.thumb

Hijack_HofViewSetup: @ hook at overlay 64, 0x1002 (0x021E6902)
  ldrh r1, [r1, #0x18]  @ hijacked code

  ldr r2, [sp, #0x5C]  @ \ u32 personality   = ((PokepicTemplate*) (sp + 0x50))->personality;
  lsr r2, #16          @ | u32 hueShiftIndex = (personality >> 16) & (64-1);
  push {r0}            @ |
  mov r0, #63          @ |
  and r2, r0           @ |
  pop {r0}             @ /

  @ Sneak our hue shift index into the upper bits of the 2nd parameter to GfGfxLoader_GXLoadPal!
  lsl r2, #24        @ \ GFPalLoadLocation location = (hueShiftIndex << 24) | palDataID;
  orr r1, r2         @ /

  @ restore hijacked code
  mov r2, #5

  bx lr
