.FUNCTION BG_MACRO(val) val + BG_TILE_OFFSET

.FUNCTION xyToNameTbl_M(x, y) (VRAM_ADR_NAMETBL + ((y * 32 + x) * 2)) | VRAMWRITE

.FUNCTION swapBytes(v) (v << $08 | v >> $08) & $FFFF

.FUNCTION bitValue(v) $01 << v

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