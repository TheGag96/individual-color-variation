.thumb

Hijack_PaletteUpload: @ hook at 0x73DA
  push {lr}

  ldr r1, [r0, #0x0C] @ pointer to palette
  push {r0, r1, r2, r3}

  mov r0, r1
  ldr r1, =0x020501E0 @ location of "free ram" area

  @ do not continue if 0xFA3E was not set earlier up the call stack
  ldr r3, [r1, #0x1C]
  ldr r2, =0xFA3E
  cmp r3, r2
  bne .end

  @ reset flag variable to require 0xFA3E to be set again
  mov r3, #0
  str r3, [r1, #0x1C]

  ldr r1, [r1, #0x20] @ contains personality value of last read pkmn data

  ldr r2, =0x020500BD @ location of code from hueshift.c
  blx r2

  .end:

  @ restore old code (proper value already in r0)
  pop {r0, r1, r2, r3}
  add r1, r1, r7

  pop {pc}
