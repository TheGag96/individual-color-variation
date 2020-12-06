.thumb

Hijack_BattleStart: @ hook at overlay 16, 0x42 (0x0223B182)          ------- 0x4 (0x0223B144)
  push {lr}
  push {r0, r1}

  ldr r0, =0x00BA771E
  ldr r1, =0x020501F8 @ location of in battle flag
  str r0, [r1]

  @ restore old code
  pop {r0, r1}
  mov r2, #0xB
  mov r0, #0x3

  pop {pc}
