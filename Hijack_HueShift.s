.thumb

Hijack: @ hook at 0x9018
  ldr r0, [r0, #0x0C] @ pointer to palette
  push {r0, r2, lr}

  ldr r1, =0x020501E0 @ location of "free ram" area
  ldr r2, [r1, #0x18]
  ldr r3, =0x00BA771E
  cmp r2, r3
  beq .battle

  .typical:

  ldr r1, [r1, #0x20]   @ contains personality value of last read pkmn data
  b .shift

  .battle:

  ldr r2, [sp, #0x20]   @ contains current battle sprite index (0-3)
  lsl r2, r2, #2
  ldr r1, [r1, r2]      @ index into previously-built active pokemon personality table

  .shift:

  ldr r3, =0x020500BD @ location of code from hueshift.c
  blx r3

  pop {r1, r2, r3}    @ note that the saved r0 was pushed into r1, which effectively does what the hijacked code did
  ldr r0, [sp, #0x8]

  bx r3

@ 00 49 08 47 05 24 10 02


@ C0 68 04 21 05 B5 02 4B 98 47 0E BC 02 98 18 47 BC 00 05 02 41 13
