.thumb

Hijack_WalkingPokemonDetect: @ hook at overlay 5, 0xAFE (0x021D187E)
  push {lr}
  push {r0, r1}

  ldr r0, =0x000F0110
  ldr r1, =0x020501E0 @ location of in battle flag
  str r0, [r1, #0x18]

  @ restore old code
  pop {r0, r1}
  mov r1, #0x22
  mov r2, #0x4

  pop {pc}
