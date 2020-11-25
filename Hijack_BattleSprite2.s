.thumb

Hijack_BattleSprite2: @ hook at overlay 12, 0x1B06, insert at 0x50320
  push {lr}
  push {r0, r1}

  ldr r0, =0xBEEFBABE
  ldr r1, =0x020501FC @ this spot will be read by routine that loads palette
  str r0, [r1, #0]

  @ restore old code
  pop {r0, r1}
  add r0, #0xc8
  ldr r0, [r0, #0]

  pop {pc} 

