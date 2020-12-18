.thumb

Hijack_BattleSprite: @ hook at overlay 7, 0x3FA6 (0x0221FDC6)
  push {lr}
  push {r0, r1}

  ldr r0, =0xBEEF0000
  ldr r1, [sp, #0x38] @ loop variable
  add r1, r1, r0
  ldr r0, =0x023C81C0 @ this spot will be read by routine that loads palette
  str r1, [r0]

  @ restore old code
  pop {r0, r1}
  movs r1, #0x20
  lsl r0, r0, #0x14

  pop {pc} 

