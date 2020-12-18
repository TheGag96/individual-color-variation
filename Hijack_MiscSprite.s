.thumb

Hijack_MiscSprite: @ hook at 0x14480
  push {lr}

  ldr r0, [r0, #0x0C] @ pointer to palette
  push {r0, r1, r2}

  ldr r1, =0x023C81A4 @ location of "free ram" area
  ldr r1, [r1, #0x20] @ contains personality value of last read pkmn data

  ldr r2, =0x023C8081 @ location of code from hueshift.c
  blx r2

  @ restore old code (proper value already in r0)
  pop {r0, r1, r2}
  mov r2, #0x20

  pop {pc}
