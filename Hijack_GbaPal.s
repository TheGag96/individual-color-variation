.thumb

Hijack_GbaPal: @ hook at 0x31E4
  push {lr}
  push {r0, r1, r4}

  ldr r0, =0xBEEF
  ldr r4, =0x023C81A4 
  ldr r1, [r4, #0x1C]

  @ do not continue if flag variable was not set to 0xBEEF earlier up the call chain
  cmp r0, r1
  bne .1

  @ load palette pointer and personality value
  add r0, r2, #0
  ldr r1, [r4, #0x20]

  @ call hue shifting code (from hueshift.c)
  push {r2, r3}

  mov r2, #0  @ r1 contians the whole personality value, not just a hue shift table index.

  ldr r3, =0x023C8081
  blx r3
  pop {r2, r3}

  @ reset the flag variable
  movs r0, #0
  str r0, [r4, #0x1C]

.1:
  pop {r0, r1, r4}

  @restore old code
  ldrh r1, [r3, #0x1c]
  ldrh r3, [r3, #0x18]

  pop {pc} 

