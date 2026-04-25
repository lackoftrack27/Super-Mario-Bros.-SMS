;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;$00 - offset to vine Y coordinate adder
;$02 - offset to sprite data

.SECTION "VineYPosAdder" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
VineYPosAdder:
    .db $00, $30
.ENDS

DrawVine:
    RET

;-------------------------------------------------------------------------------------

.SECTION "Sprite Drawing TBLs for Hammer" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FirstSprXPos:
    .db $04, $00, $04, $00

FirstSprYPos:
    .db $00, $04, $00, $04

SecondSprXPos:
    .db $00, $08, $00, $08

SecondSprYPos:
    .db $08, $00, $08, $00

FirstSprTilenum:
    .db $80, $82, $81, $83

SecondSprTilenum:
    .db $81, $83, $80, $82

; HammerSprAttrib:
;     .db $03, $03, $c3, $c3
.ENDS

DrawHammer:
    RET

;-------------------------------------------------------------------------------------
;$00-$01 - used to hold tile numbers ($01 addressed in draw floatey number part)
;$02 - used to hold Y coordinate for floatey number
;$03 - residual byte used for flip (but value set here affects nothing)
;$04 - attribute byte for floatey number
;$05 - used as X coordinate for floatey number

.SECTION "FlagpoleScoreNumTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FlagpoleScoreNumTiles:
    .db $31, $34    ; "5000"
    .db $2F, $34    ; "2000"
    .db $32, $33    ; "800"
    .db $30, $33    ; "400"
    .db $2E, $33    ; "100"
.ENDS

FlagpoleGfxHandler:
    LD L, <SprDataOffset            ;get sprite data offset for flagpole flag
    LD E, (HL)
    LD D, >Sprite_Y_Position
;
    LD L, <Enemy_Y_Position
    LD A, (HL)                      ;get vertical coordinate
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A                      ;and do sub to dump into first and second sprites
    INC E
    LD (DE), A
    ADD A, $08                      ;add eight pixels
    INC E
    LD (DE), A                      ;and store into third sprite
;
    LD L, <SprDataOffset
    LD E, (HL)                      ;get sprite data offset for flagpole flag
    SLA E
    SET 7, E
    EX DE, HL
    LD A, (Enemy_Rel_XPos)          ;get relative horizontal coordinate
    LD (HL), A                      ;store as X coordinate for first sprite
    INC L
    LD (HL), $47                    ;put triangle shaped tile into first
    ADD A, $08                      ;add eight pixels and store
    INC L
    LD (HL), A                      ;as X coordinate for second sprite
    INC L
    LD (HL), $46                    ;put skull tile into second sprite
    INC L
    LD (HL), A                      ;as X coordinate for third sprite
    INC L
    LD (HL), $47                    ;put triangle shaped tile into third
    EX DE, HL
;
    LD E, (HL)                      ;get sprite data offset for flagpole flag
    LD A, (Enemy_Rel_XPos)
    ADD A, $0C + $08                ;add twelve more pixels and
    LD C, A;LD (Temp_Bytes + $05), A        ;store here to be used later by floatey number
    LD A, (FlagpoleFNum_Y_Pos)      ;get vertical coordinate for floatey number
    SUB A, SMS_PIXELYOFFSET
    LD B, A;LD (Temp_Bytes + $02), A        ;store it here
;
    LD A, (FlagpoleCollisionYPos)   ;get vertical coordinate at time of collision
    OR A
    JP Z, ChkFlagOffscreen          ;if zero, branch ahead
    INC E                           ;move sprite data offset by 3
    INC E
    INC E
    PUSH HL
    LD HL, FlagpoleScoreNumTiles
    LD A, (FlagpoleScore)           ;get offset used to award points for touching flagpole
    ADD A, A                        ;multiply by 2 to get proper offset here
    addAToHL8_M                     ;get appropriate tile data
    CALL DrawSpriteObject           ;use it to render floatey number
    POP HL
    LD E, (HL)                      ;get sprite data offset for flagpole flag
    
ChkFlagOffscreen:
    ;LD HL, (ObjectOffset)
    LD A, (Enemy_OffscrBits)        ;get offscreen bits
    AND A, %00001110                ;mask out all but d3-d1
    RET Z                           ;if none of these bits set, branch to leave
    LD D, >Sprite_Y_Position
    LD A, YPOS_OFFSCREEN
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------

DrawLargePlatform:
    LD D, >Sprite_Data
;   X POSITION & TILE
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    SLA E
    SET 7, E
    LD A, (CloudTypeOverride)
    OR A
    LD B, $40
    JP Z, +
    INC B
+:
    LD A, (Enemy_Rel_XPos)
    EX DE, HL
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    EX DE, HL
;   Y POSITION
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    LD L, <Enemy_Y_Position
    LD A, (HL)
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD B, A
    LD A, (AreaType)
    CP A, $03
    LD A, YPOS_OFFSCREEN
    JP Z, SetLast2Platform
    LD A, (SecondaryHardMode)
    OR A
    LD A, YPOS_OFFSCREEN
    JP NZ, SetLast2Platform
    LD A, B

SetLast2Platform:
    LD (DE), A
    INC E
    LD (DE), A
;   OFFSCREEN CHECK
    CALL GetXOffscreenBits
    LD D, >Sprite_Data
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    LD C, A
    LD A, YPOS_OFFSCREEN
    SLA C
    JP NC, SChk2
    LD (DE), A
SChk2:
    INC E
    SLA C
    JP NC, SChk3
    LD (DE), A
SChk3:
    INC E
    SLA C
    JP NC, SChk4
    LD (DE), A
SChk4:
    INC E
    SLA C
    JP NC, SChk5
    LD (DE), A
SChk5:
    INC E
    SLA C
    JP NC, SChk6
    LD (DE), A
SChk6:
    INC E
    SLA C
    JP NC, SLChk
    LD (DE), A
SLChk:
    LD A, (Enemy_OffscrBits)
    ADD A, A
    RET NC
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    LD A, YPOS_OFFSCREEN
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------

DrawFloateyNumber_Coin:
    LD L, <Misc_Y_Position
    LD A, (FrameCounter)            ;get frame counter
    RRCA                            ;divide by 2
    JP C, NotRsNum                  ;branch if d0 not set to raise number every other frame
    DEC (HL)                        ;otherwise, decrement vertical coordinate
NotRsNum:
    LD A, (HL)                      ;get vertical coordinate
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A                      ;dump into both sprites
    INC E
    LD (DE), A
;
    DEC E                           ;(SMS)
    SLA E
    SET 7, E
    EX DE, HL
    LD A, (Misc_Rel_XPos)           ;get relative horizontal coordinate
    LD (HL), A                      ;store as X coordinate for first sprite
    INC L
    LD (HL), $2F                    ;put tile numbers into both sprites...
    INC L
    ADD A, $08                      ;add eight pixels
    LD (HL), A                      ;store as X coordinate for second sprite
    INC L
    LD (HL), $33                    ;...that resemble "200"
    EX DE, HL
    RET

.SECTION "JumpingCoinTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
JumpingCoinTiles:
    .db $19, $1B, $1D, $1F
.ENDS

JCoinGfxHandler:
    LD D, H
    INC D
    INC D

    LD E, <SprDataOffset            ;get coin/floatey number's OAM data offset
    LD A, (DE)
    LD E, A
    LD D, >Sprite_Y_Position
;
    LD L, <Misc_State
    LD A, (HL)                      ;get state of misc object
    CP A, $02                       ;if 2 or greater,
    JP NC, DrawFloateyNumber_Coin   ;branch to draw floatey number
;
    LD L, <Misc_Y_Position
    LD A, (HL)                      ;store vertical coordinate as
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A                      ;Y coordinate for first sprite
    ADD A, $08                      ;add eight pixels
    INC E
    LD (DE), A                      ;store as Y coordinate for second sprite
;
    DEC E                           ;(SMS)
    SLA E
    SET 7, E
    LD A, (Misc_Rel_XPos)           ;get relative horizontal coordinate
    LD (DE), A
    INC E
    INC E
    LD (DE), A                      ;store as X coordinate for first and second sprites
;
    LD A, (FrameCounter)            ;get frame counter
    RRCA                            ;divide by 2 to alter every other frame
    AND A, %00000011                ;mask out d2-d1
    LD BC, JumpingCoinTiles         ;use as graphical offset
    addAToBC8_M
;
    DEC E
    LD A, (BC)                      ;load tile number
    LD (DE), A                      ;write to first sprite
    INC E
    INC E
    INC A                           ;increment tile number for second sprite
    LD (DE), A                      ;write to second sprite
;
    ;LD HL, (ObjectOffset)
    RET

;-------------------------------------------------------------------------------------
;$00-$01 - used to hold tiles for drawing the power-up, $00 also used to hold power-up type
;$02 - used to hold bottom row Y position
;$03 - used to hold flip control (not used here)
;$04 - used to hold sprite attributes (UNUSED)
;$05 - used to hold X position
;$07 - counter (UNUSED)

;tiles arranged in top left, right, bottom left, right order

.SECTION "PowerUpGfxTable" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PowerUpGfxTable:
    .db $09, $0A, $0B, $0C  ; mushroom
    .db $11, $12, $13, $14  ; fire flower
    .db $15, $16, $17, $18  ; star
    .db $0D, $0E, $0F, $10  ; 1-up mushroom
.ENDS

DrawPowerUp:
    LD A, (Enemy_SprDataOffset + $05 * $100)
    LD E, A
    LD D, >Sprite_Y_Position
;
    LD A, (Enemy_Rel_YPos)
    ADD A, $08 - SMS_PIXELYOFFSET
    LD B, A ;LD (Temp_Bytes + $02), A
    LD A, (Enemy_Rel_XPos)
    LD C, A ;LD (Temp_Bytes + $05), A
;
    LD A, (PowerUpType)
    ADD A, A
    ADD A, A
    LD HL, PowerUpGfxTable
    addAToHL8_M
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    JP SprObjectOffscrChk
    
;-------------------------------------------------------------------------------------
;$00-$01 - used in DrawEnemyObjRow to hold sprite tile numbers
;$02 - used to store Y position
;$03(IXL) - used to store moving direction, used to flip enemies horizontally
;$04 - used to store enemy's sprite attributes
;$05 - used to store X position
; -------
;$eb - used to hold sprite data offset (UNUSED)
;$ec($09, IXH) - used to hold either altered enemy state or special value used in gfx handler as condition
;$ed($0A, IYL) - used to hold enemy state from buffer 
;$ef($0B, IYH) - used to hold enemy code used in gfx handler (may or may not resemble Enemy_ID values)

.SECTION "EnemyGraphicsTable" BANK BANK_SLOT2 SLOT 2 ALIGN $100
;tiles arranged in top left, right, middle left, right, bottom left, right order
EnemyGraphicsTable:
    .db $00, $00, $EA, $EB, $EC, $ED  ;buzzy beetle frame 1
    .db $00, $00, $EE, $EF, $F0, $F1  ;             frame 2
    ; ---
    .db $00, $64, $65, $66, $67, $68  ;koopa troopa frame 1
    .db $00, $69, $6A, $6B, $6C, $6D  ;             frame 2
    ; ---
    .db $6E, $64, $6F, $66, $67, $68  ;koopa paratroopa frame 1
    .db $70, $69, $71, $6B, $6C, $6D  ;                 frame 2
    ; ---
    .db $00, $00, $AC, $AD, $AE, $AF  ;spiny frame 1
    .db $00, $00, $B0, $B1, $B2, $B3  ;      frame 2
    ; ---
    .db $00, $00, $A4, $A5, $A6, $A7  ;spiny's egg frame 1  [X, $30]
    .db $00, $00, $A8, $A9, $AA, $AB  ;            frame 2  [X]
    ; ---
    .db $00, $00, $A8, $A9, $AE, $AF  ;bloober frame 1
    .db $A8, $A9, $AA, $AB, $AC, $AD  ;        frame 2
    ; ---
    .db $00, $00, $90, $91, $92, $93  ;cheep-cheep frame 1
    .db $00, $00, $94, $91, $95, $93  ;            frame 2
    ; ---
    .db $00, $00, $5C, $5D, $5E, $5F  ;goomba
    ; ---
    .db $00, $00, $72, $73, $74, $75  ;koopa shell frame 1 (upside-down)
    .db $00, $00, $72, $73, $76, $77  ;            frame 2
    ; ---
    .db $00, $00, $72, $73, $74, $75  ;koopa shell frame 1 (rightsideup)
    .db $00, $00, $72, $73, $76, $77  ;            frame 2
    ; ---
    .db $00, $00, $96, $97, $98, $99  ;buzzy beetle shell frame 1 (rightsideup)
    .db $00, $00, $96, $97, $98, $99  ;                   frame 2
    ; ---
    .db $00, $00, $96, $97, $98, $99  ;buzzy beetle shell frame 1 (upside-down)
    .db $00, $00, $96, $97, $98, $99  ;                   frame 2
    ; ---
    .db $00, $00, $00, $00, $60, $61  ;defeated goomba      [X, $8A]
    ; ---
    .db $9C, $9D, $9E, $9F, $A0, $A1  ;lakitu frame 1
    .db $00, $00, $A2, $A3, $A0, $A1  ;       frame 2
    ; ---
    .db $00, $00, $9C, $9D, $9E, $9F  ;cheep-cheep frame 1 (red) [$9C]
    .db $00, $00, $A0, $9D, $A1, $9F  ;cheep-cheep frame 2 (red)
    ; ---
    .db $C8, $C9, $CA, $CB, $CC, $CD  ;hammer bro frame 1
    .db $C8, $C9, $CE, $CF, $D0, $D1  ;           frame 2
    .db $D2, $D3, $D4, $D5, $CC, $CD  ;           frame 3
    .db $D2, $D3, $D4, $D5, $D0, $D1  ;           frame 4
    ; ---
    .db $86, $87, $88, $89, $8A, $8B  ;piranha plant frame 1
    .db $8C, $8D, $8E, $8F, $8A, $8B  ;              frame 2
    ; ---
    .db $00, $64, $C8, $C9, $CA, $CB  ;koopa troopa frame 1 (red) ($CC)
    .db $00, $69, $CC, $CD, $CE, $CF  ;             frame 2 (red)
    ; ---
    .db $6E, $64, $D0, $C9, $CA, $CB  ;koopa paratroopa frame 1 (red) ($D8)
    .db $70, $69, $D1, $CD, $CE, $CF  ;                 frame 2 (red)
    ; ---
    .db $00, $00, $C0, $C1, $C2, $C3  ;bullet bill
    ; ---
    .db $00, $00, $D2, $D3, $D4, $D5  ;koopa shell frame 1 (upside-down) (red) ($EA)
    .db $00, $00, $D2, $D3, $D6, $D7  ;            frame 2 (red)
    ; ---
    .db $00, $00, $D2, $D3, $D4, $D5  ;koopa shell frame 1 (rightsideup) ($F6)
    .db $00, $00, $D2, $D3, $D6, $D7  ;            frame 2 (red)
.ENDS

.SECTION "EnemyGraphicsTable_HFlip" BANK BANK_SLOT2 SLOT 2 ALIGN $100
;tiles arranged in top left, right, middle left, right, bottom left, right order
EnemyGraphicsTable_HFlip:
    .db $00, $00, $F6, $F7, $F8, $F9  ;buzzy beetle frame 1
    .db $00, $00, $FA, $FB, $FC, $FD  ;             frame 2
    ; ---
    .db $78, $00, $79, $7A, $7B, $7C  ;koopa troopa frame 1
    .db $7D, $00, $7E, $7F, $80, $81  ;             frame 2
    ; ---
    .db $78, $82, $79, $83, $7B, $7C  ;koopa paratroopa frame 1
    .db $7D, $84, $7E, $85, $80, $81  ;                 frame 2
    ; ---
    .db $00, $00, $B8, $B9, $BA, $BB  ;spiny frame 1
    .db $00, $00, $BC, $BD, $BE, $BF  ;      frame 2
    ; ---
    .db $00, $00, $A4, $A5, $A6, $A7  ;spiny's egg frame 1  [X, $30]
    .db $00, $00, $A8, $A9, $AA, $AB  ;            frame 2  [X]
    ; ---
    .db $00, $00, $A8, $A9, $AE, $AF  ;bloober frame 1
    .db $A8, $A9, $AA, $AB, $AC, $AD  ;        frame 2
    ; ---
    .db $00, $00, $96, $97, $98, $99  ;cheep-cheep frame 1
    .db $00, $00, $96, $9A, $98, $9B  ;            frame 2
    ; ---
    .db $00, $00, $5C, $5D, $62, $63  ;goomba
    ; ---
    .db $00, $00, $72, $73, $74, $75  ;koopa shell frame 1 (upside-down)
    .db $00, $00, $72, $73, $76, $77  ;            frame 2
    ; ---
    .db $00, $00, $72, $73, $74, $75  ;koopa shell frame 1 (rightsideup)
    .db $00, $00, $72, $73, $76, $77  ;            frame 2
    ; ---
    .db $00, $00, $96, $97, $98, $99  ;buzzy beetle shell frame 1 (rightsideup)
    .db $00, $00, $96, $97, $98, $99  ;                   frame 2
    ; ---
    .db $00, $00, $96, $97, $98, $99  ;buzzy beetle shell frame 1 (upside-down)
    .db $00, $00, $96, $97, $98, $99  ;                   frame 2
    ; ---
    .db $00, $00, $00, $00, $60, $61  ;defeated goomba      [X, $8A]
    ; ---
    .db $B4, $B5, $B6, $B7, $A0, $A1  ;lakitu frame 1
    .db $00, $00, $A2, $A3, $A0, $A1  ;       frame 2
    ; ---
    .db $00, $00, $A2, $A3, $A4, $A5  ;cheep-cheep frame 1 (red)
    .db $00, $00, $A2, $A6, $A4, $A7  ;cheep-cheep frame 2 (red)
    ; ---
    .db $D6, $D7, $D8, $D9, $DA, $DB  ;hammer bro frame 1
    .db $D6, $D7, $DC, $DD, $DE, $DF  ;           frame 2
    .db $E0, $E1, $E2, $E3, $DA, $DB  ;           frame 3
    .db $E0, $E1, $E2, $E3, $DE, $DF  ;           frame 4
    ; ---
    .db $86, $87, $88, $89, $8A, $8B  ;piranha plant frame 1
    .db $8C, $8D, $8E, $8F, $8A, $8B  ;              frame 2
    ; ---
    .db $78, $00, $D8, $D9, $DA, $DB  ;koopa troopa frame 1 (red)
    .db $7D, $00, $DC, $DD, $DE, $DF  ;             frame 2 (red)
    ; ---
    .db $78, $82, $D8, $E0, $DA, $DB  ;koopa paratroopa frame 1 (red)
    .db $7D, $84, $DC, $E1, $DE, $DF  ;                 frame 2 (red)
    ; ---
    .db $00, $00, $C4, $C5, $C6, $C7  ;bullet bill
    ; ---
    .db $00, $00, $D2, $D3, $D4, $D5  ;koopa shell frame 1 (upside-down) (red)
    .db $00, $00, $D2, $D3, $D6, $D7  ;            frame 2 (red)
    ; ---
    .db $00, $00, $D2, $D3, $D4, $D5  ;koopa shell frame 1 (rightsideup)
    .db $00, $00, $D2, $D3, $D6, $D7  ;            frame 2 (red)
.ENDS

.SECTION "EnemyGfxTableOffsets" BANK BANK_SLOT2 SLOT 2 BITWINDOW 8
EnemyGfxTableOffsets:
    .db $0c, $CC, $00, $CC, $0C, $a8, $54, $3c  ; $00 - $07
    .db $E4, $18, $48, $9C, $FF, $c0, $18, $D8  ; $08 - $0F
    .db $18, $90, $24, $FF, $9C, $FF, $FF, $FF  ; $10 - $17
    .db $FF, $FF, $FF, $8A, $FF, $FF, $FF       ; $18 - $1A
.ENDS

; .ENUM $00
;     GFXID_GreenKoopa                    DB
;     GFXID_GreenKoopa_01                 DB
;     GFXID_BuzzyBeetle                   DB
;     GFXID_RedKoopa                      DB
;     GFXID_RedKoopa_01                   DB
;     GFXID_HammerBro                     DB
;     GFXID_Goomba                        DB
;     GFXID_Bloober                       DB
;     ;
;     GFXID_BulletBill_FrenzyVar          DB
;     GFXID_TallEnemy                     DB  ;Paratroopa?
;     GFXID_GreyCheepCheep                DB
;     GFXID_RedCheepCheep                 DB
;     GFXID_Podoboo                       DB
;     GFXID_PiranhaPlant                  DB
;     GFXID_GreenParatroopaJump           DB
;     GFXID_RedParatroopa                 DB
;     ;
;     GFXID_GreenParatroopaFly            DB
;     GFXID_Lakitu                        DB
;     GFXID_Spiny                         DB
;     GFXID_SpinyEgg                      DB
;     GFXID_FlyingCheepCheep              DB  ;OBJECTID_FlyCheepCheepFrenzy
;     GFXID_Princess                      DB  ;OBJECTID_BowserFlame
;     GFXID_BowserFront                   DB  ;OBJECTID_Fireworks
;     GFXID_BowserRear                    DB  ;OBJECTID_BBill_CCheep_Frenzy
;     ;
;     GFXID_JumpSpring_00                 DB
;     GFXID_JumpSpring_01                 DB
;     GFXID_JumpSpring_02                 DB
;     GFXID_GoombaDefeated                DB
;     GFXID_RetainerObject                DB
;     GFXID_BowserFront_01                DB
;     GFXID_BowserRear_01                 DB
; .ENDE

EnemyGfxHandler:
    LD L, <Enemy_Y_Position                 ;get enemy object vertical position
    LD A, (HL)
    SUB A, SMS_PIXELYOFFSET
    LD D, A
    LD A, (Enemy_Rel_XPos)                  ;get enemy object horizontal position
    LD (Temp_Bytes + $05), A                ;relative to screen
;
    LD L, <Enemy_SprDataOffset              ;get sprite data offset
    LD E, (HL)
;
    ;XOR A                                   ;initialize vertical flip flag by default
    ;LD (VerticalFlipFlag), A
;
    LD L, <Enemy_MovingDir                  ;get enemy object moving direction
    LD A, (HL)
    LD IXL, A
;
    ;LD L, <Enemy_SprAttrib                 ;get enemy object sprite attributes
    ;LD A, (HL)
    ;LD (Temp_Bytes + $04), A
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_PiranhaPlant             ;is enemy object piranha plant?
    JP NZ, SetupState                       ;if not, branch
;
    LD L, <PiranhaPlant_Y_Speed
    LD A, (HL)
    OR A
    JP M, SetupState                        ;if piranha plant moving upwards, branch
;
    LD A, H                                 ;if timer for movement expired, branch
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    RET NZ                                  ;if all conditions fail, leave

SetupState:
    LD L, <Enemy_State                      ;store enemy state
    LD A, (HL)
    LD IYL, A
    AND A, %00011111                        ;nullify all but 5 LSB and use as Y
    LD C, A

CheckForRetainerObj:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_RetainerObject
    JP Z, RetainerGfxHandler

CheckForBulletBillCV:
    CP A, OBJECTID_BulletBill_CannonVar     ;otherwise check for bullet bill object
    JP NZ, SaveEnemyObject                  ;if not found, branch again
;
    DEC D                                   ;decrement saved vertical position
;
;     PUSH BC
;     LD A, H
;     SUB A, $C1
;     LD BC, EnemyFrameTimer
;     addAToBC8_M
;     LD A, (BC)
;     POP BC
;     OR A
;     LD A, $03
;     JP Z, SBBAt
;     LD A, $23
; SBBAt:
;     LD (Temp_Bytes + $04), A
;
    XOR A                                   ;nullify saved enemy state both in Y and in
    LD C, A                                 ;memory location here
    LD IYL, A
    LD A, $08                               ;set specific value to unconditionally branch once

SaveEnemyObject:
    LD IYH, A                               ;store saved enemy object value here
    LD IXH, C                               ;and Y here (enemy state -2 MSB if not changed)

CheckForPodoboo:
    CP A, $0C
    JP Z, PodobooGfxHandler

CheckForGoomba:
    ;LD A, IYH                
    LD C, A
    CP A, OBJECTID_Goomba                   ;check value for goomba object
    JP NZ, CheckForSpiny                    ;branch if not found
;
    LD L, <Enemy_State
    LD A, (HL)
    CP A, $02                               ;check for defeated state
    JP C, GmbaAnim                          ;if not defeated, go ahead and animate
    LD IXH, $04                             ;if defeated, write new value here
GmbaAnim:
    AND A, %00100000                        ;check for d5 set in enemy object state
    LD HL, TimerControl
    OR A, (HL)                              ;or timer disable flag set
    JP NZ, CheckForSpiny                    ;if either condition true, do not animate goomba
    LD A, (FrameCounter)
    AND A, %00001000                        ;check for every eighth frame
    JP NZ, CheckForSpiny
    LD A, %00000011
    XOR A, IXL                              ;invert bits to flip horizontally every eight frames
    LD IXL, A                               ;leave alone otherwise              

CheckForSpiny:
    LD A, C
    LD HL, EnemyGfxTableOffsets             ;load value based on enemy object as offset
    addAToHL8_M
    LD L, (HL)
;
    LD C, IXH
;
    LD A, L
    CP A, $24
    JP NZ, CheckForLakitu
;
    LD A, C
    CP A, $05
    JP NZ, CheckForHammerBro
;
    LD L, $30
    LD IXL, $02
    LD IXH, $05
    JP CheckForHammerBro

CheckForLakitu:
    CP A, $90
    JP NZ, CheckUpsideDownShell
;
    LD A, IYL
    AND A, %00100000
    JP NZ, CheckDefeatedState
;
    LD A, (FrenzyEnemyTimer)
    CP A, $10
    JP NC, CheckDefeatedState
;
    LD L, $96
    JP CheckDefeatedState

CheckUpsideDownShell:
    LD A, IYH
    CP A, $04
    JP NC, CheckRightSideUpShell
;
    LD A, C
    CP A, $02
    JP C, CheckRightSideUpShell
;
    LD L, $7E
    INC D
    LD A, IYH
    LD C, A
    CP A, OBJECTID_BuzzyBeetle
    JP Z, CheckRightSideUpShell
    DEC D
    LD L, $5A
    OR A
    JP Z, CheckRightSideUpShell
    LD L, $EA

CheckRightSideUpShell:
    LD A, IXH
    CP A, $04
    JP NZ, CheckForHammerBro
;
    LD L, $72
    INC D
    LD A, IYH
    LD C, A
    CP A, OBJECTID_BuzzyBeetle
    JP Z, CheckForDefdGoomba
;
    INC D
    LD L, $66
    CP A, $01
    JP NZ, +
    LD L, $F6
    JP CheckForDefdGoomba
+:
    CP A, OBJECTID_RedKoopa
    JP NZ, +
    LD L, $F6
    JP CheckForDefdGoomba
+:
    CP A, OBJECTID_RedParatroopa
    JP NZ, CheckForDefdGoomba
    LD L, $F6

CheckForDefdGoomba:
    LD A, C
    CP A, OBJECTID_Goomba
    JP NZ, CheckForHammerBro
;
    LD L, $54
    LD A, IYL
    AND A, %00100000
    JP NZ, CheckForHammerBro
;
    LD L, $8A
    DEC D

CheckForHammerBro:
    LD A, (ObjectOffset + $01)
    LD C, A
;
    LD A, IYH
    CP A, OBJECTID_HammerBro
    JP NZ, CheckForBloober
;
    LD A, IYL
    OR A
    JP Z, CheckToAnimateEnemy
;
    AND A, %00001000
    JP NZ, CheckDefeatedState
;
    LD L, $B4
    JP CheckToAnimateEnemy

CheckForBloober:
    LD A, L
    CP A, $48
    JP Z, CheckToAnimateEnemy
;
    LD A, C
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    LD C, A
    CP A, $05
    JP NC, CheckDefeatedState
;
    LD A, L
    CP A, $3C
    JP NZ, CheckToAnimateEnemy
;
    LD A, C
    CP A, $01
    JP Z, CheckDefeatedState
;
    INC D
    INC D
    INC D
    JP CheckAnimationStop

CheckToAnimateEnemy:
    LD A, IYH
    CP A, OBJECTID_Goomba
    JP Z, CheckDefeatedState
    CP A, $08
    JP Z, CheckDefeatedState
    CP A, $18
    JP NC, CheckDefeatedState

CheckForSecondFrame:
    LD A, (FrameCounter)
    AND A, $08
    JP NZ, CheckDefeatedState

CheckAnimationStop:
    LD A, (TimerControl)
    LD C, A
    LD A, IYL
    AND A, %10100000
    OR A, C
    JP NZ, CheckDefeatedState
;
    LD A, $06
    addAToHL8_M

CheckDefeatedState:
    LD A, IYL
    AND A, %00100000
    JP Z, DrawEnemyObject
;
    LD A, IYH
    CP A, $04
    JP C, DrawEnemyObject
;
    ;LD A, $01
    ;LD (VerticalFlipFlag), A
    LD IXH, $00

DrawEnemyObject:
    LD B, D
    LD A, (Temp_Bytes + $05)
    LD C, A

    LD D, >Sprite_Y_Position
    LD H, >EnemyGraphicsTable
    DEC IXL
    JP Z, +
    LD H, >EnemyGraphicsTable_HFlip
;
+:
    ;CALL DrawSpriteObject
    ;CALL DrawSpriteObject
    ;CALL DrawSpriteObject
    LD IXL, E
    LD A, B
    DrawSpriteObject_YPos
    DrawSpriteObject_YPos
    DrawSpriteObject_YPos
    LD E, IXL
    SLA E
    SET 7, E
    DrawSpriteObject_XT
    DrawSpriteObject_XT
    DrawSpriteObject_XT


SprObjectOffscrChk:
    LD D, >Sprite_Y_Position
    LD HL, (ObjectOffset)
    LD A, (Enemy_OffscrBits)
    LD C, A
    SRL C   ; 24
    SRL C
    SRL C
    LD A, $01
    CALL C, MoveESprColOffscreen
;
    SRL C   ; 8
    LD A, $00
    CALL C, MoveESprColOffscreen
;
    SRL C   ; 16
    SRL C
    LD A, $04
    CALL C, MoveESprRowOffscreen
;
    SRL C   ; 8
    LD A, $02
    CALL C, MoveESprRowOffscreen
;
    SRL C   ; 8
    RET NC
    XOR A
    CALL MoveESprRowOffscreen
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Podoboo
    RET Z
    LD L, <Enemy_Y_HighPos
    LD A, (HL)
    CP A, $02
    RET NZ
    JP EraseEnemyObject

MoveESprRowOffscreen:
    LD L, <Enemy_SprDataOffset
    ADD A, (HL)
    LD E, A
;
    LD A, YPOS_OFFSCREEN
    LD (DE), A
    INC E
    LD (DE), A
    RET

MoveESprColOffscreen:
    LD L, <Enemy_SprDataOffset
    ADD A, (HL)
    LD E, A
;
    LD A, YPOS_OFFSCREEN
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    RET

PodobooGfxHandler:
;   VERTICAL FLIP ADJUST
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    OR A
    LD HL, PodobooTiles
    JP M, +
    LD L, <PodobooTiles + $08
;   ANIMATE ADJUST
+:
    LD A, (FrameCounter)
    AND A, $08
    JP NZ, +
    LD A, (TimerControl)
    LD C, A
    LD A, IYL
    AND A, %10100000
    OR A, C
    JP NZ, +
    LD A, $04
    addAToHL8_M
;   DRAW SPRITE
+:
    LD A, D
    ADD A, $08
    LD B, A
    LD A, (Temp_Bytes + $05)
    LD C, A
    LD D, >Sprite_Y_Position
    INC E
    INC E
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    JP SprObjectOffscrChk

RetainerGfxHandler:
    LD HL, RetainerPrincessTiles
;   DRAW SPRITE
    LD B, D
    LD A, (Temp_Bytes + $05)
    LD C, A
    LD D, >Sprite_Y_Position
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    JP SprObjectOffscrChk

JumpspringGfxHandler:
;
    ; DIVIDE X REL BY 4 TO GET COLUMN
    ; MULTIPLY Y REL BY 8 TO GET ROW

    RET

.SECTION "PodobooTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PodobooTiles:
    .db $48, $49, $4A, $4B  ; FRAME 0
    .db $4C, $4D, $4E, $4F  ; FRAME 1
    .db $50, $51, $52, $53  ; FRAME 0 VFLIP
    .db $54, $55, $56, $57  ; FRAME 1 VFLIP
.ENDS

.SECTION "RetainerPrincessTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
RetainerPrincessTiles:
    .db $42, $43, $44, $45, $46, $47
.ENDS

;-------------------------------------------------------------------------------------
;$00-$01 - tile numbers
;$02 - relative Y position
;$03 - horizontal flip flag (not used here)
;$04 - attributes
;$05 - relative X position
;IYL - OAM Offset

.SECTION "DefaultBlockObjTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
DefaultBlockObjTiles:
    ;.db $85, $85, $86, $86             ;brick w/ line (these are sprite tiles, not BG!)
    .db $3B, $3B, $3B, $3B              ;breakable block
    .db $37, $38, $39, $3A              ;empty block
.ENDS

DrawBlock:
    LD A, (Block_Rel_YPos)          ;get relative vertical coordinate of block object
    SUB A, SMS_PIXELYOFFSET
    LD B, A ;LD (Temp_Bytes + $02), A        ;store here
;
    LD A, (Block_Rel_XPos)          ;get relative horizontal coordinate of block object
    LD C, A ;LD (Temp_Bytes + $05), A        ;store here
;
    LD D, H
    DEC D                           ;SPRDATA_BLOCK1 - OBJ_BLOCK1
    
    LD E, <SprDataOffset            ;get sprite data offset
    LD A, (DE)
    LD IYL, A ;LD (Temp_Bytes + $04), A
    LD E, A

    LD D, >Sprite_Y_Position
    PUSH HL
;
    LD L, <Block_Metatile
    LD A, (HL)
    CP A, MT_EMPTYBLK
    LD HL, DefaultBlockObjTiles
    JP NZ, +
    LD L, <DefaultBlockObjTiles + $04
;
+:
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    POP HL
;
    ;LD A, (Temp_Bytes + $04)
    ;LD E, A
    LD D, >Sprite_Y_Position
    LD E, IYL
    LD A, (Block_OffscrBits)
    PUSH AF
    AND A, %00000100
    JP Z, PullOfsB
    LD A, YPOS_OFFSCREEN
    INC E
    LD (DE), A
    INC E
    INC E
    LD (DE), A
PullOfsB:
    POP AF
    AND A, %00001000
    RET Z

    ;LD A, (Temp_Bytes + $04)
    ;LD E, A
    LD E, IYL
;MoveColOffscreen:
    LD A, YPOS_OFFSCREEN
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    RET
    
;-------------------------------------------------------------------------------------
;$00(IXL) - used to hold palette bits for attribute byte or relative X position
;$01(IXH)
DrawBrickChunks:
;   CALCULATE SPRDATAOFFSET
    LD A, H
    ADD A, SPRDATA_BLOCK1 - OBJ_BLOCK1
    LD D, A
    LD E, <SprDataOffset
    LD A, (DE)
    LD E, A
    LD D, >Sprite_Y_Position
    LD IXH, A
;   STORE Y POSITIONS
    LD A, (Block_Rel_YPos)
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A
    INC E
    LD (DE), A
    LD A, (Block_Rel_YPos_01)
    SUB A, SMS_PIXELYOFFSET
    INC E
    LD (DE), A
    INC E
    LD (DE), A
;   STORE ALL TILE IDS
    LD E, IXH
    SLA E
    SET 7, E
    INC E
    LD A, (FrameCounter)
    RRCA
    RRCA
    AND A, $03
    ADD A, $3C
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    INC E
    INC E
    LD (DE), A 
;   STORE X POSITIONS
    LD E, IXH
    SLA E
    SET 7, E
    LD A, (Block_Rel_XPos)
    LD (DE), A
    LD A, (ScreenLeft_X_Pos)
    LD C, A
    LD L, <Block_Orig_XPos
    LD A, (HL)
    SUB A, C
    LD IXL, A
    LD A, (DE)
    LD C, A
    LD A, IXL
    SUB A, C
    ADC A, IXL
    ADC A, $06
    INC E
    INC E
    LD (DE), A
;
    LD A, (Block_Rel_XPos_01)
    INC E
    INC E
    LD (DE), A
;
    LD C, A
    LD A, IXL
    SUB A, C
    ADC A, IXL
    ADC A, $06
    INC E
    INC E
    LD (DE), A
;   OFFSCREEN CHECK (YPOS?)
    LD E, IXH
    LD A, (Block_OffscrBits)
    AND A, %00001000
    JP Z, +
    LD A, YPOS_OFFSCREEN
    LD (DE), A  ; 0
    INC E
    INC E
    LD (DE), A  ; 8
+:
    LD E, IXH
    LD A, (Block_OffscrBits)
    ADD A, A
    JP NC, ChnkOfs
    LD A, YPOS_OFFSCREEN
    LD (DE), A
    INC E
    LD (DE), A
;   OFFSCREEN CHECK (XPOS?)
ChnkOfs:
    LD A, IXL
    OR A
    RET P
    LD E, IXH
    SLA E
    SET 7, E
    LD A, (DE)
    INC E
    INC E
    EX DE, HL
    CP A, (HL)
    EX DE, HL
    RET C
    LD E, IXH
    LD A, YPOS_OFFSCREEN
    INC E
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------

DrawFireball:
    LD A, H
    ADD A, SPRDATA_FIRE1 - OBJ_FIRE1
    LD D, A
    LD E, <SprDataOffset
    LD A, (DE)
    LD E, A
    LD D, >Sprite_Y_Position
;
    LD A, (Fireball_Rel_YPos)
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A
;
    SLA E
    SET 7, E
    LD A, (Fireball_Rel_XPos)
    LD (DE), A

DrawFirebar:
    INC E
    LD A, (FrameCounter)
    RRCA
    RRCA
    AND A, $03
    ADD A, $21
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------
; IXL

.SECTION "ExplosionTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
ExplosionTiles:
    .db $25, $26, $2A
.ENDS

DrawExplosion_Fireball:
    LD A, H
    ADD A, SPRDATA_ALT - OBJ_FIRE1
    LD D, A
    LD E, <SprDataOffset
    LD A, (DE)
    LD IXL, A
;
    LD L, <Fireball_State
    LD A, (HL)
    INC (HL)
    RRCA
    AND A, %00000111
    CP A, $03
    JP C, DrawExplosion_Fireworks@SkipSprOffset
    LD (HL), $00
    RET

DrawExplosion_Fireworks:
    LD IXL, E
@SkipSprOffset:
    LD DE, ExplosionTiles
    addAToDE8_M
    LD A, (DE)
;
    LD D, >Sprite_Y_Position
    LD E, IXL
;
    SLA E
    SET 7, E
    INC E
    LD (DE), A
;
    CP A, $25
    JP NZ, +
;
    ;
    DEC E
    LD A, (Fireball_Rel_XPos)
    LD (DE), A
    ;
    LD E, IXL
    LD A, (Fireball_Rel_YPos)
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A
    LD A, YPOS_OFFSCREEN
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    RET
+:
    EX DE, HL
    LD C, A
    LD A, (Fireball_Rel_XPos)
    SUB A, $04 
    DEC L
    LD (HL), A
    INC L
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    INC C
    LD (HL), C
    INC L
    SUB A, $08
    LD (HL), A
    INC L
    INC C
    LD (HL), C
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    INC C
    LD (HL), C
    EX DE, HL
;
    LD E, IXL
    LD A, (Fireball_Rel_YPos)
    SUB A, $04 + SMS_PIXELYOFFSET
    LD (DE), A
    INC E
    LD (DE), A
    ADD A, $08
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------

DrawSmallPlatform:
;   X POSITION & TILE
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    SLA E
    SET 7, E
    LD A, (Enemy_Rel_XPos)
    LD B, $40
    EX DE, HL
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    SUB A, $10
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
    EX DE, HL
;   Y POSITION
    ; FIRST 3
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    LD L, <Enemy_Y_Position
    LD A, (HL)
    CP A, $20
    JP NC, TopSP
    LD A, YPOS_OFFSCREEN
TopSP:
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    ; SECOND 3
    LD L, <Enemy_Y_Position
    LD A, (HL)
    ADD A, $80
    CP A, $20
    JP NC, BotSP
    LD A, YPOS_OFFSCREEN
BotSP:
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
;   OFFSCREEN CHECK
    ; 1ST THREE
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    INC E
    INC E
    LD A, (Enemy_OffscrBits)
    LD C, A
    LD A, YPOS_OFFSCREEN
    SRL C
    SRL C
    JP NC, +
    LD (DE), A
+:
    DEC E
    SRL C
    JP NC, +
    LD (DE), A
+:
    DEC E
    SRL C
    JP NC, +
    LD (DE), A
+:
    ; 2ND THREE
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    INC E
    INC E
    INC E
    INC E
    INC E
    LD A, (Enemy_OffscrBits)
    LD C, A
    LD A, YPOS_OFFSCREEN
    SRL C
    SRL C
    JP NC, +
    LD (DE), A
+:
    DEC E
    SRL C
    JP NC, +
    LD (DE), A
+:
    DEC E
    SRL C
    RET NC
    LD (DE), A
    RET


;-------------------------------------------------------------------------------------

DrawBubble:
    LD A, (Player_Y_HighPos)        ;if player's vertical high position
    DEC A                           ;not within screen, skip all of this
    RET NZ
;
    LD A, (Bubble_OffscrBits)       ;check air bubble's offscreen bits
    AND A, %00001000
    RET NZ                          ;if bit set, branch to leave
;
    ;LD L, <Bubble_SprDataOffset     ;get air bubble's OAM data offset
    ;LD E, (HL)
    
    LD A, H
    ADD A, SPRDATA_BUBBLE1 - OBJ_BUBB1
    LD D, A
    LD E, <SprDataOffset
    LD A, (DE)
    LD E, A

    LD D, >Sprite_Y_Position
    LD A, (Bubble_Rel_YPos)         ;get relative vertical coordinate
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A                      ;store as Y coordinate here
;
    SLA E
    SET 7, E
    LD A, (Bubble_Rel_XPos)         ;get relative horizontal coordinate
    LD (DE), A                      ;store as X coordinate here
;
    INC E
    LD A, $74                       ;put air bubble tile into OAM data
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------
;$00 - used to store player's vertical offscreen bits

.SECTION "PlayerGraphicsTable" BANK BANK_PLAYERGFX00 SLOT 2 FORCE ORG $0F20
PlayerGraphicsTable:
@bigWalk:
    .db $00, $01, $02, $03, $04, $05, $06, $07
    .db $08, $09, $0A, $0B, $0C, $0D, $0E, $0F
    .db $10, $11, $12, $13, $14, $15, $16, $17
@bigStand:
    .db $10, $11, $12, $13, $14, $15, $16, $17  ; $18
@bigSkid:
    .db $18, $19, $1A, $1B, $1C, $1D, $1E, $1F
@bigJump:
    .db $00, $20, $02, $21, $04, $22, $06, $07
@bigSwim:
    .db $23, $24, $25, $26, $27, $28, $29, $2A
    .db $23, $24, $25, $26, $2B, $2C, $2D, $2A
    .db $23, $24, $25, $26, $2E, $2F, $30, $2A
@bigClimb:
    .db $10, $11, $31, $32, $33, $34, $35, $36
    .db $37, $38, $39, $3A, $3B, $3C, $3D, $3E
@bigCrouch:
    .db $3F, $3F, $10, $11, $40, $41, $42, $43
@bigAction:
    .db $08, $44, $45, $46, $47, $48, $49, $4A
@smlWalk:
    .db $3F, $3F, $3F, $3F, $4B, $4C, $4D, $4E
    .db $3F, $3F, $3F, $3F, $4F, $50, $51, $52
    .db $3F, $3F, $3F, $3F, $4F, $50, $53, $54
@smlStand:
    .db $3F, $3F, $3F, $3F, $4F, $50, $53, $54  ; $80
@smlSkid:
    .db $3F, $3F, $3F, $3F, $55, $56, $57, $58
@smlJump:
    .db $3F, $3F, $3F, $3F, $59, $5A, $5B, $5C
@smlSwim:
    .db $3F, $3F, $3F, $3F, $59, $5D, $5E, $5F
    .db $3F, $3F, $3F, $3F, $59, $4C, $60, $61
    .db $3F, $3F, $3F, $3F, $62, $4C, $63, $61
@smlClimb:
    .db $3F, $3F, $3F, $3F, $64, $65, $66, $67
    .db $3F, $3F, $3F, $3F, $4F, $50, $68, $69
@smlKill:
    .db $3F, $3F, $3F, $3F, $6A, $6B, $6C, $6D
@interGrow:
    .db $3F, $3F, $6E, $6F, $70, $71, $72, $73  ; $C8
.ENDS

.SECTION "PlayerGraphicsTable_HFLIP" BANK BANK_PLAYERGFX01 SLOT 2 FORCE ORG $0F20
    ; BIG
    .db $00, $01, $02, $03, $04, $05, $06, $07
    .db $08, $09, $0A, $0B, $0C, $0D, $0E, $0F
    .db $10, $11, $12, $13, $14, $15, $16, $17

    .db $10, $11, $12, $13, $14, $15, $16, $17

    .db $18, $19, $1A, $1B, $1C, $1D, $1E, $1F

    .db $20, $01, $21, $03, $22, $05, $06, $07

    .db $23, $24, $25, $26, $27, $28, $29, $2A
    .db $23, $24, $25, $26, $2B, $2C, $29, $2D
    .db $23, $24, $25, $26, $2E, $2F, $29, $30

    .db $10, $11, $31, $32, $33, $34, $35, $36
    .db $37, $38, $39, $3A, $3B, $3C, $3D, $3E

    .db $3F, $3F, $10, $11, $40, $41, $42, $43

    .db $44, $09, $45, $46, $47, $48, $49, $4A
    ; SMALL
    .db $3F, $3F, $3F, $3F, $4B, $4C, $4D, $4E
    .db $3F, $3F, $3F, $3F, $4F, $50, $51, $52
    .db $3F, $3F, $3F, $3F, $4F, $50, $53, $54

    .db $3F, $3F, $3F, $3F, $4F, $50, $53, $54

    .db $3F, $3F, $3F, $3F, $55, $56, $57, $58

    .db $3F, $3F, $3F, $3F, $59, $5A, $5B, $5C

    .db $3F, $3F, $3F, $3F, $5D, $5A, $5E, $5F
    .db $3F, $3F, $3F, $3F, $4B, $5A, $60, $61
    .db $3F, $3F, $3F, $3F, $4B, $62, $60, $63

    .db $3F, $3F, $3F, $3F, $64, $65, $66, $67
    .db $3F, $3F, $3F, $3F, $4F, $50, $68, $69

    .db $3F, $3F, $3F, $3F, $6A, $6B, $6C, $6D

    .db $3F, $3F, $6E, $6F, $70, $71, $72, $73
.ENDS

.SECTION "PlayerFixedTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PlayerFixedTiles:
    .db VRAM_IDX_SPR_PLR + $00, VRAM_IDX_SPR_PLR + $01
    .db VRAM_IDX_SPR_PLR + $02, VRAM_IDX_SPR_PLR + $03
    .db VRAM_IDX_SPR_PLR + $04, VRAM_IDX_SPR_PLR + $05
    .db VRAM_IDX_SPR_PLR + $06, VRAM_IDX_SPR_PLR + $07
.ENDS

PlayerGfxHandler:
    LD A, (InjuryTimer)                 ;if player's injured invincibility timer
    OR A
    JP Z, CntPl                         ;not set, skip checkpoint and continue code
;
    LD A, (FrameCounter)
    RRCA                                ;otherwise check frame counter and branch
    RET C                               ;to leave on every other frame (when d0 is set)
CntPl:
    LD A, (GameEngineSubroutine)        ;if executing specific game engine routine,
    CP A, $0B                           ;branch ahead to some other part
    JP Z, PlayerKilled
;
    LD A, (PlayerChangeSizeFlag)        ;if grow/shrink flag set
    OR A
    JP NZ, DoChangeSize                 ;then branch to some other code
;
    /*
    ; All this is for lower body swim tile changes (ignore)
    LD A, (SwimmingFlag)                ;if swimming flag set, branch to
    OR A
    JP Z, FindPlayerAction              ;different part, do not return
;
    LD A, (Player_State)                ;if player status normal,
    OR A
    JP Z, FindPlayerAction              ;branch and do not return
;
    CALL FindPlayerAction               ;otherwise jump and return
    LD A, (FrameCounter)
    AND A, %00000100                    ;check frame counter for d2 set (8 frames every
    RET NZ                              ;eighth frame), and branch if set to leave
;
    ;tax
    LD A, (Player_SprDataOffset)
    LD C, A
    LD A, (PlayerFacingDir)
    RRCA
    JP C, SwimKT
    INC C
SwimKT:
    LD A, (PlayerSize)
    OR A
    JP Z, BigKTS
    */


FindPlayerAction:
    CALL ProcessPlayerAction            ;find proper offset to graphics table by player's actions
    JP PlayerGfxProcessing              ;draw player, then process for fireball throwing

DoChangeSize:
    CALL HandleChangeSize               ;find proper offset to graphics table for grow/shrink
    JP PlayerGfxProcessing              ;draw player, then process for fireball throwing

PlayerKilled:
    LD L, <PlayerGraphicsTable@smlKill  ;load offset for player killed


;   L - Absolute Offset from PlayerGraphicsTable
PlayerGfxProcessing:
;   STORE OFFSET
    LD (PlayerGfxOffset), HL            ;store offset to graphics table here
;   SET BANK BASED ON PLAYER'S FACING DIR
    LD A, (PlayerFacingDir)
    AND A, %00000010
    RRCA
    LD B, A
    LD HL, PlayerGfxBank
    LD A, (HL)
    AND A, %11111110
    OR A, B
    LD (HL), A
;   MERGE PALETTE BITS AND BANK LSB INTO OFFSET
    LD HL, PlayerGfxOffset + 1
    LD A, (Player_SprAttrib)
    AND A, %00000011
    RRCA
    RRCA
    RRCA
    RRCA
    LD B, A
    LD A, (PlayerGfxBank)
    AND A, %00000001
    RRCA
    RRCA
    OR A, B
    OR A, >PlayerGraphicsTable
    LD (HL), A                          ; [%MBPPMMMMMMMMMMMM]
;
    CALL RenderPlayerSub                ;draw player based on offset loaded
;   FIREBALL 'THROW' ANIMATION PROCESSING
    LD HL, FireballThrowingTimer
    LD A, (HL)
    OR A
    JP Z, PlayerOffscreenChk            ;if fireball throw timer not set, skip to the end
;
    LD A, (PlayerAnimTimer)             ;get animation frame timer
    CP A, (HL)                          ;compare to fireball throw timer
    LD (HL), $00                        ;initialize fireball throw timer
    JP NC, PlayerOffscreenChk           ;if animation frame timer => fireball throw timer skip to end
    LD (HL), A                          ;otherwise store animation timer into fireball throw timer
    LD A, <PlayerGraphicsTable@bigAction    ;load offset for player throwing
    LD (PlayerGfxOffset), A


PlayerOffscreenChk:
    LD A, (Player_OffscrBits)           ;get player's offscreen bits
    RRCA
    RRCA                                ;move vertical bits to low nybble
    RRCA
    RRCA
    AND A, $0F
    LD L, A                             ;store here
;
    LD A, (Player_SprDataOffset)        ;get player's sprite data offset
    ADD A, $06                          ;add 6 bytes to start at bottom row
    LD E, A                             ;set as offset here
    LD D, >Sprite_Y_Position
    LD B, $04                           ;check all four rows of player sprites
    LD A, YPOS_OFFSCREEN                ;load offscreen Y coordinate just in case
PROfsLoop:
    SRL L                               ;shift bit into carry
    JP NC, NPROffscr                    ;if bit clear, skip
    INC E                               ;else, dump offscreen Y coordinate into sprite data
    LD (DE), A
    DEC E
    LD (DE), A
NPROffscr:
    DEC E                               ;subtract two bytes to do
    DEC E                               ;next row up
    DJNZ PROfsLoop                      ;decrement row counter and loop until all sprite rows are checked
    RET
    

;-------------------------------------------------------------------------------------


DrawPlayer_Intermediate:
    LD BC, $4060                        ;YPOS/XPOS
    ;LD A, $40
    ;LD (Temp_Bytes + $02), A            ;YPOS
    ;LD A, $60
    ;LD (Temp_Bytes + $05), A            ;XPOS
    LD HL, PlayerGfxBank
    RES 0, (HL)                         ;RIGHT-FACING SPRITES
;
    LD HL, PlayerGraphicsTable@smlStand ;load offset for small standing
    LD (PlayerGfxOffset), HL
;
    LD HL, PlayerFixedTiles             ;load fixed tile indexes allocated for streamed player tiles
    LD DE, Sprite_Y_Position + $01      ;load sprite data offset
    JP DrawPlayerLoop

;-------------------------------------------------------------------------------------
;$00-$01 - used to hold tile numbers, $00 also used to hold upper extent of animation frames
;$02 - vertical position
;$03 - facing direction, used as horizontal flip control
;$04 - attributes
;$05 - horizontal position
;$07 - number of rows to draw
;these also used in IntermediatePlayerData

RenderPlayerSub:
    ;LD (Temp_Bytes + $03), A            ;store player's facing direction
;
    ;LD A, (Player_SprAttrib)
    ;LD (Player_SprAttrib_New), A
    ;LD (Temp_Bytes + $04), A            ;store player's sprite attributes
;
    LD HL, PlayerFixedTiles             ;load fixed tile indexes allocated for streamed player tiles
    LD A, (Player_SprDataOffset)        ;get player's sprite data offset
    LD E, A
    LD D, >Sprite_Y_Position
;
    LD A, (Player_Rel_XPos)
    LD (Player_Pos_ForScroll), A        ;store player's relative horizontal position
    LD C, A ;LD (Temp_Bytes + $05), A            ;store it here also
;
    LD A, (Player_Rel_YPos)
    SUB A, SMS_PIXELYOFFSET
    LD B, A ;LD (Temp_Bytes + $02), A            ;store player's vertical position
    

;   X - PlayerFixedTiles (HL)
;   Y - OFFSET FOR OAM (DE)
DrawPlayerLoop:
    LD IXL, E
    LD A, B
    DrawSpriteObject_YPos
    DrawSpriteObject_YPos
    DrawSpriteObject_YPos
    DrawSpriteObject_YPos
    LD E, IXL
    SLA E
    SET 7, E
    DrawSpriteObject_XT
    DrawSpriteObject_XT
    DrawSpriteObject_XT
    DrawSpriteObject_XT
    RET
    ;CALL DrawSpriteObject               ;draw sprite row 1
    ;CALL DrawSpriteObject               ;draw sprite row 2
    ;CALL DrawSpriteObject               ;draw sprite row 3
    ;JP DrawSpriteObject                 ;draw sprite row 4

ProcessPlayerAction:
    LD A, (Player_State)                ;get player's state
    OR A
    JP Z, ProcOnGroundActs              ;if not jumping, branch here
    DEC A
    JP Z, ActionSwimmingChk             ;if swimming, branch here
    DEC A
    JP Z, ActionFalling                 ;if falling, branch here
ActionClimbing:
    LD L, <PlayerGraphicsTable@bigClimb ;load offset for climbing
    LD A, (Player_Y_Speed)              ;check player's vertical speed
    OR A
    JP Z, NonAnimatedActs               ;if no speed, branch, use offset as-is
    CALL GetGfxOffsetAdder              ;otherwise get offset for graphics table
    LD A, $02                           ;load upper extent for frame control for climbing
    JP AnimationControl                 ;jump to get offset and animate player object

ProcOnGroundActs:
    LD L, <PlayerGraphicsTable@bigCrouch;load offset for crouching
    LD A, (CrouchingFlag)               ;get crouching flag
    OR A
    JP NZ, NonAnimatedActs              ;if set, branch to get offset for graphics table
;
    LD L, <PlayerGraphicsTable@bigStand ;load offset for standing
    LD A, (Player_X_Speed)              ;check player's horizontal speed
    LD B, A
    LD A, (Left_Right_Buttons)          ;and left/right controller bits
    OR A, B
    JP Z, NonAnimatedActs               ;if no speed or buttons pressed, use standing offset
;
    LD A, (Player_XSpeedAbsolute)       ;load walking/running speed
    
    .IF PALBUILD == $00
    CP A, $09
    .ELSE
    CP A, $0A                           ;PAL diff: Faster speed cutoff to accomodate FPS difference
    .ENDIF

    JP C, ActionWalkRun                 ;if less than a certain amount, branch, too slow to skid
;
    LD A, (Player_MovingDir)            ;otherwise check to see if moving direction
    LD B, A
    LD A, (PlayerFacingDir)             ;and facing direction are the same
    AND A, B
    JP NZ, ActionWalkRun                ;if moving direction = facing direction, branch, don't skid
;
    LD L, <PlayerGraphicsTable@bigSkid  ;else, load offset for skiding

NonAnimatedActs:
    CALL GetGfxOffsetAdder              ;do a sub here to get offset adder for graphics table
    XOR A
    LD (PlayerAnimCtrl), A              ;initialize animation frame control
    RET

ActionFalling:
    LD L, <PlayerGraphicsTable@bigWalk  ;load offset for walking/running
    CALL GetGfxOffsetAdder              ;get offset to graphics table
    JP GetCurrentAnimOffset             ;execute instructions for falling state

ActionWalkRun:
    LD L, <PlayerGraphicsTable@bigWalk  ;load offset for walking/running
    CALL GetGfxOffsetAdder              ;get offset to graphics table
    JP FourFrameExtent                  ;execute instructions for normal state

ActionSwimmingChk:
    LD A, (SwimmingFlag)                
    OR A
    JP NZ, ActionSwimming               ;if swimming flag set, branch elsewhere
;
    LD L, <PlayerGraphicsTable@bigCrouch;load offset for crouching
    LD A, (CrouchingFlag)               ;get crouching flag
    OR A
    JP NZ, NonAnimatedActs              ;if set, branch to get offset for graphics table
;
    LD L, <PlayerGraphicsTable@bigJump  ;otherwise load offset for jumping
    JP NonAnimatedActs                  ;go to get offset to graphics table

ActionSwimming:
    LD L, <PlayerGraphicsTable@bigSwim  ;load offset for swimming
    CALL GetGfxOffsetAdder
;
    LD A, (JumpSwimTimer)               ;check jump/swim timer
    LD B, A
    LD A, (PlayerAnimCtrl)
    OR A, B                             ;and animation frame control
    JP NZ, FourFrameExtent              ;if any one of these set, branch ahead
;
    LD A, (A_B_Buttons)
    OR A                                ;check for A button pressed
    JP M, FourFrameExtent               ;branch to same place if A button pressed

GetCurrentAnimOffset:
    LD A, (PlayerAnimCtrl)              ;get animation frame control
    ADD A, A                            ;multiply animation frame control
    ADD A, A                            ;by 8 to get proper amount
    ADD A, A                            ;to add to our offset
    addAToHL8_M                         ;add to offset to graphics table
    RET

FourFrameExtent:
    LD A, $03                           ;load upper extent for frame control

AnimationControl:
    LD B, A                             ;store upper extent here
    CALL GetCurrentAnimOffset           ;get proper offset to graphics table
    LD A, (PlayerAnimTimer)             ;load animation frame timer
    OR A
    RET NZ                              ;branch if not expired
    LD A, (PlayerAnimTimerSet)          ;get animation frame timer amount
    LD (PlayerAnimTimer), A             ;and set timer accordingly
    LD A, (PlayerAnimCtrl)
    INC A                               ;add one to animation frame control
    CP A, B                             ;compare to upper extent
    JP C, SetAnimC                      ;if frame control + 1 < upper extent, use as next
    XOR A                               ;otherwise initialize frame control
SetAnimC:
    LD (PlayerAnimCtrl), A              ;store as new animation frame control
    RET

;   A - N/A
;   X - N/A
;   Y - Current offset for PlayerGfxTblOffsets

;   HL - Absolute offset into PlayerGraphicsTable
GetGfxOffsetAdder:
    LD A, (PlayerSize)                  ;get player's size
    OR A
    RET Z                               ;if player big, use current offset as-is
    LD A, <PlayerGraphicsTable@smlWalk - <PlayerGraphicsTable
    addAToHL8_M                         ;otherwise add offset for small player
    RET

.SECTION "ChangeSizeOffsetAdder" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
ChangeSizeOffsetAdder:
    ;   SMALL -> BIG
    ;   SML, GRW, SML, GRW, SML, GRW, BIG, SML, GRW, BIG
    .db $80, $C8, $80, $C8, $80, $C8, $18, $80, $C8, $18
    ;   BIG -> SMALL
    ;   SML, BIG, SML, BIG, SML, BIG, SML, BIG, SML, BIG
    .db $02, $00, $02, $00, $02, $00, $02, $00, $02, $00
.ENDS

HandleChangeSize:
    LD A, (PlayerAnimCtrl)              ;get animation frame control
    LD C, A
    LD A, (FrameCounter)
    AND A, %00000011                    ;get frame counter and execute this code every
    JP NZ, GorSLog                      ;fourth frame, otherwise branch ahead
;
    INC C                               ;increment frame control
    LD A, C                             ;check for preset upper extent
    CP A, $0A
    JP C, CSzNext                       ;if not there yet, skip ahead to use
;
    XOR A                               ;otherwise initialize both grow/shrink flag
    LD (PlayerChangeSizeFlag), A        ;and animation frame control
CSzNext:
    LD (PlayerAnimCtrl), A              ;store proper frame control
    LD C, A
GorSLog:
    LD A, (PlayerSize)                  ;get player's size
    OR A
    LD A, C
    JP NZ, ShrinkPlayer                 ;if player small, skip ahead to next part
;
    LD HL, ChangeSizeOffsetAdder        ;get offset adder based on frame control as offset
    addAToHL8_M
    LD A, (HL)
    ADD A, <PlayerGraphicsTable         ;use as relative offset from table base
    LD L, A
    RET

ShrinkPlayer:
    ADD A, $0A                          ;add ten bytes to frame control as offset
    LD HL, ChangeSizeOffsetAdder
    addAToHL8_M
    LD A, (HL)                          ;get what would normally be offset adder
    OR A
    LD L, <PlayerGraphicsTable@smlSwim  ;load offset for small player swimming
    RET NZ                              ;branch to use offset if nonzero
    LD L, <PlayerGraphicsTable@bigSwim  ;otherwise load offset for big player swimming
    RET

;-------------------------------------------------------------------------------------
;   HL - Address to tile indexes for object
;   DE - Address to sprite data(SAT) for object
;   BC - Y POS, X POS
;   IXL - temp

DrawSpriteObject:
    LD IXL, E 
;   Sprite Y Position
    LD A, B
        ; Tile 0
    LD (DE), A
        ; Tile 1
    INC E
    LD (DE), A
        ; Prepare for next loop
    ADD A, $08
    LD B, A
;   Sprite X Position & Tile
    DEC E
    SLA E
    SET 7, E
        ; Tile 0
    LD A, C
    LD (DE), A
    INC E
    LDI
    INC BC
        ; Tile 1
    ADD A, $08
    LD (DE), A
    INC E
    LDI
    INC BC
;   Prepare for next loop
    LD E, IXL
    INC E
    INC E
    RET