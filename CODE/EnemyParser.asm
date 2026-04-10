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

CheckEndofBuffer:
    AND A, %00001111                ;check for special row $0e
    CP A, $0E
    JP Z, CheckRightBounds          ;if found, branch, otherwise
    LD A, H                         ;check for end of buffer
    CP A, $C0 + OBJ_SLOT6
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
    EX AF, AF' ;LD C, A                         ;save identifier in Y register for now
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    ADD A, $08                      ;add eight pixels to what will eventually be the
    LD (HL), A                      ;enemy object's vertical coordinate ($00-$14 only)
;
    LD L, <EnemyOffscrBitsMasked    ;set offscreen masked bit
    LD (HL), $01
;
    EX AF, AF' ;LD A, C                         ;get identifier back and use as offset for jump engine

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

;   X - ENEMY OFFSET
;   Y - BLOCK OFFSET
Setup_Vine:
    POP HL
Setup_Vine_NOPOP:
    LD A, OBJECTID_VineObject
    LD L, <Enemy_ID
    LD (HL), A
;
    LD L, <Enemy_Flag
    LD (HL), $01
;
    LD E, <Block_PageLoc
    LD A, (DE)
    LD L, <Enemy_PageLoc
    LD (HL), A
;
    LD E, <Block_X_Position
    LD A, (DE)
    LD L, <Enemy_X_Position
    LD (HL), A
;
    LD A, (VineFlagOffset)
    OR A
    LD E, <Block_Y_Position
    LD A, (DE)
    LD L, <Enemy_Y_Position
    LD (HL), A
;    
    JP NZ, NextVO
    LD (VineStart_Y_Position), A
NextVO: 
    LD DE, VineObjOffset
    LD A, (VineFlagOffset)
    ADD A, D
    LD D, A
    LD A, H
    SUB A, $D0  ; RAM OFFSET -> OBJECT OFFSET
    LD (DE), A
;
    LD A, (VineFlagOffset)
    INC A
    LD (VineFlagOffset), A
;
    LD A, SNDID_VINE
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
    LD L, <Enemy_Y_Position         ;set fixed vertical position for
    LD (HL), $B8                    ;princess/mushroom retainer object
    RET

;--------------------------------

InitNormalEnemy:
    POP HL
InitNormalEnemy_NOPOP:
    LD A, (PrimaryHardMode)         ;check for primary hard mode flag set
    OR A
    LD A, $F4                       ;load default offset
    JP NZ, GetESpd
    LD A, $F8                       ;if not set, load alternate offset
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
;
TallBBox:
    LD A, $03                       ;set specific bounding box size control
SetBBox:
    LD L, <Enemy_BoundBoxCtrl       ;set bounding box control here
    LD (HL), A
;
    LD L, <Enemy_MovingDir          ;set moving direction for left
    LD (HL), $02
;
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
    JP InitHorizFlySwimEnemy        ;set $03 as bounding box, set other attributes
    ;JP TallBBox2                   ;set $03 as bounding box again (not necessary) and leave

;--------------------------------
;$01-$03 - used to hold pseudorandom difference adjusters

.SECTION "PRDiffAdjustData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PRDiffAdjustData:
    .db $26, $2c, $32, $38
    .db $20, $22, $24, $26
    .db $13, $14, $15, $16
.ENDS 

LakituAndSpinyHandler:
    POP HL
;
    LD A, (FrenzyEnemyTimer)            ;if timer here not expired, leave
    OR A
    RET NZ
;
    LD A, H
    CP A, $C0 + OBJ_SLOT6               ;if we are on the special use slot, leave
    RET NC
;
    LD A, $80                           ;set timer
    LD (FrenzyEnemyTimer), A
;
    LD DE, Enemy_ID + OBJ_SLOT5 * $100  ;start with the last enemy slot
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
    LD HL, Enemy_Flag + OBJ_SLOT5 * $100;start with the last enemy slot again
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
    LD L, <Enemy_PageLoc
    LD A, (DE)
    LD (HL), A
;
    LD E, <Enemy_X_Position             ;into the coordinates of the spiny we're going to create
    LD L, <Enemy_X_Position
    LD A, (DE)
    LD (HL), A
;
    LD L, <Enemy_Y_HighPos              ;put spiny within vertical screen unit
    LD (HL), $01
;
    LD E, <Enemy_Y_Position             ;put spiny eight pixels above where lakitu is
    LD L, <Enemy_Y_Position
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
    LD BC, PRDiffAdjustData
    addAToBC8_M
;
DifLoop:
    LD A, (BC)                          ;get three values and save them
    LD (Temp_Bytes + $03), A            ;to $01-$03
    LD A, $04
    addAToBC8_M
    LD A, (BC)
    LD (Temp_Bytes + $02), A
    LD A, $04
    addAToBC8_M
    LD A, (BC)
    LD (Temp_Bytes + $01), A
;
    ;LD HL, (ObjectOffset)              ;get enemy object buffer offset
    CALL PlayerLakituDiff               ;move enemy, change direction, get value - difference
    /*
    EX AF, AF'
    LD A, (Player_X_Speed)              ;check player's horizontal speed
    CP A, $08
    JP NC, SetSpSpd                     ;if moving faster than a certain amount, branch elsewhere
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg + $01
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011                    ;get one of the LSFR parts and save the 2 LSB
    JP Z, UsePosv                       ;branch if neither bits are set
    EX AF, AF'
    NEG                                 ;otherwise get two's compliment of Y
    EX AF, AF'
UsePosv:
SetSpSpd:
    EX AF, AF'                          ;put value from A in Y back to A (they will be lost anyway)
    */
    CALL SmallBBox                      ;set bounding box control, init attributes, lose contents of A
;
    LD L, <Enemy_X_Speed                ;set horizontal speed to zero because previous contents
    LD (HL), A
    /*
    OR A                                ;of A were lost...branch here will never be taken for
    LD A, $02                           ;the same reason
    JP M, SpinyRte
    DEC A
SpinyRte:
    */
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

.SECTION "FirebarSpinSpdData/FirebarSpinDirData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FirebarSpinSpdData:
    .db $28, $38, $28, $38, $28

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

.SECTION "FlyCCXPositionData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FlyCCXPositionData:
    .db $80, $30, $40, $80
    .db $30, $50, $50, $70
    .db $20, $40, $80, $a0
    .db $70, $40, $90, $68
.ENDS

.SECTION "FlyCCXSpeedData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FlyCCXSpeedData:
    .db $0e, $05, $06, $0e
    .db $1c, $20, $10, $0c
    .db $1e, $22, $18, $14
.ENDS

.SECTION "FlyCCTimerData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
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
    LD (HL), $FB
;
    LD A, (Player_X_Speed)              ;check player's horizontal speed
    OR A
    LD A, $00                           ;load default value
    JP Z, GSeed                         ;if player not moving left or right, skip this part
    LD A, (Player_X_Speed)              ;if moving to the right but not very quickly,
    CP A, $19
    LD A, $04
    JP C, GSeed                         ;do not change A
    ADD A, A                            ;otherwise, multiply A by 2
GSeed:
    PUSH AF
    LD C, A
    LD A, (Temp_Bytes + $00)
    ADD A, C
    LD (Temp_Bytes + $00), A
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011
    JP Z, RSeed
    INC C
    LD A, (BC)
    AND A, %00001111
    LD (Temp_Bytes + $00), A
RSeed:
    POP AF
    LD C, A
    LD A, (Temp_Bytes + $01)
    ADD A, C
    LD C, A
    LD DE, FlyCCXSpeedData
    addAToDE8_M
    LD A, (DE)
    LD L, <Enemy_X_Speed
    LD (HL), A
;
    LD L, <Enemy_MovingDir
    LD (HL), $01
;
    LD A, (Player_X_Speed)
    OR A
    JP NZ, D2XPos1
    LD A, (Temp_Bytes + $00)
    LD C, A
    AND A, %00000010
    JP Z, D2XPos1
    LD L, <Enemy_X_Speed
    LD A, (HL)
    NEG
    LD (HL), A
    LD L, <Enemy_MovingDir
    INC (HL)
;
D2XPos1:
    LD A, C
    LD DE, FlyCCXPositionData
    addAToDE8_M
    LD A, C
    AND A, %00000010
    JP Z, D2XPos2
    LD A, (Player_X_Position)
    EX DE, HL
    ADD A, (HL)
    EX DE, HL
    LD L, <Enemy_X_Position
    LD (HL), A
    LD A, (Player_PageLoc)
    ADC A, $00
    JP FinCCSt
;
D2XPos2:
    LD A, (Player_X_Position)
    EX DE, HL
    SUB A, (HL)
    EX DE, HL
    LD L, <Enemy_X_Position
    LD (HL), A
    LD A, (Player_PageLoc)
    SBC A, $00
;
FinCCSt:
    LD L, <Enemy_PageLoc
    LD (HL), A
;
    LD L, <Enemy_Flag
    LD (HL), $01
    LD L, <Enemy_Y_HighPos
    LD (HL), $01
    LD L, <Enemy_Y_Position
    LD (HL), $F8
    RET

;--------------------------------

InitBowser:
    POP HL
;
    CALL DuplicateEnemyObj
;
    LD A, H
    SUB A, $C1
    LD (BowserFront_Offset), A
;
    XOR A
    LD (BowserBodyControls), A
    LD (BridgeCollapseOffset), A
;
    LD L, <Enemy_X_Position
    LD A, (HL)
    LD (BowserOrigXPos), A
;
    LD A, $DF
    LD (BowserFireBreathTimer), A
    LD L, <Enemy_MovingDir
    LD (HL), A
;
    LD A, $20
    LD (BowserFeetCounter), A
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, $20
    LD (BC), A
;
    LD A, $05
    LD (BowserHitPoints), A
;
    SRL A
    LD (BowserMovementSpeed), A
    RET

;--------------------------------

DuplicateEnemyObj:
    LD DE, $C000 + <Enemy_Flag
FSLoop:
    INC D
    LD A, (DE)
    OR A
    JP NZ, FSLoop
;
    LD A, D
    SUB A, $C1
    LD (DuplicateObj_Offset), A
;
    LD A, H
    SUB A, $C1
    OR A, %10000000
    LD (DE), A
;
    LD L, <Enemy_PageLoc
    LD E, <Enemy_PageLoc
    LD A, (HL)
    LD (DE), A
;
    LD L, <Enemy_X_Position
    LD E, <Enemy_X_Position
    LD A, (HL)
    LD (DE), A
;
    LD L, <Enemy_Flag
    LD E, <Enemy_Y_HighPos
    LD A, $01
    LD (HL), A
    LD (DE), A
;
    LD L, <Enemy_Y_Position
    LD E, <Enemy_Y_Position
    LD A, (HL)
    LD (DE), A
    RET
    
;--------------------------------

.SECTION "FlameYPosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FlameYPosData:
    .db $90, $80, $70, $90
    ;.db $78, $68, $58, $78
.ENDS


InitBowserFlame:
    POP HL
;
    LD A, (FrenzyEnemyTimer)
    OR A
    RET NZ
;
    LD L, <Enemy_Y_MoveForce
    LD (HL), A
;
    LD A, SNDID_FLAME
    LD (SFXTrack2.SoundQueue), A
;
    LD DE, Enemy_ID
    LD A, (BowserFront_Offset)
    ADD A, D
    LD D, A
    LD A, (DE)
    CP A, OBJECTID_Bowser
    JP Z, SpawnFromMouth
;
    CALL SetFlameTimer
    ADD A, $20
    LD C, A
    LD A, (SecondaryHardMode)
    OR A
    JP Z, SetFrT
    LD A, C
    SUB A, $10
    LD C, A
SetFrT:
    LD A, C
    LD (FrenzyEnemyTimer), A
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011
    LD L, <BowserFlamePRandomOfs
    LD (HL), A
    LD BC, FlameYPosData
    addAToBC8_M
    LD A, (BC)

PutAtRightExtent:
    LD L, <Enemy_Y_Position
    LD (HL), A
;
    LD A, (ScreenRight_X_Pos)
    ADD A, $20
    LD L, <Enemy_X_Position
    LD (HL), A
;
    LD A, (ScreenRight_PageLoc)
    ADC A, $00
    LD L, <Enemy_PageLoc
    LD (HL), A
;
    JP FinishFlame

SpawnFromMouth:
    LD E, <Enemy_X_Position
    LD L, <Enemy_X_Position
    LD A, (DE)
    SUB A, $0E
    LD (HL), A
;
    LD E, <Enemy_PageLoc
    LD L, <Enemy_PageLoc
    LD A, (DE)
    LD (HL), A
;
    LD E, <Enemy_Y_Position
    LD L, <Enemy_Y_Position
    LD A, (DE)
    ADD A, $08
    LD (HL), A
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)
    AND A, %00000011
    LD L, <Enemy_YMF_Dummy
    LD (HL), A
;
    LD BC, FlameYPosData
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_Y_Position
    CP A, (HL)
    LD A, $FF
    JP C, SetMF
    LD A, $01
SetMF:
    LD L, <Enemy_Y_MoveForce
    LD (HL), A
    XOR A
    LD (EnemyFrenzyBuffer), A

FinishFlame:
    LD L, <Enemy_BoundBoxCtrl
    LD (HL), $08
;
    LD A, $01
    LD L, <Enemy_Y_HighPos
    LD (HL), A
    LD L, <Enemy_Flag
    LD (HL), A
;
    XOR A
    LD L, <Enemy_X_MoveForce
    LD (HL), A
    LD L, <Enemy_State
    LD (HL), A
    RET

;--------------------------------

.SECTION "FireworksXPosData/FireworksYPosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FireworksXPosData:
    .db $00, $30, $60, $60, $00, $20

FireworksYPosData:
    .db $60, $40, $70, $40, $60, $30
    ;.db $48, $28, $58, $28, $48, $18
.ENDS

InitFireworks:
    POP HL
;
    LD A, (FrenzyEnemyTimer)
    OR A
    RET NZ
;
    LD A, $20
    LD (FrenzyEnemyTimer), A
;
    LD A, (FireworksCounter)
    DEC A
    LD (FireworksCounter), A
;
    LD DE, Enemy_ID + $06 * $100
StarFChk:
    DEC D
    LD A, (DE)
    CP A, OBJECTID_StarFlagObject
    JP NZ, StarFChk
;
    LD E, <Enemy_X_Position
    LD A, (DE)
    SUB A, $30
    PUSH AF
;
    LD E, <Enemy_PageLoc
    LD A, (DE)
    SBC A, $00
    LD (Temp_Bytes + $00), A
;
    LD A, (FireworksCounter)
    LD C, A
    LD E, <Enemy_State
    LD A, (DE)
    ADD A, C
    LD DE, FireworksXPosData
    addAToDE8_M
    POP AF
    LD C, A
    LD A, (DE)
    ADD A, C
    LD L, <Enemy_X_Position
    LD (HL), A
;
    LD A, (Temp_Bytes + $00)
    ADC A, $00
    LD L, <Enemy_PageLoc
    LD (HL), A
;
    LD A, $06
    addAToDE8_M
    LD A, (DE)
    LD L, <Enemy_Y_Position
    LD (HL), A
;
    LD A, $01
    LD L, <Enemy_Y_HighPos
    LD (HL), A
    LD L, <Enemy_Flag
    LD (HL), A
;
    XOR A
    LD L, <ExplosionGfxCounter
    LD (HL), A
;
    LD L, <ExplosionTimerCounter
    LD (HL), $08
    RET

;--------------------------------

.SECTION "Bitmasks" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
Bitmasks:
    .db %00000001, %00000010, %00000100, %00001000, %00010000, %00100000, %01000000, %10000000
.ENDS

.SECTION "Enemy17YPosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
Enemy17YPosData:
    .db $40, $30, $90, $50, $20, $60, $a0, $70
    ;.db $28, $18, $78, $38, $08, $48, $88, $58
.ENDS

.SECTION "SwimCC_IDData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
SwimCC_IDData:
    .db $0a, $0b
.ENDS

BulletBillCheepCheep:
    POP HL
;
    LD A, (FrenzyEnemyTimer)
    OR A
    RET NZ
;
    LD A, (AreaType)
    OR A
    JP NZ, DoBulletBills
;
    LD A, H
    CP A, $C4
    RET NC
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)
    LD C, $00
    CP A, $AA
    JP C, ChkW2
    INC C
ChkW2:
    LD A, (WorldNumber)
    CP A, WORLD2
    JP Z, Get17ID
    INC C
Get17ID:
    LD A, C
    AND A, %00000001
    LD BC, SwimCC_IDData
    addAToBC8_M
    LD A, (BC)
Set17ID:
    LD L, <Enemy_ID
    LD (HL), A
;
    LD A, (BitMFilter)
    CP A, $FF
    JP NZ, GetRBit
    XOR A
    LD (BitMFilter), A
;
GetRBit:
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)
    AND A, %00000111
    LD E, A
    LD BC, Bitmasks
    addAToBC8_M
    LD A, (BC)
    LD C, A
ChkRBit:
    LD A, (BitMFilter)
    AND A, C
    JP Z, AddFBit
    RLC C
    LD A, E
    INC A
    AND A, %00000111
    LD E, A
    JP ChkRBit
AddFBit:
    LD A, (BitMFilter)
    OR A, C
    LD (BitMFilter), A
;
    LD A, E
    LD BC, Enemy17YPosData
    addAToBC8_M
    LD A, (BC)
    CALL PutAtRightExtent
;
    LD L, <Enemy_YMF_Dummy
    LD (HL), A
    LD A, $20
    LD (FrenzyEnemyTimer), A
;
    JP CheckpointEnemyID

DoBulletBills:
    LD D, $C0
BB_SLoop:
    INC D
    LD A, D
    CP A, $C6
    JP NC, FireBulletBill
    LD E, <Enemy_Flag
    LD A, (DE)
    OR A
    JP Z, BB_SLoop
    LD E, <Enemy_ID
    LD A, (DE)
    CP A, OBJECTID_BulletBill_FrenzyVar
    JP NZ, BB_SLoop
    RET

FireBulletBill:
    LD A, SNDID_CANNON
    LD (SFXTrack1.SoundQueue), A
    LD A, OBJECTID_BulletBill_FrenzyVar
    JP Set17ID

;--------------------------------
;$00(C) - used to store Y position of group enemies
;$01(IXL) - used to store enemy ID
;$02(D) - used to store page location of right side of screen
;$03(E) - used to store X position of right side of screen
    /*
HandleGroupEnemies:
    LD C, $00
    SUB A, $37
    PUSH AF
    CP A, $04
    JP NC, SnglID
;
    PUSH AF
    LD C, OBJECTID_Goomba
    LD A, (PrimaryHardMode)
    OR A
    JP Z, PullID
    LD C, OBJECTID_BuzzyBeetle
PullID:
    POP AF
SnglID:
    LD IXL, C
    AND A, $02
    LD A, $B0
    JP Z, SetYGp
    LD A, $70
SetYGp:
    LD B, A ;LD (Temp_Bytes + $00), A
    LD A, (ScreenRight_PageLoc)
    LD D, A ;LD (Temp_Bytes + $02), A
    LD A, (ScreenRight_X_Pos)
    LD E, A ;LD (Temp_Bytes + $03), A
    LD C, $02
    POP AF
    SRL A
    JP NC, CntGrp
    INC C
CntGrp:
    LD A, C
    LD (NumberofGroupEnemies), A
GrLoop:
    LD H, $C0
GSltLp:
    INC H
    LD A, H
    CP A, $C6
    JP NC, Inc2B
    LD L, <Enemy_Flag
    LD A, (HL)
    OR A
    JP NZ, GSltLp
;
    LD A, IXL
    LD L, <Enemy_ID
    LD (HL), A
    ;LD A, (Temp_Bytes + $02)
    LD L, <Enemy_PageLoc
    LD (HL), D ;LD (HL), A
    LD A, E ;LD A, (Temp_Bytes + $03)
    LD L, <Enemy_X_Position
    LD (HL), A
    ADD A, $18
    LD E, A ;LD (Temp_Bytes + $03), A
    LD A, D ;LD A, (Temp_Bytes + $02)
    ADC A, $00
    LD D, A ;LD (Temp_Bytes + $02), A
    ;LD A, (Temp_Bytes + $00)
    LD L, <Enemy_Y_Position
    LD (HL), B ;LD (HL), A
    LD A, $01
    LD L, <Enemy_Y_HighPos
    LD (HL), A
    LD L, <Enemy_Flag
    LD (HL), A
;
    CALL CheckpointEnemyID
;
    LD A, (NumberofGroupEnemies)
    DEC A
    LD (NumberofGroupEnemies), A
    JP NZ, GrLoop
;
    JP Inc2B
    */
HandleGroupEnemies:
    LD IXL, $00
    SUB A, $37
    PUSH AF
    CP A, $04
    JP NC, SnglID
;
    PUSH AF
    LD IXL, OBJECTID_Goomba
    LD A, (PrimaryHardMode)
    OR A
    JP Z, PullID
    LD IXL, OBJECTID_BuzzyBeetle
PullID:
    POP AF
SnglID:
    AND A, $02
    LD A, $B0
    JP Z, SetYGp
    LD A, $70
SetYGp:
    LD C, A
    LD A, (ScreenRight_PageLoc)
    LD D, A
    LD A, (ScreenRight_X_Pos)
    LD E, A
    LD B, $02
    POP AF
    SRL A
    JP NC, CntGrp
    INC B
CntGrp:
    LD H, $C0
GrLoop:
GSltLp:
    INC H
    LD A, H
    CP A, $C6
    JP NC, Inc2B
    LD L, <Enemy_Flag
    LD A, (HL)
    OR A
    JR NZ, GSltLp
;
    LD A, IXL
    LD L, <Enemy_ID
    LD (HL), A
    LD L, <Enemy_PageLoc
    LD (HL), D
    LD A, E
    LD L, <Enemy_X_Position
    LD (HL), A
    ADD A, $18
    LD E, A
    LD A, D
    ADC A, $00
    LD D, A
    LD L, <Enemy_Y_Position
    LD (HL), C
    LD A, $01
    LD L, <Enemy_Y_HighPos
    LD (HL), A
    LD L, <Enemy_Flag
    LD (HL), A
    CALL CheckpointEnemyID  ; BC ISN'T TOUCHED FOR GOOMBA, GREEN KOOPA, OR BETTLE
    DJNZ GrLoop
;
    JP Inc2B

;--------------------------------

InitPiranhaPlant:
    POP HL
InitPiranhaPlant_NOPOP:
    LD L, <PiranhaPlant_Y_Speed
    LD (HL), $01
;
    XOR A
    LD L, <Enemy_State
    LD (HL), A
    LD L, <PiranhaPlant_MoveFlag
    LD (HL), A
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD L, <PiranhaPlantDownYPos
    LD (HL), A
    SUB A, $18
    LD L, <PiranhaPlantUpYPos
    LD (HL), A
;
    LD A, $09
    JP SetBBox2


;--------------------------------

InitEnemyFrenzy:
    POP HL
    PUSH HL
    LD L, <Enemy_ID
    LD A, (HL)
    LD (EnemyFrenzyBuffer), A
    SUB A, $12
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
    LD D, $C6
    LD B, $06
LakituChk:
    LD E, <Enemy_ID
    LD A, (DE)
    CP A, OBJECTID_Lakitu
    JP NZ, NextFSlot
    LD E, <Enemy_State
    LD A, $01
    LD (DE), A
NextFSlot:
    DEC D
    DJNZ LakituChk
;
    XOR A
    LD (EnemyFrenzyBuffer), A
    LD L, <Enemy_Flag
    LD (HL), A
    RET

;--------------------------------

InitJumpGPTroopa:
    POP HL
;
    LD L, <Enemy_MovingDir
    LD (HL), $02
    LD L, <Enemy_X_Speed
    LD (HL), $F8
TallBBox2:
    LD A, $03
SetBBox2:
    LD L, <Enemy_BoundBoxCtrl
    LD (HL), A
    RET

;--------------------------------

InitBalPlatform:
    POP HL
;
    LD L, <Enemy_Y_Position
    DEC (HL)
    DEC (HL)
;
    LD A, (SecondaryHardMode)
    OR A
    JP NZ, AlignP
    LD A, $02
    CALL PosPlatform
AlignP:
    LD A, (BalPlatformAlignment)
    LD L, <Enemy_State
    LD (HL), A
    OR A
    LD A, $FF
    JP P, SetBPA
    LD A, H
    SUB A, $C1
SetBPA:
    LD (BalPlatformAlignment), A
    XOR A
    LD L, <Enemy_MovingDir
    LD (HL), A
    CALL PosPlatform

;--------------------------------

InitDropPlatform:
    POP HL
;
    LD L, <PlatformCollisionFlag
    LD (HL), $FF
;
    JP CommonPlatCode

;--------------------------------

InitHoriPlatform:
    POP HL
;
    LD L, <XMoveSecondaryCounter
    LD (HL), $00
;
    JP CommonPlatCode

;--------------------------------

InitVertPlatform:
    POP HL
;
    LD C, $40
    LD L, <Enemy_Y_Position
    LD A, (HL)
    OR A
    JP P, SetYO
    NEG
    LD C, $C0
SetYO:
    LD L, <YPlatformTopYPos
    LD (HL), A
    LD L, <Enemy_Y_Position
    LD A, C
    ADD A, (HL)
    LD L, <YPlatformCenterYPos
    LD (HL), A
    ; FALL THROUGH

;--------------------------------

CommonPlatCode:
    CALL InitVStf
SPBBox:
    LD A, (AreaType)
    CP A, $03
    LD A, $05
    JP Z, CasPBB
    LD A, (SecondaryHardMode)
    OR A
    LD A, $05
    JP NZ, CasPBB
    LD A, $06
CasPBB:
    LD L, <Enemy_BoundBoxCtrl
    LD (HL), A
    RET

;--------------------------------

LargeLiftUp:
    POP HL
;
    CALL PlatLiftUp_NOPOP
    JP SPBBox

LargeLiftDown:
    POP HL
;
    CALL PlatLiftDown_NOPOP
    JP SPBBox

;--------------------------------

PlatLiftUp:
    POP HL
PlatLiftUp_NOPOP:
    LD L, <Enemy_Y_MoveForce
    LD (HL), $10
    LD L, <Enemy_Y_Speed
    LD (HL), $FF
    JP CommonSmallLift

;--------------------------------

PlatLiftDown:
    POP HL
PlatLiftDown_NOPOP:
    LD L, <Enemy_Y_MoveForce
    LD (HL), $F0
    LD L, <Enemy_Y_Speed
    LD (HL), $00

;--------------------------------

CommonSmallLift:
    LD A, $01
    CALL PosPlatform
    LD L, <Enemy_BoundBoxCtrl
    LD (HL), $04
    RET

;--------------------------------
.SECTION "PlatPosDataLow/PlatPosDataHigh" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PlatPosDataLow:
    .db $08,$0c,$f8

PlatPosDataHigh:
    .db $00,$00,$ff
.ENDS

PosPlatform:
    LD BC, PlatPosDataLow
    addAToBC8_M
;
    LD A, (BC)
    LD L, <Enemy_X_Position
    ADD A, (HL)
    LD (HL), A
;
    INC C
    INC C
    INC C
    LD A, (BC)
    LD L, <Enemy_PageLoc
    ADC A, (HL)
    LD (HL), A
    RET

;--------------------------------

EndOfEnemyInitCode:
    POP HL
    RET