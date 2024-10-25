.thumb

Hijack_Ov74Setup: @ hook at overlay 74, 0xEB60 (0x02235BC0)
  ldr r0, [sp, #0x44]  @ \ u32 personality   = (*(PokepicTemplate**) (sp + 0x44))->personality;
  ldr r0, [r0, #0xC]   @ | u32 hueShiftIndex = (personality >> 16) & (64-1);
  lsr r0, #16          @ |
  mov r1, #63          @ |
  and r0, r1           @ /

  @ Sneak our hue shift index into the upper bits of the 2nd parameter to GfGfxLoader_GXLoadPal!
  ldrh r1, [r4, #4]  @ \ (part of hijacked code)
  lsl r0, #24        @ | memberNo = (hueShiftIndex << 24) | palDataID;
  orr r1, r0         @ /

  @ restore hijacked code
  ldrh r0, [r4, #0]

  bx lr
