.thumb

Hijack_WalkingPokemon: @ hook at overlay 5, 0x1D21E (0x021EDF9E) and 0x1D2DC (0x021EE05C)
  push {r4, lr}

  @ r1 contains the subfile ID inside the narc file root/data/mmodel/mmodel.narc containing all the OW sprites
  mov r4, r1

  ldr r3, =0x021EDCF5
  blx r3

  push {r0, r1, r2}

  @ r0 now contains pointer to the BTX file that was just loaded

  @ skip this code if we did not just load a Pokemon OW sprite
  @ these bounds are the IDs of Pokemon OW sprites specifically
  ldr r1, =471
  cmp r4, r1
  blt .end
  ldr r1, =1324
  cmp r4, r1
  bgt .end

  ldr r3, =0x020501E0 @ location of "free ram" area

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

  ldr r1, [r3, #0x0] @ contains personality value of last read pkmn data

  ldr r2, =0x020500BD @ location of code from hueshift.c

  push {r0, r1, r2, r3}
  blx r2
  pop {r0, r1, r2, r3}

  add r0, r0, #0x20  @ run code on shiny palette also since Pokemon may be shiny
  blx r2

  .end:

  @ restore old code
  pop {r0, r1, r2}

  pop {r4, pc}
