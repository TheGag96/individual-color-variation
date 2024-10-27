.thumb

Hijack_BoxSprite2: @ hook at 0x7E00
  push {lr}

  ldr r0, [r0, #0x0C] @ pointer to palette
  push {r0, r1, r2, r3}

  ldr r1, =0x023C81A4 @ location of "free ram" area

  @ stop if 0xB0C5 was not set up the chain (loading sprite viewing the pc box)
  ldr r2, [r1, #0x1C]
  ldr r3, =0xB0C5
  cmp r2, r3
  bne .end

  @ clear box flag
  mov r3, #0
  str r3, [r1, #0x1C]

  ldr r1, [r1, #0x20] @ contains personality value of last read pkmn data
  mov r2, #0          @ r1 contians the whole personality value, not just a hue shift table index.

  ldr r3, =0x023C8081 @ location of code from hueshift.c
  blx r3

  .end:

  @ restore old code (proper value already in r0)
  pop {r0, r1, r2, r3}
  mov r1, r5

  pop {pc}
