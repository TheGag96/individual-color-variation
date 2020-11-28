.thumb

Hijack_PersonalityClearPokedex: @ hook at 0x2756E (runs on entering Pokedex)
  push {lr}
  push {r0, r1}

  ldr r1, =0x02050200 @ location of "free ram" containing personality of last read pkmn data
  movs r0, #0         @ clear it, since we do not want pokedex sprites to be shifted
  str r0, [r1, #0]

  @ restore old code
  pop {r0, r1}
  add r6, r0, #0
  add r5, r1, #0

  pop {pc}
