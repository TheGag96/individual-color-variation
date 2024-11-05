.thumb

Hijack: @ hook at 0x999C
  ldr r0, [r0, #0x0C] @ pointer to palette
  push {lr}
  push {r0-r3}

  ldr r2, [sp, #0x28]   @ contains current sprite index, i (0-3)
  mov r1, #0xAC         @ size of Pokepic struct

  @ r5 contains argument to PokepicManager_BufferPlttData, pokepicManager
  @ so, load pokepicManager->pics[i].template.personality
  @ luckily, Hijack_PersonalityStore makes sure this always filled!
  mul r1, r2
  add r1, r5, r1
  ldr r1, [r1, #0x10]

  mov r2, #0  @ r1 contians the whole personality value, not just a hue shift table index.

  ldr r3, =0x023C8081 @ location of code from hueshift.c
  blx r3

  @ restore old code
  pop {r0-r3}
  mov r1, r0
  ldr r0, [sp, #0xC]

  pop {pc}
