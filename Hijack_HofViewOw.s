.thumb

Hijack_HofViewOw: @ hook at 0x1504, overlay 64 (0x021E6E04)
  push {lr}
  push {r0, r1, r2}

  @ Load personality value (hofMon->mon.box.pid)
  ldr r1, =400
  ldr r1, [r5, r1]

  mov r2, #0  @ r1 contians the whole personality value, not just a hue shift table index.

  ldr r3, =0x023C8081 @ location of code from hueshift.c
  blx r3

  @ Restore old code
  pop {r0, r1, r2}
  mov r1, r6
  mov r2, #0x20

  pop {pc}

