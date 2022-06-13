.thumb

Hijack_PersonalityTableBuild: @ hook at overlay 12, 0x39F4 (0x02223614)
  .start:

  push {lr}
  push {r0-r6}

  ldr r3, =0x020501E0 @ table of active personality values (and also cached battle data ptr)
  add r4, r0, #0 @ save loop variable

  .write_table:

  ldr r0, [r3, #0x10] @ reload battle data ptr, as it was probably blown away
  ldr r1, [r0, #0x30] @ load other battle data ptr??
  ldr r2, =0x219C
  add r1, r1, r2      @ r1 now contains pointer to active battle member array

  @ the table appears to be in this format:
  @ [<active friendly mon 1>, <active enemy mon 1>, <active friendly mon 2>, <active enemy mon 2>]
  @ whose party these pokemon come from can depend on whether you are in a single battle, double battle, double with partner, etc.

  @ get pokemon-in-party index from active party member table
  ldrb r2, [r1, r4]

  @ skip if invalid/blank ID
  @ may not need this? not sure, but copying this from Hijack_PersonalityTableBuild2 just in case
  cmp r2, #6
  beq .end

  @ load loop variable as party index
  @ note about the party index:
  @ 0 and 2 are either the player or partner pokemon, and 1 and 3 are enemy trainer(s).
  @ in a single battle, the party ID of the enemy trainer is 1. in a double battle, it is either 2 or 3 depending on
  @ whether the player is facing one or two trainers.
  @ luckily, if the player is by himself in a double battle, party 2 just maps to party 0, so it is safe to just go
  @ ahead and use the loop variable as the party ID (same goes for one-trainer vs two-trainer double battles with 1 and 3).

  mov r1, r4

  push {r3, r4}
  ldr r3, =0x0223DFAD @ GetMainBattleData_GetAdrOfPkmnInParty
  blx r3
  pop {r3, r4}

  @ store personality value in our table
  ldr r0, [r0]
  lsl r4, r4, #2
  str r0, [r3, r4]

  .end:

  @ restore old code
  pop {r0-r6}
  add r3, r1, #0
  add r0, r0, r2

  pop {pc} 

