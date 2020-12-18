.thumb

Hijack_BattleEnd: @ hook at overlay 12, 0x166 (0x02237A26)
  push {lr}
  push {r0, r1}

  mov r0, #0
  ldr r1, =0x023C81BC @ location of in battle flag
  str r0, [r1]

  @ restore old code
  pop {r0, r1}
  mov r0, #0xA
  str r0, [r4]

  pop {pc}
