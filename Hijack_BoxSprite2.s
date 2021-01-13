.thumb

Hijack_BoxSprite2: @ hook at 0x7E96
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

  ldr r2, =0x023C8081 @ location of code from hueshift.c
  blx r2

  .end:

  @ restore old code (proper value already in r0)
  pop {r0, r1, r2, r3}
  ldr r3, [r3, r4]

  pop {pc}
