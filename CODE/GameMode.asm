;-------------------------------------------------------------------------------------

;indirect jump routine called when
;$0770 is set to 1
GameMode:
    LD A, (OperMode_Task)
    RST JumpEngine

    .dw InitializeArea
    .dw ScreenRoutines
    .dw SecondaryGameSetup
    .dw GameCoreRoutine

;-------------------------------------------------------------------------------------

InitializeArea:
    LD HL, InitAreaOffset           ;clear all memory again, only as far as $074b
    CALL InitializeMemory           ;this is only necessary if branching from
;@ClrTimersLoop:
    LD HL, Timers                   ;clear out memory between
    LD DE, Timers + $01             ;$0780 and $07a1
    LD BC, $22 - $01
    LD (HL), $00
    LDIR
    LD A, (AltEntranceControl)
    OR A
    LD A, (HalfwayPage)             ;if AltEntranceControl not set, use halfway page, if any found
    JP Z, @StartPage
    LD A, (EntrancePage)            ;otherwise use saved entry page number here
@StartPage:
    LD (ScreenLeft_PageLoc), A      ;set as value here
    LD (CurrentPageLoc), A          ;also set as current page
    LD (BackloadingFlag), A         ;set flag here if halfway page or saved entry page number found
    CALL GetScreenPosition          ;get pixel coordinates for screen borders
    LD HL, VRAM_ADR_NAMETBL + $40 | VRAMWRITE
    LD (CurrentNTAddr), HL          ;store name table address
    AND A, %00000001
    ADD A, A                        ;store LSB of page number in high nybble
    ADD A, A                        ;of block buffer column position
    ADD A, A
    ADD A, A
    LD (BlockBufferColumnPos), A
    LD HL, AreaObjectLength
    DEC (HL)                        ;set area object lengths for all empty
    INC H
    DEC (HL)
    INC H
    DEC (HL)
    LD A, $2E   ; $2F
    ;LD A, $20                       ;"ColumnSets" is now more like the amount of columns drawn to the screen in tiles (NOT METATILES)
    ;LD A, $0B                       ;set value for renderer to update 12 column sets
    LD (ColumnSets), A              ;12 column sets = 24 metatile columns = 1 1/2 screens
    CALL GetAreaDataAddrs           ;get enemy and level addresses and load header
    LD A, (PrimaryHardMode)         ;check to see if primary hard mode has been activated
    OR A
    JP NZ, @SetSecHard              ;if so, activate the secondary no matter where we're at
    LD A, (WorldNumber)             ;otherwise check world number
    CP A, WORLD5                    ;if less than 5, do not activate secondary
    JP C, @CheckHalfway
    JP NZ, @SetSecHard              ;if not equal to, then world > 5, thus activate
    LD A, (LevelNumber)             ;otherwise, world 5, so check level number
    CP A, LEVEL3                    ;if 1 or 2, do not set secondary hard mode flag
    JP C, @CheckHalfway 
@SetSecHard:
    LD HL, SecondaryHardMode        ;set secondary hard mode flag for areas 5-3 and beyond
    INC (HL)
@CheckHalfway:
    LD A, (HalfwayPage)
    OR A
    JP Z, @DoneInitArea
    LD A, $02                       ;if halfway page set, overwrite start position from header
    LD (PlayerEntranceCtrl), A
@DoneInitArea:
    LD A, SNDID_SILENCE
    LD (MusicTrack0.SoundQueue), A
    LD A, $01                       ;disable screen output
    LD (DisableScreenFlag), A
    LD HL, OperMode_Task            ;increment one of the modes
    INC (HL)
    RET

;-------------------------------------------------------------------------------------

SecondaryGameSetup:
    XOR A
    LD (DisableScreenFlag), A           ;enable screen output
;   !!! THIS CLEARS WAY MORE STUFF THAN JUST THE VRAM BUFFERS !!!
    /*
    LD HL, VRAM_Buffer1_Offset          ;clear buffer at $0300-$03ff
    LD DE, VRAM_Buffer1_Offset + $01
    LD BC, $00FF
    LD (HL), A
    LDIR
    */
    LD HL, VRAM_Buffer1
    LD (VRAM_Buffer1_Ptr), HL
    LD DE, VRAM_Buffer1 + $01
    LD BC, _sizeof_VRAM_Buffer1 - 1
    LD (HL), $00
    LDIR    
    LD HL, VRAM_Buffer2
    LD DE, VRAM_Buffer2 + $01
    LD BC, _sizeof_VRAM_Buffer2 - 1
    LD (HL), $00
    LDIR
    ;LD HL, VRAM_Buffer2
    ;LD (VRAM_Buffer2_Ptr), HL
;   !!!
    LD (GameTimerExpiredFlag), A        ;clear game timer exp flag
    LD (DisableIntermediate), A         ;clear skip lives display flag
    LD (BackloadingFlag), A             ;clear value here
    DEC A
    LD (BalPlatformAlignment), A        ;initialize balance platform assignment flag
    CALL GetAreaMusic                   ;load proper music into queue
;
    LD HL, SprShuffleAmt + $02 * $100   ;load sprite shuffle amounts to be used later
    LD (HL), $0E ;$38
    DEC H
    LD (HL), $12 ;$48
    DEC H
    LD (HL), $16 ;$58
    LD HL, DefaultSprOffsets            ;load default OAM offsets
    LD DE, SprDataOffset
    LD B, $0F
-:
    LD A, (HL)
    LD (DE), A
    INC L
    INC D
    DJNZ -
;
    LD HL, Sprite0HitDetectFlag         ;set sprite #0 check flag
    INC (HL)
    LD HL, OperMode_Task                ;increment to next task
    INC (HL)
    RET

.SECTION "Default Sprite Offsets" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
DefaultSprOffsets:
    ;.db $04, $30, $48, $60, $78, $90, $a8, $c0
    ;.db $d8, $e8, $24, $f8, $fc, $28, $2c
    .db $01 ; Player
    .db $0C ; Enemy 1
    .db $12 ; Enemy 2
    .db $18 ; Enemy 3
    .db $1E ; Enemy 4
    .db $24 ; Enemy 5
    .db $2A ; Enemy 6/Power Up
    .db $30 ; Enemy 7?
    .db $36 ; Block/Alt 1
    .db $3A ; Block/Alt 2
    .db $09 ; Bubble 1
    .db $3E ; Bubble 2
    .db $3F ; Bubble 3
    .db $0A ; Fireball 1
    .db $0B ; Fireball 2
.ENDS

;Sprite0Data:
;    .db $18, $ff, $23, $58

;-------------------------------------------------------------------------------------

GameCoreRoutine:
    LD A, (CurrentPlayer)               ;use appropriate player's controller bits
    OR A
    JP Z, +
    LD A, (SavedJoypad2Bits)
    LD (SavedJoypad1Bits), A            ;as the master controller bits
+:
    CALL GameRoutines                   ;execute one of many possible subs
    LD A, (OperMode_Task)               ;check major task of operating mode
    CP A, $03                           ;if we are supposed to be here,
    JP NC, GameEngine                   ;branch to the game engine itself
    RET
    
;-------------------------------------------------------------------------------------

GameEngine:
    CALL ProcFireball_Bubble                ;process fireballs and air bubbles
;
    LD H, $C0 + OBJ_SLOT1   ; 54
ProcELoop:
    LD (ObjectOffset), HL
    CALL EnemiesAndLoopsCore                ;process enemy objects
    LD L, <FloateyNum_Control
    LD A, (HL)                              ;load control for floatey number
    OR A
    CALL NZ, FloateyNumbersRoutine          ;process floatey numbers
    INC H
    LD A, $C0 + OBJ_SLOT6+1
    CP A, H                                 ;do these two subroutines until the whole buffer is done
    JP NZ, ProcELoop
;
    LD H, $C0 + OBJ_PLAYER  ; 92
    CALL GetPlayerOffscreenBits             ;get offscreen bits for player object
    CALL RelativePlayerPosition             ;get relative coordinates for player object
    LD A, (HidePlayerFlag)
    OR A
    CALL Z, PlayerGfxHandler                ;draw the player if he isn't hidden by end-of-level castle
    CALL BlockObjMT_Updater                 ;replace block objects with metatiles if necessary
;
    LD H, $C0 + OBJ_BLOCK2                  ;set offset for second block object
    LD (ObjectOffset), HL
    CALL BlockObjectsCore                   ;process second block object
    DEC H                                   ;set offset for first and process
    LD (ObjectOffset), HL
    CALL BlockObjectsCore
;
    CALL MiscObjectsCore
    ;CALL ProcessCannons
    ;CALL ProcessWhirlpools
    CALL FlagpoleRoutine
    CALL RunGameTimer
    CALL ColorRotation
;
    LD A, (Player_Y_HighPos)
    CP A, $02
    JP P, NoChgMus
    LD A, (StarInvincibleTimer)
    OR A
    JP Z, ClrPlrPal
    CP A, $04
    JP NZ, NoChgMus
    LD A, (IntervalTimerControl)
    OR A
    CALL Z, GetAreaMusic
NoChgMus:
    LD A, (StarInvincibleTimer)
    CP A, $08
    LD A, (FrameCounter)
    JP NC, CycleTwo
    SRL A
    SRL A
CycleTwo:
    SRL A
    CALL CyclePlayerPalette
    JP SaveAB
ClrPlrPal:
    CALL GetPlayerColors ;CALL ResetPalStar
;
SaveAB:
    LD A, (A_B_Buttons)
    LD (PreviousA_B_Buttons), A
    XOR A
    LD (Left_Right_Buttons), A
;
UpdScrollVar:
    LD A, (VRAM_Buffer_AddrCtrl)
    CP A, VRAMTBL_BUFFER2
    RET Z
    LD A, (AreaParserTaskNum)
    OR A
    JP NZ, AreaParserTaskHandler
    LD HL, ScrollThirtyTwo
    LD A, (HL)
    CP A, $08   ;   $20, $08
    RET M
    SUB A, $08  ;   $20, $08
    LD (HL), A
    ;LD HL, VRAM_Buffer2
    ;LD (VRAM_Buffer2_Ptr), HL
RunParser:
    JP AreaParserTaskHandler


;-------------------------------------------------------------------------------------

.SECTION "Animated Background Tile Initializations" BANK BANK_SLOT2 SLOT 2 FREE
AnimatedBGTileInits:
@Coin:
    .dw $3D00 | VRAMWRITE       ; VRAM ADR
    .db $04 * $20               ; TILES PER FRAME IN BYTE COUNT
    .dw AnimiatedBGTiles@Coin   ; FRAME TABLE ADR
    .db $04, $08, $08           ; TOTAL SPRITE FRAMES, FRAMES PER TILE, FRAMES PER TILE RESET VALUE
@Grass:
    .dw $3D80 | VRAMWRITE
    .db $06 * $20
    .dw AnimiatedBGTiles@Grass
    .db $04, $10, $10
.ENDS

.SECTION "Animated Background Tile Tables" BANK BANK_SLOT2 SLOT 2 BITWINDOW 8
AnimiatedBGTiles:
@Coin:
    .dw CoinFrame0, CoinFrame1, CoinFrame2, CoinFrame1, $0000
@Grass:
    .dw GrassFrame0, GrassFrame1, GrassFrame2, GrassFrame1, $0000
.ENDS

;   AnimatedBGTileQueue
;   $00:        animate flag
;   $01-$02:    vdp address
;   $03:        number of tiles per frame
;   $04-$05:    current frame's tile address
;   $06:        total frame count
;   $07:        frame timer
;   $08:        frame timer reset value
ColorRotation:
;   SLOT 0
    ; DECREMENT TIMER AND BRANCH IF IT HASN'T EXPIRED
    LD HL, BGTileQueue0.Timer
    DEC (HL)
    JP NZ, @UpdateSlot1
    ; SET TIMER TO RESET VALUE
    INC L
    LD A, (HL)
    DEC L
    LD (HL), A
    ; SET UPDATE FLAG
    LD A, $01
    LD (BGTileQueue0.UpdateFlag), A
    ; MOVE TO NEXT FRAME IN LIST
    LD HL, (BGTileQueue0.TileAdr)           ; get address of current tile data
    INC L
    INC L
    INC L
    ; CHECK IF AT END OF THE LIST (HIGH BYTE == $00)
    LD A, (HL)                              ; high byte of next frame's tile address
    OR A
    JP NZ, +
    ; MOVE POINTER BACK TO BEGINNING OF LIST IF SO
    LD A, (BGTileQueue0.FrameCount)
    ADD A, A
    SUB A, L
    NEG
    LD L, A
+:
    DEC L
    LD (BGTileQueue0.TileAdr), HL
@UpdateSlot1:
;   SLOT 1
    LD HL, BGTileQueue1.Timer
    DEC (HL)
    RET NZ;JP NZ, @UpdateSlot1
    INC L
    LD A, (HL)
    DEC L
    LD (HL), A
    LD A, $01
    LD (BGTileQueue1.UpdateFlag), A
    ;
    LD HL, (BGTileQueue1.TileAdr)           ; get address of current tile data
    INC L
    INC L
    INC L
    LD A, (HL)                              ; high byte of next frame's tile address
    OR A
    JP NZ, +
    LD A, (BGTileQueue1.FrameCount)
    ADD A, A
    SUB A, L
    NEG
    LD L, A
+:
    DEC L
    LD (BGTileQueue1.TileAdr), HL
    RET


;-------------------------------------------------------------------------------------
;   $00 (IXL)

ScrollHandler:
    LD HL, Player_X_Scroll
    LD A, (Platform_X_Scroll)               ;load value saved here
    ADD A, (HL)                             ;add value used by left/right platforms
    LD (HL), A                              ;save as new value here to impose force on scroll
;
    LD A, (ScrollLock)                      ;check scroll lock flag
    OR A
    JP NZ, InitScrlAmt                      ;skip a bunch of code here if set
;
    LD A, (Player_Pos_ForScroll)
    CP A, $50                               ;check player's horizontal screen position
    JP C, InitScrlAmt                       ;if less than 80 pixels to the right, branch
;
    LD A, (SideCollisionTimer)              ;if timer related to player's side collision
    OR A
    JP NZ, InitScrlAmt                      ;not expired, branch
;
    LD A, (HL)                              ;get value and decrement by one (Player_X_Scroll)
    DEC A                                   ;if value originally set to zero or otherwise
    JP M, InitScrlAmt                       ;negative for left movement, branch
    INC A
    CP A, $02                               ;if value $01, branch and do not decrement
    JP C, ChkNearMid
    DEC A                                   ;otherwise decrement by one
;
ChkNearMid:
    LD C, A
    LD A, (Player_Pos_ForScroll)
    CP A, $70                               ;check player's horizontal screen position
    JP C, ScrollScreen                      ;if less than 112 pixels to the right, branch
    LD C, (HL)                              ;otherwise get original value undecremented

ScrollScreen:
    LD A, C
    LD (ScrollAmount), A                    ;save value here
;
    LD HL, ScrollThirtyTwo
    ADD A, (HL)                             ;add to value already set here
    LD (HL), A                              ;save as new value here
;
    LD A, C
    LD HL, ScreenLeft_X_Pos
    ADD A, (HL)                             ;add to left side coordinate
    LD (HL), A                              ;save as new left side coordinate
;
    LD (HorizontalScroll), A                ;save here also
;
    LD A, (ScreenLeft_PageLoc)
    ADC A, $00                              ;add carry to page location for left
    LD (ScreenLeft_PageLoc), A              ;side of the screen
    ;AND A, $01
    ;LD IXL, A
    ;LD A, (Mirror_PPU_CTRL_REG1)
    ;AND A, %11111110
    ;OR A, IXL
    ;LD (Mirror_PPU_CTRL_REG1), A
    CALL GetScreenPosition                  ;figure out where the right side is
    JP ChkPOffscr                           ;skip this part
InitScrlAmt:
    XOR A
    LD (ScrollAmount), A                    ;initialize value here
ChkPOffscr:
    LD H, $C0 + OBJ_PLAYER                  ;set X for player offset
    CALL GetXOffscreenBits                  ;get horizontal offscreen bits for player
    OR A
    LD HL, X_SubtracterData
    LD DE, ScreenEdge_X_Pos                 ;load default offset (left side)
    JP M, KeepOnscr                         ;if d7 of offscreen bits are set, branch with default offset
;
    INC L
    INC E                                   ;otherwise use different offset (right side)
    AND A, %00100000                        ;check offscreen bits for d5 set
    JP Z, InitPlatScrl                      ;if not set, branch ahead of this part
KeepOnscr:
    LD A, (DE)                              ;get left or right side coordinate based on offset
    SUB A, (HL)                             ;subtract amount based on offset
    LD (Player_X_Position), A               ;store as player position to prevent movement further
    DEC E
    DEC E                                   ;(SMS)ScreenEdge_PageLoc,y
    LD A, (DE)                              ;get left or right page location based on offset
    SBC A, $00                              ;subtract borrow
    LD (Player_PageLoc), A                  ;save as player's page location
    INC L
    INC L                                   ;(SMS)OffscrJoypadBitsData,y
    LD A, (Left_Right_Buttons)              ;check saved controller bits
    CP A, (HL)                              ;against bits based on offset
    JP Z, InitPlatScrl                      ;if not equal, branch
;
    XOR A
    LD (Player_X_Speed), A                  ;otherwise nullify horizontal speed of player
InitPlatScrl:
    XOR A                                   ;nullify platform force imposed on scroll
    LD (Platform_X_Scroll), A
    RET

.SECTION "X_SubtracterData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
X_SubtracterData:
    .db $00, $10

OffscrJoypadBitsData:
    .db $01, $02
.ENDS

;-------------------------------------------------------------------------------------

GetScreenPosition:
    LD A, (ScreenLeft_X_Pos)        ;get coordinate of screen's left boundary
    ADD A, $FF                      ;add 255 pixels
    LD (ScreenRight_X_Pos), A       ;store as coordinate of screen's right boundary
    LD A, (ScreenLeft_PageLoc)      ;get page number where left boundary is
    ADC A, $00                      ;add carry from before
    LD (ScreenRight_PageLoc), A     ;store as page number where right boundary is
    RET

;-------------------------------------------------------------------------------------
;$00 (IXL) - used to store downward movement force in FireballObjCore
;$01
;$02 (IYL) - used to store maximum vertical speed in FireballObjCore
;$07 (IYL) - used to store pseudorandom bit in BubbleCheck

ProcFireball_Bubble:
    LD A, (PlayerStatus)            ;check player's status
    CP A, $02
    JP C, ProcAirBubbles            ;if not fiery, branch
;
    LD A, (A_B_Buttons)
    AND A, bitValue(SMS_BTN_1)      ;check for b button pressed
    JP Z, ProcFireballs             ;branch if not pressed
;
    LD HL, PreviousA_B_Buttons
    AND A, (HL)
    JP NZ, ProcFireballs            ;if button pressed in previous frame, branch
;
    LD A, (FireballCounter)         ;load fireball counter
    AND A, %00000001                ;get LSB and use as offset for buffer
    LD HL, Fireball_State
    ADD A, H
    LD H, A
    LD A, (HL)                      ;load fireball state
    OR A
    JP NZ, ProcFireballs            ;if not inactive, branch
;
    LD A, (Player_Y_HighPos)        ;if player too high or too low, branch
    DEC A
    JP NZ, ProcFireballs
;
    LD A, (CrouchingFlag)           ;if player crouching, branch
    OR A
    JP NZ, ProcFireballs
;
    LD A, (Player_State)            ;if player's state = climbing, branch
    CP A, $03
    JP Z, ProcFireballs
;
    LD A, SNDID_FIREBALL            ;play fireball sound effect
    LD (SFXTrack0.SoundQueue), A
    LD (HL), $02                    ;load state
    LD A, (PlayerAnimTimerSet)      ;copy animation frame timer setting
    LD (FireballThrowingTimer), A   ;into fireball throwing timer
    DEC A
    LD (PlayerAnimTimer), A         ;decrement and store in player's animation timer
    LD HL, FireballCounter          ;increment fireball counter
    INC (HL)

ProcFireballs:
    LD H, $C0 + OBJ_FIRE1           ; B = 0
    CALL FireballObjCore            ;process first fireball object
    INC H                           ; B = 1
    CALL FireballObjCore            ;process second fireball object, then do air bubbles

ProcAirBubbles:
    LD A, (AreaType)                ;if not water type level, skip the rest of this
    OR A
    RET NZ

    LD B, $03                       ;otherwise load counter and use as offset
    LD H, $C0 + OBJ_BUBB3
BublLoop:
    LD (ObjectOffset), HL
    CALL BubbleCheck                ;check timers and coordinates, create air bubble
    CALL RelativeBubblePosition     ;get relative coordinates
    CALL GetBubbleOffscreenBits     ;get offscreen information
    CALL DrawBubble                 ;draw the air bubble                
    DJNZ BublLoop                   ;do this until all three are handled
    RET

.SECTION "FireballXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FireballXSpdData:
    .db $40, $c0
.ENDS
    
;   X is either 0 or 1
FireballObjCore:
    LD (ObjectOffset), HL
    LD L, <Fireball_State
    LD A, (HL)                      
    OR A
    JP M, FireballExplosion         ;if d7 = 1, branch to get relative coordinates and draw explosion
    RET Z                           ;if fireball inactive, branch to leave
    DEC A                           ;if fireball state set to 1, skip this part and just run it
    JP Z, RunFB
;
    LD A, (Player_X_Position)       ;get player's horizontal position
    ADD A, $04                      ;add four pixels and store as fireball's horizontal position
    LD L, <Fireball_X_Position
    LD (HL), A
;
    LD A, (Player_PageLoc)          ;get player's page location
    ADC A, $00                      ;add carry and store as fireball's page location
    LD L, <Fireball_PageLoc
    LD (HL), A
;
    LD A, (Player_Y_Position)       ;get player's vertical position and store
    LD L, <Fireball_Y_Position
    LD (HL), A
;
    LD L, <Fireball_Y_HighPos
    LD (HL), $01                    ;set high byte of vertical position
;
    LD A, (PlayerFacingDir)         ;get player's facing direction
    DEC A
    LD DE, FireballXSpdData
    addAToDE8_M
    LD A, (DE)                      ;set horizontal speed of fireball accordingly
    LD L, <Fireball_X_Speed
    LD (HL), A
;
    LD L, <Fireball_Y_Speed
    LD (HL), $04                    ;set vertical speed of fireball
;
    LD L, <Fireball_BoundBoxCtrl
    LD (HL), $07                    ;set bounding box size control for fireball
;
    LD L, <Fireball_State
    DEC (HL)                        ;decrement state to 1 to skip this part from now on
RunFB:
    LD IXL, $50                     ;set downward movement force here
    LD IYL, $03                     ;set maximum speed here
    XOR A
    CALL ImposeGravity              ;do sub here to impose gravity on fireball and move vertically
    CALL MoveObjectHorizontally     ;do another sub to move it horizontally
;
    ;LD HL, (ObjectOffset)
    CALL RelativeFireballPosition   ;get relative coordinates
    CALL GetFireballOffscreenBits   ;get offscreen information
    CALL GetFireballBoundBox        ;get bounding box coordinates
    CALL FireballBGCollision        ;do fireball to background collision detection
    LD A, (Fireball_OffscrBits)     ;get fireball offscreen bits
    AND A, %11001100                ;mask out certain bits
    JP NZ, EraseFB                  ;if any bits still set, branch to kill fireball
    CALL FireballEnemyCollision     ;do fireball to enemy collision detection and deal with collisions
    JP DrawFireball                 ;draw fireball appropriately and leave
EraseFB:
    LD L, <Fireball_State
    LD (HL), $00                    ;erase fireball state
    RET

FireballExplosion:
    CALL RelativeFireballPosition
    JP DrawExplosion_Fireball

BubbleCheck:
    LD A, B
    LD DE, PseudoRandomBitReg
    addAToDE8_M
    LD A, (DE)                      ;get part of LSFR
    AND A, $01
    LD IYL, A                       ;store pseudorandom bit here
;
    LD L, <Bubble_Y_Position
    LD A, (HL)                      ;get vertical coordinate for air bubble
    CP A, YPOS_OFFSCREEN            ;if offscreen coordinate not set,
    JP NZ, MoveBubl                 ;branch to move air bubble
;
    LD A, (AirBubbleTimer)          ;if air bubble timer not expired,
    OR A
    RET NZ                          ;branch to leave, otherwise create new air bubble
SetupBubble:
    LD C, $00                       ;load default value here
    LD A, (PlayerFacingDir)         ;get player's facing direction
    RRA                             ;move d0 to carry
    JP NC, PosBubl                  ;branch to use default value if facing left
    LD C, $09 ;$08                       ;otherwise load alternate value here (+1 due to carry being set and 6502 code using 'adc' with 'clc' beforehand)
PosBubl:
    LD A, (Player_X_Position)
    ADD A, C                        ;add to player's horizontal position
    LD L, <Bubble_X_Position
    LD (HL), A                      ;save as horizontal position for airbubble
;
    LD A, (Player_PageLoc)
    ADC A, $00                      ;add carry to player's page location
    LD L, <Bubble_PageLoc
    LD (HL), A                      ;save as page location for airbubble
;
    LD A, (Player_Y_Position)
    ADD A, $08                      ;add eight pixels to player's vertical position
    LD L, <Bubble_Y_Position
    LD (HL), A                      ;save as vertical position for air bubble
;
    LD L, <Bubble_Y_HighPos
    LD (HL), $01                    ;set vertical high byte for air bubble
;
    LD A, IYL                       ;get pseudorandom bit, use as offset
    LD DE, BubbleTimerData
    addAToDE8_M
    LD A, (DE)                      ;get data for air bubble timer
    LD (AirBubbleTimer), A          ;set air bubble timer
MoveBubl:
    LD A, IYL                       ;get pseudorandom bit again, use as offset
    LD DE, Bubble_MForceData
    addAToDE8_M
    LD L, <Bubble_YMF_Dummy
    LD A, (HL)
    EX DE, HL
    SUB A, (HL)                     ;subtract pseudorandom amount from dummy variable
    EX DE, HL
    LD (HL), A                      ;save dummy variable
;
    LD L, <Bubble_Y_Position
    LD A, (HL)
    SBC A, $00                      ;subtract borrow from airbubble's vertical coordinate
    CP A, $08   ; $20               ;if below the status bar,
    JP NC, Y_Bubl                   ;branch to go ahead and use to move air bubble upwards
    LD A, YPOS_OFFSCREEN            ;otherwise set offscreen coordinate
Y_Bubl:
    LD (HL), A                      ;store as new vertical coordinate for air bubble
    RET

.SECTION "Bubble_MForceData & BubbleTimerData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
Bubble_MForceData:
    .db $ff, $50

BubbleTimerData:
    .db $40, $20
.ENDS

;-------------------------------------------------------------------------------------

EnemiesAndLoopsCore:
    LD L, <Enemy_Flag
    LD A, (HL)                      ;check data here for MSB set
    OR A
    JP M, ChkBowserF                ;if MSB set in enemy flag, branch ahead of jumps
    JP NZ, RunEnemyObjectsCore      ;if data isn't zero, jump to run enemy subroutines
ChkAreaTsk:
    ;LD A, (AreaParserTaskNum)       ;check number of tasks to perform
    ; AND A, $07
    ; CP A, $07
    ; JP NZ, ProcLoopCommand
    ;CP A, $02                       ;if at a specific task, jump and leave
    ;JP NZ, ProcLoopCommand          ;otherwise, jump to process loop command/load enemies
    ;LD A, (ColumnSide)
    ;OR A
    ;JP NZ, ProcLoopCommand
    ;RET
    JP ProcLoopCommand
ChkBowserF:
    AND A, %00001111                ;mask out high nybble
    LD D, H
    LD E, <Enemy_Flag
    LD A, (DE)                      ;use as pointer and load same place with different offset
    OR A
    RET NZ
    LD (HL), A                      ;if second enemy flag not set, also clear first one
    RET


;--------------------------------

.SECTION "Loop Command Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
LoopCmdWorldNumber:
    .db $03, $03, $06, $06, $06, $06, $06, $06, $07, $07, $07

LoopCmdPageNumber:
    .db $05, $09, $04, $05, $06, $08, $09, $0a, $06, $0b, $10

LoopCmdYPosition:
    ;.db $40, $b0, $b0, $80, $40, $40, $80, $40, $f0, $f0, $f0
    .db $28, $98, $98, $68, $28, $28, $68, $28, $D8, $D8, $D8

AreaDataOfsLoopback:
    .db $12, $36, $0e, $0e, $0e, $32, $32, $32, $0a, $26, $40
.ENDS

ExecGameLoopback:
    LD A, (Player_PageLoc)          ;send player back four pages
    SUB A, $04
    LD (Player_PageLoc), A
;
    LD A, (CurrentPageLoc)          ;send current page back four pages
    SUB A, $04
    LD (CurrentPageLoc), A
;
    LD A, (ScreenLeft_PageLoc)      ;subtract four from page location
    SUB A, $04                      ;of screen's left border
    LD (ScreenLeft_PageLoc), A
;
    LD A, (ScreenRight_PageLoc)     ;do the same for the page location
    SUB A, $04                      ;of screen's right border
    LD (ScreenRight_PageLoc), A
;
    LD A, (AreaObjectPageLoc)       ;subtract four from page control
    SUB A, $04                      ;for area objects
    LD (AreaObjectPageLoc), A
;
    XOR A                           ;initialize page select for both
    LD (EnemyObjectPageSel), A      ;area and enemy objects
    LD (AreaObjectPageSel), A
    LD (EnemyDataOffset), A         ;initialize enemy object data offset
    LD (EnemyObjectPageLoc), A      ;and enemy object page control
;
    LD A, $0B
    addAToDE8_M
    LD A, (DE)                      ;adjust area object offset based on
    LD (AreaDataOffset), A          ;which loop command we encountered
    RET

ProcLoopCommand:
    LD A, (LoopCommand)             ;check if loop command was found
    OR A
    JP Z, ChkEnemyFrenzy
;
    LD A, (CurrentColumnPos)        ;check to see if we're still on the first page
    OR A
    JP NZ, ChkEnemyFrenzy           ;if not, do not loop yet
;
    LD DE, LoopCmdPageNumber + $0B  ;start at the end of each set of loop data
    EX DE, HL
    LD B, $0C
FindLoop:
    DEC L
    DJNZ ChkEnemyFrenzy_EX          ;if all data is checked and not match, do not loop
    LD A, $F5
    addAToHL8_M                     ;LoopCmdWorldNumber
    LD A, (WorldNumber)             ;check to see if one of the world numbers
    CP A, (HL)                      ;matches our current world number
    JP NZ, FindLoop
    LD A, $0B
    addAToHL8_M                     ;LoopCmdPageNumber
    LD A, (CurrentPageLoc)          ;check to see if one of the page numbers
    CP A, (HL)                      ;matches the page we're currently on
    JP NZ, FindLoop
;
    LD A, $0B
    addAToHL8_M                     ;LoopCmdYPosition
    LD A, (Player_Y_Position)       ;check to see if the player is at the correct position
    CP A, (HL)                      ;if not, branch to check for world 7
    JP NZ, WrongChk
;
    LD A, (Player_State)            ;check to see if the player is
    OR A                            ;on solid ground (i.e. not jumping or falling)
    JP NZ, WrongChk                 ;if not, player fails to pass loop, and loopback
;
    EX DE, HL
    LD A, (WorldNumber)             ;are we in world 7? (check performed on correct
    CP A, WORLD7                    ;vertical position and on solid ground)
    JP NZ, InitMLp                  ;if not, initialize flags used there, otherwise
;
    LD A, (MultiLoopCorrectCntr)    ;increment counter for correct progression
    INC A
    LD (MultiLoopCorrectCntr), A
IncMLoop:
    LD A, (MultiLoopPassCntr)       ;increment master multi-part counter
    INC A
    LD (MultiLoopPassCntr), A
    CP A, $03                       ;have we done all three parts?
    JP NZ, InitLCmd                 ;if not, skip this part
    LD A, (MultiLoopCorrectCntr)    ;if so, have we done them all correctly?
    CP A, $03
    JP Z, InitMLp                   ;if so, branch past unnecessary check here
    JP DoLpBack                     ;unconditional branch if previous branch fails
;
WrongChk:
    EX DE, HL
    LD A, (WorldNumber)             ;are we in world 7? (check performed on
    CP A, WORLD7                    ;incorrect vertical position or not on solid ground)
    JP Z, IncMLoop
;
DoLpBack:
    CALL ExecGameLoopback           ;if player is not in right place, loop back
    CALL KillAllEnemies
InitMLp:
    XOR A                           ;initialize counters used for multi-part loop commands
    LD (MultiLoopPassCntr), A
    LD (MultiLoopCorrectCntr), A
InitLCmd:
    XOR A                           ;initialize loop command flag
    LD (LoopCommand), A
    JP ChkEnemyFrenzy

;--------------------------------

ChkEnemyFrenzy_EX:
    EX DE, HL
ChkEnemyFrenzy:
    LD A, (EnemyFrenzyQueue)        ;check for enemy object in frenzy queue
    OR A
    JP Z, ProcessEnemyData          ;if not, skip this part
;
    LD L, <Enemy_ID
    LD (HL), A                      ;store as enemy object identifier here
    LD L, <Enemy_Flag
    LD (HL), $01                    ;activate enemy object flag
    LD L, <Enemy_State
    LD (HL), $00                    ;initialize state and frenzy queue
    LD (EnemyFrenzyQueue), A
;
    JP InitEnemyObject              ;and then jump to deal with this enemy

;-------------------------------------------------------------------------------------

RunEnemyObjectsCore:
    LD HL, (ObjectOffset)           ;get offset for enemy object buffer
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $15                       ;if enemy object < $15, use default value
    LD A, $00                       ;load value 0 for jump engine by default
    JP C, JmpEO
    LD A, (HL)                      ;otherwise subtract $14 from the value and use
    SUB A, $14                      ;as value for jump engine
JmpEO:
    PUSH HL                         ;(SMS) save ObjectOffset
    RST JumpEngine

    .dw RunNormalEnemies  ;for objects $00-$14

    .dw RunBowserFlame    ;for objects $15-$1f
    .dw RunFireworks
    .dw NoRunCode
    .dw NoRunCode
    .dw NoRunCode
    .dw NoRunCode
    .dw RunFirebarObj
    .dw RunFirebarObj
    .dw RunFirebarObj
    .dw RunFirebarObj
    .dw RunFirebarObj

    .dw RunFirebarObj     ;for objects $20-$2f
    .dw RunFirebarObj
    .dw RunFirebarObj
    .dw NoRunCode
    .dw RunLargePlatform
    .dw RunLargePlatform
    .dw RunLargePlatform
    .dw RunLargePlatform
    .dw RunLargePlatform
    .dw RunLargePlatform
    .dw RunLargePlatform
    .dw RunSmallPlatform
    .dw RunSmallPlatform
    .dw RunBowser
    .dw PowerUpObjHandler
    .dw VineObjectHandler

    .dw NoRunCode         ;for objects $30-$35
    .dw RunStarFlagObj
    .dw JumpspringHandler
    .dw NoRunCode
    .dw WarpZoneObject
    .dw RunRetainerObj

;-------------------------------------------------------------------------------------

WarpZoneObject:
    POP HL
;
    LD A, (ScrollLock)
    OR A
    RET Z
;
    LD A, (Player_Y_Position)
    LD C, A
    LD A, (Player_Y_HighPos)
    AND A, C
    RET NZ
;
    LD (ScrollLock), A
    LD A, (WarpZoneControl)
    INC A
    LD (WarpZoneControl), A
    JP EraseEnemyObject


;--------------------------------

PowerUpObjHandler:
    POP HL
;
    LD H, $C0 + OBJ_SLOT6
    LD (ObjectOffset), HL
;
    LD A, (Enemy_State + $05 * $100)
    OR A
    RET Z
;
    JP P, GrowThePowerUp
;
    LD A, (TimerControl)
    OR A
    JP NZ, RunPUSubs
;
    LD A, (PowerUpType)
    OR A
    JP Z, ShroomM
;
    CP A, $03
    JP Z, ShroomM
;
    CP A, $02
    JP NZ, RunPUSubs
;
    CALL MoveJumpingEnemy_NOPOP
    CALL EnemyJump
    JP RunPUSubs
;
ShroomM:
    CALL MoveNormalEnemy_NOPOP
    CALL EnemyToBGCollisionDet
    JP RunPUSubs

GrowThePowerUp:
    LD A, (FrameCounter)
    AND A, $03
    JP NZ, ChkPUSte
;
    ;LD L, <Enemy_Y_Position
    ;DEC (HL)
    LD L, <Enemy_Y_Position
    LD A, (HL)
    SUB A, $01
    LD (HL), A
    LD L, <Enemy_Y_HighPos
    LD A, (HL)
    SBC A, $00
    LD (HL), A
;
    LD L, <Enemy_State
    LD A, (HL)
    INC (HL)
    CP A, $11
    JP C, ChkPUSte
;
    LD A, %10000000
    LD (HL), A
    ADD A, A
    ;LD (Enemy_SprAttrib + $05 * $100), A
    RLA
    LD L, <Enemy_MovingDir
    LD (HL), A
;
    LD L, <Enemy_X_Speed
    LD (HL), $10
;
ChkPUSte:
    LD A, (Enemy_State + $05 * $100)
    CP A, $06
    RET C
;
RunPUSubs:
    CALL RelativeEnemyPosition
    CALL GetEnemyOffscreenBits
    AND A, $0F
    LD (DE), A
    CALL GetEnemyBoundBox
    CALL DrawPowerUp
    CALL PlayerEnemyCollision
    JP OffscreenBoundsCheck

;--------------------------------

.SECTION "Jumpspring_Y_PosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
Jumpspring_Y_PosData:
    .db $08, $10, $08, $00
.ENDS

JumpspringHandler:
    POP HL
;
    CALL GetEnemyOffscreenBits
;
    LD A, (TimerControl)
    OR A
    JP NZ, DrawJSpr
;   
    LD A, (JumpspringAnimCtrl)
    OR A
    JP Z, DrawJSpr
;
    DEC A
    LD C, A
    AND A, %00000010
    LD A, (Player_Y_Position)
    JP NZ, DownJSpr
    ADD A, $02
    JP PosJSpr
DownJSpr:
    SUB A, $02
PosJSpr:
    LD (Player_Y_Position), A
;
    LD A, C
    LD DE, Jumpspring_Y_PosData
    addAToDE8_M
    LD A, (DE)
    LD L, <Jumpspring_FixedYPos
    ADD A, (HL)
    LD L, <Enemy_Y_Position
    LD (HL),A
;
    LD A, C
    CP A, $01
    JP C, BounceJS
    LD A, (A_B_Buttons)
    AND A, SMS_BTN_2
    JP Z, BounceJS
    LD E, A
    LD A, (PreviousA_B_Buttons)
    AND A, E
    JP NZ, BounceJS
    LD A, $F4
    LD (JumpspringForce), A
BounceJS:
    LD A, C
    CP A, $03
    JP NZ, DrawJSpr
    LD A, (JumpspringForce)
    LD (Player_Y_Speed), A
    XOR A
    LD (JumpspringAnimCtrl), A
DrawJSpr:
    CALL RelativeEnemyPosition
    CALL EnemyGfxHandler
    CALL OffscreenBoundsCheck
    LD A, (JumpspringAnimCtrl)
    OR A
    RET Z
    LD A, (JumpspringTimer)
    OR A
    RET NZ
    LD A, $04
    LD (JumpspringTimer), A
    LD A, (JumpspringAnimCtrl)
    INC A
    LD (JumpspringAnimCtrl), A
    RET


;--------------------------------
;$06-$07 - used as address to block buffer data
;$02(IXL) - used as vertical high nybble of block buffer offset

.SECTION "VineHeightData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
VineHeightData:
    .db $30, $60
.ENDS

VineObjectHandler:
    POP HL
;
    LD A, H
    CP A, $C6
    JP NZ, ExitVH
;
    LD A, (VineFlagOffset)
    DEC A
    LD BC, VineHeightData
    addAToBC8_M
    LD A, (BC)
    LD C, A
    LD A, (VineHeight)
    CP A, C
    JP Z, RunVSubs
;
    LD A, (FrameCounter)
    RRCA
    RRCA
    JP NC, RunVSubs
;
    LD A, (Enemy_Y_Position + $05 * $100)
    SUB A, $01
    LD (Enemy_Y_Position + $05 * $100), A
    LD A, (VineHeight)
    INC A
    LD (VineHeight), A
;
RunVSubs:
    LD A, (VineHeight)
    CP A, $08
    JP C, ExitVH
    CALL RelativeEnemyPosition
    CALL GetEnemyOffscreenBits
    LD C, $00
VDrawLoop:
    CALL DrawVine
    INC C
    LD A, (VineFlagOffset)
    CP A, C
    JP NZ, VDrawLoop
;
    LD A, (Enemy_OffscrBits)
    AND A, %00001100
    JP Z, WrCMTile
    DEC C
KillVine:
    LD A, C
    ADD A, $C1
    LD D, A
    LD E, <VineObjOffset
    LD A, (DE)
    ADD A, $C1
    LD H, A
    PUSH BC
    CALL EraseEnemyObject
    POP BC
    DEC C
    JP P, KillVine
    LD (VineFlagOffset), A
    LD (VineHeight), A
WrCMTile:
    LD A, (VineHeight)
    CP A, $20
    JP C, ExitVH
    LD H, $C0 + OBJ_SLOT6
    LD A, $02
    LD C, $1B
    CALL BlockBufferCollision
    LD A, IXL
    CP A, $D0
    JP NC, ExitVH
    LD A, (DE)
    OR A
    JP NZ, ExitVH
    LD A, MT_VINEBLANK
    LD (DE), A
ExitVH:
    LD HL, (ObjectOffset)
    RET

;--------------------------------

NoRunCode:
    POP HL
;
    RET

;--------------------------------

RunRetainerObj:
    POP HL
RunRetainerObj_NOPOP:
    CALL GetEnemyOffscreenBits
    CALL RelativeEnemyPosition
    JP EnemyGfxHandler

;--------------------------------

RunNormalEnemies:
    POP HL
;
    ;lda #$00                  ;init sprite attributes
    ;sta Enemy_SprAttrib,x
    CALL GetEnemyOffscreenBits  ; 3,
    CALL RelativeEnemyPosition  ; 1, 
    CALL EnemyGfxHandler        ; 7, 
    CALL GetEnemyBoundBox       ; 1, 
    CALL EnemyToBGCollisionDet  ; 7,
    CALL EnemiesCollision       ; 0,
    CALL PlayerEnemyCollision   ; 1, 
;
    LD A, (TimerControl)
    OR A
    CALL Z, EnemyMovementSubs   ; 2, 3
;
    JP OffscreenBoundsCheck

EnemyMovementSubs:
    LD L, <Enemy_ID
    LD A, (HL)
    PUSH HL
    RST JumpEngine

    .dw MoveNormalEnemy      ;only objects $00-$14 use this table
    .dw MoveNormalEnemy
    .dw MoveNormalEnemy
    .dw MoveNormalEnemy
    .dw MoveNormalEnemy
    .dw ProcHammerBro
    .dw MoveNormalEnemy
    .dw MoveBloober
    .dw MoveBulletBill
    .dw NoMoveCode
    .dw MoveSwimmingCheepCheep
    .dw MoveSwimmingCheepCheep
    .dw MovePodoboo
    .dw MovePiranhaPlant
    .dw MoveJumpingEnemy
    .dw ProcMoveRedPTroopa
    .dw MoveFlyGreenPTroopa
    .dw MoveLakitu
    .dw MoveNormalEnemy
    .dw NoMoveCode   ;dummy
    .dw MoveFlyingCheepCheep

;--------------------------------

NoMoveCode:
    POP HL
    RET

;--------------------------------

RunBowserFlame:
    POP HL
    CALL ProcBowserFlame
    CALL GetEnemyOffscreenBits
    CALL RelativeEnemyPosition
    CALL GetEnemyBoundBox
    CALL PlayerEnemyCollision
    JP OffscreenBoundsCheck

;--------------------------------

RunFirebarObj:
    POP HL
    CALL ProcFirebar
    JP OffscreenBoundsCheck

;--------------------------------

RunSmallPlatform:
    POP HL
    CALL GetEnemyOffscreenBits
    CALL RelativeEnemyPosition
    CALL SmallPlatformBoundBox
    CALL SmallPlatformCollision
    CALL RelativeEnemyPosition
    CALL DrawSmallPlatform
    CALL MoveSmallPlatform
    JP OffscreenBoundsCheck

;--------------------------------

RunLargePlatform:
    POP HL
    CALL GetEnemyOffscreenBits
    CALL RelativeEnemyPosition
    CALL LargePlatformBoundBox
    CALL LargePlatformCollision
    LD A, (TimerControl)             ;if master timer control set,
    OR A
    CALL Z, LargePlatformSubroutines
    CALL RelativeEnemyPosition
    CALL DrawLargePlatform
    JP OffscreenBoundsCheck

;--------------------------------

LargePlatformSubroutines:
    POP HL
    PUSH HL
    LD L, <Enemy_ID
    LD A, (HL)
    SUB A, $24
    RST JumpEngine

    .dw BalancePlatform   ;table used by objects $24-$2a
    .dw YMovingPlatform
    .dw MoveLargeLiftPlat
    .dw MoveLargeLiftPlat
    .dw XMovingPlatform
    .dw DropPlatform
    .dw RightPlatform

;-------------------------------------------------------------------------------------

EraseEnemyObject:
    XOR A
    LD L, <Enemy_Flag
    LD (HL), A
    LD L, <Enemy_ID
    LD (HL), A
    LD L, <Enemy_State
    LD (HL), A
    LD L, <FloateyNum_Control
    LD (HL), A
    LD L, <ShellChainCounter
    LD (HL), A
    ;LD L, <Enemy_SprAttrib
    ;LD (HL), A
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    XOR A
    LD (BC), A
    LD A, <EnemyIntervalTimer - <EnemyFrameTimer
    addAToBC8_M
    XOR A
    LD (BC), A
    RET

;-------------------------------------------------------------------------------------

MovePodoboo:
    POP HL
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    JP NZ, MoveJ_EnemyVertically
;
    PUSH BC
    CALL InitPodoboo_NOPOP
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD A, (BC)
    OR A, %10000000
    LD L, <Enemy_Y_MoveForce
    LD (HL), A
;
    POP BC
    AND A, %00001111
    OR A, $06
    LD (BC), A
;
    LD L, <Enemy_Y_Speed
    LD (HL), $F9
;
    JP MoveJ_EnemyVertically

;--------------------------------
;$00 - used in HammerBroJumpCode as bitmask

;HammerThrowTmrData:
;    .db $30, $1c

.SECTION "XSpeedAdderData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
XSpeedAdderData:
    .db $00, $e8, $00, $18
.ENDS

.SECTION "RevivedXSpeed" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
RevivedXSpeed:
    .db $08, $f8, $0c, $f4
.ENDS

ProcHammerBro:
    POP HL
;
    LD L, <Enemy_State
    BIT 5, (HL)
    JP NZ, MoveDefeatedEnemy
;
    LD L, <HammerBroJumpTimer
    LD A, (HL)
    OR A
    JP Z, HammerBroJumpCode
;
    DEC (HL)
    LD A, (Enemy_OffscrBits)
    AND A, %00001100
    JP NZ, MoveHammerBroXDir
;
    LD L, <HammerThrowingTimer
    LD A, (HL)
    OR A
    JP NZ, DecHT
;
    LD A, (SecondaryHardMode)
    OR A
    LD A, $30
    JP Z, +
    LD A, $1C
+:
    LD (HL), A
;
    CALL SpawnHammerObj
    JP NC, DecHT
;
    LD L, <Enemy_State
    SET 3, (HL)
;
    JP MoveHammerBroXDir
;
DecHT:
    LD L, <HammerThrowingTimer
    DEC (HL)
    JP MoveHammerBroXDir

.SECTION "HammerBroJumpLData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
HammerBroJumpLData:
    .db $20, $37
.ENDS

HammerBroJumpCode:
    LD L, <Enemy_State
    LD A, (HL)
    AND A, %00000111
    CP A, $01
    JP Z, MoveHammerBroXDir
;
    XOR A
    LD (Temp_Bytes + $00), A
;
    LD C, $FA
    LD L, <Enemy_Y_Position
    LD A, (HL)
    CP A, $80 - SMS_PIXELYOFFSET
    JP NC, SetHJ
    LD C, $FD
    CP A, $70 - SMS_PIXELYOFFSET
    LD A, (Temp_Bytes + $00)
    INC A
    LD (Temp_Bytes + $00), A
    JP C, SetHJ
    DEC A
    LD (Temp_Bytes + $00), A
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD A, (BC)
    AND A, $01
    JP NZ, SetHJ
    LD C, $FA
SetHJ:
    LD L, <Enemy_Y_Speed
    LD (HL), C
;
    LD L, <Enemy_State
    SET 0, (HL)
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg+2
    addAToBC8_M
    PUSH BC
    LD A, (Temp_Bytes + $00)
    LD C, A
    LD A, (BC)
    AND A, C
    LD C, A
    LD A, (SecondaryHardMode)
    OR A
    JP NZ, HJump
    LD C, A
HJump:
    LD A, C
    LD BC, HammerBroJumpLData
    addAToBC8_M
    LD A, H
    SUB A, $C1
    LD DE, EnemyFrameTimer
    addAToDE8_M
    LD A, (BC)
    LD (DE), A
;
    POP BC
    DEC C
    LD A, (BC)
    OR A, %11000000
    LD L, <HammerBroJumpTimer
    LD (HL), A

MoveHammerBroXDir:
    LD C, $FC
    LD A, (FrameCounter)
    AND A, %01000000
    JP NZ, Shimmy
    LD C, $04
Shimmy:
    LD L, <Enemy_X_Speed
    LD (HL), C
;
    LD C, $01
    CALL PlayerEnemyDiff
    JP M, SetShim
    INC C
    LD A, H
    SUB A, $C1
    LD DE, EnemyIntervalTimer
    addAToDE8_M
    LD A, (DE)
    OR A
    JP NZ, SetShim
    LD L, <Enemy_X_Speed
    LD (HL), $F8
SetShim:
    LD L, <Enemy_MovingDir
    LD (HL), C

MoveNormalEnemy:
    POP HL
MoveNormalEnemy_NOPOP:
    LD C, $00
    LD L, <Enemy_State
    LD A, (HL)
    BIT 6, A
    JP NZ, FallE
;
    OR A
    JP M, SteadM
;
    BIT 5, A
    JP NZ, MoveDefeatedEnemy
;
    AND A, %00000111
    JP Z, SteadM
;
    CP A, $05
    JP Z, FallE
;
    CP A, $03
    JP NC, ReviveStunned
;
FallE:
    CALL MoveD_EnemyVertically
    LD C, $00
    LD L, <Enemy_State
    LD A, (HL)
    CP A, $02
    JP Z, MoveEnemyHorizontally
;
    AND A, %01000000
    JP Z, SteadM
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_PowerUpObject
    JP Z, SteadM

SlowM:
    LD C, $01
SteadM:
    LD L, <Enemy_X_Speed
    LD A, (HL)
    PUSH AF
    OR A
    JP P, AddHS
    INC C
    INC C
AddHS:
    LD A, C
    LD BC, XSpeedAdderData
    addAToBC8_M
    LD A, (BC)
    ADD A, (HL)
    LD (HL), A
;
    CALL MoveEnemyHorizontally
;
    POP AF
    LD L, <Enemy_X_Speed
    LD (HL), A
    RET

ReviveStunned:
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    JP NZ, ChkKillGoomba
;
    LD L, <Enemy_State
    LD (HL), A
;
    LD A, (FrameCounter)
    AND A, $01
    LD C, A
    INC C
    LD L, <Enemy_MovingDir
    LD (HL), C
;
    DEC C
    LD A, (PrimaryHardMode)
    OR A
    JP Z, SetRSpd
    INC C
    INC C
SetRSpd:
    LD A, C
    LD BC, RevivedXSpeed
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_X_Speed
    LD (HL), A
    RET

MoveDefeatedEnemy:
    CALL MoveD_EnemyVertically
    JP MoveEnemyHorizontally

ChkKillGoomba:
    CP A, $0E
    RET NZ
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Goomba
    RET NZ
;
    JP EraseEnemyObject

;--------------------------------

MoveJumpingEnemy:
    POP HL
MoveJumpingEnemy_NOPOP:
    CALL MoveJ_EnemyVertically
    JP MoveEnemyHorizontally

;--------------------------------

ProcMoveRedPTroopa:
    POP HL
;
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    LD L, <Enemy_Y_MoveForce
    OR A, (HL)
    JP NZ, MoveRedPTUpOrDown
;
    LD L, <Enemy_YMF_Dummy
    LD (HL), A
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD L, <RedPTroopaOrigXPos
    CP A, (HL)
    JP NC, MoveRedPTUpOrDown
;
    LD A, (FrameCounter)
    AND A, %00000111
    RET NZ
;
    LD L, <Enemy_Y_Position
    INC (HL)
    RET

MoveRedPTUpOrDown:
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD L, <RedPTroopaCenterYPos
    CP A, (HL)
    JP C, MoveRedPTroopaDown
    JP MoveRedPTroopaUp

;--------------------------------
;$00 - used to store adder for movement, also used as adder for platform
;$01 - used to store maximum value for secondary counter

MoveFlyGreenPTroopa:
    POP HL
;
    CALL XMoveCntr_GreenPTroopa
    CALL MoveWithXMCntrs
;
    LD C, $01
    LD A, (FrameCounter)
    AND A, %00000011
    RET NZ
;
    LD A, (FrameCounter)
    AND A, %01000000
    JP NZ, YSway
    LD C, $FF
YSway:
    LD A, C
    LD (Temp_Bytes + $00), A
    LD L, <Enemy_Y_Position
    LD A, (HL)
    ADD A, C
    LD (HL), A
    RET

XMoveCntr_GreenPTroopa:
    LD A, $13

XMoveCntr_Platform:
    LD (Temp_Bytes + $01), A
;
    LD A, (FrameCounter)
    AND A, %00000011
    RET NZ
;
    LD L, <XMoveSecondaryCounter
    LD C, (HL)
    LD L, <XMovePrimaryCounter
    LD A, (HL)
    SRL A
    JP C, DecSeXM
    LD A, C
    CP A, $01
    JP Z, IncPXM
    LD L, <XMoveSecondaryCounter
    INC (HL)
    RET
IncPXM:
    LD L, <XMovePrimaryCounter
    INC (HL)
    RET
DecSeXM:
    LD A, C
    OR A
    JP Z, IncPXM
    LD L, <XMoveSecondaryCounter
    DEC (HL)
    RET

MoveWithXMCntrs:
    LD L, <XMoveSecondaryCounter
    LD A, (HL)
    PUSH AF
;
    LD C, $01
    LD L, <XMovePrimaryCounter
    LD A, (HL)
    AND A, %00000010
    JP NZ, XMRight
;
    LD L, <XMoveSecondaryCounter
    LD A, (HL)
    NEG
    LD (HL), A
    LD C, $02
;
XMRight:
    LD L, <Enemy_MovingDir
    LD (HL), C
    CALL MoveEnemyHorizontally
    LD (Temp_Bytes + $00), A
    POP AF
    LD L, <XMoveSecondaryCounter
    LD (HL), A
    RET

;--------------------------------

.SECTION "BlooberBitmasks" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BlooberBitmasks:
    .db %00111111, %00000011
.ENDS

MoveBloober:
    POP HL
    RET

;--------------------------------

MoveBulletBill:
    POP HL
;
    LD L, <Enemy_State
    LD A, (HL)
    AND A, %00100000
    JP NZ, MoveJ_EnemyVertically
;
    LD L, <Enemy_X_Speed
    LD (HL), $E8
    JP MoveEnemyHorizontally

;--------------------------------
;$02 - used to hold preset values
;$03 - used to hold enemy state

.SECTION "SwimCCXMoveData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
SwimCCXMoveData:
    .db $40, $80
    ;.db $04, $04 ;residual data, not used
.ENDS

MoveSwimmingCheepCheep:
    POP HL
    RET

;--------------------------------
;$00 - used as counter for firebar parts
;$01 - used for oscillated high byte of spin state or to hold horizontal adder
;$02 - used for oscillated high byte of spin state or to hold vertical adder
;$03 - used for mirror data
;$04 - used to store player's sprite 1 X coordinate
;$05 - used to evaluate mirror data
;$06 - used to store either screen X coordinate or sprite data offset
;$07 - used to store screen Y coordinate
;$ed - used to hold maximum length of firebar
;$ef - used to hold high byte of spinstate

;horizontal adder is at first byte + high byte of spinstate,
;vertical adder is same + 8 bytes, two's compliment
;if greater than $08 for proper oscillation

.SECTION "FirebarPosLookupTbl" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FirebarPosLookupTbl:
    .db $00, $01, $03, $04, $05, $06, $07, $07, $08
    .db $00, $03, $06, $09, $0b, $0d, $0e, $0f, $10
    .db $00, $04, $09, $0d, $10, $13, $16, $17, $18
    .db $00, $06, $0c, $12, $16, $1a, $1d, $1f, $20
    .db $00, $07, $0f, $16, $1c, $21, $25, $27, $28
    .db $00, $09, $12, $1b, $21, $27, $2c, $2f, $30
    .db $00, $0b, $15, $1f, $27, $2e, $33, $37, $38
    .db $00, $0c, $18, $24, $2d, $35, $3b, $3e, $40
    .db $00, $0e, $1b, $28, $32, $3b, $42, $46, $48
    .db $00, $0f, $1f, $2d, $38, $42, $4a, $4e, $50
    .db $00, $11, $22, $31, $3e, $49, $51, $56, $58

FirebarMirrorData:
    .db $01, $03, $02, $00

FirebarTblOffsets:
    .db $00, $09, $12, $1b, $24, $2d
    .db $36, $3f, $48, $51, $5a, $63

FirebarYPos:
    .db $0c, $18
.ENDS

ProcFirebar:
    RET

;--------------------------------

.SECTION "PRandomSubtracter" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PRandomSubtracter:
    .db $f8, $a0, $70, $bd, $00
.ENDS

.SECTION "FlyCCBPriority" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FlyCCBPriority:
    .db $20, $20, $20, $00, $00
.ENDS

MoveFlyingCheepCheep:
    POP HL
    RET

;--------------------------------
;$00 - used to hold horizontal difference
;$01-$03 - used to hold difference adjusters

;LakituDiffAdj:
;    .db $15, $30, $40

MoveLakitu:
    POP HL
;
    LD L, <Enemy_State
    LD A, (HL)
    BIT 5, A
    JP NZ, MoveD_EnemyVertically
;
    OR A
    JP Z, Fr12S
;
    XOR A
    LD L, <LakituMoveDirection
    LD (HL), A
    LD (EnemyFrenzyBuffer), A
    LD A, $10
    JP SetLSpd
;
Fr12S:
    LD A, OBJECTID_Spiny
    LD (EnemyFrenzyBuffer), A
;
    LD A, $40
    LD (Temp_Bytes + $03), A
    LD A, $30
    LD (Temp_Bytes + $02), A 
    LD A, $15
    LD (Temp_Bytes + $01), A
;
    CALL PlayerLakituDiff
;
SetLSpd:
    LD L, <LakituMoveSpeed
    LD (HL), A
    LD C, $01
    LD L, <LakituMoveDirection
    LD A, (HL)
    AND A, $01
    JP NZ, SetLMov
    LD L, <LakituMoveSpeed
    LD A, (HL)
    NEG
    LD (HL), A
    INC C
SetLMov:
    LD L, <Enemy_MovingDir
    LD (HL), C
    JP MoveEnemyHorizontally

PlayerLakituDiff:
    LD C, $00
    CALL PlayerEnemyDiff
    JP P, ChkLakDif
    INC C
    LD A, (Temp_Bytes + $00)
    NEG
    LD (Temp_Bytes + $00), A
ChkLakDif:
    LD A, (Temp_Bytes + $00)
    CP A, $3C
    JP C, ChkPSpeed
    LD A, $3C
    LD (Temp_Bytes + $00), A
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Lakitu
    JP NZ, ChkPSpeed
    LD A, C
    LD L, <LakituMoveDirection
    CP A, (HL)
    JP Z, ChkPSpeed
    LD A, (HL)
    OR A
    JP Z, SetLMovD
    LD L, <LakituMoveSpeed
    DEC (HL)
    LD A, (HL)
    OR A
    RET NZ
SetLMovD:
    LD A, C
    LD L, <LakituMoveDirection
    LD (HL), A
ChkPSpeed:
    LD A, (Temp_Bytes + $00)
    AND A, %00111100
    SRL A
    SRL A
    LD (Temp_Bytes + $00), A
;
    LD C, $00
    LD A, (Player_X_Speed)
    OR A
    JP Z, SubDifAdj
    LD A, (ScrollAmount)
    OR A
    JP Z, SubDifAdj
    INC C
    LD A, (Player_X_Speed)
    CP A, $19
    JP C, ChkSpinyO
    LD A, (ScrollAmount)
    CP A, $02
    JP C, ChkSpinyO
    INC C
ChkSpinyO:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Spiny
    JP NZ, ChkEmySpd
    LD A, (Player_X_Speed)
    OR A
    JP NZ, SubDifAdj
ChkEmySpd:
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    OR A
    JP NZ, SubDifAdj
    LD C, $00
SubDifAdj:
    LD A, C
    LD BC, Temp_Bytes + $01
    addAToBC8_M
    LD A, (Temp_Bytes + $00)
    LD B, A
    INC B
    LD A, (BC)
SPixelLak:
    DEC A
    DJNZ SPixelLak
    RET

;-------------------------------------------------------------------------------------
;$04-$05 - used to store name table address in little endian order

.SECTION "BridgeCollapseData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BridgeCollapseData:
    .db $1a ;axe
    .db $58 ;chain
    .db $98, $96, $94, $92, $90, $8e, $8c ;bridge
    .db $8a, $88, $86, $84, $82, $80
.ENDS

BridgeCollapse:
    POP HL
;
    RET

;--------------------------------

.SECTION "PRandomRange" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PRandomRange:
    .db $21, $41, $11, $31
.ENDS

RunBowser:
    POP HL
;
    RET

KillAllEnemies:
    LD H, $C0 + OBJ_SLOT5
KillLoop:
    CALL EraseEnemyObject
    DEC H
    LD A, H
    CP A, $C0
    JP NZ, KillLoop
    XOR A
    LD (EnemyFrenzyBuffer), A
    LD HL, (ObjectOffset)
    RET


;-------------------------------------------------------------------------------------
;$00 - used to hold movement force and tile number
;$01 - used to hold sprite attribute data

.SECTION "FlameTimerData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FlameTimerData:
    .db $bf, $40, $bf, $bf, $bf, $40, $40, $bf
.ENDS

SetFlameTimer:
    LD A, (BowserFlameTimerCtrl)
    LD C, A
    INC A
    AND A, %00000111
    LD (BowserFlameTimerCtrl), A
    LD A, C
    LD BC, FlameTimerData
    addAToBC8_M
    LD A, (BC)
    RET

ProcBowserFlame:
    RET

;--------------------------------

RunFireworks:
    POP HL
;
    LD L, <ExplosionTimerCounter
    DEC (HL)
    JP NZ, SetupExpl
;
    LD (HL), $08
    LD L, <ExplosionGfxCounter
    INC (HL)
    LD A, (HL)
    CP A, $03
    JP NC, FireworksSoundScore
;
SetupExpl:
    CALL RelativeEnemyPosition
;
    LD A, (Enemy_Rel_YPos)
    LD (Fireball_Rel_YPos), A
    LD A, (Enemy_Rel_XPos)
    LD (Fireball_Rel_XPos), A
;

    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    LD L, <ExplosionGfxCounter
    LD A, (HL)
    JP DrawExplosion_Fireworks

FireworksSoundScore:
    LD L, <Enemy_Flag
    LD (HL), $00
    LD A, SNDID_CANNON
    LD (SFXTrack1.SoundQueue), A
    LD A, $05
    LD (DigitModifier + $04 * $100), A
    JP EndAreaPoints

;--------------------------------

;StarFlagYPosAdder:
;    .db $00, $00, $08, $08

;StarFlagXPosAdder:
;    .db $00, $08, $00, $08

;StarFlagTileData:
;    .db $54, $55, $56, $57

RunStarFlagObj:
    POP HL
;
    XOR A
    LD (EnemyFrenzyBuffer), A
;
    LD A, (StarFlagTaskControl)
    CP A, $05
    RET NC
;
    PUSH HL
    RST JumpEngine

    .dw StarFlagExit
    .dw GameTimerFireworks
    .dw AwardGameTimerPoints
    .dw RaiseFlagSetoffFWorks
    .dw DelayToAreaEnd

GameTimerFireworks:
    POP HL
;
    LD C, $05
    LD A, (GameTimerDisplay+2)
    CP A, $01
    JP Z, SetFWC
    LD C, $03
    CP A, $03
    JP Z, SetFWC
    LD C, $00
    CP A, $06
    JP Z, SetFWC
    LD A, $FF
SetFWC:
    LD (FireworksCounter), A
    LD L, <Enemy_State
    LD (HL), C

IncrementSFTask1:
    LD A, (StarFlagTaskControl)
    INC A
    LD (StarFlagTaskControl), A
    RET

StarFlagExit:
    POP HL
    RET

AwardGameTimerPoints:
    POP HL
;
    EX DE, HL
    LD HL, GameTimerDisplay
    LD A, (HL)
    INC L
    OR A, (HL)
    INC L
    OR A, (HL)
    EX DE, HL
    JP Z, IncrementSFTask1
;
    LD A, (FrameCounter)
    AND A, %00000100
    JP Z, NoTTick
    LD A, SNDID_BEEP
    LD (SFXTrack1.SoundQueue), A
NoTTick:
    LD A, $FF
    LD (DigitModifier + $05 * $100), A
    LD DE, GameTimerDisplay + $02
    CALL DigitsMathRoutine
    LD A, $05
    LD (DigitModifier + $05 * $100), A

EndAreaPoints:
    LD DE, PlayerScoreDisplay + $05
    LD A, (CurrentPlayer)
    OR A
    JP Z, ELPGive
    LD E, <OffScr_ScoreDisplay + $05
ELPGive:
    CALL DigitsMathRoutine
;
    LD A, (CurrentPlayer)
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    OR A, %00000100
    JP UpdateNumber

RaiseFlagSetoffFWorks:
    POP HL
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    CP A, $72 - SMS_PIXELYOFFSET
    JP C, SetoffF
    DEC (HL)
    JP DrawStarFlag
SetoffF:
    LD A, (FireworksCounter)
    OR A
    JP Z, DrawFlagSetTimer
    JP M, DrawFlagSetTimer
    LD A, OBJECTID_Fireworks
    LD (EnemyFrenzyBuffer), A

DrawStarFlag:
    CALL RelativeEnemyPosition
;
    LD L, <Enemy_SprDataOffset
    LD E, (HL)
    LD D, >Sprite_Y_Position
    EX DE, HL
    LD A, (Enemy_Rel_YPos)
    LD C, A
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), A
    INC L
    LD (HL), C
    INC L
    LD (HL), C
    EX DE, HL
;
    LD E, (HL)
    SLA E
    SET 7, E
    EX DE, HL
    LD A, (Enemy_Rel_XPos)
    LD C, A
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), $43
    INC L
    LD (HL), C
    INC L
    LD (HL), $42
    INC L
    LD (HL), A
    INC L
    LD (HL), $41
    INC L
    LD (HL), C
    INC L
    LD (HL), $40
    EX DE, HL
    RET

DrawFlagSetTimer:
    CALL DrawStarFlag
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, $06
    LD (BC), A

IncrementSFTask2:
    LD A, (StarFlagTaskControl)
    INC A
    LD (StarFlagTaskControl), A
    RET

DelayToAreaEnd:
    POP HL
;
    CALL DrawStarFlag                           ;do sub to draw star flag
;
    LD A, H                                     ;if interval timer set in previous task
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    RET NZ                                      ;not yet expired, branch to leave
;
    LD A, (MusicTrack0.SoundPlaying)            ;if event music buffer empty,
    CP A, SNDID_LEVELDONE
    JP NZ, IncrementSFTask2                     ;branch to increment task
    RET

;--------------------------------
;$00 - used to store horizontal difference between player and piranha plant

MovePiranhaPlant:
    POP HL
;
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    JP NZ, PutinPipe
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    JP NZ, PutinPipe
;
    LD L, <PiranhaPlant_MoveFlag
    LD A, (HL)
    OR A
    JP NZ, SetupToMovePPlant
;
    LD L, <PiranhaPlant_Y_Speed
    LD A, (HL)
    OR A
    JP M, ReversePlantSpeed
;
    CALL PlayerEnemyDiff
    JP P, ChkPlayerNearPipe
;
    LD A, (Temp_Bytes + $00)
    NEG
    LD (Temp_Bytes + $00), A

ChkPlayerNearPipe:
    LD A, (Temp_Bytes + $00)
    CP A, $21
    JP C, PutinPipe

ReversePlantSpeed:
    LD L, <PiranhaPlant_Y_Speed
    LD A, (HL)
    NEG
    LD (HL), A
    LD L, <PiranhaPlant_MoveFlag
    INC (HL)

SetupToMovePPlant:
    LD L, <PiranhaPlant_Y_Speed
    LD A, (HL)
    OR A
    LD L, <PiranhaPlantDownYPos
    LD A, (HL)
    JP P, RiseFallPiranhaPlant
    LD L, <PiranhaPlantUpYPos
    LD A, (HL)

RiseFallPiranhaPlant:
    LD (Temp_Bytes + $00), A
;
    LD A, (FrameCounter)
    SRL A
    JP NC, PutinPipe
    LD A, (TimerControl)
    OR A
    JP NZ, PutinPipe
;
    LD L, <PiranhaPlant_Y_Speed
    LD A, (HL)
    LD L, <Enemy_Y_Position
    ADD A, (HL)
    LD (HL), A
;
    LD A, (Temp_Bytes + $00)
    LD C, A
    LD A, (HL)
    CP A, C
    JP NZ, PutinPipe
;
    LD L, <PiranhaPlant_MoveFlag
    LD (HL), $00
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, $40
    LD (BC), A

PutinPipe:
    ;LD A, %00100000
    ;LD L, <Enemy_SprAttrib
    ;LD (HL), A
    RET

;-------------------------------------------------------------------------------------
;$07 - spinning speed

FirebarSpin:

SpinCounterClockwise:


;-------------------------------------------------------------------------------------
;$00 - used to hold collision flag, Y movement force + 5 or low byte of name table for rope
;$01 - used to hold high byte of name table for rope
;$02 - used to hold page location of rope

BalancePlatform:
    POP HL
;
    LD L, <Enemy_Y_HighPos
    LD A, (HL)
    CP A, $03
    JP Z, EraseEnemyObject
;
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    RET M

CheckBalPlatform:
    LD C, A
;
    LD L, <PlatformCollisionFlag
    LD A, (HL)
    LD (Temp_Bytes + $00), A
    LD B, A
;
    LD L, <Enemy_MovingDir
    LD A, (HL)
    OR A
    JP NZ, PlatformFall

ChkForFall:
    LD A, $2D - SMS_PIXELYOFFSET
    LD L, <Enemy_Y_Position
    CP A, (HL)
    JP C, ChkOtherForFall
;
    LD A, C
    CP A, B
    JP Z, InitPlatformFall
;
    LD A, $2D - SMS_PIXELYOFFSET
    ADD A, $02
    LD L, <Enemy_Y_Position
    LD (HL), A
    JP StopPlatforms

ChkOtherForFall:
    RET

ChkToMoveBalPlat:

DoOtherPlatform:

DrawEraseRope:

OtherRope:

SetupPlatformRope:

InitPlatformFall:
    LD A, C
    ADD A, $C1
    LD H, A
    CALL GetEnemyOffscreenBits
;
    LD A, $06
    CALL SetupFloateyNumber
;
    LD A, (Player_Rel_XPos)
    LD L, <FloateyNum_X_Pos
    LD (HL), A
    LD A, (Player_Y_Position)
    LD L, <FloateyNum_Y_Pos
    LD (HL), A
;
    LD L, <Enemy_MovingDir
    LD (HL), $01

StopPlatforms:
    CALL InitVStf
;
    LD A, C
    ADD A, $C1
    LD D, A
;
    XOR A
    LD E, <Enemy_Y_Speed
    LD (DE), A
    LD E, <Enemy_Y_MoveForce
    LD (DE), A
    RET

PlatformFall:
    
ExPF:
    LD HL, (ObjectOffset)
    RET

;--------------------------------

YMovingPlatform:
    POP HL
;
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    LD L, <Enemy_Y_MoveForce
    OR A, (HL)
    JP NZ, ChkYCenterPos
;
    LD L, <Enemy_YMF_Dummy
    LD (HL), A
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD L, <YPlatformTopYPos
    CP A, (HL)
    JP NC, ChkYCenterPos
;
    LD A, (FrameCounter)
    AND A, %00000111
    JP NZ, ChkYPCollision
;
    LD L, <Enemy_Y_Position
    INC (HL)
    JP ChkYPCollision

ChkYCenterPos:
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD L, <YPlatformCenterYPos
    CP A, (HL)
    JP C, YMDown
    CALL MovePlatformUp
    JP ChkYPCollision
YMDown:
    CALL MovePlatformDown

ChkYPCollision:
    LD L, <PlatformCollisionFlag
    LD A, (HL)
    OR A
    CALL P, PositionPlayerOnVPlat
    RET

;--------------------------------
;$00 - used as adder to position player hotizontally

XMovingPlatform:
    POP HL
;
    LD A, $0E
    CALL XMoveCntr_Platform
;
    CALL MoveWithXMCntrs
;
    LD L, <PlatformCollisionFlag
    LD A, (HL)
    OR A
    RET M

PositionPlayerOnHPlat:
    LD A, (Player_X_Position)
    LD C, A
    LD A, (Temp_Bytes + $00)
    ADD A, C
    LD (Player_X_Position), A
;
    LD A, (Temp_Bytes + $00)
    BIT 7, A
    LD A, (Player_PageLoc)
    JP NZ, PPHSubt
    ADC A, $00
    JP SetPVar
PPHSubt:
    SBC A, $00
SetPVar:
    LD (Player_PageLoc), A
;
    LD A, (Temp_Bytes + $00)
    LD (Platform_X_Scroll), A
;
    JP PositionPlayerOnVPlat 

;--------------------------------

DropPlatform:
    POP HL
;
    LD L, <PlatformCollisionFlag
    LD A, (HL)
    OR A
    RET M
;
    CALL MoveDropPlatform
    JP PositionPlayerOnVPlat

;--------------------------------

RightPlatform:
    POP HL
;
    CALL MoveEnemyHorizontally
;
    LD L, <PlatformCollisionFlag
    LD A, (HL)
    OR A
    RET M
;
    LD L, <Enemy_X_Speed
    LD (HL), $10
;
    JP PositionPlayerOnHPlat

;--------------------------------

MoveLargeLiftPlat:
    POP HL
;
    CALL MoveLiftPlatforms
    JP ChkYPCollision

MoveSmallPlatform:
    CALL MoveLiftPlatforms
    JP ChkSmallPlatCollision

MoveLiftPlatforms:
    LD A, (TimerControl)
    OR A
    RET NZ
;
    LD L, <Enemy_Y_MoveForce
    LD A, (HL)
    LD L, <Enemy_YMF_Dummy
    ADD A, (HL)
    LD (HL), A
;
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    LD L, <Enemy_Y_Position
    ADD A, (HL)
    LD (HL), A
    RET

ChkSmallPlatCollision:
    LD L, <PlatformCollisionFlag
    LD A, (HL)
    OR A
    RET Z
    JP PositionPlayerOnS_Plat

;-------------------------------------------------------------------------------------
;$00(B) - page location of extended left boundary
;$01(C) - extended left boundary position
;$02(D) - page location of extended right boundary
;$03(E) - extended right boundary position

OffscreenBoundsCheck:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_FlyingCheepCheep
    RET Z
;
    CP A, OBJECTID_HammerBro
    JP Z, LimitB
    CP A, OBJECTID_PiranhaPlant
    JP NZ, +
LimitB:
    LD A, (ScreenLeft_X_Pos)
    ADD A, $39  ;ADD A, $38
    JP ExtendLB
+:
    LD A, (ScreenLeft_X_Pos)
ExtendLB:
    SBC A, $48
    LD C, A ;LD (Temp_Bytes + $01), A
;
    LD A, (ScreenLeft_PageLoc)
    SBC A, $00
    LD B, A ;LD (Temp_Bytes + $00), A
;
    LD A, (ScreenRight_X_Pos)
    ADD A, $48
    LD E, A ;LD (Temp_Bytes + $03), A
;
    LD A, (ScreenRight_PageLoc)
    ADC A, $00
    LD D, A ;LD (Temp_Bytes + $02), A
;
    ;LD A, (Temp_Bytes + $01)
    ;LD C, A
    LD L, <Enemy_X_Position
    LD A, (HL)
    CP A, C
    ;LD A, (Temp_Bytes + $00)
    ;LD C, A
    DEC L ;LD L, <Enemy_PageLoc
    LD A, (HL)
    SBC A, B ;SBC A, C
    JP M, EraseEnemyObject
;
    ;LD A, (Temp_Bytes + $03)
    ;LD C, A
    INC L ;LD L, <Enemy_X_Position
    LD A, (HL)
    CP A, E ;CP A, C
    ;LD A, (Temp_Bytes + $02)
    ;LD C, A
    DEC L ;LD L, <Enemy_PageLoc
    LD A, (HL)
    SBC A, D ;SBC A, C
    RET M
;
    LD L, <Enemy_State
    LD A, (HL)
    CP A, OBJECTID_HammerBro
    RET Z
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_PiranhaPlant
    RET Z
    CP A, OBJECTID_FlagpoleFlagObject
    RET Z
    CP A, OBJECTID_StarFlagObject
    RET Z
    CP A, OBJECTID_JumpspringObject
    RET Z
    JP EraseEnemyObject

































;-------------------------------------------------------------------------------------

.SECTION "FloateyNumTileData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
;data is used as tiles for numbers
;that appear when you defeat enemies
FloateyNumTileData:
    .db BLANKTILE, BLANKTILE    ;dummy
    .db $2E, $33    ; "100"
    .db $2F, $33    ; "200"
    .db $30, $33    ; "400"
    .db $31, $33    ; "500"
    .db $32, $33    ; "800"
    .db $2E, $34    ; "1000"
    .db $2F, $34    ; "2000"
    .db $30, $34    ; "4000"
    .db $31, $34    ; "5000"
    .db $32, $34    ; "8000"
    .db $35, $36    ; "1-UP"
.ENDS

.SECTION "ScoreUpdateData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
;high nybble is digit number, low nybble is number to
;add to the digit of the player's score
ScoreUpdateData:
    .db $ff ;dummy
    .db $41, $42, $44, $45, $48
    .db $31, $32, $34, $35, $38, $00
.ENDS

FloateyNumbersRoutine:
    ;LD L, <FloateyNum_Control
    ;LD A, (HL)                              ;load control for floatey number
    ;OR A
    ;RET Z                                   ;if zero, branch to leave
;
    CP A, $0B                               ;if less than $0b, branch
    JP C, ChkNumTimer
    LD A, $0B
    LD (HL), A                              ;otherwise set to $0b, thus keeping it in range
ChkNumTimer:
    LD C, A                                 ;use as Y
;
    LD L, <FloateyNum_Timer
    LD A, (HL)                              ;check value here
    OR A
    JP NZ, DecNumTimer                      ;if nonzero, branch ahead
    LD L, <FloateyNum_Control
    LD (HL), A                              ;initialize floatey number control and leave
    RET
DecNumTimer:
    DEC (HL)                                ;decrement value here
    CP A, $2B                               ;if not reached a certain point, branch
    JP NZ, ChkTallEnemy
    LD A, C
    CP A, $0B                               ;check offset for $0b
    JP NZ, LoadNumTiles                     ;branch ahead if not found
    LD A, (NumberofLives)                   ;give player one extra life (1-up)
    INC A
    LD (NumberofLives), A
    LD A, SNDID_1UP
    LD (SFXTrack1.SoundQueue), A
LoadNumTiles:
    LD A, C
    LD BC, ScoreUpdateData
    addAToBC8_M
    LD A, (BC)                              ;load point value here
    RRCA                                    ;move high nybble to low
    RRCA
    RRCA
    RRCA
    AND A, $0F
    ADD A, >DigitModifier
    LD D, A                                 ;use as X offset, essentially the digit
    LD E, <DigitModifier
    LD A, (BC)                              ;load again and this time
    AND A, %00001111                        ;mask out the high nybble
    LD (DE), A                              ;store as amount to add to the digit
    CALL AddToScore                         ;update the score accordingly
ChkTallEnemy:
    LD L, <Enemy_SprDataOffset
    LD C, (HL)                              ;get OAM data offset for enemy object
    LD L, <Enemy_ID
    LD A, (HL)                              ;get enemy object identifier
    CP A, OBJECTID_Spiny
    JP Z, FloateyPart                       ;branch if spiny
    CP A, OBJECTID_PiranhaPlant
    JP Z, FloateyPart                       ;branch if piranha plant
    CP A, OBJECTID_HammerBro
    JP Z, GetAltOffset                      ;branch elsewhere if hammer bro
    CP A, OBJECTID_GreyCheepCheep
    JP Z, FloateyPart                       ;branch if cheep-cheep of either color
    CP A, OBJECTID_RedCheepCheep
    JP Z, FloateyPart
    CP A, OBJECTID_TallEnemy
    JP NC, GetAltOffset                     ;branch elsewhere if enemy object => $09
    LD L, <Enemy_State
    LD A, (HL)
    CP A, $02                               ;if enemy state defeated or otherwise
    JP NC, FloateyPart                      ;$02 or greater, branch beyond this part
GetAltOffset:
    LD A, (SprDataOffset_Ctrl)              ;load some kind of control bit
    ADD A, $C0 + SPRDATA_ALT
    LD D, A
    LD E, <SprDataOffset
    LD A, (DE)                              ;get alternate OAM data offset
    LD C, A
    ;LD HL, (ObjectOffset)                       
FloateyPart:
    LD L, <FloateyNum_Y_Pos
    LD A, (HL)                              ;get vertical coordinate for
    CP A, $18 - SMS_PIXELYOFFSET            ;floatey number, if coordinate in the
    JP C, SetupNumSpr                       ;status bar, branch
    DEC (HL)                                ;otherwise subtract one and store as new                             
SetupNumSpr:
    LD E, C
    LD D, >Sprite_Y_Position
    LD A, (HL)                              ;get vertical coordinate
    SUB A, $08                              ;subtract eight and dump into the
    LD (DE), A                              ;left and right sprite's Y coordinates
    INC E
    LD (DE), A
    DEC E
;
    SLA E                                   ;(SMS) double due to X,ID layout
    SET 7, E
    LD L, <FloateyNum_X_Pos
    LD A, (HL)                              ;get horizontal coordinate
    LD (DE), A                              ;store into X coordinate of left sprite
    ADD A, $08                              ;add eight pixels and store into X
    INC E                                   ;(SMS) skip tile ID
    INC E
    LD (DE), A                              ;coordinate of right sprite
;
    ;LD A, C
    ;LD HL, Sprite_Attributes
    ;addAToHL8_M
    ;LD (HL), $02                            ;set palette control in attribute bytes
    ;INC L
    ;INC L
    ;INC L
    ;INC L
    ;LD (HL), $02                            ;of left and right sprites
;
    LD L, <FloateyNum_Control
    LD A, (HL)
    ADD A, A                                ;multiply our floatey number control by 2
    LD DE, FloateyNumTileData               ;and use as offset for look-up table
    addAToDE8_M
    LD A, (DE)
    LD B, >Sprite_Tilenumber
    SLA C                                   ;(SMS) double due to X,ID layout
    SET 7, C
    INC C
    LD (BC), A                              ;display first half of number of points
;
    INC E
    LD A, (DE)
    INC C                                   ;(SMS) skip X Pos
    INC C
    LD (BC), A                              ;display the second half
    ;LD HL, (ObjectOffset)
    RET

;-------------------------------------------------------------------------------------

RunGameTimer:
    LD A, (OperMode)                        ;get primary mode of operation
    OR A
    RET Z                                   ;branch to leave if in title screen mode
;
    LD A, (GameEngineSubroutine)
    CP A, $08                               ;if routine number less than eight running,
    RET C                                   ;branch to leave
;
    CP A, $0B                               ;if running death routine,
    RET Z                                   ;branch to leave
;
    LD A, (Player_Y_HighPos)
    CP A, $02                               ;if player below the screen,
    RET NC                                  ;branch to leave regardless of level type
;
    LD A, (GameTimerCtrlTimer)
    OR A                                    ;if game timer control not yet expired,
    RET NZ                                  ;branch to leave
;
    LD HL, GameTimerDisplay                 ;otherwise check game timer digits
    LD A, (HL)
    INC L
    OR A, (HL)
    INC L
    OR A, (HL)
    JP Z, TimeUpOn                          ;if game timer digits at 000, branch to time-up code
;
    LD A, (GameTimerDisplay)                ;otherwise check first digit
    DEC A                                   ;if first digit not on 1,
    JP NZ, ResGTCtrl                        ;branch to reset game timer control
;
    LD A, (HL)                              ;otherwise check second and third digits
    DEC L
    OR A, (HL)
    JP NZ, ResGTCtrl                        ;if timer not at 100, branch to reset game timer control
;
    ;CALL GetAreaMusic
    LD A, (MusicTrack0.SoundPlaying)
    LD (MusicTrack1.SoundQueue), A
    LD A, SNDID_HURRYUP
    LD (MusicTrack0.SoundQueue), A          ; EVENT
    LD A, $01
    LD (SndHurryUpFlag), A
;
ResGTCtrl:
    LD A, $18                               ;reset game timer control
    LD (GameTimerCtrlTimer), A
    LD DE, GameTimerDisplay + $02           ;set offset for last digit
    LD A, $FF                               ;set value to decrement game timer digit
    LD (DigitModifier + $05 * $100), A
    CALL DigitsMathRoutine                  ;do sub to decrement game timer slowly
    LD A, $A4                               ;set status nybbles to update game timer display
    JP PrintStatusBarNumbers                ;do sub to update the display
TimeUpOn:
    LD (PlayerStatus), A                    ;init player status (note A will always be zero here)
    CALL ForceInjury                       ;do sub to kill the player (note player is small here)
    LD A, $01                               ;set game timer expiration flag
    LD (GameTimerExpiredFlag), A
    RET

;-------------------------------------------------------------------------------------

.SECTION "FlagpoleScoreMods, FlagpoleScoreDigits" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FlagpoleScoreDigits:
    .db $03, $03, $04, $04, $04

FlagpoleScoreMods:
    .db $05, $02, $08, $04, $01
.ENDS

FlagpoleRoutine:
    LD H, $C0 + OBJ_SLOT6                   ;set enemy object offset
    LD (ObjectOffset), HL                   ;to special use slot
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_FlagpoleFlagObject       ;if flagpole flag not found,
    RET NZ                                  ;branch to leave
;
    LD A, (GameEngineSubroutine)
    CP A, $04                               ;if flagpole slide routine not running,
    JP NZ, FPGfx                            ;branch to near the end of code
;
    LD A, (Player_State)
    CP A, $03                               ;if player state not climbing,
    JP NZ, FPGfx                            ;branch to near the end of code
;
    LD L, <Enemy_Y_Position
    LD A, (HL)                              ;check flagpole flag's vertical coordinate
    CP A, $AA - SMS_PIXELYOFFSET            ;if flagpole flag down to a certain point,
    JP NC, GiveFPScr                        ;branch to end the level
;
    LD A, (Player_Y_Position)               ;check player's vertical coordinate
    CP A, $A2 - SMS_PIXELYOFFSET            ;if player down to a certain point,
    JP NC, GiveFPScr                        ;branch to end the level
;
    LD L, <Enemy_YMF_Dummy
    LD A, (HL)
    ADD A, $FF                              ;add movement amount to dummy variable
    LD (HL), A                              ;save dummy variable
;
    LD L, <Enemy_Y_Position
    LD A, (HL)                              ;get flag's vertical coordinate
    ADC A, $01                              ;add 1 plus carry to move flag, and
    LD (HL), A                              ;store vertical coordinate
;
    LD A, (FlagpoleFNum_YMFDummy)
    SUB A, $FF                              ;subtract movement amount from dummy variable
    LD (FlagpoleFNum_YMFDummy), A           ;save dummy variable
;
    LD A, (FlagpoleFNum_Y_Pos)
    SBC A, $01                              ;subtract one plus borrow to move floatey number,
    LD (FlagpoleFNum_Y_Pos), A              ;and store vertical coordinate here
;SkipScore:
    JP FPGfx                                ;jump to skip ahead and draw flag and floatey number
GiveFPScr:
    LD DE, FlagpoleScoreDigits
    LD A, (FlagpoleScore)                   ;get score offset from earlier (when player touched flagpole)
    addAToDE8_M
    LD A, (DE)                              ;get digit with which to award points
    ADD A, >DigitModifier                   ;(SMS)
    LD H, A
    LD L, <DigitModifier
    LD A, $05
    addAToDE8_M
    LD A, (DE)                              ;get amount to award player points
    LD (HL), A                              ;store in digit modifier
    
    CALL AddToScore                         ;do sub to award player points depending on height of collision
    LD A, $05
    LD (GameEngineSubroutine), A            ;set to run end-of-level subroutine on next frame
    LD H, $C0 + OBJ_SLOT6 
FPGfx:
    CALL GetEnemyOffscreenBits              ;get offscreen information
    CALL RelativeEnemyPosition              ;get relative coordinates
    JP FlagpoleGfxHandler                   ;draw flagpole flag and floatey number

;-------------------------------------------------------------------------------------

BlockObjectsCore:
    LD L, <Block_State
    LD A, (HL)                      ;get state of block object
    OR A
    RET Z                           ;if not set, branch to leave
;
    AND A, $0F                      ;mask out high nybble
    PUSH AF                         ;push to stack    
    ;LD C, A                         ;put in Y for now
    ;DEC C                           ;decrement Y to check for solid block state
    DEC A
    JP Z, BouncingBlockHandler      ;branch if found, otherwise continue for brick chunks
;
    CALL ImposeGravityBlock         ;do sub to impose gravity on one block object object
    CALL MoveObjectHorizontally     ;do another sub to move horizontally
;
    INC H                           ;move onto next block object
    INC H
    CALL ImposeGravityBlock         ;do sub to impose gravity on other block object
    CALL MoveObjectHorizontally     ;do another sub to move horizontally
;
    ;LD HL, (ObjectOffset)          ;get block object offset used for both
    DEC H
    DEC H
    CALL RelativeBlockPosition      ;get relative coordinates
    CALL GetBlockOffscreenBits      ;get offscreen information
    CALL DrawBrickChunks            ;draw the brick chunks
;
    LD L, <Block_Y_HighPos
    LD A, (HL)                      ;check vertical high byte of block object
    OR A
    JP Z, UpdSte                    ;if above the screen, branch to kill it
;
    INC H
    INC H
    LD L, <Block_Y_Position         ;Block_Y_Position+2
    LD A, $F0 - SMS_PIXELYOFFSET   ; CHANGE???
    CP A, (HL)                      ;check to see if bottom block object went
    JP NC, ChkTop                   ;to the bottom of the screen, and branch if not
    LD (HL), A                      ;otherwise set offscreen coordinate
ChkTop:
    DEC H
    DEC H
    LD A, (HL)
    CP A, $F0                       ;see if top block object went to the bottom of the screen
    JP C, UpdSte                    ;if not, branch to save state
    JP KillBlock                    ;otherwise do unconditional branch to kill it

BouncingBlockHandler:
    CALL ImposeGravityBlock         ;do sub to impose gravity on block object
    ;LD HL, (ObjectOffset)          ;get block object offset
    CALL RelativeBlockPosition      ;get relative coordinates
    CALL GetBlockOffscreenBits      ;get offscreen information
    CALL DrawBlock                  ;draw the block
;
    LD L, <Block_Y_Position
    LD A, (HL)                      ;get vertical coordinate
    ADD A, $08
    AND A, $0F                      ;mask out high nybble
    CP A, $05                       ;check to see if low nybble wrapped around
    JP NC, UpdSte                   ;if still above amount, not time to kill block yet, thus branch
;
    LD L, <Block_RepFlag
    LD (HL), $01                    ;otherwise set flag to replace metatile
KillBlock:
    POP AF
    XOR A                           ;if branched here, nullify object state
    PUSH AF
UpdSte:
    POP AF
    LD L, <Block_State
    LD (HL), A                      ;store contents of A in block object state
    RET
    
;-------------------------------------------------------------------------------------
;$02(IXL) - used to store offset to block buffer
;$06-$07(DE) - used to store block buffer address

BlockObjMT_Updater:    
    LD H, $C0 + OBJ_BLOCK2              ;set offset to start with second block object
    LD B, $02
UpdateLoop:
    LD (ObjectOffset), HL               ;set offset here
;
    LD A, (VRAM_Buffer1)                ;if vram buffer already being used here,
    OR A
    JP NZ, NextBUpd                     ;branch to move onto next block object
;
    LD L, <Block_RepFlag
    LD A, (HL)                          ;if flag for block object already clear,
    OR A
    JP Z, NextBUpd                      ;branch to move onto next block object
;
    LD L, <Block_BBuf_Low
    LD E, (HL)                          ;get low byte of block buffer and store
    LD D, >Block_Buffer_1               ;set high byte of block buffer address
;
    LD L, <Block_Orig_YPos
    LD A, (HL)                          ;get original vertical coordinate of block object
    LD IXL, A                           ;store here and use as offset to block buffer
;
    addAToDE_M
    LD L, <Block_Metatile
    LD A, (HL)                          ;get metatile to be written
    LD (DE), A                          ;write it to the block buffer
    PUSH HL
    EX DE, HL                           ;!!! METATILES THAT ARE SPLIT BY LEFT SCREEN EDGE WILL HAVE THAT PART BE PUT ON THE RIGHT EDGE
    CALL WriteBlockMetatile             ;do sub to replace metatile where block object is
    POP HL
;
    LD L, <Block_RepFlag
    LD (HL), $00                        ;clear block object flag
NextBUpd:
    DEC H                               ;decrement block object offset
    DJNZ UpdateLoop                     ;do this until both block objects are dealt with                
    RET

;-------------------------------------------------------------------------------------
;$00 - temp store for offset control bit
;$01 - temp vram buffer offset
;$02(IXL) - temp store for vertical high nybble in block buffer routine
;$03 - temp adder for high byte of name table address
;$04, $05 - name table address low/high
;$06, $07(DE) - block buffer address low/high

.SECTION "BlockGfxData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BlockGfxData:
    ;    TL   TR   BL   BR
    ;.db $45, $45, $47, $47          ; TILES FOR SHINY BRICK METATILE
    ;.db $47, $47, $47, $47          ; TILES FOR BRICK METATILE
    ;.db $57, $58, $59, $5a          ; TILES FOR EMPTY BLOCK METATILE
    ;.db $24, $24, $24, $24          ; TILES FOR BLANK METATILE  
    ;.db $26, $26, $26, $26          ; TILES FOR BLANK METATILE FOR WATER

    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; SHINY BRICK MT
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; BRICK MT
    .dw BG_MACRO($11A5), BG_MACRO($11A7), BG_MACRO($11A6), BG_MACRO($11A8)  ; EMPTY BLOCK MT (PRIORITY)
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE  ; BLANK MT
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE  ; WATER MT
    .dw BG_MACRO($01A5), BG_MACRO($01A7), BG_MACRO($01A6), BG_MACRO($01A8)  ; EMPTY BLOCK MT (NO PRI)
.ENDS

    /*
RemovePriBlock:
    CALL GetBlockBufferAddr
    EX DE, HL
    LD DE, (VRAM_Buffer1_Ptr)
    LD A, $05
    CALL PutBlockMetatile
    LD (VRAM_Buffer1_Ptr), DE
    RET
    */

RemoveCoin_Axe:
    LD DE, (VRAM_Buffer1_Ptr)    
    ;LD DE, (VRAM_Buffer2_Ptr)
    ;LD DE, VRAM_Buffer2             ;set low byte so offset points to $0341 (VRAM_Buffer2)
    LD A, (AreaType)                ;check area type
    OR A
    LD A, $03                       ;load offset for default blank metatile
    JP NZ, WriteBlankMT             ;if not water type, use offset
    INC A                           ;otherwise load offset for blank metatile used in water
WriteBlankMT:
    CALL PutBlockMetatile           ;do a sub to write blank metatile to vram buffer
    ;LD (VRAM_Buffer2_Ptr), DE
    ;LD A, VRAMTBL_BUFFER2
    ;LD (VRAM_Buffer_AddrCtrl), A    ;set vram address controller to $0341 and leave
    LD (VRAM_Buffer1_Ptr), DE
    XOR A
    LD (VRAM_Buffer_AddrCtrl), A
    RET


DestroyBlockMetatile:
    XOR A                           ;force blank metatile if branched/jumped to this point

WriteBlockMetatile:
    LD C, $03                       ;load offset for blank metatile
    OR A                            ;check contents of A for blank metatile
    JP Z, UseBOffset                ;branch if found (unconditional if branched from DestroyBlockMetatile)
    LD C, $00                       ;load offset for brick metatile w/ line
    CP A, MT_SBRICK_COIN
    JP Z, UseBOffset                ;use offset if metatile is brick with coins (w/ line)
    CP A, MT_SBRICK
    JP Z, UseBOffset                ;use offset if metatile is breakable brick w/ line
    INC C                           ;increment offset for brick metatile w/o line
    CP A, MT_BRICK_COIN
    JP Z, UseBOffset                ;use offset if metatile is brick with coins (w/o line)
    CP A, MT_BRICK
    JP Z, UseBOffset                ;use offset if metatile is breakable brick w/o line
    INC C                           ;if any other metatile, increment offset for empty block
UseBOffset:
    LD A, C                         ;put Y in A
    LD DE, (VRAM_Buffer1_Ptr)       ;get vram buffer offset
    CALL PutBlockMetatile           ;get appropriate block data and write to vram buffer
MoveVOffset:
    LD (VRAM_Buffer1_Ptr), DE       ;store new vram buffer offset
    RET


;   X - N/A but needs to be saved since it holds SprDataOffset_Ctrl? (NOT NEEDED???)
;   Y - VRAM Buffer offset
;   A - Index into BlockGfxData
;   ----
;   A - Index into BlockGfxData
;   HL - Block_Buffer Ptr
;   DE - VRAM_Buffer Ptr
;   BC - BlockGfxData Ptr
PutBlockMetatile:
    PUSH BC
;   PREPARE BlockGfxData PTR
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, <BlockGfxData
    LD C, A
    LD B, >BlockGfxData
;   CONVERT BLOCK BUFFER COLUMN TO NAMETABLE COLUMN
    LD A, L
    AND A, $0F
    ADD A, A
    ADD A, A
    LD IXH, A   ;LD I, A
;   MULTIPLY BLOCK BUFFER ROW TO NAMETABLE ROW
    LD A, IXL   ; CHANGE REG?
    ADD A, $08
    LD L, A
    LD H, $00
    ADD HL, HL
    ADD HL, HL
    ADD HL, HL
;   NAMETABLE ROW LOW BYTE + COLUMN
    LD A, IXH   ;LD A, I
    ADD A, L
    LD L, A
;   NAMETABLE ROW HIGH BYTE + CARRY + BASE NT
    LD A, H
    ADC A, $00
    ADD A, $20 | >VRAMWRITE  ; BASE NT ADDR
    LD H, A
;   WRITE VRAM BUFFER (VDP ADDRESS)
    LD (DE), A  ; HIGH BYTE
    INC E
    LD A, L
    LD (DE), A  ; LOW BYTE
    INC E
;   WRITE VRAM BUFFER (COUNT)
    LD A, $02 | STRIPE_HWRITE_W
    LD (DE), A
    INC E
;   WRITE VRAM BUFFER (TOP LEFT TILE, TOP RIGHT TILE)
    LD A, (BC)
    LD (DE), A
    INC C
    INC E
    LD A, (BC)
    LD (DE), A
    INC C
    INC E
    LD A, (BC)
    LD (DE), A
    INC C
    INC E
    LD A, (BC)
    LD (DE), A
    INC C
    INC E
;   WRITE VRAM BUFFER (VDP ADDRESS)
    LD A, $40
    addAToHL_M
    LD (DE), A  ; HIGH BYTE
    INC E
    LD A, L
    LD (DE), A  ; LOW BYTE
    INC E
;   WRITE VRAM BUFFER (COUNT)
    LD A, $02 | STRIPE_HWRITE_W
    LD (DE), A
    INC E
;   WRITE VRAM BUFFER (BOT LEFT TILE, BOT RIGHT TILE)
    LD A, (BC)
    LD (DE), A
    INC C
    INC E
    LD A, (BC)
    LD (DE), A
    INC C
    INC E
    LD A, (BC)
    LD (DE), A
    INC C
    INC E
    LD A, (BC)
    LD (DE), A
    INC E
;   SET TERMINATOR
    XOR A
    LD (DE), A
;
    POP BC
    RET

;-------------------------------------------------------------------------------------

.SECTION "HammerEnemyOfsData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
HammerEnemyOfsData:
    .db $04, $04, $04, $05, $05, $05
    .db $06, $06, $06
.ENDS

.SECTION "HammerXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
HammerXSpdData:
    .db $10, $f0
.ENDS

SpawnHammerObj:
    RET

;-------------------------------------------------------------------------------------
;$02(IXL) - used to store vertical high nybble offset from block buffer routine
;$06 - used to store low byte of block buffer address

CoinBlock:
    POP HL
    CALL FindEmptyMiscSlot
;
    LD L, <Block_PageLoc
    LD E, <Misc_PageLoc
    LD A, (HL)
    LD (DE), A
;
    LD L, <Block_X_Position
    LD E, <Misc_X_Position
    LD A, (HL)
    ADD A, $05
    LD (DE), A
;
    LD L, <Block_Y_Position
    LD E, <Misc_Y_Position
    LD A, (HL)
    SUB A, $10
    LD (DE), A
    JP JCoinC

SetupJumpCoin:
    CALL FindEmptyMiscSlot
;
    LD L, <Block_PageLoc2
    LD E, <Misc_PageLoc
    LD A, (HL)
    LD (DE), A
;
    LD E, <Misc_X_Position
    LD A, (Temp_Bytes + $06)
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, $05
    LD (DE), A
;
    LD E, <Misc_Y_Position
    LD A, IXL
    ADD A, $08
    LD (DE), A
;
JCoinC:
    LD E, <Misc_Y_Speed
    LD A, $FB
    LD (DE), A
;
    LD E, <Misc_Y_HighPos
    LD A, $01
    LD (DE), A
    LD E, <Misc_State
    LD (DE), A
;
    LD A, SNDID_COIN
    LD (SFXTrack1.SoundQueue), A
;
    LD (ObjectOffset), HL
    CALL GiveOneCoin
    LD A, (CoinTallyFor1Ups)
    INC A
    LD (CoinTallyFor1Ups), A
    RET

FindEmptyMiscSlot:
    LD C, $03
    LD DE, Misc_State + ($08 * $100)
FMiscLoop:
    LD A, (DE)
    OR A
    RET Z
    DEC D
    DEC C
    JP NZ, FMiscLoop
    LD D, >Misc_State + $08
    RET

;-------------------------------------------------------------------------------------

MiscObjectsCore:
    LD H, $C0 + OBJ_MISC9               ;set at end of misc object buffer
MiscLoop:
    LD (ObjectOffset), HL               ;store misc object offset here
    LD L, <Misc_State                   ;check misc object state
    LD A, (HL)
    OR A
    JP Z, MiscLoopBack                  ;branch to check next slot
    JP P, ProcJumpCoin                  ;if d7 not set, jumping coin, thus skip to rest of code here
    ;CALL ProcHammerObj                  ;otherwise go to process hammer,
    JP MiscLoopBack                     ;then check next slot

;--------------------------------
;$00(IXL) - used to set downward force
;$01(IXH) - used to set upward force (residual)
;$02(IYL) - used to set maximum speed

ProcJumpCoin:
    DEC A                               ;decrement misc object state to see if it's set to 1
    JP Z, JCoinRun                      ;if so, branch to handle jumping coin
;
    INC (HL)                            ;otherwise increment state to either start off or as timer
    LD L, <Misc_X_Position              ;get horizontal coordinate for misc object
    LD A, (ScrollAmount)                ;whether its jumping coin (state 0 only) or floatey number
    ADD A, (HL)                         ;add current scroll speed
    LD (HL), A                          ;store as new horizontal coordinate
;
    LD L, <Misc_PageLoc                 ;get page location
    LD A, (HL)
    ADC A, $00                          ;add carry
    LD (HL), A                          ;store as new page location
;
    LD L, <Misc_State
    LD A, (HL)
    CP A, $30                           ;check state of object for preset value
    JP NZ, RunJCSubs                    ;if not yet reached, branch to subroutines
    LD (HL), $00                        ;otherwise nullify object state
    JP MiscLoopBack                     ;and move onto next slot
;
JCoinRun:
    LD IXL, $50                         ;set downward movement amount
    LD IYL, $06                         ;set maximum vertical speed
    XOR A                               ;set A to impose gravity on jumping coin
    CALL ImposeGravity                  ;do sub to move coin vertically and impose gravity on it
;
    ;LD HL, (ObjectOffset)               ;get original misc object offset
    LD L, <Misc_Y_Speed
    LD A, (HL)                          ;check vertical speed
    CP A, $05
    JP NZ, RunJCSubs                    ;if not moving downward fast enough, keep state as-is
    LD L, <Misc_State
    INC (HL)                            ;otherwise increment state to change to floatey number
RunJCSubs:
    CALL RelativeMiscPosition           ;get relative coordinates
    CALL GetMiscOffscreenBits           ;get offscreen information
    ;CALL GetMiscBoundBox
    CALL JCoinGfxHandler                ;draw the coin or floatey number

MiscLoopBack:
    DEC H                               ;decrement misc object offset
    LD A, $C0 + OBJ_MISC1-1
    CP A, H
    JP NZ, MiscLoop                     ;loop back until all misc objects handled
    RET

;-------------------------------------------------------------------------------------

GiveOneCoin:
    LD A, $01                           ;set digit modifier to add 1 coin
    LD (DigitModifier + $05 * $100), A  ;to the current player's coin tally
;
    LD DE, PlayerCoinDisplay + $01      ;get correct offset for player's coin tally
    LD A, (CurrentPlayer)
    OR A
    JP Z, +
    LD E, <OffScr_CoinDisplay + $01
+:
    CALL DigitsMathRoutine              ;update the coin tally
;
    LD HL, CoinTally                    ;increment onscreen player's coin amount
    INC (HL)
    LD A, (HL)
    CP A, 100                           ;does player have 100 coins yet?
    JP NZ, CoinPoints                   ;if not, skip all of this
    LD (HL), $00                        ;otherwise, reinitialize coin amount
    LD HL, NumberofLives                ;give the player an extra life
    INC (HL)
    LD A, SNDID_1UP
    LD (SFXTrack1.SoundQueue), A
CoinPoints:
    LD A, $02                           ;set digit modifier to award
    LD (DigitModifier + $04 * $100), A  ;200 points to the player

AddToScore:
    LD DE, PlayerScoreDisplay + $05
    LD A, (CurrentPlayer)
    OR A
    JP Z, +
    LD E, <OffScr_ScoreDisplay + $05
+:
    CALL DigitsMathRoutine

GetSBNybbles:
    LD A, (CurrentPlayer)               ;get current player
    OR A
    LD A, $02                           ;get nybbles based on player, use to update score and coins
    JP Z, UpdateNumber
    LD A, $13

UpdateNumber:
    CALL PrintStatusBarNumbers          ;print status bar numbers based on nybbles, whatever they be
    LD HL, (VRAM_Buffer1_Ptr)           ;check highest digit of score
    LD DE, -$000C
    ADD HL, DE
    LD A, (HL)
    CP A, BG_TILE_OFFSET
    JP NZ, NoZSup                       ;if zero, overwrite with space tile for zero suppression
    LD (HL), BLANKTILE
    INC L
    LD (HL), $00                        ;attribute byte (tile is in sprite bank)
NoZSup:    
    LD HL, (ObjectOffset)               ;get enemy object buffer offset
    RET

;-------------------------------------------------------------------------------------

SetupPowerUp:
    LD A, OBJECTID_PowerUpObject
    LD (Enemy_ID + $05 * $100), A
;
    LD L, <Block_PageLoc
    LD A, (HL)
    LD (Enemy_PageLoc + $05 * $100), A
;
    LD L, <Block_X_Position
    LD A, (HL)
    LD (Enemy_X_Position + $05 * $100), A
;
    LD A, $01
    LD (Enemy_Y_HighPos + $05 * $100), A
;
    LD L, <Block_Y_Position
    LD A, (HL)
    SUB A, $08
    LD (Enemy_Y_Position + $05 * $100), A
;
    LD A, $01
    LD (Enemy_State + $05 * $100), A
    LD (Enemy_Flag + $05 * $100), A
;
    LD A, $03
    LD (Enemy_BoundBoxCtrl + $05 * $100), A
;
    LD A, (PowerUpType)
    CP A, $02
    JP NC, PutBehind
    LD A, (PlayerStatus)
    CP A, $02
    JP C, StrType
    SRL A
StrType:
    LD (PowerUpType), A
PutBehind:
    ;LD A, %00100000
    ;LD (Enemy_SprAttrib + $05 * $100), A
    LD A, SNDID_ITEM
    LD (SFXTrack1.SoundQueue), A
    RET

;-------------------------------------------------------------------------------------
;$00(IXL) - used to store high nybble of horizontal speed as adder
;$01(IXH) - used to store low nybble of horizontal speed
;$02(IYL) - used to store adder to page location

;MoveEnemyHorizontally:
    ;CALL MoveObjectHorizontally     ;position object horizontally according to
    ;LD HL, (ObjectOffset)          ;counters, return with saved value in A,
    ;RET

MovePlayerHorizontally:
    LD A, (JumpspringAnimCtrl)      ;if jumpspring currently animating,
    OR A
    RET NZ                          ;branch to leave
    ;LD B, A                         ;otherwise set zero for offset to use player's stuff
    LD H, $C0 + OBJ_PLAYER

MoveEnemyHorizontally:
MoveObjectHorizontally:
    LD L, <SprObject_X_Speed
    LD A, (HL)                      ;get currently saved value (horizontal
    ADD A, A                        ;speed, secondary counter, whatever)
    ADD A, A                        ;and move low nybble to high
    ADD A, A
    ADD A, A
    LD IXH, A                       ;store result here
;
    LD A, (HL)                      ;get saved value again
    RRCA                            ;move high nybble to low
    RRCA
    RRCA
    RRCA
    AND A, $0F
    CP A, $08                       ;if < 8, branch, do not change
    JP C, SaveXSpd
    OR A, %11110000                 ;otherwise alter high nybble
SaveXSpd:
    LD IXL, A                       ;save result here
    LD C, $00                       ;load default Y value here
    OR A                            ;if result positive, leave Y alone
    JP P, UseAdder
    DEC C                           ;otherwise decrement Y
UseAdder:
    LD IYL, C                       ;save Y here
;
    LD L, <SprObject_X_MoveForce
    LD A, (HL)                      ;get whatever number's here
    ADD A, IXH                      ;add low nybble moved to high
    LD (HL), A                      ;store result here
    PUSH AF
;
    LD L, <SprObject_X_Position
    LD A, (HL)
    ADC A, IXL                      ;add carry plus saved value (high nybble moved to low
    LD (HL), A                      ;plus $f0 if necessary) to object's horizontal position
;
    LD L, <SprObject_PageLoc
    LD A, (HL)
    ADC A, IYL                      ;add carry plus other saved value to the
    LD (HL), A                      ;object's page location and save
;
    POP AF                          ;pull old carry from stack and add
    LD A, IXL                       ;to high nybble moved to low
    ADC A, $00
    RET
    
;-------------------------------------------------------------------------------------
;$00(IXL) - used for downward force
;$01(IXH) - used for upward force
;$02(IYL) - used for maximum vertical speed

MovePlayerVertically:
    ;LD B, $00                       ;set X for player offset
    LD A, (TimerControl)
    OR A
    JP NZ, NoJSChk                  ;if master timer control set, branch ahead
    LD A, (JumpspringAnimCtrl)      ;otherwise check to see if jumpspring is animating
    OR A
    RET NZ                          ;branch to leave if so
NoJSChk:
    LD A, (VerticalForce)           ;dump vertical force 
    LD IXL, A
    LD A, $04                       ;set maximum vertical speed here
    JP ImposeGravitySprObj          ;then jump to move player vertically

;--------------------------------

MoveD_EnemyVertically:
    LD C, $3D                       ;set quick movement amount downwards
    LD L, <Enemy_State
    LD A, (HL)                      ;then check enemy state
    CP A, $05                       ;if not set to unique state for spiny's egg, go ahead
    JP NZ, SetHiMax                 ;and use, otherwise set different movement amount, continue on

MoveFallingPlatform:
    LD C, $20                       ;set movement amount
    JP SetHiMax                     ;jump to skip the rest of this

;--------------------------------

MoveRedPTroopaDown:
    LD C, $00                       ;set Y to move downwards
    JP MoveRedPTroopa               ;skip to movement routine

MoveRedPTroopaUp:
    LD C, $01                       ;set Y to move upwards

MoveRedPTroopa:
    ;INC B                           ;increment X for enemy offset
    LD IXL, $03                     ;set downward movement amount here
    LD IXH, $06                     ;set upward movement amount here
    LD IYL, $02                     ;set maximum speed here
    LD A, C                         ;set movement direction in A, and
    JP RedPTroopaGrav               ;jump to move this thing

;--------------------------------

MoveDropPlatform:
    LD C, $7F                       ;set movement amount for drop platform
    JP SetMdMax                     ;skip ahead of other value set here

MoveEnemySlowVert:
    LD C, $0F                       ;set movement amount for bowser/other objects
SetMdMax:
    LD A, $02                       ;set maximum speed in A
    JP SetXMoveAmt

;--------------------------------

MoveJ_EnemyVertically:
    LD C, $1C                       ;set movement amount for podoboo/other objects
SetHiMax:
    LD A, $03                       ;set maximum speed in A
SetXMoveAmt:
    LD IXL, C                       ;set movement amount here
    ;INC B                           ;increment X for enemy offset
    CALL ImposeGravitySprObj        ;do a sub to move enemy object downwards
    ;LD HL, (ObjectOffset)          ;get enemy object buffer offset and leave
    ;LD B, (HL)
    RET

;--------------------------------

.SECTION "MaxSpdBlockData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
MaxSpdBlockData:
    .db $06, $08
.ENDS

ImposeGravityBlock:
    LD IXL, $50                     ;set movement amount here
    ;LD C, $01                       ;set offset for maximum speed
    ;LD A, $01
    ;LD DE, MaxSpdBlockData
    ;addAToDE8_M
    ;LD A, (DE)                      ;get maximum speed
    LD A, (MaxSpdBlockData + $01)
    
    
ImposeGravitySprObj:
    LD IYL, A                       ;set maximum speed here
    XOR A                           ;set value to move downwards
    JP ImposeGravity                ;jump to the code that actually moves it

;--------------------------------

MovePlatformDown:
    XOR A
    JP MovePlatformUp@SaveVal

MovePlatformUp:
    LD A, $01
@SaveVal:
    PUSH AF                         ;save value to stack
    LD L, <Enemy_ID
    LD C, (HL)                      ;get enemy object identifier
    ;INC B                           ;increment offset for enemy object
    INC H
    LD IXL, $05                     ;save downward movement amount here
    LD IXH, $0A                     ;save upward movement amount here
    LD IYL, $03                     ;save maximum vertical speed here
    POP AF                          ;get value from stack
    LD C, A                         ;use as Y, then move onto code shared by red koopa
    
RedPTroopaGrav:
    CALL ImposeGravity              ;do a sub to move object gradually
    ;LD HL, (ObjectOffset)          ;get enemy object offset and leave
    ;LD B, (HL)
    RET

;-------------------------------------------------------------------------------------
;$00(IXL) - used for downward force
;$01(IXH) - used for upward force (ONLY USED IF A == 1)
;$02(IYL) - used for maximum vertical speed
;$07(IYH) - used as adder for vertical position

;   A - FLAG FOR SOMETHING?
;   B - OBJECT OFFSET
ImposeGravity:
    PUSH AF                         ;push value to stack
;
    LD D, H
    LD E, <SprObject_YMF_Dummy
    LD L, <SprObject_Y_MoveForce
    LD A, (DE)                      ;add value in movement force to contents of dummy variable
    ADD A, (HL)
    LD (DE), A
;
    LD C, $00                       ;set Y to zero by default
    LD E, <SprObject_Y_Speed
    LD A, (DE)                      ;get current vertical speed
    BIT 7, A
    JP Z, AlterYP                   ;if currently moving downwards, do not decrement Y
    DEC C                           ;otherwise decrement Y
AlterYP:
    ;LD IYH, C
;
    LD L, <SprObject_Y_Position
    ADC A, (HL)                     ;add vertical position to vertical speed plus carry
    LD (HL), A                      ;store as new vertical position
;
    LD L, <SprObject_Y_HighPos
    LD A, (HL)
    ADC A, C                        ;add carry plus contents of $07 to vertical high byte
    LD (HL), A                      ;store as new vertical high byte
;
    LD L, <SprObject_Y_MoveForce
    LD A, (HL)
    ADD A, IXL                      ;add downward movement amount to contents of $0433
    LD (HL), A
;
    LD A, (DE)
    ADC A, $00                      ;add carry to vertical speed and store
    LD (DE), A
;
    CP A, IYL                       ;compare to maximum speed
    JP M, ChkUpM                    ;if less than preset value, skip this part
    LD A, (HL)
    CP A, $80                       ;if less positively than preset maximum, skip this part
    JP C, ChkUpM
    LD A, IYL                       ;keep vertical speed within maximum value
    LD (DE), A
    LD (HL), $00                    ;clear fractional
;
ChkUpM:
    POP AF                          ;get value from stack
    OR A
    RET Z                           ;if set to zero, branch to leave
;
    LD A, IYL                       ;otherwise get two's compliment of maximum speed
    NEG
    LD C, A
;
    LD A, (HL)                      ;subtract upward movement amount from contents
    SUB A, IXH                      ;of movement force, note that $01 is twice as large as $00,
    LD (HL), A                      ;thus it effectively undoes add we did earlier
;
    LD A, (DE)
    SBC A, $00                      ;subtract borrow from vertical speed and store
    LD (DE), A
;
    CP A, C                         ;compare vertical speed to two's compliment
    RET P                           ;if less negatively than preset maximum, skip this part
;
    LD A, (HL)                      ;check if fractional part is above certain amount,
    CP A, $80
    RET NC                          ;and if so, branch to leave
;   
    LD A, C                         ;keep vertical speed within maximum value
    LD (DE), A
    LD (HL), $FF                    ;clear fractional
    RET

;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;$01 - enemy buffer offset

FireballEnemyCollision:
    LD L, <Fireball_State
    LD A, (HL)
    OR A
    RET Z
    RET M
;
    LD A, (FrameCounter)
    SRL A
    RET C
;
    LD D, H
    LD H, $C0 + OBJ_SLOT5

FireballEnemyCDLoop:
    LD A, H
    LD (Temp_Bytes + $01), A
    PUSH DE
;
    LD L, <Enemy_State
    BIT 5, (HL)
    JP NZ, NoFToECol
;
    LD L, <Enemy_Flag
    LD A, (HL)
    OR A
    JP Z, NoFToECol
;
    LD L, <Enemy_ID
    CP A, $24
    JP C, GoombaDie
    CP A, $2B
    JP C, NoFToECol
;
GoombaDie:
    CP A, OBJECTID_Goomba
    JP NZ, NotGoomba
    LD L, <Enemy_State
    LD A, (HL)
    CP A, $02
    JP NC, NoFToECol
;
NotGoomba:
    LD L, <EnemyOffscrBitsMasked
    LD A, (HL)
    OR A
    JP NZ, NoFToECol
    CALL SprObjectCollisionCore
    LD HL, (ObjectOffset)
    JP NC, NoFToECol
    LD L, <Fireball_State
    SET 7, (HL)
    LD A, (Temp_Bytes + $01)
    LD H, A
    CALL HandleEnemyFBallCol
NoFToECol:
    POP DE
    LD A, (Temp_Bytes + $01)
    DEC A
    LD H, A
    CP A, $C0
    JP NZ, FireballEnemyCDLoop
    
ExitFBallEnemy:
    LD HL, (ObjectOffset)
    RET

.SECTION "BowserIdentities" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BowserIdentities:
    .db OBJECTID_Goomba, OBJECTID_GreenKoopa, OBJECTID_BuzzyBeetle
    .db OBJECTID_Spiny, OBJECTID_Lakitu, OBJECTID_Bloober
    .db OBJECTID_HammerBro, OBJECTID_Bowser
.ENDS

HandleEnemyFBallCol:
    CALL RelativeEnemyPosition
;
    LD A, (Temp_Bytes + $01)
    LD H, A
    LD L, <Enemy_Flag
    LD A, (HL)
    OR A
    JP P, ChkBuzzyBeetle
;
    AND A, %00001111
    ADD A, $C1
    LD H, A
    LD L, <Enemy_ID
    CP A, OBJECTID_Bowser
    JP Z, HurtBowser
;
    LD A, (Temp_Bytes + $01)
    LD H, A

ChkBuzzyBeetle:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_BuzzyBeetle
    RET Z
;
    CP A, OBJECTID_Bowser
    JP NZ, ChkOtherEnemies

HurtBowser:
    LD A, (BowserHitPoints)
    DEC A
    LD (BowserHitPoints), A
    RET NZ
;
    CALL InitVStf
    LD L, <Enemy_X_Speed
    LD (HL), A
    LD (EnemyFrenzyBuffer), A
;
    LD A, $FE
    LD L, <Enemy_Y_Speed
    LD (HL), A
;
    LD A, (WorldNumber)
    LD BC, BowserIdentities
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_ID
    LD (HL), A
;
    LD A, (WorldNumber)
    CP A, $03
    LD A, $20
    JP NC, SetDBSte
    OR A, $03
SetDBSte:
    LD L, <Enemy_State
    LD (HL), A
;
    ;lda #Sfx_BowserFall
    ;sta Square2SoundQueue
;
    LD A, (Temp_Bytes + $01)
    LD H, A
;
    LD A, $09
    JP EnemySmackScore

ChkOtherEnemies:
    CP A, OBJECTID_BulletBill_FrenzyVar
    RET Z
    CP A, OBJECTID_Podoboo
    RET Z
    CP A, $15
    RET NC

ShellOrBlockDefeat:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_PiranhaPlant
    JP NZ, StnE
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    ADD A, $19 ;$18      ; (+1 due to carry being set and 6502 code using 'adc' without 'clc' beforehand) 
    LD (HL), A
;
StnE:
    CALL ChkToStunEnemies
;
    LD L, <Enemy_State
    LD A, (HL)
    AND A, %00011111
    OR A, %00100000
    LD (HL), A
;
    LD C, $02
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_HammerBro
    JP NZ, GoombaPoints
    LD C, $06

GoombaPoints:
    CP A, OBJECTID_Goomba
    LD A, C
    JP NZ, EnemySmackScore
    LD A, $01

EnemySmackScore:
    CALL SetupFloateyNumber
    LD A, SNDID_KICK
    LD (SFXTrack0.SoundQueue), A
    RET

;-------------------------------------------------------------------------------------

PlayerHammerCollision:
    LD A, (FrameCounter)
    RRCA
    RET NC
;
    LD A, (TimerControl)
    LD C, A
    LD A, (Misc_OffscrBits)
    RET NZ
;
    LD D, H
    CALL PlayerCollisionCore
    LD HL, (ObjectOffset)
    JP NC, ClHCol
;
    LD L, <Misc_Collision_Flag
    LD A, (HL)
    RET NZ
;
    LD (HL), $01
    LD L, <Misc_X_Speed
    LD A, (HL)
    NEG
    LD (HL), A
;
    LD A, (StarInvincibleTimer)
    OR A
    RET NZ
;
    JP InjurePlayer
;
ClHCol:
    LD L, <Misc_Collision_Flag
    LD (HL), $00
    RET

;-------------------------------------------------------------------------------------

HandlePowerUpCollision:
    CALL EraseEnemyObject
;
    LD A, $06
    CALL SetupFloateyNumber
;
    LD A, SNDID_POWERUP
    LD (SFXTrack1.SoundQueue), A
;
    LD A, (PowerUpType)
    CP A, $02
    JP C, Shroom_Flower_PUp
    CP A, $03
    JP Z, SetFor1Up
;
    LD A, $23
    LD (StarInvincibleTimer), A
;
    ;LD A, (SndHurryUpFlag)
    ;ADD A, SNDID_INVINCIBLE
    LD A, SNDID_INVINCIBLE
    LD (MusicTrack0.SoundQueue), A 
    RET


Shroom_Flower_PUp:
    LD A, (PlayerStatus)
    OR A
    JP Z, UpToSuper
;
    CP A, $01
    RET NZ
;
    LD A, $02
    LD (PlayerStatus), A
    CALL GetPlayerColors
;
    LD A, $0C
    JP UpToFiery

SetFor1Up:
    LD L, <FloateyNum_Control
    LD (HL), $0B
    RET

UpToSuper:
    LD A, $01
    LD (PlayerStatus), A
    LD A, $09

UpToFiery:
    LD C, $00
    JP SetPRout

;--------------------------------

.SECTION "KickedShellXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
KickedShellXSpdData:
    .db $30, $d0
.ENDS

.SECTION "DemotedKoopaXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
DemotedKoopaXSpdData:
    .db $08, $f8
.ENDS

PlayerEnemyCollision:
    LD A, (FrameCounter)
    RRCA
    RET C
;
    CALL CheckPlayerVertical
    RET NC
;
    LD L, <EnemyOffscrBitsMasked
    LD A, (HL)
    OR A
    RET NZ
;
    LD A, (GameEngineSubroutine)
    CP A, $08
    RET NZ
;
    LD L, <Enemy_State
    BIT 5, (HL)
    RET NZ
;
    CALL GetEnemyBoundBoxOfs
    CALL PlayerCollisionCore
    LD HL, (ObjectOffset)
    JP C, CheckForPUpCollision
;
    LD L, <Enemy_CollisionBits
    LD A, (HL)
    AND A, %11111110
    LD (HL), A
    RET

CheckForPUpCollision:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_PowerUpObject
    JP Z, HandlePowerUpCollision
;
    LD A, (StarInvincibleTimer)
    OR A
    JP NZ, ShellOrBlockDefeat

HandlePECollisions:
    LD L, <Enemy_CollisionBits
    LD A, (HL)
    AND A, %00000001
    LD L, <EnemyOffscrBitsMasked
    OR A, (HL)
    RET NZ
;
    LD L, <Enemy_CollisionBits
    SET 0, (HL)
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Spiny
    JP Z, ChkForPlayerInjury
    CP A, OBJECTID_PiranhaPlant
    JP Z, InjurePlayer
    CP A, OBJECTID_Podoboo
    JP Z, InjurePlayer
    CP A, OBJECTID_BulletBill_CannonVar
    JP Z, ChkForPlayerInjury
    CP A, $15
    JP NC, InjurePlayer
    LD A, (AreaType)
    OR A
    JP Z, InjurePlayer
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    JP M, ChkForPlayerInjury
    AND A, %00000111
    CP A, $02
    JP C, ChkForPlayerInjury
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Goomba
    RET Z
;
    LD A, SNDID_KICK                ;play smack enemy sound
    LD (SFXTrack0.SoundQueue), A
;
    LD L, <Enemy_State
    SET 7, (HL)
;
    CALL EnemyFacePlayer
;
    LD A, C
    LD BC, KickedShellXSpdData
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_X_Speed
    LD (HL), A
;
    LD A, (StompChainCounter)
    ADD A, $03
    LD (Temp_Bytes + $00), A
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    CP A, $03
    LD A, (Temp_Bytes + $00)
    JP NC, SetupFloateyNumber
    LD BC, KickedShellPtsData
    addAToBC8_M
    LD A, (BC)
    JP SetupFloateyNumber

.SECTION "KickedShellPtsData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
KickedShellPtsData:
    .db $0a, $06, $04
.ENDS

ChkForPlayerInjury:
    LD A, (Player_Y_Speed)
    OR A
    JP M, ChkInj
    JP NZ, EnemyStomped
ChkInj:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Bloober
    JP C, ChkETmrs
    LD A, (Player_Y_Position)
    ADD A, $0C
    LD L, <Enemy_Y_Position
    CP A, (HL)
    JP C, EnemyStomped
ChkETmrs:
    LD A, (StompTimer)
    OR A
    JP NZ, EnemyStomped
    LD A, (InjuryTimer)
    OR A
    JP NZ, ExInjColRoutines
    LD A, (Enemy_Rel_XPos)
    LD C, A
    LD A, (Player_Rel_XPos)
    CP A, C
    JP NC, ChkEnemyFaceRight
;
    LD L, <Enemy_MovingDir
    LD A, (HL)
    CP A, $01
    JP Z, LInj

InjurePlayer:
    LD A, (InjuryTimer)
    OR A
    JP NZ, ExInjColRoutines

ForceInjury:
    LD A, (PlayerStatus)
    OR A
    JP Z, KillPlayer
;
    XOR A
    LD (PlayerStatus), A
    LD A, $08
    LD (InjuryTimer), A
;
    LD A, SNDID_PIPE
    LD (SFXTrack0.SoundQueue), A
;
    CALL GetPlayerColors
    LD A, $0A
SetKRout:
    LD C, $01
SetPRout:
    LD (GameEngineSubroutine), A
    LD A, C
    LD (Player_State), A
    XOR A
    LD (ScrollAmount), A
    DEC A
    LD (TimerControl), A

ExInjColRoutines:
    LD HL, (ObjectOffset)
    RET

KillPlayer:
    LD (Player_X_Speed), A
;
    LD A, SNDID_DEATH
    LD (MusicTrack0.SoundQueue), A    ; EVENT
;
    LD A, $FC
    LD (Player_Y_Speed), A
    LD A, $0B
    JP SetKRout

.SECTION "StompedEnemyPtsData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
StompedEnemyPtsData:
    .db $02, $06, $05, $06
.ENDS

EnemyStomped:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Spiny
    JP Z, InjurePlayer
;  
    LD A, SNDID_SWIM
    LD (SFXTrack0.SoundQueue), A
;
    LD L, <Enemy_ID
    LD A, (HL)
    LD C, $00
    CP A, OBJECTID_FlyingCheepCheep
    JP Z, EnemyStompedPts
    CP A, OBJECTID_BulletBill_FrenzyVar
    JP Z, EnemyStompedPts
    CP A, OBJECTID_BulletBill_CannonVar
    JP Z, EnemyStompedPts
    CP A, OBJECTID_Podoboo
    JP Z, EnemyStompedPts
    INC C
    CP A, OBJECTID_HammerBro
    JP Z, EnemyStompedPts
    INC C
    CP A, OBJECTID_Lakitu
    JP Z, EnemyStompedPts
    INC C
    CP A, OBJECTID_Bloober
    JP NZ, ChkForDemoteKoopa

EnemyStompedPts:
    LD A, C
    LD BC, StompedEnemyPtsData
    addAToBC8_M
    LD A, (BC)
    CALL SetupFloateyNumber
;
    LD L, <Enemy_MovingDir
    LD A, (HL)
    PUSH AF
    CALL SetStun
    POP AF
    LD L, <Enemy_MovingDir
    LD (HL), A
;
    LD A, %00100000
    LD L, <Enemy_State
    LD (HL), A
;
    CALL InitVStf
    LD L, <Enemy_X_Speed
    LD (HL), A
    LD A, $FD
    LD (Player_Y_Speed), A
    RET

ChkForDemoteKoopa:
    CP A, $09
    JP C, HandleStompedShellE
;
    AND A, %00000001
    LD L, <Enemy_ID
    LD (HL), A
;
    LD L, <Enemy_State
    LD (HL), $00
;
    LD A, $03
    CALL SetupFloateyNumber
;
    CALL InitVStf
    CALL EnemyFacePlayer
    LD A, C
    LD BC, DemotedKoopaXSpdData
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_X_Speed
    LD (HL), A
    JP SBnce

;RevivalRateData:
;    .db $10, $0b

HandleStompedShellE:
    LD L, <Enemy_State
    LD (HL), $04
;
    LD A, (StompChainCounter)
    INC A
    LD (StompChainCounter), A
    LD C, A
    LD A, (StompTimer)
    ADD A, C
    CALL SetupFloateyNumber
;
    LD A, (StompTimer)
    INC A
    LD (StompTimer), A
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (PrimaryHardMode)
    OR A
    LD A, $10
    JP Z, +
    LD A, $0B
+:
    LD (BC), A
;
SBnce:
    LD A, $FC
    LD (Player_Y_Speed), A
    RET

ChkEnemyFaceRight:
    LD L, <Enemy_MovingDir
    LD A, (HL)
    CP A, $01
    JP NZ, InjurePlayer
LInj:
    CALL EnemyTurnAround
    JP InjurePlayer

EnemyFacePlayer:
    LD C, $01
    CALL PlayerEnemyDiff
    JP P, SFcRt
    INC C
SFcRt:
    LD L, <Enemy_MovingDir
    LD (HL), C
    DEC C
    RET

SetupFloateyNumber:
    LD L, <FloateyNum_Control
    LD (HL), A
    LD L, <FloateyNum_Timer
    LD (HL), $30
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD L, <FloateyNum_Y_Pos
    LD (HL), A
;
    LD A, (Enemy_Rel_XPos)
    LD L, <FloateyNum_X_Pos
    LD (HL), A
    RET

;-------------------------------------------------------------------------------------
;$01 - used to hold enemy offset for second enemy

.SECTION "SetBitsMask" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
SetBitsMask:
    .db %10000000, %01000000, %00100000, %00010000, %00001000, %00000100, %00000010
.ENDS

.SECTION "ClearBitsMask" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
ClearBitsMask:
    .db %01111111, %10111111, %11011111, %11101111, %11110111, %11111011, %11111101
.ENDS

EnemiesCollision:
    LD A, (FrameCounter)
    RRCA
    RET NC
;
    LD A, (AreaType)
    OR A
    RET Z
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $15
    JP NC, ExitECRoutine
;
    CP A, OBJECTID_Lakitu
    JP Z, ExitECRoutine
;
    CP A, OBJECTID_PiranhaPlant
    JP Z, ExitECRoutine
;
    LD L, <EnemyOffscrBitsMasked
    LD A, (HL)
    OR A
    JP NZ, ExitECRoutine
;
    CALL GetEnemyBoundBoxOfs
    DEC H
    LD A, H
    CP A, $C0
    JP Z, ExitECRoutine
;
ECLoop:
    LD A, H
    LD (Temp_Bytes + $01), A
    PUSH DE
;
    LD L, <Enemy_Flag
    LD A, (HL)
    OR A
    JP Z, ReadyNextEnemy
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $15
    JP NC, ReadyNextEnemy
;
    CP A, OBJECTID_Lakitu
    JP Z, ReadyNextEnemy
;
    CP A, OBJECTID_PiranhaPlant
    JP Z, ReadyNextEnemy
;
    LD L, <EnemyOffscrBitsMasked
    LD A, (HL)
    OR A
    JP NZ, ReadyNextEnemy
;
    CALL SprObjectCollisionCore
    LD HL, (ObjectOffset)
    LD A, (Temp_Bytes + $01)
    LD D, A
    JP NC, NoEnemyCollision
;
    LD E, <Enemy_State
    LD L, <Enemy_State
    LD A, (DE)
    OR A, (HL)
    AND A, %10000000
    JP NZ, YesEC
;
    LD A, H
    SUB A, $C1
    LD BC, SetBitsMask
    addAToBC8_M
    LD A, (BC)
    LD C, A
    LD E, <Enemy_CollisionBits
    LD A, (DE)
    AND A, C
    JP NZ, ReadyNextEnemy
    LD A, (DE)
    OR A, C
    LD (DE), A
;
YesEC:
    CALL ProcEnemyCollisions
    JP ReadyNextEnemy

NoEnemyCollision:
    LD A, H
    SUB A, $C1
    LD BC, ClearBitsMask
    addAToBC8_M
    LD A, (BC)
    LD C, A
    LD E, <Enemy_CollisionBits
    LD A, (DE)
    AND A, C
    LD (DE), A

ReadyNextEnemy:
    POP DE
    LD A, (Temp_Bytes + $01)
    DEC A
    LD H, A
    CP A, $C0
    JP NZ, ECLoop

ExitECRoutine:
    LD HL, (ObjectOffset)
    RET

ProcEnemyCollisions:
    LD E, <Enemy_State
    LD L, <Enemy_State
    LD A, (DE)
    OR A, (HL)
    AND A, %00100000
    RET NZ
;
    LD L, <Enemy_State
    LD A, (HL)
    CP A, $06
    JP C, ProcSecondEnemyColl
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_HammerBro
    RET Z
;
    LD A, (DE)
    ADD A, A
    JP NC, ShellCollisions
;
    LD A, $06
    CALL SetupFloateyNumber
    CALL ShellOrBlockDefeat
    LD A, (Temp_Bytes + $01)
    LD D, A

ShellCollisions:
    LD H, D
    CALL ShellOrBlockDefeat
;
    LD HL, (ObjectOffset)
    LD L, <ShellChainCounter
    LD A, (HL)
    ADD A, $04
    LD HL, (Temp_Bytes + $00)   ; $01
    CALL SetupFloateyNumber
    LD HL, (ObjectOffset)
    LD L, <ShellChainCounter
    INC (HL)
    RET

ProcSecondEnemyColl:
    LD E, <Enemy_State
    LD A, (DE)
    CP A, $06
    JP C, MoveEOfs
;
    LD E, <Enemy_ID
    LD A, (DE)
    CP A, OBJECTID_HammerBro
    RET Z
;
    CALL ShellOrBlockDefeat
;
    LD DE, (Temp_Bytes + $00)   ; $01
    LD E, <ShellChainCounter
    LD A, (DE)
    ADD A, $04
    LD HL, (ObjectOffset)
    CALL SetupFloateyNumber
;
    LD HL, (Temp_Bytes + $00)   ; $01
    LD L, <ShellChainCounter
    INC (HL)
    RET

MoveEOfs:
    LD H, D
    CALL EnemyTurnAround
    LD HL, (ObjectOffset)

EnemyTurnAround:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_PiranhaPlant
    RET Z
    CP A, OBJECTID_Lakitu
    RET Z
    CP A, OBJECTID_HammerBro
    RET Z
    CP A, OBJECTID_Spiny
    JP Z, RXSpd
    CP A, OBJECTID_GreenParatroopaJump
    JP Z, RXSpd
    CP A, $07
    RET NC 
;
RXSpd:
    LD L, <Enemy_X_Speed
    LD A, (HL)
    NEG
    LD (HL), A
    LD L, <Enemy_MovingDir
    LD A, (HL)
    XOR A, %00000011
    LD (HL), A
    RET

;-------------------------------------------------------------------------------------
;$00 - vertical position of platform

LargePlatformCollision:
    LD L, <PlatformCollisionFlag
    LD (HL), $FF
;
    LD A, (TimerControl)
    OR A
    JP NZ, ExLPC
;
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    JP M, ExLPC
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $24
    JP NZ, ChkForPlayerC_LargeP
;
    LD L, <Enemy_State
    LD A, (HL)
    ADD A, $C1
    LD H, A
    CALL ChkForPlayerC_LargeP

ChkForPlayerC_LargeP:
    CALL CheckPlayerVertical
    JP NC, ExLPC
;
    LD A, H
    CALL GetEnemyBoundBoxOfsArg
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD (Temp_Bytes + $00), A
    PUSH HL
    CALL PlayerCollisionCore
    POP HL
    CALL C, ProcLPlatCollisions
ExLPC:
    LD HL, (ObjectOffset)
    RET

;--------------------------------
;$00 - counter for bounding boxes

SmallPlatformCollision:
    LD A, (TimerControl)
    OR A
    JP NZ, ExSPC
;
    LD L, <PlatformCollisionFlag
    LD (HL), A
;
    CALL CheckPlayerVertical
    JP NC, ExSPC
;
    LD A, $02
    LD (Temp_Bytes + $00), A

ChkSmallPlatLoop:
    LD HL, (ObjectOffset)
    CALL GetEnemyBoundBoxOfs
    AND A, %00000010
    JP NZ, ExSPC
;
    LD E, <BoundingBox_UL_YPos
    LD A, (DE)
    CP A, $20
    JP C, MoveBoundBox
;
    CALL PlayerCollisionCore
    JP C, ProcSPlatCollisions

MoveBoundBox:
    LD E, <BoundingBox_UL_YPos
    LD A, (DE)
    ADD A, $80
    LD (DE), A
;
    LD E, <BoundingBox_DR_YPos
    LD A, (DE)
    ADD A, $80
    LD (DE), A
;
    LD HL, Temp_Bytes + $00
    DEC (HL)
    JP NZ, ChkSmallPlatLoop
ExSPC:
    LD HL, (ObjectOffset)
    RET

;--------------------------------

ProcSPlatCollisions:
    LD HL, (ObjectOffset)

ProcLPlatCollisions:
    LD A, (BoundingBox_UL_YPos)
    LD C, A
    LD E, <BoundingBox_DR_YPos
    LD A, (DE)
    SUB A, C
    CP A, $04
    JP NC, ChkForTopCollision
;
    LD A, (Player_Y_Speed)
    OR A
    JP P, ChkForTopCollision
;
    LD A, $01
    LD (Player_Y_Speed), A

ChkForTopCollision:
    LD E, <BoundingBox_UL_YPos
    LD A, (DE)
    LD C, A
    LD A, (BoundingBox_DR_YPos)
    SUB A, C
    CP A, $06
    JP NC, PlatformSideCollisions
;
    LD A, (Player_Y_Speed)
    OR A
    JP M, PlatformSideCollisions
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $2B
    LD A, (Temp_Bytes + $00)
    JP Z, SetCollisionFlag
    LD A, (HL)
    CP A, $2C
    LD A, (Temp_Bytes + $00)
    JP Z, SetCollisionFlag
    LD A, H
    SUB A, $C1

SetCollisionFlag:
    LD HL, (ObjectOffset)
    LD L, <PlatformCollisionFlag
    LD (HL), A
    XOR A
    LD (Player_State), A
    RET

PlatformSideCollisions:
    LD A, $01
    LD (Temp_Bytes + $00), A
;
    LD E, <BoundingBox_UL_XPos
    LD A, (DE)
    LD C, A
    LD A, (BoundingBox_DR_XPos)
    SUB A, C
    CP A, $08
    JP C, SideC
;
    LD A, $02
    LD (Temp_Bytes + $00), A
    LD A, (BoundingBox_UL_XPos)
    LD C, A
    LD E, <BoundingBox_DR_XPos
    LD A, (DE)
    SUB A, C
    CP A, $09
    JP NC, NoSideC
SideC:
    CALL ImpedePlayerMove
NoSideC:
    LD HL, (ObjectOffset)
    RET

;-------------------------------------------------------------------------------------

;.SECTION "PlayerPosSPlatData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
;PlayerPosSPlatData:
;    .db $80, $00
;.ENDS

PositionPlayerOnS_Plat:
    ;LD C, A
    ;LD BC, PlayerPosSPlatData
    ;addAToBC8_M
    ;LD A, (BC)
    OR A
    LD A, $80
    JP Z, +
    XOR A
+:
    LD L, <Enemy_Y_Position
    ADD A, (HL)
    JP PositionPlayerOnVPlat@SkipY

PositionPlayerOnVPlat:
    LD L, <Enemy_Y_Position
    LD A, (HL)
@SkipY:
    LD C, A
;
    LD A, (GameEngineSubroutine)
    CP A, $0B
    RET Z
;
    LD L, <Enemy_Y_HighPos
    LD A, (HL)
    CP A, $01
    RET NZ
;
    LD A, C
    SUB A, $20
    LD (Player_Y_Position), A
    LD A, (Enemy_Y_HighPos)
    SBC A, $00
    LD (Player_Y_HighPos), A
    XOR A
    LD (Player_Y_Speed), A
    LD (Player_Y_MoveForce), A
    RET

;-------------------------------------------------------------------------------------

;   NZ, NC = ONSCREEN
;   Z, C = OFFSCREEN
CheckPlayerVertical:
    LD A, (Player_OffscrBits)
    CP A, $F0
    RET NC
;
    LD A, (Player_Y_HighPos)
    DEC A
    RET NZ
;
    LD A, (Player_Y_Position)
    CP A, $D0
    RET

;-------------------------------------------------------------------------------------

GetEnemyBoundBoxOfs:
    LD A, (ObjectOffset + 1)

GetEnemyBoundBoxOfsArg:
    LD D, A
    LD A, (Enemy_OffscrBits)
    AND A, %00001111
    CP A, %00001111
    RET

;-------------------------------------------------------------------------------------
;$00-$01 - used to hold many values, essentially temp variables
;$04(IXH) - holds lower nybble of vertical coordinate from block buffer routine
;$eb($08) - used to hold block buffer adder

; BLOCK BUFFER TEMP VARS
;$02(IXL) - modified y coordinate
;$03(NOT USED) - stores metatile involved in block buffer collisions
;$04(IXH) - comes in with offset to block buffer adder data, goes out with low nybble x/y coordinate
;$05(IYL) - modified x coordinate
;$06-$07(DE) - block buffer address

.SECTION "PlayerBGUpperExtent" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PlayerBGUpperExtent:
    .db $20, $10
    ;.db $08, $00        ; big, small or crouch
.ENDS

.SECTION "BlockBufferAdderData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BlockBufferAdderData:
    .db $00, $07, $0e   ; big, swim, small or crouch
.ENDS

PlayerBGCollision:
    LD A, (DisableCollisionDet)         ;if collision detection disabled flag set,
    OR A
    RET NZ                              ;branch to leave
;
    LD A, (GameEngineSubroutine)        ;if running routine #11 or $0b
    CP A, $0B
    RET Z                               ;branch to leave
    CP A, $04
    RET C                               ;if running routines $00-$03 branch to leave
;
    LD A, (SwimmingFlag)                ;if swimming flag set,
    OR A
    LD A, $01                           ;load default player state for swimming
    JP NZ, SetPSte                      ;branch ahead to set default state
;
    LD A, (Player_State)                ;if player in normal state,
    OR A
    JP Z, SetFallS                      ;branch to set default state for falling
;
    CP A, $03
    JP NZ, ChkOnScr                     ;if in any other state besides climbing, skip to next part
SetFallS:
    LD A, $02                           ;load default player state for falling
SetPSte:
    LD (Player_State), A                ;set whatever player state is appropriate
ChkOnScr:
    LD A, (Player_Y_HighPos)
    CP A, $01                           ;check player's vertical high byte for still on the screen
    RET NZ                              ;branch to leave if not
;
    LD A, $FF                           ;initialize player's collision flag
    LD (Player_CollisionBits), A
;
    LD A, (Player_Y_Position)           ;check player's vertical coordinate
    CP A, $CF - SMS_PIXELYOFFSET        ;if not too close to the bottom of screen, continue
    RET NC                              ;otherwise leave

ChkCollSize:
    LD DE, BlockBufferAdderData + $02   ;otherwise leave
    LD A, (CrouchingFlag)
    OR A
    JP NZ, GBBAdr                       ;if player crouching, skip ahead
;
    LD A, (PlayerSize)
    OR A
    JP NZ, GBBAdr                       ;if player small, skip ahead
;
    DEC E                               ;otherwise decrement offset for big player not crouching
    LD A, (SwimmingFlag)
    OR A
    JP NZ, GBBAdr                       ;if swimming flag set, skip ahead
;
    DEC E                               ;otherwise decrement offset
GBBAdr:
    LD A, (DE)                          ;get value using offset
    LD (Temp_Bytes + $08), A
    LD C, A                             ;put value into Y, as offset for block buffer routine
    LD HL, PlayerBGUpperExtent
    LD A, (PlayerSize)                  ;use player's size as offset
    addAToHL8_M
    LD A, (CrouchingFlag)               ;use crouching flag as offset
    addAToHL8_M
HeadChk:
    LD A, (Player_Y_Position)           ;get player's vertical coordinate
    ADD A, SMS_PIXELYOFFSET
    CP A, (HL)                          ;compare with upper extent value based on offset
    JP C, DoFootCheck                   ;if player is too high, skip this part
;
    CALL BlockBufferColli_Head          ;do player-to-bg collision detection on top of
    JP Z, DoFootCheck                   ;player, and branch if nothing above player's head
;
    CALL CheckForCoinMTiles             ;check to see if player touched coin with their head
    JP Z, HandleCoinMetatile            ;if so, branch to some other part of code
;
    LD A, (Player_Y_Speed)              ;check player's vertical speed
    OR A
    JP P, DoFootCheck                   ;if player not moving upwards, branch elsewhere
;
    LD A, IXH                           ;check lower nybble of vertical coordinate returned
    CP A, $04                           ;from collision detection routine
    JP C, DoFootCheck                   ;if low nybble < 4, branch
;
    LD A, (DE)                          ;(SMS)reload A with MT returned from BlockBufferColli_Head
    CALL CheckForSolidMTiles            ;check to see what player's head bumped on
    JP NC, SolidOrClimb                 ;if player collided with solid metatile, branch
;
    LD A, (AreaType)                    ;otherwise check area type
    OR A
    JP Z, NYSpd                         ;if water level, branch ahead
;
    LD A, (BlockBounceTimer)            ;if block bounce timer not expired,
    OR A
    JP NZ, NYSpd                        ;branch ahead, do not process collision
;
    LD A, (DE)
    CALL PlayerHeadCollision            ;otherwise do a sub to process collision
    JP DoFootCheck                      ;jump ahead to skip these other parts here


SolidOrClimb:
    CP A, MT_VINEBLANK                  ;if climbing metatile,
    JP Z, NYSpd                         ;branch ahead and do not play sound
    LD A, SNDID_BUMP
    LD (SFXTrack0.SoundQueue), A
NYSpd:
    LD A, $01                           ;set player's vertical speed to nullify
    LD (Player_Y_Speed), A              ;jump or swim

DoFootCheck:
    LD A, (Temp_Bytes + $08)
    LD C, A
    LD A, (Player_Y_Position)
    CP A, $CF - SMS_PIXELYOFFSET        ;check to see how low player is
    JP NC, DoPlayerSideCheck            ;if player is too far down on screen, skip all of this
;
    CALL BlockBufferColli_Feet          ;do player-to-bg collision detection on bottom left of player
    CALL CheckForCoinMTiles             ;check to see if player touched coin with their left foot
    JP Z, HandleCoinMetatile            ;if so, branch to some other part of code
;
    PUSH AF                             ;save bottom left metatile to stack
    CALL BlockBufferColli_Feet          ;do player-to-bg collision detection on bottom right of player
    LD (Temp_Bytes + $00), A            ;save bottom right metatile here
    POP AF
    LD (Temp_Bytes + $01), A            ;pull bottom left metatile and save here
    OR A
    JP NZ, ChkFootMTile                 ;if anything here, skip this part
;
    LD A, (Temp_Bytes + $00)            ;otherwise check for anything in bottom right metatile
    OR A
    JP Z, DoPlayerSideCheck             ;and skip ahead if not
;
    CALL CheckForCoinMTiles             ;check to see if player touched coin with their right foot
    JP Z, HandleCoinMetatile            ;if so, erase coin and award to player 1 coin

ChkFootMTile:
    CALL CheckForClimbMTiles            ;check to see if player landed on climbable metatiles
    JP NC, DoPlayerSideCheck            ;if so, branch
;
    LD HL, Player_Y_Speed               ;check player's vertical speed
    BIT 7, (HL)
    JP NZ, DoPlayerSideCheck            ;if player moving upwards, branch
;   
    CP A, MT_AXE
    JP Z, HandleAxeMetatile             ;if player touched axe, jump to set modes of operation
;
    CALL ChkInvisibleMTiles             ;do sub to check for hidden coin or 1-up blocks
    JP Z, DoPlayerSideCheck             ;if either found, branch
;
    LD C, A
    LD A, (JumpspringAnimCtrl)          ;if jumpspring animating right now,
    OR A
    JP NZ, InitSteP                     ;branch ahead
;
    LD A, IXH                           ;check lower nybble of vertical coordinate returned
    CP A, $05                           ;from collision detection routine
    JP C, LandPlyr                      ;if lower nybble < 5, branch
;
    LD A, (Player_MovingDir)
    LD (Temp_Bytes + $00), A            ;use player's moving direction as temp variable
    JP ImpedePlayerMove                 ;jump to impede player's movement in that direction
LandPlyr:
    LD A, C ; need mt back
    CALL ChkForLandJumpSpring           ;do sub to check for jumpspring metatiles and deal with it
    LD A, (Player_Y_Position)
    AND A, $F0                          ;mask out lower nybble of player's vertical position
    ADD A, $08
    LD (Player_Y_Position), A           ;and store as new vertical position to land player properly
    CALL HandlePipeEntry                ;do sub to process potential pipe entry
    XOR A
    LD (Player_Y_Speed), A              ;initialize vertical speed and fractional
    LD (Player_Y_MoveForce), A          ;movement force to stop player's vertical movement
    LD (StompChainCounter), A           ;initialize enemy stomp counter
InitSteP:
    XOR A
    LD (Player_State), A                ;set player's state to normal

DoPlayerSideCheck:
    LD A, (Temp_Bytes + $08)
    LD C, A
    INC C
    INC C                               ;increment offset 2 bytes to use adders for side collisions
    LD A, $02                           ;set value here to be used as counter
    LD (Temp_Bytes + $00), A

SideCheckLoop:
    INC C                               ;move onto the next one
    LD A, C
    LD (Temp_Bytes + $08), A
;
    LD A, (Player_Y_Position)
    CP A, $20 - SMS_PIXELYOFFSET        ;check player's vertical position
    JP C, BHalf                         ;if player is in status bar area, branch ahead to skip this part
    CP A, $E4 - SMS_PIXELYOFFSET
    RET NC                              ;branch to leave if player is too far down
    CALL BlockBufferColli_Side          ;do player-to-bg collision detection on one half of player
    JP Z, BHalf                         ;branch ahead if nothing found
    CP A, MT_SIDEPIPE_END_TOP           ;otherwise check for pipe metatiles
    JP Z, BHalf                         ;if collided with sideways pipe (top), branch ahead
    CP A, MT_WATERPIPE_TOP              
    JP Z, BHalf                         ;if collided with water pipe (top), branch ahead
    CALL CheckForClimbMTiles            ;do sub to see if player bumped into anything climbable
    JP C, CheckSideMTiles               ;if not, branch to alternate section of code
;
BHalf:
    LD A, (Temp_Bytes + $08)
    LD C, A
    INC C                               ;increment it
    LD A, (Player_Y_Position)           ;get player's vertical position
    ADD A, SMS_PIXELYOFFSET
    CP A, $08 ;$00;$08 - SMS_PIXELYOFFSET
    RET C                               ;if too high, branch to leave
    CP A, $D0 ;- SMS_PIXELYOFFSET
    RET NC                              ;if too low, branch to leave
    CALL BlockBufferColli_Side          ;do player-to-bg collision detection on other half of player
    JP NZ, CheckSideMTiles              ;if something found, branch
    LD HL, Temp_Bytes + $00
    DEC (HL)                            ;otherwise decrement counter
    JP NZ, SideCheckLoop                ;run code until both sides of player are checked
    RET

CheckSideMTiles:
    CALL ChkInvisibleMTiles             ;check for hidden or coin 1-up blocks
    RET Z                               ;branch to leave if either found
;
    CALL CheckForClimbMTiles            ;check for climbable metatiles
    JP NC, HandleClimbing               ;if found, jump to handle climbing
;
    CALL CheckForCoinMTiles             ;check to see if player touched coin
    JP Z, HandleCoinMetatile            ;if so, execute code to erase coin and award to player 1 coin
;
    CALL ChkJumpspringMetatiles         ;check for jumpspring metatiles
    JP NZ, ChkPBtm                      ;if not found, branch ahead to continue code
;
    LD A, (JumpspringAnimCtrl)          ;otherwise check jumpspring animation control
    OR A
    RET NZ                              ;branch to leave if set
;
    JP ImpedePlayerMove                 ;otherwise jump to impede player's movement
ChkPBtm:
    LD C, A
    LD A, (Player_State)                ;get player's state
    OR A                                ;check for player's state set to normal
    JP NZ, ImpedePlayerMove             ;if not, branch to impede player's movement
;
    LD A, (PlayerFacingDir)             ;get player's facing direction
    DEC A
    JP NZ, ImpedePlayerMove             ;if facing left, branch to impede movement
;
    LD A, C ; need to get tile id back
    CP A, MT_WATERPIPE_BOT              ;otherwise check for pipe metatiles
    JP Z, PipeDwnS                      ;if collided with sideways pipe (bottom), branch
    CP A, MT_SIDEPIPE_END_BOT           ;if collided with water pipe (bottom), continue
    JP NZ, ImpedePlayerMove             ;otherwise branch to impede player's movement
PipeDwnS:
    LD A, (Player_SprAttrib)            ;check player's attributes
    BIT 5, A
    JP NZ, PlyrPipe                     ;if already set, branch, do not play sound again
    LD A, SNDID_PIPE
    LD (SFXTrack0.SoundQueue), A
    LD A, (Player_SprAttrib)
PlyrPipe:
    OR A, %00100000
    LD (Player_SprAttrib), A            ;set background priority bit in player attributes
;
    LD A, (Player_X_Position)
    AND A, %00001111                    ;get lower nybble of player's horizontal coordinate
    JP Z, ChkGERtn                      ;if at zero, branch ahead to skip this part
;
    LD DE, AreaChangeTimerData          ;set default offset for timer setting data
    LD A, (ScreenLeft_PageLoc)          ;load page location for left side of screen
    OR A
    JP Z, SetCATmr                      ;if at page zero, use default offset
    INC E                               ;otherwise increment offset
SetCATmr:
    LD A, (DE)                          ;set timer for change of area as appropriate
    LD (ChangeAreaTimer), A
;
ChkGERtn:
    LD A, (GameEngineSubroutine)        ;get number of game engine routine running
    CP A, $07
    RET Z                               ;if running player entrance routine or
    CP A, $08                           ;player control routine, go ahead and branch to leave
    RET NZ
    LD A, $02
    LD (GameEngineSubroutine), A        ;otherwise set sideways pipe entry routine to run
    RET

.SECTION "AreaChangeTimerData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
AreaChangeTimerData:
    .db $a0, $34
.ENDS

;--------------------------------
;$02(IXL) - high nybble of vertical coordinate from block buffer
;$04(IXH) - low nybble of horizontal coordinate from block buffer
;$06-$07 - block buffer address

HandleCoinMetatile:
    CALL ErACM                          ;do sub to erase coin metatile from block buffer
    LD HL, CoinTallyFor1Ups             ;increment coin tally used for 1-up blocks
    INC (HL)
    JP GiveOneCoin                      ;update coin amount and tally on the screen

HandleAxeMetatile:
    XOR A
    LD (OperMode_Task), A               ;reset secondary mode
    LD A, $02
    LD (OperMode), A                    ;set primary mode to autoctrl mode
    LD A, $18
    LD (Player_X_Speed), A              ;set horizontal speed and continue to erase axe metatile
ErACM:
    LD DE, (Temp_Bytes + $06)
    LD A, IXL                           ;load vertical high nybble offset for block buffer
    addAToDE_M
    XOR A                               ;load blank metatile
    LD (DE), A                          ;store to remove old contents from block buffer
    LD HL, (Temp_Bytes + $06)           ;(SMS)put block buffer addr into HL for PutBlockMetatile
    JP RemoveCoin_Axe                   ;update the screen accordingly


;--------------------------------
;$02(IXL) - high nybble of vertical coordinate from block buffer
;$04(IXH) - low nybble of horizontal coordinate from block buffer
;$06-$07 - block buffer address

.SECTION "ClimbXPosAdder/ClimbPLocAdder" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
ClimbXPosAdder:
    .db $00 ; PADDING
    .db $f9, $07

ClimbPLocAdder:
    .db $ff, $00
.ENDS

.SECTION "FlagpoleYPosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
FlagpoleYPosData:
    ;.db $18, $22, $50, $68, $90
    .db $00, $0A, $38, $50, $78
.ENDS

HandleClimbing:
    LD A, IXH                           ;check low nybble of horizontal coordinate returned from
    CP A, $06                           ;collision detection routine against certain values, this
    RET C                               ;makes actual physical part of vine or flagpole thinner
    CP A, $0A                           ;than 16 pixels
    RET NC                              ;leave if too far left or too far right
    LD A, (DE)                          ;(SMS)get metatile id back from last call to BlockBufferColli_Side
    CP A, MT_FLAGPOLE_BALL              ;check climbing metatiles
    JP Z, FlagpoleCollision             ;branch if flagpole ball found
    CP A, MT_FLAGPOLE_SHAFT
    JP NZ, VineCollision                ;branch to alternate code if flagpole shaft not found

FlagpoleCollision:
    LD A, (GameEngineSubroutine)
    CP A, $05                           ;check for end-of-level routine running
    JP Z, PutPlayerOnVine               ;if running, branch to end of climbing code
    LD A, $01
    LD (PlayerFacingDir), A             ;set player's facing direction to right
    LD (ScrollLock), A
    ;LD HL, ScrollLock                   ;set scroll lock flag
    ;INC (HL)
    LD A, (GameEngineSubroutine)
    CP A, $04                           ;check for flagpole slide routine running
    JP Z, RunFR                         ;if running, branch to end of flagpole code here
    LD A, OBJECTID_BulletBill_CannonVar ;load identifier for bullet bills (cannon variant)
    CALL KillEnemies                    ;get rid of them
    LD A, SNDID_SILENCE
    LD (MusicTrack0.SoundQueue), A      ; EVENT
    LD A, SNDID_FLAGPOLE                ;load flagpole sound
    LD (FlagpoleSoundQueue), A
    LD HL, FlagpoleYPosData + $04       ;start at end of vertical coordinate data
    LD A, (Player_Y_Position)
    LD (FlagpoleCollisionYPos), A       ;store player's vertical coordinate here to be used later
    LD B, $04
ChkFlagpoleYPosLoop:
    CP A, (HL)                          ;compare with current vertical coordinate data
    JP NC, MtchF                        ;if player's => current, branch to use current offset
    DEC L                               ;otherwise decrement offset to use
    DJNZ ChkFlagpoleYPosLoop
    ;DEC B
    ;JP NZ, ChkFlagpoleYPosLoop          ;do this until all data is checked (use last one if all checked)
MtchF:
    LD A, B
    LD (FlagpoleScore), A               ;store offset here to be used later
RunFR:
    LD A, $04
    LD (GameEngineSubroutine), A        ;set value to run flagpole slide routine
    JP PutPlayerOnVine                  ;jump to end of climbing code
    
VineCollision:
    CP A, MT_VINEBLANK                  ;check for climbing metatile used on vines
    JP NZ, PutPlayerOnVine
    LD A, (Player_Y_Position)           ;check player's vertical coordinate
    CP A, $20 - SMS_PIXELYOFFSET        ;for being in status bar area
    JP NC, PutPlayerOnVine              ;branch if not that far up
    LD A, $01
    LD (GameEngineSubroutine), A        ;otherwise set to run autoclimb routine next frame

PutPlayerOnVine:
    LD A, $03                           ;set player state to climbing
    LD (Player_State), A
;
    XOR A                               ;nullify player's horizontal speed
    LD (Player_X_Speed), A              ;and fractional horizontal movement force
    LD (Player_X_MoveForce), A
;
    LD A, (Player_X_Position)           ;get player's horizontal coordinate
    LD HL, ScreenLeft_X_Pos
    SUB A, (HL)                         ;subtract from left side horizontal coordinate
    CP A, $10
    JP NC, SetVXPl                      ;if 16 or more pixels difference, do not alter facing direction
;
    LD A, $02
    LD (PlayerFacingDir), A             ;otherwise force player to face left
SetVXPl:
    LD A, (PlayerFacingDir)             ;get current facing direction, use as offset
    LD HL, ClimbXPosAdder
    addAToHL8_M
    LD A, (Temp_Bytes + $06)            ;get low byte of block buffer address
    ADD A, A                            ;move low nybble to high
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, (HL)                         ;add pixels depending on facing direction
    LD (Player_X_Position), A           ;store as player's horizontal coordinate
    LD A, (Temp_Bytes + $06)            ;get low byte of block buffer address again
    OR A
    RET NZ                              ;if not zero, branch
    INC L
    INC L                               ;ClimbPLocAdder
    LD A, (ScreenRight_PageLoc)         ;load page location of right side of screen
    ADD A, (HL)                         ;add depending on facing location
    LD (Player_PageLoc), A              ;store as player's page location
    RET

;--------------------------------

ChkInvisibleMTiles:
    CP A, MT_HIDDENBLK_COIN             ;check for hidden coin block
    RET Z                               ;branch to leave if found
    CP A, MT_HIDDENBLK_1UP              ;check for hidden 1-up block
    RET                                 ;leave with zero flag set if either found

;--------------------------------
;$00-$01 - used to hold bottom right and bottom left metatiles (in that order)
;$00 - used as flag by ImpedePlayerMove to restrict specific movement

ChkForLandJumpSpring:
    CALL ChkJumpspringMetatiles
    RET NZ
    LD A, $70
    LD (VerticalForce), A
    LD A, $F9
    LD (JumpspringForce), A
    LD A, $03
    LD (JumpspringTimer), A
    LD A, $01
    LD (JumpspringAnimCtrl), A
    RET

ChkJumpspringMetatiles:
    CP A, MT_SPRING_BLANK
    RET Z
    CP A, MT_SPRING_HALF
    RET

HandlePipeEntry:
    LD A, (Up_Down_Buttons)
    AND A, %00000100
    RET Z
;
    LD A, (Temp_Bytes + $00)
    CP A, $11
    RET NZ
;
    LD A, (Temp_Bytes + $01)
    CP A, $10
    RET NZ
;
    LD A, $30
    LD (ChangeAreaTimer), A
;
    LD A, $03
    LD (GameEngineSubroutine), A
;
    LD A, SNDID_PIPE
    LD (SFXTrack0.SoundQueue), A
;
    ;LD A, %00100000
    ;LD (Player_SprAttrib), A
;
    LD A, (WarpZoneControl)
    OR A
    RET Z
;
    AND A, %00000011
    ADD A, A
    ADD A, A
    LD HL, WarpZoneNumbers
    addAToHL8_M
    LD A, (Player_X_Position)
    CP A, $60
    JP C, GetWNum
    INC L
    CP A, $A0
    JP C, GetWNum
    INC L
GetWNum:
    LD A, (HL)
    DEC A
    LD (WorldNumber), A
    ADD A, A
    LD HL, WorldAddrOffsets
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    LD A, (HL)
    LD (AreaPointer), A
    LD A, SNDID_SILENCE
    LD (MusicTrack0.SoundQueue), A  ; EVENT
    XOR A
    LD (EntrancePage), A
    LD (AreaNumber), A
    LD (LevelNumber), A
    LD (AltEntranceControl), A
    INC A
    LD (Hidden1UpFlag), A
    LD (FetchNewGameTimerFlag), A
    RET

ImpedePlayerMove:
    LD B, $00
    LD HL, Temp_Bytes + $00
    LD C, (HL)
    DEC C
    JP NZ, RImpd
    INC C
    LD A, (Player_X_Speed)
    OR A
    JP M, ExIPM
    DEC B
    JP NXSpd
RImpd:
    LD C, $02
    LD A, (Player_X_Speed)
    CP A, $01
    JP P, ExIPM
    LD B, $01
NXSpd:
    LD A, $10
    LD (SideCollisionTimer), A
    XOR A
    LD (Player_X_Speed), A
    BIT 7, B
    JP Z, PlatF
    DEC A
PlatF:
    LD (HL), A
    LD A, (Player_X_Position)
    ADD A, B
    LD (Player_X_Position), A
    LD A, (Player_PageLoc)
    ADC A, (HL)
    LD (Player_PageLoc), A
ExIPM:
    LD HL, Player_CollisionBits
    LD A, C
    XOR A, $FF
    AND A, (HL)
    LD (HL), A
    RET

;--------------------------------

.SECTION "SolidMTileUpperExt" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
SolidMTileUpperExt:
    .db MT_WARPPIPE_TOP_LEFT, MT_SOLIDBLK_3D, MT_CLOUDGND, MT_EMPTYBLK
.ENDS

;   NC  - GREATER OR EQUAL
;   C   - LESS
CheckForSolidMTiles:
    PUSH AF                         ;save metatile value to stack
    AND A, %11000000                ;mask out all but 2 MSB
    RLCA                            ;shift and rotate d7-d6 to d1-d0
    RLCA
    LD BC, SolidMTileUpperExt       ;use as offset for metatile data
    addAToBC8_M
    LD A, (BC)
    LD B, A
    POP AF                          ;get original metatile value back
    CP A, B                         ;compare current metatile with solid metatiles
    RET

.SECTION "ClimbMTileUpperExt" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
ClimbMTileUpperExt:
    .db MT_FLAGPOLE_BALL, MT_UNUSEDFLAG, MT2_CLIMBSTART, MT3_CLIMBSTART
.ENDS
    
;   NC  - GREATER OR EQUAL
;   C   - LESS
CheckForClimbMTiles:
    PUSH AF                         ;save metatile value to stack
    AND A, %11000000                ;mask out all but 2 MSB
    RLCA                            ;shift and rotate d7-d6 to d1-d0
    RLCA
    LD BC, ClimbMTileUpperExt       ;use as offset for metatile data
    addAToBC8_M
    LD A, (BC)
    LD B, A
    POP AF                          ;get original metatile value back
    CP A, B                         ;compare current metatile with climbable metatiles
    RET

;   NZ  - NO COIN MT
;   Z   - COIN MT
CheckForCoinMTiles:
    CP A, MT_COIN                   ;check for regular coin
    JP Z, CoinSd                    ;branch if found
    CP A, MT_WATERCOIN              ;check for underwater coin
    RET NZ                          ;branch if neither coin was found
CoinSd:
    LD A, SNDID_COIN
    LD (SFXTrack1.SoundQueue), A
    RET


;-------------------------------------------------------------------------------------
;$06-$07 - address from block buffer routine

.SECTION "EnemyBGCStateData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
EnemyBGCStateData:
    .db $01, $01, $02, $02, $02, $05
.ENDS

.SECTION "EnemyBGCXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
EnemyBGCXSpdData:
    .db $10, $f0
.ENDS

EnemyToBGCollisionDet:
    LD L, <Enemy_State
    BIT 5, (HL)
    RET NZ
;
    CALL SubtEnemyYPos
    RET C
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Spiny
    JP NZ, DoIDCheckBGColl
;
    LD L, <Enemy_Y_Position
    LD A, (HL)
    CP A, $25 - SMS_PIXELYOFFSET
    RET C

DoIDCheckBGColl:
    CP A, OBJECTID_GreenParatroopaJump
    JP Z, EnemyJump
;
    CP A, OBJECTID_HammerBro
    JP Z, HammerBroBGColl
;
    CP A, OBJECTID_Spiny
    JP Z, YesIn
    CP A, OBJECTID_PowerUpObject
    JP Z, YesIn
;
    CP A, $07
    RET NC
;
YesIn:
    CALL ChkUnderEnemy
    JP Z, ChkForRedKoopa

;--------------------------------
;$02(IXL) - vertical coordinate from block buffer routine

HandleEToBGCollision:
    CALL ChkForNonSolids
    JP Z, ChkForRedKoopa
;
    CP A, MT_HITBLANK
    JP NZ, LandEnemyProperly
;
    LD A, IXL
    LD DE, (Temp_Bytes + $06)
    addAToDE_M
    XOR A
    LD (DE), A
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $15
    JP NC, ChkToStunEnemies
;
    CP A, OBJECTID_Goomba
    CALL Z, KillEnemyAboveBlock

GiveOEPoints:
    LD A, $01
    CALL SetupFloateyNumber

ChkToStunEnemies:
    CP A, $09
    JP C, SetStun
    CP A, $11
    JP NC, SetStun
    CP A, $0A
    JP C, Demote
    CP A, OBJECTID_PiranhaPlant
    JP C, SetStun
Demote:
    AND A, %00000001
    LD L, <Enemy_ID
    LD (HL), A
SetStun:
    LD L, <Enemy_State
    LD A, (HL)
    AND A, %11110000
    OR A, %00000010
    LD (HL), A
;
    LD L, <Enemy_Y_Position
    DEC (HL)
    DEC (HL)
;
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Bloober
    JP Z, SetWYSpd
    LD A, (AreaType)
    OR A
    LD A, $FD
    JP NZ, SetNotW
SetWYSpd:
    LD A, $FF
SetNotW:
    LD L, <Enemy_Y_Speed
    LD (HL), A
;
    LD C, $01
    CALL PlayerEnemyDiff
    JP P, ChkBBill
    INC C
ChkBBill:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_BulletBill_CannonVar
    JP Z, NoCDirF
    CP A, OBJECTID_BulletBill_FrenzyVar
    JP Z, NoCDirF
    LD L, <Enemy_MovingDir
    LD (HL), C
NoCDirF:
    DEC C
    LD A, C
    LD BC, EnemyBGCXSpdData
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_X_Speed
    LD (HL), A
    RET

;--------------------------------
;$04(IXH) - low nybble of vertical coordinate from block buffer routine

LandEnemyProperly:
    LD A, IXH
    SUB A, $08
    CP A, $05
    JP NC, ChkForRedKoopa
;
    LD L, <Enemy_State
    LD A, (HL)
    BIT 6, A
    JP NZ, LandEnemyInitState
    OR A
    JP M, DoEnemySideCheck

ChkLandedEnemyState:
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    JP Z, DoEnemySideCheck
    CP A, $05
    JP Z, ProcEnemyDirection
    CP A, $03
    RET NC
    CP A, $02
    JP NZ, ProcEnemyDirection
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Spiny
    LD A, $10
    JP NZ, SetForStn
    XOR A
SetForStn:
    LD (BC), A
;
    LD L, <Enemy_State
    LD (HL), $03
    JP EnemyLanding

ProcEnemyDirection:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_Goomba
    JP Z, LandEnemyInitState
    CP A, OBJECTID_Spiny
    JP NZ, InvtD
;
    LD L, <Enemy_MovingDir
    LD (HL), $01
    LD L, <Enemy_X_Speed
    LD (HL), $08
    LD A, (FrameCounter)
    AND A, %00000111
    JP Z, LandEnemyInitState
;
InvtD:
    LD C, $01
    CALL PlayerEnemyDiff
    JP P, CNwCDir
    INC C
CNwCDir:
    LD A, C
    LD L, <Enemy_MovingDir
    CP A, (HL)
    CALL Z, ChkForBump_HammerBroJ

LandEnemyInitState:
    CALL EnemyLanding
;
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    JP M, NMovShellFallBit
    XOR A
    LD (HL), A
    RET

NMovShellFallBit:
    RES 6, A
    LD (HL), A
    RET

;--------------------------------

ChkForRedKoopa:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_RedKoopa
    JP NZ, Chk2MSBSt
;
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    JP Z, ChkForBump_HammerBroJ
;
Chk2MSBSt:
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    JP P, GetSteFromD
    SET 6, A
    JP SetD6Ste
GetSteFromD:
    LD BC, EnemyBGCStateData
    addAToBC8_M
    LD A, (BC)
SetD6Ste:
    LD (HL), A

;--------------------------------
;$00 - used to store bitmask (not used but initialized here)
;$eb(IYH) - used in DoEnemySideCheck as counter and to compare moving directions

DoEnemySideCheck:
    LD L, <Enemy_Y_Position
    LD A, (HL)
    CP A, $20 - SMS_PIXELYOFFSET
    RET C
;
    LD C, $16
    LD IYH, $02
SdeCLoop:
    LD A, IYH
    LD L, <Enemy_MovingDir
    CP A, (HL)
    JP NZ, NextSdeC
    LD A, $01
    CALL BlockBufferChk_Enemy
    JP Z, NextSdeC
    CALL ChkForNonSolids
    JP NZ, ChkForBump_HammerBroJ
NextSdeC:
    DEC IYH
    INC C
    LD A, C
    CP A, $18
    JP C, SdeCLoop
    RET

ChkForBump_HammerBroJ:
    LD A, H
    CP A, $C6
    JP Z, NoBump
;
    LD L, <Enemy_State
    LD A, (HL)
    ADD A, A
    JP NC, NoBump
    LD A, SNDID_BUMP
    LD (SFXTrack0.SoundQueue), A 
NoBump:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $05
    JP NZ, RXSpd
    XOR A
    LD (Temp_Bytes + $00), A
    LD C, $FA
    JP SetHJ

;--------------------------------
;$00 - used to hold horizontal difference between player and enemy

PlayerEnemyDiff:
    LD A, (Player_X_Position)
    LD IXL, A
    LD L, <Enemy_X_Position
    LD A, (HL)
    SUB A, IXL
    LD (Temp_Bytes + $00), A
    LD A, (Player_PageLoc)
    LD IXL, A
    LD L, <Enemy_PageLoc
    LD A, (HL)
    SBC A, IXL
    RET

;--------------------------------

EnemyLanding:
    CALL InitVStf
    LD L, <Enemy_Y_Position
    LD A, (HL)
    AND A, %11110000
    ;OR A, %00001000
    LD (HL), A
    RET

SubtEnemyYPos:
    LD L, <Enemy_Y_Position
    LD A, (HL)
    ADD A, $3E
    CP A, $44 - SMS_PIXELYOFFSET
    RET

EnemyJump:
    CALL SubtEnemyYPos
    JP C, DoEnemySideCheck
;
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    ADD A, $02
    CP A, $03
    JP C, DoEnemySideCheck
;
    CALL ChkUnderEnemy
    JP Z, DoEnemySideCheck
;
    CALL ChkForNonSolids
    JP Z, DoEnemySideCheck
;
    CALL EnemyLanding
    LD L, <Enemy_Y_Speed
    LD (HL), $FD
    JP DoEnemySideCheck

;--------------------------------

HammerBroBGColl:
    CALL ChkUnderEnemy
    JP Z, NoUnderHammerBro
    CP A, MT_HITBLANK
    JP NZ, UnderHammerBro

KillEnemyAboveBlock:
    CALL ShellOrBlockDefeat
    LD L, <Enemy_Y_Speed
    LD (HL), $FC
    RET

UnderHammerBro:
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    JP NZ, NoUnderHammerBro
;
    LD L, <Enemy_State
    LD A, (HL)
    AND A, %10001000
    LD (HL), A
;
    CALL EnemyLanding
    JP DoEnemySideCheck

NoUnderHammerBro:
    LD L, <Enemy_State
    SET 0, (HL)
    RET

ChkUnderEnemy:
    XOR A
    LD C, $15
    JP BlockBufferChk_Enemy

ChkForNonSolids:
    CP A, MT_VINEBLANK
    RET Z
    CP A, MT_COIN
    RET Z
    CP A, MT_WATERCOIN
    RET Z
    CP A, MT_HIDDENBLK_COIN
    RET Z
    CP A, MT_HIDDENBLK_1UP
    RET
    
;-------------------------------------------------------------------------------------

FireballBGCollision:
    LD L, <Fireball_Y_Position
    LD A, (HL)
    CP A, $18 - SMS_PIXELYOFFSET
    JP C, ClearBounceFlag
;
    CALL BlockBufferChk_FBall
    JP Z, ClearBounceFlag
;
    CALL ChkForNonSolids
    JP Z, ClearBounceFlag
;
    LD L, <Fireball_Y_Speed
    LD A, (HL)
    OR A
    JP M, InitFireballExplode
;
    LD L, <FireballBouncingFlag
    LD A, (HL)
    OR A
    JP NZ, InitFireballExplode
;
    LD L, <Fireball_Y_Speed
    LD (HL), $FD
    LD L, <FireballBouncingFlag
    LD (HL), $01
    LD L, <Fireball_Y_Position
    LD A, (HL)
    AND A, %11111000
    LD (HL), A
    RET

ClearBounceFlag:
    LD L, <FireballBouncingFlag
    LD (HL), $00
    RET

InitFireballExplode:
    LD L, <Fireball_State
    LD (HL), $80
    LD A, SNDID_BUMP
    LD (SFXTrack0.SoundQueue), A
    RET

;-------------------------------------------------------------------------------------
;$00(IXL) - used to hold one of bitmasks, or offset
;$01(IXH) - used for relative X coordinate, also used to store middle screen page location
;$02(IYL) - used for relative Y coordinate, also used to store middle screen coordinate

;this data added to relative coordinates of sprite objects
;stored in order: left edge, top edge, right edge, bottom edge
.SECTION "BoundBoxCtrlData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BoundBoxCtrlData:
    .db $02, $08, $0e, $20 
    .db $03, $14, $0d, $20
    .db $02, $14, $0e, $20
    .db $02, $09, $0e, $15
    .db $00, $00, $18, $06
    .db $00, $00, $20, $0d
    .db $00, $00, $30, $0d
    .db $00, $00, $08, $08
    .db $06, $04, $0a, $08
    .db $03, $0e, $0d, $14
    .db $00, $02, $10, $15
    .db $04, $04, $0c, $1c
.ENDS

GetFireballBoundBox:
    LD D, >Fireball_Rel_XPos                ;set offset for relative coordinates
    CALL BoundingBoxCore                    ;get bounding box coordinates
    JP CheckRightScreenBBox                 ;jump to handle any offscreen coordinates

GetMiscBoundBox:
    LD D, >Misc_Rel_XPos                    ;set offset for relative coordinates
    CALL BoundingBoxCore                    ;get bounding box coordinates
    JP CheckRightScreenBBox                 ;jump to handle any offscreen coordinates

GetEnemyBoundBox:
    LD IXL, $48                             ;store bitmask here for now
    LD C, $44                               ;store another bitmask here for now and jump
    JP GetMaskedOffScrBits

SmallPlatformBoundBox:
    LD IXL, $08                             ;store bitmask here for now
    LD C, $04                               ;store another bitmask here for now

GetMaskedOffScrBits:
    LD A, (ScreenLeft_X_Pos)
    LD E, A
    LD L, <Enemy_X_Position
    LD A, (HL)
    SUB A, E
    LD IXH, A
;
    LD A, (ScreenLeft_PageLoc)
    LD E, A
    LD L, <Enemy_PageLoc
    LD A, (HL)
    SBC A, E
    JP M, CMBits
;
    OR A, IXH
    JP Z, CMBits
    LD C, IXL
CMBits:
    LD A, (Enemy_OffscrBits)
    AND A, C
    LD L, <EnemyOffscrBitsMasked
    LD (HL), A
    JP NZ, MoveBoundBoxOffscreen
    JP SetupEOffsetFBBox

LargePlatformBoundBox:
    CALL GetXOffscreenBits                  ;jump directly to the sub for horizontal offscreen bits
    CP A, $FE                               ;if completely offscreen, branch to put entire bounding
    JP NC, MoveBoundBoxOffscreen            ;box offscreen, otherwise start getting coordinates

SetupEOffsetFBBox:
    LD D, >Enemy_Rel_XPos                   ;set offset for relative coordinates
    CALL BoundingBoxCore                    ;do a sub to get the coordinates of the bounding box
    JP CheckRightScreenBBox                 ;jump to handle offscreen coordinates of bounding box

MoveBoundBoxOffscreen:
    LD A, $FF                               ;load value into four locations here and leave
    LD L, <EnemyBoundingBoxCoord
    LD (HL), A
    INC L
    LD (HL), A
    INC L
    LD (HL), A
    INC L
    LD (HL), A
    RET

;   X - OBJECT OFFSET
;   Y - REL POS OFFSET
BoundingBoxCore:
    LD E, <SprObject_Rel_YPos
    LD A, (DE)
    LD IYL, A
;
    DEC E
    LD A, (DE)
    LD IXH, A
;
    LD D, H
;
    LD L, <SprObj_BoundBoxCtrl
    LD A, (HL)
    ADD A, A
    ADD A, A
    LD BC, BoundBoxCtrlData
    addAToBC8_M
    LD A, (BC)
    ADD A, IXH
    LD E, <BoundingBox_UL_Corner
    LD (DE), A
;
    INC C
    INC C
    LD A, (BC)
    ADD A, IXH
    LD E, <BoundingBox_LR_Corner
    LD (DE), A
;
    DEC C
    LD A, (BC)
    ADD A, IYL
    LD E, <BoundingBox_UL_Corner + $01
    LD (DE), A
;
    INC C
    INC C
    LD A, (BC)
    ADD A, IYL
    LD E, <BoundingBox_LR_Corner + $01
    LD (DE), A
    RET

CheckRightScreenBBox:
    LD A, (ScreenLeft_X_Pos)
    ADD A, $80
    LD IYL, A
;
    LD A, (ScreenLeft_PageLoc)
    ADC A, $00
    LD IXH, A
;
    LD L, <SprObject_X_Position
    LD A, (HL)
    CP A, IYL
    LD L, <SprObject_PageLoc
    LD A, (HL)
    SBC A, IXH
    JP C, CheckLeftScreenBBox
;
    LD E, <BoundingBox_DR_XPos
    LD A, (DE)
    OR A
    JP M, NoOfs
    LD E, <BoundingBox_UL_XPos
    LD A, (DE)
    OR A
    LD A, $FF
    JP M, SORte
    LD (DE), A
SORte:
    LD E, <BoundingBox_DR_XPos
    LD (DE), A
NoOfs:
    ;ldx ObjectOffset
    RET

CheckLeftScreenBBox:
    LD E, <BoundingBox_UL_XPos
    LD A, (DE)
    OR A
    JP P, NoOfs2
;
    CP A, $A0
    JP C, NoOfs2
;
    LD E, <BoundingBox_DR_XPos
    LD A, (DE)
    OR A
    LD A, $00
    JP P, SOLft
    LD (DE), A
SOLft:
    LD E, <BoundingBox_UL_XPos
    LD (DE), A
NoOfs2:
    ;ldx ObjectOffset
    RET

;-------------------------------------------------------------------------------------
;$06(STACK) - second object's offset
;$07(B) - counter

PlayerCollisionCore:
    LD H, $C0 + OBJ_PLAYER                      ;initialize X to use player's bounding box for comparison

SprObjectCollisionCore:
    LD B, $02                                   ;save as counter, compare horizontal coordinates first

    ;BoundingBox_UL_Corner: [$00] 1ST LOOP
    ;BoundingBox_UL_YPos:   [$01] 2ND LOOP
    ;BoundingBox_LR_Corner: [$02] 1ST LOOP
    ;BoundingBox_DR_YPos:   [$03] 2ND LOOP
    LD E, <BoundingBox_UL_Corner                ;(SMS)offsets for first loop
    LD L, <BoundingBox_UL_Corner

;   X - 1ST OBJECT OFFSET
;   Y - 2ND OBJECT OFFSET
CollisionCoreLoop:
    LD A, (DE)                                  ;compare left/top coordinates
    CP A, (HL)                                  ;of first and second objects' bounding boxes
    JP NC, FirstBoxGreater                      ;if first left/top => second, branch
;
    INC L
    INC L                                       ;BoundingBox_LR_Corner
    CP A, (HL)                                  ;otherwise compare to right/bottom of second
    JP C, SecondBoxVerticalChk                  ;if first left/top < second right/bottom, branch elsewhere
    JP Z, CollisionFound                        ;if somehow equal, collision, thus branch
;
    INC E
    INC E                                       ;BoundingBox_LR_Corner
    LD A, (DE)                                  ;if somehow greater, check to see if bottom of
    DEC E
    DEC E                                       ;BoundingBox_UL_Corner
    EX DE, HL                                   ;(SMS)swap DE, HL to effectively do 'CP A, (DE)'
    CP A, (HL)                                  ;first object's bounding box is greater than its top
    EX DE, HL                                   ;(SMS)revert swap
    JP C, CollisionFound                        ;if somehow less, vertical wrap collision, thus branch
;
    DEC L
    DEC L                                       ;BoundingBox_UL_Corner
    CP A, (HL)                                  ;otherwise compare bottom of first bounding box to the top
    JP NC, CollisionFound                       ;of second box, and if equal or greater, collision, thus branch
;
    OR A                                        ;otherwise return with carry clear and Y = $0006
    RET                                         ;note horizontal wrapping never occurs

;   E = BoundingBox_UL_Corner
;   L = BoundingBox_LR_Corner
SecondBoxVerticalChk:
    LD A, (HL)                                  ;check to see if the vertical bottom of the box
    DEC L
    DEC L                                       ;BoundingBox_UL_Corner
    CP A, (HL)                                  ;is greater than the vertical top
    JP C, CollisionFound                        ;if somehow less, vertical wrap collision, thus branch
;
    INC E
    INC E                                       ;BoundingBox_LR_Corner
    LD A, (DE)                                  ;otherwise compare horizontal right or vertical bottom
    CP A, (HL)                                  ;of first box with horizontal left or vertical top of second box
    JP NC, CollisionFound                       ;if equal or greater, collision, thus branch
;
    OR A                                        ;otherwise return with carry clear and Y = $0006
    RET

;   E = BoundingBox_UL_Corner
;   L = BoundingBox_UL_Corner
FirstBoxGreater:
    CP A, (HL)                                  ;compare first and second box horizontal left/vertical top again
    JP Z, CollisionFound                        ;if first coordinate = second, collision, thus branch
;
    INC L
    INC L                                       ;BoundingBox_LR_Corner
    CP A, (HL)                                  ;if not, compare with second object right or bottom edge
    JP C, CollisionFound                        ;if left/top of first less than or equal to right/bottom of second
    JP Z, CollisionFound                        ;then collision, thus branch
;
    INC E
    INC E                                       ;BoundingBox_LR_Corner
    EX DE, HL
    CP A, (HL)                                  ;otherwise check to see if top of first box is greater than bottom
    EX DE, HL
    JP C, NoCollisionFound                      ;if less than or equal, no collision, branch to end
    JP Z, NoCollisionFound
;
    DEC L
    DEC L                                       ;BoundingBox_UL_Corner
    LD A, (DE)                                  ;otherwise compare bottom of first to top of second
    CP A, (HL)                                  ;if bottom of first is greater than top of second, vertical wrap
    JP NC, CollisionFound                       ;collision, and branch, otherwise, proceed onwards here

NoCollisionFound:
    OR A                                        ;clear carry, then load value set earlier, then leave
    RET                                         ;not bother checking vertical ones, because what's the point?

CollisionFound:
    LD E, <BoundingBox_UL_Corner + $01          ;increment offsets on both objects to check
    LD L, <BoundingBox_UL_Corner + $01          ;the vertical coordinates
    DJNZ CollisionCoreLoop                      ;decrement counter to reflect this and if counter not expired, branch to loop
    SCF                                         ;otherwise we already did both sets, therefore collision, so set carry
    RET

;-------------------------------------------------------------------------------------
;$02(IXL) - modified y coordinate
;$03(NOT USED) - stores metatile involved in block buffer collisions
;$04(IXH) - comes in with offset to block buffer adder data, goes out with low nybble x/y coordinate
;$05(IYL) - modified x coordinate
;$06-$07(DE) - block buffer address

.SECTION "BlockBuffer_X_Adder" BANK BANK_SLOT2 SLOT 2 FREE ALIGN 256
BlockBuffer_X_Adder:
    .db $08, $03, $0c, $02, $02, $0d, $0d, $08  ; $07
    .db $03, $0c, $02, $02, $0d, $0d, $08, $03  ; $0F
    .db $0c, $02, $02, $0d, $0d, $08, $00, $10  ; $17
    .db $04, $14, $04, $04                      ; $1B
.ENDS

.SECTION "BlockBuffer_Y_Adder" BANK BANK_SLOT2 SLOT 2 FREE ALIGN 256
BlockBuffer_Y_Adder:
    .db $04, $20, $20, $08, $18, $08, $18, $02
    .db $20, $20, $08, $18, $08, $18, $12, $20
    .db $20, $18, $18, $18, $18, $18, $14, $14
    .db $06, $06, $08, $10
.ENDS

/*
    $08, $04
    $03, $20
    $0C, $20
    $02, $08
    $02, $18
    $0D, $08
    $0D, $18
    $08, $02
*/

;BlockBufferChk_Enemy:
;    JP BlockBufferCollision

BlockBufferChk_FBall:
    LD C, $1A 
    XOR A
    JP BlockBufferCollision
    ;ldx ObjectOffset

BlockBufferColli_Feet:
    INC C

BlockBufferColli_Head:
    XOR A
    JP BlockBufferColli_Side@SetPlayerOffset

BlockBufferColli_Side:
    LD A, $01
@SetPlayerOffset:
    LD H, $C0 + OBJ_PLAYER


;   A - FLAG TO RETURN EITHER H OR V COORDINATES
;   X - OBJECT OFFSET
;   Y - BLOCKBUFFER_XXX_ADDER OFFSET?

;   C - BlockBuffer_X_Adder/BlockBuffer_Y_Adder (INPUT)
;   HL - OBJECT OFFSET (INPUT)
;   DE - BLOCK BUFFER ADDRESS
BlockBufferChk_Enemy:
BlockBufferCollision:
    PUSH AF                             ;save contents of A to stack
;
    LD B, >BlockBuffer_X_Adder          
    LD A, (BC)                          ;add horizontal coordinate
    LD L, <SprObject_X_Position         ;of object to value obtained using Y as offset
    ADD A, (HL)
    LD IYL, A                           ;store here
;
    LD L, <SprObject_PageLoc
    LD A, (HL)
    ADC A, $00                          ;add carry to page location
    RRCA                                ;move LSB to carry
    LD A, IYL                           ;get stored value
    RRA                                 ;rotate carry to MSB of A
    RRCA                                ;and effectively move high nybble to
    RRCA                                ;lower, LSB which became MSB will be
    RRCA                                ;d4 at this point
    ;;;
    ;CALL GetBlockBufferAddr             ;get address of block buffer into $06, $07
    LD DE, Block_Buffer_1
    BIT 4, A
    JP Z, +
    LD E, <Block_Buffer_2
+:
    AND A, $0F                      ;mask out high nybble
    addAToDE8_M                     ;add to low byte    
    LD (Temp_Bytes + $06), DE
    ;;;
;
    LD B, >BlockBuffer_Y_Adder
    LD A, (BC)
    LD L, <SprObject_Y_Position         ;get vertical coordinate of object
    ADD A, (HL)                         ;add it to value obtained using Y as offset
    SUB A, $08  ; $20                   ;subtract 8 pixels for the status bar     
    AND A, %11110000                    ;mask out low nybble
    LD IXL, A                           ;store result here
;
    addAToDE_M
;
    POP AF                              ;pull A from stack
    OR A
    LD L, <SprObject_X_Position
    LD A, (HL)
    JP NZ, RetC                         ;if A = 1, load horizontal coordinate
    LD L, <SprObject_Y_Position         ;if A = 0, load vertical coordinate
    LD A, (HL)
    ADD A, SMS_PIXELYOFFSET 
RetC:
    AND A, %00001111                    ;and mask out high nybble
    LD IXH, A                           ;store masked out result here
    LD A, (DE)                          ;get content of block buffer
    OR A
    RET

/*
    BLOCK BUFFER DATA LAYOUT:
    HN: ROW,  LN: COL
    00 01 02 03 04 05 06 07 08 09 0A 0B 0C 0D 0E 0F
    10 11 12 13 14 15 16 17 18 19 1A 1B 1C 1D 1E 1F
    20 21 22 23 24 25 26 27 28 29 2A 2B 2C 2D 2E 2F
    30 31 32 33 34 35 36 37 38 39 3A 3B 3C 3D 3E 3F
    40 41 42 43 44 45 46 47 48 49 4A 4B 4C 4D 4E 4F
    50 51 52 53 54 55 56 57 58 59 5A 5B 5C 5D 5E 5F
    60 61 62 63 64 65 66 67 68 69 6A 6B 6C 6D 6E 6F
    70 71 72 73 74 75 76 77 78 79 7A 7B 7C 7D 7E 7F
    80 81 82 83 84 85 86 87 88 89 8A 8B 8C 8D 8E 8F
    90 91 92 93 94 95 96 97 98 99 9A 9B 9C 9D 9E 9F
    A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF
    B0 B1 B2 B3 B4 B5 B6 B7 B8 B9 BA BB BC BD BE BF
    C0 C1 C2 C3 C4 C5 C6 C7 C8 C9 CA CB CC CD CE CF <- UNSEEN DUE TO SMALLER RESOLUTION
*/



;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;$00 (IXL) - used in adding to get proper offset

RelativePlayerPosition:
    LD H, >Player_Rel_XPos
    LD D, H
    JP GetObjRelativePosition

RelativeBubblePosition:
    LD D, >Bubble_Rel_XPos
    JP GetObjRelativePosition

RelativeFireballPosition:
    LD D, >Fireball_Rel_XPos
    JP GetObjRelativePosition
    /*
RelWOfs:
    CALL GetObjRelativePosition
    LD HL, (ObjectOffset)
    RET
    */

RelativeMiscPosition:
    LD D, >Misc_Rel_XPos
    JP GetObjRelativePosition

RelativeEnemyPosition:
    LD D, >Enemy_Rel_XPos
    JP GetObjRelativePosition

RelativeBlockPosition:
    LD D, >Block_Rel_XPos
    CALL GetObjRelativePosition
;
    INC H
    INC H
    INC D
    CALL GetObjRelativePosition
    DEC H
    DEC H
    RET

    /*
;   HL - OBJECT OFFSET
;   DE - XXX_Rel_XPos/YPos OFFSET
VariableObjOfsRelPos:
    ;LD IXL, B
    ;ADD A, B
    ;LD B, A
    CALL GetObjRelativePosition
    ;LD HL, (ObjectOffset)
    ;LD B, (HL)
    RET
    */

;   HL - OBJECT OFFSET
;   DE - XXX_Rel_XPos/YPos OFFSET
GetObjRelativePosition:
    LD L, <SprObject_Y_Position
    LD E, <SprObject_Rel_YPos
    LD A, (HL)                              ;load vertical coordinate low
    LD (DE), A                              ;store here
;
    LD L, <SprObject_X_Position
    ;LD E, <SprObject_Rel_XPos
    DEC E                                   ;<SprObject_Rel_XPos
    LD A, (ScreenLeft_X_Pos)
    LD C, A
    LD A, (HL)                              ;load horizontal coordinate
    SUB A, C                                ;subtract left edge coordinate
    LD (DE), A                              ;store result here
    RET

;-------------------------------------------------------------------------------------
;$00 (IXL) - used as temp variable to hold offscreen bits

GetPlayerOffscreenBits:
    LD H, >Player_OffscrBits
    LD D, H
    JP GetOffScreenBitsSet

GetFireballOffscreenBits:
    LD D, >Fireball_OffscrBits
    JP GetOffScreenBitsSet

GetBubbleOffscreenBits:
    LD D, >Bubble_OffscrBits
    JP GetOffScreenBitsSet

GetMiscOffscreenBits:
    LD D, >Misc_OffscrBits
    JP GetOffScreenBitsSet

GetEnemyOffscreenBits:
    LD D, >Enemy_OffscrBits
    JP GetOffScreenBitsSet

GetBlockOffscreenBits:
    LD D, >Block_OffscrBits

;   HL - OBJECT OFFSET
;   DE - OffscreenBits OFFSET
GetOffScreenBitsSet:
    PUSH DE                                 ;save offscreen bits offset to stack for now
    ;CALL RunOffscrBitsSubs
    CALL GetXOffscreenBits
    RRCA
    RRCA
    RRCA
    RRCA
    AND A, $0F
    LD IXL, A
    CALL GetYOffscreenBits
    ADD A, A                                ;move low nybble to high nybble
    ADD A, A
    ADD A, A
    ADD A, A
    OR A, IXL                               ;mask together with previously saved low nybble
    POP DE                                  ;get offscreen bits offset from stack
    LD E, <SprObject_OffscrBits
    LD (DE), A
    ;LD HL, (ObjectOffset)
    RET

    /*
RunOffscrBitsSubs:
    CALL GetXOffscreenBits                  ;do subroutine here
    RRCA                                    ;move high nybble to low
    RRCA
    RRCA
    RRCA
    AND A, $0F
    LD IXL, A                               ;store here
    JP GetYOffscreenBits
    */

;--------------------------------
;(these apply to these three subsections)
; NOT USED!!! $04 (IXL) - used to store proper offset
;$05 (IXH) - used as adder in DividePDiff
;$06 (IYL) - used to store preset value used to compare to pixel difference in $07
;$07 (IYH) - used to store difference between coordinates of object and screen edges

.SECTION "XOffscreenBitsData, DefaultXOnscreenOfs" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
XOffscreenBitsData:
    ; $00
    .db $7f, $3f, $1f, $0f, $07, $03, $01, $00
    ; $07
    .db $80, $c0, $e0, $f0, $f8, $fc, $fe, $ff
    ; $0F

DefaultXOnscreenOfs:
    .db $07, $0f, $07
.ENDS

GetXOffscreenBits:
;   LOOP 1 (RIGHT SIDE CHECK?)
    LD L, <SprObject_X_Position
    LD A, (ScreenEdge_X_Pos + $01)          ;get pixel coordinate of edge
    SUB A, (HL)                             ;get difference between pixel coordinate of edge
    LD IYH, A                               ;store here
;
    LD L, <SprObject_PageLoc
    LD A, (ScreenEdge_PageLoc + $01)        ;get page location of edge
    SBC A, (HL)                             ;subtract from page location of object position
;
    LD DE, DefaultXOnscreenOfs + $01        ;load offset value here
    JP M, XLdBData                          ;if beyond right edge or in front of left edge, branch
    INC E                                   ;if not, load alternate offset value here
    CP A, $01
    JP P, XLdBData                          ;if one page or more to the left of either edge, branch
    LD IYL, $38                             ;if no branching, load value here and store
    LD A, $08                               ;load some other value and execute subroutine
    CALL DividePDiff
    JP XLdBData@DividePDiff_Ret
XLdBData:
    LD A, (DE)                              
@DividePDiff_Ret:
    LD DE, XOffscreenBitsData
    addAToDE8_M
    LD A, (DE)                              ;get bits here
    OR A                                    ;if bits not zero, branch to leave
    RET NZ
;   LOOP 2 (LEFT SIDE CHECK?)
    LD L, <SprObject_X_Position
    LD A, (ScreenEdge_X_Pos)
    SUB A, (HL)
    LD IYH, A
;
    LD L, <SprObject_PageLoc
    LD A, (ScreenEdge_PageLoc)
    SBC A, (HL)
;
    LD DE, DefaultXOnscreenOfs
    JP M, XLdBData_2
    INC E
    CP A, $01
    JP P, XLdBData_2
    LD IYL, $38
    LD A, $08
    CALL DividePDiff_2
    JP XLdBData_2@DividePDiff_Ret
XLdBData_2:
    LD A, (DE)
@DividePDiff_Ret:
    LD DE, XOffscreenBitsData
    addAToDE8_M
    LD A, (DE)
    RET

;--------------------------------

.SECTION "YOffscreenBitsData, DefaultYOnscreenOfs, HighPosUnitData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
YOffscreenBitsData:
    ; $00
    .db $00, $08, $0c, $0e
    ; $04
    .db $0f, $07, $03, $01
    ; $08
    .db $00

DefaultYOnscreenOfs:
    .db $04, $00, $04

HighPosUnitData:
    .db $ff, $00
.ENDS

;   1, 0
GetYOffscreenBits:
;   LOOP 1 (TOP SIDE CHECK?)
    LD L, <SprObject_Y_Position
    LD A, (HighPosUnitData + $01)
    SUB A, (HL)
    LD IYH, A
;
    LD L, <SprObject_Y_HighPos
    LD A, $01
    SBC A, (HL)
;
    LD DE, DefaultYOnscreenOfs + $01
    JP M, YLdBData
    INC E
    CP A, $01
    JP P, YLdBData
    LD IYL, $20
    LD A, $04
    CALL DividePDiff
    JP YLdBData@DividePDiff_Ret
YLdBData:
    LD A, (DE)
@DividePDiff_Ret:
    LD DE, YOffscreenBitsData
    addAToDE8_M
    LD A, (DE)
    OR A
    RET NZ
;   LOOP 2 (BOTTOM SIDE CHECK?)
    LD L, <SprObject_Y_Position
    LD A, (HighPosUnitData)
    SUB A, (HL)
    LD IYH, A
;
    LD L, <SprObject_Y_HighPos
    LD A, $01
    SBC A, (HL)
;
    LD DE, DefaultYOnscreenOfs
    JP M, YLdBData_2
    INC E
    CP A, $01
    JP P, YLdBData_2
    LD IYL, $20
    LD A, $04
    CALL DividePDiff_2
    JP YLdBData_2@DividePDiff_Ret
YLdBData_2:
    LD A, (DE)
@DividePDiff_Ret:
    LD DE, YOffscreenBitsData
    addAToDE8_M
    LD A, (DE)
    RET

;--------------------------------
DividePDiff:
    LD IXH, A                           ;store current value in A here
    LD A, IYH                           ;get pixel difference
    CP A, IYL                           ;compare to preset value
    LD A, (DE)                          ;(SMS)reload offset from DefaultYOnscreenOfs/DefaultXOnscreenOfs in case of RET
    RET NC                              ;if pixel difference >= preset value, branch
;
    LD A, IYH
    RRCA                                ;divide by eight
    RRCA
    RRCA
    AND A, $07                          ;mask out all but 3 LSB
    RET

DividePDiff_2:
    LD IXH, A                           ;store current value in A here
    LD A, IYH                           ;get pixel difference
    CP A, IYL                           ;compare to preset value
    LD A, (DE)                          ;(SMS)reload offset from DefaultYOnscreenOfs/DefaultXOnscreenOfs in case of RET
    RET NC                              ;if pixel difference >= preset value, branch
;
    LD A, IYH
    RRCA                                ;divide by eight
    RRCA
    RRCA
    AND A, $07                          ;mask out all but 3 LSB
    ADD A, IXH                          ;if not, add value to difference / 8
    RET
    
;-------------------------------------------------------------------------------------
