.include "vm.i"
.include "macro.i"
.include "data/game_globals.i"

; define constants in rom bank 0
.area _CODE

_start_scene_x:: 
        .dw 4608
_start_scene_y:: 
        .dw 4352 
_start_scene_dir:: 
        .db .DIR_RIGHT
_start_scene::
        IMPORT_FAR_PTR_DATA _scene_1
_start_player_move_speed:: 
        .db 128
_start_player_anim_tick:: 
        .db 15
_ui_fonts:: 
        IMPORT_FAR_PTR_DATA _font_cjk
        IMPORT_FAR_PTR_DATA _font_korean
        IMPORT_FAR_PTR_DATA _font_korean_ext0
        IMPORT_FAR_PTR_DATA _font_cjk_ext0
        IMPORT_FAR_PTR_DATA _font_cjk_ext1


; define engine init VM routine which will be packed into some bank
.area _CODE_255

___bank_script_engine_init = 255
.globl ___bank_script_engine_init

.globl _topdown_grid
.globl _fade_style
.globl _gtx_first_tile
.globl _gtx_last_tile
.globl _gtx_tile_placement

_script_engine_init::
        VM_RPN
            .R_INT8 8
            .R_REF_MEM_SET .MEM_I8, _topdown_grid
            .R_INT8 0
            .R_REF_MEM_SET .MEM_I8, _fade_style
            .R_INT8 64
            .R_REF_MEM_SET .MEM_I8, _gtx_first_tile
            .R_INT8 192
            .R_REF_MEM_SET .MEM_I8, _gtx_last_tile
            .R_INT8 0
            .R_REF_MEM_SET .MEM_I8, _gtx_tile_placement
            .R_STOP

        ; return from init routine
        VM_RET_FAR
