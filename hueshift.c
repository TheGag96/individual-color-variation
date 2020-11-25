#include "nds.h"

//Chosen to provide the most amount of precision without overflowing in our use case
typedef s32 fixed;
#define FIX_SHIFT 10

#define ONE        (fixed) (1  << FIX_SHIFT)
#define THREE      (fixed) (3  << FIX_SHIFT)
#define THIRTY_TWO (fixed) (32 << FIX_SHIFT)
#define ONE_HALF   (fixed) (1  << (FIX_SHIFT-1))
#define ONE_THIRD  (fixed) (0x155)
#define TWO_THIRDS (fixed) (0x2AA)
#define SQRT_1_3   (fixed) (0x24F)

#define COS_LOC 0x0205003C
#define SIN_LOC 0x0205007C

//Note: Functions in this file are inline because i need to insert this code all in one spot and don't want to have to
//deal with linking.

///Multiply two fixed point values
__attribute__((always_inline)) static inline fixed fxmul(fixed fa, fixed fb) { return (fa*fb)>>FIX_SHIFT; }

///Take a fixed point value and round it, clamp to 0 or 31, then shift down to integer
__attribute__((always_inline)) static inline s32 roundClampShift(fixed v) {
  v += ONE_HALF;
  if (v < 0)           return 0;
  if (v >= THIRTY_TWO) return 31;
  return v >> FIX_SHIFT;
}

/***
 * Performs a hue shift on the colors in a given palette. Index must be from 0 to 63.
 * Values 0-31 shift right, while values 32-63 shift left (but 32 is treated as 0, 33 as 1, etc.).
 ***/
void shiftPalette(u16* colors, u32 index) {
  //Limit the index to valid bounds
  index = index & (64-1);

  u16* cosTable = (u16*)COS_LOC;
  u16* sinTable = (u16*)SIN_LOC;

  //Inserted along with this code are two tables for precalculated cosine values, one after other, each with 32
  //elements of two bytes. The values are represented in fixed point, and the table doesn't go very far around the
  //circle (currently represent about +/-20 degrees).
  //The index into the table is treated a little strangely. an index of 0 corresponds to cos(0) and sin(0).
  //values of index after 32 are treated like -(index-32). for cosine, because cos(x) == cos(-x), I can just
  //chop off bits after the first 5 and index into the table. For sine, sin(-x) == -sin(x), so I flip the sign of the
  //value in the table at (index-32). This is all done to save space.
  fixed cosA = cosTable[index & 31],
        sinA = index >= 32 ? -(fixed)(sinTable[index-32]) : sinTable[index];

  //The following code performs an approximate hue shift on each color in the palette, taken from this post on stack
  //overflow, optimized to work with this fixed point stuff: https://stackoverflow.com/a/8510751/963007
  fixed val1 = ONE_THIRD + fxmul(cosA, TWO_THIRDS);
  fixed val2 = fxmul(ONE - cosA, ONE_THIRD) - fxmul(SQRT_1_3, sinA);
  fixed val3 = fxmul(ONE - cosA, ONE_THIRD) + fxmul(SQRT_1_3, sinA);

  for (u8 i = 1; i < 16; i++) { //Skip past first color, which is transparency
    u16 color = colors[i];

    //Unpack the color
    fixed r = (color & 0x1F) << FIX_SHIFT;
    color = color >> 5;
    fixed g = (color & 0x1F) << FIX_SHIFT;
    color = color >> 5;
    fixed b = (color & 0x1F) << FIX_SHIFT;

    //Hue shift, clamping at the max component value (31)
    s32 rx = roundClampShift(fxmul(r, val1) + fxmul(g, val2) + fxmul(b, val3));
    s32 gx = roundClampShift(fxmul(r, val3) + fxmul(g, val1) + fxmul(b, val2));
    s32 bx = roundClampShift(fxmul(r, val2) + fxmul(g, val3) + fxmul(b, val1));

    //Pack the color
    colors[i] = rx | (gx << 5) | (bx << 10);
  }
}
