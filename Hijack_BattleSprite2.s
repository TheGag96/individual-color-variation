.thumb

Hijack_BattleSprite2: @ hook at overlay 7, 0x1BCA (0x0221D9EA)
  push {lr}
  push {r0, r1}

  @ r6 contains a pointer to a Pokepic
  @ so, load pokepic->template.personality
  @ luckily, Hijack_PersonalityStore makes sure this always filled!
  ldr r1, [r6, #0x10]

  ldr r0, =0x023C81A4 @ location of "free ram" area
  str r1, [r0, #0x20] @ contains last-cached personality value

  @ set flag to be read later by Hijack_GbaPal.s
  ldr r1, =0xBEEF
  str r1, [r0, #0x1C]

  @ restore old code
  pop {r0, r1}
  add r0, #0xc8
  ldr r0, [r0, #0]

  pop {pc} 

