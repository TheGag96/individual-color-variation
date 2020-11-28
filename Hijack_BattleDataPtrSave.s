.thumb

Hijack_BattleDataPtrSave: @ hook at overlay 16, 0x2e6e (0x0223DFAE, GetMainBattleData_GetAdrOfPkmnInParty)
  push {lr}
  push {r0, r1}

  @ save off battle data context pointer so it can be easily retrieved later
  ldr r1, =0x020501E0
  str r0, [r1, #0x10]

  @ restore old code
  pop {r0, r1}
  add r5, r0, #0
  add r6, r2, #0

  pop {pc}
