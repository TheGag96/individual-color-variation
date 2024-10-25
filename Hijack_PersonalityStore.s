.thumb

Hijack_PersonalityStore: @ hook at 0x701F8 and 0x7059E, in GetMonSpriteCharAndPlttNarcIdsEx and DP_GetMonSpriteCharAndPlttNarcIdsEx
  @ the personality field is normally only stored conditionally (spinda front sprite).
  @ but, we need it everywhere, so store it there always!
  ldr r0, [sp, #0x20]
  str r0, [r5, #0xC]

  @ restore hijacked code
  mov r0, r4
  mov r7, r3

  bx lr
