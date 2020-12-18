.thumb

Hijack_BattleSprite2: @ hook at overlay 7, 0x1BCA (0x0221D9EA)
  push {lr}
  push {r0, r1}

  ldr r1, =0xBEEF0000
  ldr r0, [sp, #0x28]
  add r1, r1, r0
  ldr r0, =0x023C81C0 @ this spot will be read by routine that loads palette
  str r1, [r0]

  @ restore old code
  pop {r0, r1}
  add r0, #0xc8
  ldr r0, [r0, #0]

  pop {pc} 

