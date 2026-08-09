#pragma bank 255
// SpriteSheet: actor

#include "gbs_types.h"
#include "data/sprite_actor_tileset.h"


BANKREF(sprite_actor)

#define SPRITE_0_STATE_DEFAULT 0
#define SPRITE_0_STATE_BLINKING 8

const metasprite_t sprite_actor_metasprite_0[]  = {
    { 12, 8, 0, 32 }, { 0, 8, 2, 32 },
    {metasprite_end}
};

const metasprite_t sprite_actor_metasprite_1[]  = {
    { 12, 16, 0, 0 }, { 0, -8, 2, 0 },
    {metasprite_end}
};

const metasprite_t sprite_actor_metasprite_2[]  = {
    {metasprite_end}
};

const metasprite_t * const sprite_actor_metasprites[] = {
    sprite_actor_metasprite_0,
    sprite_actor_metasprite_1,
    sprite_actor_metasprite_0,
    sprite_actor_metasprite_2,
    sprite_actor_metasprite_1,
    sprite_actor_metasprite_2
};

const struct animation_t sprite_actor_animations[] = {
    {
        .start = 0,
        .end = 0
    },
    {
        .start = 1,
        .end = 1
    },
    {
        .start = 1,
        .end = 1
    },
    {
        .start = 0,
        .end = 0
    },
    {
        .start = 0,
        .end = 0
    },
    {
        .start = 1,
        .end = 1
    },
    {
        .start = 1,
        .end = 1
    },
    {
        .start = 0,
        .end = 0
    },
    {
        .start = 2,
        .end = 3
    },
    {
        .start = 4,
        .end = 5
    },
    {
        .start = 4,
        .end = 5
    },
    {
        .start = 2,
        .end = 3
    },
    {
        .start = 2,
        .end = 3
    },
    {
        .start = 4,
        .end = 5
    },
    {
        .start = 4,
        .end = 5
    },
    {
        .start = 2,
        .end = 3
    }
};

const UWORD sprite_actor_animations_lookup[] = {
    SPRITE_0_STATE_DEFAULT,
    SPRITE_0_STATE_BLINKING
};

const struct spritesheet_t sprite_actor = {
    .n_metasprites = 6,
    .emote_origin = {
        .x = 0,
        .y = -32
    },
    .metasprites = sprite_actor_metasprites,
    .animations = sprite_actor_animations,
    .animations_lookup = sprite_actor_animations_lookup,
    .bounds = {
        .left = PX_TO_SUBPX(0),
        .bottom = PX_TO_SUBPX(8) - 1,
        .right = PX_TO_SUBPX(16) - 1,
        .top = PX_TO_SUBPX(-8)
    },
    .tileset = TO_FAR_PTR_T(sprite_actor_tileset),
    .cgb_tileset = { NULL, NULL }
};
