.thumb

Hijack_PersonalityTableBuild: @ hook at overlay 12, 0x39F4 (0x0223614)
  .start:

  push {lr}
  push {r0-r6}

  ldr r3, =0x020501E0 @ table of active personality values (and also cached battle data ptr)
  add r4, r0, #0 @ save loop variable

  @ try to figure out which pokemon exactly the loop variable is referring to
  @ 0 and 1 are either the player or partner pokemon, and 2 and 3 are enemy trainer(s).
  @ in a single battle, the party ID of the enemy trainer is 1. in a double battle, it is either 2 or 3 depending on
  @ whether the player is facing one or two trainers.

  cmp r4, #1
  beq .party_1

  cmp r4, #2
  beq .party_0_or_2

  cmp r4, #3
  beq .party_1_or_3

  .party_0:

  mov r5, #0 @ definitely the player
  b .write_table

  .party_1:

  mov r5, #1 @ definitely enemy trainer 1
  b .write_table

  .party_0_or_2:

  mov r1, #2
  mov r5, #0
  mov r6, #2
  b .test_party_empty

  .party_1_or_3:

  mov r1, #3
  mov r5, #1
  mov r6, #3
  b .test_party_empty

  .party_2_or_3:

  mov r1, #3
  mov r5, #2
  mov r6, #3
  b .test_party_empty

  .test_party_empty:

  ldr r0, [r3, #0x10] @ load battle data ptr
  ldr r2, =0x0223DF61 @ GetMainBattleData_NrOfPkmnInParty
  blx r2
  cmp r0, #0
  beq .write_table
  mov r5, r6

  .write_table:

  ldr r0, [r3, #0x10] @ reload battle data ptr, as it was probably blown away
  ldr r1, [r0, #0x30] @ load other battle data ptr??
  ldr r2, =0x219C
  add r1, r1, r2      @ r1 now contains pointer to active battle member array

  @ the table appears to be in this format:
  @ [<active friendly mon 1>, <active enemy mon 1>, <active friendly mon 2>, <active enemy mon 2>]
  @ whose party these pokemon come from can depend on whether you are in a single battle, double battle, double with partner, etc.

  @ get party index from active party member table
  ldrb r2, [r1, r4]

  @ load correct party determined earlier
  mov r1, r5

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

