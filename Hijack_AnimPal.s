.thumb

Hijack_AnimPal: @ hook at 0xCCD8

  @ old code branched away if r0 was null - preserve that
  cmp r0, #0   
  beq .cancel

  push {lr}
  push {r0, r1, r2, r3}

  mov r0, r1          @ contains pointer to palette
  ldr r1, =0x020501E0 @ location of "free ram" area

  @ do not continue if 0x0E66 was not set earlier up the call stack
  ldr r3, [r1, #0x1C]
  ldr r2, =0x0E66
  cmp r3, r2
  bne .end

  @ reset flag variable to require 0x0E66 to be set again
  mov r3, #0
  str r3, [r1, #0x1C]

  ldr r1, [r1, #0x20] @ contains personality value of last read pkmn data

  ldr r2, =0x020500BD @ location of code from hueshift.c
  blx r2

  .end:

  @ restore old code (proper value already in r0)
  pop {r0, r1, r2, r3}
  mov r5, r0

  pop {pc}

  .cancel:

  mov r5, r0           @ restore this code just in case?
  ldr r0, =0x0200CD01  @ right before call to ErrorHandling
  bx r0
