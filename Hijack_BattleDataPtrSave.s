.thumb

Hijack_BattleDataPtrSave: @ hook at overlay 16, 0x2e6e, insert at 0x
  push {lr}
  push {r0, r1}

  ldr r1, =0x020501E0
  str r0, [r1, #0x10]

  @ restore old code
  pop {r0, r1}
  add r5, r0, #0
  add r6, r2, #0

  pop {pc}
