.thumb

Hijack_PersonalityTableBuild2: @ hook at overlay 16, 0x26E8 (0x0223D828)
  .start:

  push {lr}
  push {r0-r7}

  ldr r3, =0x020501E0 @ table of active personality values (and also cached battle data ptr)

  mov r5, #0          @ loop variable

  ldr r6, [r4, #0x30] @ load other battle data ptr??
  ldr r2, =0x219C
  add r6, r6, r2      @ r6 now contains pointer to active battle member array

  ldr r7, =0x0223DFAD @ GetMainBattleData_GetAdrOfPkmnInParty

  .loop:

  mov r0, r4

  @ the table appears to be in this format:
  @ [<active friendly mon 1>, <active enemy mon 1>, <active friendly mon 2>, <active enemy mon 2>]
  @ whose party these pokemon come from can depend on whether you are in a single battle, double battle, double with partner, etc.

  @ get pokemon-in-party index from active party member table
  ldrb r2, [r6, r5]

  @ load loop variable as party index
  @ note about the party index:
  @ 0 and 2 are either the player or partner pokemon, and 1 and 3 are enemy trainer(s).
  @ in a single battle, the party ID of the enemy trainer is 1. in a double battle, it is either 2 or 3 depending on
  @ whether the player is facing one or two trainers.
  @ luckily, if the player is by himself in a double battle, party 2 just maps to party 0, so it is safe to just go
  @ ahead and use the loop variable as the party ID (same goes for one-trainer vs two-trainer double battles with 1 and 3).

  mov r1, r5

  push {r3}
  blx r7
  pop {r3}

  @ store personality value in our table
  ldr r0, [r0]
  lsl r1, r5, #2
  str r0, [r3, r1]

  add r5, r5, #1
  cmp r5, #4
  bls .loop

  .end:

  @ restore old code
  pop {r0-r7}
  ldr r0, [r4, #0x2C]
  mov r1, #0x4

  pop {pc} 

