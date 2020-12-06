.thumb

Hijack_BattleEndCaught: @ hook at overlay 16, 0xEDE0 (0x02249F20)
  push {lr}
  push {r0, r1}

  mov r0, #0
  ldr r1, =0x020501F8 @ location of in battle flag
  str r0, [r1]

  @ restore old code
  pop {r0, r1}
  add r0, r6, #0
  mov r1, #0x5

  pop {pc}
