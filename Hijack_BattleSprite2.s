.thumb

Hijack_BattleSprite2: @ hook at overlay 12, 0x1B06 (0x0221726)
  push {lr}
  push {r0, r1}

  ldr r1, =0xBEEF0000
  add r1, r1, r7
  ldr r0, =0x020501FC @ this spot will be read by routine that loads palette
  str r1, [r0]

  @ restore old code
  pop {r0, r1}
  add r0, #0xc8
  ldr r0, [r0, #0]

  pop {pc} 

