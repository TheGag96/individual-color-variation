.thumb

Hijack_Ov112: @ hook at overlay 112 @ 0xB3F2 (0x021F0CF2), overlay 97 @ 0x1682 (0x0221FC42)
  push {r4, r5, lr}
  push {r0, r1, r2}

  @ r0 contains a pointer to the palette

  @ grab personality value
  ldr r1, [sp, #0x38]  @ u32 personality   = ((PokepicTemplate*) (oldSp + 0x14))->personality;

  mov r2, #0  @ r1 contians the whole personality value, not just a hue shift table index.

  ldr r3, =0x023C8081 @ location of code from hueshift.c
  blx r3

  @ restore old code
  pop {r0, r1, r2}
  add r1, r4, r1
  mov r2, #0x20

  pop {r4, r5, pc}
