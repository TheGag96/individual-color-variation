.thumb

Hijack_PersonalitySave: @ hook at 0x74472 and 0x74572
  push {lr}
  push {r0, r1}


  ldr r1, =0x02050200 @ location of "free ram"
  ldr r0, [r0, #0]
  str r0, [r1, #0]

  @ restore old code
  pop {r0, r1}
  add r5, r0, #0
  ldrh r0, [r5, #4]

  pop {pc}
