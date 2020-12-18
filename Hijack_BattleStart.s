.thumb

Hijack_BattleStart: @ hook at overlay 12, 0x42 (0x02237902)
  push {lr}
  push {r0, r1}

  ldr r0, =0x00BA771E
  ldr r1, =0x023C81BC @ location of in battle flag
  str r0, [r1]

  @ restore old code
  pop {r0, r1}
  mov r2, #0xB
  mov r0, #0x3

  pop {pc}
