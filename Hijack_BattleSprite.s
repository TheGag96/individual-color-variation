.thumb

Hijack_BattleSprite: @ hook at overlay 12, 0x3B0E, insert at 0x502A0
  push {lr}
  push {r0, r1}

  ldr r0, =0xBEEFBABE
  ldr r1, =0x020501FC @ this spot will be read by routine that loads palette
  str r0, [r1, #0]

  @ restore old code
  pop {r0, r1}
  movs r1, #0x20
  lsl r0, r0, #0x14

  pop {pc} 

