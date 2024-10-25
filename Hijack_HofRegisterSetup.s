.thumb

Hijack_HofRegisterSetup: @ hook at overlay 63, 0xB22 (0x0221C942), in RegisterHallOfFame_IndivMonsScene_SetPicGfxAndPltt
  ldr r2, [sp, #20]  @ \ u32 personality   = ((PokepicTemplate*) (sp + 8))->personality;
  lsr r2, #16        @ | u32 hueShiftIndex = (personality >> 16) & (64-1);
  push {r0}          @ |
  mov r0, #63        @ |
  and r2, r0         @ |
  pop {r0}           @ /

  @ Sneak our hue shift index into the upper bits of the 2nd parameter to GfGfxLoader_GXLoadPal!
  ldrh r1, [r1, #4]  @ hijacked code
  lsl r2, #24        @ \ memberNo = (hueShiftIndex << 24) | palDataID;
  orr r1, r2         @ /

  @ restore hijacked code
  mov r2, #1

  bx lr
