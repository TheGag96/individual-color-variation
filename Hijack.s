.thumb

Hijack: @ hook at 0x9018, insert at 0x5023c
  ldr r0, [r0, #0x0C] @ pointer to palette
  ldr r1, =0x02050200 @ location of "free ram"
  ldr r1, [r1, #0]
  lsr r1, r1, #16
  push {r0, r2, lr}
  ldr r3, =0x020500BD @ location of code from hueshift.c
  blx r3
  pop {r1, r2, r3}    @ note that the saved r0 was pushed into r1, which effectively does what the hijacked code did
  ldr r0, [sp, #0x8]
  bx r3

@ 00 49 08 47 05 24 10 02


@ C0 68 04 21 05 B5 02 4B 98 47 0E BC 02 98 18 47 BC 00 05 02 41 13