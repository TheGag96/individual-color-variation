.thumb

Hijack_BattleSprite: @ hook at overlay 7, 0x3FA6 (0x0221FDC6)
  push {lr}
  push {r0, r1}

  @ r5 contains a pointer to a Pokepic
  @ so, load pokepic->template.personality
  @ luckily, Hijack_PersonalityStore makes sure this always filled!
  ldr r1, [r5, #0x10]

  ldr r0, =0x023C81A4 @ location of "free ram" area
  str r1, [r0, #0x20] @ contains last-cached personality value

  @ set flag to be read later by Hijack_GbaPal.s
  ldr r1, =0xBEEF
  str r1, [r0, #0x1C]

  @ restore old code
  pop {r0, r1}
  movs r1, #0x20
  lsl r0, r0, #0x14

  pop {pc} 

