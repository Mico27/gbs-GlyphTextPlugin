.module scene_1_init

.include "vm.i"
.include "data/game_globals.i"

.globl _fade_frames_per_step, b_gtx_display_dialogue, _gtx_display_dialogue

.area _CODE_255


___bank_scene_1_init = 255
.globl ___bank_scene_1_init

_scene_1_init::
        VM_LOCK

        ; Set Sprite Mode: 8x16
        VM_SET_SPRITE_MODE      .MODE_8X16

        ; Glyph Text: Assign Extended Fonts
        VM_PUSH_CONST           _gtx_group_font_korean
        VM_PUSH_CONST           ___bank_gtx_group_font_korean
        VM_CALL_NATIVE          b_gtx_set_font_group, _gtx_set_font_group
        VM_POP                  2

        ; Glyph Text: Assign Extended Fonts
        VM_PUSH_CONST           _gtx_group_font_cjk
        VM_PUSH_CONST           ___bank_gtx_group_font_cjk
        VM_CALL_NATIVE          b_gtx_set_font_group, _gtx_set_font_group
        VM_POP                  2

        ; Set Font
        VM_SET_FONT             FONT_CJK

        ; Glyph Text: Reset Tile Cache
        VM_CALL_NATIVE          b_gtx_reset_cache, _gtx_reset_cache

        ; Glyph Text: Draw To Background
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_BKG
        VM_LOAD_TEXT            0
        .asciz "\003\002\002Glyph Text: VWF 12px\012Proportional widths:\012iiiii vs WWWWW\012.,;:!? 0123456789\012Press A"
        VM_CALL_NATIVE          b_gtx_display_text, _gtx_display_text
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_WIN

        ; Idle
        VM_IDLE

        ; Fade In
        VM_SET_CONST_INT8       _fade_frames_per_step, 3
        VM_FADE_IN              1

        ; Wait For Input
        VM_INPUT_WAIT           16

        VM_CALL_NATIVE b_scroll_repaint, _scroll_repaint

        ; Idle
        VM_IDLE

        ; Glyph Text: Reset Tile Cache
        VM_CALL_NATIVE          b_gtx_reset_cache, _gtx_reset_cache

        ; Glyph Text: Draw To Background
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_BKG
        VM_LOAD_TEXT            0
        .asciz "\003\002\002\200\316\200\322\200\325\200\316\200\324\200\307\012\200\313\200\312\200\317\200\321\200\334\200\330\012\200\332\200\304\200\316\200\311\200\306\200\310\200\337\012\200\323 A \200\344\200\340\200\341"
        VM_CALL_NATIVE          b_gtx_display_text, _gtx_display_text
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_WIN

        ; Wait For Input
        VM_INPUT_WAIT           16

        VM_CALL_NATIVE b_scroll_repaint, _scroll_repaint

        ; Idle
        VM_IDLE

        ; Glyph Text: Reset Tile Cache
        VM_CALL_NATIVE          b_gtx_reset_cache, _gtx_reset_cache

        ; Glyph Text: Draw To Background
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_BKG
        VM_LOAD_TEXT            0
        .asciz "\003\002\002\200\273\200\301\200\277\200\325\200\316\200\342\200\336\012\200\313\200\315\200\320\200\302\200\303\200\275\200\301\200\303\200\273\012\200\266\200\270\200\261\200\265\200\272\200\274\200\272\200\276\200\335\200\316\012A \200\300\200\274\200\303\200\263\200\331\200\267"
        VM_CALL_NATIVE          b_gtx_display_text, _gtx_display_text
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_WIN

        ; Wait For Input
        VM_INPUT_WAIT           16

        VM_CALL_NATIVE b_scroll_repaint, _scroll_repaint

        ; Idle
        VM_IDLE

        ; Glyph Text: Reset Tile Cache
        VM_CALL_NATIVE          b_gtx_reset_cache, _gtx_reset_cache

        ; Glyph Text: Draw To Background
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_BKG
        VM_LOAD_TEXT            0
        .asciz "\003\002\002\200\231\200\250\200\240\200\234\200\236\200\252 \200\244\200\240\200\250\012\200\231\200\250\200\246\200\247\200\246\200\250\200\255\200\240\200\246\200\245\200\233\200\243\200\260\200\245\200\257\200\241\012\200\256\200\250\200\240\200\254\200\252 \200\235\200\234\200\236\200\245\200\233\200\235\200\255\200\233\200\252\200\260\012\200\230\200\233\200\237\200\244\200\240\200\252\200\236 A"
        VM_CALL_NATIVE          b_gtx_display_text, _gtx_display_text
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_WIN

        ; Wait For Input
        VM_INPUT_WAIT           16

        VM_CALL_NATIVE b_scroll_repaint, _scroll_repaint

        ; Idle
        VM_IDLE

        ; Glyph Text: Reset Tile Cache
        VM_CALL_NATIVE          b_gtx_reset_cache, _gtx_reset_cache

        ; Glyph Text: Draw To Background
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_BKG
        VM_LOAD_TEXT            0
        .asciz "\003\002\002\200\201\200\211\200\213\200\204 \200\223\200\220\200\225 \200\214\200\226\200\223\200\216\200\211\012\200\200\200\217\200\206\200\215\200\220\200\207\200\213\200\214\200\226 \200\221\200\215\200\204\200\224\200\220\200\222\012\200\210\200\227\200\210\200\211\200\214\200\206 pixel\012\200\203\200\206\200\224\200\205\200\223\200\224\200\211 A"
        VM_CALL_NATIVE          b_gtx_display_text, _gtx_display_text
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_WIN

        ; Wait For Input
        VM_INPUT_WAIT           16

        VM_CALL_NATIVE b_scroll_repaint, _scroll_repaint

        ; Idle
        VM_IDLE

        ; Glyph Text: Reset Tile Cache
        VM_CALL_NATIVE          b_gtx_reset_cache, _gtx_reset_cache

        ; Glyph Text: Reset Tile Cache
        VM_CALL_NATIVE          b_gtx_reset_cache, _gtx_reset_cache

        ; Glyph Text: Draw To Background
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_BKG
        VM_LOAD_TEXT            0
        .asciz "\003\002\002\002\002\200\202\200\212\200\230 \200\214\200\224 \200\227\200\220\012\200\200\200\215 \200\226 \200\232\200\202 \200\207\200\205\200\213\012\200\222\200\206 \200\231\200\217 \200\225\200\203\012A \200\211 \200\204\200\210\200\216\200\223"
        VM_CALL_NATIVE          b_gtx_display_text, _gtx_display_text
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_WIN

        ; Wait For Input
        VM_INPUT_WAIT           16

        VM_CALL_NATIVE b_scroll_repaint, _scroll_repaint

        ; Idle
        VM_IDLE

        ; Glyph Text Dialogue
        VM_OVERLAY_CLEAR        0, 0, 20, 6, .UI_COLOR_WHITE, .UI_DRAW_FRAME
        VM_OVERLAY_MOVE_TO      0, 18, .OVERLAY_SPEED_INSTANT
        VM_OVERLAY_MOVE_TO      0, 12, .OVERLAY_IN_SPEED
        VM_OVERLAY_SET_SCROLL   1, 1, 18, 4, .UI_COLOR_WHITE
        VM_OVERLAY_WAIT         .UI_NONMODAL, .UI_WAIT_WINDOW
        VM_LOAD_TEXT            0
        .asciz "\003\002\002\001\006VWF 12px \200\333\200\314\012\200\305\200\325 \200\326\200\327\200\343 \200\202\200\215\200\215\200\212\200\217\200\213\200\214\200\204\015\002\002\200\232\200\201\200\221\002\001 \200\232\200\253\200\251\200\251\200\242\200\240\200\241\015A \200\263\200\264\200\262\200\271"
        VM_INVOKE               b_gtx_display_dialogue, _gtx_display_dialogue, 0, .ARG0
        VM_OVERLAY_WAIT         .UI_NONMODAL, ^/(.UI_WAIT_WINDOW | .UI_WAIT_TEXT | .UI_WAIT_BTN_A)/
        VM_IDLE
        VM_OVERLAY_MOVE_TO      0, 18, .OVERLAY_OUT_SPEED
        VM_OVERLAY_WAIT         .UI_NONMODAL, ^/(.UI_WAIT_WINDOW | .UI_WAIT_TEXT)/

        ; Glyph Text: Menu
        VM_OVERLAY_CLEAR        0, 0, 20, 8, .UI_COLOR_WHITE, ^/(.UI_AUTO_SCROLL | .UI_DRAW_FRAME)/
        VM_OVERLAY_MOVE_TO      0, 10, .OVERLAY_IN_SPEED
        VM_OVERLAY_WAIT         .UI_NONMODAL, .UI_WAIT_WINDOW
        VM_SWITCH_TEXT_LAYER    .TEXT_LAYER_WIN
        VM_LOAD_TEXT            0
        .asciz "\003\003\002\200\305\200\325 CJK\012\200\232\200\253\200\251\200\251\200\242\200\240\200\241\012\200\202\200\215\200\215\200\212\200\217\200\213\200\214\200\204"
        VM_CALL_NATIVE          b_gtx_display_text, _gtx_display_text
        VM_PUSH_CONST           VAR_ITEM_ID
        VM_PUSH_CONST           2
        VM_PUSH_CONST           3
        VM_PUSH_CONST           1
        VM_CALL_NATIVE          b_gtx_menu, _gtx_menu
        VM_POP                  4
        VM_OVERLAY_MOVE_TO      0, 18, .OVERLAY_OUT_SPEED
        VM_OVERLAY_WAIT         .UI_NONMODAL, .UI_WAIT_WINDOW

        ; Glyph Text Dialogue
        VM_OVERLAY_CLEAR        0, 0, 20, 6, .UI_COLOR_WHITE, .UI_DRAW_FRAME
        VM_OVERLAY_MOVE_TO      0, 18, .OVERLAY_SPEED_INSTANT
        VM_OVERLAY_MOVE_TO      0, 12, .OVERLAY_IN_SPEED
        VM_OVERLAY_SET_SCROLL   1, 1, 18, 4, .UI_COLOR_WHITE
        VM_OVERLAY_WAIT         .UI_NONMODAL, .UI_WAIT_WINDOW
        VM_LOAD_TEXT            1
        .dw VAR_ITEM_ID
        .asciz "\003\002\002\001\006You chose %d.\012Every option drawn\015at its own width.\015A \200\263\200\264\200\262\200\271"
        VM_INVOKE               b_gtx_display_dialogue, _gtx_display_dialogue, 0, .ARG0
        VM_OVERLAY_WAIT         .UI_NONMODAL, ^/(.UI_WAIT_WINDOW | .UI_WAIT_TEXT | .UI_WAIT_BTN_A)/
        VM_IDLE
        VM_OVERLAY_MOVE_TO      0, 18, .OVERLAY_OUT_SPEED
        VM_OVERLAY_WAIT         .UI_NONMODAL, ^/(.UI_WAIT_WINDOW | .UI_WAIT_TEXT)/

        ; Stop Script
        VM_STOP
