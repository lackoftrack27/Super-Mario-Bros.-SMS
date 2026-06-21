;--------------------------------
;$06(IXL) - used to hold page location of extended right boundary
;$07(IXH) - used to hold high nybble of position of extended right boundary

ProcessEnemyData:
    LD D, >EnemyDataBank            ;get offset of enemy object data
    LD A, (EnemyDataOffset)
    LD E, A
    LD A, (DE)                      ;load first byte
    CP A, $FF                       ;check for EOD terminator
    JP Z, CheckFrenzyBuffer         ;if found, jump to check frenzy buffer, otherwise

;CheckEndofBuffer:
    AND A, %00001111                ;check for special row $0e
    CP A, $0E
    JP Z, CheckRightBounds          ;if found, branch, otherwise
    LD A, H                         ;check for end of buffer
    CP A, >Enemy_ID_05
    JP C, CheckRightBounds          ;if not at end of buffer, branch
;
    INC E
    LD A, (DE)                      ;check for specific value here
    AND A, %00111111                ;not sure what this was intended for, exactly
    CP A, $2E                       ;this part is quite possibly residual code
    RET NZ                          ;but it has the effect of keeping enemies out of the sixth slot

CheckRightBounds:
    LD A, (ScreenRight_X_Pos)       ;add 48 to pixel coordinate of right boundary
    ADD A, $30
    LD C, A
    LD A, (ScreenRight_PageLoc)     ;add carry to page location of right boundary
    ADC A, $00
    LD IXL, A ;LD (Temp_Bytes + $06), A        ;store page location + carry
    LD A, C
    AND A, %11110000
    LD IXH, A ;LD (Temp_Bytes + $07), A        ;store high nybble
;
    LD A, (EnemyDataOffset)
    LD E, A
    INC E
    LD A, (DE)                      ;if MSB of enemy object is clear, branch to check for row $0f
    ADD A, A
    JP NC, CheckPageCtrlRow
    LD A, (EnemyObjectPageSel)      ;if page select already set, do not set again
    OR A
    JP NZ, CheckPageCtrlRow
;
    INC A                           ;otherwise, if MSB is set, set page select 
    LD (EnemyObjectPageSel), A
    LD A, (EnemyObjectPageLoc)      ;and increment page control
    INC A
    LD (EnemyObjectPageLoc), A

CheckPageCtrlRow:
    DEC E
    LD A, (DE)                      ;reread first byte
    AND A, $0F
    CP A, $0F                       ;check for special row $0f
    JP NZ, PositionEnemyObj         ;if not found, branch to position enemy object
;
    LD A, (EnemyObjectPageSel)      ;if page select set,
    OR A
    JP NZ, PositionEnemyObj         ;branch without reading second byte
;
    INC E
    LD A, (DE)                      ;otherwise, get second byte, mask out 2 MSB
    AND A, %00111111
    LD (EnemyObjectPageLoc), A      ;store as page control for enemy object data
;
    LD A, (EnemyDataOffset)         ;increment enemy object data offset 2 bytes
    ADD A, $02
    LD (EnemyDataOffset), A
    LD A, (EnemyObjectPageSel)      ;set page select for enemy object data and 
    INC A
    LD (EnemyObjectPageSel), A
    JP ProcLoopCommand              ;jump back to process loop commands again

PositionEnemyObj:
    LD A, (EnemyObjectPageLoc)      ;store page control as page location
    LD L, <Enemy_PageLoc
    LD (HL), A                      ;for enemy object
;
    LD A, (DE)                      ;get first byte of enemy object
    AND A, %11110000
    LD L, <Enemy_X_Position
    LD (HL), A                      ;store column position
;
    LD A, (ScreenRight_X_Pos)
    LD C, A
    LD A, (HL)
    CP A, C                         ;check column position against right boundary
    LD A, (ScreenRight_PageLoc)
    LD C, A
    LD L, <Enemy_PageLoc
    LD A, (HL)                      ;without subtracting, then subtract borrow
    SBC A, C                        ;from page location
    JP NC, CheckRightExtBounds      ;if enemy object beyond or at boundary, branch
;
    LD A, (DE)
    AND A, %00001111                ;check for special row $0e
    CP A, $0E                       ;if found, jump elsewhere
    JP Z, ParseRow0e
    JP CheckThreeBytes              ;if not found, unconditional jump

CheckRightExtBounds:
    LD A, IXH ;LD A, (Temp_Bytes + $07)        ;check right boundary + 48 against
    LD L, <Enemy_X_Position         ;column position without subtracting,
    CP A, (HL)
    LD A, IXL ;LD A, (Temp_Bytes + $06)        ;then subtract borrow from page control temp
    LD L, <Enemy_PageLoc            ;plus carry
    SBC A, (HL)
    JP C, CheckFrenzyBuffer         ;if enemy object beyond extended boundary, branch
;
    LD L, <Enemy_Y_HighPos          ;store value in vertical high byte
    LD (HL), $01
;
    LD A, (DE)                      ;get first byte again
    ADD A, A                        ;multiply by four to get the vertical
    ADD A, A                        ;coordinate
    ADD A, A
    ADD A, A
    LD L, <Enemy_Y_Position
    LD (HL), A
;
    CP A, $E0                       ;do one last check for special row $0e
    JP Z, ParseRow0e                ;(necessary if branched to $c1cb)???
;
    INC E
    LD A, (DE)                      ;get second byte of object
    AND A, %01000000                ;check to see if hard mode bit is set
    JP Z, CheckForEnemyGroup        ;if not, branch to check for group enemy objects
;
    LD A, (SecondaryHardMode)       ;if set, check to see if secondary hard mode flag
    OR A
    JP Z, Inc2B                     ;is on, and if not, branch to skip this object completely

CheckForEnemyGroup:
    LD A, (DE)                      ;get second byte and mask out 2 MSB
    AND A, %00111111
    CP A, $37                       ;check for value below $37
    JP C, BuzzyBeetleMutate
    CP A, $3F                       ;if $37 or greater, check for value
    JP C, HandleGroupEnemies        ;below $3f, branch if below $3f

BuzzyBeetleMutate:
    CP A, OBJECTID_Goomba           ;if below $37, check for goomba
    JP NZ, StrID                    ;value ($3f or more always fails)
    LD A, (PrimaryHardMode)         ;check if primary hard mode flag is set
    OR A
    LD A, OBJECTID_Goomba
    JP Z, StrID                     
    LD A, OBJECTID_BuzzyBeetle      ;and if so, change goomba to buzzy beetle
StrID:
    LD L, <Enemy_ID
    LD (HL), A                      ;store enemy object number into buffer
;
    LD L, <Enemy_Flag               ;set flag for enemy in buffer
    LD (HL), $01
;
    CALL InitEnemyObject
;
    LD L, <Enemy_Flag               ;check to see if flag is set
    LD A, (HL)
    OR A
    JP NZ, Inc2B                    ;if not, leave, otherwise branch
    RET

CheckFrenzyBuffer:
    LD A, (EnemyFrenzyBuffer)       ;if enemy object stored in frenzy buffer
    OR A
    JP NZ, StrFre                   ;then branch ahead to store in enemy object buffer
;
    LD A, (VineFlagOffset)          ;otherwise check vine flag offset
    CP A, $01
    RET NZ                          ;if other value <> 1, leave
;
    LD A, OBJECTID_VineObject       ;otherwise put vine in enemy identifier
StrFre:
    LD L, <Enemy_ID                 ;store contents of frenzy buffer into enemy identifier value
    LD (HL), A

InitEnemyObject:
    LD L, <Enemy_State              ;initialize enemy state
    LD (HL), $00
    JP CheckpointEnemyID            ;jump ahead to run jump engine and subroutines

ParseRow0e:
    INC E                           ;increment Y to load third byte of object
    INC E
    LD A, (DE)
    RLCA                            ;move 3 MSB to the bottom, effectively
    RLCA                            ;making %xxx00000 into %00000xxx
    RLCA
    AND A, %00000111
    LD C, A
    LD A, (WorldNumber)
    CP A, C                         ;is it the same world number as we're on?
    JP NZ, Inc3B                    ;if not, do not use (this allows multiple uses
;
    DEC E                           ;of the same area, like the underground bonus areas)
    LD A, (DE)                      ;otherwise, get second byte and use as offset
    LD (AreaPointer), A             ;to addresses for level and enemy object data
;
    INC E
    LD A, (DE)                      ;get third byte again, and this time mask out
    AND A, %00011111                ;the 3 MSB from before, save as page number to be
    LD (EntrancePage), A            ;used upon entry to area, if area is entered
;
    JP Inc3B

CheckThreeBytes:
    LD A, (EnemyDataOffset)         ;load current offset for enemy object data
    LD E, A
    LD A, (DE)                      ;get first byte
    AND A, %00001111                ;check for special row $0e
    CP A, $0E
    JP NZ, Inc2B
Inc3B:
    LD A, (EnemyDataOffset)         ;if row = $0e, increment three bytes
    ADD A, $03
    LD (EnemyDataOffset), A
    JP +
Inc2B:
    LD A, (EnemyDataOffset)         ;otherwise increment two bytes
    ADD A, $02
    LD (EnemyDataOffset), A
+:
    XOR A                           ;init page select for enemy objects
    LD (EnemyObjectPageSel), A
    LD HL, (ObjectOffset)           ;reload current offset in enemy buffers
    RET

CheckpointEnemyID:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $15                       ;check enemy object identifier for $15 or greater
    JP NC, InitEnemyRoutines        ;and branch straight to the jump engine if found
;
    EX AF, AF'                      ;save identifier in Y register for now
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    ADD A, $08                      ;add eight pixels to what will eventually be the
    LD (HL), A                      ;enemy object's vertical coordinate ($00-$14 only)
;
    LD L, <EnemyOffscrBitsMasked    ;set offscreen masked bit
    LD (HL), $01
;
    EX AF, AF'                      ;get identifier back and use as offset for jump engine

InitEnemyRoutines:
    PUSH HL                         ;(SMS) save ObjectOffset
    RST JumpEngine

;   jump engine table for newly loaded enemy objects

    .dw InitNormalEnemy  ;for objects $00-$0f
    .dw InitNormalEnemy
    .dw InitNormalEnemy
    .dw InitRedKoopa
    .dw NoInitCode
    .dw InitHammerBro
    .dw InitGoomba
    .dw InitBloober
    .dw InitBulletBill
    .dw NoInitCode
    .dw InitCheepCheep
    .dw InitCheepCheep
    .dw InitPodoboo
    .dw InitPiranhaPlant
    .dw InitJumpGPTroopa
    .dw InitRedPTroopa

    .dw InitHorizFlySwimEnemy  ;for objects $10-$1f
    .dw InitLakitu
    .dw InitEnemyFrenzy
    .dw NoInitCode
    .dw InitEnemyFrenzy
    .dw InitEnemyFrenzy
    .dw InitEnemyFrenzy
    .dw InitEnemyFrenzy
    .dw EndFrenzy
    .dw NoInitCode
    .dw NoInitCode
    .dw InitShortFirebar
    .dw InitShortFirebar
    .dw InitShortFirebar
    .dw InitShortFirebar
    .dw InitLongFirebar

    .dw NoInitCode ;for objects $20-$2f
    .dw NoInitCode
    .dw NoInitCode
    .dw NoInitCode
    .dw InitBalPlatform
    .dw InitVertPlatform
    .dw LargeLiftUp
    .dw LargeLiftDown
    .dw InitHoriPlatform
    .dw InitDropPlatform
    .dw InitHoriPlatform
    .dw PlatLiftUp
    .dw PlatLiftDown
    .dw InitBowser
    .dw NoInitCode ;PwrUpJmp   ;possibly dummy value
    .dw Setup_Vine

    .dw NoInitCode ;for objects $30-$36
    .dw NoInitCode
    .dw NoInitCode
    .dw NoInitCode
    .dw NoInitCode
    .dw InitRetainerObj
    .dw EndOfEnemyInitCode


;-------------------------------------------------------------------------------------

;   HL - ENEMY OFFSET
;   DE - BLOCK OFFSET
Setup_Vine:
    POP HL
Setup_Vine_NOPOP:
    LD L, <Enemy_ID                 ;load identifier for vine object 
    LD (HL), OBJECTID_VineObject    ;store in buffer
;
    LD L, <Enemy_Flag               ;set flag for enemy object buffer
    LD (HL), $01
;
    LD E, <Block_PageLoc            ;copy page location from previous object
    LD L, E
    LD A, (DE)
    LD (HL), A
;
    LD E, <Block_X_Position         ;copy horizontal coordinate from previous object
    LD L, E
    LD A, (DE)
    LD (HL), A
;
    LD A, (VineFlagOffset)          ;load vine flag/offset to next available vine slot
    OR A
    LD E, <Block_Y_Position         ;copy vertical coordinate from previous object
    LD L, E
    LD A, (DE)
    LD (HL), A
;    
    JP NZ, NextVO                   ;if set at all, don't bother to store vertical
    SUB A, SMS_PIXELYOFFSET
    LD (VineStart_Y_Position), A    ;otherwise store vertical coordinate here
NextVO: 
    LD DE, VineObjOffset            ;store object offset to next available vine slot
    LD A, (VineFlagOffset)
    ADD A, D
    LD D, A
    LD A, H
    LD (DE), A                      ;using vine flag as offset
;
    LD A, (VineFlagOffset)          ;increment vine flag offset
    INC A
    LD (VineFlagOffset), A
;
    LD A, SNDID_VINE                ;load vine grow sound
    LD (SFXTrack1.SoundQueue), A
    RET

;--------------------------------

NoInitCode:
    POP HL
    RET                             ;this executed when enemy object has no init code

;--------------------------------

InitGoomba:
    POP HL
    CALL InitNormalEnemy_NOPOP      ;set appropriate horizontal speed
    JP SmallBBox                    ;set $09 as bounding box control, set other values

;--------------------------------

InitPodoboo:
    POP HL
InitPodoboo_NOPOP:
    LD L, <Enemy_Y_HighPos          ;set enemy position to below
    LD (HL), $02
    LD L, <Enemy_Y_Position         ;the bottom of the screen
    LD (HL), $02
    LD L, <Enemy_State
    LD (HL), $00                    ;initialize enemy state
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, $01
    LD (BC), A                      ;set timer for enemy
;
    JP SmallBBox                    ;$09 as bounding box size and set other things

;--------------------------------

InitRetainerObj:
    POP HL
;
    XOR A
    LD (RetainerDrawnFlag), A
;
    LD L, <Enemy_Y_Position         ;set fixed vertical position for
    LD (HL), $B8                    ;princess/mushroom retainer object
    RET

;--------------------------------

InitNormalEnemy:
    POP HL
InitNormalEnemy_NOPOP:
    LD A, (PrimaryHardMode)         ;check for primary hard mode flag set
    OR A

    .IF PALBUILD == $00
    LD A, $F8                       ;load default offset
    JP Z, GetESpd
    LD A, $F4                       ;if not set, load alternate offset
    .ELSE
    LD A, $F6                       ;PAL diff: Faster speed to compensate FPS difference
    JP Z, GetESpd
    LD A, $F1
    .ENDIF

GetESpd:
SetESpd:
    LD L, <Enemy_X_Speed            ;store as speed for enemy object
    LD (HL), A
    JP TallBBox                     ;branch to set bounding box control and other data

;--------------------------------

InitRedKoopa:
    POP HL
;
    CALL InitNormalEnemy_NOPOP      ;load appropriate horizontal speed
    LD L, <Enemy_State              ;set enemy state for red koopa troopa $03
    LD (HL), $01
    RET

;--------------------------------

InitHammerBro:
    POP HL
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
;
    LD L, <HammerThrowingTimer      ;init horizontal speed and timer used by hammer bro
    LD (HL), $00                    ;apparently to time hammer throwing
    LD L, <Enemy_X_Speed
    LD (HL), $00
    LD A, (SecondaryHardMode)       ;get secondary hard mode flag
    OR A
    LD A, $80                       ;HBroWalkingTimerData
    JP Z, +
    LD A, $50                       ;HBroWalkingTimerData + $01
+:
    LD (BC), A                      ;set value as delay for hammer bro to walk left
    LD A, $0B                       ;set specific value for bounding box size control
    JP SetBBox

;--------------------------------

InitHorizFlySwimEnemy:
    POP HL
InitHorizFlySwimEnemy_NOPOP:
    XOR A                           ;initialize horizontal speed
    JP SetESpd

;--------------------------------

InitBloober:
    POP HL
;
    LD L, <BlooperMoveSpeed         ;initialize horizontal speed
    LD (HL), $00
SmallBBox:
    LD A, $09                       ;set specific bounding box size control
    JP SetBBox

;--------------------------------

InitRedPTroopa:
    POP HL
;
    LD L, <Enemy_Y_Position         ;set vertical coordinate into location to
    LD A, (HL)
    LD L, <RedPTroopaOrigXPos       ;be used as original vertical coordinate
    LD (HL), A
;
    OR A
    LD A, $30                       ;load central position adder for 48 pixels down
    JP P, GetCent                   ;if vertical coordinate < $80
    LD A, $E0                       ;if => $80, load position adder for 32 pixels up
GetCent:
    LD L, <Enemy_Y_Position         ;add to current vertical coordinate
    ADD A, (HL)
    LD L, <RedPTroopaCenterYPos     ;store as central vertical coordinate
    LD (HL), A
    ; FALL THROUGH

TallBBox:
    LD A, $03                       ;set specific bounding box size control
SetBBox:
    LD L, <Enemy_BoundBoxCtrl       ;set bounding box control here
    LD (HL), A
;
    LD L, <Enemy_MovingDir          ;set moving direction for left
    LD (HL), $02
    ; FALL THROUGH

InitVStf:
    XOR A
    LD L, <Enemy_Y_Speed            ;initialize vertical speed
    LD (HL), A
    LD L, <Enemy_Y_MoveForce        ;and movement force
    LD (HL), A
    RET

;--------------------------------

InitBulletBill:
    POP HL
;
    LD L, <Enemy_MovingDir          ;set moving direction for left
    LD (HL), $02
    LD L, <Enemy_BoundBoxCtrl       ;set bounding box control for $09
    LD (HL), $09
    RET

;--------------------------------

InitCheepCheep:
    POP HL
;
    CALL SmallBBox                  ;set vertical bounding box, speed, init others
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)                      ;check one portion of LSFR
    AND A, %00010000                ;get d4 from it
    LD L, <CheepCheepMoveMFlag      ;save as movement flag of some sort
    LD (HL), A
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD L, <CheepCheepOrigYPos       ;save original vertical coordinate here
    LD (HL), A
    RET

;--------------------------------

InitLakitu:
    POP HL
;
    LD A, (EnemyFrenzyBuffer)       ;check to see if an enemy is already in
    OR A
    JP NZ, EraseEnemyObject         ;the frenzy buffer, and branch to kill lakitu if so

SetupLakitu:
    XOR A                           ;erase counter for lakitu's reappearance
    LD (LakituReappearTimer), A
    JP InitHorizFlySwimEnemy_NOPOP  ;set $03 as bounding box, set other attributes
    ;JP TallBBox2                   ;set $03 as bounding box again (not necessary) and leave

;--------------------------------
;$01-$03 - used to hold pseudorandom difference adjusters

.SECTION "PRDiffAdjustData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
PRDiffAdjustData:
    ;.db $26, $2c, $32, $38
    ;.db $20, $22, $24, $26
    ;.db $13, $14, $15, $16

    .db $26, $20, $13, $00
    .db $2C, $22, $14, $00
    .db $32, $24, $15, $00
    .db $38, $26, $16, $00
.ENDS 

LakituAndSpinyHandler:
    POP HL
;
    LD A, (FrenzyEnemyTimer)            ;if timer here not expired, leave
    OR A
    RET NZ
;
    LD A, H
    CP A, $C6                           ;if we are on the special use slot, leave
    RET NC
;
    LD A, $80                           ;set timer
    LD (FrenzyEnemyTimer), A
;
    LD DE, Enemy_ID_04                  ;start with the last enemy slot
    LD B, $05
ChkLak:
    LD A, (DE)                          ;check all enemy slots to see
    CP A, OBJECTID_Lakitu               ;if lakitu is on one of them
    JP Z, CreateSpiny                   ;if so, branch out of this loop
    DEC D                               ;otherwise check another slot
    DJNZ ChkLak                         ;loop until all slots are checked
;
    LD A, (LakituReappearTimer)         ;increment reappearance timer
    INC A
    LD (LakituReappearTimer), A
    CP A, $07                           ;check to see if we're up to a certain value yet
    RET C                               ;if not, leave
;
    LD HL, Enemy_Flag_04                ;start with the last enemy slot again
    LD B, $05
ChkNoEn:
    LD A, (HL)                          ;check enemy buffer flag for non-active enemy slot
    OR A
    JP Z, CreateL                       ;branch out of loop if found
    DEC H                               ;otherwise check next slot
    DJNZ ChkNoEn                        ;branch until all slots are checked
    JP RetEOfs                          ;if no empty slots were found, branch to leave
;
CreateL:
    LD L, <Enemy_State                  ;initialize enemy state
    LD (HL), $00
    LD L, <Enemy_ID                     ;create lakitu enemy object
    LD (HL), OBJECTID_Lakitu
    CALL SetupLakitu                    ;do a sub to set up lakitu
    LD A, $20
    CALL PutAtRightExtent               ;finish setting up lakitu
RetEOfs:
    LD HL, (ObjectOffset)               ;get enemy object buffer offset again and leave
    RET

;--------------------------------

CreateSpiny:
    LD A, (Player_Y_Position)           ;if player above a certain point, branch to leave
    CP A, $2C
    RET C
;
    LD E, <Enemy_State                  ;if lakitu is not in normal state, branch to leave
    LD A, (DE)
    OR A
    RET NZ
;
    LD E, <Enemy_PageLoc                ;store horizontal coordinates (high and low) of lakitu
    LD L, E
    LD A, (DE)
    LD (HL), A
;
    LD E, <Enemy_X_Position             ;into the coordinates of the spiny we're going to create
    LD L, E
    LD A, (DE)
    LD (HL), A
;
    LD L, <Enemy_Y_HighPos              ;put spiny within vertical screen unit
    LD (HL), $01
;
    LD E, <Enemy_Y_Position             ;put spiny eight pixels above where lakitu is
    LD L, E
    LD A, (DE)
    SUB A, $08
    LD (HL), A
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)                          ;get 2 LSB of LSFR and save to Y
    AND A, %00000011
    ADD A, A
    ADD A, A
    LD HL, PRDiffAdjustData
    addAToHL8_M
    LD DE, Temp_Bytes + $03             ;get three values and save them
    LDD                                 ;to $01-$03
    LDD
    LDD
    LD HL, (ObjectOffset)               ;get enemy object buffer offset
;
    CALL PlayerLakituDiff               ;move enemy, change direction, get value - difference
;     EX AF, AF'
;     LD A, (Player_X_Speed)              ;check player's horizontal speed
    ; .IF PALBUILD == $00
    ; CP A, $08
    ; .ELSE
    ; CP A, $0C                         ;PAL diff: Faster speed cutoffs to compensate FPS difference
    ; .ENDIF
;     JP NC, SetSpSpd                     ;if moving faster than a certain amount, branch elsewhere
;     LD A, H
;     SUB A, $C1
;     LD BC, PseudoRandomBitReg + $01
;     addAToBC8_M
;     LD A, (BC)
;     AND A, %00000011                    ;get one of the LSFR parts and save the 2 LSB
;     JP Z, UsePosv                       ;branch if neither bits are set
;     EX AF, AF'
;     NEG                                 ;otherwise get two's compliment of Y
;     EX AF, AF'
; UsePosv:
; SetSpSpd:
;     EX AF, AF'                          ;put value from A in Y back to A (they will be lost anyway)
    CALL SmallBBox                      ;set bounding box control, init attributes, lose contents of A
;
    LD L, <Enemy_X_Speed                ;set horizontal speed to zero because previous contents
    LD (HL), A
;     OR A                                ;of A were lost...branch here will never be taken for
;     LD A, $02                           ;the same reason
;     JP M, SpinyRte
;     DEC A
; SpinyRte:
    LD A, $01
    LD L, <Enemy_MovingDir              ;set moving direction to the right
    LD (HL), A
    LD L, <Enemy_Y_Speed                ;set vertical speed to move upwards
    LD (HL), $FD
    LD L, <Enemy_Flag                   ;enable enemy object by setting flag
    LD (HL), $01
    LD L, <Enemy_State                  ;put spiny in egg state and leave
    LD (HL), $05
    RET

;--------------------------------

.SECTION "FirebarSpinSpdData/FirebarSpinDirData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FirebarSpinSpdData:
    
    .IF PALBUILD == $00
    .db $28, $38, $28, $38, $28
    .ELSE
    .db $30, $43, $30, $43, $30         ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

FirebarSpinDirData:
    .db $00, $00, $10, $10, $00
.ENDS

InitLongFirebar:
    POP HL
;
    CALL DuplicateEnemyObj              ;create enemy object for long firebar
    JP InitShortFirebar_NOPOP

InitShortFirebar:
    POP HL
InitShortFirebar_NOPOP:
    LD L, <FirebarSpinState_Low         ;initialize low byte of spin state
    LD (HL), $00
;
    LD L, <Enemy_ID
    LD A, (HL)                          ;subtract $1b from enemy identifier
    SUB A, $1B                          ;to get proper offset for firebar data
    LD BC, FirebarSpinSpdData
    addAToBC8_M
    LD A, (BC)                          ;get spinning speed of firebar
    LD L, <FirebarSpinSpeed
    LD (HL), A
;
    LD A, $05
    addAToBC8_M                         ;FirebarSpinDirData
    LD A, (BC)                          ;get spinning direction of firebar
    LD L, <FirebarSpinDirection
    LD (HL), A
;
    LD L, <Enemy_Y_Position             ;add four pixels to vertical coordinate
    LD A, (HL)
    ADD A, $04
    LD (HL), A
;
    LD L, <Enemy_X_Position             ;add four pixels to horizontal coordinate
    LD A, (HL)
    ADD A, $04
    LD (HL), A
;
    LD L, <Enemy_PageLoc                ;add carry to page location
    LD A, (HL)
    ADC A, $00
    LD (HL), A
;
    JP TallBBox2                        ;set bounding box control (not used) and leave

;--------------------------------
;$00-$01 - used to hold pseudorandom bits

.SECTION "FlyCCXPositionData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlyCCXPositionData:
    .db $80, $30, $40, $80
    .db $30, $50, $50, $70
    .db $20, $40, $80, $a0
    .db $70, $40, $90, $68
.ENDS

.SECTION "FlyCCXSpeedData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlyCCXSpeedData:

    .IF PALBUILD == $00
    .db $0e, $05, $06, $0e
    .db $1c, $20, $10, $0c
    .db $1e, $22, $18, $14
    .ELSE
    .db $11, $07, $08, $0a              ;PAL diff: Faster speed to compensate FPS difference
    .db $23, $28, $15, $10
    .db $22, $2c, $1f, $1b
    .ENDIF
.ENDS

.SECTION "FlyCCTimerData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlyCCTimerData:
    .db $10, $60, $20, $48
.ENDS

InitFlyingCheepCheep:
    POP HL
;
    LD A, (FrenzyEnemyTimer)            ;if timer here not expired yet, branch to leave
    OR A
    RET NZ
;
    CALL SmallBBox                      ;jump to set bounding box size $09 and init other values
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011                    ;set pseudorandom offset here
    LD BC, FlyCCTimerData
    addAToBC8_M
    LD A, (BC)                          ;load timer with pseudorandom offset
    LD (FrenzyEnemyTimer), A
;
    LD A, (SecondaryHardMode)
    OR A
    LD A, $03                           ;load Y with default value
    JP Z, MaxCC                         ;if secondary hard mode flag not set, do not increment Y
    INC A                               ;otherwise, increment Y to allow as many as four onscreen
MaxCC:
    LD (Temp_Bytes + $00), A            ;store whatever pseudorandom bits are in Y
    LD C, A                             ;compare enemy object buffer offset with Y
    LD A, H
    SUB A, $C1
    CP A, C
    RET NC                              ;if X => Y, branch to leave
;
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011                    ;get last two bits of LSFR, first part
    LD (Temp_Bytes + $00), A            ;and store in two places
    LD (Temp_Bytes + $01), A
;
    LD L, <Enemy_Y_Speed                ;set vertical speed for cheep-cheep

    .IF PALBUILD == $00
    LD (HL), $FB
    .ELSE
    LD (HL), $FA                        ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

;
    LD A, (Player_X_Speed)              ;check player's horizontal speed
    OR A
    LD A, $00                           ;load default value
    JP Z, GSeed                         ;if player not moving left or right, skip this part
    LD A, (Player_X_Speed)              ;if moving to the right but not very quickly,
    
    .IF PALBUILD == $00
    CP A, $19
    .ELSE
    CP A, $1D                           ;PAL diff: Faster speed cutoffs to compensate FPS difference
    .ENDIF

    LD A, $04
    JP C, GSeed                         ;do not change A
    ADD A, A                            ;otherwise, multiply A by 2
GSeed:
    PUSH AF                             ;save to stack
    LD C, A
    LD A, (Temp_Bytes + $00)            ;add to last two bits of LSFR we saved earlier
    ADD A, C
    LD (Temp_Bytes + $00), A            ;save it there
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011                    ;if neither of the last two bits of second LSFR set,
    JP Z, RSeed                         ;skip this part and save contents of $00
    INC C
    LD A, (BC)
    AND A, %00001111                    ;otherwise overwrite with lower nybble of
    LD (Temp_Bytes + $00), A            ;third LSFR part
RSeed:
    POP AF                              ;get value from stack we saved earlier
    LD C, A
    LD A, (Temp_Bytes + $01)            ;add to last two bits of LSFR we saved in other place
    ADD A, C
    LD C, A                             ;use as pseudorandom offset here
    LD DE, FlyCCXSpeedData              ;get horizontal speed using pseudorandom offset
    addAToDE8_M
    LD A, (DE)
    LD L, <Enemy_X_Speed
    LD (HL), A
;
    LD L, <Enemy_MovingDir              ;set to move towards the right
    LD (HL), $01
;
    LD A, (Player_X_Speed)              ;if player moving left or right, branch ahead of this part
    OR A
    JP NZ, D2XPos1
    LD A, (Temp_Bytes + $00)            ;get first LSFR or third LSFR lower nybble
    LD C, A
    AND A, %00000010                    ;and check for d1 set
    JP Z, D2XPos1                       ;if d1 not set, branch
    LD L, <Enemy_X_Speed
    LD A, (HL)                          ;if d1 set, change horizontal speed
    NEG                                 ;into two's compliment, thus moving in the opposite
    LD (HL), A                          ;direction
    LD L, <Enemy_MovingDir              ;increment to move towards the left
    INC (HL)
;
D2XPos1:
    LD A, C                             ;get first LSFR or third LSFR lower nybble again
    LD DE, FlyCCXPositionData
    addAToDE8_M
    LD A, C
    AND A, %00000010
    JP Z, D2XPos2                       ;check for d1 set again, branch again if not set
    LD A, (Player_X_Position)           ;get player's horizontal position
    EX DE, HL
    ADD A, (HL)                         ;if d1 set, add value obtained from pseudorandom offset              
    EX DE, HL
    LD L, <Enemy_X_Position             ;and save as enemy's horizontal position
    LD (HL), A
    LD A, (Player_PageLoc)              ;get player's page location
    ADC A, $00                          ;add carry and jump past this part
    JP FinCCSt
;
D2XPos2:
    LD A, (Player_X_Position)           ;get player's horizontal position
    EX DE, HL      
    SUB A, (HL)                         ;if d1 not set, subtract value obtained from pseudorandom
    EX DE, HL
    LD L, <Enemy_X_Position             ;offset and save as enemy's horizontal position
    LD (HL), A
    LD A, (Player_PageLoc)              ;get player's page location
    SBC A, $00                          ;subtract borrow
;
FinCCSt:
    LD L, <Enemy_PageLoc                ;save as enemy's page location
    LD (HL), A
;
    LD L, <Enemy_Flag                   ;set enemy's buffer flag
    LD (HL), $01
    LD L, <Enemy_Y_HighPos              ;set enemy's high vertical byte
    LD (HL), $01
    LD L, <Enemy_Y_Position             ;put enemy below the screen, and we are done
    LD (HL), YPOS_OFFSCREEN_LOGICAL
    RET

;--------------------------------

InitBowser:
    POP HL
;
    CALL DuplicateEnemyObj              ;jump to create another bowser object
;
    LD A, H                             ;save offset of first here
    LD (BowserFront_Offset), A
;
    XOR A                               ;initialize bowser's body controls
    LD (BowserBodyControls), A          ;and bridge collapse offset
    LD (BridgeCollapseOffset), A
;
    LD L, <Enemy_X_Position             ;store original horizontal position here
    LD A, (HL)
    LD (BowserOrigXPos), A
;
    LD A, $DF                           ;store something here
    LD (BowserFireBreathTimer), A
    LD L, <Enemy_MovingDir              ;and in moving direction
    LD (HL), A
;
    LD A, $20
    LD (BowserFeetCounter), A           ;set bowser's feet timer and in enemy timer
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, $20
    LD (BC), A
;
    LD A, $05                           ;give bowser 5 hit points
    LD (BowserHitPoints), A
;
    SRL A                               ;set default movement speed here
    LD (BowserMovementSpeed), A
;
    LD HL, BowserPaletteData            ;load palette for bowser depending on gfx mode
    LD BC, _sizeof_BowserPaletteData
    LD A, (OptionBitflags)
    AND A, $01
    JP Z, +
    LD HL, BowserPaletteData_NES
    LD BC, _sizeof_BowserPaletteData_NES
+:
    LD DE, (VRAM_Buffer1_Ptr)
    LDIR
    DEC E
    LD (VRAM_Buffer1_Ptr), DE
    LD HL, (ObjectOffset)
;
    LD A, (OptionBitflags)              ;play boss music if doing FM sound
    AND A, %00000010
    RET Z
    LD A, (WorldNumber)
    CP A, WORLD8
    LD A, SNDID_BOWSER_FM
    JP NZ, +
    INC A
+:
    LD (MusicTrack0.SoundQueue), A
    RET

.SECTION "Bowser Palette Data" BANK BANK_SLOT2 SLOT 2 FREE RETURNORG
BowserPaletteData:
    .dw swapBytes($C010)
    .db StripeCount($10)
    .db $00, $00, $04, $15, $2A, $24, $0E, $06, $1B, $0F, $07, $3F, $03, $02, $10, $09
    .db $00
.ENDS

.SECTION "Bowser Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE RETURNORG
BowserPaletteData_NES:
    .dw swapBytes($C014)
    .db StripeCount($03)
    .db $08, $3F, $0B
    .db $00
.ENDS

;--------------------------------

DuplicateEnemyObj:
    LD DE, $C000 + <Enemy_Flag          ;start at beginning of enemy slots
FSLoop:
    INC D                               ;increment one slot
    LD A, (DE)                          ;check enemy buffer flag for empty slot
    OR A
    JP NZ, FSLoop                       ;if set, branch and keep checking
;
    LD (DuplicateObj_Offset), DE        ;otherwise set offset here
;
    LD A, H                             ;transfer original enemy buffer offset
    SUB A, $C1                          ;(SMS) remove RAM offset
    OR A, %10000000                     ;store with d7 set as flag in new enemy
    LD (DE), A                          ;slot as well as enemy offset
;
    LD L, <Enemy_PageLoc                ;copy page location and horizontal coordinates
    LD E, L                             ;from original enemy to new enemy
    LD A, (HL)
    LD (DE), A
;
    LD L, <Enemy_X_Position
    LD E, L
    LD A, (HL)
    LD (DE), A
;
    LD L, <Enemy_Flag                   ;set flag as normal for original enemy
    LD E, <Enemy_Y_HighPos              ;set high vertical byte for new enemy
    LD A, $01
    LD (HL), A
    LD (DE), A
;
    LD L, <Enemy_Y_Position             ;copy vertical coordinate from original to new
    LD E, L
    LD A, (HL)
    LD (DE), A
    RET
    
;--------------------------------

.SECTION "FlameYPosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlameYPosData:
    .db $90, $80, $70, $90
.ENDS

; FlameYMFAdderData:
;     .db $ff, $01

InitBowserFlame:
    POP HL
;
    LD A, (FrenzyEnemyTimer)            ;if timer not expired yet, branch to leave
    OR A
    RET NZ
;
    LD L, <Enemy_Y_MoveForce            ;reset something here
    LD (HL), A
;
    LD A, SNDID_FLAME                   ;load bowser's flame sound into queue
    LD (SFXTrack2.SoundQueue), A
;
    LD DE, (BowserFront_Offset - 1)     ;get bowser's buffer offset
    LD E, <Enemy_ID                     ;check for bowser
    LD A, (DE)
    CP A, OBJECTID_Bowser
    JP Z, SpawnFromMouth                ;branch if found
;
    CALL SetFlameTimer                  ;get timer data based on flame counter
    ADD A, $20                          ;add 32 frames by default
    LD C, A
    LD A, (SecondaryHardMode)           ;if secondary mode flag not set, use as timer setting
    OR A
    LD A, C
    JP Z, SetFrT
    SUB A, $10                          ;otherwise subtract 16 frames for secondary hard mode       
SetFrT:
    LD (FrenzyEnemyTimer), A            ;set timer accordingly
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011                    ;get 2 LSB from first part of LSFR
    LD L, <BowserFlamePRandomOfs        ;set here
    LD (HL), A
    LD BC, FlameYPosData                ;use as offset
    addAToBC8_M
    LD A, (BC)                          ;load vertical position based on pseudorandom offset
    ; FALL THROUGH

PutAtRightExtent:
    LD L, <Enemy_Y_Position             ;set vertical position
    LD (HL), A
;
    LD A, (ScreenRight_X_Pos)           ;place enemy 32 pixels beyond right side of screen
    ADD A, $20
    LD L, <Enemy_X_Position
    LD (HL), A
;
    LD A, (ScreenRight_PageLoc)         ;add carry
    ADC A, $00
    LD L, <Enemy_PageLoc
    LD (HL), A
;
    JP FinishFlame                      ;skip this part to finish setting values

SpawnFromMouth:
    LD E, <Enemy_X_Position             ;get bowser's horizontal position
    LD L, E
    LD A, (DE)
    SUB A, $0E                          ;subtract 14 pixels
    LD (HL), A                          ;save as flame's horizontal position
;
    LD E, <Enemy_PageLoc                ;copy page location from bowser to flame
    LD L, E
    LD A, (DE)
    LD (HL), A
;
    LD E, <Enemy_Y_Position             ;add 8 pixels to bowser's vertical position
    LD L, E
    LD A, (DE)
    ADD A, $08
    LD (HL), A                          ;save as flame's vertical position
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011                    ;get 2 LSB from first part of LSFR
    LD L, <Enemy_YMF_Dummy              ;save here
    LD (HL), A
;
    LD BC, FlameYPosData                ;use as offset
    addAToBC8_M                         ;get value here using bits as offset
    LD A, (BC)
    LD L, <Enemy_Y_Position             ;compare value to flame's current vertical position
    CP A, (HL)
    LD A, $FF                           ;load default offset
    JP C, SetMF                         ;if less, do not increment offset
    LD A, $01                           ;otherwise use 2nd value
SetMF:
    LD L, <Enemy_Y_MoveForce            ;save to vertical movement force
    LD (HL), A
    XOR A                               ;clear enemy frenzy buffer
    LD (EnemyFrenzyBuffer), A
    ; FALL THROUGH

FinishFlame:
    LD L, <Enemy_BoundBoxCtrl           ;set $08 for bounding box control
    LD (HL), $08
;
    LD A, $01                           ;set high byte of vertical and
    LD L, <Enemy_Y_HighPos              ;enemy buffer flag
    LD (HL), A
    LD L, <Enemy_Flag
    LD (HL), A
;
    XOR A                               ;initialize horizontal movement force, and
    LD L, <Enemy_X_MoveForce            ;enemy state
    LD (HL), A
    LD L, <Enemy_State
    LD (HL), A
    RET

;--------------------------------

.SECTION "FireworksXPosData/FireworksYPosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FireworksXPosData:
    .db $00, $30, $60, $60, $00, $20

FireworksYPosData:
    .db $60, $40, $70, $40, $60, $30
.ENDS

InitFireworks:
    POP HL
;
    LD A, (FrenzyEnemyTimer)            ;if timer not expired yet, branch to leave
    OR A
    RET NZ
;
    LD A, $20                           ;otherwise reset timer
    LD (FrenzyEnemyTimer), A
;
    LD A, (FireworksCounter)            ;decrement for each explosion
    DEC A
    LD (FireworksCounter), A
;
    LD DE, Enemy_ID_05 + $100           ;start at last slot
StarFChk:
    DEC D
    LD A, (DE)                          ;check for presence of star flag object
    CP A, OBJECTID_StarFlagObject       ;if there isn't a star flag object,
    JP NZ, StarFChk                     ;routine goes into infinite loop = crash
;
    LD E, <Enemy_X_Position             ;get horizontal coordinate of star flag object, then
    LD A, (DE)                          ;subtract 48 pixels from it and save to
    SUB A, $30                          ;to B (was the stack)
    LD B, A
;
    LD E, <Enemy_PageLoc                ;subtract the carry from the page location
    LD A, (DE)                          ;of the star flag object
    SBC A, $00
    LD C, A
;
    LD A, (FireworksCounter)            ;get fireworks counter
    LD L, A
    LD E, <Enemy_State                  ;add state of star flag object (possibly not necessary)
    LD A, (DE)
    ADD A, L
    LD DE, FireworksXPosData            ;use as offset
    addAToDE8_M
    LD A, (DE)                          ;add number based on offset of fireworks counter
    ADD A, B                            ;to saved horizontal coordinate of star flag - 48 pixels            
    LD L, <Enemy_X_Position             ;store as the fireworks object horizontal coordinate
    LD (HL), A
;
    LD A, C                             ;add carry and store as page location for
    ADC A, $00                          ;the fireworks object
    LD L, <Enemy_PageLoc
    LD (HL), A
;
    LD A, $06                           ;get vertical position using same offset
    addAToDE8_M
    LD A, (DE)
    LD L, <Enemy_Y_Position             ;and store as vertical coordinate for fireworks object
    LD (HL), A
;
    LD A, $01                           ;store in vertical high byte
    LD L, <Enemy_Y_HighPos              ;and activate enemy buffer flag
    LD (HL), A
    LD L, <Enemy_Flag
    LD (HL), A
;
    XOR A                               ;initialize explosion counter
    LD L, <ExplosionGfxCounter
    LD (HL), A
;
    LD L, <ExplosionTimerCounter        ;set explosion timing counter
    LD (HL), $08
    RET

;--------------------------------

.SECTION "Bitmasks" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
Bitmasks:
    .db %00000001, %00000010, %00000100, %00001000, %00010000, %00100000, %01000000, %10000000
.ENDS

.SECTION "Enemy17YPosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
Enemy17YPosData:
    .db $40, $30, $90, $50, $20, $60, $a0, $70
.ENDS

.SECTION "SwimCC_IDData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
SwimCC_IDData:
    .db $0a, $0b
.ENDS

BulletBillCheepCheep:
    POP HL
;
    LD A, (FrenzyEnemyTimer)            ;if timer not expired yet, branch to leave
    OR A
    RET NZ
;
    LD A, (AreaType)                    ;are we in a water-type level?
    OR A
    JP NZ, DoBulletBills                ;if not, branch elsewhere
;
    LD A, H                             ;are we past third enemy slot?
    CP A, $C4
    RET NC                              ;if so, branch to leave
;
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)
    LD C, $00                           ;load default offset
    CP A, $AA                           ;check first part of LSFR against preset value
    JP C, ChkW2                         ;if less than preset, do not increment offset
    INC C                               ;otherwise increment
ChkW2:
    LD A, (WorldNumber)                 ;check world number
    CP A, WORLD2
    JP Z, Get17ID                       ;if we're on world 2, do not increment offset
    INC C                               ;otherwise increment
Get17ID:
    LD A, C
    AND A, %00000001                    ;mask out all but last bit of offset
    LD BC, SwimCC_IDData                ;load identifier for cheep-cheeps
    addAToBC8_M
    LD A, (BC)
Set17ID:
    LD L, <Enemy_ID                     ;store whatever's in A as enemy identifier
    LD (HL), A
;
    LD A, (BitMFilter)                  ;if not all bits set, skip init part and compare bits
    INC A
    JP NZ, GetRBit
    LD (BitMFilter), A                  ;initialize vertical position filter
;
GetRBit:
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)                          ;get first part of LSFR
    AND A, %00000111                    ;mask out all but 3 LSB
    LD E, A                             ;store in E
    LD BC, Bitmasks                     ;also use as offset
    addAToBC8_M
    LD A, (BC)                          ;load bitmask
    LD C, A
ChkRBit:
    LD A, (BitMFilter)                  ;perform AND on filter
    AND A, C
    JP Z, AddFBit
    RLC C                               ;shift bitmask
    INC E                               ;increment offset
    LD A, E                             ;mask out all but 3 LSB thus keeping it 0-7
    AND A, %00000111
    LD E, A
    JP ChkRBit                          ;do another check
AddFBit:
    LD A, (BitMFilter)                  ;add bit to already set bits in filter
    OR A, C
    LD (BitMFilter), A
;
    LD A, E                             ;load vertical position using offset
    LD BC, Enemy17YPosData
    addAToBC8_M
    LD A, (BC)
    CALL PutAtRightExtent               ;set vertical position and other values
;
    LD L, <Enemy_YMF_Dummy              ;initialize dummy variable
    LD (HL), A
    LD A, $20                           ;set timer
    LD (FrenzyEnemyTimer), A
;
    JP CheckpointEnemyID                ;process our new enemy object

DoBulletBills:
    LD D, $C0                           ;start at beginning of enemy slots
BB_SLoop:
    INC D                               ;move onto the next slot
    LD A, D
    CP A, $C6                           ;branch to play sound if we've done all slots
    JP NC, FireBulletBill
    LD E, <Enemy_Flag                   ;if enemy buffer flag not set,
    LD A, (DE)
    OR A
    JP Z, BB_SLoop                      ;loop back and check another slot
    LD E, <Enemy_ID                     ;check enemy identifier for
    LD A, (DE)
    CP A, OBJECTID_BulletBill_FrenzyVar ;bullet bill object (frenzy variant)
    JP NZ, BB_SLoop
    RET                                 ;if found, leave

FireBulletBill:
    LD A, SNDID_CANNON                  ;play fireworks/gunfire sound
    LD (SFXTrack1.SoundQueue), A
    LD A, OBJECTID_BulletBill_FrenzyVar ;load identifier for bullet bill object
    JP Set17ID

;--------------------------------
;$00(C) - used to store Y position of group enemies
;$01(IXL) - used to store enemy ID
;$02(D) - used to store page location of right side of screen
;$03(E) - used to store X position of right side of screen
;B - counter for amount of enemies in group

;   CheckpointEnemyID should not touch BC, DE for this to work
;   Goomba, GreenKoopa, and Bettle don't touch, so it works
HandleGroupEnemies:
    LD IXL, $00                         ;load value for green koopa troopa
    SUB A, $37                          ;subtract $37 from second byte read
    PUSH AF                             ;save result in stack for now
    CP A, $04                           ;was byte in $3b-$3e range?
    JP NC, SnglID                       ;if so, branch
;
    PUSH AF                             ;save another copy to stack
    LD IXL, OBJECTID_Goomba             ;load value for goomba enemy
    LD A, (PrimaryHardMode)             ;if primary hard mode flag not set,
    OR A
    JP Z, PullID                        ;branch, otherwise change to value
    LD IXL, OBJECTID_BuzzyBeetle        ;for buzzy beetle
PullID:
    POP AF                              ;get second copy from stack
SnglID:
    AND A, $02                          ;check to see if d1 was set
    LD C, $B0                           ;load default y coordinate
    JP Z, SetYGp                        ;if not, branch and use default
    LD C, $70                           ;otherwise move y coordinate up
SetYGp:
    LD A, (ScreenRight_PageLoc)         ;get page number of right edge of screen
    LD D, A                             ;save here
    LD A, (ScreenRight_X_Pos)           ;get pixel coordinate of right edge
    LD E, A                             ;save here
    LD B, $02                           ;load two enemies by default
    POP AF                              ;get first copy from stack
    SRL A                               ;check to see if d0 was set
    JP NC, CntGrp                       ;if not, use default value
    INC B                               ;otherwise increment to three enemies
CntGrp:
GrLoop:
    LD H, $C0                           ;start at beginning of enemy buffers
GSltLp:
    INC H                               ;increment and branch if past
    LD A, H                             ;end of buffers
    CP A, $C6
    JP NC, Inc2B
    LD L, <Enemy_Flag                   ;check to see if enemy is already
    LD A, (HL)
    OR A
    JR NZ, GSltLp                       ;stored in buffer, and branch if so
;
    LD A, IXL
    LD L, <Enemy_ID                     ;store enemy object identifier
    LD (HL), A
    LD L, <Enemy_PageLoc                ;store page location for enemy object
    LD (HL), D
    LD A, E
    LD L, <Enemy_X_Position             ;store x coordinate for enemy object
    LD (HL), A
    ADD A, $18                          ;add 24 pixels for next enemy
    LD E, A
    LD A, D                             ;add carry to page location for
    ADC A, $00                          ;next enemy
    LD D, A
    LD L, <Enemy_Y_Position             ;store y coordinate for enemy object
    LD (HL), C
    LD A, $01                           ;activate flag for buffer, and
    LD L, <Enemy_Y_HighPos              ;put enemy within the screen vertically
    LD (HL), A
    LD L, <Enemy_Flag
    LD (HL), A
    CALL CheckpointEnemyID              ;process each enemy object separately
    DJNZ GrLoop                         ;do this until we run out of enemy objects
;
    JP Inc2B                            ;jump to increment data offset and leave

;--------------------------------

InitPiranhaPlant:
    POP HL
InitPiranhaPlant_NOPOP:
    LD L, <PiranhaPlant_Y_Speed         ;set initial speed
    LD (HL), $01
;
    XOR A                               ;initialize enemy state and what would normally
    LD L, <Enemy_State                  ;be used as vertical speed, but not in this case
    LD (HL), A
    LD L, <PiranhaPlant_MoveFlag
    LD (HL), A
;
    LD L, <Enemy_Y_Position             ;save original vertical coordinate here
    LD A, (HL)
    LD L, <PiranhaPlantDownYPos
    LD (HL), A
    SUB A, $18
    LD L, <PiranhaPlantUpYPos           ;save original vertical coordinate - 24 pixels here
    LD (HL), A
;
    LD A, $09                           ;set specific value for bounding box control
    LD L, <Enemy_BoundBoxCtrl           ;set bounding box control then leave
    LD (HL), A
    RET


;--------------------------------

InitEnemyFrenzy:
    POP HL
    PUSH HL
    LD L, <Enemy_ID                     ;load enemy identifier
    LD A, (HL)                          ;save in enemy frenzy buffer
    LD (EnemyFrenzyBuffer), A
    SUB A, $12                          ;subtract 12 and use as offset for jump engine
    RST JumpEngine

;   frenzy object jump table
    .dw LakituAndSpinyHandler
    .dw NoFrenzyCode
    .dw InitFlyingCheepCheep
    .dw InitBowserFlame
    .dw InitFireworks
    .dw BulletBillCheepCheep

;--------------------------------

NoFrenzyCode:
    POP HL
    RET

;--------------------------------

EndFrenzy:
    POP HL
;
    LD D, $C6                           ;start at last slot
    LD B, $06
LakituChk:
    LD E, <Enemy_ID                     ;check enemy identifiers
    LD A, (DE)
    CP A, OBJECTID_Lakitu               ;for lakitu
    JP NZ, NextFSlot
    LD E, <Enemy_State                  ;if found, set state
    LD A, $01
    LD (DE), A
NextFSlot:
    DEC D                               ;move onto the next slot
    DJNZ LakituChk                      ;do this until all slots are checked
;
    XOR A                               ;empty enemy frenzy buffer
    LD (EnemyFrenzyBuffer), A           ;disable enemy buffer flag for this object
    LD L, <Enemy_Flag
    LD (HL), A
    RET

;--------------------------------

InitJumpGPTroopa:
    POP HL
;
    LD L, <Enemy_MovingDir                  ;set for movement to the left
    LD (HL), $02
    LD L, <Enemy_X_Speed

    .IF PALBUILD == $00
    LD (HL), $F8                            ;set horizontal speed
    .ELSE
    LD (HL), $F6                            ;PAL diff: Faster horizontal speed to compensate FPS difference
    .ENDIF

TallBBox2:
    LD A, $03                               ;set specific value for bounding box control
;SetBBox2:
    LD L, <Enemy_BoundBoxCtrl               ;set bounding box control then leave
    LD (HL), A
    RET

;--------------------------------

InitBalPlatform:
    POP HL
;
    LD L, <Enemy_Y_Position                 ;raise vertical position by two pixels
    DEC (HL)
    DEC (HL)
;
    LD A, (SecondaryHardMode)               ;if secondary hard mode flag not set,
    OR A
    JP NZ, AlignP                           ;branch ahead
    LD BC, $FFF8                            ;otherwise set value here
    CALL PosPlatform                        ;do a sub to add or subtract pixels
AlignP:
    LD A, (BalPlatformAlignment)            ;get current balance platform alignment
    LD L, <Enemy_State                      ;set platform alignment to object state here
    LD (HL), A
    OR A
    LD A, $FF                               ;set default value here for now
    JP P, SetBPA                            ;if old alignment $ff, put $ff as alignment for negative
    LD A, H                                 ;if old contents already $ff, put
    SUB A, $C1                              ;object offset as alignment to make next positive
SetBPA:
    LD (BalPlatformAlignment), A            ;store value here
    XOR A
    LD L, <Enemy_MovingDir                  ;init moving direction
    LD (HL), A
    LD BC, $0008
    CALL PosPlatform                        ;do a sub to add 8 pixels, then run shared code here
    ; FALL THROUGH
    JP InitDropPlatform_NOPOP

;--------------------------------

InitDropPlatform:
    POP HL
;
InitDropPlatform_NOPOP:
    LD L, <PlatformCollisionFlag            ;set some value here
    LD (HL), $FF
;
    JP CommonPlatCode                       ;then jump ahead to execute more code

;--------------------------------

InitHoriPlatform:
    POP HL
;
    LD L, <XMoveSecondaryCounter            ;init one of the moving counters
    LD (HL), $00
;
    JP CommonPlatCode                       ;jump ahead to execute more code

;--------------------------------

InitVertPlatform:
    POP HL
;
    LD C, $40                               ;set default value here
    LD L, <Enemy_Y_Position                 ;check vertical position
    LD A, (HL)
    OR A
    JP P, SetYO                             ;if above a certain point, skip this part
    NEG                                     ;otherwise get two's compliment
    LD C, $C0                               ;get alternate value to add to vertical position
SetYO:
    LD L, <YPlatformTopYPos                 ;save as top vertical position
    LD (HL), A
    LD L, <Enemy_Y_Position                 ;load value from earlier, add number of pixels
    LD A, C                                 ;to vertical position
    ADD A, (HL)
    LD L, <YPlatformCenterYPos              ;save result as central vertical position
    LD (HL), A
    ; FALL THROUGH

;--------------------------------

CommonPlatCode:
    CALL InitVStf                           ;do a sub to init certain other values
SPBBox:
    LD A, (AreaType)
    CP A, $03                               ;check for castle-type level
    LD A, $05                               ;set default bounding box size control
    JP Z, CasPBB                            ;use default value if found
    LD A, (SecondaryHardMode)               ;otherwise check for secondary hard mode flag
    OR A
    LD A, $05
    JP NZ, CasPBB                           ;if set, use default value
    LD A, $06                               ;use alternate value if not castle or secondary not set
CasPBB:
    LD L, <Enemy_BoundBoxCtrl               ;set bounding box size control here and leave
    LD (HL), A
    RET

;--------------------------------

LargeLiftUp:
    POP HL
;
    CALL PlatLiftUp_NOPOP                   ;execute code for platforms going up
    JP SPBBox                               ;overwrite bounding box for large platforms

LargeLiftDown:
    POP HL
;
    CALL PlatLiftDown_NOPOP                 ;execute code for platforms going down
    JP SPBBox                               ;jump to overwrite bounding box size control

;--------------------------------

PlatLiftUp:
    POP HL
PlatLiftUp_NOPOP:
    LD L, <Enemy_Y_MoveForce                ;set movement amount here
    LD (HL), $10
    LD L, <Enemy_Y_Speed                    ;set moving speed for platforms going up
    LD (HL), $FF
    JP CommonSmallLift                      ;skip ahead to part we should be executing

;--------------------------------

PlatLiftDown:
    POP HL
PlatLiftDown_NOPOP:
    LD L, <Enemy_Y_MoveForce                ;set movement amount here
    LD (HL), $F0
    LD L, <Enemy_Y_Speed                    ;set moving speed for platforms going down
    LD (HL), $00

;--------------------------------

CommonSmallLift:
    LD BC, $000C
    CALL PosPlatform                        ;do a sub to add 12 pixels due to preset value
    LD L, <Enemy_BoundBoxCtrl               ;set bounding box control for small platforms
    LD (HL), $04
    RET

;--------------------------------
; PlatPosDataLow:
;     .db $08,$0c,$f8

; PlatPosDataHigh:
;     .db $00,$00,$ff

; $0008 : $00
; $000C : $01
; $FFF8 : $02

PosPlatform:
    LD A, C
    LD L, <Enemy_X_Position                 ;get horizontal coordinate
    ADD A, (HL)                             ;add or subtract pixels depending on offset
    LD (HL), A                              ;store as new horizontal coordinate
;
    LD A, B
    DEC L                                   ;<Enemy_PageLoc
    ADC A, (HL)                             ;add or subtract page location depending on offset
    LD (HL), A                              ;store as new page location
    RET

;--------------------------------

EndOfEnemyInitCode:
    POP HL
    RET