.thumb

Hijack_WalkingPokemonDetect2: @ hook at Following Platinum sythetic overlay, 0x50 (0x023C8050), 0x1050 (0x023C9050), and 0x23A6 (0x023CA3A6)
  push {lr}
  push {r0, r1}

  ldr r1, =0x020501E0 @ location of in battle flag
  ldr r0, [r0, #0x0]
  str r0, [r1, #0x0]

  @ restore old code
  pop {r0, r1}
  mov r1, #5
  mov r2, #0

  pop {pc}
