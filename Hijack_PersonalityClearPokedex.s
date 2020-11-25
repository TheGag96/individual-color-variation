.thumb

Hijack_PersonalityClearPokedex: @ hook at 0x2756E, insert at 0x50280
  push {lr}
  push {r0, r1}

  ldr r1, =0x02050200 @ location of "free ram"
  movs r0, #0
  str r0, [r1, #0]

  @ restore old code
  pop {r0, r1}
  add r6, r0, #0
  add r5, r1, #0

  pop {pc}
