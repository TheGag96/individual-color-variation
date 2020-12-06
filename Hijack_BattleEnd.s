.thumb

Hijack_BattleEnd: @ hook at overlay 16, 0x154 (0x0223B294)
  push {lr}
  push {r0, r1}

  mov r0, #0
  ldr r1, =0x020501F8 @ location of in battle flag
  str r0, [r1]

  @ restore old code
  pop {r0, r1}
  mov r0, #0xA
  str r0, [r4]

  pop {pc}
