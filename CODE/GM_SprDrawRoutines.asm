;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------

; .SECTION "VineYPosAdder" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; VineYPosAdder:
;     .db $00, $30
; .ENDS

.DEFINE VINE_TILE00 $47
.DEFINE VINE_TILE01 $48
.DEFINE VINE_TILE02 $49

.DEFINE FLAG_TILE00 $45
.DEFINE FLAG_TILE01 $46

.DEFINE LIFT_TILE   $51

.DEFINE BUBBLE_TILE $4A

DrawVine:
;   GET OBJECT ADDRESS
    LD C, A                                 ;save offset here
    LD HL, VineObjOffset                    ;get vine object
    ADD A, H
    LD H, A
    LD H, (HL)
;   GET OBJECT'S S.A.T. ADDRESS
    LD L, <Enemy_SprDataOffset              ;get vine's sprite data offset
    LD L, (HL)
    LD E, L                                 ;copy in E for later
    LD H, >Sprite_Y_Position
;   Y POSITION
    DEC C                                   ;add $30 to YPOS if offset is 1 (grow second vine)
    LD B, $00
    JR NZ, +
    LD B, $30
+:
    LD A, (Enemy_Rel_YPos)
    ADD A, B
    SUB A, SMS_PIXELYOFFSET                 ;subtract vertical res difference
    CP A, $D0                               ;skip if at sprite terminator
    JR Z, +
    LD (HL), A                              ;store for sprite data's YPOS
    .REPEAT $05
+:
    INC L                                   ;do this 5 more times...
    ADD A, $08                              ;add successive YPOS offset
    CP A, $D0
    JR Z, +
    LD (HL), A
    .ENDR
+:
    LD L, E                                 ;get back unmodified sprite data offset
;   X POSITION & TILE
    SLA L                                   ;get x position address by doubling and setting bit 7
    SET 7, L
    LD A, (Enemy_Rel_XPos)                  ;store x position and tile of all 6 sprites...
    LD B, A
    ADD A, $06
    LD (HL), B
    INC L
    LD E, L                                 ;copy 1st tile address in E for later
    LD (HL), VINE_TILE00
    INC L
    LD (HL), A
    INC L
    LD (HL), VINE_TILE01
    INC L
    LD (HL), B
    INC L
    LD (HL), VINE_TILE00
    INC L
    LD (HL), A
    INC L
    LD (HL), VINE_TILE01
    INC L
    LD (HL), B
    INC L
    LD (HL), VINE_TILE00
    INC L
    LD (HL), A
    INC L
    LD (HL), VINE_TILE01
    LD L, E                                 ;get 1st sprite's tile address
    INC C                                   ;if offset is 0 (on first vine), make top sprite be the vine 'end' 
    JR NZ, SkpVTop                          ;else, skip
    LD (HL), VINE_TILE02
;   OFFSCREEN CHECK
SkpVTop:
    DEC L                                   ;reset sprite address to be 1st YPos
    RES 7, L
    SRL L
    LD B, $06
ChkFTop:
    LD A, (VineStart_Y_Position)            ;get original starting vertical coordinate
    SUB A, (HL)                             ;subtract top-most sprite's Y coordinate
    CP A, $64                               ;if two coordinates are less than 100/$64 pixels
    JR C, NextVSp                           ;apart, skip this to leave sprite alone
    LD (HL), YPOS_OFFSCREEN                 ;otherwise move sprite offscreen
NextVSp:
    INC L                                   ;move offset to next OAM data
    DJNZ ChkFTop                            ;do this until all sprites are checked
    RET

;-------------------------------------------------------------------------------------

.SECTION "Sprite Drawing TBLs for Hammer" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG

; FirstSprYPos:
;     .db $00, $04, $00, $04

; SecondSprYPos:
;     .db $08, $00, $08, $00

; FirstSprXPos:
;     .db $04, $00, $04, $00

; SecondSprXPos:
;     .db $00, $08, $00, $08

; FirstSprTilenum:
;     .db $80, $82, $81, $83

; SecondSprTilenum:
;     .db $81, $83, $80, $82

;        Y0,  Y1,  X0,  T0,  X1,  T1, PAD, PAD 
HammerSpriteData:
    .db $00, $08, $04, $4B, $00, $4C, $00, $00    ; FIRST (DOWN)
    .db $04, $00, $00, $4D, $08, $4E, $00, $00    ; SECOND (LEFT)
    .db $00, $08, $04, $4C, $00, $4F, $00, $00    ; THIRD (UP)
    .db $04, $00, $00, $4E, $08, $50, $00, $00    ; FOURTH (RIGHT)
@Castle:
    .db $00, $08, $04, $68, $00, $69, $00, $00    ; FIRST (DOWN)
    .db $04, $00, $00, $6A, $08, $6B, $00, $00    ; SECOND (LEFT)
    .db $00, $08, $04, $69, $00, $6C, $00, $00    ; THIRD (UP)
    .db $04, $00, $00, $6B, $08, $6D, $00, $00    ; FOURTH (RIGHT)

; HammerSprAttrib:
;     .db $03, $03, $c3, $c3
.ENDS

DrawHammer:
    LD BC, HammerSpriteData                 ;use different set of hammmer sprites
    LD A, (AreaType)                        ;in castle area to get around Bowser's weird palette
    CP A, $03
    JR NZ, +
    LD C, <HammerSpriteData@Castle
+:
;   GET OBJECT'S S.A.T. ADDRESS
    LD D, H                                 ;get misc object OAM data offset
    INC D
    INC D                                   ;Misc_SprDataOffset
    LD E, <SprDataOffset
    LD A, (DE)
    LD IXL, A                               ;save S.A.T. address in IXL for later
    LD E, A
    LD D, >Sprite_Y_Position                ;DE: S.A.T. ADDRESS for 1st sprite's Ypos
;   CALCULATE HAMMER FRAME
    LD A, (TimerControl)                    ;if master timer control set, skip this part
    OR A
    JR NZ, RenderH
    ;
    LD L, <Misc_State                       ;otherwise get hammer's state
    LD A, (HL)
    AND A, %01111111                        ;mask out d7
    DEC A                                   ;check to see if set to 1 yet
    JR NZ, RenderH                          ;if so, branch
    ;
    LD A, (FrameCounter)                    ;get frame counter
    AND A, %00001100                        ;use d3-d2 to determine hammer frame (changes every four frames)
    ADD A, A
    ADD A, C
    LD C, A
;   Y POSITION
RenderH:
    LD L, C                                 ;move hammer frame data ptr to HL
    LD H, B
    ;
    LD A, (Misc_Rel_YPos)                   ;subtract y offset to adjust for SMS
    SUB A, SMS_PIXELYOFFSET

    ; FIX TO NOT TRIGGER SPRITE TERMINATOR
    CP A, $D0
    RET Z
    ; ---

    ADD A, (HL)                             ;add Ypos offsets from frame data to object's Ypos
    LD (DE), A                              ;and write to S.A.T.
    INC E
    INC L
    ADD A, (HL)
    LD (DE), A
    DEC E
    INC L
;   X POSITION & TILE
    SLA E                                   ;set S.A.T. address for 1st sprite's Xpos
    SET 7, E
    LD A, (Misc_Rel_XPos)
    ADD A, (HL)                             ;add Xpos offsets from frame data to object's Xpos
    LD (DE), A                              ;and write to S.A.T.
    INC E
    INC L
    LDI                                     ;also write frame's tiles
    ADD A, (HL)
    LD (DE), A
    INC E
    INC L
    LDI
;   OFFSCREEN CHECK
    LD HL, (ObjectOffset)                   ;get misc object offset
    LD A, (Misc_OffscrBits)                 ;check offscreen bits
    AND A, %11111100
    RET Z                                   ;if all bits clear, leave object alone
    LD L, <Misc_State                       ;otherwise nullify misc object state
    LD (HL), $00
    LD E, IXL                               ;and move hammer sprites offscreen
    LD D, >Sprite_Y_Position
    LD A, YPOS_OFFSCREEN
    LD (DE), A
    INC E
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------
;$00-$01 - used to hold tile numbers ($01 addressed in draw floatey number part)
;$02 - used to hold Y coordinate for floatey number
;$03 - residual byte used for flip (but value set here affects nothing)
;$04 - attribute byte for floatey number
;$05 - used as X coordinate for floatey number

.SECTION "FlagpoleScoreNumTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlagpoleScoreNumTiles:
    .db $31, $34    ; "5000"
    .db $2F, $34    ; "2000"
    .db $32, $33    ; "800"
    .db $30, $33    ; "400"
    .db $2E, $33    ; "100"
.ENDS

FlagpoleGfxHandler:
;   GET OBJECT'S S.A.T ADDRESS
    LD L, <SprDataOffset            ;get sprite data offset for flagpole flag
    LD E, (HL)
    LD D, >Sprite_Y_Position
;   Y POSITION
    LD L, <Enemy_Y_Position
    LD A, (HL)                      ;get vertical coordinate
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A                      ;and do sub to dump into first and second sprites
    INC E
    LD (DE), A
    ADD A, $08                      ;add eight pixels
    INC E
    LD (DE), A                      ;and store into third sprite
;   X POSITION & TILE
    LD L, <SprDataOffset
    LD E, (HL)                      ;get sprite data offset for flagpole flag
    SLA E
    SET 7, E
    EX DE, HL
    LD A, (Enemy_Rel_XPos)          ;get relative horizontal coordinate
    LD (HL), A                      ;store as X coordinate for first sprite
    INC L
    LD (HL), FLAG_TILE01            ;put triangle shaped tile into first
    ADD A, $08                      ;add eight pixels and store
    INC L
    LD (HL), A                      ;as X coordinate for second sprite
    INC L
    LD (HL), FLAG_TILE00            ;put skull tile into second sprite
    INC L
    LD (HL), A                      ;as X coordinate for third sprite
    INC L
    LD (HL), FLAG_TILE01            ;put triangle shaped tile into third
    EX DE, HL
;
    LD E, (HL)                      ;get sprite data offset for flagpole flag
    LD A, (Enemy_Rel_XPos)
    ADD A, $0C + $08                ;add twelve more pixels and
    LD C, A                         ;store here to be used later by floatey number
    LD A, (FlagpoleFNum_Y_Pos)      ;get vertical coordinate for floatey number
    SUB A, SMS_PIXELYOFFSET
    LD B, A                         ;store it here
;
    LD A, (FlagpoleCollisionYPos)   ;get vertical coordinate at time of collision
    OR A
    JR Z, ChkFlagOffscreen          ;if zero, branch ahead
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
    .REPEAT $04
    INC E
    LD (DE), A
    .ENDR
    RET

;-------------------------------------------------------------------------------------

DrawLargePlatform:
    LD D, >Sprite_Data
;   X POSITION & TILE
    LD L, <Enemy_SprDataOffset      ;get S.A.T. address for 1st sprite's Xpos
    LD E, (HL)
    SLA E
    SET 7, E
    ;
    LD B, LIFT_TILE                 ;cloud and lift share the same tile index
    LD A, (Enemy_Rel_XPos)          ;write Xpos and tile for all 6 sprites...
    EX DE, HL
    LD (HL), A
    INC L
    LD (HL), B
.REPEAT $05
    INC L
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), B
.ENDR
    EX DE, HL
;   Y POSITION
    LD L, <Enemy_SprDataOffset      ;get S.A.T. address for 1st sprite's Ypos
    LD E, (HL)
    LD L, <Enemy_Y_Position
    LD A, (HL)
    SUB A, SMS_PIXELYOFFSET         ;subtract y offset to adjust for SMS

    ; FIX TO NOT TRIGGER SPRITE TERMINATOR
    CP A, $D0
    RET Z
    ; ---
    .REPEAT $04
    LD (DE), A                      ;dump into first four sprites as Y coordinate
    INC E
    .ENDR
    ;
    LD B, A                         ;save coord in B for later
    LD A, (AreaType)                ;check for castle-type level
    CP A, $03
    LD A, YPOS_OFFSCREEN            ;load offscreen coordinate if flag set or castle-type level
    JR Z, SetLast2Platform          
    LD A, (SecondaryHardMode)       ;check for secondary hard mode flag set
    OR A
    LD A, YPOS_OFFSCREEN
    JR NZ, SetLast2Platform         ;branch if not set elsewhere
    LD A, B                         ;get back Ypos

SetLast2Platform:
    LD (DE), A                      ;make last two sprites either offscreen or same as the rest
    INC E
    LD (DE), A
;   OFFSCREEN CHECK
    CALL GetXOffscreenBits          ;get offscreen bits again
    LD D, >Sprite_Data              ;get S.A.T. address for 1st sprite's Ypos
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    LD C, A
    LD A, YPOS_OFFSCREEN
    SLA C                           ;rotate d7 into carry
    JR NC, SChk2
    LD (DE), A                      ;if d7 was set, move first sprite offscreen
SChk2:
    INC E
    SLA C                           ;rotate d6 into carry
    JR NC, SChk3
    LD (DE), A                      ;if d6 was set, move second sprite offscreen
SChk3:
    INC E
    SLA C                           ;rotate d5 into carry
    JR NC, SChk4
    LD (DE), A                      ;if d5 was set, move third sprite offscreen
SChk4:
    INC E
    SLA C                           ;rotate d4 into carry
    JR NC, SChk5
    LD (DE), A                      ;if d4 was set, move fourth sprite offscreen
SChk5:
    INC E
    SLA C                           ;rotate d3 into carry
    JR NC, SChk6
    LD (DE), A                      ;if d3 was set, move fifth sprite offscreen
SChk6:
    INC E
    SLA C                           ;rotate d2 into carry
    JR NC, SLChk
    LD (DE), A                      ;if d2 was set, move sixth sprite offscreen
SLChk:
    LD A, (Enemy_OffscrBits)        ;check d7 of offscreen bits
    ADD A, A
    RET NC                          ;and if d7 is not set, skip
    ;
    LD L, <Enemy_SprDataOffset      ;otherwise move all sprites offscreen
    LD E, (HL)
    LD A, YPOS_OFFSCREEN
    LD (DE), A
    .REPEAT $05
    INC E
    LD (DE), A
    .ENDR
    RET

;-------------------------------------------------------------------------------------

DrawFloateyNumber_Coin:
    LD L, <Misc_Y_Position
    LD A, (FrameCounter)            ;get frame counter
    RRCA                            ;divide by 2
    JR C, NotRsNum                  ;branch if d0 not set to raise number every other frame
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

.SECTION "JumpingCoinTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
JumpingCoinTiles:
    .db $19, $1B, $1D, $1F
.ENDS

JCoinGfxHandler:
;   GET S.A.T. ADDRESS
    LD D, H
    INC D
    INC D                           ;Misc_SprDataOffset

    LD E, <SprDataOffset            ;get coin/floatey number's OAM data offset
    LD A, (DE)
    LD E, A
    LD D, >Sprite_Y_Position
;
    LD L, <Misc_State
    LD A, (HL)                      ;get state of misc object
    CP A, $02                       ;if 2 or greater,
    JR NC, DrawFloateyNumber_Coin   ;branch to draw floatey number
;   YPOS
    LD L, <Misc_Y_Position
    LD A, (HL)                      ;store vertical coordinate as
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A                      ;Y coordinate for first sprite
    ADD A, $08                      ;add eight pixels
    INC E
    LD (DE), A                      ;store as Y coordinate for second sprite
;   XPOS
    DEC E                           ;(SMS)
    SLA E
    SET 7, E
    LD A, (Misc_Rel_XPos)           ;get relative horizontal coordinate
    LD (DE), A
    INC E
    INC E
    LD (DE), A                      ;store as X coordinate for first and second sprites
;   SPRITE FRAME CALC
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

.SECTION "PowerUpGfxTable" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
PowerUpGfxTable:
    .db $09, $0A, $0B, $0C  ; mushroom
    .db $11, $12, $13, $14  ; fire flower
    .db $15, $16, $17, $18  ; star
    .db $0D, $0E, $0F, $10  ; 1-up mushroom
.ENDS

DrawPowerUp:
;   OFFSCREEN CHECK
    LD HL, (Enemy_Y_Position_05)            ;don't display powerup if it is below visible screen
    LD DE, $01D8                            ;to avoid sprite terminator
    OR A
    SBC HL, DE
    JP NC, SprObjectOffscrChk
;   GET OBJECT'S S.A.T. ADDRESS
    LD A, (Enemy_SprDataOffset_05)          ;get power-up's sprite data offset
    LD E, A
    LD D, >Sprite_Y_Position
;   X/YPOS REG SETUP
    LD A, (Enemy_Rel_YPos)                  ;get relative vertical coordinate
    ADD A, $08 - SMS_PIXELYOFFSET           ;add eight pixels (-SMS offset)
    LD B, A                                 ;store result here
    LD A, (Enemy_Rel_XPos)                  ;get relative horizontal coordinate
    LD C, A                                 ;store here
;   TILE SETUP
    LD A, (PowerUpType)                     ;get power-up type
    ADD A, A
    ADD A, A
    LD HL, PowerUpGfxTable
    addAToHL8_M
;   WRITE TO S.A.T.
    CALL DrawSpriteObject                   ;draw first row of our power-up object
    CALL DrawSpriteObject                   ;draw second row of our power-up object
;   OBJECT OFFSCREEN CHECK
    JP SprObjectOffscrChk                   ;jump to check to see if power-up is offscreen at all, then leave
    
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

.INCLUDE "ASSETS/MAP_Enemy.inc"

.SECTION "EnemyGfxTableOffsets" BANK BANK_SLOT2 SLOT 2 BITWINDOW 8 RETURNORG
EnemyGfxTableOffsets:
    .dw EnemyGraphicsTable_Arr0@GKoopa
    .dw EnemyGraphicsTable_Arr0@RKoopa
    .dw EnemyGraphicsTable_Arr0@Beetle
    .dw EnemyGraphicsTable_Arr0@RKoopa
    .dw EnemyGraphicsTable_Arr0@GKoopa
    .dw EnemyGraphicsTable_Arr0@HammerBro
    .dw EnemyGraphicsTable_Arr0@Goomba
    .dw EnemyGraphicsTable_Arr0@Blooper

    .dw EnemyGraphicsTable_Arr0@Bullet
    .dw EnemyGraphicsTable_Arr0@GPKoopa
    .dw EnemyGraphicsTable_Arr0@GCheep
    .dw EnemyGraphicsTable_Arr0@RCheep
    .dw $0000
    .dw EnemyGraphicsTable_Arr0@Piranha
    .dw EnemyGraphicsTable_Arr0@GPKoopa
    .dw EnemyGraphicsTable_Arr0@RPKoopa

    .dw EnemyGraphicsTable_Arr0@GPKoopa
    .dw EnemyGraphicsTable_Arr0@Lakitu
    .dw EnemyGraphicsTable_Arr0@Spiny
    .dw $0000
    .dw EnemyGraphicsTable_Arr0@RCheep
.ENDS

EnemyGfxHandler:
    LD L, <Enemy_Y_Position                 ;don't display enemy if it is below visible screen
    LD A, (HL)                              ;to avoid sprite terminator
    INC L
    LD H, (HL)
    LD L, A
    LD DE, $01D0                                
    OR A
    SBC HL, DE
    JP NC, SprObjectOffscrChk
    LD HL, (ObjectOffset)
;
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
    LD L, <Enemy_MovingDir                  ;get enemy object moving direction
    LD A, (HL)
    LD IXL, A
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
    JR NZ, SaveEnemyObject                  ;if not found, branch again
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
    CP A, $0C                               ;check for podoboo object
    JP Z, PodobooGfxHandler                 ;branch if found

CheckForGoomba:
    ;LD A, IYH                
    LD C, A
    CP A, OBJECTID_Goomba                   ;check value for goomba object
    JR NZ, CheckForSpiny                    ;branch if not found
;
    LD L, <Enemy_State
    LD A, (HL)
    CP A, $02                               ;check for defeated state
    JR C, GmbaAnim                          ;if not defeated, go ahead and animate
    LD IXH, $04                             ;if defeated, write new value here
GmbaAnim:
    AND A, %00100000                        ;check for d5 set in enemy object state
    LD HL, TimerControl
    OR A, (HL)                              ;or timer disable flag set
    JR NZ, CheckForSpiny                    ;if either condition true, do not animate goomba
    LD A, (FrameCounter)
    AND A, %00001000                        ;check for every eighth frame
    JR NZ, CheckForSpiny
    LD A, %00000011
    XOR A, IXL                              ;invert bits to flip horizontally every eight frames
    LD IXL, A                               ;leave alone otherwise              

CheckForSpiny:
    LD A, C
    ADD A, A
    LD HL, EnemyGfxTableOffsets             ;load value based on enemy object as offset
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
;
    LD C, IXH
;
    LD A, L                                 ;check if value loaded is for spiny (low byte)
    CP A, <EnemyGraphicsTable_Arr0@Spiny
    JR NZ, CheckForLakitu                   ;if not found, branch
;
    LD A, C                                 ;if enemy state set to $05, do this,
    CP A, $05
    JR NZ, CheckForHammerBro                ;otherwise branch
;
    LD HL, EnemyGraphicsTable_Arr0@SpinyEgg ;set to spiny egg offset
    LD IX, $0502                            ;set enemy direction and state
    JP CheckForHammerBro

CheckForLakitu:
    LD A, L                                 ;check value for lakitu's offset loaded (low)
    CP A, <EnemyGraphicsTable_Arr0@Lakitu                               
    JR NZ, CheckUpsideDownShell             ;branch if not loaded
;
    LD A, IYL
    AND A, %00100000                        ;check for d5 set in enemy state
    JP NZ, CheckDefeatedState               ;branch if set
;
    LD A, (FrenzyEnemyTimer)
    CP A, $10                               ;check timer to see if we've reached a certain range
    JP NC, CheckDefeatedState               ;branch if not
;
    LD HL, EnemyGraphicsTable_Arr0@LakituAlt;if d6 not set and timer in range, load alt frame for lakitu
    JP CheckDefeatedState                   ;skip this next part if we found lakitu but alt frame not needed

CheckUpsideDownShell:
    LD A, IYH                               ;check for enemy object => $04
    CP A, $04
    JR NC, CheckRightSideUpShell            ;branch if true
;
    LD A, C
    CP A, $02
    JR C, CheckRightSideUpShell             ;branch if enemy state < $02
;
    LD HL, EnemyGraphicsTable_Arr0@BeetleUSD;set for upside-down buzzy beetle shell by default
    INC D                                   ;increment vertical position by one pixel
    LD A, IYH
    ;LD C, A
    CP A, OBJECTID_BuzzyBeetle              ;check for buzzy beetle object
    JR Z, CheckRightSideUpShell
    DEC D                                   ;revert vertical position
    LD HL, EnemyGraphicsTable_Arr0@GKoopaUSD;set for upside-down koopa shell by default (GREEN)
    OR A                                    ;$00 = Green Koopa
    JR Z, CheckRightSideUpShell
    LD HL, EnemyGraphicsTable_Arr0@RKoopaUSD;set for upside-down koopa shell (RED)

CheckRightSideUpShell:
    LD A, IXH                               ;check for value set here
    CP A, $04                               ;if enemy state < $02, do not change to shell, if
    JR NZ, CheckForHammerBro                ;enemy state => $02 but not = $04, leave shell upside-down
;
    LD HL, EnemyGraphicsTable_Arr0@BeetleRSU;set right-side up buzzy beetle shell by default
    INC D                                   ;increment saved vertical position by one pixel
    LD A, IYH
    LD C, A
    CP A, OBJECTID_BuzzyBeetle              ;check for buzzy beetle object
    JR Z, CheckForDefdGoomba                ;branch if found
;
    INC D                                   ;and increment saved vertical position again
    LD HL, EnemyGraphicsTable_Arr0@GKoopaRSU;change to right-side up koopa shell if not found (GREEN)
    CP A, $01
    JR Z, +                                 ;check if koopa isn't green
    CP A, OBJECTID_RedKoopa
    JR Z, +
    CP A, OBJECTID_RedParatroopa            ;check if paratroopa isn't red
    JR NZ, CheckForDefdGoomba
+:
    LD HL, EnemyGraphicsTable_Arr0@RKoopaRSU;else, change to right-side up koopa shell (RED)

CheckForDefdGoomba:
    LD A, C                                 ;check for goomba object (necessary if previously
    CP A, OBJECTID_Goomba
    JR NZ, CheckForHammerBro                ;failed buzzy beetle object test)
;
    LD HL, EnemyGraphicsTable_Arr0@Goomba   ;load for regular goomba
    LD A, IYL                               ;note that this only gets performed if enemy state => $02
    AND A, %00100000                        ;check saved enemy state for d5 set
    JR NZ, CheckForHammerBro                ;branch if set
;
    LD HL, EnemyGraphicsTable_Arr0@GoombaDefeat ;load offset for defeated goomba
    DEC D                                   ;set different value and decrement saved vertical position

CheckForHammerBro:
    LD A, IYH                               ;check for hammer bro object
    CP A, OBJECTID_HammerBro
    JR NZ, CheckForBloober                  ;branch if not found
;
    LD A, IYL                               ;branch if not in normal enemy state
    OR A
    JR Z, CheckToAnimateEnemy
;
    AND A, %00001000                        ;if d3 not set, branch further away
    JR Z, CheckDefeatedState
;
    LD HL, EnemyGraphicsTable_Arr0@HammerBro_Alt    ;otherwise load offset for different frame
    JP CheckToAnimateEnemy

CheckForBloober:
    LD A, L                                 ;check for green cheep-cheep offset loaded
    CP A, <EnemyGraphicsTable_Arr0@GCheep
    JR Z, CheckToAnimateEnemy               ;branch if found
    CP A, <EnemyGraphicsTable_Arr0@RCheep   ;check for red cheep-cheep offset loaded
    JR Z, CheckToAnimateEnemy               ;branch if found
;
    LD A, (ObjectOffset + $01)
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    LD C, A
    CP A, $05                               ;branch if some timer is above a certain point
    JR NC, CheckDefeatedState
;
    LD A, L                                 ;check for bloober offset loaded (low)
    CP A, <EnemyGraphicsTable_Arr0@Blooper
    JR NZ, CheckToAnimateEnemy              ;branch if not found this time
;
    LD A, C
    DEC A                                   ;branch if timer is set to certain point
    JR Z, CheckDefeatedState
;
    INC D                                   ;increment saved vertical coordinate three pixels
    INC D
    INC D
    JP CheckAnimationStop

CheckToAnimateEnemy:
    LD A, IYH                               ;check for specific enemy objects
    CP A, OBJECTID_Goomba
    JR Z, CheckDefeatedState                ;branch if goomba
    CP A, $08
    JR Z, CheckDefeatedState                ;branch if bullet bill (note both variants use $08 here)
    CP A, $18
    JR NC, CheckDefeatedState               ;branch if => $18

CheckForSecondFrame:
    LD A, (FrameCounter)                    ;load frame counter
    AND A, $08                              ;mask it
    JR NZ, CheckDefeatedState               ;branch if timing is off

CheckAnimationStop:
    LD A, (TimerControl)
    LD C, A
    LD A, IYL                               ;check saved enemy state
    AND A, %10100000                        ;for d7 or d5, or check for timers stopped
    OR A, C
    JR NZ, CheckDefeatedState               ;if either condition true, branch
;
    LD A, $06                               ;add $06 to current enemy offset
    addAToHL_M                              ;to animate various enemy objects

CheckDefeatedState:
    LD A, IYL                               ;check saved enemy state
    AND A, %00100000                        ;for d5 set
    JR Z, DrawEnemyObject                   ;branch if not set
;
    LD A, IYH                               ;check for saved enemy object => $04
    CP A, $04                               ;branch if less
    JR C, DrawEnemyObject
;
    LD A, L                                 ;check if enemy is bullet bill
    CP A, <EnemyGraphicsTable_Arr0@Bullet   ;if so, don't use death sprite
    JR Z, DrawEnemyObject
;
    LD A, $FA                               ;subtract 6 to point to death sprite
    DEC H
    addAToHL_M
    ;LD IXH, $00                             ;init saved value here
    JR DrawEnemyObject_NoHFlip              ;don't try to flip it horizontally

DrawEnemyObject:
    DEC IXL                                 ;check which way enemy is facing
    JR Z, DrawEnemyObject_NoHFlip
    LD A, $0C                               ;add 12 to point to horizontally flipped sprite
    addAToHL_M

DrawEnemyObject_NoHFlip:
    LD B, D                                 ;put vertical pos into B
    LD A, (Temp_Bytes + $05)                ;put horizontal pos into C
    LD C, A

    LD A, (EnemyGFXBank)                    ;point to the correct table       
    OR A, H
    LD H, A

    LD A, BANK_ENEMYTBL                     ;set bank for GFX tables
    LD (MAPPER_SLOT2), A

    LD D, >Sprite_Y_Position                ;set up SAT pointer
    LD IXL, E
    LD A, B
    DrawSpriteObject_YPos                   ;draw six tiles of data
    DrawSpriteObject_YPos
    LD (DE), A                              ;DrawSpriteObject_YPos
    INC E
    LD (DE), A
    LD E, IXL
    SLA E
    SET 7, E
    DrawSpriteObject_XT
    DrawSpriteObject_XT
    LD A, C                                 ;DrawSpriteObject_XT
    LD (DE), A
    INC E
    LDI
    INC BC
    ADD A, $08
    LD (DE), A
    INC E
    LDI
    ; FALL THROUGH

    LD A, BANK_SLOT2                        ;reset bank
    LD (MAPPER_SLOT2), A

SprObjectOffscrChk:
    LD D, >Sprite_Y_Position                ;set up SAT pointer
    LD HL, (ObjectOffset)                   ;get enemy buffer offset
    LD A, (Enemy_OffscrBits)                ;check offscreen information
    LD C, A
    SRL C                                   ;shift three times to the right
    SRL C                                   ;which puts d2 into carry
    SRL C
    LD A, $01                               ;if carry, move right column sprites offscreen
    CALL C, MoveESprColOffscreen
;
    SRL C                                   ;move d3 to carry
    LD A, $00                               ;if carry, move left column sprites offscreen
    CALL C, MoveESprColOffscreen
;
    SRL C                                   ;move d5 to carry this time
    SRL C
    LD A, $04                               ;if carry, move third row of sprites offscreen
    CALL C, MoveESprRowOffscreen
;
    SRL C                                   ;move d6 into carry
    LD A, $02
    CALL C, MoveESprRowOffscreen            ;if carry, move second and third rows offscreen
;
    SRL C                                   ;move d7 into carry
    RET NC
    XOR A                                   ;if carry, move all sprites offscreen
    CALL MoveESprRowOffscreen
;
    LD L, <Enemy_ID                         ;check enemy identifier for podoboo
    LD A, (HL)
    CP A, OBJECTID_Podoboo
    RET Z                                   ;skip this part if found, we do not want to erase podoboo!
    LD L, <Enemy_Y_HighPos                  ;check high byte of vertical position
    LD A, (HL)
    CP A, $02                               ;if not yet past the bottom of the screen, branch
    RET NZ
    JP EraseEnemyObject

MoveESprRowOffscreen:
    LD L, <Enemy_SprDataOffset              ;add A to enemy object OAM data offset
    ADD A, (HL)
    LD E, A
;
    LD A, YPOS_OFFSCREEN                    ;move first row of sprites offscreen
    LD (DE), A
    INC E
    LD (DE), A
    RET

MoveESprColOffscreen:
    LD L, <Enemy_SprDataOffset              ;add A to enemy object OAM data offset
    ADD A, (HL)
    LD E, A
;
    LD A, YPOS_OFFSCREEN                    ;move first, second, and third row sprites in column offscreen
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    RET

PodobooGfxHandler:
;   VERTICAL FLIP CHECK
    LD L, <Enemy_Y_Speed                    ;use v-flipped tiles if y speed is positive
    LD A, (HL)
    OR A
    LD HL, PodobooTiles
    JP M, +
    LD L, <PodobooTiles + $08
+:
;   ANIMATION CHECK
    LD A, (FrameCounter)                    ;load frame counter
    AND A, $08                              ;mask it
    JR NZ, +                                ;branch if timing is off
    LD A, (TimerControl)
    LD C, A
    LD A, IYL                               ;check saved enemy state
    AND A, %10100000                        ;for d7 or d5, or check for timers stopped
    OR A, C
    JR NZ, +                                ;if either condition true, branch
    LD A, $04                               ;add 4 to point to second frame
    addAToHL8_M
+:
;   X/YPOS REG SETUP
+:
    LD A, D                                 ;add 8 to vertical coordinate (podoboo is only 16px tall)
    ADD A, $08

    ; FIX TO NOT TRIGGER SPRITE TERMINATOR
    CP A, $D0
    JR NZ, +
    INC A
+:
    ; ---
    LD B, A                                 ;store vertical coord in B

    LD A, (Temp_Bytes + $05)                ;store horizontal coord in C
    LD C, A
;   WRITE TO S.A.T.
    LD D, >Sprite_Y_Position
    INC E
    INC E
    CALL DrawSpriteObject                   ;draw row 0
    CALL DrawSpriteObject                   ;draw row 1
;   OBJECT OFFSCREEN CHECK
    JP SprObjectOffscrChk

.SECTION "Podoboo Tiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
PodobooTiles:
    .db $52, $53, $54, $55  ; FRAME 0
    .db $5A, $5B, $5C, $5D  ; FRAME 1
    .db $56, $57, $58, $59  ; FRAME 0 VFLIP
    .db $5E, $5F, $60, $61  ; FRAME 1 VFLIP
.ENDS

;   --- NAMETABLE OBJECT DRAW ROUTINES ---

RetainerGfxHandler:
;   EXIT IF RETAINER/PRINCESS HAS ALREADY BEEN DRAWN
    LD A, (RetainerDrawnFlag)
    OR A
    RET NZ
;   SET FLAG TO SIGNAL THAT IT HAS BEEN DRAWN
    INC A
    LD (RetainerDrawnFlag), A
;   CALCULATE WHERE IT SHOULD BE DRAWN
    LD L, <Enemy_Y_Position                 ;get enemy object vertical position
    CALL CalculateNTAddr
;   WRITE TILE DATA TO VRAM BUFFER
    ; RIGHT SIDE
    INC L
    INC L
    PUSH HL
    CALL StripeBufferSetup
    LD A, (WorldNumber)
    CP A, WORLD8
    LD HL, RetainerTilesRight + $05
    JR NZ, +
    LD HL, PrincessTilesRight + $05
+:
    CALL NTObjectDrawSide
    POP HL
    ; LEFT SIDE
    DEC L
    DEC L
    CALL StripeBufferSetup
    LD A, (WorldNumber)
    CP A, WORLD8
    LD HL, RetainerTilesLeft + $05
    JR NZ, +
    LD HL, PrincessTilesLeft + $05
+:
    JP NTObjectDrawSide

JumpspringGfxHandler:
;   EXIT IF JUMPSPRING FRAME HASN'T CHANGE
    LD A, (JumpspringAnimCtrl_Old)
    LD B, A
    LD A, (JumpspringAnimCtrl)
    CP A, B
    RET Z
    LD (JumpspringAnimCtrl_Old), A
;   CALCULATE WHERE IT SHOULD BE DRAWN
    LD L, <Jumpspring_FixedYPos             ;get fixed y position of jumpspring
    CALL CalculateNTAddr
;   WRITE TILE DATA TO VRAM_BUFFER
    ; RIGHT SIDE
    INC L
    INC L
    PUSH HL
    CALL StripeBufferSetup
    LD HL, JumpspringFramesRight + $05
    LD A, (JumpspringAnimCtrl)
    ADD A, A
    ADD A, A
    ADD A, A
    addAToHL8_M
    CALL NTObjectDrawSide
    POP HL
    ; LEFT SIDE
    LD A, (Enemy_OffscrBits)
    BIT 3, A
    RET NZ
    DEC L
    DEC L
    CALL StripeBufferSetup
    LD HL, JumpspringFramesLeft + $05
    LD A, (JumpspringAnimCtrl)
    ADD A, A
    ADD A, A
    ADD A, A
    addAToHL8_M
    ; FALL THROUGH

;   --- NAMETABLE DRAW HELPER ROUTINES ---

NTObjectDrawSide:
    LDD                                     ;store tile 2's tile data
    LDD
    DEC E                                   ;skip its NT address and count as it's already been written...
    DEC E
    DEC E
    LDD                                     ;store tile 1's tile data
    LDD
    DEC E                                   ;skip its NT address and count as it's already been written...
    DEC E
    DEC E
    LDD                                     ;store tile 0's tile data
    LDD
    RET

CalculateNTAddr:
    ;LD L, <Enemy_Y_Position                 ;get enemy object vertical position
    LD A, (HL)
    SUB A, SMS_PIXELYOFFSET                 ;subtract SMS Y offset
    AND A, $F8                              ;round down to closest tile (multiple of 8)
    LD L, A
    LD H, (>VRAMWRITE | >VRAM_ADR_NAMETBL) >> $03 ;$0C
    ADD HL, HL                              ;left shift by 3 (d12-d6 determine row)
    ADD HL, HL
    ADD HL, HL
    ;
    LD A, (ScreenLeft_X_Pos)                ;add left-edge of screen to enemy object horizontal position
    LD B, A                                 ;to get real x coordinate
    LD A, (Enemy_Rel_XPos)
    ADD A, B
    AND A, $F8                              ;round down to closest tile (multiple of 8)
    RRCA                                    ;right shift by 2 (d5-d0 determine column)
    RRCA
    OR A, L                                 ;combine with row to get final result
    LD L, A
    RET

StripeBufferSetup:
    LD DE, (VRAM_Buffer1_Ptr)               ;get VRAM_Buffer1's ptr
    EX DE, HL                               ;DE: NT address, HL: *VRAM_Buffer1_Ptr
;
    LD (HL), D                              ;store tile 0's NT address and count
    INC L
    LD (HL), E
    INC L
    LD (HL), StripeCount($02)
    INC L                                   ;skip actual tile data for now...
    INC L
    INC L
;
    LD A, $40                               ;store tile 1's NT address and count
    addAToDE_M
    LD (HL), D
    INC L
    LD (HL), E
    INC L
    LD (HL), StripeCount($02)
    INC L                                   ;skip actual tile data for now...
    INC L
    INC L
;
    LD A, $40                               ;store tile 2's NT address and count
    addAToDE_M
    LD (HL), D
    INC L
    LD (HL), E
    INC L
    LD (HL), StripeCount($02)
    INC L                                   ;skip actual tile data for now...
    INC L
    INC L
;
    LD (HL), $00                            ;store terminator
    LD (VRAM_Buffer1_Ptr), HL               ;update buffer ptr
    DEC L
    EX DE, HL                               ;DE: *VRAM_Buffer1_Ptr, HL: NT address
    RET

.SECTION "Jumpspring Frames" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
JumpspringFramesLeft:
    .dw $095A, $095B, $0D5A, $0000  ; F1
    .dw $0000, $095C, $0D5C, $0000  ; F2
    .dw $0000, $0000, $095D, $0000  ; F3
    .dw $0000, $095C, $0D5C, $0000  ; F2
    .dw $095A, $095B, $0D5A, $0000  ; F1

JumpspringFramesRight:
    .dw $0B5A, $0B5B, $0F5A, $0000
    .dw $0000, $0B5C, $0F5C, $0000
    .dw $0000, $0000, $0B5D, $0000
    .dw $0000, $0B5C, $0F5C, $0000
    .dw $0B5A, $0B5B, $0F5A, $0000
.ENDS

.SECTION "Retainer/Princess Tiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
RetainerTilesLeft:
    .dw $0983, $0984, $0985

RetainerTilesRight:
    .dw $0B83, $0B84, $0B85

PrincessTilesLeft:
    .dw $0986, $0987, $0988

PrincessTilesRight:
    .dw $0989, $098A, $098B
.ENDS

;-------------------------------------------------------------------------------------
;$00-$01 - tile numbers
;$02 - relative Y position
;$03 - horizontal flip flag (not used here)
;$04 - attributes
;$05 - relative X position
;IYL - OAM Offset

.SECTION "DefaultBlockObjTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
DefaultBlockObjTiles:
    .db $3B, $3B, $3B, $3B              ;breakable block
    .db $40, $40, $3B, $3B              ;brick w/ line (these are sprite tiles, not BG!)
    .db $37, $38, $39, $3A              ;empty block
.ENDS

DrawBlock:
;   X/YPOS REG STEUP
    LD A, (Block_Rel_YPos)          ;get relative vertical coordinate of block object
    SUB A, SMS_PIXELYOFFSET
    LD B, A                         ;store here
    LD A, (Block_Rel_XPos)          ;get relative horizontal coordinate of block object
    LD C, A                         ;store here
;   GET OBJECT'S S.A.T. ADDRESS
    LD D, H
    DEC D                           ;Block_SprDataOffset
    
    LD E, <SprDataOffset            ;get sprite data offset
    LD A, (DE)
    LD IYL, A                       ;copy to IYL for later
    LD E, A

    LD D, >Sprite_Y_Position
    PUSH HL                         ;save object offset to stack
;   TILE SETUP
    LD A, (AreaType)                ;if areatype is overworld, use brick with line
    DEC A
    LD L, <Block_Metatile
    LD A, (HL)
    LD HL, DefaultBlockObjTiles     ;assume brick with no line
    JR NZ, +
    LD L, <DefaultBlockObjTiles + $04
+:
    CP A, MT_EMPTYBLK               ;also check for empty block
    JR NZ, +
    LD L, <DefaultBlockObjTiles + $08   ;if so, draw that
;   SEND TO S.A.T.
+:
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    POP HL                          ;get back object offset
;   OFFSCREEN CHECK
    LD D, >Sprite_Y_Position        ;reset S.A.T. address to 1st sprite's Ypos
    LD E, IYL
    ; RIGHT SIDE
    LD A, (Block_OffscrBits)        ;get offscreen bits for block object
    PUSH AF                         ;save to stack
    AND A, %00000100                ;check to see if d2 in offscreen bits are set
    JR Z, PullOfsB                  ;if not set, branch, otherwise move sprites offscreen
    LD A, YPOS_OFFSCREEN            ;move offscreen two OAMs
    INC E                           ;on the right side
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    ; LEFT SIDE
PullOfsB:
    POP AF                          ;pull offscreen bits from stack
    AND A, %00001000                ;check to see if d3 in offscreen bits are set
    RET Z                           ;if not set, branch, otherwise move sprites offscreen
    LD E, IYL                       ;reset S.A.T. address to 1st sprite's Ypos
    LD A, YPOS_OFFSCREEN            ;move offscreen two OAMs
    LD (DE), A                      ;on the left side
    INC E
    INC E
    LD (DE), A
    RET
    
;-------------------------------------------------------------------------------------
;$00(IXL) - used to hold palette bits for attribute byte or relative X position
;$01(IXH)
DrawBrickChunks:
;   CALCULATE SPRDATAOFFSET
    LD D, H
    DEC D                                   ;Block_SprDataOffset
    LD E, <SprDataOffset
    LD A, (DE)
    LD E, A
    LD D, >Sprite_Y_Position                ;get OAM data offset
    LD IXH, A
;   STORE Y POSITIONS
    LD A, (Block_Rel_YPos)                  ;get first block object's relative vertical coordinate
    SUB A, SMS_PIXELYOFFSET
    
    ; FIX TO NOT TRIGGER SPRITE TERMINATOR
    CP A, $D0
    JP NZ, +
    INC A
+:
    ; ---

    LD (DE), A                              ;dump current Y coordinate into two sprites
    INC E
    LD (DE), A
    LD A, (Block_Rel_YPos_01)               ;get second block object's relative vertical coordinate
    SUB A, SMS_PIXELYOFFSET

    ; FIX TO NOT TRIGGER SPRITE TERMINATOR
    CP A, $D0
    JP NZ, +
    INC A
+:
    ; ---

    INC E                                   ;dump into Y coordinates of third and fourth sprites
    LD (DE), A
    INC E
    LD (DE), A
;   STORE ALL TILE IDS
    LD E, IXH
    SLA E
    SET 7, E
    INC E
    LD A, (FrameCounter)                    ;use frame counter to determine brick tile
    RRCA
    RRCA
    AND A, $03
    ADD A, $3C
    LD (DE), A                              ;dump tile number into all four sprites
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
    ; 1ST BLOCK OBJ
    LD E, IXH
    SLA E
    SET 7, E
    LD A, (Block_Rel_XPos)                  ;get first block object's relative horizontal coordinate
    LD (DE), A                              ;save into X coordinate of first sprite
    LD A, (ScreenLeft_X_Pos)
    LD C, A
    LD L, <Block_Orig_XPos                  ;get original horizontal coordinate
    LD A, (HL)
    SUB A, C                                ;subtract coordinate of left side from original coordinate
    LD IXL, A                               ;store result as relative horizontal coordinate of original
    LD A, (DE)
    LD C, A
    LD A, IXL                               ;get difference of relative positions of original - current
    SUB A, C
    CCF                                     ;carry inversion for z80
    ADC A, IXL                              ;add original relative position to result
    ADC A, $06                              ;plus 6 pixels to position second brick chunk correctly
    INC E
    INC E
    LD (DE), A                              ;save into X coordinate of second sprite
    ; 2ND BLOCK OBJ
    LD A, (Block_Rel_XPos_01)               ;get second block object's relative horizontal coordinate
    INC E
    INC E
    LD (DE), A                              ;save into X coordinate of third sprite
    LD C, A
    LD A, IXL                               ;use original relative horizontal position
    SUB A, C                                ;get difference of relative positions of original - current
    CCF                                     ;carry inversion for z80
    ADC A, IXL                              ;add original relative position to result
    ADC A, $06                              ;plus 6 pixels to position fourth brick chunk correctly
    INC E
    INC E
    LD (DE), A                              ;save into X coordinate of fourth sprite
;   OFFSCREEN CHECK (YPOS?)
    LD E, IXH
    LD A, (Block_OffscrBits)                ;get offscreen bits for block object
    AND A, %00001000                        ;check to see if d3 in offscreen bits are set
    JP Z, +                                 ;if not set, branch, otherwise move sprites offscreen
    LD A, YPOS_OFFSCREEN                    ;move offscreen two OAMs
    LD (DE), A                              ;on the left side               
    INC E
    INC E
    LD (DE), A
+:
    LD E, IXH
    LD A, (Block_OffscrBits)                ;get offscreen bits again
    ADD A, A                                ;shift d7 into carry
    JP NC, ChnkOfs                          ;if d7 not set, branch to last part
    LD A, YPOS_OFFSCREEN                    ;otherwise move top sprites offscreen
    LD (DE), A
    INC E
    LD (DE), A
;   OFFSCREEN CHECK (XPOS?)
ChnkOfs:
    LD A, IXL                               ;if relative position on left side of screen,
    OR A
    RET P                                   ;go ahead and leave
    LD E, IXH
    SLA E
    SET 7, E
    LD A, (DE)                              ;otherwise compare left-side X coordinate...
    INC E
    INC E
    EX DE, HL
    CP A, (HL)                              ;to right-side X coordinate
    EX DE, HL
    RET C                                   ;branch to leave if less
    LD E, IXH                               ;otherwise move right half of sprites offscreen
    LD A, YPOS_OFFSCREEN
    INC E
    LD (DE), A
    INC E
    INC E
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------

DrawFireball:
;   GET OBJECT'S S.A.T. ADDRESS
    LD A, H
    ADD A, >FBall_SprDataOffset - >Fireball_State
    LD D, A
    LD E, <SprDataOffset
    LD A, (DE)
    LD E, A
    LD D, >Sprite_Y_Position
;   Y POSITION
    LD A, (Fireball_Rel_YPos)               ;get relative vertical coordinate
    SUB A, SMS_PIXELYOFFSET

    ; FIX TO NOT TRIGGER SPRITE TERMINATOR
    CP A, $D0
    JP NZ, +
    INC A
+:
    ; ---

    LD (DE), A                              ;store as sprite Y coordinate
;   X POSITION
    SLA E
    SET 7, E
    LD A, (Fireball_Rel_XPos)               ;get relative horizontal coordinate
    LD (DE), A                              ;store as sprite X coordinate, then do shared code
;   TILE
;DrawFirebar:
    INC E
    LD A, (FrameCounter)                    ;get frame counter
    RRCA                                    ;divide by four
    RRCA
    AND A, $03                              ;use d3-d2 to determine fireball sprite
    ADD A, $21
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------
; IXL

.SECTION "ExplosionTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
ExplosionTiles:
    .db $25, $26, $2A
.ENDS

DrawExplosion_Fireball:
;   GET OBJECT'S S.A.T. ADDRESS
    LD A, H
    ADD A, >Alt_SprDataOffset - >Fireball_State
    LD D, A
    LD E, <SprDataOffset
    LD A, (DE)
    LD IXL, A
;   GET TILE FRAME
    LD L, <Fireball_State                   ;load fireball state
    LD A, (HL)
    INC (HL)                                ;increment state for next frame
    RRCA                                    ;divide by 2
    AND A, %00000111                        ;mask out all but d2-d0
    CP A, $03                               ;check to see if time to kill fireball
    JP C, DrawExplosion_Fireworks@SkipSprOffset ; if not, draw explosion
    LD (HL), $00                            ;else, KILL IT
    RET

DrawExplosion_Fireworks:
    LD IXL, E
@SkipSprOffset:
    LD DE, ExplosionTiles                   ;use whatever's in A for offset
    addAToDE8_M                             ;get tile number using offset
    LD A, (DE)
;   STORE 1ST TILE
    LD D, >Sprite_Y_Position
    LD E, IXL
    SLA E           
    SET 7, E
    INC E                                   ;dump 1st tile number
    LD (DE), A
    ;
    CP A, $25                               ;jump if doing a multi-sprite explosion (not frame 0)
    JP NZ, @MultiSprExplode
;   SINGLE SPRITE EXPLOSION
    ; XPOS
    DEC E
    LD A, (Fireball_Rel_XPos)               ;store relative horizontal coordinate
    LD (DE), A
    ; YPOS
    LD E, IXL
    LD A, (Fireball_Rel_YPos)               ;store relative vertical coordinate
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A
    LD A, YPOS_OFFSCREEN                    ;move unused sprites offscreen
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    RET
;   MULTI SPRITE EXPLOSION
@MultiSprExplode:
    ; XPOS/TILE
    EX DE, HL                               ;DE: N/A, HL: S.A.T. address
    LD C, A                                 ;move tile ID to C
    LD A, (Fireball_Rel_XPos)               ;get relative horizontal coordinate
    SUB A, $04                              ;subtract four pixels horizontally
    DEC L                                   ;for first sprite
    LD (HL), A
    INC L
        ; SPRITE 1
    INC L
    ADD A, $08                              ;add 8 for second sprite
    LD (HL), A
    INC L
    INC C                                   ;increment tile ID for each sprite
    LD (HL), C
        ; SPRITE 2
    INC L
    SUB A, $08                              ;reset Xpos offset for third sprite
    LD (HL), A
    INC L
    INC C
    LD (HL), C
        ; SPRITE 3
    INC L
    ADD A, $08                              ;add 8 for fourth sprite
    LD (HL), A
    INC L
    INC C
    LD (HL), C

    EX DE, HL                               ;DE: S.A.T. address, HL: N/A
    ; YPOS
    LD E, IXL
    LD A, (Fireball_Rel_YPos)               ;get relative vertical coordinate
    SUB A, $04 + SMS_PIXELYOFFSET           ;subtract four pixels vertically
    LD (DE), A                              ;for first and second sprites
    INC E
    LD (DE), A
    ADD A, $08                              ;add eight pixels vertically
    INC E
    LD (DE), A                              ;for third and fourth sprites
    INC E
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------

DrawSmallPlatform:
;   X POSITION & TILE
    LD L, <Enemy_SprDataOffset              ;get OAM data offset
    LD E, (HL)
    LD D, >Sprite_Y_Position
    SLA E
    SET 7, E
    ;
    LD A, (Enemy_Rel_XPos)                  ;get relative horizontal coordinate
    LD B, LIFT_TILE                         ;B = tile ID
    EX DE, HL
    ; TILE 0
    LD (HL), A                              ;first sprite = Xpos
    INC L
    LD (HL), B
    INC L
    ; TILE 1
    ADD A, $08
    LD (HL), A                              ;second sprite = Xpos+8
    INC L
    LD (HL), B
    INC L
    ; TILE 2
    ADD A, $08
    LD (HL), A                              ;third sprite = Xpos+16
    INC L
    LD (HL), B
    INC L
    ; TILE 3
    SUB A, $10                              ;fourth sprite = Xpos
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ; TILE 4
    ADD A, $08                              ;fifth sprite = Xpos+8
    LD (HL), A
    INC L
    LD (HL), B
    INC L
    ; TILE 5
    ADD A, $08                              ;sixth sprite = Xpos+16
    LD (HL), A
    INC L
    LD (HL), B
    EX DE, HL
;   Y POSITION
    ; FIRST 3
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    LD L, <Enemy_Y_Position                 ;get vertical coordinate
    LD A, (HL)
    CP A, $D8                               ;move offscreen if below visible screen
    JP NC, +
    CP A, $20                               ;if vertical coordinate below status bar,
    JP NC, TopSP                            ;do not mess with it
+:
    LD A, (YPOS_OFFSCREEN + SMS_PIXELYOFFSET) & 0xFF    ;otherwise move first three sprites offscreen
TopSP:
    SUB A, SMS_PIXELYOFFSET                 ;dump vertical coordinate into Y coordinates
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    ; SECOND 3
    LD L, <Enemy_Y_Position
    LD A, (HL)
    ADD A, $80                              ;add 128 pixels
    CP A, $D8                               ;move offscreen if below visible screen
    JP NC, +
    CP A, $20                               ;if below status bar (taking wrap into account)
    JP NC, BotSP                            ;then do not change altered coordinate
+:
    LD A, (YPOS_OFFSCREEN + SMS_PIXELYOFFSET) & 0xFF    ;otherwise move last three sprites offscreen
BotSP:
    SUB A, SMS_PIXELYOFFSET                 ;dump vertical coordinate + 128 pixels
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
;   OFFSCREEN CHECK
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    INC E
    INC E                                   ;DE: SprDataOffset + $02
    LD H, D
    LD L, E
    INC L
    INC L
    INC L                                   ;HL: SprDataOffset + $05
    LD A, (Enemy_OffscrBits)                ;get offscreen bits
    LD C, A
    LD A, YPOS_OFFSCREEN
    SRL C                                   ;check d1
    SRL C
    JR NC, +
    LD (DE), A                              ;if d1 was set, move third and
    LD (HL), A                              ;sixth sprites offscreen
+:
    DEC E
    DEC L
    SRL C                                   ;check d2
    JR NC, +
    LD (DE), A                              ;if d2 was set, move second and
    LD (HL), A                              ;fifth sprites offscreen
+:
    DEC E
    DEC L
    SRL C                                   ;check d3
    JR NC, ExSPl
    LD (DE), A                              ;if d3 was set, move first and
    LD (HL), A                              ;fourth sprites offscreen
ExSPl:
    LD HL, (ObjectOffset)                   ;get enemy object offset and leave
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
    LD A, H                         ;get air bubble's OAM data offset
    ADD A, >Bubble_SprDataOffset - >Bubble_Y_Position
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
    LD A, BUBBLE_TILE               ;put air bubble tile into OAM data
    LD (DE), A
    RET

;-------------------------------------------------------------------------------------
;$00 - used to store player's vertical offscreen bits

.INCLUDE "ASSETS/MAP_Player.inc"

.SECTION "PlayerFixedTiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
PlayerFixedTiles:
    .db VRAM_IDX_SPR_PLR + $00, VRAM_IDX_SPR_PLR + $01
    .db VRAM_IDX_SPR_PLR + $02, VRAM_IDX_SPR_PLR + $03
    .db VRAM_IDX_SPR_PLR + $04, VRAM_IDX_SPR_PLR + $05
    .db VRAM_IDX_SPR_PLR + $06, VRAM_IDX_SPR_PLR + $07
.ENDS

PlayerGfxHandler:
    LD HL, (Player_Y_Position)          ;don't draw player if they are under the visible screen
    LD DE, $01D0                        ;to avoid sprite terminator
    OR A
    SBC HL, DE
    RET NC
;
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
    JR NZ, DoChangeSize                 ;then branch to some other code
;
    LD A, (OptionBitflags)              ;if on all-stars gfx mode
    AND A, bitValue(OPTFLAG_GFX)        ;skip lower body swim tile changes
    JR Z, FindPlayerAction
;
    ; All this is for lower body swim tile changes
    LD A, (SwimmingFlag)                ;if swimming flag set, branch to
    OR A
    JR Z, FindPlayerAction              ;different part, do not return
;
    LD A, (Player_State)                ;if player status normal,
    OR A
    JR Z, FindPlayerAction              ;branch and do not return
;
    CALL FindPlayerAction               ;otherwise jump and return
    LD A, (FrameCounter)
    AND A, %00000100                    ;check frame counter for d2 set (8 frames every
    RET NZ                              ;eighth frame), and branch if set to leave
;
    LD HL, (PlayerGfxOffset)
    LD A, (PlayerSize)
    OR A
    JR Z, BigKTS
    LD A, L
    CP A, <PlayerGraphicsTable + $A8
    RET Z
    LD A, $10
    DEC H
    addAToHL_M
    LD (PlayerGfxOffset), HL
    RET
BigKTS:
    LD A, $60
    DEC H
    addAToHL_M
    LD (PlayerGfxOffset), HL
    RET


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
    JR Z, PlayerOffscreenChk            ;if fireball throw timer not set, skip to the end
;
    LD A, (PlayerAnimTimer)             ;get animation frame timer
    CP A, (HL)                          ;compare to fireball throw timer
    LD (HL), $00                        ;initialize fireball throw timer
    JR NC, PlayerOffscreenChk           ;if animation frame timer => fireball throw timer skip to end
    LD (HL), A                          ;otherwise store animation timer into fireball throw timer

    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JR Z, +
    LD A, (Player_X_Speed)
    LD HL, Left_Right_Buttons
    OR A, (HL)
    JR Z, +
    LD HL, (PlayerGfxOffset)
    LD A, $B8
    DEC H
    addAToHL_M
    LD (PlayerGfxOffset), HL
    JP PlayerOffscreenChk
+:
    LD A, <PlayerGraphicsTable@bigAction    ;load offset for player throwing
    LD (PlayerGfxOffset), A
    ; FALL THROUGH

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
    LD HL, PlayerGfxBank
    RES 0, (HL)                         ;RIGHT-FACING SPRITES
;
    LD HL, PlayerGraphicsTable@smlStand ;load offset for small standing
    LD (PlayerGfxOffset), HL
    INC L                               ;invalidate old offset to force tile streaming for player
    LD (PlayerGfxOffset_Old), HL
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
    LD C, A                             ;store it here also
;
    LD A, (Player_Rel_YPos)
    SUB A, SMS_PIXELYOFFSET
    LD B, A                             ;store player's vertical position
    

;   X - PlayerFixedTiles (HL)
;   Y - OFFSET FOR OAM (DE)
DrawPlayerLoop:
    LD IXL, E
    LD A, B
    DrawSpriteObject_YPos
    DrawSpriteObject_YPos
    DrawSpriteObject_YPos
    LD (DE), A                          ;DrawSpriteObject_YPos
    INC E
    LD (DE), A
    LD E, IXL
    SLA E
    SET 7, E
    DrawSpriteObject_XT
    DrawSpriteObject_XT
    DrawSpriteObject_XT
    LD A, C                             ;DrawSpriteObject_XT
    LD (DE), A
    INC E
    LDI
    INC BC
    ADD A, $08
    LD (DE), A
    INC E
    LDI
    RET

ProcessPlayerAction:
    LD A, (Player_State)                ;get player's state
    OR A
    JR Z, ProcOnGroundActs              ;if not jumping, branch here
    DEC A
    JR Z, ActionSwimmingChk             ;if swimming, branch here
    DEC A
    JR Z, ActionFalling                 ;if falling, branch here
ActionClimbing:
    LD L, <PlayerGraphicsTable@bigClimb ;load offset for climbing
    LD A, (Player_Y_Speed)              ;check player's vertical speed
    OR A
    JR Z, NonAnimatedActs               ;if no speed, branch, use offset as-is
    CALL GetGfxOffsetAdder              ;otherwise get offset for graphics table
    LD A, $02                           ;load upper extent for frame control for climbing
    JP AnimationControl                 ;jump to get offset and animate player object

ProcOnGroundActs:
    LD L, <PlayerGraphicsTable@bigCrouch;load offset for crouching
    LD A, (CrouchingFlag)               ;get crouching flag
    OR A
    JR NZ, NonAnimatedActs              ;if set, branch to get offset for graphics table
;
    LD L, <PlayerGraphicsTable@bigStand ;load offset for standing
    LD A, (Player_X_Speed)              ;check player's horizontal speed
    LD B, A
    LD A, (Left_Right_Buttons)          ;and left/right controller bits
    OR A, B
    JR Z, NonAnimatedActs               ;if no speed or buttons pressed, use standing offset
;
    LD A, (Player_XSpeedAbsolute)       ;load walking/running speed
    
    .IF PALBUILD == $00
    CP A, $09
    .ELSE
    CP A, $0A                           ;PAL diff: Faster speed cutoff to accomodate FPS difference
    .ENDIF

    JR C, ActionWalkRun                 ;if less than a certain amount, branch, too slow to skid
;
    LD A, (Player_MovingDir)            ;otherwise check to see if moving direction
    LD B, A
    LD A, (PlayerFacingDir)             ;and facing direction are the same
    AND A, B
    JR NZ, ActionWalkRun                ;if moving direction = facing direction, branch, don't skid
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
    JR NZ, ActionSwimming               ;if swimming flag set, branch elsewhere
;
    LD L, <PlayerGraphicsTable@bigCrouch;load offset for crouching
    LD A, (CrouchingFlag)               ;get crouching flag
    OR A
    JR NZ, NonAnimatedActs              ;if set, branch to get offset for graphics table
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
    JR NZ, FourFrameExtent              ;if any one of these set, branch ahead
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
    JR C, SetAnimC                      ;if frame control + 1 < upper extent, use as next
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

.SECTION "ChangeSizeOffsetAdder" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
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
    JR NZ, GorSLog                      ;fourth frame, otherwise branch ahead
;
    INC C                               ;increment frame control
    LD A, C                             ;check for preset upper extent
    CP A, $0A
    JR C, CSzNext                       ;if not there yet, skip ahead to use
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
    JR NZ, ShrinkPlayer                 ;if player small, skip ahead to next part
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