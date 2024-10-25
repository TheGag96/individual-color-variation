.thumb

Hijack_HofRegisterOw: @ hook at 0xE44, overlay 63 (0x0221CC64)
  push {lr}
  push {r0, r1, r2}

  @ Load personality value (hofMon->mon.box.pid)
  ldr r1, [sp, #0x1C]
  ldr r1, [r1, #0x0]
  ldr r1, [r1, #0x0]

  mov r2, #0  @ r1 contians the whole personality value, not just a hue shift table index.

  ldr r3, =0x023C8081 @ location of code from hueshift.c
  blx r3

  @ Restore old code
  pop {r0, r1, r2}
  mov r1, r4
  mov r2, #0x20

  pop {pc}

