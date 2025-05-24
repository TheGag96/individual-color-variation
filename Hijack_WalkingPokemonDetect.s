.thumb

Hijack_WalkingPokemonDetect: @ hook at overlay 1, 0xBA8 (0x021E64A8)
  push {lr}
  push {r0, r1}

  ldr r0, =0x000F0110
  ldr r1, =0x023C8000 @ location of "free ram" area
  str r0, [r1, #0x18]

  @ restore old code
  pop {r0, r1}
  mov r1, #0x17
  mov r2, #0x4
  @mov r4, r0
  @ldrb r0, [r4, #0x17]

  pop {pc}
