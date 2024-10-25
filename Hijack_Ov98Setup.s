.thumb

Hijack_Ov98Setup1: @ hook at overlay 98, 0x2CA (0x0221E88A)
  ldr r3, [sp, #0x34]  @ \ u32 personality   = ((PokepicTemplate*) (sp + 0x28))->personality;
  lsr r3, #16          @ | 
  mov r0, #63          @ |
  and r3, r0           @ /

  @ Sneak our hue shift index into the upper bits of the 3rd parameter to this function!
  lsl r3, #24        @ \ u32 palDataId = (hueShiftIndex << 24) | r2;
  orr r2, r3         @ /

  @ restore hijacked code
  ldr r3, [sp, #0x14]
  mov r0, r5

  bx lr
