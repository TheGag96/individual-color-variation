.thumb

Hijack_WalkingPokemon: @ hook at overlay 1, 0x14BD6 (0x021FA4D6)
  push {lr}
  push {r0, r1, r2}

  @ r0 contains pointer to the BTX file that was just loaded
  @ r7 contains the subfile ID inside the narc file root/a/0/8/1 containing all the OW sprites

  @ skip this code if we did not just load a Pokemon OW sprite
  @ these bounds are the IDs of Pokemon OW sprites specifically
  ldr r1, =297
  cmp r7, r1
  blt .end
  ldr r1, =862
  cmp r7, r1
  bgt .end

  ldr r3, =0x023C81A4 @ location of "free ram" area

  @ do not continue if 0xF0110 was not set earlier
  ldr r2, [r3, #0x18]
  ldr r1, =0x000F0110
  cmp r2, r1
  bne .end

  @ reset flag used to look for 0xF0110
  mov r1, #0
  str r1, [r3, #0x18]

  ldr r2, =0x1180     @ offset of normal palette in BTX file
  add r0, r0, r2

  ldr r1, [r3, #0x20] @ contains personality value of last read pkmn data
  mov r2, #0          @ r1 contians the whole personality value, not just a hue shift table index.

  ldr r3, =0x023C8081 @ location of code from hueshift.c

  push {r0, r1, r2, r3}
  blx r3
  pop {r0, r1, r2, r3}

  add r0, r0, #0x20  @ run code on shiny palette also since Pokemon may be shiny
  blx r3

  .end:

  @ restore old code
  pop {r0, r1, r2}
  mov r2, r0
  ldr r3, [sp, #0x4]

  pop {pc}
