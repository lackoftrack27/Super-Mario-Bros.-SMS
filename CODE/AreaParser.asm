;-------------------------------------------------------------------------------------
 
AreaParserTaskHandler:
    LD A, (AreaParserTaskNum)   ;check number of tasks here
    OR A
    JP NZ, DoAPTasks            ;if already set, go ahead
    LD A, $08
    LD (AreaParserTaskNum), A   ;otherwise, set eight by default
DoAPTasks:
    DEC A
    CALL AreaParserTasks
    LD HL, AreaParserTaskNum
    DEC (HL)                    ;if all tasks not complete do not
    RET NZ                      ;set VRAM address control to Buffer2
    LD A, VRAMTBL_BUFFER2
    LD (VRAM_Buffer_AddrCtrl), A
    RET

AreaParserTasks:
    RST JumpEngine

    .dw IncrementColumnPos
    .dw RenderAreaGraphics
    .dw RenderAreaGraphics
    .dw AreaParserCore
    .dw IncrementColumnPos
    .dw RenderAreaGraphics
    .dw RenderAreaGraphics
    .dw AreaParserCore

;-------------------------------------------------------------------------------------

IncrementColumnPos:
    LD HL, CurrentColumnPos     ;increment column where we're at
    LD A, (HL)
    INC A
    AND A, %00001111            ;mask out higher nybble
    LD (HL), A
    JP NZ, @NoColWrap
    LD HL, CurrentPageLoc       ;and increment page number where we're at
    INC (HL)
@NoColWrap:
    LD HL, BlockBufferColumnPos ;increment column offset where we're at
    LD A, (HL)
    INC A
    AND A, %00011111            ;mask out all but 5 LSB (0-1f)
    LD (HL), A                  ;and save
    RET

;-------------------------------------------------------------------------------------
;$00 - used as counter, store for low nybble for background, ceiling byte for terrain
;$01 - used to store floor byte for terrain
;$07 - used to store terrain metatile
;$06-$07 - used to store block buffer address

.SECTION "BG Scenery Offsets Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   BACKGROUND SCENERY (0 - NO SCENERY, 1 - CLOUDS, 2 - CLOUDS/MOUNTAINS/GRASS, 3 - CLOUDS/TREES/FENCES)
BSceneDataOffsets:
    ;.db $00, $30, $60, $90
    ; BANK 0
    .dw BackSceneryData@Clouds
    .dw BackSceneryData@Mountains
    .dw BackSceneryData@Trees
    ; BANK 1
    .dw BackSceneryData@Laterns
    .dw BackSceneryData@CloudsNight
    .dw BackSceneryData@MountainsNight
    .dw BackSceneryData@TreesNight
    ; BANK 2
    .dw BackSceneryData@Water00
    .dw BackSceneryData@Water01
    .dw BackSceneryData@WaterCastle
.ENDS

.SECTION "BG Scenery Data - Clouds" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   HIGH NIBBLE: HEIGHT, LOW NIBBLE: OFFSET-1 INTO BackSceneryMetatiles
;   0 = NO DATA (SKIP)
BackSceneryData:
@Clouds:
    ; .db $93, $00, $00, $11, $12, $12, $13, $00, $00, $51, $52, $53, $00, $00, $00, $00
    ; .db $00, $00, $01, $02, $02, $03, $00, $00, $00, $00, $00, $00, $91, $92, $93, $00
    ; .db $00, $00, $00, $51, $52, $53, $41, $42, $43, $00, $00, $00, $00, $00, $91, $92
    .db $01, $00, $00, $02, $03, $03, $04, $00, $00, $05, $06, $07, $00, $00, $00, $00
    .db $00, $00, $08, $09, $09, $0A, $00, $00, $00, $00, $00, $00, $0B, $0C, $01, $00
    .db $00, $00, $00, $05, $06, $07, $0D, $0E, $0F, $00, $00, $00, $00, $00, $0B, $0C
.ENDS

.SECTION "BG Scenery Data - Mountains" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@Mountains:
    ; .db $97, $87, $88, $89, $99, $00, $00, $00, $11, $12, $13, $a4, $a5, $a5, $a5, $a6
    ; .db $97, $98, $99, $01, $02, $03, $00, $a4, $a5, $a6, $00, $11, $12, $12, $12, $13
    ; .db $00, $00, $00, $00, $01, $02, $02, $03, $00, $a4, $a5, $a5, $a6, $00, $00, $00
    .db $10, $11, $12, $13, $14, $00, $00, $00, $02, $03, $04, $15, $16, $16, $16, $17
    .db $10, $18, $14, $08, $09, $0A, $00, $15, $16, $17, $00, $02, $03, $03, $03, $04
    .db $00, $00, $00, $00, $08, $09, $09, $0A, $00, $15, $16, $16, $17, $00, $00, $00
.ENDS

.SECTION "BG Scenery Data - Trees" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@Trees:
    ; .db $11, $12, $12, $13, $00, $00, $00, $00, $00, $00, $00, $9c, $00, $8b, $aa, $aa
    ; .db $aa, $aa, $11, $12, $13, $8b, $00, $9c, $9c, $00, $00, $01, $02, $03, $11, $12
    ; .db $12, $13, $00, $00, $00, $00, $aa, $aa, $9c, $aa, $00, $8b, $00, $01, $02, $03
    .db $02, $03, $03, $04, $00, $00, $00, $00, $00, $00, $00, $19, $00, $1A, $1B, $1B
    .db $1B, $1B, $02, $03, $04, $1A, $00, $19, $19, $00, $00, $08, $09, $0A, $02, $03
    .db $03, $04, $00, $00, $00, $00, $1B, $1B, $19, $1B, $00, $1A, $00, $08, $09, $0A
.ENDS

.SECTION "BG Scenery Data - Laterns" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@Laterns:
    ; .db $00, $00, $00, $00, $00, $00, $4D, $4E, $00, $00, $00, $00, $00, $00, $00, $00
    ; .db $00, $00, $00, $00, $00, $00, $4D, $4E, $00, $00, $00, $00, $00, $00, $00, $00
    ; .db $00, $00, $00, $00, $00, $00, $00, $1D, $1E, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $00, $8E, $8F, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $00, $8E, $8F, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $00, $00, $90, $91, $00, $00, $00, $00, $00, $00, $00
.ENDS

.SECTION "BG Scenery Data - CloudsNight" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@CloudsNight:
    .db $1C, $1D, $1E, $02, $1F, $03, $20, $21, $22, $23, $24, $07, $25, $00, $26, $27
    .db $00, $28, $29, $2A, $09, $2B, $2C, $2D, $2E, $00, $00, $2F, $30, $31, $01, $32
    .db $33, $1D, $1E, $05, $34, $07, $0D, $35, $36, $37, $38, $00, $25, $00, $39, $3A
.ENDS

.SECTION "BG Scenery Data - MountainsNight" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@MountainsNight:
    .db $3B, $3C, $3D, $13, $3E, $00, $3F, $21, $40, $03, $41, $15, $42, $16, $43, $44
    .db $10, $45, $46, $47, $09, $2B, $2C, $48, $49, $17, $00, $4A, $4B, $4C, $03, $4D
    .db $33, $1D, $1E, $00, $4E, $09, $4F, $50, $22, $51, $52, $16, $53, $00, $26, $27
.ENDS

.SECTION "BG Scenery Data - TreesNight" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@TreesNight:
    .db $54, $55, $56, $04, $57, $00, $3F, $21, $22, $37, $38, $19, $25, $1A, $58, $59
    .db $1B, $5A, $5B, $03, $04, $1A, $2C, $5C, $5D, $00, $00, $5E, $5F, $60, $02, $61
    .db $62, $63, $64, $00, $57, $00, $65, $66, $67, $68, $38, $1A, $25, $08, $69, $0A
.ENDS

.SECTION "BG Scenery Data - Water (2-2/7-2)" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@Water00:
    .db $6A, $6B, $6C, $6D, $6C, $6D, $6C, $6D, $6E, $6F, $70, $71, $6C, $6D, $6C, $6D
    .db $6C, $6D, $6C, $6D, $72, $73, $74, $75, $6A, $6B, $6E, $6F, $70, $71, $6C, $6D
    .db $6C, $6D, $6C, $6D, $6C, $6D, $6C, $6D, $6C, $6D, $72, $73, $74, $75, $76, $77
.ENDS

.SECTION "BG Scenery Data - Water (5-2/6-2)" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@Water01:
    .db $6C, $6D, $6C, $6D, $6C, $6D, $6C, $6D, $6E, $6F, $70, $71, $6C, $6D, $6C, $6D
    .db $6C, $6D, $6C, $6D, $72, $73, $74, $75, $6A, $6B, $6E, $6F, $70, $71, $6C, $6D
    .db $6C, $6D, $6C, $6D, $6C, $6D, $6C, $6D, $6C, $6D, $6E, $6F, $70, $71, $6C, $6D
.ENDS

.SECTION "BG Scenery Data - Water Castle" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
@WaterCastle:
    .db $78, $79, $7A, $7B, $78, $79, $7C, $7D, $7E, $7F, $80, $81, $7E, $7F, $80, $81
    .db $82, $83, $80, $81, $84, $85, $86, $7B, $78, $79, $7C, $7D, $82, $83, $80, $87
    .db $88, $89, $8A, $8B, $8C, $8D, $80, $81, $84, $85, $86, $7B, $78, $79, $7A, $7B
.ENDS

;.SECTION "BG Scenery Metatile Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
; BackSceneryMetatiles:
; ;   Clouds
;     .db MT_CLOUD_LEFT, MT_CLOUD_LEFTBOT, MT_BLANK               ; left
;     .db MT_CLOUD_MID, MT_CLOUD_MIDBOT, MT_BLANK                 ; middle
;     .db MT_CLOUD_RIGHT, MT_CLOUD_RIGHTBOT, MT_BLANK             ; right
; ;   Bush/Grass
;     .db MT_BUSH_LEFT, MT_BLANK, MT_BLANK                        ; left
;     .db MT_BUSH_MID, MT_BLANK, MT_BLANK                         ; middle
;     .db MT_BUSH_RIGHT, MT_BLANK, MT_BLANK                       ; right
; ;   Mountains
;     .db MT_BLANK, MT_MOUNT_LEFT, MT_MOUNT_LEFTBOT               ; left
;     ;.db MT_MOUNT_MIDTOP, MT_MOUNT_LEFTBOT,  MT_MOUNT_MIDBOT     ; middle
;     .db MT_MOUNT_MIDTOP, $01,  MT_MOUNT_MIDBOT     ; middle
;     .db MT_BLANK, MT_MOUNT_RIGHT, MT_MOUNT_RIGHTBOT             ; right
; ;   Fence
;     .db MT_FENCE, MT_BLANK, MT_BLANK
; ;   Trees
;     .db MT_TALLTREE_TOP, MT_TALLTREE_BOT, MT_TREE_TRUNK         ; tall
;     .db MT_SMALLTREE_TOP, MT_TREE_TRUNK, MT_TREE_TRUNK          ; short
; ;   Latern
;     .db MT_LATERN_LT, MT_LATERN_LB, MT_BLANK
;     .db MT_LATERN_RT, MT_LATERN_RB, MT_BLANK
;.ENDS

.SECTION "FG Scenery Offsets Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   FOREGROUND SCENERY (0 - NO SCENERY, 1 - WATER, 2 - BRICK WALL, 3 - OVER WATER)
;   ONLY 1,2,3 HAVE INDEXES
;   VALUES ARE OFFSETS INTO ForeSceneryData
FSceneDataOffsets:
    ;.db $00, $0d, $1a
    .dw ForeSceneryData@Water, ForeSceneryData@Wall, ForeSceneryData@OverWater
.ENDS

.SECTION "FG Scenery Metatile Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   METATILE DATA
;   0 = NO DATA (SKIP)
ForeSceneryData:
@Water:
    ;.db MT_WATER_TOP, MT_WATER, MT_WATER, MT_WATER, MT_WATER, MT_WATER, MT_WATER
    ;.db MT_WATER, MT_WATER, MT_WATER, MT_WATER, MT_SOLIDBLK_WATER;, MT_SOLIDBLK_WATER
    .db MT_WATER_TOP, MT_WATER, MT_WATER, MT_WATER, MT_WATER, MT_WATER, MT_WATER
    .db MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK
@Wall:
    .db MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK, MT_CASTLE_TOP_NONPRI, MT_CASTLE_BRICK
    .db MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_BLANK;, MT_BLANK
@OverWater:
    .db MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK
    .db MT_BLANK, MT_BLANK
    .db MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK, MT_WATER_TOP;, MT_WATER 
@OverLava:
    .db MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK
    .db MT_BLANK, MT_BLANK
    .db MT_BLANK, MT_BLANK, MT_BLANK, MT_BLANK, MT_LAVA_TOP 
.ENDS


.SECTION "Terrain Metatile Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   BLOCK FOR AREATYPE (WATER,OVERWORLD,UNDERGROUND,CASTLE)
TerrainMetatiles:
    .db MT_SOLIDBLK_WATER, MT_ROCK, MT_BRICK, MT_CASTLECEILING_L;MT_SOLIDBLK_WHITE
.ENDS

.SECTION "Terrain Render Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
TerrainRenderBits:
    .db %00000000, %00000000 ;no ceiling or floor
    .db %00000000, %00011000 ;no ceiling, floor 2
    .db %00000001, %00011000 ;ceiling 1, floor 2
    .db %00000111, %00011000 ;ceiling 3, floor 2
    .db %00001111, %00011000 ;ceiling 4, floor 2
    .db %11111111, %00011000 ;ceiling 8, floor 2
    .db %00000001, %00011111 ;ceiling 1, floor 5
    .db %00000111, %00011111 ;ceiling 3, floor 5
    .db %00001111, %00011111 ;ceiling 4, floor 5
    .db %10000001, %00011111 ;ceiling 1, floor 6
    .db %00000001, %00000000 ;ceiling 1, no floor
    .db %10001111, %00011111 ;ceiling 4, floor 6
    .db %11110001, %00011111 ;ceiling 1, floor 9
    .db %11111001, %00011000 ;ceiling 1, middle 5, floor 2
    .db %11110001, %00011000 ;ceiling 1, middle 4, floor 2
    .db %11111111, %00011111 ;completely solid top to bottom
.ENDS


AreaParserCore:
    LD A, (BackloadingFlag)         ;check to see if we are starting right of start
    OR A
    CALL NZ, ProcessAreaData        ;if not, go ahead and render background, foreground and terrain

RenderSceneryTerrain:
;   Clear Metatile Buffer
    DI
    LD HL, $0000
    LD E, L
    LD D, H
    ADD HL, SP
    EX DE, HL
    LD SP, MetatileBuffer + $0D
    PUSH HL ; C, B
    PUSH HL ; A, 9
    PUSH HL ; 8, 7
    PUSH HL ; 6, 5
    PUSH HL ; 4, 3
    PUSH HL ; 2, 1
    INC SP
    PUSH HL ; 1, 0
    EX DE, HL
    LD SP, HL
    EI
;   BACKGROUND SCENERY
    LD A, (BackgroundScenery)       ;do we need to render the background scenery?
    OR A
    JR Z, RendFore                  ;if not, skip to check the foreground
;   Calculate which third of the page we're on (0, 1, or 2)
    LD A, (CurrentPageLoc)          ;otherwise check for every third page
    ; Get CurrentPageLoc mod 3
    LD C, A                         ;add nibbles
    RRCA
    RRCA
    RRCA
    RRCA
    ADD A, C
    ADC A, $00                      ;n mod 15 (+1) in both nibbles
    LD C, A                         ;add half nibbles
    RRCA
    RRCA
    ADD A, C
    ADC A, $01
    JR Z, @RendBack
    AND A, $03
    DEC A
;   Combine page third with column position and bg scenery offset
@RendBack:
    ADD A, A                        ;multiply by 16
    ADD A, A
    ADD A, A
    ADD A, A
    LD B, A
    LD A, (CurrentColumnPos)
    ADD A, B                        ;add our current column position
    LD B, A
    LD HL, BSceneDataOffsets
    LD A, (BackgroundScenery)
    DEC A
    ;addAToHL8_M
    ;LD A, (HL)              
    ;ADD A, B                        ;add to it bg scenery offset
;   Use as offset into BackSceneryData
    ;LD HL, BackSceneryData
    ;addAToHL8_M
    ADD A, A                        ;get pointer to bg scenery data
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    LD A, B                         ;get data for current column
    addAToHL8_M
    LD A, (HL)                      ;load data from sum of offsets
    OR A
    JR Z, RendFore                  ;if zero, no scenery for that part
;   Extract low nybble (metatile type) and high nybble (height)
;     ; metatile
;     PUSH AF
;     AND A, $0F                      ;save to stack and clear high nybble
;     DEC A                           ;subtract one (because low nybble is $01-$0c)
;     LD B, A                         ;save low nybble
;     ADD A, A                        ;multiply by three (shift to left and add result to old one)
;     ADD A, B                        ;note that since d7 was nulled, the carry flag is always clear
;     LD HL, BackSceneryMetatiles     ;save as offset for background scenery metatile data
;     addAToHL8_M
;     ; height
;     POP AF                          ;get high nybble from stack, move low
;     RRCA
;     RRCA
;     RRCA
;     RRCA
;     AND A, $0F
;     LD B, A                         ;save for next loop
;     LD DE, MetatileBuffer           ;use as second offset (used to determine height)
;     addAToDE8_M
; ;   Copy 3 metatiles starting at the height position
;     LD A, B
;     LD BC, $03FF                    ; C == $FF so LDI won't mess up DJNZ
; SceLoop1:
;     LDI                     
;     INC A
;     CP A, $0B                       ;if at this location, leave loop (Terrain starts here)
;     JR Z, RendFore
;     DJNZ SceLoop1                   ;decrement until counter expires, barring exception
    DEC A
    LD DE, BackSceneryColumnPtrs    ; load metatile list for column type
    LD L, A
    LD H, $00
    ADD HL, HL
    ADD HL, DE
    LD A, (HL)
    INC HL
    LD H, (HL)
    LD L, A
    LD D, >MetatileBuffer
-:
    LD A, (HL)                      ; get row of metatile
    LD C, A                         ; also store here
    AND A, $7F                      ; remove terminator bit
    LD E, <MetatileBuffer           ; store metatile into MetatileBuffer at the correct index
    addAToDE8_M
    INC HL
    LDI
    INC C                           ; check if that was the last metatile in the list
    JP P, -                         ; if not (bit 7 clear), keep processing list
;   FOREGROUND SCENERY
RendFore:
    LD A, (ForegroundScenery)       ;check for foreground data needed or not
    OR A
    JR Z, RendTerr                  ;if not, skip this part
;   Get pointer to foreground type's data
    DEC A
    ADD A, A                        ; multiply by 12 (length of MetatileBuffer)
    ADD A, A
    LD B, A
    ADD A, A
    ADD A, B
    LD HL, ForeSceneryData
    addAToHL8_M
;
    LD A, (AreaType)
    CP A, $03
    JR NZ, +
    LD HL, ForeSceneryData@OverLava
+:
;   Copy foreground scenery data to metatile buffer
    LD DE, MetatileBuffer
    LD B, $0C
SceLoop2:
    LD A, (HL)
    OR A
    JR Z, NoFore                    ;do not store if zero found
    LD (DE), A
NoFore:
    INC HL
    INC E
    DJNZ SceLoop2                   ;store up to end of metatile buffer
;   FLOOR TERRAIN
RendTerr:
    LD A, (CurrentColumnPos)        ;set flag for castle ceiling tile
    AND A, $01
    LD IYH, A
    ;
    LD IYL, $00                     ;flag to render castle ceiling and floor
    LD A, (AreaType)
    CP A, $03
    JR NZ, +
    LD IYL, $01                     ;render castle ceiling
+:
    ;LD A, (AreaType)                ;check world type for water level
    OR A
    JR NZ, TerMTile                 ;if not water level, skip this part
    LD A, (WorldNumber)             ;check world number, if not world number eight
    CP A, WORLD8                    ;then skip this part
    JR NZ, TerMTile
    ;LD A, MT_SOLIDBLK_WHITE         ;if set as water level and world number eight,
    LD A, MT_CASTLECEILING_L
    LD IYL, $01
    JP StoreMT                      ;use castle wall metatile as terrain type
TerMTile:
    LD A, (CloudTypeOverride)       ;check for cloud type override
    OR A
    LD A, MT_CLOUDGND               ;if set, use cloud block terrain
    JR NZ, StoreMT
    LD HL, TerrainMetatiles         ;otherwise get appropriate metatile for area type
    LD A, (AreaType)
    addAToHL8_M
    LD A, (HL)
StoreMT:
    LD IXH, A                       ;store value here
    LD A, (TerrainControl)          ;use yet another value from the header
    ADD A, A                        ;multiply by 2 and use as yet another offset
    LD HL, TerrainRenderBits
    addAToHL8_M
    LD IXL, $00                     ;initialize X, use as metatile buffer offset
    LD DE, MetatileBuffer
TerrLoop:
    LD C, (HL)                      ;get one of the terrain rendering bit data
    LD A, (CloudTypeOverride)       ;skip if value here is zero
    OR A
    JR Z, NoCloud2
    LD A, IXL                       ;otherwise, check if we're doing the ceiling byte
    OR A
    JR Z, NoCloud2
    LD A, C                         ;if not, mask out all but d3
    AND A, %00001000
    LD C, A
NoCloud2:
    LD B, $08                       ;start at beginning of bitmasks
TerrBChk:
    RR C                            ;rotate byte and check if carry occured
    JR C, RenderBit                 ;if not set, skip this part (do not write terrain to buffer)
    LD A, IYL                       ;
    DEC A
    JR NZ, NextTBit
    INC IYL                         ;set flag to render castle floor
    JP NextTBit
RenderBit:
    LD A, IYL                       ;check if rendering castle floor top
    CP A, $02
    JR NZ, +                        ;if not, skip
    LD IXH, MT_CASTLEFLOOR_TOP      ;set metatile to castle floor top
+:
    ;
    LD A, IXH
    LD (DE), A                      ;load terrain type metatile number and store into buffer here
    ;
    LD A, IYL                       ;check if doing castle ceiling/floor rendering
    OR A
    JR Z, NextTBit                  ;if not, skip
    ;
    CP A, $02                       ;check if rendering if castle floor top
    JR NZ, +                        ;if not, skip
    LD IYL, $00                     ;disable castle ceiling/floor processing
    INC IXH                         ;set metatile to castle floor bottom
    INC IXH
    JP NextTBit                     ;do next terrain bit
    ;
+:
    LD A, IYH                       ;check if we need to render right castle ceiling tile               
    AND A, $01
    JR NZ, NextTBit                 ;if not, skip
    LD A, IXH
    INC A
    LD (DE), A
NextTBit:
    INC E                           ;continue until end of buffer
    INC IXL
    LD A, IXL
    CP A, $0D
    JR Z, RendBBuf                  ;if we're at the end, break out of this loop
    LD A, (AreaType)                ;check world type for underground area
    CP A, $02
    JR NZ, EndUChk                  ;if not underground, skip this part
    LD A, IXL
    CP A, $0B
    JR NZ, EndUChk                  ;if we're at the bottom of the screen, override
    LD IXH, MT_ROCK                 ;old terrain type with ground level terrain type
EndUChk:
    INC IYH                         ;toggle castle ceiling tile flag
    DJNZ TerrBChk                   ;if not all bits checked, loop back
    INC HL
    JP TerrLoop                     ;unconditional branch, use Y to load next byte
RendBBuf:
    CALL ProcessAreaData            ;do the area data loading routine now
;   WRITE BLOCK BUFFER (COLLISION DATA)
    LD A, (BlockBufferColumnPos)

    ;;;
    ;CALL GetBlockBufferAddr         ;get block buffer address from where we're at
    LD DE, Block_Buffer_1
    BIT 4, A
    JR Z, +
    LD E, <Block_Buffer_2
+:
    AND A, $0F                      ;mask out high nybble
    addAToDE8_M                     ;add to low byte    
    LD (Temp_Bytes + $06), DE
    ;;;

    LD H, >BlockBuffLowBounds       ;init index regs and start at beginning of smaller buffer
    LD BC, MetatileBuffer
    LD IXL, $0D
ChkMTLow:
    LD A, (BC)                      ;load stored metatile number
    AND A, %11000000                ;mask out all but 2 MSB
    RLCA                            ;make %xx000000 into %000000xx
    RLCA
    ADD A, <BlockBuffLowBounds      ;(SMS) calculate pointer to BlockBuffLowBounds
    LD L, A
    LD A, (BC)                      ;reload original unmasked value here
    CP A, (HL)                      ;check for certain values depending on bits set
    JR NC, StrBlock                 ;if equal or greater, branch
    XOR A                           ;if less, init value before storing
StrBlock:
    LD (DE), A                      ;store value into block buffer
    LD A, $10
    addAToDE_M                      ;add 16 (move down one row) to offset
    INC C                           ;increment column value
    DEC IXL
    JP NZ, ChkMTLow                 ;continue until we pass last row, then leave
    RET

    ; BLOCK BUFFER DATA LAYOUT:
    ; HN: ROW,  LN: COL
    ; 00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    ; 10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F
    ; 20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F
    ; 30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F
    ; 40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
    ; 50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F
    ; 60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F
    ; 70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E 7F
    ; 80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F
    ; 90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F
    ; A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
    ; B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
    ; C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF <- UNSEEN DUE TO SMALLER RESOLUTION

.SECTION "Metatile Index Collision Floor TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;numbers lower than these with the same attribute bits
;will not be stored in the block buffer
BlockBuffLowBounds:
    .db MT_WARPPIPE_TOP_LEFT, MT_SBRICK, MT_CLOUDGND, MT_QBLK_COIN
.ENDS

;-------------------------------------------------------------------------------------
;$00(IXL) - used to store area object identifier
;$07(IXH) - used as adder to find proper area object code
; B/C   = X/Y


ProcessAreaData:
    LD HL, AreaObjectLength_03              ;start at the end of area object buffer
ProcADLoop:
    LD (ObjectOffset), HL
    XOR A                                   ;reset flag
    LD (BehindAreaParserFlag), A
    ; Get current area object data
    LD D, >AreaDataBank
    LD A, (AreaDataOffset)                  ;get offset of area data pointer
    LD E, A
    LD A, (DE)                              ;get first byte of area object
    ; Check for end-of-area marker
    CP A, $D0                               ;if end-of-area, skip all this crap
    JR Z, RdyDecode
    ; Check if this buffer slot is already in use
    LD A, (HL)                              ;check area object buffer flag
    OR A
    JP P, RdyDecode                         ;if buffer not negative, branch, otherwise
    ; Get second byte and check for page select bit
    INC E
    LD A, (DE)                              ;get second byte of area object
    ADD A, A                                ;check for page select bit (d7), branch if not set
    JP NC, Chk1Row13
    LD A, (AreaObjectPageSel)               ;check page select
    OR A
    JP NZ, Chk1Row13
    PUSH HL
    LD HL, AreaObjectPageSel
    LD (HL), $01                            ;if not already set, set it now
    DEC L                                   ;AreaObjectPageLoc
    INC (HL)                                ;and increment page location
    POP HL
    ; Check object row position
Chk1Row13:
    DEC E
    LD A, (DE)                              ;reread first byte of level object
    AND A, $0F                              ;mask out high nybble
    CP A, $0D                               ;row 13?
    JR NZ, Chk1Row14
    INC E                                   ;if so, reread second byte of level object
    LD A, (DE)
    DEC E                                   ;decrement to get ready to read first byte
    AND A, %01000000                        ;check for d6 set (if not, object is page control)
    JR NZ, CheckRear
    LD A, (AreaObjectPageSel)               ;if page select is set, do not reread
    OR A
    JR NZ, CheckRear
    ; Set new page location from lower 5 bits
    INC E                                   ;if d6 not set, reread second byte
    LD A, (DE)
    AND A, %00011111                        ;mask out all but 5 LSB and store in page control
    LD (AreaObjectPageLoc), A
    LD A, (AreaObjectPageSel)               ;increment page select
    INC A
    LD (AreaObjectPageSel), A
    ; Skip to next object
    JP NextAObj
Chk1Row14:
    CP A, $0E                               ;row 14?
    JR NZ, CheckRear
    LD A, (BackloadingFlag)                 ;check flag for saved page number and branch if set
    OR A
    JR NZ, RdyDecode                        ;to render the object (otherwise bg might not look right)
    ; Check if object is behind renderer
CheckRear:
    LD A, (CurrentPageLoc)                  ;check to see if current page of level object is
    LD B, A
    LD A, (AreaObjectPageLoc)               ;behind current page of renderer
    CP A, B
    JR C, SetBehind                         ;if so branch
RdyDecode:
    CALL DecodeAreaData                     ;do sub and do not turn on flag
    JP ChkLength
SetBehind:
    LD A, $01                               ;turn on flag if object is behind renderer
    LD (BehindAreaParserFlag), A
NextAObj:
    CALL IncAreaObjOffset                   ;increment buffer offset and move on
ChkLength:
    LD HL, (ObjectOffset)                   ;get buffer offset
    LD L, <AreaObjectLength
    LD A, (HL)                              ;check object length for anything stored here
    OR A
    JP M, ProcLoopb                         ;if not, branch to handle loopback
    DEC (HL)                                ;otherwise decrement length or get rid of it
ProcLoopb:                          
    DEC H                                   ;decrement buffer offset                                      
    BIT 6, H
    JP NZ, ProcADLoop                       ;and loopback unless exceeded buffer
;
    LD A, (BehindAreaParserFlag)            ;check for flag set if objects were behind renderer
    OR A
    JP NZ, ProcessAreaData                  ;branch if true to load more level data, otherwise
    LD A, (BackloadingFlag)                 ;check for flag set if starting right of page $00
    OR A
    JP NZ, ProcessAreaData                  ;branch if true to load more level data, otherwise leave
    RET

IncAreaObjOffset:
    LD A, (AreaDataOffset)      ;increment offset of level pointer
    ADD A, $02
    LD (AreaDataOffset), A
    XOR A                       ;reset page select
    LD (AreaObjectPageSel), A
    RET

; ON ENTRY: X = ObjectOffset
; B/C   = X/Y
; IX    = $00/$07

; HL -> AreaObjectLength + n
; DE -> AreaDataBank + n
DecodeAreaData:
;   Get the data offset
    ; Check current object's buffer flag
    LD A, (HL)                              ;check current buffer flag
    OR A
    ; Assume new object, use current area data offset
    JP M, Chk1stB                           ;jump if flag is $FF
    ; Object already in progress, so use stored offset
    LD L, <AreaObjOffsetBuffer              ;if not, get offset from buffer
    LD A, (HL)
    LD E, A
Chk1stB:
;   Check for end of level
    LD A, (DE)                              ;get first byte of level object again
    CP A, $D0
    RET Z                                   ;if end of level, leave this routine
;   Extract row from low nybble
    AND A, $0F                              ;otherwise, mask out low nybble
;   Determine base offset for object type lookup
    LD B, $10                               ;load offset of 16 for special row 15
    CP A, $0F                               ;row 15?
    JR Z, ChkRow14                          ;if so, keep the offset of 16
    LD B, $08                               ;otherwise load offset of 8 for special row 12
    CP A, $0C                               ;row 12?
    JR Z, ChkRow14                          ;if so, keep the offset value of 8
    LD B, $00                               ;otherwise nullify value by default
;   Handle rows
ChkRow14:
    LD IXH, B                               ;store whatever value we just loaded here
    ;LD HL, (ObjectOffset)
    CP A, $0E                               ;row 14?
    JR NZ, ChkRow13 
    LD IXH, $00                             ;if so, load offset with $00
    LD A, $4A ;LD A, $2E                               ;and load A with another value
    JP NormObj                              ;unconditional branch
ChkRow13:
    CP A, $0D                               ;row 13?
    JR NZ, ChkSRows
    LD IXH, $22                             ;if so, load offset with 34
    ; Check if this is a page control object (d6 clear)                     
    INC E
    LD A, (DE)                              ;get next byte
    BIT 6, A                                ;mask out all but d6 (page control obj bit)
    RET Z                                   ;if d6 clear, branch to leave (we handled this earlier)
    ; Check for loop command (low nybble = 0x4B with d6 set)
    AND A, %01111111                        ;mask out d7
    CP A, $4B                               ;check for loop command in low nybble
    JR NZ, Mask2MSB                         ;(plus d6 set for object other than page control)
    LD A, $01
    LD (LoopCommand), A                     ;if loop command, set loop command flag
Mask2MSB:
    LD A, (DE)
    AND A, %00111111                        ;mask out d7 and d6
    JP NormObj                              ;and jump
;   Get Object ID
ChkSRows:
    CP A, $0C                               ;row 12-15?
    JR NC, SpecObj
    INC E
    LD A, (DE)                               ;if not, get second byte of level object
    AND A, %01110000                        ;mask out all but d6-d4
    JR NZ, LrgObj                           ;if any bits set, branch to handle large object
    ; Get Normal Object's ID
    LD IXH, $16                             ;otherwise set offset of 24 for small object
    LD A, (DE)                              ;reload second byte of level object
    AND A, %00001111                        ;mask out higher nybble and jump
    JP NormObj
    ; Get Large Object's ID
LrgObj:
    LD IXL, A                               ;store value here (branch for large objects)
    CP A, $70                               ;check for vertical pipe object
    JR NZ, NotWPipe
    LD A, (DE)
    AND A, %00001000                        ;if d3 clear, branch to get original value
    JR Z, NotWPipe
    LD IXL, $00                             ;otherwise, nullify value for warp pipe
NotWPipe:
    LD A, IXL                               ;get value and jump ahead
    JP MoveAOId
    ; Get Special Object's ID
SpecObj:
    INC E                                   ;branch here for rows 12-15
    LD A, (DE)
    AND A, %01110000                        ;get next byte and mask out all but d6-d4
MoveAOId:
    RRCA                                    ;move d6-d4 to lower nybble
    RRCA
    RRCA
    RRCA
    AND A, $0F
;
NormObj:
    ; If object already in progress, always render
    LD IXL, A                               ;store value here (branch for small objects and rows 13 and 14)
    LD L, <AreaObjectLength
    LD A, (HL)
    OR A                                    ;is there something stored here already?
    JP P, RunAObj                           ;if so, branch to do its particular sub
    ; Check if object is on current page
    LD A, (AreaObjectPageLoc)               ;otherwise check to see if the object we've loaded is on the
    LD E, A
    LD A, (CurrentPageLoc) 
    CP A, E                                 ;same page as the renderer, and if so, branch
    
    LD A, (AreaDataOffset)                  ;get old offset of level pointer
    LD E, A
    JR Z, InitRear
    ; Not on current page, so check for row 14 and backload flag
    LD A, (DE)                               ;reload first byte
    AND A, %00001111
    CP A, $0E                               ;row 14?
    RET NZ
    LD A, (BackloadingFlag)                 ;if so, check backloading flag
    OR A
    JR NZ, StrAObj                          ;if set, branch to render object, else leave
    RET
    ; On current page: check backloading initialization
InitRear:
    LD A, (BackloadingFlag)                 ;check backloading flag to see if it's been initialized
    OR A
    JR Z, BackColC                          ;branch to column-wise check
    XOR A                                   ;if not, initialize both backloading and
    LD (BackloadingFlag), A                 ;behind-renderer flags and leave
    LD (BehindAreaParserFlag), A
    LD A, $C0
    LD (ObjectOffset + 1), A
    RET
    ; Check column position
BackColC:
    LD A, (DE)                               ;get first byte again
    AND A, %11110000                        ;mask out low nybble and move high to low
    RRCA
    RRCA
    RRCA
    RRCA
    LD E, A
    LD A, (CurrentColumnPos)
    CP A, E                                 ;is this where we're at?
    RET NZ                                  ;if not, branch to leave
;   Store Object in buffer
StrAObj:
    LD L, <AreaObjOffsetBuffer              ;if so, load area obj offset and store in buffer
    LD A, (AreaDataOffset)
    LD (HL), A
    CALL IncAreaObjOffset                   ;do sub to increment to next object data
;   Execute object code
RunAObj:
    LD A, IXL                               ;get stored value and add offset to it
    ADD A, IXH                              ;then use the jump engine with current contents of A
    RST JumpEngine

;large objects (rows $00-$0b or 00-11, d6-d4 set)
    .dw VerticalPipe         ;used by warp pipes
    .dw AreaStyleObject
    .dw RowOfBricks
    .dw RowOfSolidBlocks
    .dw RowOfCoins
    .dw ColumnOfBricks
    .dw ColumnOfSolidBlocks
    .dw VerticalPipe         ;used by decoration pipes

;objects for special row $0c or 12
    .dw Hole_Empty
    .dw PulleyRopeObject
    .dw Bridge_High
    .dw Bridge_Middle
    .dw Bridge_Low
    .dw Hole_Water
    .dw QuestionBlockRow_High
    .dw QuestionBlockRow_Low

;objects for special row $0f or 15
    .dw EndlessRope
    .dw BalancePlatRope
    .dw CastleObject
    .dw StaircaseObject
    .dw ExitPipe
    .dw FlagBalls_Residual

;small objects (rows $00-$0b or 00-11, d6-d4 all clear)
    .dw QuestionBlock     ;power-up
    .dw QuestionBlock     ;coin
    .dw QuestionBlock     ;hidden, coin
    .dw Hidden1UpBlock    ;hidden, 1-up
    .dw BrickWithItem     ;brick, power-up
    .dw BrickWithItem     ;brick, vine
    .dw BrickWithItem     ;brick, star
    .dw BrickWithCoins    ;brick, coins
    .dw BrickWithItem     ;brick, 1-up
    .dw WaterPipe
    .dw EmptyBlock
    .dw Jumpspring

;objects for special row $0d or 13 (d6 set) [$22]
    .dw IntroPipe
    .dw FlagpoleObject
    .dw AxeObj
    .dw ChainObj
    .dw CastleBridgeObj
    .dw ScrollLockObject_Warp
    .dw ScrollLockObject
    .dw ScrollLockObject
    .dw AreaFrenzy            ;flying cheep-cheeps 
    .dw AreaFrenzy            ;bullet bills or swimming cheep-cheeps
    .dw AreaFrenzy            ;stop frenzy
    .dw LoopCmdE
    .dw CastleCeilingTileY00    ; $0C
    .dw CastleCeilingTileY01
    .dw CastleCeilingTileY02
    .dw CastleCeilingTileY03
    .dw CastleStairsY05
    .dw CastleStairsY06
    .dw CastleStairsY07
    .dw CastleFloorLeftWallY07  ; $13
    .dw CastleFloorLeftY07
    .dw CastleFloorRightWallY07
    .dw CastleFloorRightY07
    .dw CastleFloorLeftWallY08  ; $17
    .dw CastleFloorLeftY08
    .dw CastleFloorRightWallY08
    .dw CastleFloorRightY08
    .dw CastleFloorLeftWallY09  ; $1B
    .dw CastleFloorLeftY09
    .dw CastleFloorRightWallY09
    .dw CastleFloorRightY09
    .dw CastleFloorLeftWallY0A  ; $1F
    .dw CastleFloorLeftY0A
    .dw CastleFloorRightWallY0A
    .dw CastleFloorRightY0A
    .dw CastleFloorRightWallY0B ; $23
    .dw CastleFloorLeftWallY0B  ; $24
    .dw CastleFloorBodyY07      ; $25
    .dw CastleCeilingTileY0B      ; $26
    .dw CastleCeilingTileY05      ; $27

;object for special row $0e or 14           [$45]
    .dw AlterAreaAttributes     

;-------------------------------------------------------------------------------------
;(these apply to all area object subroutines in this section unless otherwise stated)
;$00(IXL) - used to store offset used to find object code
;$07(IXH) - starts with adder from area parser, used to store row offset

CastleCeilingTileY00:
    LD HL, MetatileBuffer
    JP CastleCeilingTileMain

CastleCeilingTileY01:
    LD HL, MetatileBuffer + $01
    JP CastleCeilingTileMain

CastleCeilingTileY02:
    LD HL, MetatileBuffer + $02
    JP CastleCeilingTileMain

CastleCeilingTileY03:
    LD HL, MetatileBuffer + $03
    ; FALL THROUGH

CastleCeilingTileMain:
    LD B, $06   ; metatile buffer length / 2
    LD (HL), MT_CASTLECEILING_S
-:
    INC L
    INC L
    LD A, (HL)
    CP A, MT_CASTLECEILING_L
    JP Z, ReplaceWithSingle
    CP A, MT_CASTLECEILING_R
    RET NZ
ReplaceWithSingle:
    LD (HL), MT_CASTLECEILING_S
    DJNZ -
    RET

CastleCeilingTileY05:
    LD HL, MetatileBuffer + $05
    LD (HL), MT_CASTLECEILING_S
    RET

CastleCeilingTileY0B:
    LD HL, MetatileBuffer + $0B
    LD (HL), MT_CASTLECEILING_S
    RET

;--------------------------------

CastleStairsY05:
    LD C, $02
    LD DE, MetatileBuffer + $05
    JP CastleStairsMain

CastleStairsY06:
    LD C, $03
    LD DE, MetatileBuffer + $06
    JP CastleStairsMain

CastleStairsY07:
    LD C, $04
    LD DE, MetatileBuffer + $07
    ; FALL THROUGH

CastleStairsMain:
    CALL ChkLrgObjFixedLength
    EX DE, HL
    JP NZ, NotLastStair
;
    LD (HL), MT_CASTLESTAIRS_END
    INC L
    LD A, (HL)
    OR A
    JP NZ, RenderUnderStairs
    LD (HL), MT_CASTLESTAIRS_ENDL
    INC L
    JP RenderUnderStairs
;
NotLastStair:
    LD A, (HL)
    OR A
    JP NZ, RenderUnderStairs
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    LD (HL), MT_CASTLESTAIRS_TOP
    JP Z, RenderUnderStairs
    LD (HL), MT_SOLIDBLK_WHITE
    ; FALL THROUGH

RenderUnderStairs:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    LD C, MT_CASTLESTAIRS_BOT
    JP Z, +
    LD C, MT_SOLIDBLK_WHITE
;
+:
    LD B, $03
-:
    LD A, (HL)
    OR A
    JP NZ, +
    LD (HL), C
+:
    INC L
    DJNZ -
    RET

;--------------------------------

CastleFloorLeftWallY07:
    LD HL, MetatileBuffer + $07
    LD B, $04
    JP CastleFloorLeftWallMain

CastleFloorLeftWallY08:
    LD HL, MetatileBuffer + $08
    LD B, $03
    JP CastleFloorLeftWallMain

CastleFloorLeftWallY09:
    LD HL, MetatileBuffer + $09
    LD B, $02
    JP CastleFloorLeftWallMain

CastleFloorLeftWallY0A:
    LD HL, MetatileBuffer + $0A
    LD B, $01
    JP CastleFloorLeftWallMain

CastleFloorLeftWallY0B:
    LD HL, MetatileBuffer + $0B
    LD B, $01
    ; FALL THROUGH

CastleFloorLeftWallMain:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    RET NZ
;
    LD (HL), MT_CASTLEFLOOR_LTOP
    INC L
-:
    LD A, (HL)
    CP A, MT_CASTLEFLOOR_LBOT
    RET Z
    LD (HL), MT_CASTLEFLOOR_LBOT
    INC L
    DJNZ -
    RET

;--------------------------------

CastleFloorLeftY07:
    LD HL, MetatileBuffer + $07
    JP CastleFloorLeftMain

CastleFloorLeftY08:
    LD HL, MetatileBuffer + $08
    JP CastleFloorLeftMain

CastleFloorLeftY09:
    LD HL, MetatileBuffer + $09
    JP CastleFloorLeftMain

CastleFloorLeftY0A:
    LD HL, MetatileBuffer + $0A
    JP CastleFloorLeftMain

CastleFloorLeftY0B:
    LD HL, MetatileBuffer + $0B
    ; FALL THROUGH

CastleFloorLeftMain:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    RET NZ
;
    LD A, (HL)
    CP A, MT_CASTLEFLOOR_TOP
    LD A, MT_CASTLEFLOOR_LTOP
    JP Z, +
    LD A, MT_CASTLEFLOOR_LBOT
+:
    LD (HL), A
    ;
    INC L
    LD (HL), MT_CASTLEFLOOR_LCORNER
    RET

;--------------------------------

CastleFloorRightWallY07:
    LD HL, MetatileBuffer + $07
    LD B, $04
    JP CastleFloorRightWallMain

CastleFloorRightWallY08:
    LD HL, MetatileBuffer + $08
    LD B, $03
    JP CastleFloorRightWallMain

CastleFloorRightWallY09:
    LD HL, MetatileBuffer + $09
    LD B, $02
    JP CastleFloorRightWallMain

CastleFloorRightWallY0A:
    LD HL, MetatileBuffer + $0A
    LD B, $01
    JP CastleFloorRightWallMain

CastleFloorRightWallY0B:
    LD HL, MetatileBuffer + $0B
    LD B, $01
    ; FALL THROUGH

CastleFloorRightWallMain:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    RET NZ
;
    LD (HL), MT_CASTLEFLOOR_RTOP
    INC L
-:
    LD A, (HL)
    CP A, MT_CASTLEFLOOR_RBOT
    RET Z
    LD (HL), MT_CASTLEFLOOR_RBOT
    INC L
    DJNZ -
    RET

;--------------------------------

CastleFloorRightY07:
    LD HL, MetatileBuffer + $07
    JP CastleFloorRightMain

CastleFloorRightY08:
    LD HL, MetatileBuffer + $08
    JP CastleFloorRightMain

CastleFloorRightY09:
    LD HL, MetatileBuffer + $09
    JP CastleFloorRightMain

CastleFloorRightY0A:
    LD HL, MetatileBuffer + $0A
    JP CastleFloorRightMain

CastleFloorRightY0B:
    LD HL, MetatileBuffer + $0B
    ; FALL THROUGH

CastleFloorRightMain:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    RET NZ
;
    LD A, (HL)
    CP A, MT_CASTLEFLOOR_TOP
    LD A, MT_CASTLEFLOOR_RTOP
    JP Z, +
    LD A, MT_CASTLEFLOOR_RBOT
+:
    LD (HL), A
    ;
    INC L
    LD (HL), MT_CASTLEFLOOR_RCORNER
    RET

;--------------------------------

CastleFloorBodyY07:
    LD HL, MetatileBuffer + $07
    LD B, $04
    JP CastleFloorBodyMain

CastleFloorBodyY0B:
    LD HL, MetatileBuffer + $0B
    LD B, $01
    ; FALL THROUGH

CastleFloorBodyMain:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    RET NZ
;
    LD (HL), MT_CASTLEFLOOR_TOP
    INC L
-:
    LD (HL), MT_CASTLEFLOOR_BOT
    INC L
    DJNZ -
    RET

;--------------------------------

AlterAreaAttributes:
    LD HL, (ObjectOffset)
    LD L, <AreaObjOffsetBuffer          
    LD E, (HL)                          ;load offset for level object data saved in buffer
    INC E                               ;load second byte
    LD A, (DE)
    BIT 6, A
    JP NZ, Alter2                       ;branch if d6 is set
    PUSH AF                             ;pull and push offset to copy to A
    AND A, %00001111                    ;mask out high nybble and store as
    LD (TerrainControl), A              ;new terrain height type bits
    LD A, (BackgroundScenery)
    AND A, %00001100                    ;preserve d2 of background scenery
    LD B, A                             ;store in B
    POP AF
    AND A, %00110000                    ;pull and mask out all but d5 and d4
    RRCA                                ;move bits to lower nybble and store
    RRCA                                ;as new background scenery bits
    RRCA
    RRCA
    OR A, B                             ;OR with d2 of original background scenery to preserve bank
    LD (BackgroundScenery), A           ;then leave
    RET
Alter2:
    AND A, %00000111                    ;mask out all but 3 LSB
    CP A, $04                           ;if four or greater, set color control bits
    JP C, SetFore                       ;and nullify foreground scenery bits
    LD (BackgroundColorCtrl), A
    XOR A
SetFore:
    LD (ForegroundScenery), A           ;otherwise set new foreground scenery bits
LoopCmdE:
    RET

;--------------------------------

ScrollLockObject_Warp:
    LD B, $04                           ;load value of 4 for game text routine as default
    LD A, (WorldNumber)                 ;warp zone (4-3-2), then check world number
    OR A
    JP Z, WarpNum
    INC B                               ;if world number > 1, increment for next warp zone (5)
    LD A, (AreaType)                    ;check area type
    DEC A
    JP NZ, WarpNum                      ;if ground area type, increment for last warp zone
    INC B                               ;(8-7-6) and move on
WarpNum:
    LD A, B
    LD (WarpZoneControl), A             ;store number here to be used by warp zone routine
    CALL WriteGameText                  ;print text and warp zone numbers
    LD C, OBJECTID_PiranhaPlant
    CALL KillEnemies                    ;load identifier for piranha plants and do sub
    ; FALL THROUGH

ScrollLockObject:
    LD A, (ScrollLock)                  ;invert scroll lock to turn it on
    XOR A, %00000001
    LD (ScrollLock), A
    RET

;--------------------------------
;$00(C) - used to store enemy identifier

KillEnemies:
    LD B, $05
    LD DE, Enemy_ID_04
    LD HL, Enemy_Flag_04
KillELoop:
    LD A, (DE)                          ;check for identifier in enemy object buffer
    CP A, C                             ;if not found, branch
    JP NZ, NoKillE
    LD (HL), $00                        ;if found, deactivate enemy object flag
NoKillE:
    DEC D                               ;do this until all slots are checked
    DEC H
    DJNZ KillELoop
    RET

;--------------------------------

.SECTION "Frenzy ID Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FrenzyIDData:
    .db OBJECTID_FlyCheepCheepFrenzy, OBJECTID_BBill_CCheep_Frenzy, OBJECTID_Stop_Frenzy
.ENDS

AreaFrenzy:
    LD A, IXL                           ;use area object identifier bit as offset
    SUB A, $08
    LD HL, FrenzyIDData                 ;note that it starts at 8, thus weird address here
    addAToHL8_M
    LD A, (HL)
    LD HL, Enemy_ID_05
    LD B, $06
FreCompLoop:
    DEC H                               ;check regular slots of enemy object buffer
    DJNZ ExitAFrenzy                    ;if all slots checked and enemy object not found, branch to store
    CP A, (HL)                          ;check for enemy object in buffer versus frenzy object
    JP NZ, FreCompLoop
    XOR A                               ;if enemy object already present, nullify queue and leave
ExitAFrenzy:
    LD (EnemyFrenzyQueue), A            ;store enemy into frenzy queue
    RET

;--------------------------------
;$06(IYL) - used by MushroomLedge to store length

AreaStyleObject:
    LD A, (AreaStyle)               ;load level object style and jump to the right sub
    RST JumpEngine

    .dw TreeLedge                   ;also used for cloud type levels
    .dw MushroomLedge
    .dw BulletBillCannon

TreeLedge:
    CALL GetLrgObjAttrib                ;get row and length of green ledge          
    LD L, <AreaObjectLength
    LD A, (HL)                          ;check length counter for expiration
    OR A
    JP Z, EndTreeL
    JP P, MidTreeL
    LD (HL), C                          ;store lower nybble into buffer flag as length of ledge
    LD L, <TreeLedgeLength
    LD (HL), C
    LD A, (CurrentPageLoc)
    LD E, A
    LD A, (CurrentColumnPos)
    OR A, E                             ;are we at the start of the level?
    JP Z, MidTreeL
    LD A, MT_TREELEDGE_LEFT             ;render start of tree ledge
    JP NoUnder
MidTreeL:
    LD B, IXH                           ;render middle of tree ledge
    LD HL, MetatileBuffer               ;note that this is also used if ledge position is
    LD A, B
    addAToHL8_M
    LD (HL), MT_TREELEDGE_MID           ;at the start of level for continuous effect
    ;LD A, MT_TREELEDGE_TRUCK
    ; ALL-STARS
    EX DE, HL
    ; CHECK IF TOTAL LENGTH IS 2
    LD HL, (ObjectOffset)
    LD L, <TreeLedgeLength
    LD A, (HL)
    CP A, $02
    LD A, MT_TREELEDGE_TRUCK_ST
    JP Z, MidTreeLSetMT
    ; CHECK IF AT 1ST COLUMN OF TRUNK
    LD A, (HL)
    LD L, <AreaObjectLength
    SUB A, (HL)
    DEC A
    LD A, MT_TREELEDGE_TRUCK_LT         ; LEFT EDGE
    JP Z, MidTreeLSetMT
    ; CHECK IF LAST COLUMN OF TRUNK
    LD A, (HL)
    DEC A
    LD A, MT_TREELEDGE_TRUCK            ; CENTER
    JP NZ, MidTreeLSetMT
    LD A, MT_TREELEDGE_TRUCK_RT         ; RIGHT EDGE
MidTreeLSetMT:
    INC E
    LD (DE), A
    INC B
    ADD A, $04
    JP AllUnder                         ;now render the part underneath
EndTreeL:
    LD A, MT_TREELEDGE_RIGHT            ;render end of tree ledge
    JP NoUnder

MushroomLedge:
    CALL ChkLrgObjLength                ;get shroom dimensions
    LD IYL, C                           ;store length here for now
    JP NC, EndMushL
    LD A, (HL)                          ;AreaObjectLength
    LD L, <MushroomLedgeHalfLen
    SRL A
    LD (HL), A                          ;divide length by 2 and store elsewhere
    LD A, MT_MUSHROOM_LEFT              ;render start of mushroom
    JP NoUnder
EndMushL:
    LD A, (HL)                          ;AreaObjectLength
    LD C, A
    OR A
    LD A, MT_MUSHROOM_RIGHT             ;if at the end, render end of mushroom
    JP Z, NoUnder
    LD L, <MushroomLedgeHalfLen         ;get divided length and store where length
    LD A, (HL)
    LD IYL, A                           ;was stored originally
    LD B, IXH   ; B <- $07
    LD A, B
    LD HL, MetatileBuffer
    addAToHL8_M
    LD A, MT_MUSHROOM_MID
    LD (HL), A                          ;render middle of mushroom
    LD A, C
    CP A, IYL                           ;are we smack dab in the center?
    RET NZ                              ;if not, branch to leave
    INC L
    INC B
    LD (HL), MT_MSTUMP_TOP              ;render stem top of mushroom underneath the middle
    LD A, MT_MSTUMP_BOT
AllUnder:
    INC B
    LD C, $0F                           ;set $0f to render all way down
    JP RenderUnderPart                  ;now render the stem of mushroom
NoUnder:
    LD B, IXH
    LD C, $00                        ;load row of ledge, set 0 for no bottom on this part
    JP RenderUnderPart      

;--------------------------------

.SECTION "Pulley & Rope Metatile Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;tiles used by pulleys and rope object
PulleyRopeMetatiles:
    .db MT_PULLEY_LEFT, MT_ROPE_HORI, MT_PULLEY_RIGHT
.ENDS

PulleyRopeObject:
    CALL ChkLrgObjLength                ;get length of pulley/rope object
    LD DE, PulleyRopeMetatiles          ;initialize metatile offset
    JP C, RenderPul                     ;if starting, render left pulley
    INC DE
    LD A, (HL)                          ;if not at the end, render rope (AreaObjectLength)
    OR A
    JP NZ, RenderPul
    INC DE                              ;otherwise render right pulley
RenderPul:
    LD A, (DE)
    LD (MetatileBuffer), A              ;render at the top of the screen
    RET

;--------------------------------
;$06(IYL) - used to store upper limit of rows for CastleObject

.SECTION "Castle Metatile Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
CastleMetatiles:
    .db MT_BLANK, MT_CASTLE_TOP_NONPRI, MT_CASTLE_TOP_NONPRI, MT_CASTLE_TOP_NONPRI, MT_BLANK
    .db MT_BLANK, MT_CASTLE_WINDOWRIGHT, MT_CASTLE_BRICK, MT_CASTLE_WINDOWLEFT, MT_BLANK
    .db MT_CASTLE_TOP_NONPRI, MT_CASTLE_TOPBRICK_NONPRI, MT_CASTLE_TOPBRICK_NONPRI, MT_CASTLE_TOPBRICK_NONPRI, MT_CASTLE_TOP_NONPRI
    .db MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK, MT_CASTLE_BRICK
    .db MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK, MT_CASTLE_BRICK

    .db MT_CASTLE_TOPBRICK_NONPRI, MT_CASTLE_TOPBRICK_NONPRI, MT_CASTLE_TOPBRICK_NONPRI, MT_CASTLE_TOPBRICK_NONPRI, MT_CASTLE_TOPBRICK_NONPRI
    .db MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK
    .db MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK
    .db MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_BRICK
    .db MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP
    .db MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT
CastleMetatilesPriority:
    .db MT_BLANK, MT_CASTLE_TOP, MT_CASTLE_TOP, MT_CASTLE_TOP, MT_BLANK
    .db MT_BLANK, MT_CASTLE_WINDOWRIGHT, MT_CASTLE_BRICK_PRI, MT_CASTLE_WINDOWLEFT, MT_BLANK
    .db MT_CASTLE_TOP, MT_CASTLE_TOPBRICK, MT_CASTLE_TOPBRICK, MT_CASTLE_TOPBRICK, MT_CASTLE_TOP
    .db MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK, MT_CASTLE_BRICK
    .db MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK, MT_CASTLE_BRICK

    .db MT_CASTLE_TOPBRICK, MT_CASTLE_TOPBRICK, MT_CASTLE_TOPBRICK, MT_CASTLE_TOPBRICK, MT_CASTLE_TOPBRICK
    .db MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK_PRI, MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK
    .db MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK_PRI, MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK
    .db MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_BRICK, MT_CASTLE_BRICK
    .db MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP, MT_CASTLE_BRICK, MT_CASTLE_ENTRYTOP
    .db MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT, MT_CASTLE_BRICK, MT_CASTLE_ENTRYBOT
.ENDS

CastleObject:
    CALL GetLrgObjAttrib                ;save lower nybble as starting row
    LD IXH, C                           ;if starting row is above $0a, game will crash!!!
    LD C, $04
    CALL ChkLrgObjFixedLength           ;load length of castle if not already loaded
    PUSH HL                             ;save obj buffer offset to stack
    ;LD A, (HL)                          ;use current length as offset for castle data
    LD B, IXH                           ;begin at starting row
    LD IYL, $0B                         ;load upper limit of number of rows to print
    
    LD A, (CurrentPageLoc)
    OR A
    LD A, (HL)
    LD HL, CastleMetatiles
    JP Z, +
    LD HL, CastleMetatilesPriority
+:
    addAToHL8_M
    LD A, B
    LD DE, MetatileBuffer
    addAToDE8_M
CRendLoop:
    LD A, (HL)                          ;load current byte using offset
    LD (DE), A
    INC E                               ;store in buffer and increment buffer offset
    INC B
    LD A, IYL
    OR A
    JP Z, ChkCFloor                     ;have we reached upper limit yet?
    LD A, L                             ;if not, increment column-wise
    ADD A, $05                          ;to byte in next row
    LD L, A
    DEC IYL                             ;move closer to upper limit
ChkCFloor:
    LD A, B
    CP A, $0B                           ;have we reached the row just before floor?
    JP NZ, CRendLoop                    ;if not, go back and do another row
;
    POP HL                              ;get obj buffer offset from before
;
    LD A, (CurrentPageLoc)
    OR A
    RET Z                               ;if we're at page 0, we do not need to do anything
;    
    LD L, <AreaObjectLength
    LD A, (HL)                          ;check length
    CP A, $01                           ;if length almost about to expire, put brick at floor
    JP Z, PlayerStop
    LD A, IXH                           ;check starting row for tall castle ($00) (Y was loaded here)
    OR A
    LD A, (HL)                          ; RELOAD
    JP NZ, NotTall
    CP A, $03                           ;if found, then check to see if we're at the second column
    JP Z, PlayerStop
NotTall:
    CP A, $02                           ;if not tall castle, check to see if we're at the third column
    RET NZ                              ;if we aren't and the castle is tall, don't create flag yet
    CALL GetAreaObjXPosition            ;otherwise, obtain and save horizontal pixel coordinate
    PUSH AF
    CALL FindEmptyEnemySlot             ;find an empty place on the enemy object buffer
    POP AF
    LD (HL), $01                        ;set enemy flag for buffer
    LD L, <Enemy_ID
    LD (HL), OBJECTID_StarFlagObject    ;set star flag value in buffer itself
    LD L, <Enemy_X_Position
    LD (HL), A                          ;then write horizontal coordinate for star flag
    LD L, <Enemy_PageLoc
    LD A, (CurrentPageLoc)
    LD (HL), A                          ;set page location for star flag
    LD L, <Enemy_Y_HighPos
    LD (HL), $01                        ;set vertical high byte
    LD L, <Enemy_Y_Position
    LD (HL), $90                        ;set vertical coordinate
    RET
PlayerStop:
    LD A, MT_BRICK                      ;put brick at floor to stop player at end of level
    LD (MetatileBuffer + $0A), A        ;this is only done if we're on the second column
    RET

;--------------------------------

WaterPipe:
    CALL GetLrgObjAttrib                ;get row and lower nybble
    ;LD B, IXH                           ;get row
    ;LD A, B
    LD A, IXH
    LD HL, MetatileBuffer
    addAToHL8_M
    LD (HL), MT_WATERPIPE_TOP           ;draw something here and below it
    INC L
    LD (HL), MT_WATERPIPE_BOT
    INC L
    INC (HL)
    RET

;--------------------------------
;$05(IYL) - used to store length of vertical shaft in RenderSidewaysPipe
;$06(IYH) - used to store leftover horizontal length in RenderSidewaysPipe
; and vertical length in VerticalPipe and GetPipeHeight

IntroPipe:
    LD C, $03                           ;check if length set, if not set, set it
    CALL ChkLrgObjFixedLength
    LD C, $0A                           ;set fixed value and render the sideways part
    CALL RenderSidewaysPipe
    RET NC                              ;if carry flag isn't set, not time to draw vertical pipe part
;
    LD HL, MetatileBuffer               ;blank everything above the vertical pipe part
    LD DE, MetatileBuffer + $01         ;all the way to the top of the screen
    LD BC, $06                          ;because otherwise it will look like exit pipe
    LD (HL), $00
    LDIR
;
    ;LD A, C
    LD A, IYH
    LD DE, VerticalPipeData
    addAToDE8_M
    LD A, (DE)                          ;draw the end of the vertical pipe part
    LD (MetatileBuffer+7), A
    RET

.SECTION "Side Pipe Metatile Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
SidePipeShaftData:
    ;used to control whether or not vertical pipe shaft
    ;is drawn, and if so, controls the metatile number
    .db MT_PIPESHAFT_RIGHT, MT_PIPESHAFT_LEFT
    .db MT_BLANK, MT_BLANK
SidePipeTopPart:
    ;top part of sideways part of pipe
    .db MT_PIPESHAFT_RIGHT, MT_SIDEPIPE_JOINT_TOP
    .db MT_SIDEPIPE_SHAFT_TOP, MT_SIDEPIPE_END_TOP
SidePipeBottomPart:
    ;bottom part of sideways part of pipe
    .db MT_PIPESHAFT_RIGHT, MT_SIDEPIPE_JOINT_BOT
    .db MT_SIDEPIPE_SHAFT_BOT, MT_SIDEPIPE_END_BOT
.ENDS

ExitPipe:
    LD C, $03                           ;check if length set, if not set, set it
    CALL ChkLrgObjFixedLength
    CALL GetLrgObjAttrib                ;get vertical length, then plow on through RenderSidewaysPipe

RenderSidewaysPipe:
    DEC C                               ;decrement twice to make room for shaft at bottom
    DEC C                               ;and store here for now as vertical length
    LD IYL, C
;
    LD L, <AreaObjectLength
    LD C, (HL)                          ;get length left over and store here
    LD IYH, C
;
    LD B, IYL                           ;get vertical length plus one, use as buffer offset
    INC B
;
    LD A, C
    LD HL, SidePipeShaftData
    addAToHL8_M
    LD A, (HL)                          ;check for value $00 based on horizontal offset
    OR A
    JP Z, DrawSidePart                  ;if found, do not draw the vertical pipe shaf
;
    LD B, $00
    LD C, IYL                           ;init buffer offset and get vertical length
    CALL RenderUnderPart                ;and render vertical shaft using tile number in A
    SCF                                 ;set carry flag to be used by IntroPipe
DrawSidePart:
    PUSH AF                             ;save flags for IntroPipe
    LD C, IYH                           ;render side pipe part at the bottom
;
    LD A, C
    LD HL, SidePipeTopPart
    addAToHL8_M
;
    LD A, B
    LD DE, MetatileBuffer
    addAToDE8_M
;
    LD A, (HL)
    LD (DE), A                          ;note that the pipe parts are stored
;
    LD A, $04
    addAToHL8_M                         ; SidePipeBottomPart
;
    LD A, (HL)                          ;backwards horizontally
    INC E
    LD (DE), A
;
    INC E
    LD A, (DE)
    INC A
    LD (DE), A
;
    POP AF                              ;return flags for IntroPipe
    RET

.SECTION "Vertical Pipe Metatile Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
VerticalPipeData:
    ;used by pipes that lead somewhere
    .db MT_WARPPIPE_TOP_RIGHT, MT_WARPPIPE_TOP_LEFT
    .db MT_PIPESHAFT_RIGHT, MT_PIPESHAFT_LEFT
    ;used by decoration pipes
    .db MT_DECPIPE_TOP_RIGHT, MT_DECPIPE_TOP_LEFT
    .db MT_PIPESHAFT_RIGHT, MT_PIPESHAFT_LEFT
.ENDS

.SECTION "Vertical Pipe Blocks" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
VerticalPipeBlocks:
    .db MT_ROCK, MT_SOLIDBLK_WHITE, MT_SOLIDBLK_3D
.ENDS

VerticalPipe:
    LD C, $01                           ;check for length loaded, if not, load
    CALL ChkLrgObjFixedLength           ;pipe length of 2 (horizontal)
    CALL GetLrgObjAttrib
    LD A, C                             ;get saved lower nybble as height
    AND A, $07                          ;save only the three lower bits as
    LD IYH, A                           ;vertical length, then load Y with
    LD L, <AreaObjectLength
    LD C, (HL)                          ;length left over
;
    LD A, IXL                           ;check to see if value was nullified earlier
    OR A
    JR Z, WarpPipe                      ;(if d3, the usage control bit of second byte, was set)
    INC C
    INC C
    INC C
    INC C                               ;add four if usage control bit was not set
WarpPipe:
    LD A, C                             ;save value in stack
    PUSH AF
    LD A, (WorldNumber)
    LD E, A
    LD A, (AreaNumber)
    OR A, E                             ;if at world 1-1, do not add piranha plant ever
    JR Z, DrawPipe
    LD L, <AreaObjectLength
    LD C, (HL)                          ;if on second column of pipe, branch
    LD A, C
    OR A
    JR Z, DrawPipe                      ;(because we only need to do this once)
    CALL FindEmptyEnemySlot             ;check for an empty moving data buffer space
    JR C, DrawPipe                      ;if not found, too many enemies, thus skip
    CALL GetAreaObjXPosition            ;get horizontal pixel coordinate
    LD (HL), $01                        ;activate enemy flag
    LD L, <Enemy_ID
    LD (HL), OBJECTID_PiranhaPlant      ;write piranha plant's value into buffer
    LD L, <Enemy_X_Position
    ADD A, $08                          ;add eight to put the piranha plant in the center
    LD (HL), A                          ;store as enemy's horizontal coordinate
    LD A, (CurrentPageLoc)              ;add carry to current page number
    LD L, <Enemy_PageLoc
    ADC A, $00
    LD (HL), A                          ;store as enemy's page coordinate
    LD L, <Enemy_Y_HighPos
    LD (HL), $01
    CALL GetAreaObjYPosition            ;get piranha plant's vertical coordinate and store here
    LD L, <Enemy_Y_Position
    LD (HL), A
    CALL InitPiranhaPlant_NOPOP
DrawPipe:
    LD A, IXL
    CPL
    LD C, A
    LD A, (AltEntranceControl)          ;AltEntranceControl != 0 OR ~IXL != 0
    OR A, C
    JR Z, DrawPipe_1
;   FOR BLOCKS UNDER PIPESHAFT (TERRAIN)
    LD A, IXH
    INC A
    ADD A, IYH
    LD DE, MetatileBuffer
    addAToDE8_M
    LD A, (DE)
    LD HL, VerticalPipeBlocks
    LD BC, $0003
    CPIR
    JP PO, DrawPipe_1
    INC A
    LD (DE), A
DrawPipe_1:
    POP AF                              ;get value saved earlier and use as Y
    LD HL, VerticalPipeData
    addAToHL8_M
    LD B, IXH                           ;get buffer offset
    LD A, B
    LD DE, MetatileBuffer
    addAToDE8_M
    LD A, (HL)                          ;draw the appropriate pipe with the Y we loaded earlier
    LD (DE), A                          ;render the top of the pipe
    INC B
    INC E
    INC HL
    INC HL
    LD A, (HL)                          ;render the rest of the pipe
    LD C, IYH                           ;subtract one from length and render the part underneath
    DEC C
    JP RenderUnderPart
      
FindEmptyEnemySlot:
    LD HL, Enemy_Flag                   ;start at first enemy slot
EmptyChkLoop:
    LD A, (HL)                          ;check enemy buffer for nonzero
    OR A                                ;clear carry flag by default
    RET Z                               ;if zero, leave
    INC H                               ;if nonzero, check next value
    LD A, H
    CP A, $C5 + $01                     ;(SMS) add 1 since Enemy_Flag starts on RAM page $C1
    JP NZ, EmptyChkLoop
    SCF                                 ;if all values nonzero, carry flag is set
    RET

;--------------------------------

Hole_Water:
    CALL ChkLrgObjLength                ;get low nybble and save as length
    LD A, (AreaType)
    CP A, $03
    LD A, MT_WATER_TOP                  ;render waves
    JP NZ, +
    LD A, MT_LAVA_TOP
+:
    LD (MetatileBuffer+10), A
    LD BC, $0B01                        ;now render the water underneath
    INC A
    JP RenderUnderPart

;--------------------------------

QuestionBlockRow_High:
    LD A, $03                           ;start on the fourth row
    JP QuestionBlockRow_Low@SaveRow

QuestionBlockRow_Low:
    LD A, $07                           ;start on the eighth row
@SaveRow:
    PUSH AF                             ;save whatever row to the stack for now
    CALL ChkLrgObjLength                ;get low nybble and save as length
    POP AF
    ;LD B, A                             ;render question boxes with coins
    LD HL, MetatileBuffer
    addAToHL8_M
    LD (HL), MT_QBLK_COIN
    RET

;--------------------------------

Bridge_High:
    LD B, $06                           ;start on the seventh row from top of screen
    JP Bridge_Low@SaveRow

Bridge_Middle:
    LD B, $07                           ;start on the eighth row
    JP Bridge_Low@SaveRow

Bridge_Low:
    LD B, $09                           ;start on the tenth row
@SaveRow:
    CALL ChkLrgObjLength                ;get low nybble and save as length
    LD A, B
    LD HL, MetatileBuffer
    JP Z, EndBridge
    JP P, MidBridge
    addAToHL8_M
    LD (HL), MT_RAIL_LEFT               ;render bridge railing
    JP RenderBridge
MidBridge:
    addAToHL8_M
    LD (HL), MT_RAIL_MID                ;render bridge railing
    JP RenderBridge
EndBridge:
    addAToHL8_M
    LD (HL), MT_RAIL_RIGHT              ;render bridge railing
RenderBridge:
    INC B
    LD C, $00                           ;now render the bridge itself
    LD A, MT_BRIDGE
    JP RenderUnderPart

;--------------------------------

FlagBalls_Residual:
    CALL GetLrgObjAttrib                ;get low nybble from object byte
    LD B, $02                           ;render flag balls on third row from top
    LD A, MT_UNUSEDFLAG                 ;of screen downwards based on low nybble
    JP RenderUnderPart

;--------------------------------

FlagpoleObject:
    LD A, MT_FLAGPOLE_BALL
    LD (MetatileBuffer), A              ;render flagpole ball on top
    LD BC, $0108                        ;now render the flagpole shaft
    LD A, MT_FLAGPOLE_SHAFT
    CALL RenderUnderPart
    LD A, MT_SOLIDBLK_3D                ;render solid block at the bottom
    LD (MetatileBuffer+10), A
    CALL GetAreaObjXPosition
    SUB A, $08                          ;get pixel coordinate of where the flagpole is, subtract eight pixels and use as horizontal
    LD (Enemy_X_Position+5*$100), A          ;coordinate for the flag
    LD A, (CurrentPageLoc)
    SBC A, $00                          ;subtract borrow from page location and use as
    LD (Enemy_PageLoc+5*$100), A             ;page location for the flag
    LD A, $30
    LD (Enemy_Y_Position+5*$100), A          ;set vertical coordinate for flag
    LD A, $B0
    LD (FlagpoleFNum_Y_Pos), A          ;set initial vertical coordinate for flagpole's floatey number
    LD A, OBJECTID_FlagpoleFlagObject
    LD (Enemy_ID+5*$100), A                  ;set flag identifier, note that identifier and coordinates
    LD A, $01                           ;use last space in enemy object buffer
    LD (Enemy_Flag+5*$100), A
    RET

;--------------------------------

EndlessRope:
    LD BC, $000F                        ;render rope from the top to the bottom of screen
    JP DrawRope

BalancePlatRope:
    ;PUSH HL                            ;save object buffer offset for now
    LD BC, $010F                        ;blank out all from second row to the bottom
    LD A, MT_PULLEY_BLANK               ;with blank used for balance platform rope
    CALL RenderUnderPart
    ;POP HL                             ;get back object buffer offset
    CALL GetLrgObjAttrib                ;get vertical length from lower nybble
    LD B, $01
DrawRope:
    LD A, MT_ROPE_VERT                  ;render the actual rope
    JP RenderUnderPart

;--------------------------------

.SECTION "Coin Metatile Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
CoinMetatileData:
    .db MT_WATERCOIN, MT_COIN, MT_COIN, MT_COIN
.ENDS

RowOfCoins:
    LD A, (OptionBitflags)              ;always load watercoin if doing NES GFX
    AND A, bitValue(OPTFLAG_GFX)
    LD A, MT_WATERCOIN
    JP NZ, GetRow
;
    LD A, (AreaType)                    ;get area type
    LD DE, CoinMetatileData
    addAToDE8_M
    LD A, (DE)                          ;load appropriate coin metatile
    JP GetRow

;--------------------------------

.SECTION "Castle Object Row and Metatile TBLs" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
C_ObjectRow:
    .db $00, $00                        ;padding
    .db $06, $07, $08

C_ObjectMetatile:
    .db MT_AXE, MT_CHAIN, MT_BOWSERBRIDGE
.ENDS

CastleBridgeObj:
    LD C, $0C                           ;load length of 13 columns
    CALL ChkLrgObjFixedLength
    JP ChainObj

AxeObj:
    ; LD A, VRAMTBL_BOWSERPAL             ;load bowser's palette into sprite portion of palette
    ; LD (VRAM_Buffer_AddrCtrl), A

ChainObj:
    LD C, IXL                           ;get value loaded earlier from decoder                 
    LD A, C
    LD DE, C_ObjectRow
    addAToDE8_M
    LD A, (DE)                          ;get appropriate row and metatile for object
    LD B, A
    INC E
    INC E
    INC E
    LD A, (DE)
    JP ColObj

EmptyBlock:
    CALL GetLrgObjAttrib                ;get row location
    LD B, IXH
    LD A, MT_EMPTYBLK
ColObj:
    LD C, $00                           ;column length of 1
    JP RenderUnderPart        

;--------------------------------

.SECTION "Solid Block Metatile TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
SolidBlockMetatiles:
    .db MT_SOLIDBLK_WATER, MT_SOLIDBLK_3D, MT_SOLIDBLK_3D, MT_SOLIDBLK_WHITE

SolidBlockMetatilesPriority:
    .db MT_SOLIDBLK_WATER, MT_SOLIDBLK_3D_PRI, MT_SOLIDBLK_3D_PRI, MT_SOLIDBLK_WHITE
.ENDS

.SECTION "Brick Metatile TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
BrickMetatiles:
    .db MT_SEAPLANT, MT_SBRICK, MT_BRICK, MT_BRICK
    .db MT_CLOUDGND ;used only by row of bricks object
.ENDS

RowOfBricks:
    LD A, (AreaType)                    ;load area type obtained from area offset pointer
    LD C, A
    LD A, (CloudTypeOverride)           ;check for cloud type override
    OR A
    JP Z, DrawBricks
    LD C, $04                           ;if cloud type, override area type
DrawBricks:
    LD A, C
    LD DE, BrickMetatiles
    addAToDE8_M
    LD A, (DE)                          ;get appropriate metatile
    JP GetRow                           ;and go render it

RowOfSolidBlocks:
    CALL ChkLrgObjLength
    LD DE, SolidBlockMetatiles
    LD A, IXH
    DEC A
    LD HL, MetatileBuffer
    addAToHL8_M
    LD A, (HL)
    CP A, MT_PIPESHAFT_LEFT
    JP Z, +
    CP A, MT_PIPESHAFT_RIGHT
    JP NZ, RowOfSolidBlocks_0
+:
    LD E, <SolidBlockMetatilesPriority
RowOfSolidBlocks_0:
    LD A, (AreaType)                    ;load area type obtained from area offset pointer
    addAToDE8_M
    LD A, (DE)                          ;get metatile
GetRow:
    PUSH AF                             ;store metatile here
    CALL ChkLrgObjLength                ;get row number, load length
DrawRow:
    LD B, IXH
    LD C, $00                           ;set vertical height of 1
    POP AF
    JP RenderUnderPart                  ;render object

ColumnOfBricks:
    LD A, (AreaType)                    ;load area type obtained from area offset
    LD DE, BrickMetatiles
    addAToDE8_M
    LD A, (DE)                          ;get metatile (no cloud override as for row)
    JP GetRow2

ColumnOfSolidBlocks:
    LD A, (AreaType)                    ;load area type obtained from area offset
    LD DE, SolidBlockMetatiles
    addAToDE8_M
    LD A, (DE)                          ;get metatile
GetRow2:
    PUSH AF                             ;save metatile to stack for now
    CALL GetLrgObjAttrib                ;get length and row
    POP AF                              ;restore metatile
    LD B, IXH                           ;get starting row
    JP RenderUnderPart                  ;now render the column

;--------------------------------

BulletBillCannon:
    CALL GetLrgObjAttrib                ;get row and length of bullet bill cannon
    LD B, IXH                           ;start at first row
    LD A, B
    LD HL, MetatileBuffer
    addAToHL8_M
    LD (HL), MT_BBILL_BARR              ;render bullet bill cannon
    INC B
    INC L
    DEC C                               ;done yet?
    JP M, SetupCannon
    LD (HL), MT_BBILL_TOP               ;if not, render middle part
    INC B
    INC L
    DEC C                               ;done yet?
    JP M, SetupCannon
    LD A, MT_BBILL_BOT                  ;if not, render bottom until length expires
    CALL RenderUnderPart
SetupCannon:
    LD A, (Cannon_Offset)               ;get offset for data used by cannons and whirlpools
    ADD A, >Cannon_Y_Position           ;(SMS) set high byte for RAM address (offset)
    LD H, A
    CALL GetAreaObjYPosition            ;get proper vertical coordinate for cannon
    LD L, <Cannon_Y_Position
    LD (HL), A                          ;and store it here
    LD L, <Cannon_PageLoc
    LD A, (CurrentPageLoc)
    LD (HL), A                          ;store page number for cannon here
    CALL GetAreaObjXPosition            ;get proper horizontal coordinate for cannon
    LD L, <Cannon_X_Position
    LD (HL), A                          ;and store it here
    INC H
    LD A, H
    CP A, >Cannon_Y_Position + $06      ;increment and check offset
    JP C, StrCOffset                    ;if not yet reached sixth cannon, branch to save offset
    LD A, >Cannon_Y_Position            ;otherwise initialize it
StrCOffset:
    SUB A, >Cannon_Y_Position
    LD (Cannon_Offset), A               ;save new offset and leave
    RET

;--------------------------------

.SECTION "Staircase Height TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
StaircaseHeightData:
    .db $07, $07, $06, $05, $04, $03, $02, $01, $00
.ENDS

.SECTION "Staircase Row TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
StaircaseRowData:
    .db $03, $03, $04, $05, $06, $07, $08, $09, $0a
.ENDS

StaircaseObject:
    CALL ChkLrgObjLength                ;check and load length
    LD HL, StaircaseControl
    JP NC, NextStair                    ;if length already loaded, skip init part
    LD (HL), $09                        ;start past the end for the bottom of the staircase
NextStair:
    DEC (HL)                            ;move onto next step (or first if starting)
    LD C, (HL)
    LD A, C
    LD HL, StaircaseRowData
    addAToHL8_M
    LD B, (HL)                          ;get starting row and height to render
    LD A, C
    LD HL, StaircaseHeightData
    addAToHL8_M
    LD C, (HL)
    LD A, MT_SOLIDBLK_3D                ;now render solid block staircase
    JP RenderUnderPart

;--------------------------------

Jumpspring:
    CALL GetLrgObjAttrib
    CALL FindEmptyEnemySlot             ;find empty space in enemy object buffer
    
    .IF PALBUILD != $00
    RET C                               ;PAL bugfix: Stop if there are no free enemy slots
    .ENDIF

    LD A, $FF
    LD (JumpspringAnimCtrl_Old), A
    LD (HL), $01                        ;set flag for enemy object buffer
    LD L, <Enemy_ID
    LD (HL), OBJECTID_JumpspringObject  ;write jumpspring object to enemy object buffer
    CALL GetAreaObjXPosition            ;get horizontal coordinate for jumpspring
    LD L, <Enemy_X_Position
    LD (HL), A                          ;and store
    LD L, <Enemy_PageLoc
    LD A, (CurrentPageLoc)              ;store page location of jumpspring
    LD (HL), A
    CALL GetAreaObjYPosition            ;get vertical coordinate for jumpspring
    LD L, <Enemy_Y_Position
    LD (HL), A                          ;and store
    LD L, <Jumpspring_FixedYPos
    LD (HL), A                          ;store as permanent coordinate here
    LD L, <Enemy_Y_HighPos
    LD (HL), $01                        ;store vertical high byte
    ;LD B, IXH
    ;LD A, B
    LD A, IXH
    LD HL, MetatileBuffer
    addAToHL8_M
    LD (HL), MT_SPRING_BLANK            ;draw metatiles in two rows where jumpspring is
    INC L
    LD (HL), MT_SPRING_HALF
    RET

;--------------------------------
;$07(IXH) - used to save ID of brick object

Hidden1UpBlock:
    LD A, (Hidden1UpFlag)               ;if flag not set, do not render object
    OR A
    RET Z
    XOR A                               ;if set, init for the next one
    LD (Hidden1UpFlag), A
    JP BrickWithItem                    ;jump to code shared with unbreakable bricks

QuestionBlock:
    LD A, IXL                           ;get value saved from area parser routine
    LD C, A                             ;save to Y
    JP DrawQBlk                         ;go to render it

BrickWithCoins:
    XOR A                               ;initialize multi-coin timer flag
    LD (BrickCoinTimerFlag), A

BrickWithItem:
    LD A, IXL                           ;get value saved from area parser routine
    LD C, A                             ;save to Y
    LD IXH, C
    LD A, (AreaType)                    ;check level type for ground level
    DEC A
    LD A, $00                           ;load default adder for bricks with lines
    JP Z, BWithL                        ;if ground type, do not start with 5
    LD A, $05                           ;otherwise use adder for bricks without lines
BWithL:
    ADD A, IXH                          ;add object ID to adder
    LD C, A                             ;use as offset for metatile
DrawQBlk:
    LD A, C
    LD DE, BrickQBlockMetatiles
    addAToDE8_M
    LD A, (DE)                          ;get appropriate metatile for brick (question block
    PUSH AF                             ;if branched to here from question block routine)
    CALL GetLrgObjAttrib                ;get row from location byte
    JP DrawRow                          ;now render the object

;--------------------------------

; .SECTION "Hole Metatile TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
; HoleMetatiles:
;     .db MT_WATER, MT_BLANK, MT_BLANK, MT_BLANK
; .ENDS

Hole_Empty:
    CALL ChkLrgObjLength                ;get lower nybble and save as length
    LD A, (AreaType)                    ;check for water type level
    DEC A
    JP P, NoWhirlP                      ;if not water type, skip this part
    RET NC                              ;skip this part if length already loaded
;
    LD A, (Whirlpool_Offset)            ;get offset for data used by cannons and whirlpools
    ADD A, >Whirlpool_LeftExtent        ;(SMS) set high byte of RAM address (index)
    LD H, A
;
    CALL GetAreaObjXPosition            ;get proper vertical coordinate of where we're at
    LD L, <Whirlpool_LeftExtent
    SUB A, $10                          ;subtract 16 pixels
    LD (HL), A                          ;store as left extent of whirlpool
    LD A, (CurrentPageLoc)              ;get page location of where we're at
    SBC A, $00                          ;subtract borrow
    LD L, <Whirlpool_PageLoc
    LD (HL), A                          ;save as page location of whirlpool
    INC C
    INC C                               ;increment length by 2
    LD A, C
    ADD A, A                            ;multiply by 16 to get size of whirlpool
    ADD A, A                            ;note that whirlpool will always be
    ADD A, A                            ;two blocks bigger than actual size of hole
    ADD A, A                            ;and extend one block beyond each edge
    LD L, <Whirlpool_Length
    LD (HL), A                          ;save size of whirlpool here
    INC H                               
    LD A, H
    CP A, >Whirlpool_Length + $05       ;increment and check offset
    JR C, StrWOffset                    ;if not yet reached fifth whirlpool, branch
    LD A, >Whirlpool_Length             ;otherwise initialize it
StrWOffset:
    SUB A, >Whirlpool_Length
    LD (Whirlpool_Offset), A            ;save new offset here
    RET
    
NoWhirlP:
    ;LD A, (AreaType)                    ;get appropriate metatile, then
    ;LD HL, HoleMetatiles
    ;addAToHL8_M
    ;LD A, (HL)                          ;render the hole proper
    LD A, MT_BLANK
    LD BC, $080F                        ;start at ninth row and go to bottom, run RenderUnderPart
    ; FALL THROUGH

;--------------------------------

; Y(C) = number of tiles to draw
; X(B) = Y position of the first tile to draw
; A = tile number to draw
RenderUnderPart:
    LD E, A                             ;save metatile id to E
    LD A, B                             ;calculate offset into MetatileBuffer
    LD HL, MetatileBuffer
    addAToHL8_M
@loop:
    LD A, (HL)                          ;check current spot to see if there's something
    OR A
    JR Z, DrawThisRow                   ;we need to keep, if nothing, go ahead
    CP A, MT_TREELEDGE_MID
    JR Z, WaitOneRow                    ;if middle part (tree ledge), wait until next row
    CP A, MT_MUSHROOM_MID
    JR Z, WaitOneRow                    ;if middle part (mushroom ledge), wait until next row
    CP A, MT_QBLK_COIN
    JR Z, DrawThisRow                   ;if question block w/ coin, overwrite
;
    CP A, MT_TREELEDGE_TRUCK            ;don't overwrite the center tiles of the tree trunk
    JR Z, WaitOneRow
    CP A, MT_TREELEDGE_TRUCK_CB
    JR Z, WaitOneRow
;
    CP A, MT_QBLK_COIN
    JR NC, WaitOneRow                   ;if any other metatile with palette 3, wait until next row
    CP A, MT_ROCK
    JR NZ, DrawThisRow                  ;if cracked rock terrain, overwrite
    LD A, E
    CP A, MT_MSTUMP_BOT
    JR Z, WaitOneRow                    ;if stem top of mushroom, wait until next row
DrawThisRow:
    LD (HL), E                          ;render contents of A from routine that called this
WaitOneRow:
    INC L
    INC B
    LD A, B
    CP A, $0D                           ;stop rendering if we're at the bottom of the screen
    RET NC
    DEC C                               ;decrement, and stop rendering if there is no more length
    JP P, RenderUnderPart@loop
    RET

;--------------------------------

ChkLrgObjLength:
    CALL GetLrgObjAttrib            ;get row location and size (length if branched to from here)

ChkLrgObjFixedLength:
    LD HL, (ObjectOffset)
    LD L, <AreaObjectLength
    LD A, (HL)                      ;check for set length counter
    OR A                            ;clear carry flag for not just starting
    RET P                           ;if counter not set, load it, otherwise leave alone
    LD (HL), C                      ;save length into length counter
    SCF                             ;set carry flag if just starting
    RET

GetLrgObjAttrib:
    LD HL, (ObjectOffset)
    LD L, <AreaObjOffsetBuffer      ;get offset saved from area obj decoding routine
    LD A, (HL)
    LD E, A                         ;get first byte of level object
    LD D, >AreaDataBank
    LD A, (DE)
    AND A, %00001111
    LD IXH, A                       ;save row location
    INC E
    LD A, (DE)                      ;get next byte, save lower nybble (length or height)
    AND A, %00001111                ;as Y, then leave
    LD C, A 
    RET

;--------------------------------

GetAreaObjXPosition:
    LD A, (CurrentColumnPos)    ;multiply current offset where we're at by 16
    ADD A, A                    ;to obtain horizontal pixel coordinate
    ADD A, A
    ADD A, A
    ADD A, A
    RET

;--------------------------------

GetAreaObjYPosition:
    LD A, IXH                   ;multiply value by 16
    ADD A, A
    ADD A, A                    ;this will give us the proper vertical pixel coordinate
    ADD A, A
    ADD A, A
    ADD A, $20                  ;add 32 pixels for the status bar
    RET

;-------------------------------------------------------------------------------------
;$06-$07 - used to store block buffer address used as indirect

;   A - Offset into the buffer (High nibble - block buffer x, Low Nibble - Column)
; GetBlockBufferAddr:
;     LD DE, Block_Buffer_1
;     BIT 4, A
;     JP Z, +
;     LD E, <Block_Buffer_2
; +:
;     AND A, $0F              ;mask out high nybble
;     addAToDE8_M             ;add to low byte    
;     LD (Temp_Bytes + $06), DE
;     RET

;-------------------------------------------------------------------------------------
;$00 - temp vram buffer offset
;$01 - temp metatile buffer offset
;$02 - temp metatile graphics table offset
;$03 - used to store attribute bits
;$04 - used to determine attribute table row
;$05 - used to determine attribute table column
;$06 - metatile graphics table address low
;$07 - metatile graphics table address high

;BC = X/Y
;DE,IX,IY = 00/01,02/03,04/05
;HL = 06/07

.SECTION "Metatile Graphics TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
MetatileGraphics:
    .dw Palette0_MTiles, Palette1_MTiles, Palette2_MTiles, Palette3_MTiles
.ENDS

RenderAreaGraphics:
    LD BC, MetatileBuffer-1
    LD A, (ColumnSets)
    CP A, $04
    LD HL, (VRAM_Buffer2_Ptr)
    JP P, +
    LD HL, (ColumnUpdate_Ptr)
+:
;   SET INITIAL ADDRESS AND COUNT FOR BUFFER
    LD DE, (CurrentNTAddr)              ;get current name table address we're supposed to render
    LD (HL), D                          ;write high byte
    INC L
    LD (HL), E                          ;write low byte
;
    EX DE, HL
;   CALCULATE OFFSET FOR DRAWING EITHER LEFT OR RIGHT SIDE OF METATILE
    LD A, (AreaParserTaskNum)
    CPL
    AND A, %00000001
    ADD A, A                            ;then add to the tile offset so we can draw either side
    LD IXL, A                           ;of the metatiles
;
    LD IXH, $0C                         ;loop counter, amount of metatiles on screen vertically
DrawMTLoop:
    INC C
    INC E
    LD A, (BC)                          ;get first metatile number, and mask out all but 2 MSB
    AND A, %11000000
    RLCA                                ;note that metatile format is:
    RLCA                                ;%xx000000 - attribute table bits,
    ADD A, A                            ;rotate bits to d1-d0 and use as offset here
    LD HL, MetatileGraphics
    addAToHL8_M
    LD A, (HL)                          ;get address to graphics table from here
    INC L
    LD H, (HL)
    LD L, A
    ;
    LD A, (BC)                          ;get metatile number again
    ADD A, A                            ;multiply by 4 and use as tile offset
    ADD A, A
    ADD A, IXL                          ;add column position
    ADD A, A                            ;NOTICE: Overflow can occur here
    JP NC, +
    INC H
+:
    addAToHL_M
    LD A, (HL)                          ;get first tile number (top left or top right) and store
    LD (DE), A
    INC E
    INC L
    LD A, (HL)
    LD (DE), A
    INC E
    INC L
    LD A, (HL)                          ;now get the second (bottom left or bottom right) and store
    LD (DE), A
    INC E
    INC L
    LD A, (HL)
    LD (DE), A
    INC L
    ;
    DEC IXH
    JP NZ, DrawMTLoop                   ;if not there yet, loop back
    ;
    DEC E
    XOR A
    LD (DE), A
    ;
    LD HL, CurrentNTAddr                ;increment name table address low
    INC (HL)
    INC (HL)
    LD A, (HL)                          ;check current low byte
    AND A, %00111111                    ;if no wraparound, just skip this part
    JP NZ, SetVRAMCtrl
    LD (HL), $40                        ;if wraparound occurs, make sure low byte stays
SetVRAMCtrl:
    LD A, VRAMTBL_BUFFER2
    LD (VRAM_Buffer_AddrCtrl), A

    LD A, D
    CP A, >VRAM_Buffer2
    JP NZ, +
    LD (VRAM_Buffer2_Ptr), DE
    RET
+:
    LD HL, ColumnUpdate_Ptr + $01
    INC (HL)
    LD A, (HL)
    CP A, >ColumnBuffer_0F + $01
    RET NZ
    LD (HL), >ColumnBuffer
    RET

;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------

LoadAreaPointer:
    CALL FindAreaPointer    ;find it and store it here
    LD (AreaPointer), A

GetAreaType:
    AND A, %01100000        ;mask out all but d6 and d5
    RLCA
    RLCA
    RLCA                    ;make %0xx00000 into %000000xx        
    LD (AreaType), A        ;save 2 MSB as area type
    RET

FindAreaPointer:
    LD A, (WorldNumber)     ;load offset from world variable
    ADD A, A
    LD HL, WorldAddrOffsets
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    ;
    LD A, (AreaNumber)
    addAToHL8_M
    LD A, (HL)              ;from there we have our area pointer
    RET

GetAreaDataAddrs:
;   Calculate AreaType for current level (used as index into EnemyAddrHOffsets/AreaDataHOffsets)
    LD A, (AreaPointer)             ;use 2 MSB for Y
    CALL GetAreaType
    LD B, A
;   Calculate index into EnemyDataAddr/AreaDataAddr
    LD A, (AreaPointer)             ;mask out all but 5 LSB
    AND A, %00011111
    LD (AreaAddrsLOffset), A        ;save as low offset
;   Calculate EnemyData pointer for current level
    LD A, B                         ;use area type as offset
    LD HL, EnemyAddrHOffsets
    addAToHL8_M
    LD A, (AreaAddrsLOffset)        ;load base value with 2 altered MSB,
    ADD A, (HL)                     ;then add base value to 5 LSB, result becomes offset for level data
    ADD A, A
    LD HL, EnemyDataAddr            ;use offset to load pointer
    addAToHL8_M
    LD A, (HL)
    INC HL
    LD H, (HL)
    LD L, A
    PUSH HL
;   Calculate AreaData pointer for current level
    LD A, B                         ;use area type as offset
    LD HL, AreaDataHOffsets         ;do the same thing but with different base value
    addAToHL8_M
    LD A, (AreaAddrsLOffset)
    ADD A, (HL)
    ADD A, A
    LD HL, AreaDataAddr             ;use this offset to load another pointer
    addAToHL8_M
    LD A, (HL)
    INC HL
    LD H, (HL)
    LD L, A
;   Parse the two header bytes of AreaData
    LD A, BANK_AREAENEMY            ;set bank
    LD (MAPPER_SLOT2), A
    LD A, (HL)                      ;load first byte of header
    LD B, A
    AND A, %00000111                ;save 3 LSB for foreground scenery or bg color control
    CP A, $04
    JP C, @StoreFore
    LD (BackgroundColorCtrl), A     ;if 4 or greater, save value here as bg color control
    XOR A
@StoreFore:
    LD (ForegroundScenery), A       ;if less, save value here as foreground scenery
    LD A, B
    AND A, %00111000                ;save player entrance control bits
    RRCA                            ;shift bits over to LSBs
    RRCA
    RRCA
    LD (PlayerEntranceCtrl), A      ;save value here as player entrance control
    LD A, B                         ;pull byte again but do not push it back
    AND A, %11000000                ;save 2 MSB for game timer setting
    RLCA                            ;rotate bits over to LSBs
    RLCA
    LD (GameTimerSetting), A        ;save value here as game timer setting
    INC HL
    LD A, (HL)                      ;load second byte of header
    LD B, A                         ;save
    AND A, %00001111                ;mask out all but lower nybble
    LD (TerrainControl), A
    LD A, B
    AND A, %00110000                ;save 2 MSB for background scenery type
    RRCA                            ;shift bits to LSBs
    RRCA
    RRCA
    RRCA
    LD (BackgroundScenery), A       ;save as background scenery
    LD A, B
    AND A, %11000000
    RLCA                            ;rotate bits over to LSBs
    RLCA
    CP A, %00000011                 ;if set to 3, store here
    JP NZ, @StoreStyle              ;and nullify other value
    LD (CloudTypeOverride), A       ;otherwise store value in other place
    LD (BonusAreaFlag), A
    XOR A
@StoreStyle:
    LD (AreaStyle), A
    ; Correct palette on w6-3 (only for default gfx)
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JP NZ, +
    LD A, (BackgroundColorCtrl)
    CP A, $07
    JP NZ, +
    LD A, $04
    LD (BackgroundColorCtrl), A
+:
    ; POTENTIAL 3RD BYTE
    INC HL
    LD A, (HL)
    LD B, A
    AND A, $F0
    CP A, $F0
    JP NZ, +
    LD A, (BackgroundScenery)
    LD C, A
    LD A, B
    AND A, %00000011
    RLCA
    RLCA
    OR A, C
    LD (BackgroundScenery), A
;   Upload AreaData to aligned area in RAM
    INC HL
+:
;
    LD A, (TitleLoadedFlag)         ;skip copying level data to RAM
    OR A                            ;if past initial load on title screen
    JP NZ, +
;
    LD DE, AreaDataBank
    LD BC, $0100
    LDIR
;   Upload EnemyData to aligned area in RAM
    POP HL
    LD BC, $0100
    LDIR
;   Restore bank
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
;   set bonus area flag for underground coin room (FM only)
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    RET Z
    LD A, (AreaPointer)
    AND A, $7F
    CP A, $42
    RET NZ
    LD (BonusAreaFlag), A
    RET

+:
    POP HL
;   Restore bank
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    RET


.SECTION "World Offsets into AreaAddrOffsets" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   ----- GAME LEVEL POINTERS -----
WorldAddrOffsets:
    .dw World1Areas, World2Areas
    .dw World3Areas, World4Areas
    .dw World5Areas, World6Areas
    .dw World7Areas, World8Areas
.ENDS

.SECTION "Level Offsets into Area/Enemy DataAddr and HOffsets" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
AreaAddrOffsets:
;   D6,D5 ARE AREA TYPE
;   D4,D3,D2,D1,D0 ARE INDEX OF AREATYPE LIST
World1Areas: .db $25, $29, $c0, $26, $60
World2Areas: .db $28, $29, $01, $27, $62
World3Areas: .db $24, $35, $20, $63
World4Areas: .db $22, $29, $41, $2c, $61
World5Areas: .db $2a, $31, $26, $62
World6Areas: .db $2e, $23, $2d, $60
World7Areas: .db $33, $29, $01, $27, $64
World8Areas: .db $30, $32, $21, $65
.ENDS

;bonus area data offsets, included here for comparison purposes
;underground bonus area  - c2
;cloud area 1 (day)      - 2b
;cloud area 2 (night)    - 34
;water area (5-2/6-2)    - 00
;water area (8-4)        - 02
;warp zone area (4-2)    - 2f

.SECTION "AreaType Offsets into EnemyDataAddr" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   STARTING INDEXES OF AREATYPES (WATER, OVERWORLD, UNDERGROUND, CASTLE)
EnemyAddrHOffsets:
    .db $1f, $06, $1c, $00
.ENDS

.SECTION "Enemy Data Pointers" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
EnemyDataAddr:
    .dw E_CastleArea1, E_CastleArea2, E_CastleArea3, E_CastleArea4, E_CastleArea5, E_CastleArea6
    .dw E_GroundArea1, E_GroundArea2, E_GroundArea3, E_GroundArea4, E_GroundArea5, E_GroundArea6
    .dw E_GroundArea7, E_GroundArea8, E_GroundArea9, E_GroundArea10, E_GroundArea11, E_GroundArea12
    .dw E_GroundArea13, E_GroundArea14, E_GroundArea15, E_GroundArea16, E_GroundArea17, E_GroundArea18
    .dw E_GroundArea19, E_GroundArea20, E_GroundArea21, E_GroundArea22, E_UndergroundArea1
    .dw E_UndergroundArea2, E_UndergroundArea3, E_WaterArea1, E_WaterArea2, E_WaterArea3
.ENDS

.SECTION "AreaType Offsets into AreaDataAddr" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   STARTING INDEXES OF AREATYPES (WATER, OVERWORLD, UNDERGROUND, CASTLE)
AreaDataHOffsets:
    .db $00, $03, $19, $1c
.ENDS

.SECTION "Area Data Pointers" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
AreaDataAddr:
    .dw L_WaterArea1, L_WaterArea2, L_WaterArea3, L_GroundArea1, L_GroundArea2, L_GroundArea3
    .dw L_GroundArea4, L_GroundArea5, L_GroundArea6, L_GroundArea7, L_GroundArea8, L_GroundArea9
    .dw L_GroundArea10, L_GroundArea11, L_GroundArea12, L_GroundArea13, L_GroundArea14, L_GroundArea15
    .dw L_GroundArea16, L_GroundArea17, L_GroundArea18, L_GroundArea19, L_GroundArea20, L_GroundArea21
    .dw L_GroundArea22, L_UndergroundArea1, L_UndergroundArea2, L_UndergroundArea3, L_CastleArea1
    .dw L_CastleArea2, L_CastleArea3, L_CastleArea4, L_CastleArea5, L_CastleArea6
.ENDS