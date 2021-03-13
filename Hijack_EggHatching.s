.thumb

Hijack_EggHatching: @ hook at overlay 119, 0x7E4 (0x021D1564)
  push {lr}
  push {r0, r1, r2}

  @ set flag to 0x0E66 to be read down the callstack
  ldr r1, =0x020501E0 @ location of "free ram" area
  ldr r2, =0x0E66
  str r2, [r1, #0x1C] 

  pop {r0, r1, r2}
  mov r0, r6
  mov r3, r5

  pop {pc}
