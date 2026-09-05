;-------------------------------------------------------------------------------------

TitleScreenMode:
    LD A, (OperMode_Task)
    RST JumpEngine

    .dw InitializeGame
    .dw ScreenRoutines
    .dw PrimaryGameSetup
    .dw GameMenuRoutine

;-------------------------------------------------------------------------------------

InitializeGame:
    LD HL, InitGameOffset           ;clear all memory as in initialization procedure...
    LD A, (TitleLoadedFlag)         ;only do this on initial load
    OR A
    CALL Z, InitializeMemory        ;...but this time, clear only as far as $076f
;
    LD A, (TitleLoadedFlag)         ;only do this on initial load
    OR A
    CALL Z, SndInitMemory           ;clear out memory used by the sound engine
;
    LD A, (TitleLoadedFlag)         ;do different initialization routine if after initial load
    OR A
    CALL NZ, InitializeMemoryExceptSND
;
    LD A, $18                       ;set demo timer
    LD (DemoTimer), A
    LD A, $02
    LD (PaletteFadeFlag), A
;
    CALL LoadAreaPointer
    JP InitializeArea

;-------------------------------------------------------------------------------------

PrimaryGameSetup:
;
    LD A, $01
    LD (FetchNewGameTimerFlag), A   ;set flag to load game timer from header
    LD (PlayerSize), A              ;set player's size to small
;
    INC A
    LD (NumberofLives), A           ;give each player three lives
    LD (OffScr_NumberofLives), A
    JP SecondaryGameSetup

;-------------------------------------------------------------------------------------

.SECTION "World Select Stripe Command for GameMenuRoutine" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
WSelectBufferTemplate:
    .dw swapBytes(xyToNameTbl_M(20, 0))     ; ADDRESS
    .db StripeCount($02)                    ; COUNT
    .dw BG_MACRO($0100)                     ; PLACEHOLDER FOR WORLD NUMBER
    .db $00                                 ; TERMINATOR
.ENDS

GameMenuRoutine:
    .IF WORLDSELECT != $00
    LD A, WORLDSELECT
    LD (WorldNumber), A
    .ENDIF
    .IF LEVELSELECT != $00
    LD A, LEVELSELECT
    LD (LevelNumber), A
    LD (AreaNumber), A
    .ENDIF
;
    LD A, $01                       ;set initial load flag
    LD (TitleLoadedFlag), A

    LD E, $00
    LD A, (SavedJoypad1Bits)        ;check to see if either player pressed
    LD HL, SavedJoypad2Bits         ;only the start button (either joypad) [Button 1 for SMS]
    OR A, (HL)
    LD B, A                         ;save copy in B
    CP A, bitValue(SMS_BTN_1)       
    JP Z, @ChkContinue              ;if either start or A + start, execute here
    CP A, bitValue(SMS_BTN_2) | bitValue(SMS_BTN_1)  ;check to see if A + start was pressed [Button 1 + 2 for SMS]
    JP Z, @ChkContinue              ;if either start or A + start, execute here
@ChkSelect:
    AND A, %00001111                ;check to see if any d-pad buttons were pressed
    JR NZ, @SelectBLogic            ;if so, branch reset demo timer
    LD A, (DemoTimer)               ;otherwise check demo timer
    OR A
    JR NZ, @ChkWorldSel             ;if demo timer not expired, branch to check world selection
    LD (SelectTimer), A             ;set controller bits here if running demo
    CALL DemoEngine                 ;run through the demo actions
    JP C, @ResetTitle               ;if carry flag set, demo over, thus branch
    JP @RunDemo                     ;otherwise, run game engine for demo
@ChkWorldSel:
    LD A, (WorldSelectEnableFlag)   ;check to see if world selection has been enabled
    RRCA
    JR NC, @NullJoypad
    LD A, B
    CP A, bitValue(SMS_BTN_2)       ;if so, check to see if the B button was pressed (Button 2 for SMS)
    JR NZ, @NullJoypad
    INC E                           ;if so, increment Y and execute same code as select (E for Z80)
@SelectBLogic:
    LD A, (DemoTimer)               ;if select or B pressed, check demo timer one last time
    OR A
    JR Z, @ResetTitle               ;if demo timer expired, branch to reset title screen mode
    LD A, $18                       ;otherwise reset demo timer
    LD (DemoTimer), A
    LD A, (SelectTimer)             ;check select/B button timer
    OR A
    JR NZ, @NullJoypad              ;if not expired, branch
    LD A, $10
    LD (SelectTimer), A             ;otherwise reset select button timer
    DEC E                           ;was the B button pressed earlier?  if so, branch
    JR Z, @IncWorldSel              ;note this will not be run if world selection is disabled
    LD A, B
    CP A, bitValue(SMS_BTN_RIGHT)   ;if right isn't pressed, skip
    JR Z, @TogglePlayerGFX
    CP A, bitValue(SMS_BTN_LEFT)
    JR NZ, @TogglePlayers
    LD A, (WorldSelectEnableFlag)   ;check if world select flag is set
    OR A
    JR Z, @NullJoypad               ;if not, skip
    XOR A, $02                      ;toggle bit 1 of world select flag (toggle star icon)
    LD (WorldSelectEnableFlag), A
    CALL DrawMushroomIcon
    JR @NullJoypad
@TogglePlayerGFX:
    LD A, (CurrentPlayerGfx)        ;toggle player graphics
    XOR A, %00000001
    LD (CurrentPlayerGfx), A
    LD (PlayerGfxOffset_Old), A     ;invalidate old gfx offset to ensure tile stream occurs
    JR @NullJoypad    
@TogglePlayers:
    LD A, (NumberOfPlayers)         ;if no, must have been the select button, therefore
    XOR A, $01                      ;change number of players and draw icon accordingly
    LD (NumberOfPlayers), A
    CALL DrawMushroomIcon
    JR @NullJoypad
;
@IncWorldSel:
    LD A, (WorldSelectNumber)       ;increment world select number
    INC A
    AND A, %00000111                ;mask out higher bits
    LD (WorldSelectNumber), A       ;store as current world select number
    CALL @GoContinue
    LD HL, WSelectBufferTemplate    ;write template for world select in vram buffer
    LD DE, VRAM_Buffer1
    LD BC, _sizeof_WSelectBufferTemplate    ;do this until all bytes are written
    LDIR
    DEC E
    LD (VRAM_Buffer1_Ptr), DE       ;update buffer index
    LD A, (WorldNumber)             ;get world number from variable and increment for
    ADD A, BG_TILE_OFFSET
    INC A                           ;proper display, and put in blank byte before
    LD (VRAM_Buffer1+3), A          ;null terminator
;
@NullJoypad:
    XOR A                           ;clear joypad bits for player 1
    LD (SavedJoypad1Bits), A
@RunDemo:
    CALL GameCoreRoutine            ;run game engine
    LD A, (GameEngineSubroutine)    ;check to see if we're running lose life routine
    CP A, $06
    RET NZ                          ;if not, do not do all the resetting below
@ResetTitle:
    XOR A                           ;reset game modes, disable
    LD (OperMode), A                ;sprite 0 check and disable
    LD (OperMode_Task), A           ;screen output
    LD (Sprite0HitDetectFlag), A
    LD (DisableScreenFlag), A
    JP FadeOutScreen
@ChkContinue:
    LD A, (DemoTimer)               ;if timer for demo has expired, reset modes
    OR A
    JR Z, @ResetTitle
    LD A, B
    BIT SMS_BTN_2, A                ;check to see if button 2 was also pushed
    JR Z, @StartWorld1              ;if not, don't load continue function's world number
    LD A, (ContinueWorld)           ;load previously saved world number for secret
    CALL @GoContinue                ;continue function when pressing A + start
@StartWorld1:
    CALL LoadAreaPointer
;
    XOR A
    LD (OperMode_Task), A           ;set game mode here, and clear demo timer
    LD (DemoTimer), A
    LD (TitleLoadedFlag), A         ;clear initial load flag
;
    INC A
    LD (Hidden1UpFlag), A           ;set 1-up box flag for both players
    LD (OffScr_Hidden1UpFlag), A
    LD (FetchNewGameTimerFlag), A   ;set fetch new game timer flag
    LD (OperMode), A                ;set next game mode
;
    LD A, (WorldSelectEnableFlag)   ;bit 1 of world select flag determines primary hard mode
    SRL A
    LD (PrimaryHardMode), A
;
    ;LD HL, ScoreAndCoinDisplay      ;clear player scores and coin displays
    ;LD DE, ScoreAndCoinDisplay + $01
    ;LD BC, $0017
    LD HL, PlayerScoreDisplay
    LD DE, PlayerScoreDisplay + $01
    LD BC, $000F
    LD (HL), B
    LDIR
    JP FadeOutScreen
@GoContinue:
;
    LD (WorldNumber), A             ;start both players at the first area
    LD (OffScr_WorldNumber), A      ;of the previously saved world number
;
    XOR A                           ;note that on power-up using this function
    LD (AreaNumber), A              ;will make no difference
    LD (OffScr_AreaNumber), A
    RET

;-------------------------------------------------------------------------------------

.SECTION "Mushroom Icon Stripe Command for DrawMushroomIcon" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
MushroomIconData:
    .dw swapBytes(xyToNameTbl_M(9, 15))     ; ADDRESS
    .db StripeCount($02)
    .dw BLANKTILE                           ; $03-$04

    .dw swapBytes(xyToNameTbl_M(9, 17))
    .db StripeCount($02)
    .dw BLANKTILE                           ; $08-$09
    .db $00
.ENDS

DrawMushroomIcon:
;
    LD HL, MushroomIconData         ;read eight bytes to be read by transfer routine
    LD DE, VRAM_Buffer1             ;note that the default position is set for a
    LD BC, _sizeof_MushroomIconData ;1-player game
    LDIR
;
    LD B, $08                       ;use SPR palette for icon if in new gfx mode
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JR Z, +
    LD B, $00                       ;else, use BG palette
+:
    LD A, (WorldSelectEnableFlag)   ;use mushroom icon for normal quest
    BIT 1, A
    LD C, $B6
    JR Z, +
    LD C, $B5                       ;else, use star icon for second quest
+:
;
    LD (VRAM_Buffer1 + $03), BC     ;write icon for 1 player
;
+:
    DEC E
    LD (VRAM_Buffer1_Ptr), DE       ;update buffer index
;
    LD A, (NumberOfPlayers)         ;check number of players
    OR A
    RET Z                           ;if set to 1-player game, we're done
;
    LD (VRAM_Buffer1 + $08), BC     ;otherwise, load icon tile in 2-player position
    LD BC, $0000
    LD (VRAM_Buffer1 + $03), BC     ;then load blank tile in 1-player position
    RET

;-------------------------------------------------------------------------------------

.SECTION "Action Data TBL for DemoEngine" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
DemoActionData:
    .db $00 ; PADDING
    .db $01, $80, $02, $81, $41, $80, $01
    .db $42, $c2, $02, $80, $41, $c1, $41, $c1
    .db $01, $c1, $01, $02, $80, $00
.ENDS

.SECTION "Timing Data TBL for DemoEngine" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
DemoTimingData:
    .db $00 ; PADDING
    .db $9b, $10, $18, $05, $2c, $20, $24
    .db $15, $5a, $10, $20, $28, $30, $20, $10
    .db $80, $20, $30, $30, $01, $ff, $00
.ENDS

DemoEngine:
;
    LD A, (DemoActionTimer)         ;load current action timer
    OR A
    JR NZ, @DoAction                ;if timer still counting down, skip
;
    LD HL, DemoAction               ;if expired, increment action, X
    INC (HL)
    LD A, (HL)
    LD HL, DemoTimingData           ;get next timer
    addAToHL8_M
    LD A, (HL)
    LD (DemoActionTimer), A         ;store as current timer
    OR A
    SCF                             ;set carry by default for demo over
    RET Z                           ;if timer already at zero, skip (Demo Over!)
@DoAction:
    LD A, (DemoAction)              ;load current demo action
    LD HL, DemoActionData           ;get and perform action (current or next)
    addAToHL8_M
    LD A, (HL)
    LD (SavedJoypad1Bits), A
    LD HL, DemoActionTimer          ;decrement action timer
    DEC (HL)
    OR A                            ;clear carry if demo still going
    RET