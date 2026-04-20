;   Special Functions
.FUNCTION BG_MACRO(val) val + BG_TILE_OFFSET

.FUNCTION xyToNameTbl_M(x, y) (VRAM_ADR_NAMETBL + ((y * 32 + x) * 2)) | VRAMWRITE

.FUNCTION swapBytes(v) (v << $08 | v >> $08) & $FFFF

.FUNCTION bitValue(v) $01 << v

.FUNCTION StripeCount(v) -(v << $01) & $00FF


;   Macros for player BG collision
.MACRO BlockBufferColli_Head
    XOR A
    CALL BlockBufferColli_Side@SetPlayerOffset
.ENDM

.MACRO BlockBufferColli_Feet
    INC C
    XOR A
    CALL BlockBufferColli_Side@SetPlayerOffset
.ENDM

;   Macros for sprite drawing
.MACRO DrawSpriteObject_YPos
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    ADD A, $08
.ENDM

.MACRO DrawSpriteObject_XT
    LD A, C
    LD (DE), A
    INC E
    LDI
    INC BC
    ADD A, $08
    LD (DE), A
    INC E
    LDI
    INC BC
.ENDM

;   Macros for relative position
.MACRO RelativePlayerPosition_M
    LD H, >Player_Rel_XPos
    LD D, H
    CALL GetObjRelativePosition
.ENDM

.MACRO RelativeBubblePosition_M
    LD D, >Bubble_Rel_XPos
    CALL GetObjRelativePosition
.ENDM

.MACRO RelativeFireballPosition_M
    LD D, >Fireball_Rel_XPos
    CALL GetObjRelativePosition
.ENDM

.MACRO RelativeMiscPosition_M
    LD D, >Misc_Rel_XPos
    CALL GetObjRelativePosition
.ENDM

;   Macros for offscreen bits
.MACRO GetPlayerOffscreenBits_M
    LD H, >Player_OffscrBits
    LD D, H
    CALL GetOffScreenBitsSet
.ENDM

.MACRO GetFireballOffscreenBits_M
    LD D, >Fireball_OffscrBits
    CALL GetOffScreenBitsSet
.ENDM

.MACRO GetBubbleOffscreenBits_M
    LD D, >Bubble_OffscrBits
    CALL GetOffScreenBitsSet
.ENDM

.MACRO GetMiscOffscreenBits_M
    LD D, >Misc_OffscrBits
    CALL GetOffScreenBitsSet
.ENDM

.MACRO GetBlockOffscreenBits_M
    LD D, >Block_OffscrBits
    CALL GetOffScreenBitsSet
.ENDM

;   8 bit ADD to 16 bit value
.MACRO addAToHL_M
    ADD A, L
    LD L, A
    ADC A, H
    SUB A, L
    LD H, A
.ENDM

.MACRO addAToDE_M
    ADD A, E
    LD E, A
    ADC A, D
    SUB A, E
    LD D, A
.ENDM

.MACRO addAToBC_M
    ADD A, C
    LD C, A
    ADC A, B
    SUB A, C
    LD B, A
.ENDM

.MACRO addAToIX_M
    ADD A, IXL
    LD IXL, A
    ADC A, IXH
    SUB A, IXL
    LD IXH, A
.ENDM

.MACRO addAToHLS_M
    OR A
    JP P, +
    DEC H
+:
    addAToHL_M
.ENDM

.MACRO addAToDES_M
    OR A
    JP P, +
    DEC D
+:
    addAToDE_M
.ENDM

.MACRO addAToBCS_M
    OR A
    JP P, +
    DEC B
+:
    addAToBC_M
.ENDM

;   8 bit ADD to 16 bit value (low byte only)
.MACRO addAToHL8_M
    ADD A, L
    LD L, A
.ENDM

.MACRO addAToDE8_M
    ADD A, E
    LD E, A
.ENDM

.MACRO addAToBC8_M
    ADD A, C
    LD C, A
.ENDM

.MACRO addAToIX8_M
    ADD A, IXL
    LD IXL, A
.ENDM

.MACRO addAToIY8_M
    ADD A, IYL
    LD IYL, A
.ENDM

;   
.MACRO negBC_M
    XOR A
    SUB A, C
    LD C, A
    SBC A, A
    SUB A, B
    LD B, A
.ENDM