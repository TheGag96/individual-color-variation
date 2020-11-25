.thumb

Hijack_GbaPal: @ hook at 0x3034, insert at 0x502E0
  push {lr}
  push {r0, r1, r4}

  ldr r0, =0xBEEFBABE
  ldr r4, =0x020501F8 
  ldr r1, [r4, #4]

  @ do not continue if flag variable was not set to 0xBEEFBABE earlier up the call chain
  cmp r0, r1
  bne .1

  @ load palette pointer and personality value
  add r0, r2, #0
  ldr r1, [r4, #0]
  @ lsr r1, r1, #16

  @ call hue shifting code (from hueshift.c)
  push {r2, r3}
  ldr r3, =0x020500BD
  blx r3
  pop {r2, r3}

  @ reset the flag variable
  movs r0, #0
  str r0, [r4, #4]

.1:
  pop {r0, r1, r4}

  @restore old code
  ldrh r1, [r3, #0x1c]
  ldrh r3, [r3, #0x18]

  pop {pc} 

