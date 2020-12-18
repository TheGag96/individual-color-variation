.thumb

Hijack_BattleEndCaught: @ hook at overlay 12, 0xF090 (0x02246950)
  push {lr}
  push {r0, r1}

  mov r0, #0
  ldr r1, =0x023C81BC @ location of in battle flag
  str r0, [r1]

  @ restore old code
  pop {r0, r1}
  add r0, r6, #0
  mov r1, #0x5

  pop {pc}
