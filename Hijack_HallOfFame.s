.thumb

Hijack_HallOfFame: @ hook at overlay 86, 0xB18 (0x0223BC58), and overlay 87, 0xCA2 (0x021D1A22)
  push {lr}
  push {r0, r1, r2}

  @ set flag to 0xFA3E to be read down the callstack
  ldr r1, =0x020501E0 @ location of "free ram" area
  ldr r2, =0xFA3E
  str r2, [r1, #0x1C] 

  pop {r0, r1, r2}
  ldrh r0, [r0]
  ldrh r1, [r1, #4]

  pop {pc}
