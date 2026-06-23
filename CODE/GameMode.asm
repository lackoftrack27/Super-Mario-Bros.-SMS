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
    DI                              ;prevent interrupts from corrupting mem initialization

    LD A, (TitleLoadedFlag)         ;skip mem initialization if past initial load on title screen
    OR A
    JR NZ, +
    LD HL, InitAreaOffset           ;clear all memory again, only as far as $074b
    CALL InitializeMemory           ;this is only necessary if branching from
;
    LD HL, Timers                   ;clear out memory between
    LD DE, Timers + $01             ;$0780 and $07a1
    LD BC, $22 - $01
    LD (HL), $00
    LDIR
;
+:
    LD HL, ColumnBuffer
    LD (ColumnUpdate_Ptr), HL
    DEC H
    LD (ColumnWrite_Ptr), HL
;
    LD A, (AltEntranceControl)
    OR A
    LD A, (HalfwayPage)             ;if AltEntranceControl not set, use halfway page, if any found
    JR Z, @StartPage
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
    INC H
    DEC (HL)
    LD A, $0B                       ;set value for renderer to update 12 column sets
    LD (ColumnSets), A              ;12 column sets = 24 metatile columns = 1 1/2 screens
    CALL GetAreaDataAddrs           ;get enemy and level addresses and load header
    LD A, (PrimaryHardMode)         ;check to see if primary hard mode has been activated
    OR A
    JR NZ, @SetSecHard              ;if so, activate the secondary no matter where we're at
    LD A, (WorldNumber)             ;otherwise check world number
    CP A, WORLD5                    ;if less than 5, do not activate secondary
    JR C, @CheckHalfway
    JR NZ, @SetSecHard              ;if not equal to, then world > 5, thus activate
    LD A, (LevelNumber)             ;otherwise, world 5, so check level number
    CP A, LEVEL3                    ;if 1 or 2, do not set secondary hard mode flag
    JR C, @CheckHalfway 
@SetSecHard:
    LD HL, SecondaryHardMode        ;set secondary hard mode flag for areas 5-3 and beyond
    INC (HL)
@CheckHalfway:
    LD A, (HalfwayPage)
    OR A
    JR Z, @DoneInitArea
    LD A, $02                       ;if halfway page set, overwrite start position from header
    LD (PlayerEntranceCtrl), A
@DoneInitArea:
    LD A, (TitleLoadedFlag)         ;don't silence music if past initial load on title screen
    OR A
    JR NZ, +
    LD A, SNDID_SILENCE
    LD (MusicTrack0.SoundQueue), A
+:
    XOR A                           ;disable screen output
    LD (DisableScreenFlag), A
    LD HL, OperMode_Task            ;increment one of the modes
    INC (HL)

    IN A, (VDPCON_PORT)             ;clear any pending VDP interrupts
    EI
    RET

;-------------------------------------------------------------------------------------

SecondaryGameSetup:
    LD A, $40
    LD (DisableScreenFlag), A           ;enable screen output
    ; LD HL, VRAM_Buffer1_Offset          ;clear buffer at $0300-$03ff
    ; LD DE, VRAM_Buffer1_Offset + $01  ;   !!! THIS CLEARS WAY MORE STUFF THAN JUST THE VRAM BUFFERS !!!
    ; LD BC, $00FF
    ; LD (HL), A
    ; LDIR
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
    XOR A
    LD (GameTimerExpiredFlag), A        ;clear game timer exp flag
    LD (DisableIntermediate), A         ;clear skip lives display flag
    LD (BackloadingFlag), A             ;clear value here
    DEC A
    LD (BalPlatformAlignment), A        ;initialize balance platform assignment flag
    CALL GetAreaMusic                   ;load proper music into queue
;
    LD HL, SprShuffleAmt_02             ;load sprite shuffle amounts to be used later
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

.SECTION "Default Sprite Offsets" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
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
    RET C                               ;exit if we are not suppose to be in the mode
    ; FALL THROUGH

;-------------------------------------------------------------------------------------

GameEngine:
    CALL ProcFireball_Bubble                ;process fireballs and air bubbles
;
    LD H, >Enemy_ID
ProcELoop:
    LD (ObjectOffset), HL
    CALL EnemiesAndLoopsCore                ;process enemy objects
    LD L, <FloateyNum_Control
    LD A, (HL)                              ;load control for floatey number
    OR A
    CALL NZ, FloateyNumbersRoutine          ;process floatey numbers
    INC H
    LD A, >Enemy_ID_05 + $01
    CP A, H                                 ;do these two subroutines until the whole buffer is done
    JP NZ, ProcELoop
;
    GetPlayerOffscreenBits_M                ;get offscreen bits for player object
    RelativePlayerPosition_M                ;get relative coordinates for player object
    LD A, (HidePlayerFlag)
    OR A
    CALL Z, PlayerGfxHandler                ;draw the player if he isn't hidden by end-of-level castle
    CALL BlockObjMT_Updater                 ;replace block objects with metatiles if necessary
;
    LD H, >Block_State + $01                ;set offset for second block object
    LD (ObjectOffset), HL
    CALL BlockObjectsCore                   ;process second block object
    DEC H                                   ;set offset for first and process
    LD (ObjectOffset), HL                   ;set offset for first
    CALL BlockObjectsCore                   ;process first block object
;
    CALL MiscObjectsCore                    ;process misc objects (hammer, jumping coins)
;
    LD A, (AreaType)                        ;process bullet bill cannons
    OR A
    CALL NZ, ProcessCannons
;
    LD A, (AreaType)                        ;process whirlpools
    OR A
    CALL Z, ProcessWhirlpools
;
    CALL FlagpoleRoutine                    ;process the flagpole
;
    CALL RunGameTimer                       ;count down the game timer
;
    LD HL, (AnimateRoutine)                 ;do either palette cycling or tile animation based on gfx mode
    CALL IndirectCallHL
;
    LD A, (Player_Y_HighPos)                ;if player is below the screen, don't bother with the music
    CP A, $02
    JP P, NoChgMus
    LD A, (StarInvincibleTimer)             ;if star mario invincibility timer at zero,
    OR A
    JP Z, ClrPlrPal                         ;skip this part
    CP A, $04
    JP NZ, NoChgMus                         ;if not yet at a certain point, continue
    LD A, (IntervalTimerControl)            ;if interval timer has expired,
    OR A
    CALL Z, GetAreaMusic                    ;re-attain appropriate level music
NoChgMus:
    LD A, (StarInvincibleTimer)             ;get invincibility timer
    CP A, $08                               ;if timer still above certain point,
    LD A, (FrameCounter)                    ;get frame counter
    JP NC, CycleTwo                         ;branch to cycle player's palette quickly
    SRL A                                   ;otherwise, divide by 8 to cycle every eighth frame
    SRL A
CycleTwo:
    SRL A                                   ;if branched here, divide by 2 to cycle every other frame
    CALL CyclePlayerPalette                 ;do sub to cycle the palette (note: shares fire flower code)
    JP SaveAB                               ;then skip this sub to finish up the game engine
ClrPlrPal:
    LD A, (GameEngineSubroutine)            ;if not doing player color cycling for fire flower,
    CP A, $0C
    CALL NZ, GetPlayerColors                ;set default colors for player
;
SaveAB:
    LD A, (A_B_Buttons)                     ;save current A and B button
    LD (PreviousA_B_Buttons), A             ;into temp variable to be used on next frame
    XOR A                                   ;nullify left and right buttons temp variable
    LD (Left_Right_Buttons), A
;
UpdScrollVar:
    LD A, (VRAM_Buffer_AddrCtrl)
    CP A, VRAMTBL_BUFFER2                   ;if vram address controller set to VRAM_Buffer2
    RET Z                                   ;then branch to leave
;
    LD A, (AreaParserTaskNum)               ;otherwise check number of tasks
    OR A
    JP NZ, RunParser
    LD A, (ScrollThirtyTwo)                 ;get horizontal scroll in 0-31 or $00-$20 range
    SUB A, $20                              ;check to see if exceeded $21
    JP M, CheckScrollEight                  ;if not, branch to check if scroll exceeded $09
    LD (ScrollThirtyTwo), A                 ;store new scroll value
    LD HL, VRAM_Buffer2                     ;reset buffer2's ptr (not necessary)
    LD (VRAM_Buffer2_Ptr), HL
RunParser:
    CALL AreaParserTaskHandler              ;update the name table with more level graphics (kind of...)
    ; FALL THROUGH

CheckScrollEight:
    LD A, (ScrollEight)                     ;get horizontal scroll in 0-7 or $00-$08 range
    SUB A, $08                              ;check to see if exceeded $09
    RET M                                   ;if not, exit
    LD (ScrollEight), A                     ;store new scroll value
    LD A, $01                               ;set flag to update nametable with a 1 tile-wide column
    LD (RenderColumnFlag), A
    ;
    LD HL, ColumnWrite_Ptr + $01            ;update pointer on where to read the column data from
    INC (HL)
    LD A, (HL)
    CP A, >ColumnBuffer_0F + $01            ;ensure pointer doesn't exceed boundaries
    RET NZ
    LD (HL), >ColumnBuffer
    RET

;-------------------------------------------------------------------------------------

.SECTION "Animated Background Tile Initializations" BANK BANK_SLOT2 SLOT 2 FREE RETURNORG
AnimatedBGTileInits:
@Coin:
    .dw $3D00 | VRAMWRITE       ; VRAM ADDR
    .db StripeCount($04 * $20)  ; TILES PER FRAME IN LDI COUNT
    .dw CoinFrame0              ; STARTING TILE ADDR
    .db $03, $08, $03, $08      ; FRAME COUNT, TIMER COUNT, FRAME RESET, TIMER RESET
@Grass:
    .dw $3D80 | VRAMWRITE
    .db $00                     ; N/A
    .dw GrassFrame0
    .db $03, $10, $03, $10
@Latern:
    .dw $3D80 | VRAMWRITE
    .db StripeCount($04 * $20)
    .dw LaternFrame0
    .db $03, $10, $03, $10
@WaterA1:
    .dw $3CA0 | VRAMWRITE
    .db StripeCount($02 * $20)
    .dw WaterA1Frame0
    .db $08, $10, $08, $10
@WaterA0:
    .dw $3CA0 | VRAMWRITE
    .db StripeCount($02 * $20)
    .dw WaterA0Frame0
    .db $08, $10, $08, $10
@WaterCoin:
    .dw $3D00 | VRAMWRITE
    .db StripeCount($04 * $20)
    .dw WCoinFrame0
    .db $03, $08, $03, $08
@Lava:
    .dw $3D80 | VRAMWRITE
    .db StripeCount($04 * $20)
    .dw LavaFrame0
    .db $08, $10, $08, $10
@QBlock:
    .dw $3C20 | VRAMWRITE
    .db StripeCount($04 * $20)
    .dw QBlockFrame0
    .db $03, $08, $03, $08
.ENDS

;   AnimatedBGTileQueue
;   $00:        animate flag
;   $01-$02:    vdp address
;   $03:        frame byte count (in LDIs)
;   $04-$05:    current frame's tile address
;   $06:        current frame
;   $07:        frame timer
;   $08:        frame reset value
;   $09:        frame timer reset value
AnimateBGTiles:
;   SLOT 0
    ; DECREMENT TIMER AND BRANCH IF IT HASN'T EXPIRED
    LD HL, BGTileQueue0.Timer
    DEC (HL)
    JR NZ, @UpdateSlot1
    ; SET TIMER TO RESET VALUE
    LD A, (BGTileQueue0.TimerReset)
    LD (HL), A
    ; SET UPDATE FLAG
    LD A, $01
    LD (BGTileQueue0.UpdateFlag), A
    ; MOVE TO NEXT FRAME IN LIST
    LD A, (BGTileQueue0.TileAdr + $01)
    INC A
    DEC L
    DEC (HL)
    JR NZ, +
    LD B, A
    LD A, (BGTileQueue0.FrameReset)
    LD (HL), A
    LD A, B
    SUB A, (HL)
+:
    LD (BGTileQueue0.TileAdr + $01), A
@UpdateSlot1:
    LD HL, BGTileQueue1.Timer
    ;LD A, (HL)
    ;OR A
    ;JP M, @UpdateSlot2
    DEC (HL)
    JR NZ, @UpdateSlot2
    LD A, (BGTileQueue1.TimerReset)
    LD (HL), A
    LD A, $01
    LD (BGTileQueue1.UpdateFlag), A
    LD A, (BGTileQueue1.TileAdr + $01)
    INC A
    DEC L
    DEC (HL)
    JR NZ, +
    LD B, A
    LD A, (BGTileQueue1.FrameReset)
    LD (HL), A
    LD A, B
    SUB A, (HL)
+:
    LD (BGTileQueue1.TileAdr + $01), A
@UpdateSlot2:
    LD HL, BGTileQueue2.Timer
    LD A, (HL)
    OR A
    RET M
    DEC (HL)
    RET NZ
    LD A, (BGTileQueue2.TimerReset)
    LD (HL), A
    LD A, $01
    LD (BGTileQueue2.UpdateFlag), A
    LD A, (BGTileQueue2.TileAdr + $01)
    INC A
    DEC L
    DEC (HL)
    JR NZ, +
    LD B, A
    LD A, (BGTileQueue2.FrameReset)
    LD (HL), A
    LD A, B
    SUB A, (HL)
+:
    LD (BGTileQueue2.TileAdr + $01), A
    RET

ColorRotation:
;   SPR PALETTE ROTATION
    LD HL, (VRAM_Buffer1_Ptr)
    LD (HL), $C0
    INC L
    LD (HL), $1D
    INC L
    LD (HL), StripeCount($03)
    INC L
    ;
    LD DE, SpritePaletteCopy
    LD A, (FrameCounter)
    AND A, $06
    ADD A, A
    addAToDE8_M
    EX DE, HL
    LDI
    LDI
    LDI
    XOR A
    LD (DE), A
    LD (VRAM_Buffer1_Ptr), DE
;   BG PALETTE ROTATION
    LD A, (FrameCounter)
    AND A, $07
    RET NZ
    ;
    LD HL, (VRAM_Buffer1_Ptr)
    LD (HL), $C0
    INC L
    LD (HL), $0A
    INC L
    LD (HL), StripeCount($01)
    INC L
    ;
    LD DE, BGColorRotatePalette
    LD A, (ColorRotateOffset)
    addAToDE8_M
    LD A, (DE)
    LD (HL), A
    INC L
    LD (HL), $00
    LD (VRAM_Buffer1_Ptr), HL
    ;
    LD HL, ColorRotateOffset
    INC (HL)
    LD A, (HL)
    CP A, $06
    RET C
    LD (HL), $00
    RET

.SECTION "BG Color Rotation Palette" BANK BANK_SLOT2 SLOT 2 BITWINDOW 8 RETURNORG
BGColorRotatePalette:
    .db $0B, $0B, $0B, $06, $01, $06
.ENDS

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
    LD HL, ScrollEight
    ADD A, (HL)
    LD (HL), A
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
    CALL GetScreenPosition                  ;figure out where the right side is
    JP ChkPOffscr                           ;skip this part
InitScrlAmt:
    XOR A
    LD (ScrollAmount), A                    ;initialize value here
ChkPOffscr:
    LD H, >Player_Y_Position                  ;set X for player offset
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

.SECTION "X_SubtracterData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
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
    LD A, (Player_Y_HighPos)
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
    LD H, >Fireball_State
    CALL FireballObjCore            ;process first fireball object
    INC H
    CALL FireballObjCore            ;process second fireball object, then do air bubbles

ProcAirBubbles:
    LD A, (AreaType)                ;if not water type level, skip the rest of this
    OR A
    RET NZ

    ;LD B, $03                       ;otherwise load counter and use as offset
    LD H, >Bubble_Y_Position + $02
BublLoop:
.REPEAT $03
    LD (ObjectOffset), HL
    CALL BubbleCheck                ;check timers and coordinates, create air bubble
    RelativeBubblePosition_M        ;get relative coordinates
    GetBubbleOffscreenBits_M        ;get offscreen information
    CALL DrawBubble                 ;draw the air bubble                
    DEC H
.ENDR
    ;DJNZ BublLoop                   ;do this until all three are handled
    RET

.SECTION "FireballXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG

FireballXSpdData:
.IF PALBUILD == $00
    .db $40, $c0
.ELSE
    .db $4c, $b4                    ;PAL diff: Faster speed to compensate FPS difference
.ENDIF

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
    
    .IF PALBUILD == $00
    LD (HL), $04                    ;set vertical speed of fireball
    .ELSE
    LD (HL), $05                    ;PAL diff: faster speed to compensate for FPS diff
    .ENDIF
;
    LD L, <Fireball_BoundBoxCtrl
    LD (HL), $07                    ;set bounding box size control for fireball
;
    LD L, <Fireball_State
    DEC (HL)                        ;decrement state to 1 to skip this part from now on
RunFB:
    .IF PALBUILD == $00
    LD BC, $5003                     ;set downward movement force & max speed here
    .ELSE
    LD BC, $6005                     ;PAL diff: Faster acceleration & max speed to compensate FPS difference
    .ENDIF
    
    ;XOR A
    ;CALL ImposeGravity              ;do sub here to impose gravity on fireball and move vertically
    CALL ImposeGravity_A0
    CALL MoveObjectHorizontally     ;do another sub to move it horizontally
;
    ;LD HL, (ObjectOffset)
    RelativeFireballPosition_M      ;get relative coordinates
    GetFireballOffscreenBits_M      ;get offscreen information
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
    RelativeFireballPosition_M
    JP DrawExplosion_Fireball

BubbleCheck:
    LD A, H
    SUB A, >Bubble_Y_Position
    LD DE, PseudoRandomBitReg
    addAToDE8_M
    LD A, (DE)                      ;get part of LSFR
    AND A, $01
    LD B, A                         ;store pseudorandom bit here
;
    LD L, <Bubble_Y_Position
    LD A, (HL)                      ;get vertical coordinate for air bubble
    CP A, YPOS_OFFSCREEN_LOGICAL    ;if offscreen coordinate not set,
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
    LD C, $09                       ;otherwise load alternate value here (+1 due to carry being set and 6502 code using 'adc' with 'clc' beforehand)
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
    LD A, $40                       ;BubbleTimerData[0]
    INC B                           ;get pseudorandom bit, use as offset
    DEC B
    JR Z, +
    LD A, $20                       ;BubbleTimerData[1]
+:
    LD (AirBubbleTimer), A          ;set air bubble timer
MoveBubl:
    DEC B                           ;get pseudorandom bit again, use as offset
    ;LD B, $FF                       ;Bubble_MForceData[0]
    JR NZ, +
    LD B, $50                       ;Bubble_MForceData[1]
+:
    LD L, <Bubble_YMF_Dummy
    LD A, (HL)
    SUB A, B                        ;subtract pseudorandom amount from dummy variable
    LD (HL), A                      ;save dummy variable
;
    LD L, <Bubble_Y_Position
    LD A, (HL)
    SBC A, $00                      ;subtract borrow from airbubble's vertical coordinate
    CP A, $20                       ;if below the status bar,
    JP NC, Y_Bubl                   ;branch to go ahead and use to move air bubble upwards
    LD A, YPOS_OFFSCREEN_LOGICAL    ;otherwise set offscreen coordinate
Y_Bubl:
    LD (HL), A                      ;store as new vertical coordinate for air bubble
    RET

; .SECTION "Bubble_MForceData & BubbleTimerData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
; Bubble_MForceData:
;     .db $ff, $50

; BubbleTimerData:
;     .db $40, $20
; .ENDS

;-------------------------------------------------------------------------------------

ProcessCannons:
    LD H, $C3
ThreeSChk:
    LD (ObjectOffset), HL           ;start at third enemy slot
    LD L, <Enemy_Flag               ;check enemy buffer flag
    LD A, (HL)
    OR A
    JP NZ, Chk_BB                   ;if set, branch to check enemy
;
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD A, (BC)                      ;otherwise get part of LSFR
    LD C, A
    LD A, (SecondaryHardMode)       ;get secondary hard mode flag, use as offset
    OR A
    LD A, %00001111
    JP Z, +
    LD A, %00000111
+:
    AND A, C                        ;mask out bits of LSFR as decided by flag
    CP A, $06                       ;check to see if lower nybble is above certain value
    JP NC, Chk_BB                   ;if so, branch to check enemy
    ADD A, >Cannon_PageLoc          ;transfer masked contents of LSFR to Y as pseudorandom offset
    LD D, A
    LD E, <Cannon_PageLoc           ;get page location
    LD A, (DE)
    OR A
    JP Z, Chk_BB                    ;if not set or on page 0, branch to check enemy
    LD E, <Cannon_Timer             ;get cannon timer
    LD A, (DE)
    OR A
    JP Z, FireCannon                ;if expired, branch to fire cannon
    DEC A                           ;otherwise subtract borrow (note carry will always be clear here)
    LD (DE), A                      ;to count timer down
    JP Chk_BB                       ;then jump ahead to check enemy

FireCannon:
    LD A, (TimerControl)            ;if master timer control set,
    OR A
    JP NZ, Chk_BB                   ;branch to check enemy
;
    LD A, $0E                       ;otherwise we start creating one
    LD (DE), A                      ;first, reset cannon timer
;
    LD E, <Cannon_PageLoc           ;get page location of cannon
    LD L, <Enemy_PageLoc            ;save as page location of bullet bill
    LD A, (DE)
    LD (HL), A
;
    LD E, <Cannon_X_Position        ;get horizontal coordinate of cannon
    LD L, <Enemy_X_Position         ;save as horizontal coordinate of bullet bill
    LD A, (DE)
    LD (HL), A
;
    LD E, <Cannon_Y_Position        ;get vertical coordinate of cannon
    LD L, <Enemy_Y_Position         ;subtract eight pixels (because enemies are 24 pixels tall)
    LD A, (DE)
    SUB A, $08
    LD (HL), A                      ;save as vertical coordinate of bullet bill
;
    LD A, $01
    LD L, <Enemy_Y_HighPos          ;set vertical high byte of bullet bill
    LD (HL), A
    LD L, <Enemy_Flag               ;set buffer flag
    LD (HL), A
    XOR A
    LD L, <Enemy_State              ;initialize enemy's state
    LD (HL), A
;
    LD L, <Enemy_BoundBoxCtrl       ;set bounding box size control for bullet bill
    LD (HL), $09
;
    LD L, <Enemy_ID                 ;load identifier for bullet bill (cannon variant)
    LD (HL), OBJECTID_BulletBill_CannonVar
    JP Next3Slt                     ;move onto next slot
;
Chk_BB:
    LD L, <Enemy_ID                 ;check enemy identifier for bullet bill (cannon variant)
    LD A, (HL)
    CP A, OBJECTID_BulletBill_CannonVar
    JP NZ, Next3Slt                 ;if not found, branch to get next slot
    CALL OffscreenBoundsCheck       ;otherwise, check to see if it went offscreen
    LD L, <Enemy_Flag               ;check enemy buffer flag
    LD A, (HL)
    OR A
    CALL NZ, BulletBillHandler      ;if set, do sub to handle bullet bill
Next3Slt:
    DEC H                           ;move onto next slot
    LD A, H
    CP A, $C0
    JP NZ, ThreeSChk                ;do this until first three slots are checked
    RET

;--------------------------------

BulletBillHandler:
    CALL GetEnemyOffscreenBits      ;get offscreen information
;
    LD A, (TimerControl)            ;if master timer control set,
    OR A
    JP NZ, RunBBSubs
;
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    JP NZ, ChkDSte                  ;if bullet bill's state set, branch to check defeated state
;
    LD A, (Enemy_OffscrBits)        ;otherwise load offscreen bits
    AND A, %00001100                ;mask out bits
    CP A, %00001100                 ;check to see if all bits are set
    JP Z, EraseEnemyObject          ;if so, branch to kill this object
;
    LD C, $01                       ;set to move right by default
    CALL PlayerEnemyDiff            ;get horizontal difference between player and bullet bill
    JP M, SetupBB                   ;if enemy to the left of player, branch
    INC C                           ;otherwise increment to move left
;
SetupBB:
    LD L, <Enemy_MovingDir          ;set bullet bill's moving direction
    LD (HL), C
    DEC C                           ;decrement to use as offset

    .IF PALBUILD == $00
    LD A, $18                       ;get horizontal speed based on moving direction
    JP Z, +
    LD A, $E8
    .ELSE
    LD A, $1C                       ;PAL diff: Faster speed to compensate FPS difference
    JP Z, +
    LD A, $E4
    .ENDIF

+:
    LD L, <Enemy_X_Speed            ;and store it
    LD (HL), A
;
    LD A, (Temp_Bytes + $00)        ;get horizontal difference
    CCF                             ;6502 SBC carry to Z80 carry
    ADC A, $28                      ;add 40 pixels
    CP A, $50                       ;if less than a certain amount, player is too close
    JP C, EraseEnemyObject          ;to cannon either on left or right side, thus branch
;
    LD L, <Enemy_State              ;otherwise set bullet bill's state
    LD (HL), $01
;
    LD A, H                         ;set enemy frame timer
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    
    .IF PALBUILD == $00
    LD A, $0A
    .ELSE
    LD A, $09                       ;PAL diff: Faster timer to compensate FPS difference
    .ENDIF
    
    LD (BC), A
;
    LD A, SNDID_CANNON              ;play fireworks/gunfire sound
    LD (SFXTrack1.SoundQueue), A
;
ChkDSte:
    LD L, <Enemy_State              ;check enemy state for d5 set
    LD A, (HL)
    AND A, %00100000
    CALL NZ, MoveD_EnemyVertically  ;if set, do sub to move bullet bill vertically
    CALL MoveEnemyHorizontally      ;do sub to move bullet bill horizontally
RunBBSubs:
    CALL GetEnemyOffscreenBits      ;get offscreen information
    CALL RelativeEnemyPosition      ;get relative coordinates
    CALL GetEnemyBoundBox           ;get bounding box coordinates
    CALL PlayerEnemyCollision       ;handle player to enemy collisions
    JP EnemyGfxHandler              ;draw the bullet bill and leave

;-------------------------------------------------------------------------------------
;$00(D) - used in WhirlpoolActivate to store whirlpool length / 2, page location of center of whirlpool
;and also to store movement force exerted on player
;$01(E) - used in ProcessWhirlpools to store page location of right extent of whirlpool
;and in WhirlpoolActivate to store center of whirlpool
;$02(C) - used in ProcessWhirlpools to store right extent of whirlpool and in
;WhirlpoolActivate to store maximum vertical speed

ProcessWhirlpools:
    LD (Whirlpool_Flag), A          ;initialize whirlpool flag
;
    LD A, (TimerControl)            ;if master timer control set,
    OR A
    RET NZ                          ;branch to leave
;
    LD B, $05                       ;otherwise start with last whirlpool data
    LD H, >Whirlpool_LeftExtent + $04
WhLoop:
    LD L, <Whirlpool_LeftExtent     ;get left extent of whirlpool
    LD A, (HL)
    INC L                           ;Whirlpool_Length
    ADD A, (HL)                     ;add length of whirlpool
    LD C, A                         ;store result as right extent here
    LD L, <Whirlpool_PageLoc        ;get page location
    LD A, (HL)
    ADC A, $00                      ;add carry
    LD E, A                         ;store result as page location of right extent here
    LD A, (HL)                      ;get page location again
    OR A
    JP Z, NextWh                    ;if none or page 0, branch to get next data
    ;
    LD A, (Player_X_Position)       ;get player's horizontal position
    INC L                           ;Whirlpool_LeftExtent
    SUB A, (HL)                     ;subtract left extent
    LD A, (Player_PageLoc)          ;get player's page location
    DEC L                           ;Whirlpool_PageLoc
    SBC A, (HL)                     ;subtract borrow
    JP M, NextWh                    ;if player too far left, branch to get next data
    ;
    LD A, (Player_X_Position)
    LD D, A
    LD A, C                         ;get right extent
    SUB A, D                        ;subtract player's horizontal coordinate
    LD A, (Player_PageLoc)
    LD D, A
    LD A, E                         ;get right extent's page location
    SBC A, D                        ;subtract borrow
    JP P, WhirlpoolActivate         ;if player within right extent, branch to whirlpool code
    ;
NextWh:
    DEC H                           ;move onto next whirlpool data
    DJNZ WhLoop                     ;do this until all whirlpools are checked
    RET

WhirlpoolActivate:
    LD L, <Whirlpool_Length         ;get length of whirlpool
    LD A, (HL)
    SRL A                           ;divide by 2
    LD D, A                         ;save here
;
    DEC L                           ;Whirlpool_LeftExtent
    LD A, (HL)                      ;get left extent of whirlpool
    ADD A, D                        ;add length divided by 2
    LD E, A                         ;save as center of whirlpool
    DEC L                           ;Whirlpool_PageLoc
    LD A, (HL)                      ;get page location
    ADC A, $00                      ;add carry
    LD D, A                         ;save as page location of whirlpool center
;
    LD A, (FrameCounter)            ;get frame counter
    RRCA                            ;shift d0 into carry (to run on every other frame)
    JP NC, WhPull                   ;if d0 not set, branch to last part of code
;
    LD A, (Player_X_Position)
    LD C, A
    LD A, E                         ;get center
    SUB A, C                        ;subtract player's horizontal coordinate
    LD A, (Player_PageLoc)
    LD C, A
    LD A, D                         ;get page location of center
    SBC A, C                        ;subtract borrow
    JP P, LeftWh                    ;if player to the left of center, branch
;
    LD A, (Player_X_Position)       ;otherwise slowly pull player left, towards the center
    SUB A, $01                      ;subtract one pixel
    LD (Player_X_Position), A       ;set player's new horizontal coordinate
    LD A, (Player_PageLoc)
    SBC A, $00                      ;subtract borrow
    JP SetPWh                       ;jump to set player's new page location
;
LeftWh:
    LD A, (Player_CollisionBits)    ;get player's collision bits
    RRCA                            ;shift d0 into carry
    JP NC, WhPull                   ;if d0 not set, branch
;
    LD A, (Player_X_Position)       ;otherwise slowly pull player right, towards the center
    ADD A, $01                      ;add one pixel
    LD (Player_X_Position), A       ;set player's new horizontal coordinate
    LD A, (Player_PageLoc)
    ADC A, $00                      ;add carry
SetPWh:
    LD (Player_PageLoc), A          ;set player's new page location
WhPull:
    LD A, $01                       ;set whirlpool flag to be used later
    LD (Whirlpool_Flag), A
    LD BC, $1001                    ;set vertical movement force and maximum vertical speed
    LD H, >Player_Y_Position        ;set X for player offset              
    JP ImposeGravity_A0             ;jump to put whirlpool effect on player vertically, do not return

;-------------------------------------------------------------------------------------

.SECTION "HammerEnemyOfsData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
HammerEnemyOfsData:
    ; .db $04, $04, $04, $05, $05, $05
    ; .db $06, $06, $06

    .db $C5, $C5, $C5, $C6, $C6, $C6
    .db $C7, $C7, $C7
.ENDS

.SECTION "HammerXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG

HammerXSpdData:
.IF PALBUILD == $00
    .db $10, $f0
.ELSE
    .db $14, $EC                            ;PAL diff: Faster speed to compensate FPS difference
.ENDIF

.ENDS

SpawnHammerObj:
    LD A, (PseudoRandomBitReg+1)            ;get pseudorandom bits from
    AND A, %00000111                        ;second part of LSFR
    JP NZ, SetMOfs                          ;if any bits are set, branch and use as offset
    LD A, (PseudoRandomBitReg+1)            ;get d3 from same part of LSFR
    AND A, %00001000
SetMOfs:
    LD L, A                                 ;use either d3 or d2-d0 for offset here
    LD DE, Misc_State
    ADD A, D
    LD D, A
    LD A, (DE)                              ;if any values loaded in
    OR A                                    ;$2a-$32 where offset is then leave with carry clear
    RET NZ
;    
    LD A, L                                 ;get offset of enemy slot to check using Y as offset
    LD HL, HammerEnemyOfsData
    addAToHL8_M
    LD H, (HL)
    LD L, <Enemy_Flag                       ;check enemy buffer flag at offset
    LD A, (HL)
    OR A                                    ;if buffer flag set, branch to leave with carry clear
    LD HL, (ObjectOffset)                   ;get original enemy object offset in case we leave
    RET NZ
;
    LD A, H
    LD E, <HammerEnemyOffset                ;save enemy offset here
    LD (DE), A
    LD E, <Misc_State                       ;save hammer's state here
    LD A, $90
    LD (DE), A
    LD E, <Misc_BoundBoxCtrl                ;set something else entirely, here
    LD A, $07
    LD (DE), A
    SCF                                     ;return with carry set
    RET

;--------------------------------
;$00(IXL) - used to set downward force
;$01 - used to set upward force (residual)
;$02(IYL) - used to set maximum speed

ProcHammerObj:
    LD A, (TimerControl)                    ;if master timer control set
    OR A
    JP NZ, RunHSubs                         ;skip all of this code and go to last subs at the end
;
    LD L, <Misc_State                       ;otherwise get hammer's state
    LD A, (HL)
    AND A, %01111111                        ;mask out d7
    LD L, <HammerEnemyOffset                ;get enemy object offset that spawned this hammer
    LD D, (HL)
    CP A, $02                               ;check hammer's state
    JP Z, SetHSpd                           ;if currently at 2, branch
    JP NC, SetHPos                          ;if greater than 2, branch elsewhere
    
    .IF PALBUILD == $00
    LD BC, $1004                            ;set downward movement force and maximum vertical speed
    .ELSE
    LD BC, $2304                            ;PAL diff: Faster acceleration to compensate FPS difference
    .ENDIF
    
    ;XOR A                                   ;set A to impose gravity on hammer
    ;CALL ImposeGravity                      ;do sub to impose gravity on hammer and move vertically
    CALL ImposeGravity_A0
    CALL MoveObjectHorizontally             ;do sub to move it horizontally
    CALL PlayerHammerCollision              ;handle collisions
    JP RunHSubs                             ;branch to essential subroutines
;
SetHSpd:
    LD L, <Misc_Y_Speed
    
    .IF PALBUILD == $00
    LD (HL), $FE                            ;set hammer's vertical speed
    .ELSE
    LD (HL), $FD                            ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

    LD E, <Enemy_State                      ;get enemy object state
    LD A, (DE)
    AND A, %11110111                        ;mask out d3
    LD (DE), A                              ;store new state

    LD E, <Enemy_MovingDir                  ;get enemy's moving direction
    LD A, (DE)
    DEC A                                   ;decrement to use as offset
    LD BC, HammerXSpdData                   ;get proper speed to use based on moving direction
    addAToBC8_M
    LD A, (BC)
    LD L, <Misc_X_Speed                     ;set hammer's horizontal speed
    LD (HL), A
;
SetHPos:
    LD L, <Misc_State                       ;decrement hammer's state
    DEC (HL)

    LD E, <Enemy_X_Position                 ;get enemy's horizontal position
    LD L, E
    LD A, (DE)
    ADD A, $02                              ;set position 2 pixels to the right
    LD (HL), A                              ;store as hammer's horizontal position

    LD E, <Enemy_PageLoc                    ;get enemy's page location
    LD L, E
    LD A, (DE)
    ADC A, $00                              ;add carry
    LD (HL), A                              ;store as hammer's page location

    LD E, <Enemy_Y_Position                 ;get enemy's vertical position
    LD L, E
    LD A, (DE)
    SUB A, $0A                              ;move position 10 pixels upward
    LD (HL), A                              ;store as hammer's vertical position

    LD L, <Misc_Y_HighPos                   ;set hammer's vertical high byte
    LD (HL), $01
RunHSubs:
    GetMiscOffscreenBits_M                  ;get offscreen information
    RelativeMiscPosition_M                  ;get relative coordinates
    CALL GetMiscBoundBox                    ;get bounding box coordinates
    CALL DrawHammer                         ;draw the hammer
    JP MiscLoopBack

;-------------------------------------------------------------------------------------

EnemiesAndLoopsCore:
    LD L, <Enemy_Flag
    LD A, (HL)                      ;check data here for MSB set
    OR A
    JP M, ChkBowserF                ;if MSB set in enemy flag, branch ahead of jumps
    JP NZ, RunEnemyObjectsCore      ;if data isn't zero, jump to run enemy subroutines
ChkAreaTsk:
    LD A, (AreaParserTaskNum)       ;check number of tasks to perform
    AND A, $07
    CP A, $07
    RET Z                           ;if at a specific task, jump and leave
    JP ProcLoopCommand              ;otherwise, jump to process loop command/load enemies
ChkBowserF:
    AND A, %00001111                ;mask out high nybble
    ADD A, >Enemy_ID
    LD D, A
    LD E, <Enemy_Flag
    LD A, (DE)                      ;use as pointer and load same place with different offset
    OR A
    RET NZ
    LD (HL), A                      ;if second enemy flag not set, also clear first one
    RET


;--------------------------------

.SECTION "Loop Command Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
; LoopCmdWorldNumber:
;     .db $03, $03, $06, $06, $06, $06, $06, $06, $07, $07, $07

; LoopCmdPageNumber:
;     .db $05, $09, $04, $05, $06, $08, $09, $0a, $06, $0b, $10

; LoopCmdYPosition:
;     .db $40, $b0, $b0, $80, $40, $40, $80, $40, $f0, $f0, $f0

; AreaDataOfsLoopback:
;     .db $12, $36, $0e, $0e, $0e, $32, $32, $32, $0a, $26, $40

LoopCmdData:
    ;.db $12, $40, $05, $03
    ;.db $36, $B0, $09, $03
    .db $20, $40, $05, $03
    .db $70, $B0, $09, $03
    

    ; .db $0E, $B0, $04, $06
    ; .db $0E, $80, $05, $06
    ; .db $0E, $40, $06, $06
    ; .db $32, $40, $08, $06
    ; .db $32, $80, $09, $06
    ; .db $32, $40, $0A, $06
    .db $1C, $B0, $04, $06
    .db $1C, $80, $05, $06
    .db $1C, $40, $06, $06
    .db $60, $40, $08, $06
    .db $60, $80, $09, $06
    .db $60, $40, $0A, $06

    ; .db $0A, $F0, $06, $07
    ; .db $26, $F0, $0B, $07
    ; .db $40, $F0, $10, $07
    .db $0E, $F0, $06, $07
    .db $48, $F0, $0B, $07
    .db $70, $F0, $10, $07
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
    LD A, E                         ;adjust area object offset based on
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
    PUSH HL                         ;save object offset
    LD HL, LoopCmdData + $2C        ;start at the end of each set of loop data
FindLoop:
    DEC L
    LD B, (HL)                      ;store world number in B
    DEC L
    LD C, (HL)                      ;store page number in C
    DEC L
    LD D, (HL)                      ;store y position in D
    DEC L
    LD E, (HL)                      ;store area data offset in E
    LD A, L
    CP A, <LoopCmdData - $04        ;if all data is checked and not match, do not loop
    JP Z, ChkEnemyFrenzy_POP
    LD A, (WorldNumber)             ;check to see if one of the world numbers
    CP A, B                         ;matches our current world number
    JP NZ, FindLoop
    LD A, (CurrentPageLoc)          ;check to see if one of the page numbers
    CP A, C                         ;matches the page we're currently on
    JP NZ, FindLoop
    LD HL, MultiLoopCorrectCntr
    LD A, (Player_Y_Position)       ;check to see if the player is at the correct position
    CP A, D                         ;if not, branch to check for world 7
    JP NZ, WrongChk
    LD A, (Player_State)            ;check to see if the player is
    OR A                            ;on solid ground (i.e. not jumping or falling)
    JP NZ, WrongChk                 ;if not, player fails to pass loop, and loopback
    LD A, (WorldNumber)             ;are we in world 7? (check performed on correct
    CP A, WORLD7                    ;vertical position and on solid ground)
    JP NZ, InitMLp                  ;if not, initialize flags used there, otherwise   
    INC (HL)                        ;increment counter for correct progression
IncMLoop:
    INC L                           ;MultiLoopPassCntr
    INC (HL)                        ;increment master multi-part counter
    LD A, (HL)                      ;have we done all three parts?
    CP A, $03
    JP NZ, InitLCmd                 ;if not, skip this part
    DEC L                           ;MultiLoopCorrectCntr
    LD A, (HL)                      ;if so, have we done them all correctly?
    CP A, $03
    JP Z, InitMLp                   ;if so, branch past unnecessary check here
    JP DoLpBack                     ;unconditional branch if previous branch fails
WrongChk:
    LD A, (WorldNumber)             ;are we in world 7? (check performed on
    CP A, WORLD7                    ;incorrect vertical position or not on solid ground)
    JP Z, IncMLoop
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
    ; FALL THROUGH

;--------------------------------

ChkEnemyFrenzy_POP:
    POP HL
ChkEnemyFrenzy:
    LD A, (EnemyFrenzyQueue)        ;check for enemy object in frenzy queue
    OR A
    JP Z, ProcessEnemyData          ;if not, skip this part
;
    LD L, <Enemy_ID
    LD (HL), A                      ;store as enemy object identifier here
    LD L, <Enemy_Flag
    LD (HL), $01                    ;activate enemy object flag
    XOR A
    LD L, <Enemy_State
    LD (HL), A                      ;initialize state and frenzy queue
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
    LD A, (ScrollLock)                      ;check for scroll lock flag
    OR A
    RET Z                                   ;branch if not set to leave
;
    LD A, (Player_Y_Position)               ;check to see if player's vertical coordinate has
    LD C, A
    LD A, (Player_Y_HighPos)                ;same bits set as in vertical high byte (why?)
    AND A, C
    RET NZ                                  ;if so, branch to leave
;
    LD (ScrollLock), A                      ;otherwise nullify scroll lock flag
    LD A, (WarpZoneControl)                 ;increment warp zone flag to make warp pipes for warp zone
    INC A
    LD (WarpZoneControl), A
    JP EraseEnemyObject                     ;kill this object


;--------------------------------

PowerUpObjHandler:
    POP HL
;
    LD HL, Enemy_State_05                   ;set object offset for last slot in enemy object buffer
    LD (ObjectOffset), HL
;
    LD A, (HL)                              ;check power-up object's state
    OR A
    RET Z                                   ;if not set, branch to leave
;
    JP P, GrowThePowerUp                    ;if d7 not set, branch ahead to skip this part
;
    LD A, (TimerControl)                    ;if master timer control set,
    OR A
    JP NZ, RunPUSubs                        ;branch ahead to enemy object routines
;
    LD A, (PowerUpType)                     ;check power-up type
    OR A
    JP Z, ShroomM                           ;if normal mushroom, branch ahead to move it
;
    CP A, $03
    JP Z, ShroomM                           ;if 1-up mushroom, branch ahead to move it
;
    CP A, $02
    JP NZ, RunPUSubs                        ;if not star, branch elsewhere to skip movement
;
    CALL MoveJumpingEnemy_NOPOP             ;otherwise impose gravity on star power-up and make it jump
    CALL EnemyJump                          ;note that green paratroopa shares the same code here
    JP RunPUSubs                            ;then jump to other power-up subroutines
;
ShroomM:
    CALL MoveNormalEnemy_NOPOP              ;do sub to make mushrooms move
    CALL EnemyToBGCollisionDet              ;deal with collisions
    JP RunPUSubs                            ;run the other subroutines

GrowThePowerUp:
    LD A, (FrameCounter)                    ;get frame counter
    AND A, $03                              ;mask out all but 2 LSB
    JP NZ, ChkPUSte                         ;if any bits set here, branch
;
    LD L, <Enemy_Y_Position                 ;otherwise decrement vertical coordinate slowly
    DEC (HL)
;
    LD L, <Enemy_State                      ;load power-up object state
    LD A, (HL)
    INC (HL)                                ;increment state for next frame (to make power-up rise)
    CP A, $11                               ;if power-up object state not yet past 16th pixel,
    JP C, ChkPUSte                          ;branch ahead to last part here
;
    LD A, %10000000                         ;otherwise set d7 in power-up object's state
    LD (HL), A
    ;ADD A, A                                ;shift once to init A
    ;LD (Enemy_SprAttrib_05), A
    ;RLA                                     ;rotate A to set right moving direction
    RLCA
    LD L, <Enemy_MovingDir                  ;set moving direction
    LD (HL), A
;
    LD L, <Enemy_X_Speed                    ;set horizontal speed
    LD (HL), $10
;
ChkPUSte:
    LD A, (Enemy_State_05)                  ;check power-up object's state
    CP A, $06                               ;for if power-up has risen enough
    RET C                                   ;if not, don't even bother running these routines
;
RunPUSubs:
    CALL RelativeEnemyPosition              ;get coordinates relative to screen
    CALL GetEnemyOffscreenBits              ;get offscreen bits
    CALL GetEnemyBoundBox                   ;get bounding box coordinates
    CALL DrawPowerUp                        ;draw the power-up object
    CALL PlayerEnemyCollision               ;check for collision with player
    JP OffscreenBoundsCheck                 ;check to see if it went offscreen

;--------------------------------

; .SECTION "Jumpspring_Y_PosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; Jumpspring_Y_PosData:
;     .db $08, $10, $08, $00
; .ENDS

JumpspringHandler:
    POP HL
;
    CALL GetEnemyOffscreenBits              ;get offscreen information
;
    LD A, (TimerControl)                    ;check master timer control
    OR A
    JP NZ, DrawJSpr                         ;branch to last section if set
;   
    LD A, (JumpspringAnimCtrl)              ;check jumpspring frame control
    OR A
    JP Z, DrawJSpr                          ;branch to last section if not set
;
    DEC A                                   ;subtract one from frame control,
    LD C, A
    AND A, %00000010                        ;mask out all but d1, original value still in C
    LD A, (Player_Y_Position)
    JP NZ, DownJSpr                         ;if set, branch to move player up
    ADD A, $02                              ;move player's vertical position down two pixels
    JP PosJSpr                              ;skip to next part
DownJSpr:
    SUB A, $02                              ;move player's vertical position up two pixels
PosJSpr:
    LD (Player_Y_Position), A
;
    LD A, C                                 ;check frame control offset (second frame is $00)
    CP A, $01
    JP C, BounceJS                          ;if offset not yet at third frame ($01), skip to next part
    LD A, (A_B_Buttons)
    AND A, bitValue(SMS_BTN_2)              ;check saved controller bits for A button press
    JP Z, BounceJS                          ;skip to next part if A not pressed
    LD E, A
    LD A, (PreviousA_B_Buttons)             ;check for A button pressed in previous frame
    AND A, E
    JP NZ, BounceJS                         ;skip to next part if so
    
    .IF PALBUILD == $00
    LD A, $F4
    .ELSE
    LD A, $F2                               ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF
    
    LD (JumpspringForce), A                 ;otherwise write new jumpspring force here
;
BounceJS:
    LD A, C                                 ;check frame control offset again
    CP A, $03
    JP NZ, DrawJSpr                         ;skip to last part if not yet at fifth frame ($03)
    LD A, (JumpspringForce)                 ;store jumpspring force as player's new vertical speed
    LD (Player_Y_Speed), A
    
    .IF PALBUILD != $00
    LD A, $40                               ;PAL bugfix: Define vertical acceleration on springs (was undefined on NTSC)
    LD (VerticalForce), A
    .ENDIF
    
    XOR A                                   ;initialize jumpspring frame control
    LD (JumpspringAnimCtrl), A
;
DrawJSpr:
    CALL RelativeEnemyPosition              ;get jumpspring's relative coordinates
    LD A, (Enemy_OffscrBits)
    BIT 2, A
    CALL Z, JumpspringGfxHandler            ;draw jumpspring if right side is onscreen
    LD HL, (ObjectOffset)
    CALL OffscreenBoundsCheck               ;check to see if we need to kill it
    LD A, (JumpspringAnimCtrl)              ;if frame control at zero, don't bother
    OR A
    RET Z                                   ;trying to animate it, just leave
    LD A, (JumpspringTimer)                 ;if jumpspring timer not expired yet, leave
    OR A
    RET NZ
    LD A, $04                               ;otherwise initialize jumpspring timer
    LD (JumpspringTimer), A
    LD A, (JumpspringAnimCtrl)              ;increment frame control to animate jumpspring
    INC A
    LD (JumpspringAnimCtrl), A
    RET


;--------------------------------
;$06-$07 - used as address to block buffer data
;$02(IXL) - used as vertical high nybble of block buffer offset

; .SECTION "VineHeightData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; VineHeightData:
;     .db $30, $60
; .ENDS

VineObjectHandler:
    POP HL
;
    LD A, H
    CP A, $C6                               ;check enemy offset for special use slot
    RET NZ                                  ;if not in last slot, branch to leave
;
    LD A, (VineFlagOffset)                  ;decrement vine flag, use as offset
    DEC A
    LD C, $30
    JP Z, +
    LD C, $60
+:
    LD A, (VineHeight)                      ;if vine has reached certain height,
    CP A, C                                 ;branch ahead to skip this part
    JP Z, RunVSubs
;
    LD A, (FrameCounter)                    ;get frame counter
    RRCA
    RRCA
    JP NC, RunVSubs                         ;if d1 not set (2 frames every 4) skip this part
;
    LD L, <Enemy_Y_Position                 ;subtract vertical position of vine
    DEC (HL)
    LD A, (VineHeight)                      ;increment vine height
    INC A
    LD (VineHeight), A
;
RunVSubs:
    LD A, (VineHeight)                      ;if vine still very small,
    CP A, $08                               ;branch to leave
    RET C
    CALL RelativeEnemyPosition              ;get relative coordinates of vine,
    CALL GetEnemyOffscreenBits              ;and any offscreen bits
    EX DE, HL
    XOR A                                   ;initialize offset used in draw vine sub
    CALL DrawVine                           ;draw vine
    LD A, (VineFlagOffset)                  ;check if offset is 2
    DEC A
    CALL NZ, DrawVine                       ;if so, draw more vine
;
    LD A, (Enemy_OffscrBits)
    AND A, %00001100                        ;mask offscreen bits
    JP Z, WrCMTile                          ;if none of the saved offscreen bits set, skip ahead
;
    LD E, C                                 ;get offset used in draw vine sub
    LD A, E
KillVine:
    LD HL, VineObjOffset                    ;get enemy object offset for this vine object
    ADD A, H
    LD H, A
    LD H, (HL)
    CALL EraseEnemyObject                   ;kill this vine object
    DEC E                                   ;decrement offset
    JP P, KillVine                          ;if any vine objects left, loop back to kill it
    LD (VineFlagOffset), A                  ;initialize vine flag/offset
    LD (VineHeight), A                      ;initialize vine height
;
WrCMTile:
    EX DE, HL
    LD A, (VineHeight)                      ;check vine height
    CP A, $20                               ;if vine small (less than 32 pixels tall)
    RET C                                   ;then branch ahead to leave
    ;LD H, $C6
    ;LD A, $01
    LD BC, $0410
    ;LD C, $1B                               ;set C to offset to get block at ($04, $10) of coordinates
    ;CALL BlockBufferCollision               ;do a sub to get block buffer address set, return contents
    CALL BlockBufferCollision_A1
    LD A, IXL
    CP A, $D0                               ;if vertical high nybble offset beyond extent of
    RET NC                                  ;current block buffer, branch to leave, do not write
    LD A, (DE)                              ;otherwise check contents of block buffer at
    OR A                                    ;current offset, if not empty, branch to leave
    RET NZ
    LD A, MT_VINEBLANK                      ;otherwise, write climbing metatile to block buffer
    LD (DE), A
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
    LD A, (Enemy_OffscrBits)
    BIT 2, A
    CALL Z, RetainerGfxHandler
    LD HL, (ObjectOffset)
    RET

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
    LD A, (AreaType)
    OR A
    CALL NZ, EnemiesCollision   ; 0,
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
    ;CALL ProcFirebar
    CALL GetEnemyOffscreenBits                  ;get offscreen information
    LD A, (Enemy_OffscrBits)                    ;check for d3 set
    AND A, %00001000                            ;if so, branch to leave
    CALL Z, ProcFirebar
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
    LD A, (TimerControl)                    ;if master timer control set,
    OR A
    CALL Z, LargePlatformSubroutines
    CALL RelativeEnemyPosition
    CALL DrawLargePlatform
    JP OffscreenBoundsCheck

;--------------------------------

LargePlatformSubroutines:
    PUSH HL
    LD L, <Enemy_ID
    LD A, (HL)
    SUB A, $24
    RST JumpEngine

    .dw BalancePlatform                     ;table used by objects $24-$2a
    .dw YMovingPlatform
    .dw MoveLargeLiftPlat
    .dw MoveLargeLiftPlat
    .dw XMovingPlatform
    .dw DropPlatform
    .dw RightPlatform

;-------------------------------------------------------------------------------------

EraseEnemyObject:
    XOR A                                   ;clear all enemy object variables
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
    LD A, H                                 ;check enemy timer
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    JP NZ, MoveJ_EnemyVertically            ;branch to move enemy if not expired
;
    PUSH BC                                 ;save enemy timer
    CALL InitPodoboo_NOPOP                  ;otherwise set up podoboo again
;
    LD A, H                                 ;get part of LSFR
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD A, (BC)
    OR A, %10000000                         ;set d7
    LD L, <Enemy_Y_MoveForce                ;store as movement force
    LD (HL), A
;
    POP BC                                  ;get enemy timer back
    AND A, %00001111                        ;mask out high nybble
    OR A, $06                               ;set for at least six intervals
    LD (BC), A                              ;store as new enemy timer
;
    LD L, <Enemy_Y_Speed                    ;set vertical speed to move podoboo upwards
    LD (HL), $F9
;
    JP MoveJ_EnemyVertically                ;branch to impose gravity on podoboo

;--------------------------------
;$00 - used in HammerBroJumpCode as bitmask

;HammerThrowTmrData:
;    .db $30, $1c

.SECTION "XSpeedAdderData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
XSpeedAdderData:
    .db $00, $e8, $00, $18
.ENDS

.SECTION "RevivedXSpeed" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
RevivedXSpeed:
    .db $08, $f8, $0c, $f4
.ENDS

ProcHammerBro:
    POP HL
;
    LD L, <Enemy_State                      ;check hammer bro's enemy state for d5 set
    BIT 5, (HL)
    JP NZ, MoveDefeatedEnemy                ;if set, jump to something else
;
    LD L, <HammerBroJumpTimer               ;check jump timer
    LD A, (HL)
    OR A
    JP Z, HammerBroJumpCode                 ;if expired, branch to jump
;
    DEC (HL)                                ;otherwise decrement jump timer
    LD A, (Enemy_OffscrBits)                ;check offscreen bits
    AND A, %00001100
    JP NZ, MoveHammerBroXDir                ;if hammer bro a little offscreen, skip to movement code
;
    LD L, <HammerThrowingTimer              ;check hammer throwing timer
    LD A, (HL)
    OR A
    JP NZ, DecHT                            ;if not expired, skip ahead, do not throw hammer
    LD A, (SecondaryHardMode)               ;otherwise get secondary hard mode flag
    OR A                                    ;get timer data using flag as offset
    LD A, $30
    JP Z, +
    LD A, $1C
+:
    LD (HL), A                              ;set as new timer
;
    CALL SpawnHammerObj                     ;do a sub here to spawn hammer object
    JP NC, DecHT                            ;if carry clear, hammer not spawned, skip to decrement timer
;
    LD L, <Enemy_State                      ;set d3 in enemy state for hammer throw
    SET 3, (HL)
;
    JP MoveHammerBroXDir                    ;jump to move hammer bro
;
DecHT:
    LD L, <HammerThrowingTimer              ;decrement timer
    DEC (HL)
    JP MoveHammerBroXDir                    ;jump to move hammer bro

; .SECTION "HammerBroJumpLData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; HammerBroJumpLData:
;     .db $20, $37
; .ENDS

HammerBroJumpCode:
    LD L, <Enemy_State                      ;get hammer bro's enemy state
    LD A, (HL)
    AND A, %00000111                        ;mask out all but 3 LSB
    CP A, $01                               ;check for d0 set (for jumping)
    JP Z, MoveHammerBroXDir                 ;if set, branch ahead to moving code
;
    LD A, H 
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
;
    LD DE, $00FA                            ;set default value and vertical speed
    LD L, <Enemy_Y_Position                 ;check hammer bro's vertical coordinate
    LD A, (HL)
    OR A
    JP M, SetHJ                             ;if on the bottom half of the screen, use current speed
    LD E, $FD                               ;otherwise set alternate vertical speed
    CP A, $70                               ;check to see if hammer bro is above the middle of screen
    INC D                                   ;increment preset value to $01
    JP C, SetHJ                             ;if above the middle of the screen, use current speed and $01
    DEC D                                   ;otherwise return value to $00
    LD A, (BC)                              ;get part of LSFR, mask out all but LSB
    AND A, $01
    JP NZ, SetHJ                            ;if d0 of LSFR set, branch and use current speed and $00
    LD E, $FA                               ;otherwise reset to default vertical speed
SetHJ:
    LD L, <Enemy_Y_Speed                    ;set vertical speed for jumping
    LD (HL), E
;
    LD L, <Enemy_State                      ;set d0 in enemy state for jumping
    SET 0, (HL)
;
    INC C                                   ;PseudoRandomBitReg+2
    LD A, (BC)                              ;load part of LSFR
    AND A, D                                ;and do bit-wise comparsion with preset value
    LD E, A                                 ;then use as offset
    LD A, (SecondaryHardMode)               ;check secondary hard mode flag
    OR A
    JP NZ, HJump
    LD E, A                                 ;if secondary hard mode flag clear, set offset to 0
HJump:
    DEC C                                   ;PseudoRandomBitReg+1
    LD A, (BC)                              ;get contents of part of LSFR, set d7 and d6, then
    OR A, %11000000
    LD L, <HammerBroJumpTimer               ;store in jump timer
    LD (HL), A
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, $20                               ;get jump length timer data using offset from before
    DEC E
    JP NZ, +
    LD A, $37
+:
    LD (BC), A                              ;save in enemy timer

MoveHammerBroXDir:

    .IF PALBUILD == $00
    LD C, $FC                               ;move hammer bro a little to the left
    .ELSE
    LD C, $FB                               ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

    LD A, (FrameCounter)                    ;change hammer bro's direction every 64 frames
    AND A, %01000000
    JP NZ, Shimmy
    
    .IF PALBUILD == $00
    LD C, $04                               ;if d6 set in counter, move him a little to the right
    .ELSE
    LD C, $05                               ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

Shimmy:
    LD L, <Enemy_X_Speed                    ;store horizontal speed
    LD (HL), C
;
    LD C, $01                               ;set to face right by default
    CALL PlayerEnemyDiff                    ;get horizontal difference between player and hammer bro
    JP M, SetShim                           ;if enemy to the left of player, skip this part
    INC C                                   ;set to face left
    LD A, H
    SUB A, $C1
    LD DE, EnemyIntervalTimer               ;check walking timer
    addAToDE8_M
    LD A, (DE)
    OR A
    JP NZ, SetShim                          ;if not yet expired, skip to set moving direction
    LD L, <Enemy_X_Speed                    ;otherwise, make the hammer bro walk left towards player

    .IF PALBUILD == $00
    LD (HL), $F8
    .ELSE
    LD (HL), $F6                            ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

SetShim:
    LD L, <Enemy_MovingDir                  ;set moving direction
    LD (HL), C
    JP MoveNormalEnemy_NOPOP

MoveNormalEnemy:
    POP HL
MoveNormalEnemy_NOPOP:
    LD C, $00                               ;init Y to leave horizontal movement as-is
    LD L, <Enemy_State
    LD A, (HL)
    BIT 6, A                                ;check enemy state for d6 set, if set skip
    JP NZ, FallE                            ;to move enemy vertically, then horizontally if necessary
;
    OR A                                    ;check enemy state for d7 set
    JP M, SteadM                            ;if set, branch to move enemy horizontally
;
    BIT 5, A                                ;check enemy state for d5 set
    JP NZ, MoveDefeatedEnemy                ;if set, branch to move defeated enemy object
;
    AND A, %00000111                        ;check d2-d0 of enemy state for any set bits
    JP Z, SteadM                            ;if enemy in normal state, branch to move enemy horizontally
;
    CP A, $05
    JP Z, FallE                             ;if enemy in state used by spiny's egg, go ahead here
;
    CP A, $03
    JP NC, ReviveStunned                    ;if enemy in states $03 or $04, skip ahead to yet another part
;
FallE:
    CALL MoveD_EnemyVertically              ;do a sub here to move enemy downwards
    LD C, $00
    LD L, <Enemy_State                      ;check for enemy state $02
    LD A, (HL)
    CP A, $02
    JP Z, MoveEnemyHorizontally             ;if found, branch to move enemy horizontally
;
    AND A, %01000000                        ;check for d6 set
    JP Z, SteadM                            ;if not set, branch to something else
;
    LD L, <Enemy_ID                         ;check for power-up object
    LD A, (HL)
    CP A, OBJECTID_PowerUpObject
    JP Z, SteadM
    ; FALL THROUGH

SlowM:
    LD C, $01                               ;increment Y to slow horizontal movement
SteadM:
    LD L, <Enemy_X_Speed                    ;get current horizontal speed
    LD A, (HL)
    PUSH AF                                 ;save to stack
    OR A
    JP P, AddHS                             ;if not moving or moving right, skip, leave Y alone
    INC C                                   ;otherwise increment Y to next data
    INC C
AddHS:
    LD A, C
    LD BC, XSpeedAdderData                  ;add value here to slow enemy down if necessary
    addAToBC8_M
    LD A, (BC)
    ADD A, (HL)
    LD (HL), A                              ;save as horizontal speed temporarily
;
    CALL MoveEnemyHorizontally              ;then do a sub to move horizontally
;
    POP AF
    LD L, <Enemy_X_Speed                    ;get old horizontal speed from stack and return to
    LD (HL), A                              ;original memory location, then leave
    RET

ReviveStunned:
    LD A, H                                 ;if enemy timer not expired yet,
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    JP NZ, ChkKillGoomba                    ;skip ahead to something else
;
    LD L, <Enemy_State                      ;otherwise initialize enemy state to normal
    LD (HL), A
;
    LD A, (FrameCounter)                    ;get d0 of frame counter
    AND A, $01
    LD C, A                                 ;use as Y and increment for movement direction
    INC C
    LD L, <Enemy_MovingDir                  ;store as pseudorandom movement direction
    LD (HL), C
;
    DEC C                                   ;decrement for use as pointer
    LD A, (PrimaryHardMode)                 ;check primary hard mode flag
    OR A
    JP Z, SetRSpd                           ;if not set, use pointer as-is
    INC C                                   ;otherwise increment 2 bytes to next data
    INC C
SetRSpd:
    LD A, C                                 ;load and store new horizontal speed
    LD BC, RevivedXSpeed
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_X_Speed
    LD (HL), A
    RET

MoveDefeatedEnemy:
    CALL MoveD_EnemyVertically              ;execute sub to move defeated enemy downwards
    JP MoveEnemyHorizontally                ;now move defeated enemy horizontally

ChkKillGoomba:

    .IF PALBUILD == $00
    CP A, $0E                               ;check to see if enemy timer has reached
    .ELSE
    CP A, $0B                               ;PAL diff: Faster timer to compensate FPS difference
    .ENDIF

    RET NZ                                  ;a certain point, and branch to leave if not
;
    LD L, <Enemy_ID                         ;check for goomba object
    LD A, (HL)
    CP A, OBJECTID_Goomba
    RET NZ                                  ;branch if not found
;
    JP EraseEnemyObject                     ;otherwise, kill this goomba object

;--------------------------------

MoveJumpingEnemy:
    POP HL
MoveJumpingEnemy_NOPOP:
    CALL MoveJ_EnemyVertically              ;do a sub to impose gravity on green paratroopa
    JP MoveEnemyHorizontally                ;jump to move enemy horizontally

;--------------------------------

ProcMoveRedPTroopa:
    POP HL
;
    LD L, <Enemy_Y_Speed                    ;check for any vertical force or speed
    LD A, (HL)
    LD L, <Enemy_Y_MoveForce
    OR A, (HL)
    JP NZ, MoveRedPTUpOrDown                ;branch if any found
;
    LD L, <Enemy_YMF_Dummy                  ;initialize something here
    LD (HL), A
;
    LD L, <Enemy_Y_Position                 ;check current vs. original vertical coordinate
    LD A, (HL)
    LD L, <RedPTroopaOrigXPos
    CP A, (HL)
    JP NC, MoveRedPTUpOrDown                ;if current => original, skip ahead to more code
;
    LD A, (FrameCounter)                    ;get frame counter
    AND A, %00000111                        ;mask out all but 3 LSB
    RET NZ                                  ;if any bits set, branch to leave
;
    LD L, <Enemy_Y_Position                 ;otherwise increment red paratroopa's vertical position
    INC (HL)
    RET

MoveRedPTUpOrDown:
    LD L, <Enemy_Y_Position                 ;check current vs. central vertical coordinate
    LD A, (HL)
    LD L, <RedPTroopaCenterYPos
    CP A, (HL)
    JP C, MoveRedPTroopaDown                ;if current < central, jump to move downwards
    JP MoveRedPTroopaUp                     ;otherwise jump to move upwards

;--------------------------------
;$00(N/A) - used to store adder for movement, also used as adder for platform
;$01 - used to store maximum value for secondary counter

MoveFlyGreenPTroopa:
    POP HL
;
    CALL XMoveCntr_GreenPTroopa             ;do sub to increment primary and secondary counters
    CALL MoveWithXMCntrs                    ;do sub to move green paratroopa accordingly, and horizontally
;
    LD A, (FrameCounter)
    AND A, %00000011                        ;check frame counter 2 LSB for any bits set
    RET NZ                                  ;branch to leave if set to move up/down every fourth frame
;
    LD A, (FrameCounter)                    ;check frame counter for d6 set
    AND A, %01000000
    LD A, $01                               ;set Y to move green paratroopa down
    JP NZ, YSway                            ;branch to move green paratroopa down if set
    LD A, $FF
YSway:
    ;LD A, C
    ;LD (Temp_Bytes + $00), A                ;store adder here
    LD L, <Enemy_Y_Position                 ;add or subtract from vertical position
    ;LD A, (HL)
    ;ADD A, C
    ADD A, (HL)
    LD (HL), A                              ;to give green paratroopa a wavy flight
    RET

XMoveCntr_GreenPTroopa:
    LD A, $13                               ;load preset maximum value for secondary counter

XMoveCntr_Platform:
    LD (Temp_Bytes + $01), A                ;store value here
;
    LD A, (FrameCounter)                    ;branch to leave if not on
    AND A, %00000011
    RET NZ                                  ;every fourth frame
;
    LD L, <XMoveSecondaryCounter            ;get secondary counter
    LD C, (HL)
    LD L, <XMovePrimaryCounter              ;get primary counter
    LD A, (HL)
    SRL A
    JP C, DecSeXM                           ;if d0 of primary counter set, branch elsewhere
    LD A, (Temp_Bytes + $01)                ;compare secondary counter to preset maximum value
    CP A, C
    JP Z, IncPXM                            ;if equal, branch ahead of this part
    LD L, <XMoveSecondaryCounter            ;increment secondary counter and leave
    INC (HL)
    RET
IncPXM:
    LD L, <XMovePrimaryCounter              ;increment primary counter and leave
    INC (HL)
    RET
DecSeXM:
    LD A, C                                 ;put secondary counter in A
    OR A
    JP Z, IncPXM                            ;if secondary counter at zero, branch back
    LD L, <XMoveSecondaryCounter            ;otherwise decrement secondary counter and leave
    DEC (HL)
    RET

MoveWithXMCntrs:
    LD L, <XMoveSecondaryCounter            ;save secondary counter to stack
    LD A, (HL)
    EX AF, AF' ;PUSH AF
;
    LD C, $01                               ;set value here by default
    LD L, <XMovePrimaryCounter
    LD A, (HL)
    AND A, %00000010                        ;if d1 of primary counter is
    JP NZ, XMRight                          ;set, branch ahead of this part here
;
    LD L, <XMoveSecondaryCounter            ;otherwise change secondary
    LD A, (HL)                              ;counter to two's compliment
    NEG
    LD (HL), A
    LD C, $02                               ;load alternate value here
;
XMRight:
    LD L, <Enemy_MovingDir                  ;store as moving direction
    LD (HL), C
    CALL MoveEnemyHorizontally
    LD (Temp_Bytes + $00), A                ;save value obtained from sub here
    EX AF, AF' ;POP AF                                  ;get secondary counter from stack
    LD L, <XMoveSecondaryCounter            ;and return to original place
    LD (HL), A
    RET

;--------------------------------

; .SECTION "BlooberBitmasks" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; BlooberBitmasks:
;     .db %00111111, %00000011
; .ENDS

MoveBloober:
    POP HL
;
    LD L, <Enemy_State                      ;check enemy state for d5 set
    LD A, (HL)
    AND A, %00100000
    JP NZ, MoveEnemySlowVert                ;branch if set to move defeated bloober
;
    LD A, H                                 ;get LSFR
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD A, (BC)
    LD C, A

    LD A, (SecondaryHardMode)               ;use secondary hard mode flag as offset
    OR A

    .IF PALBUILD == $00
    LD A, %00111111
    JP Z, +
    LD A, %00000011
    .ELSE
    LD A, %00000111                         ;PAL diff: Faster swim to compensate FPS difference
    JP Z, +
    LD A, %00000001
    .ENDIF

+:
    AND A, C                                ;mask out bits in LSFR using bitmask loaded with offset
    JP NZ, BlooberSwim                      ;if any bits set, skip ahead to make swim
;
    LD A, (Player_MovingDir)                ;load player's moving direction in C
    LD C, A
    LD A, H                                 ;check to see if on second or fourth slot (1 or 3)
    SUB A, $C1
    RRCA
    JP C, SBMDir                            ;if so, do an unconditional branch to set
    LD C, $02                               ;set left moving direction by default
    CALL PlayerEnemyDiff                    ;get horizontal difference between player and bloober
    JP P, SBMDir                            ;if enemy to the right of player, keep left
    DEC C                                   ;otherwise decrement to set right moving direction
SBMDir:
    LD L, <Enemy_MovingDir                  ;set moving direction of bloober, then continue on here
    LD (HL), C

BlooberSwim:
    CALL ProcSwimmingB                      ;execute sub to make bloober swim characteristically
;
    LD L, <Enemy_Y_Position                 ;get vertical coordinate
    LD A, (HL)
    LD L, <Enemy_Y_MoveForce
    SUB A, (HL)                             ;subtract movement force
    CP A, $20                               ;check to see if position is above edge of status bar
    JP C, SwimX                             ;if so, don't do it
    LD L, <Enemy_Y_Position                 ;otherwise, set new vertical position, make bloober swim
    LD (HL), A
SwimX:
    LD L, <Enemy_MovingDir                  ;check moving direction
    LD A, (HL)
    DEC A
    JP NZ, LeftSwim                         ;if moving to the left, branch to second part
;
    LD L, <BlooperMoveSpeed                 ;add movement speed to horizontal coordinate
    LD A, (HL)
    LD L, <Enemy_X_Position
    ADD A, (HL)
    LD (HL), A                              ;store result as new horizontal coordinate
    LD L, <Enemy_PageLoc
    LD A, (HL)                              ;add carry to page location     
    ADC A, $00                              ;store as new page location and leave
    LD (HL), A
    RET

LeftSwim:
    LD L, <Enemy_X_Position                 ;subtract movement speed from horizontal coordinate
    LD A, (HL)
    LD L, <BlooperMoveSpeed
    SUB A, (HL)
    LD L, <Enemy_X_Position                 ;store result as new horizontal coordinate
    LD (HL), A
    LD L, <Enemy_PageLoc                    ;subtract borrow from page location
    LD A, (HL)
    SBC A, $00
    LD (HL), A                              ;store as new page location and leave
    RET
    
ProcSwimmingB:
    LD A, H                                 ;put enemy timer address in BC
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
;
    LD L, <BlooperMoveCounter               ;get enemy's movement counter
    LD A, (HL)
    AND A, %00000010                        ;check for d1 set
    JP NZ, ChkForFloatdown                  ;branch if set
;
    LD A, (FrameCounter)
    AND A, %00000111                        ;get 3 LSB of frame counter
    RET NZ ;PUSH AF                         ;branch to leave, execute code only every eighth frame
    LD L, <BlooperMoveCounter               ;get enemy's movement counter
    LD A, (HL)                              ;check for d0 set
    RRCA
    JP C, SlowSwim                          ;branch if set
    ;POP AF
    ;RET NZ
;
    LD L, <Enemy_Y_MoveForce                ;add to movement force to speed up swim
    LD A, (HL)
    INC A
    LD (HL), A                              ;set movement force
    LD L, <BlooperMoveSpeed                 ;set as movement speed
    LD (HL), A
    CP A, $02
    RET NZ                                  ;if certain horizontal speed, branch to leave
;
    LD L, <BlooperMoveCounter               ;otherwise increment movement counter
    INC (HL)
    RET

SlowSwim:
    ;POP AF
    ;RET NZ
;
    LD L, <Enemy_Y_MoveForce                ;subtract from movement force to slow swim
    LD A, (HL)
    DEC A
    LD (HL), A                              ;set movement force
    LD L, <BlooperMoveSpeed                 ;set as movement speed
    LD (HL), A
    RET NZ                                  ;if any speed, branch to leave
;
    LD L, <BlooperMoveCounter               ;otherwise increment movement counter
    INC (HL)
;
    LD A, $02                               ;set enemy's timer
    LD (BC), A
    RET

ChkForFloatdown:
    LD A, (BC)                              ;get enemy timer
    OR A
    JP Z, ChkNearPlayer                     ;branch if expired

Floatdown:
    LD A, (FrameCounter)                    ;get frame counter
    RRCA                                    ;check for d0 set
    RET C                                   ;branch to leave on every other frame
;
    LD L, <Enemy_Y_Position                 ;otherwise increment vertical coordinate
    INC (HL)
    RET

ChkNearPlayer:
    LD A, (Player_Y_Position)               ;store player's vertical coordinate in C
    LD C, A
    LD L, <Enemy_Y_Position                 ;get vertical coordinate
    LD A, (HL)

    .IF PALBUILD == $00                     ;CHECK FOR 6502 CARRY?
    ADD A, $10                              ;add sixteen pixels           
    .ELSE
    ADD A, $0C                              ;add twelve pixels;PAL bugfix: Bloopers can get closer vertically
    .ENDIF

    CP A, C                                 ;compare result with player's vertical coordinate
    JP C, Floatdown                         ;if modified vertical less than player's, branch
;
    LD L, <BlooperMoveCounter               ;otherwise nullify movement counter
    LD (HL), $00
    RET

;--------------------------------

MoveBulletBill:
    POP HL
;
    LD L, <Enemy_State                      ;check bullet bill's enemy object state for d5 set
    LD A, (HL)
    AND A, %00100000
    JP NZ, MoveJ_EnemyVertically            ;if set, jump to move defeated bullet bill downwards
;
    LD L, <Enemy_X_Speed                    ;set bullet bill's horizontal speed
    LD (HL), $E8                            ;and move it accordingly (note: this bullet bill
    JP MoveEnemyHorizontally                ;object occurs in frenzy object $17, not from cannons)

;--------------------------------
;$02(C) - used to hold preset values
;$03(B) - used to hold enemy state

; .SECTION "SwimCCXMoveData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; SwimCCXMoveData:
;     .db $40, $80
;     .db $04, $04 ;residual data, not used
; .ENDS

MoveSwimmingCheepCheep:
    POP HL
;
    LD L, <Enemy_State                      ;check cheep-cheep's enemy object state
    LD A, (HL)
    AND A, %00100000                        ;for d5 set
    JP NZ, MoveEnemySlowVert                ;if set, jump to move defeated cheep-cheep downwards
;
    LD B, A                                 ;save enemy state in B
    LD L, <Enemy_ID                         ;get enemy identifier
    LD A, (HL)
    SUB A, $0A                              ;subtract ten for cheep-cheep identifiers
    LD A, $40                               ;use as offset
    JP Z, +
    ADD A, A    ; $80
+:
    LD C, A                                 ;store value here
;
    LD L, <Enemy_X_MoveForce                ;load horizontal force
    LD A, (HL)
    SUB A, C                                ;subtract preset value from horizontal force
    LD (HL), A                              ;store as new horizontal force
    LD L, <Enemy_X_Position                 ;get horizontal coordinate
    LD A, (HL)                              ;subtract borrow (thus moving it slowly)
    SBC A, $00
    LD (HL), A                              ;and save as new horizontal coordinate
    LD L, <Enemy_PageLoc                    ;subtract borrow again, this time from the
    LD A, (HL)                              ;page location, then save
    SBC A, $00
    LD (HL), A
;
    LD A, H                                 ;check enemy object offset
    CP A, >Enemy_ID_02                      ;if in first or second slot, branch to leave
    RET C
;
    LD C, $20                               ;save new value here
    LD L, <CheepCheepMoveMFlag              ;check movement flag
    LD A, (HL)
    CP A, $10                               ;if movement speed set to $00,
    JP C, CCSwimUpwards                     ;branch to move upwards
;
    LD L, <Enemy_YMF_Dummy                  ;add preset value to dummy variable to get carry
    LD A, (HL)
    ADD A, C
    LD (HL), A                              ;and save dummy
    LD L, <Enemy_Y_Position                 ;get vertical coordinate
    LD A, (HL)                              ;add carry to it plus enemy state to slowly move it downwards
    ADC A, B
    LD (HL), A                              ;save as new vertical coordinate
    LD L, <Enemy_Y_HighPos                  ;add carry to page location and
    LD A, (HL)
    ADC A, $00
    JP ChkSwimYPos                          ;jump to end of movement code

CCSwimUpwards:
    LD L, <Enemy_YMF_Dummy                  ;subtract preset value to dummy variable to get borrow
    LD A, (HL)
    SUB A, C
    LD (HL), A                              ;and save dummy
    LD L, <Enemy_Y_Position                 ;get vertical coordinate
    LD A, (HL)                              ;subtract borrow to it plus enemy state to slowly move it upwards
    SBC A, B
    LD (HL), A                              ;save as new vertical coordinate
    LD L, <Enemy_Y_HighPos                  ;subtract borrow from page location
    LD A, (HL)
    SBC A, $00
    ; FALL THROUGH

ChkSwimYPos:
    LD (HL), A                              ;save new page location here
    LD C, $00                               ;load movement speed to upwards by default
    LD L, <Enemy_Y_Position                 ;get vertical coordinate
    LD A, (HL)
    LD L, <CheepCheepOrigYPos               ;subtract original coordinate from current
    SUB A, (HL)
    JP P, YPDiff                            ;if result positive, skip to next part
    LD C, $10                               ;otherwise load movement speed to downwards
    NEG                                     ;get two's compliment of result
YPDiff:
    CP A, $0F                               ;if difference between original vs. current vertical
    RET C                                   ;coordinates < 15 pixels, leave movement speed alone
    LD L, <CheepCheepMoveMFlag              ;otherwise change movement speed
    LD (HL), C
    RET

;--------------------------------
;$00(IXH) - used as counter for firebar parts
;$01(C) - used for oscillated high byte of spin state or to hold horizontal adder
;$02(IXL) - used for oscillated high byte of spin state or to hold vertical adder
;$03(B) - used for mirror data
;$04(C) - used to store player's sprite 1 X coordinate
;$05(N/A) - used to evaluate mirror data
;$06(L) - used to store screen X coordinate
;$07(H) - used to store screen Y coordinate
;$ed(IYH) - used to hold maximum length of firebar
;$ef(IYL) - used to hold high byte of spinstate

;horizontal adder is at first byte + high byte of spinstate,
;vertical adder is same + 8 bytes, two's compliment
;if greater than $08 for proper oscillation

.SECTION "FirebarPosLookupTbl" BANK BANK_SLOT2 SLOT 2 ALIGN $100 RETURNORG ;FREE BITWINDOW 8 RETURNORG
; FirebarPosLookupTbl:        ;FirebarTblOffsets[] + OSCILLATED SPINSTATE HIGH BYTE
;     .db $00, $01, $03, $04, $05, $06, $07, $07, $08
;     .db $00, $03, $06, $09, $0b, $0d, $0e, $0f, $10
;     .db $00, $04, $09, $0d, $10, $13, $16, $17, $18
;     .db $00, $06, $0c, $12, $16, $1a, $1d, $1f, $20
;     .db $00, $07, $0f, $16, $1c, $21, $25, $27, $28
;     .db $00, $09, $12, $1b, $21, $27, $2c, $2f, $30
;     .db $00, $0b, $15, $1f, $27, $2e, $33, $37, $38
;     .db $00, $0c, $18, $24, $2d, $35, $3b, $3e, $40
;     .db $00, $0e, $1b, $28, $32, $3b, $42, $46, $48
;     .db $00, $0f, $1f, $2d, $38, $42, $4a, $4e, $50
;     .db $00, $11, $22, $31, $3e, $49, $51, $56, $58

; FirebarMirrorData:          ;SPINSTATE HIGH BYTE
;     .db $01, $03, $02, $00

; FirebarTblOffsets:          ;LOOP INDEX
;     .db $00, $09, $12, $1b, $24, $2d
;     .db $36, $3f, $48, $51, $5a, $63

;FirebarYPos:
;    .db $0c, $18

FirebarPosLookupTbl:
    .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $01, $03, $04, $06, $07, $09, $0b, $0c, $0e, $0f, $11
    .db $03, $06, $09, $0c, $0f, $12, $15, $18, $1b, $1f, $22
    .db $04, $09, $0d, $12, $16, $1b, $1f, $24, $28, $2d, $31
    .db $05, $0b, $10, $16, $1c, $21, $27, $2d, $32, $38, $3e
    .db $06, $0d, $13, $1a, $21, $27, $2e, $35, $3b, $42, $49
    .db $07, $0e, $16, $1d, $25, $2c, $33, $3b, $42, $4a, $51
    .db $07, $0f, $17, $1f, $27, $2f, $37, $3e, $46, $4e, $56
    .db $08, $10, $18, $20, $28, $30, $38, $40, $48, $50, $58

FirebarMirrorData:
    .db $FE, $7F, $7E, $00 
.ENDS

ProcFirebar:
    ;CALL GetEnemyOffscreenBits                  ;get offscreen information
    ;LD A, (Enemy_OffscrBits)                    ;check for d3 set
    ;AND A, %00001000                            ;if so, branch to leave
    ;RET NZ
;
    LD A, (TimerControl)                        ;if master timer control set, branch
    OR A
    JR NZ, SusFbar                              ;ahead of this part
;
    LD L, <FirebarSpinSpeed                     ;load spinning speed of firebar
    LD B, (HL)                                  ;save spinning speed here
;FirebarSpin:
    LD L, <FirebarSpinDirection                 ;check spinning direction
    LD A, (HL)
    OR A
    LD L, <FirebarSpinState_Low
    LD A, (HL)
    JR NZ, SpinCounterClockwise                 ;if moving counter-clockwise, branch to other part                               
    ADD A, B                                    ;add spinning speed to what would normally be                                 
    LD (HL), A                                  ;the horizontal speed
    LD L, <FirebarSpinState_High
    LD A, (HL)
    ADC A, $00                                  ;add carry to what would normally be the vertical speed
    JP FirebarSpinDone

SpinCounterClockwise:
    SUB A, B                                    ;subtract spinning speed to what would normally be
    LD (HL), A                                  ;the horizontal speed
    LD L, <FirebarSpinState_High                ;add carry to what would normally be the vertical speed
    LD A, (HL)
    SBC A, $00

FirebarSpinDone:
    AND A, %00011111                            ;mask out all but 5 LSB
    LD (HL), A                                  ;and store as new high byte of spinstate
;
SusFbar:
    LD L, <Enemy_ID                             ;check enemy identifier
    LD A, (HL)
    CP A, $1F
    LD L, <FirebarSpinState_High              
    LD A, (HL)
    JR C, SetupGFB                              ;if < $1f (long firebar), branch
    CP A, $08                                   ;check high byte of spinstate
    JR Z, SkpFSte                               ;if eight, branch to change
    CP A, $18
    JR NZ, SetupGFB                             ;if not at twenty-four branch to not change
SkpFSte:
    INC A                                       ;add one to spinning thing to avoid horizontal state
    LD (HL), A
;
SetupGFB:
    LD I, A                                     ;save high byte of spinning thing, modified or otherwise
;
    CALL RelativeEnemyPosition                  ;get relative coordinates to screen
;
    LD L, <Enemy_SprDataOffset                  ;get OAM data offset
    LD E, (HL)
    LD D, >Sprite_Y_Position
    LD A, (Enemy_Rel_YPos)                      ;get relative vertical coordinate
    LD IXL, A                                   ;also save here
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A                                  ;store as Y in OAM data
    LD A, (Enemy_Rel_XPos)                      ;get relative horizontal coordinate
    SLA E
    SET 7, E
    LD (DE), A                                  ;store as X in OAM data
    LD IXH, A                                   ;also save here
    CALL FirebarCollision                       ;draw fireball part and do collision detection
;
    LD IYH, $05                                 ;load value for short firebars by default
    LD L, <Enemy_ID                             ;check enemy identifier
    LD A, (HL)
    CP A, $1F                                   ;are we doing a long firebar?
    JR C, SetMFbar                              ;no, branch then
    LD IYH, $0B                                 ;otherwise load value for long firebars
SetMFbar:
    PUSH HL                                     ;(SMS)save Object_Offset

GetFirebarPosition:                             ;this was moved out of DrawFbar for performance
    LD A, I
    AND A, %00001111                            ;mask out low nybble
    CP A, $09
    JR C, GetHAdder                             ;if lower than $09, branch ahead
    XOR A, %00001111                            ;otherwise get two's compliment to oscillate
    INC A
GetHAdder:
    LD C, A                                     ;use as index into FirebarPosLookupTbl
    ADD A, A
    ADD A, C
    ADD A, A
    ADD A, A
    SUB A, C
    LD H, >FirebarPosLookupTbl
    LD L, A
;
    LD A, I                                     ;get A back
    ADD A, $08                                  ;add eight this time, to get vertical adder
    AND A, %00001111                            ;mask out high nybble
    CP A, $09                                   ;if lower than $09, branch ahead
    JR C, GetVAdder                             ;otherwise get two's compliment
    XOR A, %00001111
    INC A
GetVAdder:
    LD C, A                                     ;use index into FirebarPosLookupTbl
    ADD A, A
    ADD A, C
    ADD A, A
    ADD A, A
    SUB A, C
    LD B, H
    LD C, A

DrawFbar:
    PUSH HL
    LD A, I                                     ;get A one last time
    RRCA                                        ;divide by eight or shift three to the right
    RRCA
    RRCA
    AND A, $1F
    LD HL, FirebarMirrorData                    ;use as offset
    addAToHL8_M
    LD A, (HL)                                  ;load mirroring data here
    LD IXL, A
    POP HL

    CALL DrawFirebar_Collision
    LD A, IYH
    CP A, $07
    JP NZ, NextFbar
    LD DE, (DuplicateObj_Offset)                ;if we arrive at fifth firebar part,
    LD E, <Enemy_SprDataOffset                  ;get offset from long firebar and load OAM data offset
    LD A, (DE)
    ADD A, A
    OR A, $80
    LD E, A
    LD D, >Sprite_X_Position
NextFbar:
    INC L                                       ;move onto the next firebar part
    INC C
    DEC IYH                                     ;if we end up at the maximum part, go on and leave
    JP NZ, DrawFbar                             ;otherwise go back and do another
    POP HL                                      ;(SMS)restore Object_Offset
    RET

;   HL: H ADDER PTR
;   BC: V ADDER PTR
;   DE: SAT PTR
;   IXL - MIRROR BYTE
DrawFirebar_Collision:
    LD A, (HL)                                  ;load horizontal adder we got from position loader
    INC IXL                                     ;shift LSB of mirror data
    JP M, AddHA                                 ;if carry was set, skip this part
    NEG                                         ;otherwise get two's compliment of horizontal adder
AddHA:
    LD IXH, A
    LD A, (Enemy_Rel_XPos)                      ;store Enemy_Rel_XPos in IYL
    LD IYL, A                                   ;add horizontal coordinate relative to screen to
    ADD A, IXH                                  ;horizontal adder, modified or otherwise
    LD IXH, A                                   ;store here for now
    LD (DE), A                                  ;store as X coordinate here
    CP A, IYL                                   ;compare X coordinate of sprite to original X of firebar
    JR NC, SubtR1                               ;if sprite coordinate => original coordinate, branch
    LD A, IYL                                   ;otherwise subtract sprite X from the
    SUB A, IXH                                  ;original one and skip this part
    JP ChkFOfs
    
SubtR1:
    SUB A, IYL                                  ;subtract original X from the current sprite X
ChkFOfs:
    CP A, $59                                   ;if difference of coordinates within a certain range,
    JR C, VAHandl                               ;continue by handling vertical adder
    LD A, YPOS_OFFSCREEN_LOGICAL                ;otherwise, load offscreen Y coordinate
    JP SetVFbr                                  ;and unconditionally branch to move sprite offscreen
VAHandl:
    LD A, (Enemy_Rel_YPos)                      ;if vertical relative coordinate offscreen,
    CP A, YPOS_OFFSCREEN_LOGICAL                ;skip ahead of this part and write into sprite Y coordinate
    JR Z, SetVFbr
    INC IXL                                     ;shift LSB of mirror data one more time
    LD IXL, A
    LD A, (BC)                                  ;load vertical adder we got from position loader
    JP M, AddVA                                 ;if carry was set, skip this part
    NEG                                         ;otherwise get two's compliment of second part
AddVA:
    ADD A, IXL                                  ;add vertical coordinate relative to screen to the second data
SetVFbr:
    LD IXL, A                                   ;also store here for now
    SUB A, SMS_PIXELYOFFSET
    RES 7, E
    SRL E
    LD (DE), A                                  ;store as Y coordinate here
    SLA E
    SET 7, E
    ; FALL THROUGH

;   HL: H ADDER PTR (NOT USED, BUT SHOULDN'T BE TOUCHED)
;   BC: V ADDER PTR (NOT USED, BUT SHOULDN'T BE TOUCHED)
;   DE: Sprite X Pos PTR
;   IX: XPOS/YPOS
FirebarCollision:
    INC E                                       ;draw current tile of firebar
    LD A, (FrameCounter)
    RRCA
    RRCA
    AND A, $03
    ADD A, $21
    LD (DE), A
    INC E                                       ;move to next sprite entry
;
    LD A, (TimerControl)                        ;if star mario invincibility timer
    LD IYL, A
    LD A, (StarInvincibleTimer)                 ;or master timer controls set
    OR A, IYL
    RET NZ                                      ;then skip all of this
;
    LD IYL, A                                   ;otherwise initialize counter
    LD A, (Player_Y_HighPos)                    ;if player's vertical high byte offscreen,
    DEC A
    RET NZ                                      ;skip all of this
    LD A, (Player_Y_Position)                   ;get player's vertical position
    LD A, (PlayerSize)                          ;get player's size
    OR A
    JR NZ, AdjSm                                ;if player small, branch to alter variables
    LD A, (CrouchingFlag)
    OR A
    LD A, (Player_Y_Position)
    JR Z, FBCLoop                               ;if player big and not crouching, jump ahead
AdjSm:                                          ;if small or big but crouching, execute this part
    LD IYL, $02                                 ;first increment our counter twice (setting $02 as flag)
    LD A, (Player_Y_Position)
    ADD A, $18                                  ;then add 24 pixels to the player's vertical coordinate                                   
;
FBCLoop:
    SUB A, IXL                                  ;subtract vertical position of firebar from the player's
    JP P, ChkVFBD                               ;if player lower on the screen than firebar, skip two's compliment part 
    NEG                                         ;otherwise get two's compliment                          
ChkVFBD:
    CP A, $08                                   ;if difference => 8 pixels, skip ahead of this part
    JR NC, Chk2Ofs
    LD A, IXH                                   ;if firebar on far right on the screen, skip this,
    CP A, $F0                                   ;because, really, what's the point?
    JR NC, Chk2Ofs
    LD A, (Sprite_X_Position + $02)             ;get OAM X coordinate for sprite #1
    ADD A, $04                                  ;add four pixels
    SUB A, IXH                                  ;subtract horizontal coordinate of firebar from the X coordinate of player's sprite 1
    JP P, ChkFBCl                               ;if modded X coordinate to the right of firebar, skip two's compliment part
    NEG                                         ;otherwise get two's compliment
ChkFBCl:
    CP A, $08                                   ;if difference < 8 pixels, collision, thus branch
    JR C, ChgSDir                               ;to process
Chk2Ofs:
    LD A, IYL                                   ;if value of $02 was set earlier for whatever reason,
    CP A, $02                                   ;branch to increment OAM offset and leave, no collision
    RET Z
    OR A                                        ;otherwise get temp here and use as offset
    LD A, (Player_Y_Position)
    JR Z, +
    ADD A, $0C
+:
    ADD A, $0C                                  ;add value loaded with offset to player's vertical coordinate
    INC IYL                                     ;then increment temp and jump back
    JP FBCLoop
;
ChgSDir:
    LD A, (Sprite_X_Position + $02)             ;if OAM X coordinate of player's sprite 1
    ADD A, $04
    CP A, IXH                                   ;is greater than horizontal coordinate of firebar
    LD A, $01                                   ;set movement direction by default
    JR NC, SetSDir                              ;then do not alter movement direction
    INC A                                       ;otherwise increment it
SetSDir:
    LD (Enemy_MovingDir), A                     ;store movement direction here
    PUSH BC
    PUSH DE                                     ;save SAT Address
    CALL InjurePlayer                           ;perform sub to hurt or kill player
    POP DE                                      ;restore SAT Address
    POP BC
    RET

;--------------------------------

.SECTION "PRandomSubtracter/FlyCCBPriority" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
PRandomSubtracter:
    .db $f8, $a0, $70, $bd, $00
FlyCCBPriority:
    .db $20, $20, $20, $00, $00

    .db $B5, $1E, $29, $20, $F0, $08            ;6502 code spill over when indexing PRandomSubtracter
.ENDS

MoveFlyingCheepCheep:
    POP HL
;

.IF PALBUILD == $00
    LD L, <Enemy_State                          ;check cheep-cheep's enemy state
    LD A, (HL)
    AND A, %00100000                            ;for d5 set
    JP NZ, MoveJ_EnemyVertically                ;if set, move defeated cheep-cheep downwards
;
    CALL MoveEnemyHorizontally                  ;move cheep-cheep horizontally based on speed and force
    LD BC, $0D05                                ;set vertical movement amount and max speed
    CALL ImposeGravity_A0                       ;branch to impose gravity on flying cheep-cheep
;
    LD L, <Enemy_Y_MoveForce                    ;get vertical movement force and
    LD A, (HL)                                  ;move high nybble to low
    RRCA
    RRCA
    RRCA
    RRCA
    AND A, $0F
    LD BC, PRandomSubtracter                    ;use as offset (note this tends to go into reach of code)
    addAToBC8_M
    LD A, (BC)
    LD C, A
    LD L, <Enemy_Y_Position                     ;get vertical position
    LD A, (HL)
    SUB A, C                                    ;subtract pseudorandom value based on offset from position
    JP P, AddCCF                                ;if result within top half of screen, skip this part
    NEG                                         ;otherwise get two's compliment
AddCCF:
    CP A, $08                                   ;if result or two's compliment greater than eight,
    RET NC                                      ;skip to the end without changing movement force
    LD L, <Enemy_Y_MoveForce                    ;otherwise add to it
    LD A, (HL)
    ADD A, $10
    LD (HL), A
    RET

.ELSE                                           ;PAL diff: reworked movement function for Cheep Cheeps
    LD BC, $2005
    LD L, <Enemy_State
    LD A, (HL)
    AND A, %00100000
    JP NZ, FlyCC
    CALL MoveEnemyHorizontally
    LD BC, $1705
FlyCC:
    JP ImposeGravity_A0
.ENDIF

;--------------------------------
;$00 - used to hold horizontal difference
;$01-$03 - used to hold difference adjusters

;LakituDiffAdj:
;    .db $15, $30, $40

MoveLakitu:
    POP HL
;
    LD L, <Enemy_State                          ;check lakitu's enemy state
    LD A, (HL)
    BIT 5, A                                    ;for d5 set
    JP NZ, MoveD_EnemyVertically                ;if set, jump to move defeated lakitu downwards
;
    OR A                                        ;if lakitu's enemy state not set at all,
    JP Z, Fr12S                                 ;go ahead and continue with code
;
    XOR A
    LD L, <LakituMoveDirection                  ;otherwise initialize moving direction to move to left
    LD (HL), A
    LD (EnemyFrenzyBuffer), A                   ;initialize frenzy buffer
    LD A, $10
    JP SetLSpd                                  ;load horizontal speed and do unconditional branch
;
Fr12S:
    LD A, OBJECTID_Spiny
    LD (EnemyFrenzyBuffer), A                   ;set spiny identifier in frenzy buffer
;
    LD A, $40
    LD (Temp_Bytes + $03), A                    ;load values
    LD A, $30
    LD (Temp_Bytes + $02), A 
    LD A, $15
    LD (Temp_Bytes + $01), A
;
    CALL PlayerLakituDiff                       ;execute sub to set speed and create spinys
;
SetLSpd:
    LD L, <LakituMoveSpeed                      ;set movement speed returned from sub
    LD (HL), A
    LD C, $01                                   ;set moving direction to right by default
    LD L, <LakituMoveDirection
    LD A, (HL)
    AND A, $01                                  ;get LSB of moving direction
    JP NZ, SetLMov                              ;if set, branch to the end to use moving direction
    LD L, <LakituMoveSpeed                      ;get two's compliment of moving speed
    LD A, (HL)
    NEG
    LD (HL), A                                  ;store as new moving speed
    INC C                                       ;increment moving direction to left
SetLMov:
    LD L, <Enemy_MovingDir                      ;store moving direction
    LD (HL), C
    JP MoveEnemyHorizontally                    ;move lakitu horizontally

PlayerLakituDiff:
    LD C, $00                                   ;set Y for default value
    CALL PlayerEnemyDiff                        ;get horizontal difference between enemy and player
    JP P, ChkLakDif                             ;branch if enemy is to the right of the player
    INC C                                       ;increment Y for left of player
    LD A, (Temp_Bytes + $00)                    ;get two's compliment of low byte of horizontal difference
    NEG
    LD (Temp_Bytes + $00), A
;
ChkLakDif:
    LD A, (Temp_Bytes + $00)                    ;get low byte of horizontal difference
    CP A, $3C                                   ;if within a certain distance of player, branch
    JP C, ChkPSpeed
    LD A, $3C                                   ;otherwise set maximum distance
    LD (Temp_Bytes + $00), A
;
    LD L, <Enemy_ID                             ;check if lakitu is in our current enemy slot
    LD A, (HL)
    CP A, OBJECTID_Lakitu
    JP NZ, ChkPSpeed                            ;if not, branch elsewhere
    LD A, C                                     ;compare contents of C, now in A
    LD L, <LakituMoveDirection                  ;to what is being used as horizontal movement direction
    CP A, (HL)
    JP Z, ChkPSpeed                             ;if moving toward the player, branch, do not alter
    LD A, (HL)                                  ;if moving to the left beyond maximum distance,
    OR A
    JP Z, SetLMovD                              ;branch and alter without delay
    LD L, <LakituMoveSpeed                      ;decrement horizontal speed
    DEC (HL)
    RET NZ
SetLMovD:
    LD L, <LakituMoveDirection                  ;set horizontal direction depending on horizontal
    LD (HL), C                                  ;difference between enemy and player if necessary
;
ChkPSpeed:
    LD A, (Temp_Bytes + $00)
    AND A, %00111100                            ;mask out all but four bits in the middle
    RRCA                                        ;divide masked difference by four                          
    RRCA
    LD (Temp_Bytes + $00), A                    ;store as new value
    LD E, A                                     ;save in E for later loop
;
    LD C, $00                                   ;init offset
    LD A, (Player_X_Speed)
    OR A
    JP Z, SubDifAdj                             ;if player not moving horizontally, branch
    LD A, (ScrollAmount)
    OR A
    JP Z, SubDifAdj                             ;if scroll speed not set, branch to same place
    INC C                                       ;otherwise increment offset
    LD A, (Player_X_Speed)

    .IF PALBUILD == $00
    CP A, $19                                   ;if player not running, branch
    .ELSE
    CP A, $1D                                   ;PAL diff: Faster speed cutoffs to compensate FPS difference
    .ENDIF

    JP C, ChkSpinyO
    LD A, (ScrollAmount)                        ;if scroll speed below a certain amount, branch
    CP A, $02
    JP C, ChkSpinyO                             ;to same place
    INC C                                       ;otherwise increment once more
;
ChkSpinyO:
    LD L, <Enemy_ID                             ;check for spiny object
    LD A, (HL)
    CP A, OBJECTID_Spiny
    JP NZ, ChkEmySpd                            ;branch if not found
    LD A, (Player_X_Speed)                      ;if player not moving, skip this part
    OR A
    JP NZ, SubDifAdj
ChkEmySpd:
    LD L, <Enemy_Y_Speed                        ;check vertical speed
    LD A, (HL)
    OR A
    JP NZ, SubDifAdj                            ;branch if nonzero
    LD C, $00                                   ;otherwise reinit offset
SubDifAdj:
    LD A, C
    LD BC, Temp_Bytes + $01                     ;get one of three saved values from earlier
    addAToBC8_M
    LD A, (BC)
    LD B, E                                     ;get saved horizontal difference
    INC B
SPixelLak:
    DEC A                                       ;subtract one for each pixel of horizontal difference
    DJNZ SPixelLak                              ;from one of three saved values
    RET

;-------------------------------------------------------------------------------------

.SECTION "BridgeCollapseData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
BridgeCollapseData:
    .dw $6374   ;axe
    .dw $63F0   ;chain
    .dw $6470, $646C, $6468, $6464, $6460, $645C, $6458 ; bridge
    .dw $6454, $6450, $644C, $6448, $6444, $6440
.ENDS

BridgeCollapse:
    LD HL, (BowserFront_Offset - 1)             ;get enemy offset for bowser
    LD L, <Enemy_ID                             ;check enemy object identifier for bowser
    LD A, (HL)
    CP A, OBJECTID_Bowser                       ;if not found, branch ahead,
    JP NZ, SetM2                                ;metatile removal not necessary
;
    LD (ObjectOffset), HL                       ;store as enemy offset here
    LD L, <Enemy_State                          ;if bowser in normal state, skip all of this
    LD A, (HL)
    OR A
    JP Z, RemoveBridge
;
    AND A, %01000000                            ;if bowser's state has d6 clear, skip to silence music
    JP Z, SetM2
;
    LD L, <Enemy_Y_Position                     ;check bowser's vertical coordinate
    LD A, (HL)
    CP A, $E0                                   ;if bowser not yet low enough, skip this part ahead
    JP C, MoveD_Bowser
    ; FALL THROUGH

SetM2:
    LD A, SNDID_SILENCE                         ;silence music
    LD (MusicTrack0.SoundQueue), A              ;EVENT
    LD HL, OperMode_Task                        ;move onto next secondary mode in autoctrl mode
    INC (HL)
    JP KillAllEnemies                           ;jump to empty all enemy slots and then leave

MoveD_Bowser:
    CALL MoveEnemySlowVert                      ;do a sub to move bowser downwards
    JP BowserGfxHandler                         ;jump to draw bowser's front and rear, then leave

RemoveBridge:
    LD A, (BowserFeetCounter)                   ;decrement timer to control bowser's feet
    DEC A
    LD (BowserFeetCounter), A
    JP NZ, BowserGfxHandler                     ;if not expired, skip all of this
;
    LD A, $04                                   ;otherwise, set timer now
    LD (BowserFeetCounter), A
    LD A, (BowserBodyControls)                  ;invert bit to control bowser's feet
    XOR A, $01
    LD (BowserBodyControls), A
;
    LD DE, (VRAM_Buffer1_Ptr)                   ;load vram buffer offset
    LD A, (BridgeCollapseOffset)                ;get bridge collapse offset here
    ADD A, A
    LD HL, BridgeCollapseData                   ;load name table address
    addAToHL8_M
    LD C, (HL)
    INC L
    LD B, (HL)
    LD HL, BlockGfxData + $18                   ;set offset for tile data for sub to draw blank metatile
    CALL RemBridge                              ;do sub here to remove bowser's bridge metatiles
;
    LD HL, (ObjectOffset)                       ;get enemy offset
    LD A, SNDID_CANNON                          ;load the fireworks/gunfire sound into the square 2 sfx
    LD (SFXTrack1.SoundQueue), A                ;queue while at the same time loading the brick
    LD A, SNDID_SHATTER                         ;shatter sound into the noise sfx queue thus
    LD (SFXTrack2.SoundQueue), A                ;producing the unique sound of the bridge collapsing
    LD A, (BridgeCollapseOffset)                ;increment bridge collapse offset
    INC A
    LD (BridgeCollapseOffset), A
    CP A, $0F                                   ;if bridge collapse offset has not yet reached
    JP NZ, BowserGfxHandler                     ;the end, go ahead and skip this part
    CALL InitVStf                               ;initialize whatever vertical speed bowser has
    LD L, <Enemy_State                          ;set bowser's state to one of defeated states (d6 set)
    LD (HL), %01000000
    LD A, SNDID_FALL                            ;play bowser defeat sound
    LD (SFXTrack1.SoundQueue), A
    JP BowserGfxHandler                         ;jump to code that draws bowser

;--------------------------------

.SECTION "PRandomRange" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
PRandomRange:
    .db $21, $41, $11, $31
.ENDS

RunBowser:
    POP HL
;
    LD L, <Enemy_State                          ;if d5 in enemy state is not set
    LD A, (HL)
    AND A, %00100000                            ;then branch elsewhere to run bowser
    JP Z, BowserControl
;
    LD L, <Enemy_Y_Position                     ;otherwise check vertical position
    LD A, (HL)
    CP A, $E0                                   ;if above a certain point, branch to move defeated bowser
    JP C, MoveD_Bowser                          ;otherwise proceed to KillAllEnemies
    ; FALL THROUGH

KillAllEnemies:
    LD H, >Enemy_ID_04                          ;start with last enemy slot
KillLoop:
    CALL EraseEnemyObject                       ;branch to kill enemy objects
    DEC H                                       ;move onto next enemy slot
    LD A, H
    CP A, >Enemy_ID - $01
    JP NZ, KillLoop                             ;do this until all slots are emptied
;
    XOR A                                       ;empty frenzy buffer
    LD (EnemyFrenzyBuffer), A
;
    LD HL, (ObjectOffset)                       ;get enemy object offset and leave
    RET

BowserControl:
    XOR A
    LD (EnemyFrenzyBuffer), A                   ;empty frenzy buffer
;
    LD A, (TimerControl)                        ;if master timer control set,
    OR A
    JP NZ, ChkFireB                             ;jump over a bunch of code
;
    LD A, (BowserBodyControls)                  ;check bowser's mouth
    OR A
    JP M, HammerChk                             ;if bit set, skip a whole section starting here
;
    LD A, (BowserFeetCounter)                   ;decrement timer to control bowser's feet
    DEC A
    LD (BowserFeetCounter), A
    JP NZ, ResetMDr                             ;if not expired, skip this part
;
    LD A, $20                                   ;otherwise, reset timer
    LD (BowserFeetCounter), A
    LD A, (BowserBodyControls)
    XOR A, %00000001                            ;and invert bit used
    LD (BowserBodyControls), A                  ;to control bowser's feet
;
ResetMDr:
    LD A, (FrameCounter)                        ;check frame counter
    AND A, %00001111                            ;if not on every sixteenth frame, skip
    JP NZ, B_FaceP                              ;ahead to continue code
    LD L, <Enemy_MovingDir                      ;otherwise reset moving/facing direction every
    LD (HL), $02                                ;sixteen frames
;
B_FaceP:
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, (BC)                                  ;if timer set here expired,
    OR A
    JP Z, GetPRCmp                              ;branch to next section
    CALL PlayerEnemyDiff                        ;get horizontal difference between player and bowser,
    JP P, GetPRCmp                              ;and branch if bowser to the right of the player
;
    LD L, <Enemy_MovingDir                      ;set bowser to move and face to the right
    LD (HL), $01
    LD A, $02
    LD (BowserMovementSpeed), A                 ;set movement speed
    LD A, $20
    LD (BC), A                                  ;set timer here
    LD (BowserFireBreathTimer), A               ;set timer used for bowser's flame
    LD L, <Enemy_X_Position
    LD A, (HL)
    CP A, $C8                                   ;if bowser to the right past a certain point,
    JP NC, HammerChk                            ;skip ahead to some other section
;
GetPRCmp:
    LD A, (FrameCounter)                        ;skip ahead to some other section
    AND A, %00000011
    JP NZ, HammerChk                            ;execute this code every fourth frame, otherwise branch
    LD A, (BowserOrigXPos)
    LD L, <Enemy_X_Position
    CP A, (HL)                                  ;if bowser not at original horizontal position,
    JP NZ, GetDToO                              ;branch to skip this part
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)                                  ;get pseudorandom offset
    AND A, %00000011
    LD BC, PRandomRange
    addAToBC8_M
    LD A, (BC)                                  ;load value using pseudorandom offset
    LD (MaxRangeFromOrigin), A                  ;and store here
;
GetDToO:
    LD A, (BowserOrigXPos)
    LD B, A
    LD A, (MaxRangeFromOrigin)
    LD C, A

    LD A, (BowserMovementSpeed)                 ;add movement speed to bowser's horizontal
    LD L, <Enemy_X_Position                     ;coordinate and save as new horizontal position
    ADD A, (HL)
    LD (HL), A
    LD L, <Enemy_MovingDir
    BIT 0, (HL)                                 ;if bowser moving and facing to the right, skip ahead
    JP NZ, HammerChk
    SUB A, B                                    ;get difference of current vs. original horizontal position
    LD B, $FF                                   ;set default movement speed here (move left)
    JP P, CompDToO                              ;if current position to the right of original, skip ahead
    LD B, $01                                   ;set alternate movement
    NEG                                         ;get two's compliment
CompDToO:
    CP A, C                                     ;compare difference with pseudorandom value
    JP C, HammerChk                             ;if difference < pseudorandom value, leave speed alone
    LD A, B
    LD (BowserMovementSpeed), A                 ;otherwise change bowser's movement speed
;
HammerChk:
    LD A, H
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, (BC)                                  ;if timer set here not expired yet, skip ahead to
    OR A
    JP NZ, MakeBJump                            ;some other section of code
    PUSH BC                                     ;save frame timer address
    CALL MoveEnemySlowVert                      ;otherwise start by moving bowser downwards
    LD A, (WorldNumber)                         ;check world number
    CP A, WORLD6
    JP C, SetHmrTmr                             ;if world 1-5, skip this part (not time to throw hammers yet)
    LD A, (FrameCounter)
    AND A, %00000011                            ;check to see if it's time to execute sub
    CALL Z, SpawnHammerObj                      ;if so, execute sub on every fourth frame to spawn misc object (hammer)
SetHmrTmr:
    POP DE                                      ;put frame timer address in DE
    LD L, <Enemy_Y_Position                     ;get current vertical position
    LD A, (HL)
    CP A, $80                                   ;if still above a certain point
    JP C, ChkFireB                              ;then skip to world number check for flames
    LD A, H
    SUB A, $C1
    LD BC, PseudoRandomBitReg
    addAToBC8_M
    LD A, (BC)                                  ;get pseudorandom offset
    AND A, %00000011
    LD BC, PRandomRange
    addAToBC8_M
    LD A, (BC)                                  ;get value using pseudorandom offset
    LD (DE), A                                  ;set for timer here
    JP ChkFireB                                 ;jump to execute flames code
;
MakeBJump:
    DEC A                                       ;if timer not yet about to expire,
    JP NZ, ChkFireB                             ;skip ahead to next part
    LD L, <Enemy_Y_Position                     ;otherwise decrement vertical coordinate
    DEC (HL)
    CALL InitVStf                               ;initialize movement amount
    LD L, <Enemy_Y_Speed                        ;set vertical speed to move bowser upwards
    LD (HL), $FE
;
ChkFireB:
    LD A, (WorldNumber)                         ;check world number here
    CP A, WORLD8                                ;world 8?
    JP Z, SpawnFBr                              ;if so, execute this part here
    CP A, WORLD6                                ;world 6-7?
    JP NC, BowserGfxHandler                     ;if so, skip this part here
SpawnFBr:
    LD A, (BowserFireBreathTimer)               ;check timer here
    OR A
    JP NZ, BowserGfxHandler                     ;if not expired yet, skip all of this
    LD A, $20
    LD (BowserFireBreathTimer), A               ;set timer here
    LD A, (BowserBodyControls)
    XOR A, %10000000                            ;invert bowser's mouth bit to open
    LD (BowserBodyControls), A                  ;and close bowser's mouth
    JP M, ChkFireB                              ;if bowser's mouth open, loop back
    CALL SetFlameTimer                          ;get timing for bowser's flame
    LD C, A
    LD A, (SecondaryHardMode)
    OR A
    LD A, C
    JP Z, SetFBTmr                              ;if secondary hard mode flag not set, skip this
    SUB A, $10                                  ;otherwise subtract from value in A
SetFBTmr:
    LD (BowserFireBreathTimer), A               ;set value as timer here
    LD A, OBJECTID_BowserFlame                  ;put bowser's flame identifier
    LD (EnemyFrenzyBuffer), A                   ;in enemy frenzy buffer
    ; FALL THROUGH

;--------------------------------

BowserGfxHandler:
    CALL ProcessBowserHalf                      ;do a sub here to process bowser's front
;
    LD L, <Enemy_MovingDir                      ;check moving direction
    LD A, (HL)
    RRCA
    LD A, $10                                   ;load default value here to position bowser's rear
    JP NC, CopyFToR                             ;if moving left, use default
    LD A, $F0                                   ;otherwise load alternate positioning value here
CopyFToR:
    LD DE, (DuplicateObj_Offset)                ;get bowser's rear object offset
    LD L, <Enemy_X_Position
    LD E, L
    ADD A, (HL)                                 ;add to bowser's front object horizontal coordinate
    LD (DE), A                                  ;store A as bowser's rear horizontal coordinate
    LD L, <Enemy_Y_Position
    LD E, L
    LD A, (HL)
    ;ADD A, $08                                  ;add eight pixels to bowser's front object
    LD (DE), A                                  ;vertical coordinate and store as vertical coordinate
    LD L, <Enemy_State
    LD E, L
    LD A, (HL)                                  ;copy enemy state directly from front to rear
    LD (DE), A
    LD L, <Enemy_MovingDir
    LD E, L
    LD A, (HL)                                  ;copy moving direction also
    LD (DE), A
    PUSH HL                                     ;save enemy object offset of front to stack
    LD L, E                                     ;put enemy object offset of rear as current
    LD H, D
    LD (ObjectOffset), HL
    LD L, <Enemy_ID                             ;set bowser's enemy identifier
    LD (HL), OBJECTID_Bowser
    CALL ProcessBowserHalf                      ;do a sub here to process bowser's rear
    POP HL
    LD (ObjectOffset), HL                       ;get original enemy object offset
    XOR A                                       ;nullify bowser's front/rear graphics flag
    LD (BowserGfxFlag), A
    RET

ProcessBowserHalf:
    LD A, (BowserGfxFlag)                       ;increment bowser's graphics flag, then run subroutines
    INC A
    LD (BowserGfxFlag), A
;
    CALL GetEnemyOffscreenBits                  ;to get offscreen bits, relative position and draw bowser
    CALL RelativeEnemyPosition
    LD IY, (BowserDrawRoutine)
    CALL IndirectCallIY
;
    LD L, <Enemy_State
    LD A, (HL)
    OR A
    RET NZ                                      ;if either enemy object not in normal state, branch to leave
;
    LD L, <Enemy_BoundBoxCtrl                   ;set bounding box size control
    LD (HL), $0A
    CALL GetEnemyBoundBox                       ;get bounding box coordinates
    JP PlayerEnemyCollision                     ;do player-to-enemy collision detection

; FRONT: FRAME 0 - MOUTH OPEN, FRAME 1 - MOUTH CLOSED [D7]
; REAR: FRAME 0 - FRONT FOOT UP, FRAME 1 - REAR FOOT UP [D0]

; 00 - FRONT FOOT, MOUTH OPEN
; 01 - FRONT FOOT, MOUTH CLOSED
; 10 - REAR FOOT, MOUTH OPEN
; 11 - REAR FOOT, MOUTH CLOSED

BowserGfxDraw:
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
    SUB A, SMS_PIXELYOFFSET - $08
    LD B, A
    LD A, (Enemy_Rel_XPos)                  ;get enemy object horizontal position
    LD C, A                                 ;relative to screen
    PUSH BC
;
    LD L, <Enemy_SprDataOffset              ;get sprite data offset
    LD E, (HL)
    LD D, >Sprite_Y_Position
;
    LD L, <Enemy_MovingDir                  ;get enemy object moving direction
    LD A, (HL)
    DEC A
    LD HL, BowserSpriteFramesHFlip
    JP Z, +
    LD L, <BowserSpriteFrames
;
+:
    LD A, (BowserGfxFlag)
    DEC A
    JP Z, +
    LD A, $06
    addAToHL8_M
;
+:
    LD A, (BowserBodyControls)
    RRCA
    RRCA
    RRCA
    addAToHL8_M
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    CALL SprObjectOffscrChk
;
    POP BC
    LD A, $F8
    ADD A, B
    LD B, A
    LD A, (BowserGfxFlag)
    DEC A
    LD L, <Enemy_MovingDir
    LD A, (HL)
    LD HL, Bubble_SprDataOffset
    LD E, (HL)
    LD D, >Sprite_Y_Position
    EX DE, HL
    JP Z, FrontExtraSprites
;
    DEC A
    JP NZ, BowserGfxExtraLeftRear
    LD A, (Enemy_OffscrBits)
    AND A, %00000100
    JP NZ, BowserGfxRet
    INC D
    INC D
    LD A, (DE)
    LD L, A
    LD (HL), B
    SLA L
    SET 7, L
    LD A, C
    ADD A, $08
    LD (HL), A
    INC L
    LD (HL), $AE
    JP BowserGfxRet
BowserGfxExtraLeftRear:
    LD A, (Enemy_OffscrBits)
    AND A, %00001000
    JP NZ, BowserGfxRet
    INC D
    INC D
    LD A, (DE)
    LD L, A
    LD (HL), B
    SLA L
    SET 7, L
    LD (HL), C
    INC L
    LD (HL), $95
    JP BowserGfxRet

FrontExtraSprites:
    DEC A
    JP NZ, BowserGfxExtraLeftFront
    LD A, (Enemy_OffscrBits)
    AND A, %00001000
    JP NZ, +
    ; TILE 0
    LD (HL), B
    SLA L
    SET 7, L
    LD (HL), C
    INC L
    LD (HL), $AF
+:
    ; TILE 1
    LD A, C
    ADD A, $08
    LD C, A
    LD A, (Enemy_OffscrBits)
    AND A, %00000100
    JP NZ, BowserGfxRet
    INC D
    LD A, (DE)
    LD L, A
    LD (HL), B
    SLA L
    SET 7, L
    LD (HL), C
    INC L
    LD (HL), $B0
    JP BowserGfxRet
BowserGfxExtraLeftFront:
    LD A, (Enemy_OffscrBits)
    AND A, %00001000
    JP NZ, +
    ; TILE 0
    LD (HL), B
    SLA L
    SET 7, L
    LD (HL), C
    INC L
    LD (HL), $93
+:
    ; TILE 1
    LD A, C
    ADD A, $08
    LD C, A
    LD A, (Enemy_OffscrBits)
    AND A, %00000100
    JP NZ, BowserGfxRet
    INC D
    LD A, (DE)
    LD L, A
    LD (HL), B
    SLA L
    SET 7, L
    LD (HL), C
    INC L
    LD (HL), $94
BowserGfxRet:
    LD HL, (ObjectOffset)
    RET

.SECTION "Bowser Sprite Map Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
BowserSpriteFrames:
    .db $96, $97, $9A, $9B, $9E, $9F ; FRONT FOOT, MOUTH OPEN
    .db $98, $99, $9C, $9D, $A0, $A1
    .db $00, $00, $00, $00

    .db $A2, $A3, $A4, $A5, $9E, $9F ; FRONT FOOT, MOUTH CLOSED
    .db $98, $99, $9C, $9D, $A0, $A1
    .db $00, $00, $00, $00

    .db $96, $97, $A6, $A7, $A8, $A9 ; REAR FOOT, MOUTH OPEN
    .db $98, $99, $9C, $9D, $AA, $AB
    .db $00, $00, $00, $00

    .db $A2, $A3, $AC, $AD, $A8, $A9 ; REAR FOOT, MOUTH CLOSED
    .db $98, $99, $9C, $9D, $AA, $AB

BowserSpriteFramesHFlip:
    .db $B3, $B4, $B7, $B8, $BB, $BC
    .db $B1, $B2, $B5, $B6, $B9, $BA
    .db $00, $00, $00, $00

    .db $BD, $BE, $BF, $C0, $BB, $BC
    .db $B2, $B2, $B5, $B6, $B9, $BA
    .db $00, $00, $00, $00

    .db $B3, $B4, $C1, $C2, $C5, $C6
    .db $B1, $B2, $B5, $B6, $C3, $C4
    .db $00, $00, $00, $00

    .db $BD, $BE, $C7, $C8, $C5, $C6
    .db $B1, $B2, $B5, $B6, $C3, $C4
.ENDS

BowserGfxDraw_NES:
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
    LD B, A
    LD A, (Enemy_Rel_XPos)                  ;get enemy object horizontal position
    LD C, A                                 ;relative to screen
;
    LD L, <Enemy_SprDataOffset              ;get sprite data offset
    LD E, (HL)
    LD D, >Sprite_Y_Position
;
    LD L, <Enemy_MovingDir                  ;get enemy object moving direction
    LD A, (HL)
    DEC A
    LD HL, BowserSpriteFramesHFlip_NES
    JP Z, +
    LD L, <BowserSpriteFrames_NES
;
+:
    LD A, (BowserGfxFlag)
    DEC A
    JP Z, +
    LD A, B
    ADD A, $08
    LD B, A
    LD A, $06
    addAToHL8_M
;
+:
    LD A, (BowserBodyControls)
    RRCA
    RRCA
    RRCA
    addAToHL8_M
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    CALL DrawSpriteObject
    JP SprObjectOffscrChk


.SECTION "Bowser Sprite Map Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
BowserSpriteFrames_NES:
    .db $93, $94, $95, $96, $00, $99
    .db $97, $98, $9A, $9B, $9C, $9D
    .db $00, $00, $00, $00

    .db $93, $94, $9E, $9F, $00, $99
    .db $97, $98, $9A, $9B, $9C, $9D
    .db $00, $00, $00, $00

    .db $93, $94, $95, $96, $00, $99
    .db $97, $98, $9A, $9B, $A0, $A1
    .db $00, $00, $00, $00

    .db $93, $94, $9E, $9F, $00, $99
    .db $97, $98, $9A, $9B, $A0, $A1

BowserSpriteFramesHFlip_NES:
    .db $A2, $A3, $A6, $A7, $AA, $00
    .db $A4, $A5, $A8, $A9, $AB, $AC
    .db $00, $00, $00, $00

    .db $A2, $A3, $AD, $AE, $AA, $00
    .db $A4, $A5, $A8, $A9, $AB, $AC
    .db $00, $00, $00, $00

    .db $A2, $A3, $A6, $A7, $AA, $00
    .db $A4, $A5, $A8, $A9, $AF, $B0
    .db $00, $00, $00, $00

    .db $A2, $A3, $AD, $AE, $AA, $00
    .db $A4, $A5, $A8, $A9, $AF, $B0
.ENDS

;-------------------------------------------------------------------------------------
;$00(B) - used to hold movement force and tile number
;$01 - used to hold sprite attribute data

.SECTION "FlameTimerData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlameTimerData:

    .IF PALBUILD == $00
    .db $bf, $40, $bf, $bf, $bf, $40, $40, $bf
    .ELSE
    .db $80, $30, $30, $80, $80, $80, $30, $50 ;PAL diff: Adjusted timing to compensate FPS difference
    .ENDIF
.ENDS

.SECTION "FlameTileData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlameTileData:
    .db $4B, $4C, $4D   ; NORMAL
    .db $4E, $4F, $50   ; VFLIP
.ENDS

SetFlameTimer:
    LD A, (BowserFlameTimerCtrl)            ;load counter as offset
    LD C, A
    INC A                                   ;increment
    AND A, %00000111                        ;mask out all but 3 LSB
    LD (BowserFlameTimerCtrl), A            ;to keep in range of 0-7
    LD A, C
    LD BC, FlameTimerData                   ;load value to be used then leave
    addAToBC8_M
    LD A, (BC)
    RET

ProcBowserFlame:
    LD A, (TimerControl)                    ;if master timer control flag set,
    OR A
    JP NZ, SetGfxF                          ;skip all of this
;
    LD A, (SecondaryHardMode)               ;if secondary hard mode flag not set, use default
    OR A

    .IF PALBUILD == $00
    LD B, $40                               ;load default movement force
    JP Z, SFlmX
    LD B, $60                               ;otherwise load alternate movement force to go faster
    .ELSE
    LD B, $70                               ;PAL diff: Faster acceleration to compensate FPS difference
    JP Z, SFlmX
    LD B, $90                               ;PAL diff: Faster acceleration to compensate FPS difference
    .ENDIF

SFlmX:
    LD L, <Enemy_X_MoveForce                ;subtract value from movement force
    LD A, (HL)
    SUB A, B
    LD (HL), A                              ;save new value
;
    LD L, <Enemy_X_Position                 ;subtract one from horizontal position to move
    LD A, (HL)                              ;to the left
    SBC A, $01
    LD (HL), A
;
    LD L, <Enemy_PageLoc                    ;subtract borrow from page location
    LD A, (HL)
    SBC A, $00
    LD (HL), A
;
    LD L, <BowserFlamePRandomOfs            ;get some value here and use as offset
    LD A, (HL)
    LD BC, FlameYPosData
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_Y_Position                 ;load vertical coordinate
    CP A, (HL)                              ;compare against coordinate data using $0417,x as offset
    JP Z, SetGfxF                           ;if equal, branch and do not modify coordinate
    LD A, (HL)                              ;otherwise add value here to coordinate and store
    LD L, <Enemy_Y_MoveForce                ;as new vertical coordinate
    ADD A, (HL)
    LD L, <Enemy_Y_Position
    LD (HL), A
;
SetGfxF:
    CALL RelativeEnemyPosition              ;get new relative coordinates
    LD L, <Enemy_State                      ;if bowser's flame not in normal state,
    LD A, (HL)
    OR A
    RET NZ                                  ;branch to leave
;
    LD L, <Enemy_SprDataOffset              ;get OAM data offset
    LD E, (HL)
    LD D, >Sprite_Y_Position
    LD HL, FlameTileData                    ;get tile list based value that changes every two frames
    LD A, (FrameCounter)
    AND A, %00000010
    JP Z, FlmeAt
    LD L, <FlameTileData + $03
FlmeAt:
    LD BC, $03FF                            ;B is number of tiles, C is so LDI doesn't affect B
    ; FALL THROUGH

DrawFlameLoop:
    LD A, (Enemy_Rel_YPos)                  ;get Y relative coordinate of current enemy object
    SUB A, SMS_PIXELYOFFSET
    LD (DE), A                              ;write into Y coordinate of OAM data
    SLA E
    SET 7, E
    LD A, (Enemy_Rel_XPos)                  ;write X relative coordinate of current enemy object
    LD (DE), A
    INC E
    LDI                                     ;write tile number
    RES 7, E
    SRL E
    ADD A, $08                              ;add eight to X rel coord and store
    LD (Enemy_Rel_XPos), A
    DJNZ DrawFlameLoop                      ;do for all tiles
;
    LD HL, (ObjectOffset)                   ;reload original enemy offset
    CALL GetEnemyOffscreenBits              ;get offscreen information
    LD L, <Enemy_SprDataOffset              ;get OAM data offset
    LD E, (HL)
    LD D, >Sprite_Y_Position
    INC E
    INC E
    LD A, (Enemy_OffscrBits)                ;get enemy object offscreen bits
    LD C, A
    LD A, YPOS_OFFSCREEN                    ;load offscreen position
    SRL C
    SRL C
    JP NC, M2FOfs                           ;branch if d1 isn't set
    LD (DE), A                              ;otherwise move third sprite offscreen
M2FOfs:
    DEC E
    SRL C
    JP NC, M1FOfs                           ;branch if d2 isn't set
    LD (DE), A                              ;otherwise move second sprite offscreen
M1FOfs:
    DEC E
    SRL C
    RET NC                                  ;branch if d3 isn't set
    LD (DE), A                              ;otherwise move first sprite offscreen
    RET

;--------------------------------

RunFireworks:
    POP HL
;
    LD L, <ExplosionTimerCounter            ;decrement explosion timing counter here
    DEC (HL)
    JP NZ, SetupExpl                        ;if not expired, skip this part
;
    LD (HL), $08                            ;reset counter
    LD L, <ExplosionGfxCounter              ;increment explosion graphics counter
    INC (HL)
    LD A, (HL)
    CP A, $03                               ;check explosion graphics counter
    JP NC, FireworksSoundScore              ;if at a certain point, branch to kill this object
    ; FALL THROUGH

SetupExpl:
    CALL RelativeEnemyPosition              ;get relative coordinates of explosion
;
    LD A, (Enemy_Rel_YPos)                  ;copy relative coordinates
    LD (Fireball_Rel_YPos), A               ;from the enemy object to the fireball object
    LD A, (Enemy_Rel_XPos)                  ;first vertical, then horizontal
    LD (Fireball_Rel_XPos), A
;
    LD L, <Enemy_SprDataOffset              ;get OAM data offset
    LD E, (HL)
    LD L, <ExplosionGfxCounter              ;get explosion graphics counter
    LD A, (HL)
    JP DrawExplosion_Fireworks              ;do a sub to draw the explosion then leave

FireworksSoundScore:
    LD L, <Enemy_Flag                       ;disable enemy buffer flag
    LD (HL), $00
    LD A, SNDID_CANNON                      ;play fireworks/gunfire sound
    LD (SFXTrack1.SoundQueue), A
    LD A, $05                               ;set part of score modifier for 500 points
    LD (DigitModifier_04), A
    JP EndAreaPoints                        ;jump to award points accordingly then leave

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
    XOR A                                   ;initialize enemy frenzy buffer
    LD (EnemyFrenzyBuffer), A
;
    LD A, (StarFlagTaskControl)             ;check star flag object task number here
    CP A, $05                               ;if greater than 5, branch to exit
    RET NC
;
    PUSH HL
    RST JumpEngine                          ;otherwise jump to appropriate sub

    .dw StarFlagExit
    .dw GameTimerFireworks
    .dw AwardGameTimerPoints
    .dw RaiseFlagSetoffFWorks
    .dw DelayToAreaEnd

GameTimerFireworks:
    POP HL
;
    LD C, $05                               ;set default state for star flag object
    LD A, (GameTimerDisplay+2)              ;get game timer's last digit
    CP A, $01
    JP Z, SetFWC                            ;if last digit of game timer set to 1, skip ahead
    LD C, $03                               ;otherwise load new value for state
    CP A, $03
    JP Z, SetFWC                            ;if last digit of game timer set to 3, skip ahead
    LD C, $00                               ;otherwise load one more potential value for state
    CP A, $06
    JP Z, SetFWC                            ;if last digit of game timer set to 6, skip ahead
    LD A, $FF                               ;otherwise set value for no fireworks
SetFWC:
    LD (FireworksCounter), A                ;set fireworks counter here
    LD L, <Enemy_State                      ;set whatever state we have in star flag object
    LD (HL), C
    ; FALL THROUGH

IncrementSFTask1:
    LD A, (StarFlagTaskControl)             ;increment star flag object task number
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
    LD HL, GameTimerDisplay                 ;check all game timer digits for any intervals left
    LD A, (HL)
    INC L
    OR A, (HL)
    INC L
    OR A, (HL)
    EX DE, HL
    JP Z, IncrementSFTask1                  ;if no time left on game timer at all, branch to next task
;
    LD A, (FrameCounter)
    AND A, %00000100                        ;check frame counter for d2 set (skip ahead
    JP Z, NoTTick                           ;for four frames every four frames) branch if not set
    LD A, SNDID_BEEP                        ;load timer tick sound
    LD (SFXTrack1.SoundQueue), A
NoTTick:
    LD A, $FF                               ;set adder here to $ff, or -1, to subtract one
    LD (DigitModifier_05), A
    LD DE, GameTimerDisplay + $02           ;set offset here to subtract from game timer's last digit
    CALL DigitsMathRoutine                  ;subtract digit
    LD A, $05                               ;set now to add 50 points
    LD (DigitModifier_05), A                ;per game timer interval subtracted
    ; FALL THROUGH

EndAreaPoints:
    LD DE, PlayerScoreDisplay + $05         ;load offset for mario's score by default
    LD A, (CurrentPlayer)                   ;check player on the screen
    OR A
    JP Z, ELPGive                           ;if mario, do not change
    LD E, <OffScr_ScoreDisplay + $05        ;otherwise load offset for luigi's score
ELPGive:
    CALL DigitsMathRoutine                  ;award 50 points per game timer interval
;
    LD A, (CurrentPlayer)                   ;get player on the screen (or 500 points per
    ADD A, A                                ;fireworks explosion if branched here from there)
    ADD A, A                                ;shift to high nybble
    ADD A, A
    ADD A, A
    OR A, %00000100                         ;add four to set nybble for game timer
    JP UpdateNumber                         ;jump to print the new score and game timer

RaiseFlagSetoffFWorks:
    POP HL
;
    LD L, <Enemy_Y_Position                 ;check star flag's vertical position
    LD A, (HL)
    CP A, $72                               ;against preset value
    JP C, SetoffF                           ;if star flag higher vertically, branch to other code
    DEC (HL)                                ;otherwise, raise star flag by one pixel
    JP DrawStarFlag                         ;and skip this part here
SetoffF:
    LD A, (FireworksCounter)                ;check fireworks counter
    OR A
    JP Z, DrawFlagSetTimer                  ;if no fireworks left to go off, skip this part
    JP M, DrawFlagSetTimer                  ;if no fireworks set to go off, skip this part
    LD A, OBJECTID_Fireworks
    LD (EnemyFrenzyBuffer), A               ;otherwise set fireworks object in frenzy queue
    ; FALL THROUGH

DrawStarFlag:
    CALL RelativeEnemyPosition              ;get relative coordinates of star flag
;
    LD L, <Enemy_SprDataOffset              ;get OAM data offset
    LD E, (HL)
    LD D, >Sprite_Y_Position
    EX DE, HL
    LD A, (Enemy_Rel_YPos)                  ;get relative vertical coordinate
    SUB A, SMS_PIXELYOFFSET
    LD C, A
    ADD A, $08
    LD (HL), A                              ;store Y coordinates
    INC L
    LD (HL), A
    INC L
    LD (HL), C
    INC L
    LD (HL), C
    EX DE, HL
;
    LD E, (HL)                              ;get OAM data offset
    SLA E
    SET 7, E
    EX DE, HL
    LD A, (Enemy_Rel_XPos)                  ;get relative horizontal coordinate
    LD C, A
    ADD A, $08
    LD (HL), A                              ;store X coordinates and tile numbers
    INC L
    LD (HL), $4C
    INC L
    LD (HL), C
    INC L
    LD (HL), $4B
    INC L
    LD (HL), A
    INC L
    LD (HL), $4A
    INC L
    LD (HL), C
    INC L
    LD (HL), $49
    EX DE, HL
    RET

DrawFlagSetTimer:
    CALL DrawStarFlag                       ;do sub to draw star flag
;
    LD A, H                                 ;set interval timer here
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, $06
    LD (BC), A
    ; FALL THROUGH

IncrementSFTask2:
    LD A, (StarFlagTaskControl)             ;move onto next task
    INC A
    LD (StarFlagTaskControl), A
    RET

DelayToAreaEnd:
    POP HL
;
    CALL DrawStarFlag                       ;do sub to draw star flag
;
    LD A, H                                 ;if interval timer set in previous task
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    RET NZ                                  ;not yet expired, branch to leave
;
    LD A, (MusicTrack0.SoundPlaying)        ;if event music buffer empty,
    CP A, SNDID_LEVELDONE
    JP NZ, IncrementSFTask2                 ;branch to increment task
    RET

;--------------------------------
;$00(C) - used to store horizontal difference between player and piranha plant

MovePiranhaPlant:
    POP HL
;
    LD L, <Enemy_State                      ;check enemy state
    LD A, (HL)
    OR A
    RET NZ                                  ;if set at all, branch to leave
;
    LD A, H                                 ;check enemy's timer here
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    RET NZ                                  ;branch to end if not yet expired
;
    LD L, <PiranhaPlant_MoveFlag            ;check movement flag
    LD A, (HL)
    OR A
    JP NZ, SetupToMovePPlant                ;if moving, skip to part ahead
;
    LD L, <PiranhaPlant_Y_Speed             ;if currently rising, branch 
    LD A, (HL)
    OR A
    JP M, ReversePlantSpeed                 ;to move enemy upwards out of pipe
;
    CALL PlayerEnemyDiff                    ;get horizontal difference between player and
    LD A, (Temp_Bytes + $00)
    JP P, ChkPlayerNearPipe                 ;piranha plant, and branch if enemy to right of player
;
    NEG                                     ;otherwise, change to two's compliment

ChkPlayerNearPipe:
    CP A, $21                               ;get saved horizontal difference
    RET C                                   ;if player within a certain distance, branch to leave
    ; FALL THROUGH

ReversePlantSpeed:
    LD L, <PiranhaPlant_Y_Speed             ;get vertical speed
    LD A, (HL)
    NEG                                     ;change to two's compliment
    LD (HL), A                              ;save as new vertical speed
    LD L, <PiranhaPlant_MoveFlag            ;increment to set movement flag
    INC (HL)
    ; FALL THROUGH

SetupToMovePPlant:
    LD L, <PiranhaPlant_Y_Speed             ;get vertical speed
    LD A, (HL)
    OR A
    LD L, <PiranhaPlantDownYPos             ;get original vertical coordinate (lowest point)
    JP P, RiseFallPiranhaPlant              ;branch if moving downwards
    LD L, <PiranhaPlantUpYPos               ;otherwise get other vertical coordinate (highest point)
    ; FALL THROUGH

RiseFallPiranhaPlant:
    LD C, (HL)                              ;save vertical coordinate here
;
    LD A, (FrameCounter)                    ;get frame counter
    RRCA
    RET NC                                  ;branch to leave if d0 set (execute code every other frame)
    LD A, (TimerControl)                    ;get master timer control
    OR A
    RET NZ                                  ;branch to leave if set (likely not necessary)
;
    LD L, <PiranhaPlant_Y_Speed
    LD A, (HL)
    LD L, <Enemy_Y_Position                 ;get current vertical coordinate
    ADD A, (HL)                             ;add vertical speed to move up or down
    LD (HL), A                              ;save as new vertical coordinate
;
    CP A, C                                 ;compare against low or high coordinate
    RET NZ                                  ;branch to leave if not yet reached
;
    LD L, <PiranhaPlant_MoveFlag            ;otherwise clear movement flag
    LD (HL), $00
;
    LD A, H                                 ;set timer to delay piranha plant movement
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, $40
    LD (BC), A
    RET

;-------------------------------------------------------------------------------------
;$00(B) - used to hold collision flag, Y movement force + 5
;(C) - low byte of name table for rope
;$01(B) - used to hold high byte of name table for rope
;$02(N/A) - used to hold page location of rope
;DE - Object_Offset of the 2nd platform

BalancePlatform:
    POP HL
;
    LD L, <Enemy_Y_HighPos                      ;check high byte of vertical position
    LD A, (HL)
    CP A, $03
    JP Z, EraseEnemyObject                      ;if far below screen, kill the object
;
    LD L, <Enemy_State                          ;get object's state (set to $ff or other platform offset)
    LD A, (HL)
    OR A
    RET M                                       ;if doing other balance platform, branch to leave

CheckBalPlatform:
    LD C, A                                     ;save offset from state as Y
    ADD A, >Enemy_ID                            ;(SMS)setup 2nd platform offset
    LD D, A
;
    LD L, <PlatformCollisionFlag                ;get collision flag of platform
    LD B, (HL)                                  ;store here
;
    LD L, <Enemy_MovingDir                      ;get moving direction
    LD A, (HL)
    OR A
    JP NZ, PlatformFall                         ;if set, jump here

ChkForFall:
    LD A, $2D                                   ;check if platform is above a certain point
    LD L, <Enemy_Y_Position
    LD E, L                                     ;Enemy_Y_Position
    CP A, (HL)
    JP C, ChkOtherForFall                       ;if not, branch elsewhere
;
    LD A, C
    CP A, B                                     ;if collision flag is set to same value as
    JP Z, InitPlatformFall                      ;enemy state, branch to make platforms fall
;
    ;LD L, <Enemy_Y_Position                     ;otherwise add 2 pixels to vertical position
    LD (HL), $2F                                ;of current platform and branch elsewhere ; $2D + $02
    JP StopPlatforms                            ;to make platforms stop

ChkOtherForFall:
    EX DE, HL                                   ;(SMS)exchange to do 'CP A, (DE)'
    CP A, (HL)                                  ;check if other platform is above a certain point
    EX DE, HL
    JP C, ChkToMoveBalPlat                      ;if not, branch elsewhere
;
    LD A, B
    ADD A, >Enemy_ID
    CP A, H                                     ;if collision flag is set to same value as
    JP Z, InitPlatformFall                      ;enemy state, branch to make platforms fall
;
    LD A, $2F                                   ;otherwise add 2 pixels to vertical position ;$2D + $02
    LD (DE), A                                  ;of other platform and branch elsewhere
    JP StopPlatforms                            ;jump to stop movement and do not return

ChkToMoveBalPlat:
    LD L, <Enemy_Y_Position                     ;save vertical position to stack
    LD A, (HL)
    PUSH AF
;
    LD L, <PlatformCollisionFlag                ;get collision flag
    LD A, (HL)
    OR A
    JP P, ColFlg                                ;branch if collision
;
    LD L, <Enemy_Y_MoveForce                    ;add $05 to contents of moveforce, whatever they be
    LD A, (HL)
    ADD A, $05
    LD B, A                                     ;store here
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    ADC A, $00                                  ;add carry to vertical speed
    JP M, PlatDn                                ;branch if moving downwards
    JP NZ, PlatUp                               ;branch elsewhere if moving upwards
    LD A, B
    CP A, $0B                                   ;check if there's still a little force left
    JP C, PlatSt                                ;if not enough, branch to stop movement
    JP PlatUp                                   ;otherwise keep branch to move upwards
ColFlg:
    LD B, A
    LD A, (ObjectOffset + $01)
    SUB A, >Enemy_ID
    CP A, B                                     ;if collision flag matches
    JP Z, PlatDn                                ;current enemy object offset, branch
PlatUp:
    CALL MovePlatformUp                         ;do a sub to move upwards
    JP DoOtherPlatform                          ;jump ahead to remaining code
PlatSt:
    CALL StopPlatforms                          ;do a sub to stop movement
    JP DoOtherPlatform                          ;jump ahead to remaining code
PlatDn:
    CALL MovePlatformDown                       ;do a sub to move downwards
    ; FALL THROUGH

DoOtherPlatform:
    LD L, <Enemy_State                          ;get offset of other platform
    LD A, (HL)
    ADD A, >Enemy_ID
    LD D, A
;
    LD L, <Enemy_Y_Position
    LD E, L
    POP AF                                      ;get old vertical coordinate from stack
    SUB A, (HL)                                 ;get difference of old vs. new coordinate
    EX DE, HL                                   ;(SMS)exchange to do 'ADD A, (DE)'
    ADD A, (HL)                                 ;add difference to vertical coordinate of other
    EX DE, HL
    LD (DE), A                                  ;platform to move it in the opposite direction
;
    LD L, <PlatformCollisionFlag                ;if no collision, skip this part here
    LD A, (HL)
    OR A
    JP M, DrawEraseRope
;
    ADD A, >Enemy_ID
    LD H, A                                     ;put offset which collision occurred here
    CALL PositionPlayerOnVPlat                  ;and use it to position player accordingly
    LD HL, (ObjectOffset)                       ;get enemy object offset
    ; FALL THROUGH

DrawEraseRope:
    LD L, <Enemy_Y_MoveForce                    ;check to see if current platform is
    LD A, (HL)                                  ;moving at all
    LD L, <Enemy_Y_Speed
    OR A, (HL)
    RET Z                                       ;if not, skip all of this and branch to leave
;
    ;CPX $20
    ;BCS ExitRp
    CALL GetXOffscreenBits                      ;get offscreen bits for X coordinate
    CP A, $C0                                   ;check if rope is offscreen (NOTE: 1 pixel off)
    LD DE, (VRAM_Buffer1_Ptr)                   ;get vram buffer offset
    JP NC, SkipRope1                            ;don't draw rope if it's offscreen
    LD L, <Enemy_Y_Position                     ;check if rope is vertically onscreen
    LD A, (HL)
    CP A, $D0
    JP NC, SkipRope1                            ;if not, don't draw rope
;
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    CALL SetupPlatformRope                      ;do a sub to figure out where to put new bg tiles
    EX DE, HL
    LD (HL), B                                  ;write name table address to vram buffer
    INC L
    LD (HL), C                                  ;first the high byte, then the low
    INC L
    LD (HL), StripeCount($04)                   ;set length for 4 bytes
    INC L
    LD E, <Enemy_Y_Speed                        ;if platform moving upwards, branch
    LD A, (DE)                                  ;to do something else
    OR A
    JP M, EraseR1
    LD (HL), $8C                                ;otherwise put tile numbers for left
    INC L
    LD (HL), $01                                ;and right sides of rope in vram buffer
    INC L
    LD (HL), $8D
    INC L
    LD (HL), $01
    JP OtherRope                                ;jump to skip this part
EraseR1:
    XOR A                                       ;put blank tiles in vram buffer
    LD (HL), A                                  ;to erase rope
    INC L
    LD (HL), A
    INC L
    LD (HL), A
    INC L
    LD (HL), A
    ; FALL THROUGH

OtherRope:
    EX DE, HL
    INC E
SkipRope1:
    LD L, <Enemy_Y_Speed
    LD B, (HL)                                  ;save vertical speed of original object in B
    LD L, <Enemy_State                          ;get offset of other platform from state
    LD A, (HL)
    ADD A, >Enemy_ID
    LD H, A
;
    PUSH DE                                     ;preserve VRAM_Buffer1_Ptr
    CALL GetXOffscreenBits                      ;get offscreen bits for X coordinate
    POP DE                                      ;get back VRAM_Buffer1_Ptr
    CP A, $C0                                   ;check if rope is offscreen (NOTE: 1 pixel off)
    JP NC, SkipRope2                            ;don't draw rope if it's offscreen
    LD L, <Enemy_Y_Position                     ;check if rope is vertically onscreen
    LD A, (HL)
    CP A, $D0
    JP NC, SkipRope2                            ;if not, don't draw rope
;
    LD A, B
    PUSH AF                                     ;save copy of vertical speed of original object
    CPL                                         ;invert bits to reverse speed
    CALL SetupPlatformRope                      ;do sub again to figure out where to put bg tiles
    EX DE, HL
    LD (HL), B                                  ;write name table address to vram buffer
    INC L
    LD (HL), C                                  ;this time we're doing putting tiles for
    INC L                                       ;the other platform
    LD (HL), StripeCount($04)                   ;set length again for 2 bytes
    INC L
    POP AF                                      ;pull first copy of vertical speed from stack
    OR A
    JP P, EraseR2                               ;if moving upwards (note inversion earlier), skip this
    LD (HL), $8C                                ;otherwise put tile numbers for left
    INC L
    LD (HL), $01                                ;and right sides of rope in vram
    INC L
    LD (HL), $8D                                ;transfer buffer
    INC L
    LD (HL), $01
    JP EndRp                                    ;jump to skip this part
EraseR2:
    XOR A                                       ;put blank tiles in vram buffer
    LD (HL), A                                  ;to erase rope
    INC L
    LD (HL), A
    INC L
    LD (HL), A
    INC L
    LD (HL), A
EndRp:
    INC L
    EX DE, HL
SkipRope2:
    XOR A
    LD (DE), A                                  ;put null terminator at the end
    LD (VRAM_Buffer1_Ptr), DE                   ;update vram buffer offset
    LD HL, (ObjectOffset)                       ;get enemy object buffer offset and leave
    RET

;   INPUT:  HL - ObjectOffset
;   INPUT:  A - Enemy_Y_Speed
;   OUTPUT: BC - NAMETABLE ADDR
SetupPlatformRope:
    PUSH HL                                     ;save current object offset
    OR A
    LD L, <Enemy_Y_Position                     ;get vertical coordinate
    LD A, (HL)
    LD L, <Enemy_X_Position                     ;get horizontal coordinate and save in B
    LD B, (HL)
    JP P, StoreRopeY                            ;skip this part if moving downwards or not at all
    ADD A, $08                                  ;add eight to vertical coordinate and
StoreRopeY:
    SUB A, SMS_PIXELYOFFSET                     ;subtract offset to adjust to SMS resolution
    AND A, $F8                                  ;remove unwanted bits (round down to whole tile)
    LD L, A                                     ;store in HL
    LD H, $0C                                   ;set bits to factor in NT base and VDP Write command
    ADD HL, HL                                  ;shift into the correct place
    ADD HL, HL                                  ;tile -> row addr ($08 -> $40)
    ADD HL, HL
;
    LD A, (SecondaryHardMode)                   ;if secondary hard mode flag set,
    OR A
    LD A, B                                     ;load horizontal coordinate
    JP NZ, StoreRopeX                           ;use coordinate as-is
    ADD A, $10                                  ;otherwise add sixteen more pixels
StoreRopeX:
    ADD A, $08
    AND A, $F0                                  ;remove unwanted bits (round down to whole tile)
    RRCA                                        ;shift into the correct place
    RRCA                                        ;tile -> col addr ($08 -> $02)
    OR A, L                                     ;add row and col addresses together
    LD C, A                                     ;store low byte in C
    LD B, H                                     ;store high byte in B
    POP HL                                      ;get back current object offset
    RET

InitPlatformFall:
    LD H, D                                     ;move offset of other platform from Y to X
    CALL GetEnemyOffscreenBits                  ;get offscreen bits
    LD HL, (ObjectOffset)
;
    LD A, $06
    CALL SetupFloateyNumber                     ;award 1000 points to player
;
    LD A, (Player_Rel_XPos)                     ;put floatey number coordinates where player is
    LD L, <FloateyNum_X_Pos
    LD (HL), A
    LD A, (Player_Y_Position)
    LD L, <FloateyNum_Y_Pos
    LD (HL), A
;
    LD L, <Enemy_MovingDir                      ;set moving direction as flag for
    LD (HL), $01                                ;falling platforms
    LD D, >Enemy_ID + $01
    ; FALL THROUGH

StopPlatforms:
    CALL InitVStf                               ;initialize vertical speed and low byte
;
    LD E, <Enemy_Y_Speed                        ;for both platforms and leave
    LD (DE), A
    LD E, <Enemy_Y_MoveForce
    LD (DE), A
    RET

PlatformFall:
    PUSH DE                                     ;save offset for other platform to stack
    CALL MoveFallingPlatform                    ;make current platform fall
;
    POP HL                                      ;pull offset from stack and save to X
    CALL MoveFallingPlatform                    ;make other platform fall
;
    LD HL, (ObjectOffset)
    LD L, <PlatformCollisionFlag                ;if player not standing on either platform,
    LD A, (HL)
    OR A
    RET M                                       ;skip this part
    ADD A, >Enemy_ID
    LD H, A                                     ;transfer collision flag offset as offset to X
    CALL PositionPlayerOnVPlat                  ;and position player appropriately
    LD HL, (ObjectOffset)                       ;get enemy object buffer offset and leave
    RET

;--------------------------------

YMovingPlatform:
    POP HL
;
    LD L, <Enemy_Y_Speed                        ;if platform moving up or down, skip ahead to
    LD A, (HL)
    LD L, <Enemy_Y_MoveForce
    OR A, (HL)
    JP NZ, ChkYCenterPos                        ;check on other position
;
    LD L, <Enemy_YMF_Dummy                      ;initialize dummy variable
    LD (HL), A
    LD L, <Enemy_Y_Position
    LD A, (HL)
    LD L, <YPlatformTopYPos                     ;if current vertical position => top position, branch
    CP A, (HL)
    JP NC, ChkYCenterPos                        ;ahead of all this
;
    LD A, (FrameCounter)
    AND A, %00000111                            ;check for every eighth frame
    JP NZ, ChkYPCollision
;
    LD L, <Enemy_Y_Position                     ;increase vertical position every eighth frame
    INC (HL)
    JP ChkYPCollision                           ;skip ahead to last part

ChkYCenterPos:
    LD L, <Enemy_Y_Position                     ;if current vertical position < central position, branch
    LD A, (HL)
    LD L, <YPlatformCenterYPos                  ;to slow ascent/move downwards
    CP A, (HL)
    JP C, YMDown
    CALL MovePlatformUp                         ;otherwise start slowing descent/moving upwards
    JP ChkYPCollision
YMDown:
    CALL MovePlatformDown                       ;start slowing ascent/moving downwards
    ; FALL THROUGH

ChkYPCollision:
    LD L, <PlatformCollisionFlag                ;if collision flag is set, position player appropriately
    LD A, (HL)
    OR A
    CALL P, PositionPlayerOnVPlat
    RET

;--------------------------------
;$00(B) - used as adder to position player hotizontally

XMovingPlatform:
    POP HL
;
    LD A, $0E                                   ;load preset maximum value for secondary counter
    CALL XMoveCntr_Platform                     ;do a sub to increment counters for movement
;
    CALL MoveWithXMCntrs                        ;do a sub to move platform accordingly, and return value
    LD A, (Temp_Bytes + $00)
    LD B, A
;
    LD L, <PlatformCollisionFlag                ;if no collision with player,
    LD A, (HL)                                  ;branch ahead to leave
    OR A
    RET M
    ; FALL THROUGH

PositionPlayerOnHPlat:
    LD A, (Player_X_Position)                   ;add saved value from second subroutine to
    ADD A, B                                    ;current player's position to position
    LD (Player_X_Position), A                   ;player accordingly in horizontal position
;
    LD A, (Player_PageLoc)                      ;get player's page location
    BIT 7, B                                    ;check to see if saved value here is positive or negative
    JP NZ, PPHSubt                              ;if negative, branch to subtract
    ADC A, $00                                  ;otherwise add carry to page location
    JP SetPVar                                  ;jump to skip subtraction
PPHSubt:
    ADC A, $FF                                  ;subtract borrow from page location
SetPVar:
    LD (Player_PageLoc), A                      ;save result to player's page location
;
    LD A, B                                     ;put saved value from second sub here to be used later
    LD (Platform_X_Scroll), A
;
    JP PositionPlayerOnVPlat                    ;position player vertically and appropriately

;--------------------------------

DropPlatform:
    POP HL
;
    LD L, <PlatformCollisionFlag                ;if no collision between platform and player
    LD A, (HL)                                  ;occurred, just leave without moving anything
    OR A
    RET M
;
    CALL MoveDropPlatform                       ;otherwise do a sub to move platform down very quickly
    JP PositionPlayerOnVPlat                    ;do a sub to position player appropriately

;--------------------------------

RightPlatform:
    POP HL
;
    CALL MoveEnemyHorizontally                  ;move platform with current horizontal speed, if any
    LD B, A                                     ;store saved value here
;
    LD L, <PlatformCollisionFlag                ;check collision flag, if no collision between player
    LD A, (HL)                                  ;and platform, branch ahead, leave speed unaltered
    OR A
    RET M
;

    LD L, <Enemy_X_Speed                        ;otherwise set new speed (gets moving if motionless)

    .IF PALBUILD == $00
    LD (HL), $10
    .ELSE
    LD (HL), $13                                ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF
;
    JP PositionPlayerOnHPlat                    ;use saved value from earlier sub to position player

;--------------------------------

MoveLargeLiftPlat:
    POP HL
;
    CALL MoveLiftPlatforms                      ;execute common to all large and small lift platforms
    JP ChkYPCollision                           ;branch to position player correctly

MoveSmallPlatform:
    CALL MoveLiftPlatforms                      ;execute common to all large and small lift platforms
    JP ChkSmallPlatCollision

MoveLiftPlatforms:
    LD A, (TimerControl)                        ;if master timer control set, skip all of this
    OR A
    RET NZ                                      ;and branch to leave
;
    LD L, <Enemy_Y_MoveForce
    LD A, (HL)
    LD L, <Enemy_YMF_Dummy
    ADD A, (HL)                                 ;add contents of movement amount to whatever's here
    LD (HL), A
;
    LD L, <Enemy_Y_Speed
    LD A, (HL)
    LD L, <Enemy_Y_Position                     ;add whatever vertical speed is set to current
    ADC A, (HL)                                 ;vertical position plus carry to move up or down
    LD (HL), A
    RET

ChkSmallPlatCollision:
    LD L, <PlatformCollisionFlag                ;get bounding box counter saved in collision flag
    LD A, (HL)
    OR A
    RET Z                                       ;if none found, leave player position alone
    JP PositionPlayerOnS_Plat                   ;use to position player correctly

;-------------------------------------------------------------------------------------
;$00(B) - page location of extended left boundary
;$01(C) - extended left boundary position
;$02(D) - page location of extended right boundary
;$03(E) - extended right boundary position

OffscreenBoundsCheck:
    LD L, <Enemy_ID                             ;check for cheep-cheep object
    LD A, (HL)
    CP A, OBJECTID_FlyingCheepCheep
    RET Z                                       ;branch to leave if found
;
    CP A, OBJECTID_HammerBro                    ;check for hammer bro object
    JP Z, LimitB
    CP A, OBJECTID_PiranhaPlant                 ;check for piranha plant object
    JP NZ, ExtendLB
LimitB:                                         ;6502 carry set (+1 to ADD)
    LD A, (ScreenLeft_X_Pos)                    ;get horizontal coordinate for left side of screen
    ADD A, $39                                  ;add 56 pixels to coordinate if hammer bro or piranha plant
    CCF                                         ;flip carry to convert 6502 logic to Z80
    SBC A, $48                                  ;subtract 72 pixels regardless of enemy object
    JP +
ExtendLB:
    LD A, (ScreenLeft_X_Pos)                    ;get horizontal coordinate for left side of screen
    SBC A, $48                                  ;subtract 72 pixels regardless of enemy object
+:
    LD C, A                                     ;store result here
;
    LD A, (ScreenLeft_PageLoc)                  ;subtract borrow from page location of left side
    SBC A, $00
    LD B, A                                     ;store result here
;
    LD A, (ScreenRight_X_Pos)                   ;add 72 pixels to the right side horizontal coordinate
    CCF                                         ;flip carry to convert 6502 logic to Z80
    ADC A, $48
    LD E, A                                     ;store result here
;
    LD A, (ScreenRight_PageLoc)                 ;then add the carry to the page location
    ADC A, $00
    LD D, A                                     ;and store result here
;
    LD L, <Enemy_X_Position                     ;compare horizontal coordinate of the enemy object
    LD A, (HL)
    CP A, C                                     ;to modified horizontal left edge coordinate to get carry
    DEC L                                       ;<Enemy_PageLoc
    LD A, (HL)
    SBC A, B                                    ;then subtract it from the page coordinate of the enemy object
    JP M, EraseEnemyObject                      ;if enemy object is too far left, branch to erase it
;
    INC L                                       ;<Enemy_X_Position
    LD A, (HL)                                  ;compare horizontal coordinate of the enemy object
    CP A, E                                     ;to modified horizontal right edge coordinate to get carry
    DEC L                                       ;<Enemy_PageLoc
    LD A, (HL)
    SBC A, D                                    ;then subtract it from the page coordinate of the enemy object
    RET M                                       ;if enemy object is on the screen, leave, do not erase enemy
;
    LD L, <Enemy_State                          ;if at this point, enemy is offscreen to the right, so check
    LD A, (HL)
    CP A, OBJECTID_HammerBro                    ;if in state used by spiny's egg, do not erase
    RET Z
    LD L, <Enemy_ID                             ;if piranha plant, do not erase
    LD A, (HL)
    CP A, OBJECTID_PiranhaPlant
    RET Z
    CP A, OBJECTID_FlagpoleFlagObject           ;if flagpole flag, do not erase
    RET Z
    CP A, OBJECTID_StarFlagObject               ;if star flag, do not erase
    RET Z
    CP A, OBJECTID_JumpspringObject             ;if jumpspring, do not erase
    RET Z
    JP EraseEnemyObject                         ;erase all others too far to the right

;-------------------------------------------------------------------------------------

.SECTION "FloateyNumTileData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
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

.SECTION "ScoreUpdateData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;high nybble is digit number, low nybble is number to
;add to the digit of the player's score
ScoreUpdateData:
    .db $ff ;dummy
    .db $41, $42, $44, $45, $48
    .db $31, $32, $34, $35, $38, $00
.ENDS

;   FloateyNum_Control
;   FloateyNum_X_Pos
;   FloateyNum_Y_Pos
;   FloateyNum_Timer

FloateyNumbersRoutine:
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
    JR Z, FloateyPart                       ;branch if spiny
    CP A, OBJECTID_PiranhaPlant
    JR Z, FloateyPart                       ;branch if piranha plant
    CP A, OBJECTID_HammerBro
    JR Z, GetAltOffset                      ;branch elsewhere if hammer bro
    CP A, OBJECTID_GreyCheepCheep
    JR Z, FloateyPart                       ;branch if cheep-cheep of either color
    CP A, OBJECTID_RedCheepCheep
    JR Z, FloateyPart
    CP A, OBJECTID_TallEnemy
    JR NC, GetAltOffset                     ;branch elsewhere if enemy object => $09
    LD L, <Enemy_State
    LD A, (HL)
    CP A, $02                               ;if enemy state defeated or otherwise
    JP NC, FloateyPart                      ;$02 or greater, branch beyond this part
GetAltOffset:
    LD A, (SprDataOffset_Ctrl)              ;load some kind of control bit
    ADD A, >Alt_SprDataOffset
    LD D, A
    LD E, <SprDataOffset
    LD A, (DE)                              ;get alternate OAM data offset
    LD C, A
    ;LD HL, (ObjectOffset)                       
FloateyPart:
    LD L, <FloateyNum_Y_Pos
    LD A, (HL)                              ;get vertical coordinate for
    CP A, $18                               ;floatey number, if coordinate in the
    JP C, SetupNumSpr                       ;status bar, branch
    DEC (HL)                                ;otherwise subtract one and store as new                             
SetupNumSpr:
    LD E, C
    LD D, >Sprite_Y_Position
    LD A, (HL)                              ;get vertical coordinate
    SUB A, $08 + SMS_PIXELYOFFSET           ;subtract eight and dump into the
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
    LD A, (MusicTrack0.SoundPlaying)
    LD (MusicTrack1.SoundQueue), A
    LD A, SNDID_HURRYUP
    LD (MusicTrack0.SoundQueue), A          ; EVENT
;
ResGTCtrl:
    .IF PALBUILD == $00
    LD A, $18                               ;reset game timer control
    .ELSE
    LD A, $14                               ;PAL diff: Game timer ticks every 20 frames (vs. 24 frames on NTSC)
    .ENDIF

    LD (GameTimerCtrlTimer), A
    LD DE, GameTimerDisplay + $02           ;set offset for last digit
    LD A, $FF                               ;set value to decrement game timer digit
    LD (DigitModifier_05), A
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

.SECTION "FlagpoleScoreMods, FlagpoleScoreDigits" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlagpoleScoreDigits:
    .db $03, $03, $04, $04, $04

FlagpoleScoreMods:
    .db $05, $02, $08, $04, $01
.ENDS

FlagpoleRoutine:
    LD HL, Enemy_ID_05                      ;set enemy object offset
    LD (ObjectOffset), HL                   ;to special use slot
;
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
    CP A, $AA                               ;if flagpole flag down to a certain point,
    JP NC, GiveFPScr                        ;branch to end the level
;
    LD A, (Player_Y_Position)               ;check player's vertical coordinate
    CP A, $A2                               ;if player down to a certain point,
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
    GetBlockOffscreenBits_M         ;get offscreen information
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
    LD A, $F0
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
    GetBlockOffscreenBits_M         ;get offscreen information
    CALL DrawBlock                  ;draw the block
;
    LD L, <Block_Y_Position
    LD A, (HL)                      ;get vertical coordinate
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
    LD H, >Block_State + $01            ;set offset to start with second block object
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
    PUSH BC                             ;(SMS)save counter in B
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
    EX DE, HL
    CALL WriteBlockMetatile             ;do sub to replace metatile where block object is
    POP HL
;
    LD L, <Block_RepFlag
    LD (HL), $00                        ;clear block object flag
    POP BC                              ;(SMS)get counter back
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

.SECTION "BlockGfxData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
BlockGfxData:
    ;    TL   TR   BL   BR
    ;.db $45, $45, $47, $47          ; TILES FOR SHINY BRICK METATILE
    ;.db $47, $47, $47, $47          ; TILES FOR BRICK METATILE
    ;.db $57, $58, $59, $5a          ; TILES FOR EMPTY BLOCK METATILE
    ;.db $24, $24, $24, $24          ; TILES FOR BLANK METATILE  
    ;.db $26, $26, $26, $26          ; TILES FOR BLANK METATILE FOR WATER

    .dw BG_MACRO($019B), BG_MACRO($019B), BG_MACRO($01A4), BG_MACRO($01A4)  ; SHINY BRICK MT
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; BRICK MT
    .dw BG_MACRO($11A5), BG_MACRO($11A7), BG_MACRO($11A6), BG_MACRO($11A8)  ; EMPTY BLOCK MT (PRIORITY)
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; BLANK MT
    .dw $01E7, $01E7, $01E7, $01E7                                          ; WATER MT
    ;.dw BG_MACRO($01A5), BG_MACRO($01A7), BG_MACRO($01A6), BG_MACRO($01A8)  ; EMPTY BLOCK MT (NO PRI)
.ENDS

RemoveCoin_Axe:
    LD DE, (VRAM_Buffer1_Ptr)
    XOR A
    LD (VRAM_Buffer_AddrCtrl), A    ;set vram address controller to VRAM_Buffer1
;
    LD A, (AreaType)                ;check area type
    OR A
    LD A, $03                       ;load offset for default blank metatile
    JP NZ, PutBlockMetatile         ;if not water type, use offset
    INC A                           ;otherwise load offset for blank metatile used in water
    JP PutBlockMetatile             ;do a sub to write blank metatile to vram buffer

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
    LD DE, (VRAM_Buffer1_Ptr)       ;get vram buffer offset
    LD A, C                         ;put Y in A
    JP PutBlockMetatile             ;get appropriate block data and write to vram buffer

;   A - Index into BlockGfxData
;   HL - Block_Buffer Ptr
;   DE - VRAM_Buffer Ptr
;   BC - BlockGfxData Ptr
;   IXL - Block_Buffer Row
PutBlockMetatile:
;   PREPARE BlockGfxData PTR
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, <BlockGfxData
    LD C, A
;   PREPARE B TO CHECK IF OBJECT IS OFF THE LEFT EDGE OF THE VISIBLE SCREEN
    ;LD A, (CurrentNTAddr)    
    ;SUB A, $02
    ;AND A, $3F
    ;LD B, A
    EXX
    LD HL, (ColumnWrite_Ptr)
    INC L
    LD A, (HL)
    EXX
    AND A, $3F
    LD B, A
;   CONVERT BLOCK BUFFER COLUMN TO NAMETABLE COLUMN
    LD A, L
    AND A, $0F
    ADD A, A
    ADD A, A
    CP A, B     ; IF COLUMNS ARE THE SAME, ONLY DRAW THE RIGHT HALF
    LD B, A
    JP Z, PutBlockMetatile_RHalf
;   CONVERT BLOCK BUFFER ROW TO NAMETABLE ROW
    LD A, IXL
    ADD A, $08  ; SKIP 1ST ROW (STATUS BAR)
    LD L, A
    LD H, (>VRAM_ADR_NAMETBL | >VRAMWRITE)  >> $03
    ADD HL, HL
    ADD HL, HL
    ADD HL, HL
;   NAMETABLE ROW LOW BYTE + COLUMN
    LD A, B
    ADD A, L
    LD L, A
;   MOVE TO BC
    LD L, C
    LD C, A
    LD B, H
    LD H, >BlockGfxData
RemBridge:
;   WRITE VRAM BUFFER (VDP ADDRESS)
    LD A, B
    LD (DE), A  ; HIGH BYTE
    INC E
    LD A, C
    LD (DE), A  ; LOW BYTE
    INC E
;   WRITE VRAM BUFFER (COUNT)
    LD A, StripeCount($04)
    LD (DE), A
    INC E
;   WRITE VRAM BUFFER (TOP LEFT TILE, TOP RIGHT TILE)
    LDI
    LDI
    LDI
    LDI
;   WRITE VRAM BUFFER (VDP ADDRESS)
    LD A, $44
    addAToBC_M
    LD (DE), A  ; HIGH BYTE
    INC E
    LD A, C
    LD (DE), A  ; LOW BYTE
    INC E
;   WRITE VRAM BUFFER (COUNT)
    LD A, StripeCount($04)
    LD (DE), A
    INC E
;   WRITE VRAM BUFFER (BOT LEFT TILE, BOT RIGHT TILE)
    LDI
    LDI
    LDI
    LDI
;   SET TERMINATOR
    XOR A
    LD (DE), A
;
    LD (VRAM_Buffer1_Ptr), DE
    RET

PutBlockMetatile_RHalf:
;   CONVERT BLOCK BUFFER ROW TO NAMETABLE ROW
    LD A, IXL
    ADD A, $08  ; SKIP 1ST ROW (STATUS BAR)
    LD L, A
    LD H, (>VRAM_ADR_NAMETBL | >VRAMWRITE)  >> $03
    ADD HL, HL
    ADD HL, HL
    ADD HL, HL
;   NAMETABLE ROW LOW BYTE + COLUMN
    LD A, B
    ADD A, L
    LD L, A
;   MOVE TO BC
    LD L, C
    LD C, A
    LD B, H
    LD H, >BlockGfxData
;   WRITE VRAM BUFFER (VDP ADDRESS)
    INC C
    INC C
    LD A, B
    LD (DE), A  ; HIGH BYTE
    INC E
    LD A, C
    LD (DE), A  ; LOW BYTE
    INC E
;   WRITE VRAM BUFFER (COUNT)
    LD A, StripeCount($02)
    LD (DE), A
    INC E
;   WRITE VRAM BUFFER (TOP RIGHT TILE)
    INC L
    INC L
    LDI
    LDI
;   WRITE VRAM BUFFER (VDP ADDRESS)
    LD A, $42
    addAToBC_M
    LD (DE), A  ; HIGH BYTE
    INC E
    LD A, C
    LD (DE), A  ; LOW BYTE
    INC E
;   WRITE VRAM BUFFER (COUNT)
    LD A, StripeCount($02)
    LD (DE), A
    INC E
;   WRITE VRAM BUFFER (BOT RIGHT TILE)
    INC L
    INC L
    LDI
    LDI
;   SET TERMINATOR
    XOR A
    LD (DE), A
;
    LD (VRAM_Buffer1_Ptr), DE
    RET

;-------------------------------------------------------------------------------------
;$02(IXL) - used to store vertical high nybble offset from block buffer routine
;$06 - used to store low byte of block buffer address

;   DE - Misc Object
;   HL - Block Object
CoinBlock:
    POP HL
    CALL FindEmptyMiscSlot              ;set offset for empty or last misc object buffer slot
;
    LD L, <Block_PageLoc                ;get page location of block object
    LD E, L                             ;store as page location of misc object
    LD A, (HL)
    LD (DE), A
;
    LD L, <Block_X_Position             ;get horizontal coordinate of block object
    LD E, L
    LD A, (HL)
    ADD A, $05                          ;add 5 pixels
    LD (DE), A                          ;store as horizontal coordinate of misc object
;
    LD L, <Block_Y_Position             ;get vertical coordinate of block object
    LD E, L
    LD A, (HL)
    SUB A, $10                          ;subtract 16 pixels
    LD (DE), A                          ;store as vertical coordinate of misc object
    JP JCoinC                           ;jump to rest of code as applies to this misc object

SetupJumpCoin:
    CALL FindEmptyMiscSlot              ;set offset for empty or last misc object buffer slot
;
    LD L, <Block_PageLoc2               ;get page location saved earlier
    LD E, <Misc_PageLoc                 ;and save as page location for misc object
    LD A, (HL)
    LD (DE), A
;
    LD E, <Misc_X_Position
    LD A, (Temp_Bytes + $06)            ;get low byte of block buffer offset
    ADD A, A                            ;multiply by 16 to use lower nybble
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, $05                          ;add five pixels
    LD (DE), A                          ;save as horizontal coordinate for misc object
;
    LD E, <Misc_Y_Position
    LD A, IXL                           ;get vertical high nybble offset from earlier
    ADD A, $20                          ;add 32 pixels for the status bar
    LD (DE), A                          ;store as vertical coordinate
;
JCoinC:
    LD E, <Misc_Y_Speed                 ;set vertical speed
    LD A, $FB
    LD (DE), A
;
    LD E, <Misc_Y_HighPos               ;set vertical high byte
    LD A, $01
    LD (DE), A
    LD E, <Misc_State                   ;set state for misc object
    LD (DE), A
;
    LD A, SNDID_COIN                    ;load coin grab sound
    LD (SFXTrack1.SoundQueue), A
;
    LD (ObjectOffset), HL               ;store current control bit as misc object offset
    CALL GiveOneCoin                    ;update coin tally on the screen and coin amount variable
    LD A, (CoinTallyFor1Ups)            ;increment coin tally used to activate 1-up block flag
    INC A
    LD (CoinTallyFor1Ups), A
    RET

FindEmptyMiscSlot:
    LD C, $03
    LD DE, Misc_State_08                ;start at end of misc objects buffer
FMiscLoop:
    LD A, (DE)                          ;get misc object state
    OR A
    RET Z                               ;branch if none found to use current offset
    DEC D                               ;decrement offset
    DEC C                               ;do this for three slots
    JP NZ, FMiscLoop                    ;do this until all slots are checked
    LD D, >Misc_State + $08             ;if no empty slots found, use last slot
    RET

;-------------------------------------------------------------------------------------

MiscObjectsCore:
    LD H, >Misc_State + $08             ;set at end of misc object buffer
MiscLoop:
    LD (ObjectOffset), HL               ;store misc object offset here
    LD L, <Misc_State                   ;check misc object state
    LD A, (HL)
    OR A
    JP Z, MiscLoopBack                  ;branch to check next slot
    JP P, ProcJumpCoin                  ;if d7 not set, jumping coin, thus skip to rest of code here
    JP ProcHammerObj                    ;otherwise go to process hammer,
    ;JP MiscLoopBack                     ;then check next slot

;--------------------------------
;$00(B) - used to set downward force
;$01 - used to set upward force (residual)
;$02(C) - used to set maximum speed

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
    LD BC, $5006                        ;set downward movement amount & max speed
    ;XOR A                               ;set A to impose gravity on jumping coin
    ;CALL ImposeGravity                  ;do sub to move coin vertically and impose gravity on it
    CALL ImposeGravity_A0
;
    ;LD HL, (ObjectOffset)               ;get original misc object offset
    LD L, <Misc_Y_Speed
    LD A, (HL)                          ;check vertical speed
    CP A, $05
    JP NZ, RunJCSubs                    ;if not moving downward fast enough, keep state as-is
    LD L, <Misc_State
    INC (HL)                            ;otherwise increment state to change to floatey number
RunJCSubs:
    RelativeMiscPosition_M              ;get relative coordinates
    GetMiscOffscreenBits_M              ;get offscreen information
    ;CALL GetMiscBoundBox
    CALL JCoinGfxHandler                ;draw the coin or floatey number

MiscLoopBack:
    DEC H                               ;decrement misc object offset
    LD A, >Misc_State - $01
    CP A, H
    JP NZ, MiscLoop                     ;loop back until all misc objects handled
    RET

;-------------------------------------------------------------------------------------

GiveOneCoin:
    LD A, $01                           ;set digit modifier to add 1 coin
    LD (DigitModifier_05), A            ;to the current player's coin tally
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
    LD (DigitModifier_04), A            ;200 points to the player
    ; FALL THROUGH

AddToScore:
    LD DE, PlayerScoreDisplay + $05
    LD A, (CurrentPlayer)
    OR A
    JP Z, +
    LD E, <OffScr_ScoreDisplay + $05
+:
    CALL DigitsMathRoutine
    ; FALL THROUGH

GetSBNybbles:
    LD A, (CurrentPlayer)               ;get current player
    OR A
    LD A, $02                           ;get nybbles based on player, use to update score and coins
    JP Z, UpdateNumber
    LD A, $13
    ; FALL THROUGH

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
    LD A, OBJECTID_PowerUpObject            ;load power-up identifier into
    LD (Enemy_ID_05), A                     ;special use slot of enemy object buffer
;
    LD L, <Block_PageLoc                    ;store page location of block object
    LD A, (HL)                              ;as page location of power-up object
    LD (Enemy_PageLoc_05), A
;
    LD L, <Block_X_Position                 ;store horizontal coordinate of block object
    LD A, (HL)
    LD (Enemy_X_Position_05), A             ;as horizontal coordinate of power-up object
;
    LD A, $01                               ;set vertical high byte of power-up object
    LD (Enemy_Y_HighPos_05), A
;
    LD L, <Block_Y_Position                 ;get vertical coordinate of block object
    LD A, (HL)
    SUB A, $08                              ;subtract 8 pixels
    LD (Enemy_Y_Position_05), A             ;and use as vertical coordinate of power-up object
;
    LD A, $01
    LD (Enemy_State_05), A                  ;set power-up object's state
    LD (Enemy_Flag_05), A                   ;set buffer flag
;
    LD A, $03                               ;set bounding box size control for power-up object
    LD (Enemy_BoundBoxCtrl_05), A
;
    LD A, (PowerUpType)                     ;check currently loaded power-up type
    CP A, $02
    JP NC, PutBehind                        ;if star or 1-up, branch ahead
    LD A, (PlayerStatus)                    ;otherwise check player's current status
    CP A, $02
    JP C, StrType                           ;if player not fiery, use status as power-up type
    SRL A                                   ;otherwise shift right to force fire flower type
StrType:
    LD (PowerUpType), A                     ;store type here
PutBehind:
    ;LD A, %00100000
    ;LD (Enemy_SprAttrib_05), A
    LD A, SNDID_ITEM                        ;load power-up reveal sound and leave
    LD (SFXTrack1.SoundQueue), A
    RET

;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;$00(C) - used to store high nybble of horizontal speed as adder
;$01(D) - used to store low nybble of horizontal speed
;$02(E) - used to store adder to page location

MovePlayerHorizontally:
    LD A, (JumpspringAnimCtrl)      ;if jumpspring currently animating,
    OR A
    RET NZ                          ;branch to leave
    LD H, >Player_Y_Position        ;otherwise set offset to use player's stuff

MoveEnemyHorizontally:
MoveObjectHorizontally:
    LD L, <SprObject_X_Speed
    LD A, (HL)                      ;get currently saved value (horizontal speed, secondary counter, whatever)
    RLCA                            ;flip nibbles
    RLCA
    RLCA
    RLCA
    LD E, A                         ;save in E
    AND A, %11110000                ;isolate low nibble that was moved to high
    LD D, A                         ;store result here
;
    LD A, E                         ;get back value
    AND A, %00001111                ;isolate high nibble that was moved to low
    CP A, $08                       ;if < 8, branch, do not change
    JP C, SaveXSpd
    OR A, %11110000                 ;otherwise alter high nybble
SaveXSpd:              
    LD C, A                         ;save result here
    LD E, $00                       ;load default value here
    OR A                            ;if result positive, leave E alone
    JP P, UseAdder
    DEC E                           ;otherwise decrement E
UseAdder:
    LD L, <SprObject_X_MoveForce
    LD A, (HL)                      ;get whatever number's here
    ADD A, D                        ;add low nybble moved to high
    LD (HL), A                      ;store result here
    LD A, $00                       ;init A
    RLA                             ;rotate carry into d0
    LD D, A                         ;store in D
    RRA                             ;rotate d0 back onto carry
;
    LD L, <SprObject_X_Position
    LD A, (HL)
    ADC A, C                        ;add carry plus saved value (high nybble moved to low
    LD (HL), A                      ;plus $f0 if necessary) to object's horizontal position
;
    DEC L                           ;<SprObject_PageLoc
    LD A, (HL)
    ADC A, E                        ;add carry plus other saved value to the
    LD (HL), A                      ;object's page location and save
;
    LD A, D                         ;pull old carry from D and add
    ADD A, C                        ;to high nybble moved to low
    RET
    
;-------------------------------------------------------------------------------------
;$00(B) - used for downward force
;$01(D) - used for upward force
;$02(C) - used for maximum vertical speed

MovePlayerVertically:
    LD A, (TimerControl)
    OR A
    JP NZ, NoJSChk                  ;if master timer control set, branch ahead
    LD A, (JumpspringAnimCtrl)      ;otherwise check to see if jumpspring is animating
    OR A
    RET NZ                          ;branch to leave if so
NoJSChk:
    LD A, (VerticalForce)           ;dump vertical force 
    LD B, A

    .IF PALBUILD == $00
    LD C, $04                       ;set maximum vertical speed here
    .ELSE
    LD C, $05                       ;PAL diff: Faster maximum vertical speed to compensate FPS difference
    .ENDIF
          
    JP ImposeGravity_A0             ;jump to the code that actually moves it

;--------------------------------

MoveD_EnemyVertically:
    LD B, $3D                       ;set quick movement amount downwards
    LD L, <Enemy_State
    LD A, (HL)                      ;then check enemy state
    CP A, $05                       ;if not set to unique state for spiny's egg, go ahead
    JP NZ, SetHiMax                 ;and use, otherwise set different movement amount, continue on

MoveFallingPlatform:
    LD B, $20                       ;set movement amount

SetHiMax:
    .IF PALBUILD == $00
    LD C, $03                       ;set maximum speed in A
    .ELSE
    LD C, $04                       ;PAL diff: Faster maximum speed to compensate FPS difference
    .ENDIF
    JP ImposeGravity_A0

;--------------------------------

MoveRedPTroopaDown:
    LD BC, $0302                    ;set downward movement amount & max speed here
    LD D, $06                       ;set upward movement amount here
    JP ImposeGravity_A0

MoveRedPTroopaUp:
    LD BC, $0302                    ;set downward movement amount & max speed here
    LD D, $06                       ;set upward movement amount here
    JP ImposeGravity_A1

;--------------------------------

MoveDropPlatform:
    LD BC, $7F02                    ;set movement amount & max speed for drop platform
    JP ImposeGravity_A0

MoveEnemySlowVert:
    .IF PALBUILD == $00
    LD BC, $0F02                    ;set movement amount & max speed for bowser/other objects
    .ELSE
    LD BC, $1202                    ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

    JP ImposeGravity_A0

;--------------------------------

MoveJ_EnemyVertically:
    .IF PALBUILD == $00
    LD BC, $1C03                    ;set movement amount & max speed for podoboo/other objects
    .ELSE
    LD BC, $1F04                    ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

    JP ImposeGravity_A0

;--------------------------------

ImposeGravityBlock:
    .IF PALBUILD == $00
    LD BC, $5008                    ;set movement amount & max speed here
    .ELSE
    LD BC, $5808                    ;PAL diff: Faster speed to compensate FPS difference
    .ENDIF

    JP ImposeGravity_A0

;--------------------------------

MovePlatformDown:
    LD BC, $0503                    ;save downward movement amount & max speed here
    LD D, $0A                       ;save upward movement amount here
    JP ImposeGravity_A0

MovePlatformUp:
    LD BC, $0503                    ;save downward movement amount & max speed here
    LD D, $0A                       ;save upward movement amount here
    ;LD C, A                         ;use as Y, then move onto code shared by red koopa
    ; FALL THROUGH

;-------------------------------------------------------------------------------------
;$00(B) - used for downward force
;$01(D) - used for upward force (ONLY USED IF A == 1)
;$02(C) - used for maximum vertical speed
;$07(E) - used as adder for vertical position

;   A - FLAG TO MOVE UPWARD
;   HL - OBJECT OFFSET
ImposeGravity_A1:
    LD L, <SprObject_Y_MoveForce    ;add value in movement force to contents of dummy variable
    LD A, (HL)
    DEC L                           ;<SprObject_YMF_Dummy
    ADD A, (HL)
    LD (HL), A
;
    LD E, $00                       ;set E to zero by default
    LD L, <SprObject_Y_Speed        ;get current vertical speed
    LD A, (HL)                       
    INC A
    DEC A
    JP P, +                         ;if currently moving downwards, do not decrement Y
    DEC E                           ;otherwise decrement E
+:
    LD L, <SprObject_Y_Position
    ADC A, (HL)                     ;add vertical position to vertical speed plus carry
    LD (HL), A                      ;store as new vertical position
;
    INC L                           ; <SprObject_Y_HighPos
    LD A, (HL)
    ADC A, E                        ;add carry plus contents of $07 to vertical high byte
    LD (HL), A                      ;store as new vertical high byte
;
    LD L, <SprObject_Y_MoveForce
    LD A, (HL)
    ADD A, B                        ;add downward movement amount to contents of SprObject_Y_MoveForce
    LD (HL), A
;
    LD L, <SprObject_Y_Speed        ;add carry to vertical speed and store
    LD A, (HL)
    ADC A, $00
    LD (HL), A
;
    CP A, C                         ;compare to maximum speed
    JP M, +                         ;if less than preset value, skip this part
    LD L, <SprObject_Y_MoveForce
    LD A, (HL)
    CP A, $80                       ;if less positively than preset maximum, skip this part
    JP C, +
    LD (HL), $00                    ;clear fractional
    LD L, <SprObject_Y_Speed
    LD (HL), C                      ;keep vertical speed within maximum value
;
+:
    LD A, C                         ;get two's compliment of maximum speed
    NEG
    LD C, A
;
    LD L, <SprObject_Y_MoveForce
    LD A, (HL)                      ;subtract upward movement amount from contents
    SUB A, D                        ;of movement force, note that $01 is twice as large as $00,
    LD (HL), A                      ;thus it effectively undoes add we did earlier
;
    LD L, <SprObject_Y_Speed
    LD A, (HL)
    SBC A, $00                      ;subtract borrow from vertical speed and store
    LD (HL), A
;
    CP A, C                         ;compare vertical speed to two's compliment
    RET P                           ;if less negatively than preset maximum, skip this part
;
    LD L, <SprObject_Y_MoveForce
    LD A, (HL)                      ;check if fractional part is above certain amount,
    CP A, $80
    RET NC                          ;and if so, branch to leave
;   
    LD (HL), $FF                    ;clear fractional
    LD L, <SprObject_Y_Speed        ;keep vertical speed within maximum value
    LD (HL), C
    RET

ImposeGravity_A0:
    LD L, <SprObject_Y_MoveForce    ;add value in movement force to contents of dummy variable
    LD A, (HL)
    DEC L                           ;<SprObject_YMF_Dummy
    ADD A, (HL)
    LD (HL), A
;
    LD E, $00                       ;set E to zero by default
    LD L, <SprObject_Y_Speed        ;get current vertical speed
    LD A, (HL)                     
    INC A
    DEC A
    JP P, +                         ;if currently moving downwards, do not decrement Y
    DEC E                           ;otherwise decrement E
+:
    LD L, <SprObject_Y_Position
    ADC A, (HL)                     ;add vertical position to vertical speed plus carry
    LD (HL), A                      ;store as new vertical position
;
    INC L                           ; <SprObject_Y_HighPos
    LD A, (HL)
    ADC A, E                        ;add carry plus contents of $07 to vertical high byte
    LD (HL), A                      ;store as new vertical high byte
;
    LD L, <SprObject_Y_MoveForce
    LD A, (HL)
    ADD A, B                        ;add downward movement amount to contents of SprObject_Y_MoveForce
    LD (HL), A
;
    LD L, <SprObject_Y_Speed        ;add carry to vertical speed and store
    LD A, (HL)
    ADC A, $00
    LD (HL), A
;
    CP A, C                         ;compare to maximum speed
    RET M                           ;if less than preset value, skip this part
    LD L, <SprObject_Y_MoveForce
    LD A, (HL)
    CP A, $80                       ;if less positively than preset maximum, skip this part
    RET C
    LD (HL), $00                    ;clear fractional
    LD L, <SprObject_Y_Speed
    LD (HL), C                      ;keep vertical speed within maximum value
    RET

;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;$01(N/A) - enemy buffer offset

FireballEnemyCollision:
    LD L, <Fireball_State           ;check to see if fireball state is set at all
    LD A, (HL)
    OR A
    RET Z                           ;branch to leave if not
    RET M                           ;branch to leave also if d7 in state is set
;
    LD A, (FrameCounter)
    RRCA                            ;get LSB of frame counter
    RET C                           ;branch to leave if set (do routine every other frame)
;
    LD D, H                         ;store fireball offset in D
    LD H, >Enemy_ID_04              ;start with last enemy

FireballEnemyCDLoop:
    LD L, <Enemy_State              ;check to see if d5 is set in enemy state
    BIT 5, (HL)
    JP NZ, NoFToECol                ;if so, skip to next enemy slot
;
    LD L, <Enemy_Flag               ;check to see if buffer flag is set
    LD A, (HL)
    OR A
    JP Z, NoFToECol                 ;if not, skip to next enemy slot
;
    LD L, <Enemy_ID                 ;check enemy identifier
    LD A, (HL)
    CP A, $24
    JP C, GoombaDie                 ;if < $24, branch to check further
    CP A, $2B
    JP C, NoFToECol                 ;if in range $24-$2a, skip to next enemy slot
    ; FALL THROUGH
;
GoombaDie:
    CP A, OBJECTID_Goomba           ;check for goomba identifier
    JP NZ, NotGoomba                ;if not found, continue with code
    LD L, <Enemy_State              ;otherwise check for defeated state
    LD A, (HL)
    CP A, $02                       ;if stomped or otherwise defeated,
    JP NC, NoFToECol                ;skip to next enemy slot
    ; FALL THROUGH
;
NotGoomba:
    LD L, <EnemyOffscrBitsMasked    ;if any masked offscreen bits set,
    LD A, (HL)
    OR A
    JP NZ, NoFToECol                ;skip to next enemy slot
    CALL SprObjectCollisionCore     ;do fireball-to-enemy collision detection
    JP NC, NoFToECol                ;if carry clear, no collision, thus do next enemy slot
    EX DE, HL                       ;swap HL and DE to put fireball object into HL
    LD L, <Fireball_State           ;set d7 in enemy state
    SET 7, (HL)
    EX DE, HL                       ;revert swap
    PUSH DE                         ;preserve firebal offset
    CALL HandleEnemyFBallCol        ;jump to handle fireball to enemy collision
    POP DE                          ;get fireball offset back
NoFToECol:
    DEC H                           ;decrement enemy object offset
    LD A, H
    CP A, $C0
    JP NZ, FireballEnemyCDLoop      ;loop back until collision detection done on all enemies
    ;LD HL, (ObjectOffset)
    LD H, D
    RET

.SECTION "BowserIdentities" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
BowserIdentities:
    .db OBJECTID_Goomba, OBJECTID_GreenKoopa, OBJECTID_BuzzyBeetle
    ;.db OBJECTID_Spiny, OBJECTID_Lakitu, OBJECTID_Bloober
    .db OBJECTID_Goomba, OBJECTID_GreenKoopa, OBJECTID_BuzzyBeetle
    .db OBJECTID_HammerBro, OBJECTID_Bowser
.ENDS

HandleEnemyFBallCol:
    CALL RelativeEnemyPosition      ;get relative coordinate of enemy
;
    LD E, H                         ;store enemy offset in E
    LD L, <Enemy_Flag               ;check buffer flag for d7 set
    LD A, (HL)
    OR A
    JP P, ChkBuzzyBeetle            ;branch if not set to continue
;
    AND A, %00001111                ;otherwise mask out high nybble and
    ADD A, >Enemy_ID                ;use low nybble as enemy offset
    LD H, A
    LD L, <Enemy_ID
    LD A, (HL)                      ;check enemy identifier for bowser
    CP A, OBJECTID_Bowser
    JP Z, HurtBowser                ;branch if found
    LD H, E                         ;otherwise retrieve current enemy offset
;

ChkBuzzyBeetle:
    LD L, <Enemy_ID                 ;check for buzzy beetle
    LD A, (HL)
    CP A, OBJECTID_BuzzyBeetle
    RET Z                           ;branch if found to leave (buzzy beetles fireproof)
;
    CP A, OBJECTID_Bowser           ;check for bowser one more time (necessary if d7 of flag was clear)
    JP NZ, ChkOtherEnemies          ;if not found, branch to check other enemies
    ; FALL THROUGH

HurtBowser:
    LD A, (BowserHitPoints)         ;decrement bowser's hit points
    DEC A
    LD (BowserHitPoints), A
    JP NZ, ExHCF                    ;if bowser still has hit points, branch to leave
;
    CALL InitVStf                   ;otherwise do sub to init vertical speed and movement force
    LD L, <Enemy_X_Speed            ;initialize horizontal speed
    LD (HL), A
    LD (EnemyFrenzyBuffer), A       ;init enemy frenzy buffer
;
    LD L, <Enemy_Y_Speed            ;set vertical speed to make defeated bowser jump a little
    LD (HL), $FE
;
    LD A, (WorldNumber)             ;use world number as offset
    LD BC, BowserIdentities         ;get enemy identifier to replace bowser with
    addAToBC8_M
    LD A, (BC)
    LD L, <Enemy_ID
    LD (HL), A                      ;set as new enemy identifier
;
    LD A, (WorldNumber)             ;check to see if using offset of 3 or more
    CP A, $06;$03                   ;branch if so
    LD A, $20                       ;set A to use starting value for state
    JP NC, SetDBSte
    OR A, $03                       ;otherwise add 3 to enemy state (shell enemies)
SetDBSte:
    LD L, <Enemy_State              ;set defeated enemy state
    LD (HL), A
;
    LD A, SNDID_FALL                ;load bowser defeat sound
    LD (SFXTrack1.SoundQueue), A
;
    LD H, E                         ;get enemy offset
    LD A, $09                       ;award 5000 points to player for defeating bowser
    JP EnemySmackScore              ;unconditional branch to award points

ChkOtherEnemies:
    CP A, OBJECTID_BulletBill_FrenzyVar
    RET Z                           ;branch to leave if bullet bill (frenzy variant)
    CP A, OBJECTID_Podoboo
    RET Z                           ;branch to leave if podoboo
    CP A, $15
    RET NC                          ;branch to leave if identifier => $15
    ; FALL THROUGH

ShellOrBlockDefeat:
    LD L, <Enemy_ID                 ;check for piranha plant
    LD A, (HL)
    CP A, OBJECTID_PiranhaPlant
    JP NZ, StnE                     ;branch if not found
;
    LD L, <Enemy_Y_Position         ;add 24 pixels to enemy object's vertical position
    LD A, (HL)
    ADD A, $19;$18                  ;(+1 due to carry being set and 6502 code using 'adc' without 'clc' beforehand) 
    LD (HL), A
;
StnE:
    CALL ChkToStunEnemies           ;do yet another sub
;
    LD L, <Enemy_State              ;mask out 2 MSB of enemy object's state
    LD A, (HL)
    AND A, %00011111
    OR A, %00100000                 ;set d5 to defeat enemy and save as new state
    LD (HL), A
;
    LD C, $02                       ;award 200 points by default
    LD L, <Enemy_ID                 ;check for hammer bro
    LD A, (HL)
    CP A, OBJECTID_HammerBro
    JP NZ, GoombaPoints             ;branch if not found
    LD C, $06                       ;award 1000 points for hammer bro
    ; FALL THROUGH

GoombaPoints:
    CP A, OBJECTID_Goomba           ;check for goomba
    LD A, C                         ;move score value into A
    JP NZ, EnemySmackScore          ;branch if not found
    LD A, $01                       ;award 100 points for goomba
    ; FALL THROUGH

EnemySmackScore:
    CALL SetupFloateyNumber         ;update necessary score variables
    LD A, SNDID_KICK                ;play smack enemy sound
    LD (SFXTrack0.SoundQueue), A
    RET

ExHCF:
    LD H, E                         ;get enemy offset
    RET

;-------------------------------------------------------------------------------------

PlayerHammerCollision:
    LD A, (FrameCounter)            ;get frame counter
    RRCA                            ;shift d0 into carry
    RET NC                          ;branch to leave if d0 not set to execute every other frame
;
    LD A, (TimerControl)            ;if either master timer control
    LD C, A
    LD A, (Misc_OffscrBits)         ;or any offscreen bits for hammer are set,
    OR A, C
    RET NZ                          ;branch to leave
;
    LD D, H                         ;move misc object to D (H will be changed to player's offset)
    CALL PlayerCollisionCore        ;do player-to-hammer collision detection
    LD H, D                         ;move misc object back into H
    JP NC, ClHCol                   ;if no collision, then branch
;
    LD L, <Misc_Collision_Flag      ;otherwise read collision flag
    LD A, (HL)
    OR A
    RET NZ                          ;if collision flag already set, branch to leave
    LD (HL), $01                    ;otherwise set collision flag now
;
    LD L, <Misc_X_Speed             ;get two's compliment of
    LD A, (HL)                      ;hammer's horizontal speed
    NEG
    LD (HL), A                      ;set to send hammer flying the opposite direction
;
    LD A, (StarInvincibleTimer)     ;if star mario invincibility timer set,
    OR A
    RET NZ                          ;branch to leave
    JP InjurePlayer                 ;otherwise jump to hurt player, do not return
;
ClHCol:
    LD L, <Misc_Collision_Flag      ;clear collision flag
    LD (HL), $00
    RET

;-------------------------------------------------------------------------------------

HandlePowerUpCollision:
    CALL EraseEnemyObject           ;erase the power-up object
;
    LD A, $06                       ;award 1000 points to player by default
    CALL SetupFloateyNumber
;
    LD A, SNDID_POWERUP             ;play the power-up sound
    LD (SFXTrack1.SoundQueue), A
    LD A, (OptionBitflags)          ;load additional sfx layer if in FM mode
    AND A, $01 << $01
    JP Z, +
    LD A, SNDID_POWERUP_01
    LD (SFXTrack0.SoundQueue), A
+:
;
    LD A, (PowerUpType)             ;check power-up type
    CP A, $02
    JP C, Shroom_Flower_PUp         ;if mushroom or fire flower, branch
    CP A, $03
    JP Z, SetFor1Up                 ;if 1-up mushroom, branch
;
    LD A, $23                       ;otherwise set star mario invincibility
    LD (StarInvincibleTimer), A     ;timer, and load the star mario music
;
    LD A, SNDID_INVINCIBLE          ;into the area music queue, then leave
    LD (MusicTrack0.SoundQueue), A 
    RET

Shroom_Flower_PUp:
    LD A, (PlayerStatus)            ;if player status = small, branch
    OR A
    JP Z, UpToSuper
;
    CP A, $01                       ;if player status not super, leave
    RET NZ
;
    LD A, $02                       ;set player status to fiery
    LD (PlayerStatus), A
    CALL GetPlayerColors            ;run sub to change colors of player
;
    LD HL, (ObjectOffset)
    LD A, $0C                       ;set value to be used by subroutine tree (fiery)
    JP UpToFiery                    ;jump to set values accordingly

SetFor1Up:
    XOR A                           ;don't play additional layer for powerup sfx
    LD (SFXTrack0.SoundQueue), A    ;1-up sfx gets set to play later in FloateyNumbersRoutine
    LD L, <FloateyNum_Control       ;change 1000 points into 1-up instead
    LD (HL), $0B
    RET

UpToSuper:
    LD A, $01                       ;set player status to super
    LD (PlayerStatus), A
    LD A, $09                       ;set value to be used by subroutine tree (super)

UpToFiery:
    LD C, $00                       ;set value to be used as new player state
    JP SetPRout                     ;set values to stop certain things in motion

;--------------------------------

; .SECTION "DemotedKoopaXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; DemotedKoopaXSpdData:
;     .db $08, $f8
; .ENDS

PlayerEnemyCollision:
    LD A, (FrameCounter)            ;check counter for d0 set
    RRCA
    RET C                           ;if set, branch to leave
;
    CALL CheckPlayerVertical        ;if player object is completely offscreen or
    RET NC                          ;if down past 224th pixel row, branch to leave
;
    LD L, <EnemyOffscrBitsMasked    ;if current enemy is offscreen by any amount,
    LD A, (HL)
    OR A
    RET NZ                          ;go ahead and branch to leave
;
    LD A, (GameEngineSubroutine)    ;if not set to run player control routine
    CP A, $08
    RET NZ                          ;on next frame, branch to leave
;
    LD L, <Enemy_State              ;if enemy state has d5 set, branch to leave
    BIT 5, (HL)
    RET NZ
;
    LD D, H                         ;move enemy offset to D
    CALL PlayerCollisionCore        ;do collision detection on player vs. enemy
    LD H, D                         ;move to enemy offset back to H
    JP C, CheckForPUpCollision      ;if collision, branch past this part here
;
    LD L, <Enemy_CollisionBits      ;otherwise, clear d0 of current enemy object's
    RES 0, (HL)                     ;collision bit
    RET

CheckForPUpCollision:
    LD L, <Enemy_ID                 ;check for power-up object
    LD A, (HL)
    CP A, OBJECTID_PowerUpObject
    JP Z, HandlePowerUpCollision    ;if found, jump to handle it
;
    LD A, (StarInvincibleTimer)     ;if star mario invincibility timer hasn't expired,
    OR A
    JP NZ, ShellOrBlockDefeat       ;kill enemy like hit with a shell, or from beneath
    ; FALL THROUGH

;HandlePECollisions:
    LD L, <Enemy_CollisionBits      ;check enemy collision bits for d0 set
    LD A, (HL)                      ;or for being offscreen at all
    AND A, %00000001
    LD L, <EnemyOffscrBitsMasked
    OR A, (HL)
    RET NZ                          ;branch to leave if either is true
;
    LD L, <Enemy_CollisionBits      ;otherwise set d0 now
    SET 0, (HL)
;
    LD L, <Enemy_ID                 ;branch if spiny
    LD A, (HL)
    CP A, OBJECTID_Spiny
    JP Z, ChkForPlayerInjury
    CP A, OBJECTID_PiranhaPlant     ;branch if piranha plant
    JP Z, InjurePlayer
    CP A, OBJECTID_Podoboo          ;branch if podoboo
    JP Z, InjurePlayer
    CP A, OBJECTID_BulletBill_CannonVar ;branch if bullet bill
    JP Z, ChkForPlayerInjury
    CP A, $15                       ;branch if object => $15
    JP NC, InjurePlayer
    LD A, (AreaType)                ;branch if water type level
    OR A
    JP Z, InjurePlayer
    LD L, <Enemy_State              ;branch if d7 of enemy state was set
    LD A, (HL)
    OR A
    JP M, ChkForPlayerInjury
    AND A, %00000111                ;mask out all but 3 LSB of enemy state
    CP A, $02                       ;branch if enemy is in normal or falling state
    JP C, ChkForPlayerInjury
    LD L, <Enemy_ID                 ;branch to leave if goomba in defeated state
    LD A, (HL)
    CP A, OBJECTID_Goomba
    RET Z
;
    LD A, SNDID_KICK                ;play smack enemy sound
    LD (SFXTrack0.SoundQueue), A
;
    LD L, <Enemy_State              ;set d7 in enemy state, thus become moving shell
    SET 7, (HL)
;
    CALL EnemyFacePlayer            ;set moving direction and get offset
;
    .IF PALBUILD == $00             ;KickedShellXSpdData
    LD A, $30                       ;load and set horizontal speed data with offset                 
    JP Z, +
    LD A, $D0
    .ELSE
    LD A, $38                       ;PAL diff: Faster speed to compensate FPS difference
    JP Z, +
    LD A, $C8
    .ENDIF
+:
    LD L, <Enemy_X_Speed
    LD (HL), A
;
    LD A, H                         ;check shell enemy's timer
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (BC)
    CP A, $03
    LD A, (StompChainCounter)       ;add three to whatever the stomp counter contains
    INC A                           ;(SMS) importantly, don't touch carry flag
    INC A
    INC A
    JP NC, SetupFloateyNumber       ;if above a certain point, branch using the points
    LD A, (BC)                      ;otherwise, set points based on proximity to timer expiration
    LD BC, KickedShellPtsData       ;set values for floatey number now
    addAToBC8_M
    LD A, (BC)
    JP SetupFloateyNumber

.SECTION "KickedShellPtsData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
KickedShellPtsData:
    .db $0a, $06, $04
.ENDS

ChkForPlayerInjury:
    LD A, (Player_Y_Speed)          ;check player's vertical speed
    OR A
    JP M, ChkInj                    ;perform procedure below if player moving upwards
    JP NZ, EnemyStomped             ;or not at all, and branch elsewhere if moving downwards
ChkInj:
    LD L, <Enemy_ID                 ;branch if enemy object < $07
    LD A, (HL)

    .IF PALBUILD == $00 
    CP A, OBJECTID_Bloober
    JP C, ChkETmrs
    LD A, (Player_Y_Position)       ;add 12 pixels to player's vertical position
    ADD A, $0C
    .ELSE                           ;PAL bugfix: Vertical difference deciding whether Mario stomped or got hit depends on the enemy
    CP A, OBJECTID_FlyingCheepCheep
    LD A, (Player_Y_Position)
    LD C, $14
    JP NZ, ChkInj2
    LD C, $07
ChkInj2:
    CCF
    ADC A, C
    .ENDIF

    LD L, <Enemy_Y_Position         ;compare modified player's position to enemy's position
    CP A, (HL)
    JP C, EnemyStomped              ;branch if this player's position above (less than) enemy's
ChkETmrs:
    LD A, (StompTimer)              ;check stomp timer
    OR A
    JP NZ, EnemyStomped             ;branch if set
    LD A, (InjuryTimer)             ;check to see if injured invincibility timer still
    OR A
    RET NZ                          ;counting down, and branch elsewhere to leave if so
    LD A, (Enemy_Rel_XPos)          ;if player's relative position to the right of enemy's
    LD C, A
    LD A, (Player_Rel_XPos)
    CP A, C
    JP NC, ChkEnemyFaceRight        ;relative position, do a jump here
;
    LD L, <Enemy_MovingDir          ;if enemy moving towards the right,
    LD A, (HL)
    CP A, $01
    CALL Z, EnemyTurnAround         ;turn the enemy around
    ; FALL THROUGH

InjurePlayer:
    LD A, (InjuryTimer)             ;check again to see if injured invincibility timer is
    OR A
    RET NZ                          ;at zero, and branch to leave if so
    ; FALL THROUGH

ForceInjury:
    LD A, (PlayerStatus)            ;check player's status
    OR A
    JP Z, KillPlayer                ;branch if small
;
    XOR A                           ;otherwise set player's status to small
    LD (PlayerStatus), A
    LD A, $08                       ;set injured invincibility timer
    LD (InjuryTimer), A
;
    LD A, SNDID_PIPE                ;play pipedown/injury sound
    LD (SFXTrack0.SoundQueue), A
;
    PUSH HL
    CALL GetPlayerColors            ;change player's palette if necessary
    POP HL
    ;LD HL, (ObjectOffset)           ;get back enemy offset
    LD A, $0A                       ;set subroutine to run on next frame
SetKRout:
    LD C, $01                       ;set new player state
SetPRout:
    LD (GameEngineSubroutine), A    ;load new value to run subroutine on next frame
    LD A, C
    LD (Player_State), A            ;store new player state
    XOR A
    LD (ScrollAmount), A            ;initialize scroll speed
    DEC A
    LD (TimerControl), A            ;set master timer control flag to halt timers
    RET

KillPlayer:
    LD (Player_X_Speed), A          ;halt player's horizontal movement by initializing speed
;
    LD A, (OperMode)
    OR A
    JP Z, +
    LD A, SNDID_DEATH               ;set event music queue to death music
    LD (MusicTrack0.SoundQueue), A  ; EVENT
+:
    LD A, $FC                       ;set new vertical speed
    LD (Player_Y_Speed), A
    LD A, $0B                       ;set subroutine to run on next frame
    JP SetKRout                     ;branch to set player's state and other things

.SECTION "StompedEnemyPtsData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
StompedEnemyPtsData:
    .db $02, $06, $05, $06
.ENDS

EnemyStomped:
    LD L, <Enemy_ID                 ;check for spiny, branch to hurt player
    LD A, (HL)
    CP A, OBJECTID_Spiny
    JP Z, InjurePlayer              ;if found
;  
    LD A, SNDID_SWIM                ;otherwise play stomp/swim sound
    LD (SFXTrack0.SoundQueue), A
;
    LD L, <Enemy_ID
    LD A, (HL)
    LD BC, StompedEnemyPtsData      ;initialize points data offset for stomped enemies
    CP A, OBJECTID_FlyingCheepCheep ;branch for cheep-cheep
    JP Z, EnemyStompedPts
    CP A, OBJECTID_BulletBill_FrenzyVar ;branch for either bullet bill object
    JP Z, EnemyStompedPts
    CP A, OBJECTID_BulletBill_CannonVar
    JP Z, EnemyStompedPts
    CP A, OBJECTID_Podoboo          ;branch for podoboo (this branch is logically impossible
    JP Z, EnemyStompedPts           ;for cpu to take due to earlier checking of podoboo)
    INC C                           ;increment points data offset
    CP A, OBJECTID_HammerBro        ;branch for hammer bro
    JP Z, EnemyStompedPts
    INC C                           ;increment points data offset
    CP A, OBJECTID_Lakitu           ;branch for lakitu
    JP Z, EnemyStompedPts
    INC C                           ;increment points data offset
    CP A, OBJECTID_Bloober
    JP NZ, ChkForDemoteKoopa        ;branch if NOT bloober
    ; FALL THROUGH

EnemyStompedPts:
    LD A, (BC)                      ;load points data using offset in Y
    CALL SetupFloateyNumber         ;run sub to set floatey number controls
;
    LD L, <Enemy_MovingDir          ;save enemy movement direction to stack
    LD A, (HL)
    PUSH AF
    CALL SetStun                    ;run sub to kill enemy
    POP AF
    LD L, <Enemy_MovingDir          ;return enemy movement direction from stack
    LD (HL), A
;
    LD A, %00100000                 ;set d5 in enemy state
    LD L, <Enemy_State
    LD (HL), A
;
    CALL InitVStf                   ;nullify vertical speed, physics-related thing,
    LD L, <Enemy_X_Speed            ;and horizontal speed
    LD (HL), A
    LD A, $FD                       ;set player's vertical speed, to give bounce
    LD (Player_Y_Speed), A
    RET

ChkForDemoteKoopa:
    CP A, $09                       ;branch elsewhere if enemy object < $09
    JP C, HandleStompedShellE
;
    AND A, %00000001                ;demote koopa paratroopas to ordinary troopas
    LD L, <Enemy_ID
    LD (HL), A
;
    LD L, <Enemy_State              ;return enemy to normal state
    LD (HL), $00
;
    LD A, $03                       ;award 400 points to the player
    CALL SetupFloateyNumber
;
    CALL InitVStf                   ;nullify physics-related thing and vertical speed
    CALL EnemyFacePlayer            ;turn enemy around if necessary
    LD A, $08                       ;DemotedKoopaXSpdData
    JP Z, +
    LD A, $F8
+:
    LD L, <Enemy_X_Speed            ;set appropriate moving speed based on direction
    LD (HL), A
    JP SBnce                        ;then move onto something else

HandleStompedShellE:
    LD L, <Enemy_State              ;set defeated state for enemy
    LD (HL), $04
;
    LD A, (StompChainCounter)       ;increment the stomp counter
    INC A
    LD (StompChainCounter), A
    LD C, A
    LD A, (StompTimer)              ;add whatever is in the stomp counter
    ADD A, C                        ;to whatever is in the stomp timer
    CALL SetupFloateyNumber         ;award points accordingly
;
    LD A, (StompTimer)              ;increment stomp timer of some sort
    INC A
    LD (StompTimer), A
;
    LD A, H                         ;get enemy's timer address
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD A, (PrimaryHardMode)         ;check primary hard mode flag
    OR A

    .IF PALBUILD == $00             ;RevivalRateData
    LD A, $10                       ;load timer setting according to flag                       
    JP Z, +
    LD A, $0B
    .ELSE
    LD A, $0D                       ;PAL diff: Faster timer to compensate FPS difference
    JP Z, +
    LD A, $09
    .ENDIF

+:
    LD (BC), A                      ;set as enemy timer to revive stomped enemy
    ; FALL THROUGH

SBnce:
    LD A, $FC                       ;set player's vertical speed for bounce
    LD (Player_Y_Speed), A
    RET

ChkEnemyFaceRight:
    LD L, <Enemy_MovingDir          ;check to see if enemy is moving to the right
    LD A, (HL)
    CP A, $01
    CALL NZ, EnemyTurnAround        ;if not, turn the enemy around, if necessary
    JP InjurePlayer                 ;go back to hurt player

EnemyFacePlayer:
    LD C, $01                       ;set to move right by default
    CALL PlayerEnemyDiff            ;get horizontal difference between player and enemy
    JP P, SFcRt                     ;if enemy is to the right of player, do not increment
    INC C                           ;otherwise, increment to set to move to the left
SFcRt:
    LD L, <Enemy_MovingDir          ;set moving direction here
    LD (HL), C
    DEC C                           ;then decrement to use as a proper offset
    RET

SetupFloateyNumber:
    LD L, <FloateyNum_Control       ;set number of points control for floatey numbers
    LD (HL), A
    LD L, <FloateyNum_Timer         ;set timer for floatey numbers
    LD (HL), $30
;
    LD L, <Enemy_Y_Position         ;set vertical coordinate
    LD A, (HL)
    LD L, <FloateyNum_Y_Pos
    LD (HL), A
;
    LD A, (Enemy_Rel_XPos)          ;set horizontal coordinate and leave
    LD L, <FloateyNum_X_Pos
    LD (HL), A
    RET

;-------------------------------------------------------------------------------------
;$01(N/A) - used to hold enemy offset for second enemy

.SECTION "SetBitsMask" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
SetBitsMask:
    .db %10000000, %01000000, %00100000, %00010000, %00001000, %00000100, %00000010
.ENDS

; .SECTION "ClearBitsMask" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; ClearBitsMask:
;     .db %01111111, %10111111, %11011111, %11101111, %11110111, %11111011, %11111101
; .ENDS

EnemiesCollision:
    LD A, (FrameCounter)                ;check counter for d0 set
    RRCA
    RET NC                              ;if d0 not set, leave
;
    LD L, <Enemy_ID                     ;if enemy object => $15, branch to leave
    LD A, (HL)
    CP A, $15
    RET NC
;
    CP A, OBJECTID_Lakitu               ;if lakitu, branch to leave
    RET Z
;
    CP A, OBJECTID_PiranhaPlant         ;if piranha plant, branch to leave
    RET Z
;
    LD L, <EnemyOffscrBitsMasked        ;if masked offscreen bits nonzero, branch to leave
    LD A, (HL)
    OR A
    RET NZ
;
    LD A, H                             ;check if were on the first enemy
    DEC A
    CP A, $C0
    RET Z                               ;branch to leave if there are no other enemies
    LD D, A                             ;move second enemy offset into D
;
    LD A, H                             ;use enemy as offset into SetBitsMask
    SUB A, $C1
    LD BC, SetBitsMask
    addAToBC8_M
    LD A, (BC)
    LD IYL, A                           ;load bitmask into IYL
    CPL
    LD IYH, A                           ;load inverted bitmask into IYH

;   DE: 2ND ENEMY, HL: CURRENT ENEMY
ECLoop:
    LD E, <Enemy_Flag                   ;check enemy object enable flag
    LD A, (DE)
    OR A
    JP Z, ReadyNextEnemy                ;branch if flag not set
;
    LD E, <Enemy_ID                     ;check for enemy object => $15
    LD A, (DE)
    CP A, $15
    JP NC, ReadyNextEnemy               ;branch if true
;
    CP A, OBJECTID_Lakitu               ;branch if enemy object is lakitu
    JP Z, ReadyNextEnemy
;
    CP A, OBJECTID_PiranhaPlant         ;branch if enemy object is piranha plant
    JP Z, ReadyNextEnemy
;
    LD E, <EnemyOffscrBitsMasked
    LD A, (DE)
    OR A
    JP NZ, ReadyNextEnemy               ;branch if masked offscreen bits set
;
    CALL SprObjectCollisionCore         ;do collision detection using the two enemies here
    JP NC, NoEnemyCollision             ;if carry clear, no collision, branch ahead of this
;
    LD E, <Enemy_State
    LD L, E
    LD A, (DE)
    OR A, (HL)                          ;check both enemy states for d7 set
    AND A, %10000000
    JP NZ, YesEC                        ;branch if at least one of them is set
;
    LD E, <Enemy_CollisionBits          ;load first enemy's collision-related bits
    LD A, (DE)
    AND A, IYL                          ;check to see if bit connected to second enemy is
    JP NZ, ReadyNextEnemy               ;already set, and move onto next enemy slot if set
    LD A, (DE)
    OR A, IYL                           ;if the bit is not set, set it now
    LD (DE), A
;
YesEC:
    CALL ProcEnemyCollisions            ;react according to the nature of collision
    JP ReadyNextEnemy                   ;move onto next enemy slot

NoEnemyCollision:
    LD E, <Enemy_CollisionBits          ;load first enemy's collision-related bits
    LD A, (DE)
    AND A, IYH                          ;clear bit connected to second enemy
    LD (DE), A                          ;then move onto next enemy slot
    ; FALL THROUGH

ReadyNextEnemy:
    DEC D                               ;decrement second enemy's object buffer offset
    LD A, D
    CP A, $C0
    JP NZ, ECLoop                       ;loop until all enemy slots have been checked
    RET

; ---------

;   DE: 2ND ENEMY, HL: CURRENT ENEMY
ProcEnemyCollisions:
    LD E, <Enemy_State                  ;check both enemy states for d5 set
    LD L, E
    LD A, (DE)
    OR A, (HL)
    AND A, %00100000                    ;if d5 is set in either state, or both, branch
    RET NZ                              ;to leave and do nothing else at this point
;
    LD A, (HL)
    CP A, $06                           ;if second* enemy state < $06, branch elsewhere
    JP C, ProcSecondEnemyColl           ;*I think this is meant to say "first"
;
    LD L, <Enemy_ID                     ;check second* enemy identifier for hammer bro
    LD A, (HL)                          ;*same correction
    CP A, OBJECTID_HammerBro            ;if hammer bro found in alt state, branch to leave
    RET Z
;
    LD A, (DE)                          ;check first* enemy state for d7 set
    ADD A, A                            ;*meant to say second I'm pretty sure
    JP NC, ShellCollisions              ;branch if d7 is clear
;
    LD A, $06
    CALL SetupFloateyNumber             ;award 1000 points for killing enemy
    PUSH DE
    CALL ShellOrBlockDefeat             ;then kill enemy, then load (KILL CURRENT ENEMY)
    POP DE
    ; FALL THROUGH

ShellCollisions:
    EX DE, HL                           ;DE: CURRENT ENEMY, HL: 2ND ENEMY
    CALL ShellOrBlockDefeat             ;kill second enemy
;
    EX DE, HL                           ;DE: 2ND ENEMY, HL: N/A
    LD HL, (ObjectOffset)               ;HL: CURRENT ENEMY
    LD L, <ShellChainCounter            ;get chain counter for shell
    LD A, (HL)
    INC (HL)                            ;increment chain counter for additional enemies
    ADD A, $04                          ;add four to get appropriate point offset
    EX DE, HL                           ;DE: CURRENT ENEMY, HL: 2ND ENEMY
    CALL SetupFloateyNumber             ;award appropriate number of points for second enemy
    EX DE, HL                           ;DE: 2ND ENEMY, HL: CURRENT ENEMY
    RET

ProcSecondEnemyColl:
    LD E, <Enemy_State                  ;if first enemy state < $06, branch elsewhere
    LD A, (DE)
    CP A, $06
    JP C, MoveEOfs
;
    LD E, <Enemy_ID                     ;check first enemy identifier for hammer bro
    LD A, (DE)
    CP A, OBJECTID_HammerBro            ;if hammer bro found in alt state, branch to leave
    RET Z
;
    PUSH DE
    CALL ShellOrBlockDefeat             ;otherwise, kill first enemy (KILL CURRENT ENEMY)
    POP DE
;
    EX DE, HL                           ;DE: CURRENT ENEMY, HL: SECOND ENEMY
    LD L, <ShellChainCounter            ;get chain counter for shell
    LD A, (HL)
    INC (HL)                            ;increment chain counter for additional enemies
    EX DE, HL                           ;DE: 2ND ENEMY, HL: CURRENT ENEMY
    ADD A, $04                          ;add four to get appropriate point offset
    JP SetupFloateyNumber               ;award appropriate number of points for first enemy

MoveEOfs:
    EX DE, HL                           ;DE: CURRENT ENEMY, HL: 2ND ENEMY
    CALL EnemyTurnAround                ;do the sub here using second enemy
    EX DE, HL                           ;DE: 2ND ENEMY, HL: CURRENT ENEMY
    ; FALL THROUGH

EnemyTurnAround:
    LD L, <Enemy_ID                     ;check for specific enemies
    LD A, (HL)
    CP A, OBJECTID_PiranhaPlant
    RET Z                               ;if piranha plant, leave
    CP A, OBJECTID_Lakitu
    RET Z                               ;if lakitu, leave
    CP A, OBJECTID_HammerBro
    RET Z                               ;if hammer bro, leave
    CP A, OBJECTID_Spiny
    JP Z, RXSpd                         ;if spiny, turn it around
    CP A, OBJECTID_GreenParatroopaJump
    JP Z, RXSpd                         ;if green paratroopa, turn it around
    CP A, $07
    RET NC                              ;if any OTHER enemy object => $07, leave
;
RXSpd:
    LD L, <Enemy_X_Speed                ;load horizontal speed
    LD A, (HL)                          ;get two's compliment for horizontal speed
    NEG
    LD (HL), A                          ;store as new horizontal speed
    LD L, <Enemy_MovingDir
    LD A, (HL)
    XOR A, %00000011                    ;invert moving direction and store, then leave
    LD (HL), A                          ;thus effectively turning the enemy around
    RET

;-------------------------------------------------------------------------------------
;$00(C) - vertical position of platform

LargePlatformCollision:
    LD L, <PlatformCollisionFlag        ;save value here
    LD (HL), $FF
;
    LD A, (TimerControl)                ;check master timer control
    OR A
    RET NZ                              ;if set, branch to leave
;
    LD L, <Enemy_State                  ;if d7 set in object state,
    LD A, (HL)
    OR A
    RET M                               ;branch to leave
;
    LD L, <Enemy_ID                     ;check enemy object identifier for
    LD A, (HL)                          ;balance platform, branch if not found
    CP A, $24
    JP NZ, ChkForPlayerC_LargeP
;
    LD L, <Enemy_State                  ;set state as enemy offset here
    LD A, (HL)
    ADD A, >Enemy_ID
    LD H, A                             ;H IS CHANGED
    CALL ChkForPlayerC_LargeP           ;perform code with state offset, then original offset, in X

ChkForPlayerC_LargeP:
    CALL CheckPlayerVertical            ;figure out if player is below a certain point
    JP NC, ExLPC                        ;or offscreen, branch to leave if true
;
    LD L, <Enemy_Y_Position             ;store vertical coordinate in
    LD C, (HL)                          ;temp variable for now
    LD D, H                             ;move object offset to D
    CALL PlayerCollisionCore            ;do player-to-platform collision detection
    LD H, D                             ;put enemy offset back into H
    CALL C, ProcLPlatCollisions         ;if collision, perform sub
ExLPC:
    LD HL, (ObjectOffset)               ;get enemy object buffer offset and leave
    RET

;--------------------------------
;$00(C) - counter for bounding boxes

SmallPlatformCollision:
    LD A, (TimerControl)                ;if master timer control set,
    OR A
    RET NZ                              ;branch to leave
;
    LD L, <PlatformCollisionFlag        ;otherwise initialize collision flag
    LD (HL), A
;
    CALL CheckPlayerVertical            ;do a sub to see if player is below a certain point
    RET NC                              ;or entirely offscreen, and branch to leave if true
;
    LD C, $02                           ;load counter here for 2 bounding boxes

ChkSmallPlatLoop:
    LD D, H                             ;move enemy offset into D
    LD A, (Enemy_OffscrBits)
    AND A, %00000010                    ;if d1 of offscreen lower nybble bits was set
    RET NZ                              ;then branch to leave
;
    LD E, <BoundingBox_UL_YPos          ;check top of platform's bounding box for being
    LD A, (DE)
    CP A, $20                           ;above a specific point
    JP C, MoveBoundBox                  ;if so, branch, don't do collision detection
;
    CALL PlayerCollisionCore            ;otherwise, perform player-to-platform collision detection
    LD H, D                             ;move enemy offset back into H
    JP C, ProcSPlatCollisions           ;skip ahead if collision

MoveBoundBox:
    LD E, <BoundingBox_UL_YPos          ;move bounding box vertical coordinates
    LD A, (DE)                          ;128 pixels downwards
    ADD A, $80
    LD (DE), A
;
    LD E, <BoundingBox_DR_YPos
    LD A, (DE)
    ADD A, $80
    LD (DE), A
;          
    DEC C                               ;decrement counter we set earlier
    JP NZ, ChkSmallPlatLoop             ;loop back until both bounding boxes are checked
    RET

;--------------------------------

ProcSPlatCollisions:
ProcLPlatCollisions:
    LD A, (BoundingBox_UL_YPos)         ;get difference by subtracting the top
    LD B, A                             ;of the player's bounding box from the bottom
    LD E, <BoundingBox_DR_YPos          ;of the platform's bounding box
    LD A, (DE)
    SUB A, B
    CP A, $04                           ;if difference too large or negative,
    JP NC, ChkForTopCollision           ;branch, do not alter vertical speed of player
;
    LD A, (Player_Y_Speed)              ;check to see if player's vertical speed is moving down
    OR A
    JP P, ChkForTopCollision            ;if so, don't mess with it
;
    LD A, $01                           ;otherwise, set vertical
    LD (Player_Y_Speed), A              ;speed of player to kill jump

ChkForTopCollision:
    EX DE, HL
    LD A, (BoundingBox_DR_YPos)
    LD L, <BoundingBox_UL_YPos          ;get difference by subtracting the top
    SUB A, (HL)                         ;of the platform's bounding box from the bottom
    EX DE, HL    
    CP A, $06                           ;of the player's bounding box
    JP NC, PlatformSideCollisions       ;if difference not close enough, skip all of this
;
    LD A, (Player_Y_Speed)
    OR A
    JP M, PlatformSideCollisions        ;if player's vertical speed moving upwards, skip this
;
    ;LD A, (Temp_Bytes + $00)            ;get saved bounding box counter from earlier
    ;LD C, A
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, $2B                           ;if either of the two small platform objects are found,
    JP Z, SetCollisionFlag              ;regardless of which one, branch to use bounding box counter
    CP A, $2C                           ;as contents of collision flag
    JP Z, SetCollisionFlag
    LD A, H                             ;otherwise use enemy object buffer offset
    SUB A, >Enemy_ID
    LD C, A

SetCollisionFlag:
    LD HL, (ObjectOffset)               ;get enemy object buffer offset
    LD L, <PlatformCollisionFlag        ;save either bounding box counter or enemy offset here
    LD (HL), C
    XOR A                               ;set player state to normal then leave
    LD (Player_State), A
    RET

PlatformSideCollisions:
    LD C, $01                           ;set value here to indicate possible left side collision
;
    EX DE, HL
    LD L, <BoundingBox_UL_XPos          ;get difference by subtracting platform's left edge
    LD A, (BoundingBox_DR_XPos)         ;from player's right edge
    SUB A, (HL)
    CP A, $08                           ;if difference close enough, skip all of this
    EX DE, HL
    JP C, SideC
;
    INC C                               ;otherwise increment value set here for right side collision
    LD HL, BoundingBox_UL_XPos          ;get difference by subtracting player's left edge
    LD E, <BoundingBox_DR_XPos          ;from platform's right edge
    LD A, (DE)
    SUB A, (HL)
    CP A, $09                           ;if difference not close enough, skip subroutine
    JP NC, NoSideC                      ;and instead branch to leave (no collision)
SideC:
    LD A, C
    LD (Temp_Bytes + $00), A
    CALL ImpedePlayerMove               ;deal with horizontal collision
NoSideC:
    LD HL, (ObjectOffset)               ;return with enemy object buffer offset
    RET

;-------------------------------------------------------------------------------------

;.SECTION "PlayerPosSPlatData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
;PlayerPosSPlatData:
;    .db $80, $00
;.ENDS

PositionPlayerOnS_Plat:
    DEC A                               ;use bounding box counter saved in collision flag for offset
    LD A, $80                           ;PlayerPosSPlatData
    JP Z, +
    XOR A
+:
    LD L, <Enemy_Y_Position             ;add positioning data using offset to the vertical
    ADD A, (HL)                         ;coordinate
    JP PositionPlayerOnVPlat@SkipY      ;skip getting enemy's y coordinate

PositionPlayerOnVPlat:
    LD L, <Enemy_Y_Position             ;get vertical coordinate
    LD A, (HL)
@SkipY:
    LD C, A
;
    LD A, (GameEngineSubroutine)        ;if certain routine being executed on this frame,
    CP A, $0B                           ;skip all of this
    RET Z
;
    LD L, <Enemy_Y_HighPos              ;if vertical high byte offscreen, skip this
    LD A, (HL)
    CP A, $01
    RET NZ
;
    LD A, C                             ;subtract 32 pixels from vertical coordinate
    SUB A, $20                          ;for the player object's height
    LD (Player_Y_Position), A           ;save as player's new vertical coordinate
    LD A, (HL)                          ;Enemy_Y_HighPos
    SBC A, $00                          ;subtract borrow and store as player's
    LD (Player_Y_HighPos), A            ;new vertical high byte
    XOR A
    LD (Player_Y_Speed), A              ;initialize vertical speed and low byte of force
    LD (Player_Y_MoveForce), A
    RET

;-------------------------------------------------------------------------------------

;   NZ, NC = ONSCREEN
;   Z, C = OFFSCREEN
CheckPlayerVertical:
    LD A, (Player_OffscrBits)           ;if player object is completely offscreen
    CP A, $F0                           ;vertically, leave this routine
    RET NC
;
    LD A, (Player_Y_HighPos)            ;if player high vertical byte is not
    DEC A                               ;within the screen, leave this routine
    RET NZ
;
    LD A, (Player_Y_Position)           ;if on the screen, check to see how far down
    CP A, $D0                           ;the player is vertically
    RET

;-------------------------------------------------------------------------------------

; GetEnemyBoundBoxOfs:
;     LD A, (ObjectOffset + 1)
;     LD D, A

; GetEnemyBoundBoxOfsArg:
;     ;LD D, A
;     LD A, (Enemy_OffscrBits)
;     AND A, %00001111
;     CP A, %00001111
;     RET

;-------------------------------------------------------------------------------------
;$00-$01 - used to hold many values, essentially temp variables
;$04(IXH) - holds lower nybble of vertical coordinate from block buffer routine
;$eb(UNUSED) - used to hold block buffer adder

; BLOCK BUFFER TEMP VARS
;$02(IXL) - modified y coordinate
;$03(UNUSED) - stores metatile involved in block buffer collisions
;$04(IXH) - comes in with offset to block buffer adder data, goes out with low nybble x/y coordinate
;$05(IYL) - modified x coordinate
;$06-$07(DE) - block buffer address

; .SECTION "PlayerBGUpperExtent" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; PlayerBGUpperExtent:
;     .db $20, $10
;     ;.db $08, $00        ; big, small or crouch
; .ENDS

; .SECTION "BlockBufferAdderData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; BlockBufferAdderData:
;     .db $00, $07, $0e   ; big, swim, small or crouch
; .ENDS

;   head,  footL, footR, side0, side1, side2, side3
;   $0804, $0320, $0C20, $0208, $0218, $0D08, $0D18 ; big
;   $0802, $0320, $0C20, $0208, $0218, $0D08, $0D18 ; swim
;   $0812, $0320, $0C20, $0218, $0218, $0D18, $0D18 ; small/crouch
;    XXYY

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
    DEC A                               ;check player's vertical high byte for still on the screen
    RET NZ                              ;branch to leave if not
;
    DEC A                               ;initialize player's collision flag
    LD (Player_CollisionBits), A
;
    LD A, (Player_Y_Position)
    CP A, $CF                           ;if not too close to the bottom of screen, continue
    RET NC                              ;otherwise leave

;ChkCollSize:
    LD BC, $0812                        ;load block offsets for crouching/small
    LD E, $10                           ;load height comparision for crouching/small
    LD A, (PlayerSize)
    LD HL, CrouchingFlag
    OR A, (HL)
    JP NZ, HeadChk                      ;if player crouching or small, skip ahead
    LD E, $20                           ;load height comparision for big
;
    LD C, $02                           ;change y offset for swimming
    LD A, (SwimmingFlag)
    OR A
    JP NZ, HeadChk                      ;if swimming flag set, skip ahead
;
    LD C, $04                           ;change y offset for big
HeadChk:
    LD A, (Player_Y_Position)
    CP A, E
    JP C, DoFootCheck                   ;if player is too high, skip this part
;
    BlockBufferColli_Head               ;do player-to-bg collision detection on top of
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

    .IF PALBUILD == $00
    LD A, $01                           ;set player's vertical speed to nullify...
    .ELSE
    LD A, (AreaType)                    ;PAL diff: Set vertical speed to 0 in water stages
    OR A
    LD A, $01
    JP NZ, +
    DEC A
+:
    .ENDIF

    LD (Player_Y_Speed), A              ;...jump or swim

DoFootCheck:
    LD A, (Player_Y_Position)
    CP A, $CF
    JP NC, DoPlayerSideCheck            ;if player is too far down on screen, skip all of this
;
    LD BC, $0320
    BlockBufferColli_Feet               ;do player-to-bg collision detection on bottom left of player
    CALL CheckForCoinMTiles             ;check to see if player touched coin with their left foot
    JP Z, HandleCoinMetatile            ;if so, branch to some other part of code
;
    PUSH AF                             ;save bottom left metatile to stack
    LD B, $0C
    BlockBufferColli_Feet               ;do player-to-bg collision detection on bottom right of player
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
    LD B, A                             ;(SMS) save metatile
    LD A, (JumpspringAnimCtrl)          ;if jumpspring animating right now,
    OR A
    JP NZ, InitSteP                     ;branch ahead
;
    LD A, IXH                           ;check lower nybble of vertical coordinate returned

    .IF PALBUILD == $00
    CP A, $05                           ;from collision detection routine
    .ELSE
    CP A, $06                           ;PAL diff: Floor is one pixel wider to accomodate for faster speeds
    .ENDIF

    JP C, LandPlyr                      ;if lower nybble < 5, branch
;
    LD A, (Player_MovingDir)
    LD (Temp_Bytes + $00), A            ;use player's moving direction as temp variable
    JP ImpedePlayerMove                 ;jump to impede player's movement in that direction
LandPlyr:
    LD A, B                             ;(SMS) get metatile back
    CALL ChkForLandJumpSpring           ;do sub to check for jumpspring metatiles and deal with it
    LD HL, Player_Y_Position
    LD A, $F0                           
    AND A, (HL)                         ;mask out lower nybble of player's vertical position
    LD (HL), A                          ;and store as new vertical position to land player properly
    CALL HandlePipeEntry                ;do sub to process potential pipe entry
    XOR A
    LD (Player_Y_Speed), A              ;initialize vertical speed and fractional
    LD (Player_Y_MoveForce), A          ;movement force to stop player's vertical movement
    LD (StompChainCounter), A           ;initialize enemy stomp counter
InitSteP:
    XOR A
    LD (Player_State), A                ;set player's state to normal
    ; FALL THROUGH

DoPlayerSideCheck:
;   LOOP 1 - LEFT SIDE CHECK
    LD A, $02                           ;set value here to be used as direction in ImpedePlayerMove
    LD (Temp_Bytes + $00), A
    LD BC, $0208
    LD A, (PlayerSize)
    LD HL, CrouchingFlag
    OR A, (HL)
    JP Z, SideCheckLoop
    LD C, $18
SideCheckLoop:
    LD A, (Player_Y_Position)
    CP A, $20
    JP C, BHalf
    CP A, $E4
    RET NC                              ;branch to leave if player is too far down
    CALL BlockBufferColli_Side          ;do player-to-bg collision detection on one half of player
    JP Z, BHalf                         ;branch ahead if nothing found
    CP A, MT_SIDEPIPE_END_TOP           ;otherwise check for pipe metatiles
    JP Z, BHalf                         ;if collided with sideways pipe (top), branch ahead
    CP A, MT_WATERPIPE_TOP              
    JP Z, BHalf                         ;if collided with water pipe (top), branch ahead
    CALL CheckForClimbMTiles            ;do sub to see if player bumped into anything climbable
    JP C, CheckSideMTiles               ;if not, branch to alternate section of code
BHalf:
    LD A, (Player_Y_Position)
    CP A, $08
    RET C
    CP A, $D0
    RET NC
    LD C, $18
    CALL BlockBufferColli_Side          ;do player-to-bg collision detection on other half of player
    JP NZ, CheckSideMTiles              ;if something found, branch
;   LOOP 2 - RIGHT SIDE CHECK
    LD A, $01
    LD (Temp_Bytes + $00), A
    LD BC, $0D08
    LD A, (PlayerSize)
    LD HL, CrouchingFlag
    OR A, (HL)
    JP Z, RightSideCheck
    LD C, $18
RightSideCheck:
    LD A, (Player_Y_Position)
    CP A, $20
    JP C, BHalf2
    CP A, $E4
    RET NC                              ;branch to leave if player is too far down
    CALL BlockBufferColli_Side          ;do player-to-bg collision detection on one half of player
    JP Z, BHalf2                        ;branch ahead if nothing found
    CP A, MT_SIDEPIPE_END_TOP           ;otherwise check for pipe metatiles
    JP Z, BHalf2                        ;if collided with sideways pipe (top), branch ahead
    CP A, MT_WATERPIPE_TOP              
    JP Z, BHalf2                        ;if collided with water pipe (top), branch ahead
    CALL CheckForClimbMTiles            ;do sub to see if player bumped into anything climbable
    JP C, CheckSideMTiles               ;if not, branch to alternate section of code
BHalf2:
    LD A, (Player_Y_Position)
    CP A, $08
    RET C
    CP A, $D0
    RET NC
    LD C, $18
    CALL BlockBufferColli_Side          ;do player-to-bg collision detection on other half of player
    RET Z
    ; FALL THROUGH

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
    LD A, (Player_State)                ;get player's state
    OR A                                ;check for player's state set to normal
    JP NZ, ImpedePlayerMove             ;if not, branch to impede player's movement
;
    LD A, (PlayerFacingDir)             ;get player's facing direction
    DEC A
    JP NZ, ImpedePlayerMove             ;if facing left, branch to impede movement
;
    LD A, (DE)                          ;(SMS) get metatile
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

.SECTION "AreaChangeTimerData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
AreaChangeTimerData:

    .IF PALBUILD == $00
    .db $a0, $34
    .ELSE
    .db $85, $2b                        ;PAL diff: Faster timer to accomodate FPS difference
    .ENDIF
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
    XOR A                               ;load blank metatile
    LD (DE), A                          ;store to remove old contents from block buffer
    LD HL, (Temp_Bytes + $06)           ;(SMS)put block buffer addr into HL for PutBlockMetatile
    JP RemoveCoin_Axe                   ;update the screen accordingly


;--------------------------------
;$02(IXL) - high nybble of vertical coordinate from block buffer
;$04(IXH) - low nybble of horizontal coordinate from block buffer
;$06-$07 - block buffer address

.SECTION "ClimbXPosAdder/ClimbPLocAdder" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
ClimbXPosAdder:
    .db $00 ; PADDING
    .db $f9, $07

ClimbPLocAdder:
    .db $ff, $00
.ENDS

.SECTION "FlagpoleYPosData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
FlagpoleYPosData:
    .db $18, $22, $50, $68, $90
.ENDS

HandleClimbing:
    LD A, IXH                           ;check low nybble of horizontal coordinate returned from
    CP A, $06                           ;collision detection routine against certain values, this
    RET C                               ;makes actual physical part of vine or flagpole thinner
    CP A, $0A                           ;than 16 pixels
    RET NC                              ;leave if too far left or too far right
;
    LD A, (DE)                          ;(SMS)get metatile id back from last call to BlockBufferColli_Side
    CP A, MT_FLAGPOLE_BALL              ;check climbing metatiles
    JP Z, FlagpoleCollision             ;branch if flagpole ball found
    CP A, MT_FLAGPOLE_SHAFT
    JP NZ, VineCollision                ;branch to alternate code if flagpole shaft not found

FlagpoleCollision:
    LD A, (GameEngineSubroutine)
    CP A, $05                           ;check for end-of-level routine running
    JP Z, PutPlayerOnVine               ;if running, branch to end of climbing code
;
    LD A, $01
    LD (PlayerFacingDir), A             ;set player's facing direction to right
    LD (ScrollLock), A
    LD A, (GameEngineSubroutine)
    CP A, $04                           ;check for flagpole slide routine running
    JP Z, RunFR                         ;if running, branch to end of flagpole code here
;
    LD C, OBJECTID_BulletBill_CannonVar ;load identifier for bullet bills (cannon variant)
    CALL KillEnemies                    ;get rid of them
;
    LD A, SNDID_SILENCE
    LD (MusicTrack0.SoundQueue), A      ; EVENT
    LD A, SNDID_FLAGPOLE                ;load flagpole sound
    LD (FlagpoleSoundQueue), A
;
    LD HL, FlagpoleYPosData + $04       ;start at end of vertical coordinate data
    LD A, (Player_Y_Position)
    LD (FlagpoleCollisionYPos), A       ;store player's vertical coordinate here to be used later
    LD B, $04
ChkFlagpoleYPosLoop:
    CP A, (HL)                          ;compare with current vertical coordinate data
    JP NC, MtchF                        ;if player's => current, branch to use current offset
    DEC L                               ;otherwise decrement offset to use
    DJNZ ChkFlagpoleYPosLoop            ;do this until all data is checked (use last one if all checked)      
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
;
    LD A, (Player_Y_Position)           ;check player's vertical coordinate
    CP A, $20                           ;for being in status bar area
    JP NC, PutPlayerOnVine              ;branch if not that far up
;
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
    CALL ChkJumpspringMetatiles         ;do sub to check if player landed on jumpspring
    RET NZ                              ;if carry not set, jumpspring not found, therefore leave
;
    LD A, $70
    LD (VerticalForce), A               ;otherwise set vertical movement force for player
;
    .IF PALBUILD == $00
    LD A, $F9                           ;set default jumpspring force
    .ELSE
    LD A, $F8                           ;PAL diff: Faster acceleration to accomodate FPS difference
    .ENDIF

    LD (JumpspringForce), A
;
    LD A, $03                           ;set jumpspring timer to be used later
    LD (JumpspringTimer), A
    LD A, $01                           ;set jumpspring animation control to start animating
    LD (JumpspringAnimCtrl), A
    RET

ChkJumpspringMetatiles:
    CP A, MT_SPRING_BLANK               ;check for top jumpspring metatile
    RET Z                               ;branch if found
    CP A, MT_SPRING_HALF                ;check for bottom jumpspring metatile
    RET

HandlePipeEntry:
    LD A, (Up_Down_Buttons)             ;check saved controller bits from earlier
    AND A, %00000100                    ;for pressing down
    RET Z                               ;if not pressing down, branch to leave
;
    LD A, (Temp_Bytes + $00)            ;check right foot metatile for warp pipe right metatile
    CP A, MT_WARPPIPE_TOP_RIGHT
    RET NZ                              ;branch to leave if not found
;
    LD A, (Temp_Bytes + $01)            ;check left foot metatile for warp pipe left metatile
    CP A, MT_WARPPIPE_TOP_LEFT
    RET NZ                              ;branch to leave if not found
;
    .IF PALBUILD == $00
    LD A, $30
    .ELSE
    LD A, $28                           ;PAL diff: Faster timer to accomodate FPS difference
    .ENDIF

    LD (ChangeAreaTimer), A             ;set timer for change of area
;
    LD A, $03
    LD (GameEngineSubroutine), A        ;set to run vertical pipe entry routine on next frame
;
    LD A, SNDID_PIPE
    LD (SFXTrack0.SoundQueue), A        ;load pipedown/injury sound
;
    ;LD A, %00100000
    ;LD (Player_SprAttrib), A
;
    LD A, (WarpZoneControl)             ;check warp zone control
    OR A
    RET Z                               ;branch to leave if none found
;
    AND A, %00000011                    ;mask out all but 2 LSB
    ADD A, A
    ADD A, A                            ;multiply by four
    ADD A, A
    LD HL, WarpZoneNumbers              ;save as offset to warp zone numbers (starts at left pipe)
    addAToHL8_M
    LD A, (Player_X_Position)           ;get player's horizontal position
    CP A, $60
    JP C, GetWNum                       ;if player at left, not near middle, use offset and skip ahead
    INC L                               ;otherwise increment for middle pipe
    INC L
    CP A, $A0
    JP C, GetWNum                       ;if player at middle, but not too far right, use offset and skip
    INC L                               ;otherwise increment for last pipe
    INC L
GetWNum:
    LD A, (HL)                          ;get warp zone numbers
    SUB A, BG_TILE_OFFSET + 1           ;decrement for use as world number
    LD (WorldNumber), A                 ;store as world number and offset
    ADD A, A
    LD HL, WorldAddrOffsets             ;get offset to where this world's area offsets are
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    LD A, (HL)                          ;get area offset based on world offset
    LD (AreaPointer), A                 ;store area offset here to be used to change areas
    LD A, SNDID_SILENCE                 ;silence music
    LD (MusicTrack0.SoundQueue), A      ;EVENT
    XOR A
    LD (EntrancePage), A                ;initialize starting page number
    LD (AreaNumber), A                  ;initialize area number used for area address offset
    LD (LevelNumber), A                 ;initialize level number used for world display
    LD (AltEntranceControl), A          ;initialize mode of entry
    INC A
    LD (Hidden1UpFlag), A               ;set flag for hidden 1-up blocks
    LD (FetchNewGameTimerFlag), A       ;set flag to load new game timer
    RET

ImpedePlayerMove:
    LD A, (Temp_Bytes + $00)            ;store $00 into B
    LD B, A
;
    LD C, $00                           ;initialize value here
    LD A, (Player_X_Speed)              ;get player's horizontal speed
    DEC B                               ;left side collision
    JP NZ, RImpd                        ;if right side collision, skip this part
    INC B                               ;return value to B
    OR A                                ;if player moving to the left,
    JP M, ExIPM                         ;branch to invert bit and leave
    DEC C                               ;otherwise load C with value to be used later
    JP NXSpd                            ;and jump to affect movement
RImpd:
    LD B, $02                           ;return $02 to B
    CP A, $01                           ;if player moving to the right,
    JP P, ExIPM                         ;branch to invert bit and leave
    INC C                               ;otherwise load C with value to be used here
NXSpd:
    LD A, $10                           ;set timer of some sort
    LD (SideCollisionTimer), A
    XOR A                               ;nullify player's horizontal speed
    LD (Player_X_Speed), A
    INC C                               ;if value set in C not set to $ff,
    DEC C
    JP P, PlatF                         ;branch ahead, do not decrement Y
    DEC A                               ;otherwise decrement A now
PlatF:
    LD E, A                             ;store A as high bits of horizontal adder                        
    LD A, C
    LD HL, Player_X_Position            ;add contents of A to player's horizontal
    ADD A, (HL)
    LD (HL), A                          ;position to move player left or right
    DEC L                               ;Player_PageLoc
    LD A, (HL)                          ;add high bits and carry to
    ADC A, E                            ;page location if necessary
    LD (HL), A
ExIPM:
    LD HL, Player_CollisionBits
    LD A, B                             ;invert contents of B
    CPL
    AND A, (HL)                         ;mask out bit that was set here
    LD (HL), A                          ;store to clear bit
    RET

;--------------------------------

.SECTION "SolidMTileUpperExt" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
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
    LD HL, SolidMTileUpperExt       ;use as offset for metatile data
    addAToHL8_M
    POP AF                          ;get original metatile value back
    CP A, (HL)                      ;compare current metatile with solid metatiles
    RET

.SECTION "ClimbMTileUpperExt" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
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
    LD HL, ClimbMTileUpperExt       ;use as offset for metatile data
    addAToHL8_M
    POP AF                          ;get original metatile value back
    CP A, (HL)                      ;compare current metatile with climbable metatiles
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

.SECTION "EnemyBGCStateData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
EnemyBGCStateData:
    .db $01, $01, $02, $02, $02, $05
.ENDS

; .SECTION "EnemyBGCXSpdData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
; EnemyBGCXSpdData:
;     .db $10, $f0
; .ENDS

EnemyToBGCollisionDet:
    LD L, <Enemy_State              ;check enemy state for d6 set*
    BIT 5, (HL)                     ;*actually check d5
    RET NZ                          ;if set, branch to leave
;
    ;SubtEnemyYPos
    LD L, <Enemy_Y_Position         ;add 62 pixels to enemy object's
    LD A, (HL)                      ;vertical coordinate
    ADD A, $3E
    CP A, $44                       ;compare against a certain range
    RET C                           ;if enemy vertical coord + 62 < 68, branch to leave
;
    LD L, <Enemy_ID                 ;if enemy object is not spiny, branch elsewhere
    LD A, (HL)
    CP A, OBJECTID_Spiny
    JP NZ, DoIDCheckBGColl
;
    LD B, A
    LD L, <Enemy_Y_Position         ;if enemy vertical coordinate < 36 branch to leave
    LD A, (HL)
    CP A, $25
    RET C
    LD A, B
    ; FALL THROUGH

DoIDCheckBGColl:
    CP A, OBJECTID_GreenParatroopaJump  ;check for some other enemy object
    JP Z, EnemyJump                 ;jump elsewhere if found
;
    CP A, OBJECTID_HammerBro        ;check for hammer bro
    JP Z, HammerBroBGColl           ;jump elsewhere if found
;
    CP A, OBJECTID_Spiny            ;if enemy object is spiny, branch
    JP Z, YesIn
    CP A, OBJECTID_PowerUpObject    ;if special power-up object, branch
    JP Z, YesIn
;
    CP A, $07                       ;if enemy object =>$07, branch to leave
    RET NC
;
YesIn:
    ChkUnderEnemy                   ;if enemy object < $07, or = $12 or $2e, do this sub
    JP Z, ChkForRedKoopa            ;if no block underneath enemy, skip and do something else

;--------------------------------
;$02(IXL) - vertical coordinate from block buffer routine

;HandleEToBGCollision:
    CALL ChkForNonSolids            ;if something is underneath enemy, find out what
    JP Z, ChkForRedKoopa            ;if blank $26, coins, or hidden blocks, jump, enemy falls through
;
    CP A, MT_HITBLANK
    JP NZ, LandEnemyProperly        ;check for blank metatile and branch if not found
;
    XOR A                           ;store default blank metatile in that spot so we won't
    LD (DE), A                      ;trigger this routine accidentally again
;
    LD L, <Enemy_ID                 ;if enemy object => $15, branch ahead
    LD A, (HL)
    CP A, $15
    JP NC, ChkToStunEnemies
;
    CP A, OBJECTID_Goomba           ;if enemy object IS goomba, do this sub
    CALL Z, KillEnemyAboveBlock

;GiveOEPoints:
    LD A, $01                       ;award 100 points for hitting block beneath enemy
    CALL SetupFloateyNumber
    ; FALL THROUGH

ChkToStunEnemies:
    CP A, $09                       ;perform many comparisons on enemy object identifier
    JP C, SetStun
    CP A, $11                       ;if the enemy object identifier is equal to the values
    JP NC, SetStun                  ;$09, $0e, $0f or $10, it will be modified, and not
    CP A, $0A                       ;modified if not any of those values, note that piranha plant will
    JP C, Demote                    ;always fail this test because A will still have vertical
    CP A, OBJECTID_PiranhaPlant     ;coordinate from previous addition, also these comparisons
    JP C, SetStun                   ;are only necessary if branching from $d7a1
Demote:
    AND A, %00000001                ;erase all but LSB, essentially turning enemy object
    LD L, <Enemy_ID                 ;into green or red koopa troopa to demote them
    LD (HL), A
SetStun:
    LD L, <Enemy_State              ;load enemy state
    LD A, (HL)
    AND A, %11110000                ;save high nybble
    OR A, %00000010
    LD (HL), A                      ;set d1 of enemy state
;
    LD L, <Enemy_Y_Position         ;subtract two pixels from enemy's vertical position
    LD A, (HL)
    SUB A, $02
    LD (HL), A
;
    LD L, <Enemy_ID                 ;check for bloober object
    LD A, (HL)
    CP A, OBJECTID_Bloober
    JP Z, SetWYSpd
    LD A, (AreaType)
    OR A
    LD A, $FD                       ;set default vertical speed
    JP NZ, SetNotW                  ;if area type not water, set as speed, otherwise
SetWYSpd:
    LD A, $FF                       ;change the vertical speed
SetNotW:
    LD L, <Enemy_Y_Speed            ;set vertical speed now
    LD (HL), A
;
    LD C, $01
    CALL PlayerEnemyDiff            ;get horizontal difference between player and enemy object
    LD B, $10                       ;EnemyBGCXSpdData
    JP P, ChkBBill                  ;branch if enemy is to the right of player
    LD B, $F0
    INC C                           ;increment Y if not
ChkBBill:
    LD L, <Enemy_ID
    LD A, (HL)
    CP A, OBJECTID_BulletBill_CannonVar ;check for bullet bill (cannon variant)
    JP Z, NoCDirF
    CP A, OBJECTID_BulletBill_FrenzyVar ;check for bullet bill (frenzy variant)
    JP Z, NoCDirF                   ;branch if either found, direction does not change
    LD L, <Enemy_MovingDir          ;store as moving direction
    LD (HL), C
NoCDirF:
    LD L, <Enemy_X_Speed            ;store proper horizontal speed
    LD (HL), B
    RET

;--------------------------------
;$04(IXH) - low nybble of vertical coordinate from block buffer routine

LandEnemyProperly:
    LD A, IXH                       ;check lower nybble of vertical coordinate saved earlier
    SUB A, $08                      ;subtract eight pixels
    CP A, $05                       ;used to determine whether enemy landed from falling
    JP NC, ChkForRedKoopa           ;branch if lower nybble in range of $0d-$0f before subtract
;
    LD L, <Enemy_State              ;branch if d6 in enemy state is set
    LD A, (HL)
    BIT 6, A
    JP NZ, LandEnemyInitState
    OR A
    JP M, DoEnemySideCheck          ;if lower nybble < $0d, d7 set but d6 not set, jump here

;ChkLandedEnemyState:
    JP Z, DoEnemySideCheck          ;if enemy in normal state, branch back to jump here
    CP A, $05                       ;if in state used by spiny's egg
    JP Z, ProcEnemyDirection        ;then branch elsewhere
    CP A, $03                       ;if already in state used by koopas and buzzy beetles
    RET NC                          ;or in higher numbered state, branch to leave
    CP A, $02                       ;if not in $02 state (used by koopas and buzzy beetles)
    JP NZ, ProcEnemyDirection       ;then branch elsewhere
;
    LD A, H
    SUB A, $C1
    LD BC, EnemyIntervalTimer
    addAToBC8_M
    LD L, <Enemy_ID                 ;check enemy identifier for spiny
    LD A, (HL)
    CP A, OBJECTID_Spiny
    LD A, $10                       ;load default timer here
    JP NZ, SetForStn                ;branch if not found
    XOR A                           ;set timer for $00 if spiny
SetForStn:
    LD (BC), A                      ;set timer here
;
    LD L, <Enemy_State              ;set state here, apparently used to render
    LD (HL), $03                    ;upside-down koopas and buzzy beetles
    JP EnemyLanding                 ;then land it properly

ProcEnemyDirection:
    LD L, <Enemy_ID                 ;check enemy identifier for goomba
    LD A, (HL)
    CP A, OBJECTID_Goomba
    JP Z, LandEnemyInitState        ;branch if found
    CP A, OBJECTID_Spiny            ;check for spiny
    JP NZ, InvtD                    ;branch if not found
;
    LD L, <Enemy_MovingDir          ;send enemy moving to the right by default
    LD (HL), $01
    LD L, <Enemy_X_Speed            ;set horizontal speed accordingly
    LD (HL), $08
    LD A, (FrameCounter)
    AND A, %00000111                ;if timed appropriately, spiny will skip over
    JP Z, LandEnemyInitState        ;trying to face the player
    ; FALL THROUGH

InvtD:
    LD C, $01                       ;load 1 for enemy to face the left (inverted here)
    CALL PlayerEnemyDiff            ;get horizontal difference between player and enemy
    JP P, CNwCDir                   ;if enemy to the right of player, branch
    INC C                           ;if to the left, increment by one for enemy to face right (inverted)
CNwCDir:
    LD A, C
    LD L, <Enemy_MovingDir          ;compare direction in A with current direction in memory
    CP A, (HL)
    CALL Z, ChkForBump_HammerBroJ   ;if equal, not facing in correct dir, do sub to turn around
    ; FALL THROUGH

LandEnemyInitState:
    CALL EnemyLanding               ;land enemy properly
;
    LD L, <Enemy_State              ;if d7 of enemy state is set, branch
    LD A, (HL)
    OR A
    JP M, NMovShellFallBit
    LD (HL), $00                    ;otherwise initialize enemy state and leave
    RET                             ;note this will also turn spiny's egg into spiny

NMovShellFallBit:
    RES 6, (HL)                     ;nullify d6 of enemy state
    RET

;--------------------------------

ChkForRedKoopa:
    LD L, <Enemy_ID                 ;check for red koopa troopa $03
    LD A, (HL)
    CP A, OBJECTID_RedKoopa
    LD L, <Enemy_State
    LD A, (HL)
    JP NZ, Chk2MSBSt                ;branch if not found
;
    OR A
    JP Z, ChkForBump_HammerBroJ     ;if enemy found and in normal state, branch
    ; FALL THROUGH
;
Chk2MSBSt:
    OR A                            ;check for d7 set
    JP P, GetSteFromD               ;branch if not set
    SET 6, A                        ;set d6
    JP SetD6Ste                     ;jump ahead of this part
GetSteFromD:
    LD BC, EnemyBGCStateData        ;load new enemy state with old as offset
    addAToBC8_M
    LD A, (BC)
SetD6Ste:
    LD (HL), A                      ;set as new state
    ; FALL THROUGH

;--------------------------------
;$00 - used to store bitmask (not used but initialized here)
;$eb(IYH) - used in DoEnemySideCheck as counter and to compare moving directions

; Was a loop that checked both directions (redundant because enemy can only face 1)
DoEnemySideCheck:
    LD L, <Enemy_Y_Position         ;if enemy within status bar, branch to leave
    LD A, (HL)                      ;because there's nothing there that impedes movement
    CP A, $20
    RET C
;
    LD BC, $0014                    ;start by finding block to the left of enemy ($00,$14)
    LD L, <Enemy_MovingDir          ;check if enemy is moving left
    LD A, (HL)
    DEC A
    JP NZ, RightChk                 ;if so, jump
    LD B, $10                       ;else, find block to the right of the enemy ($10,$14)
RightChk:
    CALL BlockBufferCollision_A1    ;find block to left or right of enemy object
    RET Z                           ;if nothing found, branch
    CALL ChkForNonSolids            ;check for non-solid blocks
    RET Z                           ;branch if not found
    ; FALL THROUGH

ChkForBump_HammerBroJ:
    LD A, H                         ;check if we're on the special use slot
    CP A, $C6
    JP Z, NoBump                    ;and if so, branch ahead and do not play sound
;
    LD L, <Enemy_State              ;if enemy state d7 not set, branch
    LD A, (HL)                      ;ahead and do not play sound
    ADD A, A
    JP NC, NoBump
    LD A, SNDID_BUMP                ;otherwise, play bump sound
    LD (SFXTrack0.SoundQueue), A 
NoBump:
    LD L, <Enemy_ID                 ;check for hammer bro
    LD A, (HL)
    CP A, $05
    JP NZ, RXSpd                    ;branch if not found
    
    LD A, H                         ;store pseudo random address in BC
    SUB A, $C1
    LD BC, PseudoRandomBitReg+1
    addAToBC8_M
    LD DE, $00FA                    ;load default vertical speed for jumping
    JP SetHJ                        ;jump to code that makes hammer bro jump

;--------------------------------
;$00 - used to hold horizontal difference between player and enemy

PlayerEnemyDiff:
    EX DE, HL                       ; DE = ENEMY, HL = PLAYER
    LD HL, Player_X_Position
    LD E, L
    LD A, (DE)                      ;get distance between enemy object's
    SUB A, (HL)                     ;horizontal coordinate and the player's
    LD (Temp_Bytes + $00), A        ;and store here
    DEC L                           ;Enemy_PageLoc
    DEC E
    LD A, (DE)
    SBC A, (HL)                     ;subtract borrow, then leave
    EX DE, HL                       ; DE = PLAYER, HL = ENEMY
    RET

;--------------------------------

EnemyLanding:
    CALL InitVStf                   ;do something here to vertical speed and something else
    LD L, <Enemy_Y_Position
    LD A, (HL)
    AND A, %11110000                ;save high nybble of vertical coordinate, and
    OR A, %00001000                 ;set d3, then store, probably used to set enemy object
    LD (HL), A                      ;neatly on whatever it's landing on
    RET

EnemyJump:
;SubtEnemyYPos:
    LD L, <Enemy_Y_Position         ;add 62 pixels to enemy object's
    LD A, (HL)                      ;vertical coordinate
    ADD A, $3E
    CP A, $44                       ;compare against a certain range

    JP C, DoEnemySideCheck          ;if enemy vertical coord + 62 < 68, branch to leave
;
    LD L, <Enemy_Y_Speed            ;add two to vertical speed
    LD A, (HL)
    ADD A, $02
    CP A, $03                       ;if green paratroopa not falling, branch ahead
    JP C, DoEnemySideCheck
;
    ChkUnderEnemy                   ;otherwise, check to see if green paratroopa is
    JP Z, DoEnemySideCheck          ;standing on anything, then branch to same place if not
;
    CALL ChkForNonSolids            ;check for non-solid blocks
    JP Z, DoEnemySideCheck          ;branch if found
;
    CALL EnemyLanding               ;change vertical coordinate and speed
    LD L, <Enemy_Y_Speed            ;make the paratroopa jump again
    LD (HL), $FD
    JP DoEnemySideCheck             ;check for horizontal blockage, then leave

;--------------------------------

HammerBroBGColl:
    ChkUnderEnemy                   ;check to see if hammer bro is standing on anything
    JP Z, NoUnderHammerBro
    CP A, MT_HITBLANK               ;check for blank metatile $23 and branch if not found
    JP NZ, UnderHammerBro
    ; FALL THROUGH

KillEnemyAboveBlock:
    CALL ShellOrBlockDefeat         ;do this sub to kill enemy
    LD L, <Enemy_Y_Speed            ;alter vertical speed of enemy and leave
    LD (HL), $FC
    RET

UnderHammerBro:
    LD A, H                         ;check timer used by hammer bro
    SUB A, $C1
    LD BC, EnemyFrameTimer
    addAToBC8_M
    LD A, (BC)
    OR A
    JP NZ, NoUnderHammerBro         ;branch if not expired
;
    LD L, <Enemy_State              ;save d7 and d3 from enemy state, nullify other bits
    LD A, (HL)
    AND A, %10001000
    LD (HL), A                      ;and store
;
    CALL EnemyLanding               ;modify vertical coordinate, speed and something else
    JP DoEnemySideCheck             ;then check for horizontal blockage and leave

NoUnderHammerBro:
    LD L, <Enemy_State              ;if hammer bro is not standing on anything, set d0
    SET 0, (HL)                     ;in the enemy state to indicate jumping or falling, then leave
    RET

; ChkUnderEnemy:
;     XOR A
;     LD C, $15
;     JP BlockBufferChk_Enemy

ChkForNonSolids:
    CP A, MT_VINEBLANK              ;blank metatile used for vines?
    RET Z
    CP A, MT_COIN                   ;regular coin?
    RET Z
    CP A, MT_WATERCOIN              ;underwater coin?
    RET Z
    CP A, MT_HIDDENBLK_COIN         ;hidden coin block?
    RET Z
    CP A, MT_HIDDENBLK_1UP          ;hidden 1-up block?
    RET
    
;-------------------------------------------------------------------------------------

FireballBGCollision:
    LD L, <Fireball_Y_Position              ;check fireball's vertical coordinate
    LD A, (HL)
    CP A, $18
    JP C, ClearBounceFlag                   ;if within the status bar area of the screen, branch ahead
;
    ; BlockBufferChk_FBall
    LD BC, $0408 ;LD C, $1A
    ;XOR A
    ;CALL BlockBufferCollision               ;do fireball to background collision detection on bottom of it
    CALL BlockBufferCollision_A0
    JP Z, ClearBounceFlag                   ;if nothing underneath fireball, branch
;
    CALL ChkForNonSolids                    ;check for non-solid metatiles
    JP Z, ClearBounceFlag                   ;branch if any found
;
    LD L, <Fireball_Y_Speed                 ;if fireball's vertical speed set to move upwards,
    LD A, (HL)
    OR A
    JP M, InitFireballExplode               ;branch to set exploding bit in fireball's state
;
    LD L, <FireballBouncingFlag             ;if bouncing flag already set,
    LD A, (HL)
    OR A
    JP NZ, InitFireballExplode              ;branch to set exploding bit in fireball's state
;
    LD L, <Fireball_Y_Speed                 ;otherwise set vertical speed to move upwards (give it bounce)
    LD (HL), $FD
    LD L, <FireballBouncingFlag             ;set bouncing flag
    LD (HL), $01
    LD L, <Fireball_Y_Position              ;modify vertical coordinate to land it properly
    LD A, (HL)
    AND A, %11111000
    LD (HL), A                              ;store as new vertical coordinate
    RET

ClearBounceFlag:
    LD L, <FireballBouncingFlag             ;clear bouncing flag by default
    LD (HL), $00
    RET

InitFireballExplode:
    LD L, <Fireball_State                   ;set exploding flag in fireball's state
    LD (HL), $80
    LD A, SNDID_BUMP                        ;load bump sound
    LD (SFXTrack0.SoundQueue), A
    RET

;-------------------------------------------------------------------------------------
;$00(B) - used to hold one of bitmasks, or offset
;D - used to store middle screen page location
;C - also used to store middle screen coordinate

;this data added to relative coordinates of sprite objects
;stored in order: left edge, top edge, right edge, bottom edge
.SECTION "BoundBoxCtrlData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
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

    .IF PALBUILD == $00
    .db $03, $0e, $0d, $14
    .ELSE
    .db $03, $0c, $0d, $14                  ;PAL diff: some enemies (Piranha, Bullet Bill, Goomba, Spiny, Blooper, Cheep Cheep) has larger hitbox
    .ENDIF

    .db $00, $02, $10, $15
    .db $04, $04, $0c, $1c
.ENDS

GetFireballBoundBox:
    LD DE, Fireball_Rel_YPos                ;set offset for relative coordinates
    CALL BoundingBoxCore                    ;get bounding box coordinates
    JP CheckRightScreenBBox                 ;jump to handle any offscreen coordinates

GetMiscBoundBox:
    LD DE, Misc_Rel_YPos                    ;set offset for relative coordinates
    CALL BoundingBoxCore                    ;get bounding box coordinates
    JP CheckRightScreenBBox                 ;jump to handle any offscreen coordinates

SmallPlatformBoundBox:
    LD BC, $0804                            ;store two bitmasks
    JP GetMaskedOffScrBits

GetEnemyBoundBox:
    LD BC, $4844                            ;store two bitmasks
    ; FALL THROUGH

GetMaskedOffScrBits:
    LD A, (ScreenLeft_X_Pos)
    LD E, A
    LD L, <Enemy_X_Position                 ;get enemy object position relative
    LD A, (HL)                              ;to the left side of the screen
    SUB A, E
    LD D, A                                 ;store here
;
    LD A, (ScreenLeft_PageLoc)              ;subtract borrow from current page location
    LD E, A
    LD L, <Enemy_PageLoc                    ;of left side
    LD A, (HL)
    SBC A, E
    JP M, CMBits                            ;if enemy object is beyond left edge, branch
;
    OR A, D
    JP Z, CMBits                            ;if precisely at the left edge, branch
    LD C, B                                 ;if to the right of left edge, use value in $00 for A
CMBits:
    LD A, (Enemy_OffscrBits)                ;otherwise use contents of C
    AND A, C
    LD L, <EnemyOffscrBitsMasked            ;preserve bitwise whatever's in here
    LD (HL), A                              ;save masked offscreen bits here
    JP NZ, MoveBoundBoxOffscreen            ;if anything set here, branch
    ; FALL THROUGH

SetupEOffsetFBBox:
    LD DE, Enemy_Rel_YPos                   ;set offset for relative coordinates
    CALL BoundingBoxCore                    ;do a sub to get the coordinates of the bounding box
    JP CheckRightScreenBBox                 ;jump to handle offscreen coordinates of bounding box

LargePlatformBoundBox:
    CALL GetXOffscreenBits                  ;jump directly to the sub for horizontal offscreen bits
    CP A, $FE                               ;if completely offscreen, branch to put entire bounding
    JP C, SetupEOffsetFBBox                 ;box offscreen, otherwise start getting coordinates
    ; FALL THROUGH

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

;   HL - OBJECT OFFSET
;   DE - REL POS OFFSET/BoundBoxCtrlData
;C - used for relative X coordinate
;B - used for relative Y coordinate
BoundingBoxCore:
    LD A, (DE)                              ;store object coordinates relative to screen
    LD B, A                                 ;vertically and horizontally in BC, respectively
;
    DEC E                                   ;<SprObject_Rel_XPos
    LD A, (DE)
    LD C, A
;
    LD L, <SprObj_BoundBoxCtrl              ;load value here to be used as offset for X
    LD A, (HL)                              ;multiply that by four and use as offset
    ADD A, A
    ADD A, A
    LD DE, BoundBoxCtrlData
    addAToDE8_M
    LD A, (DE)
    ADD A, C
    INC L                                   ;<BoundingBox_UL_Corner
    LD (HL), A
;
    INC E
    LD A, (DE)
    ADD A, B
    INC L                                   ;<BoundingBox_UL_Corner + $01
    LD (HL), A
;
    INC E
    LD A, (DE)
    ADD A, C
    INC L                                   ;<BoundingBox_LR_Corner
    LD (HL), A
;
    INC E
    LD A, (DE)
    ADD A, B
    INC L                                   ;<BoundingBox_LR_Corner + $01
    LD (HL), A
    RET

;   BC - SCREENLEFT_XPOS_ADJ/SCREENLEFT_PAGELOC_ADJ
CheckRightScreenBBox:
    LD A, (ScreenLeft_X_Pos)                ;add 128 pixels to left side of screen
    ADD A, $80                              ;and store as horizontal coordinate of middle
    LD B, A
;
    LD A, (ScreenLeft_PageLoc)              ;add carry to page location of left side of screen
    ADC A, $00                              ;and store as page location of middle
    LD C, A
;
    LD L, <SprObject_X_Position             ;get horizontal coordinate
    LD A, (HL)
    CP A, B                                 ;compare against middle horizontal coordinate
    DEC L                                   ;<SprObject_PageLoc
    LD A, (HL)                              ;get page location
    SBC A, C                                ;subtract from middle page location
    JP C, CheckLeftScreenBBox               ;if object is on the left side of the screen, branch
;
    LD L, <BoundingBox_DR_XPos              ;check right-side edge of bounding box for offscreen
    LD A, (HL)
    OR A
    RET M                                   ;coordinates, branch if still on the screen
    LD L, <BoundingBox_UL_XPos              ;check left-side edge of bounding box for offscreen
    LD A, (HL)
    OR A
    LD A, $FF                               ;load offscreen value here to use on one or both horizontal sides
    JP M, SORte
    LD (HL), A                              ;store offscreen value for left side
SORte:
    LD L, <BoundingBox_DR_XPos              ;store offscreen value for right side
    LD (HL), A
    RET

CheckLeftScreenBBox:
    LD L, <BoundingBox_UL_XPos              ;check left-side edge of bounding box for offscreen
    LD A, (HL)
    OR A
    RET P                                   ;coordinates, and branch if still on the screen
;
    CP A, $A0                               ;check to see if left-side edge is in the middle of the
    RET C                                   ;screen or really offscreen, and branch if still on
;
    LD L, <BoundingBox_DR_XPos              ;check right-side edge of bounding box for offscreen
    LD A, (HL)
    OR A
    LD A, $00
    JP P, SOLft                             ;coordinates, branch if still onscreen
    LD (HL), A                              ;store offscreen value for right side
SOLft:
    LD L, <BoundingBox_UL_XPos              ;store offscreen value for left side
    LD (HL), A
    RET

;-------------------------------------------------------------------------------------
;$06(STACK) - second object's offset
;$07(B) - counter

PlayerCollisionCore:
    LD H, >Player_Y_Position                      ;initialize X to use player's bounding box for comparison

SprObjectCollisionCore:
    LD B, $02                                   ;save as counter, compare horizontal coordinates first

    ;BoundingBox_UL_Corner: [$00] 1ST LOOP
    ;BoundingBox_UL_YPos:   [$01] 2ND LOOP
    ;BoundingBox_LR_Corner: [$02] 1ST LOOP
    ;BoundingBox_DR_YPos:   [$03] 2ND LOOP
    LD E, <BoundingBox_UL_Corner                ;(SMS)offsets for first loop
    LD L, E

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
    ; FALL THROUGH

NoCollisionFound:
    OR A                                        ;clear carry, then load value set earlier, then leave
    RET                                         ;not bother checking vertical ones, because what's the point?

CollisionFound:
    LD E, <BoundingBox_UL_Corner + $01          ;increment offsets on both objects to check
    LD L, E                                     ;the vertical coordinates
    DJNZ CollisionCoreLoop                      ;decrement counter to reflect this and if counter not expired, branch to loop
    SCF                                         ;otherwise we already did both sets, therefore collision, so set carry
    RET

;-------------------------------------------------------------------------------------
;$02(IXL) - modified y coordinate
;$03(NOT USED) - stores metatile involved in block buffer collisions
;$04(IXH) - comes in with offset to block buffer adder data, goes out with low nybble x/y coordinate
;$05(IYL) - modified x coordinate
;$06-$07(DE) - block buffer address

; .SECTION "BlockBuffer_X_Adder" BANK BANK_SLOT2 SLOT 2 FREE ALIGN 256
; BlockBuffer_X_Adder:
;     .db $08, $03, $0c, $02, $02, $0d, $0d, $08  ; $07
;     .db $03, $0c, $02, $02, $0d, $0d, $08, $03  ; $0F
;     .db $0c, $02, $02, $0d, $0d, $08, $00, $10  ; $17
;     .db $04, $14, $04, $04                      ; $1B
; .ENDS

; .SECTION "BlockBuffer_Y_Adder" BANK BANK_SLOT2 SLOT 2 FREE ALIGN 256
; BlockBuffer_Y_Adder:
;     .db $04, $20, $20, $08, $18, $08, $18, $02
;     .db $20, $20, $08, $18, $08, $18, $12, $20
;     .db $20, $18, $18, $18, $18, $18, $14, $14
;     .db $06, $06, $08, $10
; .ENDS

;BlockBufferChk_Enemy:
;    JP BlockBufferCollision

; BlockBufferChk_FBall:
;     LD C, $1A 
;     XOR A
;     JP BlockBufferCollision
    ;ldx ObjectOffset

; BlockBufferColli_Feet:
;     INC C

; BlockBufferColli_Head:
;     XOR A
;     JP BlockBufferColli_Side@SetPlayerOffset

; BlockBufferColli_Side:
;     LD A, $01
; @SetPlayerOffset:
;     LD H, >Player_Y_Position

;   BC - BlockBuffer_X_Adder/BlockBuffer_Y_Adder (INPUT)
;   HL - OBJECT OFFSET (INPUT)
;   DE - BLOCK BUFFER ADDRESS
BlockBufferCollision_A0:
    LD A, B                             ;add horizontal coordinate
    LD L, <SprObject_X_Position         ;of object to x adder
    ADD A, (HL)
    LD E, A                             ;store here
;
    DEC L                               ;<SprObject_PageLoc
    LD A, (HL)
    ADC A, $00                          ;add carry to page location
    AND A, $01
    ADD A, >BlockBufferLUT
    LD D, A
    LD A, (DE)
    LD E, A
    LD D, >Block_Buffer_1
    LD (Temp_Bytes + $06), DE
;
    LD A, C
    LD L, <SprObject_Y_Position         ;get vertical coordinate of object
    ADD A, (HL)                         ;add it to y adder
    AND A, %11110000                    ;mask out low nybble
    SUB A, $20                          ;subtract 32 pixels for the status bar
    LD IXL, A                           ;store result here
;
    addAToDE_M
;
    LD A, (HL)                          ;load vertical coordinate
    AND A, %00001111                    ;and mask out high nybble
    LD IXH, A                           ;store masked out result here
    LD A, (DE)                          ;get content of block buffer
    OR A
    RET

BlockBufferColli_Side:
    LD H, >Player_Y_Position
BlockBufferCollision_A1:
    LD L, <SprObject_X_Position
    LD A, (HL)                          ;load horizontal coordinate
    AND A, %00001111                    ;and mask out high nybble
    LD IXH, A                           ;store masked out result here
;
    LD A, B                             ;add horizontal coordinate
    ADD A, (HL)                         ;of object to x adder
    LD E, A                             ;store here
;
    DEC L                               ;<SprObject_PageLoc
    LD A, (HL)
    ADC A, $00                          ;add carry to page location
    AND A, $01
    ADD A, >BlockBufferLUT
    LD D, A
    LD A, (DE)
    LD E, A
    LD D, >Block_Buffer_1
    LD (Temp_Bytes + $06), DE
;
    LD A, C
    LD L, <SprObject_Y_Position         ;get vertical coordinate of object
    ADD A, (HL)                         ;add it to y adder
    AND A, %11110000                    ;mask out low nybble
    SUB A, $20                          ;subtract 32 pixels for the status bar
    LD IXL, A                           ;store result here
;
    addAToDE_M
;
    LD A, (DE)                          ;get content of block buffer
    OR A
    RET


.SECTION "Block Buffer LUT" BANK BANK_SLOT2 SLOT 2 FREE ALIGN 256 RETURNORG
BlockBufferLUT:
    .DEFINE lbyte <Block_Buffer_1
    .REPT $10
    .db lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte
    .REDEFINE lbyte lbyte+1
    .ENDR

    .REDEFINE lbyte <Block_Buffer_2
    .REPT $10
    .db lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte, lbyte
    .REDEFINE lbyte lbyte+1
    .ENDR

    .UNDEFINE lbyte
.ENDS

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


;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;-------------------------------------------------------------------------------------
;$00 (N/A) - used in adding to get proper offset

; RelativePlayerPosition:
;     LD H, >Player_Rel_XPos
;     LD D, H
;     JP GetObjRelativePosition

; RelativeBubblePosition:
;     LD D, >Bubble_Rel_XPos
;     JP GetObjRelativePosition

; RelativeFireballPosition:
;     LD D, >Fireball_Rel_XPos
;     JP GetObjRelativePosition

; RelativeMiscPosition:
;     LD D, >Misc_Rel_XPos
;     JP GetObjRelativePosition

RelativeBlockPosition:
    LD DE, Block_Rel_YPos
    CALL GetObjRelativePosition
;
    INC H
    INC H
    INC D
    INC E
    CALL GetObjRelativePosition
    DEC H
    DEC H
    RET

RelativeEnemyPosition:
    LD DE, Enemy_Rel_YPos

;   HL - OBJECT OFFSET
;   DE - XXX_Rel_YPos OFFSET
GetObjRelativePosition:
    LD L, <SprObject_Y_Position
    LD A, (HL)                              ;load vertical coordinate low
    LD (DE), A                              ;store here
;
    LD L, <SprObject_X_Position
    DEC E                                   ;<SprObject_Rel_XPos
    LD A, (ScreenLeft_X_Pos)
    LD C, A
    LD A, (HL)                              ;load horizontal coordinate
    SUB A, C                                ;subtract left edge coordinate
    LD (DE), A                              ;store result here
    RET

;-------------------------------------------------------------------------------------
;$00 (IXL) - used as temp variable to hold offscreen bits

; GetPlayerOffscreenBits:
;     LD H, >Player_OffscrBits
;     LD D, H
;     JP GetOffScreenBitsSet

; GetFireballOffscreenBits:
;     LD D, >Fireball_OffscrBits
;     JP GetOffScreenBitsSet

; GetBubbleOffscreenBits:
;     LD D, >Bubble_OffscrBits
;     JP GetOffScreenBitsSet

; GetMiscOffscreenBits:
;     LD D, >Misc_OffscrBits
;     JP GetOffScreenBitsSet

; GetEnemyOffscreenBits:
;     LD D, >Enemy_OffscrBits
;     JP GetOffScreenBitsSet

; GetBlockOffscreenBits:
;     LD D, >Block_OffscrBits

GetEnemyOffscreenBits:
    LD BC, Enemy_OffscrBits
    ; FALL THROUGH

;   HL - OBJECT OFFSET
;   BC - OffscreenBits OFFSET
;   DE - XOffscreenBitsData/YOffscreenBitsData
GetOffScreenBitsSet:
    ;CALL GetXOffscreenBits                  ;do subroutine here
;   --- GetXOffscreenBits INLINE ---
    ; LOOP 1 (RIGHT SIDE CHECK)
    LD L, <SprObject_X_Position
    LD A, (ScreenEdge_X_Pos + $01)          ;get pixel coordinate of edge
    SUB A, (HL)                             ;get difference between pixel coordinate of edge
    LD E, A                                 ;store here
    DEC L                                   ;<SprObject_PageLoc
    LD A, (ScreenEdge_PageLoc + $01)        ;get page location of edge
    SBC A, (HL)                             ;subtract from page location of object position
    ;
    LD A, $0F                               ;load offset value here
    JP M, XLdBData_INLINE                   ;if beyond right edge or in front of left edge, branch
    LD A, $07
    JP NZ, XLdBData_INLINE                  ;if one page or more to the left of either edge, branch
    ; DividePDiff
    LD A, E
    CP A, $38
    LD A, $07
    JP NC, XLdBData_INLINE
    LD A, E
    RRCA
    RRCA
    RRCA
    AND A, $07
XLdBData_INLINE:
    LD DE, XOffscreenBitsData
    addAToDE8_M
    LD A, (DE)                              ;get bits here
    OR A                                    ;if bits not zero, branch to leave
    JP NZ, XOffscrnRet
    ; LOOP 2 (LEFT SIDE CHECK)
    INC L                                   ;<SprObject_X_Position
    LD A, (ScreenEdge_X_Pos)
    SUB A, (HL)
    LD E, A
    DEC L                                   ;<SprObject_PageLoc
    LD A, (ScreenEdge_PageLoc)
    SBC A, (HL)
    ;
    LD A, $07
    JP M, XLdBData_2_INLINE
    LD A, $0F
    JP NZ, XLdBData_2_INLINE
    LD A, E
    CP A, $38
    LD A, $0F
    JP NC, XLdBData_2_INLINE
    LD A, E
    RRCA
    RRCA
    RRCA
    AND A, $07
    ADD A, $08
XLdBData_2_INLINE:
    LD E, <XOffscreenBitsData
    addAToDE8_M
    LD A, (DE)
;
XOffscrnRet:
    RRCA                                    ;move high nybble to low
    RRCA
    RRCA
    RRCA
    AND A, $0F
    LD IXL, A                               ;store here
    ;CALL GetYOffscreenBits
;   --- GetYOffscreenBits INLINE ---
    ; LOOP 1 (TOP SIDE CHECK) LIMIT AT $0100
    LD L, <SprObject_Y_Position
    LD A, $00
    SUB A, (HL)
    LD E, A
    INC L                               ;<SprObject_Y_HighPos
    LD A, $01
    SBC A, (HL)
    ;
    LD A, $00
    JP M, YLdBData
    LD A, $04
    JP NZ, YLdBData
    ; DividePDiff
    LD A, E
    CP A, $20
    LD A, $04
    JP NC, YLdBData
    LD A, E
    RRCA
    RRCA
    RRCA
    AND A, $07
YLdBData:
    LD E, <YOffscreenBitsData
    addAToDE8_M
    LD A, (DE)
    OR A
    JP NZ, YOffscrnRet
    ; LOOP 2 (BOTTOM SIDE CHECK) LIMIT AT $01FF
    DEC L                               ;<SprObject_Y_Position
    LD A, $FF
    SUB A, (HL)
    LD E, A
    INC L                               ;<SprObject_Y_HighPos
    LD A, $01
    SBC A, (HL)
    ;
    LD A, $04
    JP M, YLdBData_2
    LD A, $00
    JP NZ, YLdBData_2
    ; DividePDiff_2
    LD A, E
    CP A, $20
    LD A, $00
    JP NC, YLdBData_2
    LD A, E
    RRCA
    RRCA
    RRCA
    AND A, $07
    ADD A, $04
YLdBData_2:
    LD E, <YOffscreenBitsData
    addAToDE8_M
    LD A, (DE)
;
YOffscrnRet:
    ADD A, A                                ;move low nybble to high nybble
    ADD A, A
    ADD A, A
    ADD A, A
    OR A, IXL                               ;mask together with previously saved low nybble
    LD (BC), A
    ;LD HL, (ObjectOffset)
    RET

;--------------------------------
;(these apply to these three subsections)
;$04 (N/A) - used to store proper offset
;$05 (N/A) - used as adder in DividePDiff
;$06 (N/A) - used to store preset value used to compare to pixel difference in $07
;$07 (E) - used to store difference between coordinates of object and screen edges

.SECTION "XOffscreenBitsData, YOffscreenBitsData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
XOffscreenBitsData:
    ; $00
    .db $7f, $3f, $1f, $0f, $07, $03, $01, $00
    ; $08
    .db $80, $c0, $e0, $f0, $f8, $fc, $fe, $ff

YOffscreenBitsData:
    ; $00
    .db $00, $08, $0c, $0e
    ; $04
    .db $0f, $07, $03, $01
    ; $08
    .db $00
.ENDS

GetXOffscreenBits:
;   LOOP 1 (RIGHT SIDE CHECK)
    LD L, <SprObject_X_Position
    LD A, (ScreenEdge_X_Pos + $01)          ;get pixel coordinate of edge
    SUB A, (HL)                             ;get difference between pixel coordinate of edge
    LD E, A                                 ;store here
    DEC L                                   ;<SprObject_PageLoc
    LD A, (ScreenEdge_PageLoc + $01)        ;get page location of edge
    SBC A, (HL)                             ;subtract from page location of object position
;
    LD A, $0F                               ;load offset value here
    JP M, XLdBData                          ;if beyond right edge or in front of left edge, branch
    LD A, $07
    JP NZ, XLdBData                         ;if one page or more to the left of either edge, branch
    ; DividePDiff
    LD A, E
    CP A, $38
    LD A, $07
    JP NC, XLdBData
    LD A, E
    RRCA
    RRCA
    RRCA
    AND A, $07
XLdBData:
    LD DE, XOffscreenBitsData
    addAToDE8_M
    LD A, (DE)                              ;get bits here
    OR A                                    ;if bits not zero, branch to leave
    RET NZ
;   LOOP 2 (LEFT SIDE CHECK)
    INC L                                   ;<SprObject_X_Position
    LD A, (ScreenEdge_X_Pos)
    SUB A, (HL)
    LD E, A
    DEC L                                   ;<SprObject_PageLoc
    LD A, (ScreenEdge_PageLoc)
    SBC A, (HL)
;
    LD A, $07
    JP M, XLdBData_2
    LD A, $0F
    JP NZ, XLdBData_2
    LD A, E
    CP A, $38
    LD A, $0F
    JP NC, XLdBData_2
    LD A, E
    RRCA
    RRCA
    RRCA
    AND A, $07
    ADD A, $08
XLdBData_2:
    LD E, <XOffscreenBitsData
    addAToDE8_M
    LD A, (DE)
    RET

;--------------------------------

;GetYOffscreenBits:
; ;   LOOP 1 (TOP SIDE CHECK) LIMIT AT $0100
;     LD L, <SprObject_Y_Position
;     LD A, $00
;     SUB A, (HL)
;     LD E, A
;     INC L                               ;<SprObject_Y_HighPos
;     LD A, $01
;     SBC A, (HL)
; ;
;     LD A, $00
;     JP M, YLdBData
;     LD A, $04
;     JP NZ, YLdBData
;     ; DividePDiff
;     LD A, E
;     CP A, $20
;     LD A, $04
;     JP NC, YLdBData
;     LD A, E
;     RRCA
;     RRCA
;     RRCA
;     AND A, $07
; YLdBData:
;     LD E, <YOffscreenBitsData
;     addAToDE8_M
;     LD A, (DE)
;     OR A
;     RET NZ
; ;   LOOP 2 (BOTTOM SIDE CHECK) LIMIT AT $01FF
;     DEC L                               ;<SprObject_Y_Position
;     LD A, $FF
;     SUB A, (HL)
;     LD E, A
;     INC L                               ;<SprObject_Y_HighPos
;     LD A, $01
;     SBC A, (HL)
; ;
;     LD A, $04
;     JP M, YLdBData_2
;     LD A, $00
;     JP NZ, YLdBData_2
;     ; DividePDiff_2
;     LD A, E
;     CP A, $20
;     LD A, $00
;     JP NC, YLdBData_2
;     LD A, E
;     RRCA
;     RRCA
;     RRCA
;     AND A, $07
;     ADD A, $04
; YLdBData_2:
;     LD E, <YOffscreenBitsData
;     addAToDE8_M
;     LD A, (DE)
;     RET

;--------------------------------
