;   SEGA MASTER SYSTEM CONVERSION OF SUPER MARIO BROS.
;   Author: LackofTrack

;   Used "SMBDIS.ASM" by doppelganger for reference

;-------------------------------------------------------------------------------------
;   SET INCLUDE DIRECTORY
.INCDIR "CODE"
;   INCLUDES
.INCLUDE "constants.inc"
.INCLUDE "banking.inc"
.INCLUDE "ramLayout.inc"
.INCLUDE "macros.asm"


.DEFINE InitGameOffset          OperMode - $01          
.DEFINE InitAreaOffset          AreaType - $01
.DEFINE WarmBootOffset          TopScoreDisplay - $01
.DEFINE ColdBootOffset          WarmBootValidation - $01

;-------------------------------------------------------------------------------------
;   SDSC TAG AND SMS HEADER
.SDSCTAG 0.12, sdscName, sdscDesc, sdscAuth

;-------------------------------------------------------------------------------------
;   SET BANK
.BANK BANK_CODE SLOT 0

;-------------------------------------------------------------------------------------
;   BOOT VECTOR
.ORGA $0000
BootVector:
    DI                      ; DISABLE INTURRUPTS
    IM 1
    LD SP, STACK_PTR
    JR Start

;-------------------------------------------------------------------------------------|
;   USER VECTORS

.ORG $0008
ResetVector:
    DI
    NOP
    LD SP, STACK_PTR
    JP ResetStart


;   GIVEN A VALUE IN BOTH A AND HL, THE VALUE IN A WILL BE ADDED TO HL
;   INPUT: HL - VALUE, A - VALUE
;   OUTPUT: HL - HL + A, A - (HL + A)
;   USES: HL, A
.ORG $0010
addAToHL:
    ADD A, L
    LD L, A
    ADC A, H
    SUB A, L
    LD H, A
    LD A, (HL)
    RET
    .db $00                     ; FILL


;   INFO: TIME WASTER WHEN ACCESSING YM2413
.ORG $0018
SndFMWriteDelay:
    PUSH HL
    POP HL
    PUSH HL
    POP HL
    RET
    .db $00, $00, $00           ; FILL



;   INFO: GIVEN AN ADDRESS, SETS VDP ADDRESS TO IT
;   INPUT: HL
;   OUTPUT: NONE
;   USES: A
.ORG $0020
setVDPAddress:
    LD A, L                     ; LOW BYTE OF ADDRESS
    OUT (VDPCON_PORT), A    
    LD A, H                     ; OPERATION TYPE + HIGH BITS OF ADDRESS
    OUT (VDPCON_PORT), A
    RET
    .db $00                     ; FILL


;   INFO: JUMPS TO AN ADDRESS GIVEN AN OFFSET
;   INPUT: A - OFFSET
;   OUTPUT: NONE
;   USES: HL', AF
.ORG $0028
JumpEngine:
    EXX                         ;switch to shadow regs to preserve HL (ObjectOffset)
    POP HL                      ;pull saved return address from stack
    ADD A, A                    ;shift bit from contents of A
    addAToHL_M                  ;load pointer from indirect
    LD A, (HL)                  ;note that if an RTS is performed in next routine
    INC HL                      ;it will return to the execution before the sub
    LD H, (HL)                  ;that called this routine
    LD L, A
    PUSH HL                     ;put new address onto the stack
    EXX                         ;switch back to normal regs
    RET                         ;"return" to new address
    .db $00

;-------------------------------------------------------------------------------------
;   VDP VECTOR
.ORGA $0038
VdpVector:
    PUSH AF
;   CHECK IF H-INT OCCURED
    IN A, (VDPCON_PORT)
    OR A
    JP M, NonMaskableInterrupt
    ; IF SO...
    LD A, (VDPHScroll)              ;SEND HSCROLL TO VDP
    OUT (VDPCON_PORT), A
    LD A, $88
    OUT (VDPCON_PORT), A
    LD A, %00100100                 ;TURN OFF H-INTS (ONLY 1 IS REQUIRED PER FRAME)
    OUT (VDPCON_PORT), A
    LD A, $80
    OUT (VDPCON_PORT), A
    POP AF
    EI                              ;enable Z80 interrupts
    RET                             ;return from H-INT


;-------------------------------------------------------------------------------------
;   PAUSE BUTTON VECTOR
.ORGA $0066
PauseBtnVector:
    PUSH AF                     ; SAVE AF
    LD A, bitValue(SMS_BTN_START)
    LD (PauseButtonFlag), A
    POP AF                      ; RESTORE AF
    RETN                        ; RETURN FROM NMI

;-------------------------------------------------------------------------------------
;   MAIN PROGRAM START
Start:
;   CHECK FOR FM UNIT
    ; STORE MEMORY CONTROL VALUE
    LD A, ($C000)
    LD (MemoryControlValue), A
    ; DISABLE IO
    OR A, %00000100
    OUT (MEM_CONTROL), A
    ; STORE CURRENT STATE OF AUDIO CONTROL PORT IN D
    IN A, (AUDIO_CONTROL)
    AND A, $03
    LD D, A
    ; 
    LD BC, $0400
-:
    LD A, B
    DEC A
    LD E, A
    OUT (AUDIO_CONTROL), A
    IN A, (AUDIO_CONTROL)
    AND A, $03
    CP A, E
    JR NZ, +
    INC C
+:
    DJNZ -
    ; RESTORE AUDIO CONTROL PORT
    LD A, D
    OUT (AUDIO_CONTROL), A
    ; REENABLE IO
    LD A, (MemoryControlValue)
    OUT (MEM_CONTROL), A
    ; CHECK COUNTER (1 OR 3 = NO FM. 2 = MARK3. 4 = J-SMS/AFTERMARKET)
    LD A, C
    RRCA
    LD A, $00
    JR C, +
    LD A, $01
+:
    LD (FMDetectedFlag), A
ResetStart:
;   TURN OFF SCREEN (AND DISABLE VDP INTS)
    CALL turnOffScreen
;   WAIT FOR VBLANK
    CALL waitForVblank
;   CLEAR CRAM
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    ; WRITE ZEROS TO CRAM
    LD BC, CRAM_SIZE * $100 + VDPDATA_PORT
-:
    OUT (C), L  ; L IS $00
    DJNZ -
;   CLEAR VRAM
    LD HL, $0000 | VRAMWRITE
    RST setVDPAddress
    ; WRITE ZEROS TO VRAM
    LD BC, <VRAM_SIZE * $100 + >VRAM_SIZE
    XOR A               ; DATA VALUE
-:
    OUT (VDPDATA_PORT), A
    DJNZ -
    DEC C
    JP NZ, -
;   VDP REGISTER INIT.
    LD HL, vdpInitData
    LD BC, _sizeof_vdpInitData * $100 + VDPCON_PORT
    OTIR
;   MAPPER INIT.
    LD IX, MAPPER_RAM
    LD (IX + 0), $00    ; MAPPER REGISTER
    LD (IX + 1), $00    ; BANK SELECT FOR SLOT 0
    LD (IX + 2), $01    ; BANK SELECT FOR SLOT 1
    LD (IX + 3), $02    ; BANK SELECT FOR SLOT 2
;   MUTE PSG CHANNELS
    CALL SndStopAll@WritePSG
;   MUTE FM CHANNELS IF FM CHIP IS DETECTED
    LD A, (FMDetectedFlag)
    OR A
    CALL NZ, SndStopAllFM@WriteFM
;   RESET GRAPHIC & SOUND BITFLAGS
    XOR A
    LD (OptionBitflags), A
.IF INSTANTBOOT != $00
    LD HL, SndChannelProcessMUS
    LD (MusicRoutine), HL
    LD A, bitValue(OPTFLAG_GFX)
    LD (OptionBitflags), A
    LD HL, ColorRotation
    LD (AnimateRoutine), HL
    LD HL, BowserGfxDraw_NES
    LD (BowserDrawRoutine), HL
.ELSE
;   ------ OPTION SCREEN PROCESS ------
    ; LOAD BACKGROUND DATA
    LD A, :Tiles_BG_Options
    LD (MAPPER_SLOT2), A
    LD HL, Tiles_BG_Options
    LD DE, VRAM_ADR_BG | VRAMWRITE
    CALL zx7_decompressVRAM
    LD HL, Map_BG_Options
    LD DE, VRAM_ADR_NAMETBL | VRAMWRITE
    CALL zx7_decompressVRAM
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD HL, Pal_BG_Options
    LD BC, _sizeof_Pal_BG_Options * $100 + VDPDATA_PORT
    OTIR
    ; DISPLAY SOUND SELECTION IF FM CHIP IS DETECTED
    LD A, (FMDetectedFlag)
    OR A
    JR Z, +
    LD HL, $2048 | VRAMWRITE
    RST setVDPAddress
    LD HL, Map_BG_SoundSelect@Line1
    LD BC, $0600 + VDPDATA_PORT
    OTIR
    LD HL, $20C8 | VRAMWRITE
    RST setVDPAddress
    LD HL, Map_BG_SoundSelect@Line2
    LD BC, $0600 + VDPDATA_PORT
    OTIR
+:
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    ; INITIALIZE BASIC MEMORY
    LD HL, WarmBootOffset
    CALL InitializeMemory
    CALL SndInitMemory@InitSndLinearMem
    LD HL, SndChannelProcessMUS
    LD (MusicRoutine), HL
    XOR A
    LD (BGTileQueue0.UpdateFlag), A
    LD (BGTileQueue1.UpdateFlag), A
    LD (BGTileQueue2.UpdateFlag), A
    INC A
    LD (FrameDoneFlag), A
    LD (PlayerStatus), A
    LD (Player_X_Speed), A
    LD (Player_SprDataOffset), A
    LD (PlayerFacingDir), A
    LD (OperMode), A
    LD A, $07
    LD (PlayerAnimTimerSet), A
    LD A, $40
    LD (DisableScreenFlag), A
    LD A, $D0
    LD (Sprite_Y_Position + $09), A
    LD A, $20
    LD (Player_Rel_XPos), A
    ADD A, SMS_PIXELYOFFSET
    LD (Player_Rel_YPos), A
    CALL PlayerGfxHandler
    ;
    CALL waitForVblank
    IN A, (VDPCON_PORT)             ;clear any pending VDP interrupts
    EI
OptionsLoop:
    LD A, (Temp_Bytes + $01)        ;check if leaving options menu
    OR A
    JR Z, OptionsCheckJoypad        ;if not, skip
    LD A, (SFXTrack0.Control)       ;check if sfx has finished playing
    OR A
    JP P, MainGameInit              ;if so, go to main game
OptionsCheckJoypad:
    LD HL, SavedJoypad1Bits         ;debounce inputs
    LD B, (HL)
    LD A, (Temp_Bytes + $00)
    XOR A, (HL)
    AND A, (HL)
    LD (HL), A
    LD A, B
    LD (Temp_Bytes + $00), A
    LD A, (HL)
    ; --- BUTTON UP/DOWN PROCESS ---
    AND A, bitValue(SMS_BTN_UP) | bitValue(SMS_BTN_DOWN)
    JR Z, OptionCheckBtn1           ;if neither up or down is pressed, skip
    AND A, bitValue(SMS_BTN_UP)     ;check if up is pressed
    LD A, (OptionBitflags)          ;clear bit 0 of bit flags by default
    RES OPTFLAG_GFX, A
    JR NZ, +                        ;if so, skip
    SET OPTFLAG_GFX, A              ;else, set bit 0 (do NES gfx)
+:
    LD (OptionBitflags), A
    LD A, SNDID_BEEP                ;do beep sfx
    LD (SFXTrack0.SoundQueue), A
    LD (PlayerGfxOffset_Old + $01), A   ;invalidate old player gfx offset to refresh
    JR OptionUpdateSettings
    ; --- BUTTON 1 PROCESS ---
OptionCheckBtn1:
    LD A, (SavedJoypad1Bits)        ;check if button 1 is being pressed
    AND A, bitValue(SMS_BTN_1)
    JR Z, OptionCheckBtn2           ;if not, skip
    LD A, $01                       ;set flag to signal that we are leaving the options menu
    LD (Temp_Bytes + $01), A
    LD A, SNDID_BEEP                ;do beep sfx
    LD (SFXTrack0.SoundQueue), A
    JR OptionUpdateSettings
    ; --- BUTTON 2 PROCESS ---
OptionCheckBtn2:
    LD A, (FMDetectedFlag)
    OR A
    JR Z, OptionUpdateSettings
    LD A, (SavedJoypad1Bits)
    AND A, bitValue(SMS_BTN_2)
    JR Z, OptionUpdateSettings
    LD A, (OptionBitflags)
    XOR A, bitValue(OPTFLAG_FM)
    LD (OptionBitflags), A
    LD A, SNDID_BEEP                ;do beep sfx
    LD (SFXTrack0.SoundQueue), A
OptionUpdateSettings:
    LD HL, PlayerAnimTimer          ;update timer for walking animation
    DEC (HL)
    ;
    LD A, (OptionBitflags)          ;set values depending on bit 0 of option bit flags
    AND A, bitValue(OPTFLAG_GFX)
    JR NZ, +
    LD A, BANK_PLAYERGFX00
    LD (PlayerGfxBank), A
    LD A, VRAMTBL_BOWSERPAL
    LD (VRAM_Buffer_AddrCtrl), A
    LD A, $38
    LD (Player_Rel_YPos), A
    LD HL, AnimateBGTiles
    LD (AnimateRoutine), HL
    LD HL, BowserGfxDraw
    LD (BowserDrawRoutine), HL
    JR @UpdateFMSettings
+:
    LD A, BANK_PLAYERGFX04
    LD (PlayerGfxBank), A
    LD A, VRAMTBL_BOWSERPAL + $15
    LD (VRAM_Buffer_AddrCtrl), A
    LD A, $38 + $68
    LD (Player_Rel_YPos), A
    LD HL, ColorRotation
    LD (AnimateRoutine), HL
    LD HL, BowserGfxDraw_NES
    LD (BowserDrawRoutine), HL
@UpdateFMSettings:
    LD A, (FMDetectedFlag)          ;skip FM sound setting update if FM module not detected
    OR A
    JR Z, OptionDrawPlayer
    LD A, (OptionBitflags)          ;set values depending on bit 1 of option bit flags
    AND A, bitValue(OPTFLAG_FM)
    JR NZ, +
    XOR A
    OUT (AUDIO_CONTROL), A
    LD HL, SndChannelProcessMUS
    LD (MusicRoutine), HL
    LD HL, $019A
    LD DE, $0000
    JR @DrawSelector
+:
    LD A, %00000011
    OUT (AUDIO_CONTROL), A
    LD HL, SndChannelProcessFM
    LD (MusicRoutine), HL
    LD HL, $0000
    LD DE, $019A
@DrawSelector:
    LD BC, $2000 | VRAMWRITE + VDPCON_PORT
    LD A, $44
    OUT (C), A
    OUT (C), B
    DEC C
    OUT (C), L
    OUT (C), H
    INC C
    LD A, $C4
    OUT (C), A
    OUT (C), B
    DEC C
    OUT (C), E
    OUT (C), D
OptionDrawPlayer:
    CALL PlayerGfxHandler           ;draw player
    LD A, $01                       ;signal that we have completed a frame on time
    LD (FrameDoneFlag), A
OptionNMIWait:
    LD A, (FrameDoneFlag)           ;busy loop until NMI has triggered
    OR A
    JR NZ, OptionNMIWait
    JP OptionsLoop
;   ------ END OF OPTION SCREEN PROCESS ------
.ENDIF
MainGameInit:
    DI                              ;disable interrupts
    LD A, %10100000                 ;turn off screen
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A
;   LOAD CONSTANT BACKGROUND TILES
    LD A, ASSET_BGCOMM
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
;   LOAD (mostly) CONSTANT SPRITE TILES
    LD A, ASSET_SPRCOMM
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
.IF BOOTPALTILES != $00
;   LOAD PALETTE AND OVERWORLD TILE DATA ON BOOTUP (DEBUG)
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    LD HL, $C000
    RST setVDPAddress
    LD HL, GroundPaletteData + $03
    LD BC, $2000 + VDPDATA_PORT
    OTIR
    LD A, ASSET_BGOVERWORLD
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
.ENDIF
;   SET DEFAULT BANK FOR SLOT 2
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
;-------------------------------------------------------------------------------------
;   BOOT CHECK
    LD HL, ColdBootOffset           ;load default cold boot pointer
    LD B, $06
    LD DE, TopScoreDisplay + $05    ;this is where we check for a warm boot
WBootCheck:
    LD A, (DE)                      ;check each score digit in the top score
    CP A, $10                       ;to see if we have a valid digit
    JR NC, ColdBoot                 ;if not, give up and proceed with cold boot
    DEC DE
    DJNZ WBootCheck
    LD A, (WarmBootValidation)      ;second checkpoint, check to see if 
    CP A, $A5                       ;another location has a specific value
    JR NZ, ColdBoot
    LD HL, WarmBootOffset           ;if passed both, load warm boot pointer
ColdBoot:
    CALL InitializeMemory           ;clear memory using pointer in HL
    XOR A
    LD (OperMode), A                ;reset primary mode of operation
    LD (TitleLoadedFlag), A
    INC A
    LD (FrameDoneFlag), A
    LD A, $A5
    LD (WarmBootValidation), A      ;set warm boot flag
    LD (PseudoRandomBitReg), A      ;set seed for pseudorandom register
    CALL MoveAllSpritesOffscreen
    CALL InitializeNameTables       ;initialize name table
    CALL waitForVblank
    IN A, (VDPCON_PORT)             ;clear any pending VDP interrupts
    EI                              ;enable Z80 interrupts
;   MAIN LOOP START
EndlessLoop:
    LD A, (FrameDoneFlag)
    OR A
    JR NZ, EndlessLoop
    ; --- PAUSE ROUTINE ---
    LD A, (OperMode)                ;are we in victory mode?
    CP A, MODE_VICTORY              ;if so, go ahead
    JR Z, ChkPauseTimer
    CP A, MODE_GAMEPLAY             ;are we in game mode?
    JR NZ, UpdateTopScore           ;if not, leave
    LD A, (OperMode_Task)           ;if we are in game mode, are we running game engine?
    CP A, $03
    JR NZ, UpdateTopScore           ;if not, leave
ChkPauseTimer:
    LD A, (GamePauseTimer)          ;check if pause timer is still counting down
    OR A
    JR Z, ChkStart
    DEC A
    LD (GamePauseTimer), A          ;if so, decrement and leave
    JP UpdateTopScore
ChkStart:
    LD A, (SavedJoypad1Bits)        ;check to see if start is pressed
    AND A, bitValue(SMS_BTN_START)
    JR Z, ClrPauseTimer
    LD A, (GamePauseStatus)         ;check to see if timer flag is set
    AND A, $80                      ;and if so, do not reset timer
    JR NZ, UpdateTopScore
    LD A, $2B                       ;set pause timer
    LD (GamePauseTimer), A
    LD A, SNDID_PAUSE
    LD (SFXTrack0.SoundQueue), A
    LD A, $01
    LD (SndPauseFlag), A
    LD A, (GamePauseStatus)
    XOR A, $01                      ;invert d0 and set d7
    OR A, $80
    JP SetPause                     ;unconditional branch
ClrPauseTimer:
    LD A, (GamePauseStatus)         ;clear timer flag if timer is at zero and start button
    AND A, $7F                      ;is not pressed
SetPause:
    LD (GamePauseStatus), A
    ; --- UPDATE TOP SCORE ---
UpdateTopScore:
    LD DE, PlayerScoreDisplay + $05     ;start with mario's score
    CALL TopScoreCheck
    LD DE, OffScr_ScoreDisplay + $05    ;now do luigi's score
    CALL TopScoreCheck
    ; --- TIMER UPDATE ---
    LD A, (GamePauseStatus)         ;check for pause status
    RRCA
    JR C, TickPRNG
    LD HL, TimerControl
    LD A, (HL)
    OR A                            ;if master timer control not set, decrement
    JR Z, DecTimers                 ;all frame and interval timers
    DEC (HL)
    JR NZ, NoDecTimers
DecTimers:
    LD DE, Timers + $14             ;load end offset for end of frame timers
    LD B, $15
    LD HL, IntervalTimerControl
    DEC (HL)                        ;decrement interval timer control,
    JP P, DecTimersLoop             ;if not expired, only frame timers will decrement
    .IF PALBUILD == $00
    LD (HL), $14                    ;if control for interval timers expired,
    .ELSE
    LD (HL), $11                    ;PAL diff: interval timer is 18 frames (vs. 21 for NTSC)
    .ENDIF
    LD DE, Timers + $23             ;interval timers will decrement along with frame timers
    LD B, $24
DecTimersLoop:
    LD A, (DE)                      ;check current timer
    OR A
    JR Z, SkipExpTimer              ;if current timer expired, branch to skip,
    DEC A                           ;otherwise decrement the current timer
    LD (DE), A
SkipExpTimer:
    DEC E                           ;move onto next timer
    DJNZ DecTimersLoop              ;do this until all timers are dealt with   
NoDecTimers:
    LD HL, FrameCounter             ;increment frame counter
    INC (HL)
    ; --- PRNG UPDATE ---
TickPRNG:
    LD HL, PseudoRandomBitReg
    LD B, $07
    LD A, (HL)                      ;get first memory location of LSFR bytes
    INC L
    XOR A, (HL)                     ;perform exclusive-OR on d1 from first and second bytes
    DEC L
    RRCA                            ;if one or the other is set, carry will be set
    RRCA                            ;if neither or both are set, carry will be clear
RotPRandomBit:
    RR (HL)                         ;rotate carry into d7, and rotate last bit into carry
    INC L                           ;increment to next byte
    DJNZ RotPRandomBit              ;decrement for loop
    ; --- SPRITE SHUFFLE ---
    LD A, (Sprite0HitDetectFlag)
    CPL
    LD B, A
    LD A, (GamePauseStatus)
    OR A, B
    RRCA                            ;[CPU TIME: 05 LINES]
    CALL NC, SpriteShuffler
    ; --- MAIN GAME EXEC ---
    LD A, (GamePauseStatus)
    RRCA
    CALL NC, OperModeExecutionTree
    ; --- FRAME COMPLETE ---
    LD A, $01
    LD (FrameDoneFlag), A
    JP EndlessLoop                  ;endless loop, need I say more?

;-------------------------------------------------------------------------------------

.SECTION "VRAM Action Table" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
VRAM_AddrTable:
    .dw VRAM_Buffer1, WaterPaletteData, GroundPaletteData,
    .dw UndergroundPaletteData, CastlePaletteData, TitleScreenData
    .dw VRAM_Buffer2, VRAM_Buffer2, OptionsPaletteData                   ; Second VRAM_Buffer2 is never used?
    .dw DaySnowPaletteData, NightSnowPaletteData, MushroomPaletteData
    .dw MarioThanksMessage, LuigiThanksMessage, MushroomRetainerSaved
    .dw PrincessSaved1, PrincessSaved2, WorldSelectMessage1
    .dw WorldSelectMessage2, RetainerPaletteData, PrincessPaletteData
    ;
    .dw VRAM_Buffer1, WaterPaletteData_NES, GroundPaletteData_NES
    .dw UndergroundPaletteData_NES, CastlePaletteData_NES, TitleScreenData_NES
    .dw VRAM_Buffer2, VRAM_Buffer2, OptionsPaletteData_NES
    .dw DaySnowPaletteData_NES, NightSnowPaletteData_NES, MushroomPaletteData_NES 
.ENDS

NonMaskableInterrupt:
;   INITIALIZE H SCROLL REG
    XOR A
    OUT (VDPCON_PORT), A
    LD A, $88
    OUT (VDPCON_PORT), A
;   SKIP VDP UPDATE AND JOYPAD READING IF ON A LAG FRAME
    LD A, (FrameDoneFlag)
    RRA
    JR NC, LagFrame
    LD (FrameDoneFlag), A
;   SET VDP HSCROLL TO HSCROLL VALUE FROM LAST PROCESSED GAME FRAME
    LD A, (HorizontalScroll)
    NEG
    LD (VDPHScroll), A
;   TURN OFF SCREEN IF FLAG IS CLEAR
    LD A, %10100000
    LD HL, DisableScreenFlag
    OR A, (HL)
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A
;   SPRITE UPDATE                   [CPU TIME: 10 LINES]
    ; WRITE Y POSITIONS
    XOR A
    OUT (VDPCON_PORT), A
    LD A, >VRAM_ADR_SPRTBL | >VRAMWRITE
    OUT (VDPCON_PORT), A
    LD C, VDPDATA_PORT
    LD HL, Sprite_Y_Position
    CALL OutiBlock128 + $80         ; SKIP THE FIRST 64 OUTIs
    ; WRITE X POSITIONS AND TILE INDEXES
    LD A, <VRAM_ADR_SPRTBL + $80
    OUT (VDPCON_PORT), A
    LD A, >VRAM_ADR_SPRTBL | >VRAMWRITE
    OUT (VDPCON_PORT), A
    LD L, <Sprite_X_Position
    CALL OutiBlock128
;   EXTRA NAMETABLE UPDATE FOR COLUMN DRAWING   [CPU TIME: 08 LINES]
    LD A, (RenderColumnFlag)
    OR A
    CALL NZ, ColumnWriteUpdate
;   NAMETABLE UPDATE                [CPU TIME: ~04 LINES]
    LD A, (VRAM_Buffer_AddrCtrl)    ;load control for pointer to buffer contents
    LD B, A                         ;save for UpdateScreen
    ADD A, A
    LD HL, VRAM_AddrTable
    addAToHL8_M
    LD A, (HL)                      ;dereference pointer
    INC L
    LD H, (HL)
    LD L, A
    LD A, (HL)                      ;check if buffer is empty (high byte of VDP address)
    OR A
    CALL NZ, UpdateScreen           ;if not, update screen with buffer contents
    LD HL, VRAM_Buffer2
    LD A, (VRAM_Buffer_AddrCtrl)    ;check for usage of $0341 (VRAM_Buffer2)
    CP A, VRAMTBL_BUFFER2
    JR Z, +                         ;if not used, skip
    LD HL, VRAM_Buffer1
    LD (VRAM_Buffer1_Ptr), HL
+:
    LD (HL), $00                    ;clear buffer header
    XOR A
    LD (VRAM_Buffer_AddrCtrl), A    ;reinit address control to VRAM_Buffer1
;   TILE STREAMING
    LD HL, (PlayerGfxOffset_Old)
    LD DE, (PlayerGfxOffset)
    SBC HL, DE
    JP NZ, StreamPlayerTiles        ;[CPU TIME: 21 LINES]
    JP StreamAnimatedBGTiles        ;[CPU TIME: ~30 LINES]
TileStreamRet:
    CALL ReadJoypads
;   DON'T SET H-INT IF SPRITE 0 FLAG ISN'T SET (LAG FRAMES ALWAYS SET H-INT)
    LD A, (Sprite0HitDetectFlag)
    OR A
    JR Z, SoundUpdate
LagFrame:
    LD A, %00110100
    OUT (VDPCON_PORT), A
    LD A, $80
    OUT (VDPCON_PORT), A
SoundUpdate:
;   SOUND UPDATE
    EI                              ;enable z80 interrupts here because H-INT WILL interrupt SoundEngine!
    PUSH BC
    PUSH DE
    PUSH HL
    CALL SoundEngine
    POP HL
    POP DE
    POP BC
;   NMI END
    POP AF
    RET

;-------------------------------------------------------------------------------------

.SECTION "JoypadTable" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
JoypadTable:
    .db $00, $08, $04, $0c, $02, $0a, $06, $0e, $01, $09, $05, $0d, $03, $0b, $07, $0f
    .db $40, $48, $44, $4c, $42, $4a, $46, $4e, $41, $49, $45, $4d, $43, $4b, $47, $4f
    .db $80, $88, $84, $8c, $82, $8a, $86, $8e, $81, $89, $85, $8d, $83, $8b, $87, $8f
    .db $c0, $c8, $c4, $cc, $c2, $ca, $c6, $ce, $c1, $c9, $c5, $cd, $c3, $cb, $c7, $cf
.ENDS

ReadJoypads:
;   SET PORT 1'S TH TO HIGH OUTPUT
    LD A, ~(bitValue(P1_TH_DIR))
    OUT (IO_CONTROL), A
;   CONTROL 1
    LD HL, JoypadTable
    IN A, (CONTROLPORT1)
    CPL                             ; INVERT SO 1 = PRESSED, 0 = NO PRESS
    LD D, A                         ; SAVE FOR LATER
    AND A, $3F                      ; REMOVE 2P BITS
    addAToHL8_M                     ; USE AS OFFSET INTO TABLE TO CONVERT TO NES INPUT
    LD A, (HL)
    
    .IF NOINVALIDINPUTS != $00
    ; CANCEL OUT OPPOSING DIRECTIONS
    LD B, A
    RRCA
    AND A, B
    AND A, %00000101
    LD C, A
    ADD A, A
    OR A, C
    CPL
    AND A, B
    .ENDIF

    LD (SavedJoypad1Bits), A
;   CONTROL 2
    LD A, D                         ; GET 2P BUTTONS FROM 1ST READ
    AND A, $C0                      ; ISOLATE THEM
    LD D, A
    LD L, <JoypadTable
    IN A, (CONTROLPORT2)
    CPL                             ; INVERT SO 1 = PRESSED, 0 = NO PRESS
    BIT 4, A                        ; CHECK IF RESET BUTTON IS PRESSED
    JP NZ, ResetVector              ; IF SO, RESET THE GAME
    AND A, $0F                      ; ISOLATE 2P BUTTONS
    OR A, D                         ; COMBINE WITH THE BUTTONS FROM THE FIRST READ
    RLCA                            ; SHIFT INTO PLACE
    RLCA
    addAToHL8_M                     ; USE AS OFFSET INTO TABLE TO CONVERT TO NES INPUT
    LD A, (HL)

    .IF NOINVALIDINPUTS != $00
    ; CANCEL OUT OPPOSING DIRECTIONS
    LD B, A
    RRCA
    AND A, B
    AND A, %00000101
    LD C, A
    ADD A, A
    OR A, C
    CPL
    AND A, B
    .ENDIF

    LD (SavedJoypad2Bits), A
;   PAUSE ON CONTROLLER 2 BTN 1 FOR 1 PLAYER GAME
    LD HL, SavedJoypad1Bits
    LD A, (NumberOfPlayers)
    OR A
    JR NZ, PauseBtnChk
    LD A, (SavedJoypad2Bits)
    RRCA
    RRCA
    AND A, bitValue(SMS_BTN_START)
    OR A, (HL)
    LD (HL), A
;   ACCOUNT FOR PAUSE BUTTON
PauseBtnChk:
    LD A, (PauseButtonFlag)
    OR A, (HL)
    LD (HL), A
    XOR A
    LD (PauseButtonFlag), A
;   MD CONTROLLER PAUSE CHECK
    LD HL, MDControllerBits
    ; SET PORT 1'S TH TO LOW OUTPUT
    LD A, ~(bitValue(P1_TH_LVL) | bitValue(P1_TH_DIR))
    OUT (IO_CONTROL), A
    ; GET INPUTS (A, START)
    IN A, CONTROLPORT1
    CPL
    LD (HL), A
    LD C, A
    ; EXIT IF MD CONTROLLER ISN'T PLUGGED IN
    AND A, bitValue(P1_DIR_LEFT) | bitValue(P1_DIR_RIGHT)
    CP A, bitValue(P1_DIR_LEFT) | bitValue(P1_DIR_RIGHT)
    RET NZ
    ; DEBOUNCE INPUTS AND SET START BUTTON IF NEWLY PRESSED
    LD B, (HL)
    LD A, (MDControllerBitsOld)
    XOR A, (HL)
    AND A, (HL)
    LD (HL), A
    LD HL, SavedJoypad1Bits
    AND A, bitValue(P1_BTN_2)
    RRCA            ; MOVE TO SMS_BTN_START INDEX
    OR A, (HL)
    LD (HL), A
    LD A, B
    LD (MDControllerBitsOld), A
    ; DO SOFT RESET IF (START + A + B + C) IS PRESSED
    LD A, C
    AND A, bitValue(P1_BTN_2) | bitValue(P1_BTN_1)      ; no debounce on START + A
    CP A, bitValue(P1_BTN_2) | bitValue(P1_BTN_1)
    RET NZ
    LD A, (SavedJoypad1Bits)
    AND A, bitValue(SMS_BTN_1) | bitValue(SMS_BTN_2)    ; no debounce on B + C
    CP A, bitValue(SMS_BTN_1) | bitValue(SMS_BTN_2)
    RET NZ
    RST ResetVector

;-------------------------------------------------------------------------------------

UpdateScreen:
    LD A, B
    CP A, VRAMTBL_BUFFER2
    JP Z, WriteVertColumnBuff2
    LD IXH, >WriteHoriBlock
@SkipBuff2Chk:
;   Write Address to VDP
    INC HL
    INC C                       ;VDPCON_PORT
    OUTD
    OUTI
    DEC C                       ;VDPDATA_PORT
;   Set count and write data
    INC HL
    LD A, (HL)
    LD IXL, A
    INC HL
    CALL IndirectCallIX
;   check if buffer is empty
    LD A, (HL)
    OR A
    JP NZ, UpdateScreen@SkipBuff2Chk    ; if not, keep updating screen
    RET

WriteVertColumnBuff2:
;   ADVANCE POINTER TO TILE DATA
    PUSH HL
    INC L
    INC L
;   PREPARE SHADOW REGS
    EXX
    POP HL
    LD A, (HL)
    INC L
    LD L, (HL)
    LD H, A
    LD C, VDPCON_PORT
    LD DE, $0040
    EXX
;   WRITE 23 WORDS VERTICALLY
    CALL WriteVeriBlock_W
;   check if buffer is empty
    LD A, (HL)
    OR A
    JP NZ, WriteVertColumnBuff2
;   reset pointer here
    LD HL, VRAM_Buffer2
    LD (VRAM_Buffer2_Ptr), HL
    RET


ColumnWriteUpdate:
;   CLEAR RENDER FLAG
    XOR A
    LD (RenderColumnFlag), A
;   ADVANCE POINTER TO TILE DATA
    LD HL, (ColumnWrite_Ptr)
    INC L
    INC L
;   PREPARE SHADOW REGS
    EXX
    LD HL, (ColumnWrite_Ptr)
    LD A, (HL)
    INC L
    LD L, (HL)
    LD H, A
    LD C, VDPCON_PORT
    LD DE, $0040
    EXX
;   WRITE 23 WORDS VERTICALLY
    JP WriteVeriBlock_W

IndirectCallHL:
    JP (HL)

IndirectCallIX:
    JP (IX)

IndirectCallIY:
    JP (IY)

;-------------------------------------------------------------------------------------

TopScoreCheck:
    LD HL, TopScoreDisplay + $05        ;start with the lowest digit
GetScoreDiff:
    .REPEAT $06
    LD A, (DE)                          ;subtract each player digit from each high score digit
    SBC A, (HL)                         ;from lowest to highest, if any top score digit exceeds
    DEC E                               ;any player digit, borrow will be set until a subsequent
    DEC L                               ;subtraction clears it (player digit is higher than top)
    .ENDR
    RET C                               ;check to see if borrow is still set, if so, no new high score
;
    INC E                               ;increment X and Y once to the start of the score
    INC L
    EX DE, HL
    LDI                                 ;store player's score digits into high score memory area
    LDI
    LDI
    LDI
    LDI
    LDI
    RET

;-------------------------------------------------------------------------------------
;$00(C) - used for preset value

SpriteShuffler:
;   PLACE ALL SPRITES OFFSCREEN
    CALL MoveAllSpritesOffscreen
;   UPDATE SHUFFLE OFFSET
    LD HL, SprShuffleAmtOffset
    LD A, (HL)
    INC (HL)
    CP A, $02
    JR NZ, +
    LD (HL), $00
;   USE AS OFFSET INTO SpriteSlotTable
+:
    ADD A, A                            ; *2
    ADD A, A                            ; *4
    ADD A, A                            ; *8
    LD B, A                             ; B = A*8
    ADD A, A                            ; *16
    ADD A, B                            ; *24 (16 + 8)
    ADD A, <SpriteSlotTable
    LD L, A
    LD H, >SpriteSlotTable
    LD DE, SprDataOffset
;   WRITE TABLE DATA TO OBJECT SPRITE SLOTS
    .REPEAT $18
    LD A, (HL)
    LD (DE), A
    INC L
    INC D
    .ENDR
    RET

.SECTION "Sprite Slot Table" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
SpriteSlotTable:
    .db 1, 34, 40, 46, 52, 58, 10, 16, 22, 26, 9, 30, 31, 32, 33, 58, 60, 62, 10, 12, 14, 16, 18, 20
    .db 1, 52, 58, 10, 16, 22, 28, 34, 40, 44, 9, 48, 49, 50, 51, 22, 24, 26, 28, 30, 32, 34, 36, 38
    .db 1, 12, 18, 24, 30, 36, 42, 48, 54, 58, 9, 62, 63, 10, 11, 36, 38, 40, 42, 44, 46, 48, 50, 52
.ENDS

;-------------------------------------------------------------------------------------

MoveAllSpritesOffscreen:
MoveSpritesOffscreen:
;   SAVE SP IN DE
    LD HL, $0000
    ADD HL, SP
    EX DE, HL
;   MEMSET Sprite_Y_Position WITH OFFSCREEN VALUE
    LD HL, YPOS_OFFSCREEN * $100 + YPOS_OFFSCREEN
    LD SP, Sprite_Y_Position + $40
    .REPEAT $20
    PUSH HL
    .ENDR
;   RESTORE SP
    EX DE, HL
    LD SP, HL
    RET

;-------------------------------------------------------------------------------------

GetAreaMusic:
    LD A, (OperMode)                    ;if in title screen mode, skip
    OR A
    JR NZ, NotOnTitleScreen
;
    LD A, (TitleLoadedFlag)             ;if after initial load at title screen, exit
    OR A
    RET NZ
    LD A, (OptionBitflags)              ;depending on sound mode, play title or silence
    AND A, bitValue(OPTFLAG_FM)
    LD A, SNDID_TITLE_FM
    JR NZ, StoreMusicDirect
    LD A, SNDID_SILENCE
    JP StoreMusicDirect
;
NotOnTitleScreen:
    LD A, (AltEntranceControl)          ;check for specific alternate mode of entry
    CP A, $02                           ;if found, branch without checking starting position
    JR Z, ChkAreaType                   ;from area object data header
;
    LD C, $05                           ;select music for pipe intro scene by default
    LD A, (PlayerEntranceCtrl)          ;check value from level header for certain values
    CP A, $06
    JR Z, StoreMusic                    ;load music for pipe intro scene if header
    CP A, $07                           ;start position either value $06 or $07
    JR Z, StoreMusic
ChkAreaType:
    LD C, $04                           ;select music for cloud type level
    LD A, (BonusAreaFlag)               ;use it for in bonus area (cloud or underground coin room)
    OR A
    JR NZ, StoreMusic
    LD A, (AreaType)                    ;else, load area type as offset for music bit
    LD C, A
StoreMusic:
    LD A, C
    ADD A, SNDID_WATER
StoreMusicDirect:
    LD (MusicTrack0.SoundQueue), A      ;store in queue and leave
    RET

;-------------------------------------------------------------------------------------

InitializeNameTables:
    LD HL, VRAM_ADR_NAMETBL | VRAMWRITE
    CALL setVDPAddress
    LD BC, lobyte(NAMETABLE_SIZE) * $100 + hibyte(NAMETABLE_SIZE)
    XOR A                               ;clear name table with blank tile
@writeLoop:
    OUT (VDPDATA_PORT), A
    DJNZ @writeLoop
    DEC C
    JP NZ, @writeLoop
;
    LD HL, VRAM_Buffer1                 ;reset Buffer1's ptr
    LD (VRAM_Buffer1_Ptr), HL
    LD (VRAM_Buffer1), A
;
    LD (HorizontalScroll), A            ;reset scroll vars
    LD (VDPHScroll), A
    OUT (VDPCON_PORT), A
    LD A, $88
    OUT (VDPCON_PORT), A
    RET

;-------------------------------------------------------------------------------------
;   HL - RAM Address to start initializing

InitializeMemory:
    LD E, L
    LD D, H
    DEC E
    LD C, L
    LD A, H
    SUB A, $C0
    LD B, A
    LD (HL), $00
    LDDR
;   NON-ZERO INITIALIZATION
    LD HL, VRAM_Buffer1
    LD (VRAM_Buffer1_Ptr), HL
    LD HL, VRAM_Buffer2
    LD (VRAM_Buffer2_Ptr), HL
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    LD A, BANK_PLAYERGFX00
    JR Z, +
    LD A, BANK_PLAYERGFX04
+:
    LD (PlayerGfxBank), A
;   SOUND TRACK INITIALIZATION
    JP SndInitMemory@InitChanBits


InitializeMemoryExceptSND:
    DI
;   RAM BANK $1E
    LD HL, $DE00
    LD DE, $DE01
    LD BC, InitGameOffset - $DE01
    LD (HL), $00
    LDIR
;   RAM BANK $00-$15
    LD H, $C0
    EXX
    LD B, $16
-:
    EXX
    LD D, H
    LD L, $00
    LD E, $01
    LD BC, $003F
    LD (HL), $00
    LDIR
    INC H
    EXX
    DJNZ -
    EXX
;   NON-ZERO INITIALIZATION
    LD HL, VRAM_Buffer1
    LD (VRAM_Buffer1_Ptr), HL
    LD HL, VRAM_Buffer2
    LD (VRAM_Buffer2_Ptr), HL
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    LD A, BANK_PLAYERGFX00
    JR Z, +
    LD A, BANK_PLAYERGFX04
+:
    LD (PlayerGfxBank), A
;
    IN A, (VDPCON_PORT)
    EI
    RET


;-------------------------------------------------------------------------------------

OperModeExecutionTree:
    LD A, (OperMode)        ;this is the heart of the entire program,
    RST JumpEngine          ;most of what goes on starts here

    .dw TitleScreenMode
    .dw GameMode
    .dw VictoryMode
    .dw GameOverMode


;   TITLE SCREEN MODE
.INCLUDE "TitleScreenMode.asm"
;   GAME MODE
.INCLUDE "GameMode.asm"
;   VICTORY MODE
.INCLUDE "VictoryMode.asm"
;   GAME OVER MODE
.INCLUDE "GameOverMode.asm"

;   GAME ROUTINES           USED IN 'GAME MODE'
.INCLUDE "GM_GameRoutines.asm"

;   SPRITE DRAW ROUTINES    USED IN 'GAME MODE'
.INCLUDE "GM_SprDrawRoutines.asm"

;   SCREEN ROUTINES
.INCLUDE "ScreenRoutines.asm"

;   AREA PARSER (TILE BACKGROUND)
.INCLUDE "AreaParser.asm"
.INCLUDE "BackSceneryData.inc"

;   ENEMY PARSER (SPRITE OBJECTS)
.INCLUDE "EnemyParser.asm"

;   MASTER SYSTEM VDP STUFF
.INCLUDE "smsFunctions.asm"

;   SOUND DRIVER
.INCLUDE "SoundDriver.asm"

;   ZX7 DECOMPRESSION ROUTINES
.INCLUDE "decomp.asm"

;-------------------------------------------------------------------------------------

.SECTION "Game Text Stripe Data TBL" BANK BANK_SLOT2 SLOT 2 FREE RETURNORG
GameTextOffsets:
    .dw TopStatusBarLine, TopStatusBarLine
    .dw WorldLivesDisplay, WorldLivesDisplay
    .dw TimeUpDisplay, TimeUpDisplay
    .dw GameOverDisplay, GameOverDisplay

    .dw WarpZoneWelcome, WarpZoneWelcome
    .dw WarpZoneWelcome, WarpZoneWelcome
    .dw WarpZoneWelcome, WarpZoneWelcome
.ENDS

WriteGameText:
    PUSH AF                                 ;save text number to stack
    ADD A, A                                ;multiply by 2 and use as offset
    LD HL, GameTextOffsets                  ;get offset to message we want to print
    ADD A, A
    addAToHL_M
    LD A, (HL)                              ;DEREFERENCE POINTER FOR MESSAGE
    INC HL
    LD H, (HL)
    LD L, A
    LD C, (HL)                              ;LOAD BYTE COUNT
    LD B, $00
    INC HL
    LD DE, VRAM_Buffer1
    LDIR                                    ;WRITE MESSAGE DATA TO BUFFER
;EndGameText:
    XOR A                                   ;put null terminator at end
    LD (DE), A
    POP AF                                  ;pull original text number from stack
    CP A, $04                               ;are we printing warp zone?
    JR NC, PrintWarpZoneNumbers
    CP A, $02                               ;are we printing the time up or game over screen?
    JR NC, CheckPlayerName                  ;if so, print player's name
    OR A                                    ;are we printing the top status bar?
    RET Z                                   ;if so, we're done
    LD A, (NumberofLives)                   ;otherwise, check number of lives
    INC A                                   ;and increment by one for display
    CP A, $0A                               ;more than 9 lives?
    JR C, PutLives
    CP A, $64                               ;more than 99 lives?
    JR C, +
    LD A, $63                               ;if so, cap at 99
+:
    SUB A, $0A                              ;get BCD value from table
    LD HL, LivesBCDTable
    addAToHL8_M
    LD A, (HL)
    RRCA
    RRCA
    RRCA
    RRCA
    AND A, $0F
    ADD A, BG_TILE_OFFSET                   ;writes tens place digit
    LD (VRAM_Buffer1 + $0B), A
    LD A, $01
    LD (VRAM_Buffer1 + $0C), A
    LD A, (HL)
    AND A, $0F
PutLives:
    ADD A, BG_TILE_OFFSET                   ;write ones place digit
    LD (VRAM_Buffer1 + $0D), A                    
    LD A, (WorldNumber)                     ;write world and level numbers (incremented for display)
    ADD A, BG_TILE_OFFSET + $01             ;to the buffer in the spaces surrounding the dash
    LD (VRAM_Buffer1 + $20), A
    LD A, (LevelNumber)
    ADD A, BG_TILE_OFFSET + $01
    LD (VRAM_Buffer1 + $24), A              ;we're done here
    RET

CheckPlayerName:
    RRCA                                    ;set carry flag for later jump
    LD A, (NumberOfPlayers)                 ;are we doing a 2 player game?
    DEC A
    RET NZ                                  ;if not, exit
;
    LD HL, MarioName
    LD A, (CurrentPlayer)
    JR C, +                                 ;jump if displaying game over screen
    XOR A, $01                              ;for time up, switch name if CurrentPlayer == 0
+:
    OR A                                    ;for game over, switch name if CurrentPlayer == 1
    JR Z, +
    LD HL, LuigiName
+:
    LD BC, $000A
    LD DE, VRAM_Buffer1 + $03
    LDIR                                    ;WRITE MESSAGE DATA TO BUFFER
    RET

PrintWarpZoneNumbers:
    SUB A, $04                              ;subtract 4 and then shift to the left
    ADD A, A                                ;thrice to get proper warp zone number
    ADD A, A                                ;offset
    ADD A, A
    LD HL, WarpZoneNumbers
    addAToHL8_M
    LD DE, VRAM_Buffer1 + $30
    LDI                                     ;print warp zone numbers into the
    LDI                                     ;placeholders from earlier
    INC E
    INC E
    INC E
    LDI
    LDI
    INC E
    INC E
    INC E
    LDI
    LDI
    LD (VRAM_Buffer1_Ptr), DE               ;load new buffer pointer at end of message
    RET

.SECTION "LivesBCDTable" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
LivesBCDTable:
    .db $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25
    .db $26, $27, $28, $29, $30, $31, $32, $33, $34, $35, $36, $37, $38, $39, $40, $41
    .db $42, $43, $44, $45, $46, $47, $48, $49, $50, $51, $52, $53, $54, $55, $56, $57
    .db $58, $59, $60, $61, $62, $63, $64, $65, $66, $67, $68, $69, $70, $71, $72, $73
    .db $74, $75, $76, $77, $78, $79, $80, $81, $82, $83, $84, $85, $86, $87, $88, $89
    .db $90, $91, $92, $93, $94, $95, $96, $97, $98, $99
.ENDS

;-------------------------------------------------------------------------------------
;$00(IXL) - used to store status bar nybbles
;$02 - used as temp vram offset
;$03 - used to store length of status bar number

.SECTION "Status Bar VDP Address and Length Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
StatusBarData:
    .dw swapBytes(xyToNameTbl_M(16, 20))    ; top score display on title screen
    .db StripeCount($0C), $06
    .dw swapBytes(xyToNameTbl_M(3, 0))      ; player score
    .db StripeCount($0C), $06
    .dw swapBytes(xyToNameTbl_M(3, 0))      ; 2nd player score
    .db StripeCount($0C), $06
    .dw swapBytes(xyToNameTbl_M(14, 0))     ; coin tally
    .db StripeCount($04), $02
    .dw swapBytes(xyToNameTbl_M(14, 0))     ; 2nd coin tally
    .db StripeCount($04), $02
    .dw swapBytes(xyToNameTbl_M(27, 0))     ; game timer
    .db StripeCount($06), $03
.ENDS

.SECTION "Status Bar RAM Offsets Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
;   RAM ADDRESSES FOR DIGITS
StatusBarOffset:
    .dw TopScoreDisplay                         ; top score display on title screen
    .dw PlayerScoreDisplay                      ; player score
    .dw OffScr_ScoreDisplay                     ; 2nd player score
    .dw PlayerCoinDisplay                       ; coin tally
    .dw OffScr_CoinDisplay                      ; 2nd coin tally
    .dw GameTimerDisplay                        ; game timer
.ENDS

PrintStatusBarNumbers:
    LD IXL, A                   ;store player-specific offset
    CALL OutputNumbers          ;use first nybble to print the coin display
    LD A, IXL
    RRCA                        ;move high nybble to low                     
    RRCA                        ;and print to score display
    RRCA
    RRCA
    AND A, %00001111            ;mask out high nybble

OutputNumbers:
    INC A                       ;add 1 to low nybble
    AND A, %00001111            ;mask out high nybble
    CP A, $06
    RET NC
    PUSH AF                     ;save incremented value to stack for now and
    ADD A, A                    ;shift to left and use as offset
    ADD A, A
    LD HL, StatusBarData
    addAToHL8_M
    LD DE, (VRAM_Buffer1_Ptr)   ;get current buffer pointer
    LDI                         ;WRITE VDP ADDRESS
    LDI
    LDI                         ;write VDP count
    LD B, (HL)                  ;load word count
    POP AF
    ADD A, A
    LD HL, StatusBarOffset      ;load offset to value we want to write
    addAToHL8_M
    LD A, (HL)                  ;DEREFERENCE POINTER
    INC HL
    LD H, (HL)
    LD L, A
DigitPLoop:
    LD A, (HL)                  ;write digits to the buffer
    ADD A, BG_TILE_OFFSET
    LD (DE), A
    INC E
    LD A, $01                   ;ATTRIBUTE BYTE
    LD (DE), A
    INC L
    INC E
    DJNZ DigitPLoop             ;do this until all the digits are written
    XOR A                       ;put null terminator at end
    LD (DE), A
    LD (VRAM_Buffer1_Ptr), DE   ;store it in case we want to use it again
    RET

;-------------------------------------------------------------------------------------

;   A - N/A
;   X - N/A
;   Y - RAM OFFSET INTO DisplayDigits (DE)
DigitsMathRoutine:
    LD A, (OperMode)
    CP A, MODE_TITLESCREEN
    JP Z, EraseDMods
;
    LD HL, DigitModifier_05
    LD BC, $0600    ; LOOP/CARRY
AddModLoop:
    LD A, (DE)
    ADD A, (HL)
    ADD A, C
    JP M, BorrowOne
    CP A, $0A
    JP NC, CarryOne
    LD C, $00
StoreNewD:
    LD (DE), A
    DEC E
    DEC H
    DJNZ AddModLoop
    ; FALL THROUGH

EraseDMods:
    XOR A
    LD HL, DigitModifier_05
    LD B, $06   ;$07
EraseMLoop:
    LD (HL), A
    DEC H
    DJNZ EraseMLoop
    RET
;
BorrowOne:
    ADD A, $0A
    LD C, $FF
    JP StoreNewD
CarryOne:
    SUB A, $0A
    LD C, $01
    JP StoreNewD
    

;-------------------------------------------------------------------------------------

;   HL - N/A
;   DE - PlayerGfxOffset
;   BC - N/A
;   IXL 
;   PlayerGfxOffset - %MBPPMMMMMMMMMMMM [B = BANK LSB, P = PALETTE, M = MAPPING POINTER]
;   PlayerGfxBank   - %00000BBB [B = Bank : B2, = 1, B1 = CHARACTER, B0 = DIRECTION] 
StreamPlayerTiles:
    LD (PlayerGfxOffset_Old), DE
;   SET VDP ADDRESS
    LD C, VDPCON_PORT
    LD HL, VRAM_ADR_SPR_PLR | VRAMWRITE
    OUT (C), L
    OUT (C), H
    DEC C   ; VDPDATA_PORT
;   SET GFX BANK
    LD A, (PlayerGfxBank)
    LD (MAPPER_SLOT2), A
;   ISOLATE PALETTE BITS INTO IXL
    LD A, D
    AND A, %10110000
    LD IXL, A
;   REMOVE PALETTE BITS AND BANK LSB FROM OFFSET
    LD A, D
    AND A, %10001111
    LD D, A
;   WRITE TILE DATA
    ; TILE 0
    LD A, (DE)
    LD L, $00
    RRA
    RR L
    RRA
    RR L
    RRA
    RR L
    OR A, IXL
    LD H, A
    INC E
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 1
    XOR A
    LD L, A
    LD A, (DE)
    RRA
    RR L
    RRA
    RR L
    RRA
    RR L
    OR A, IXL
    LD H, A
    INC E
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 2
    XOR A
    LD L, A
    LD A, (DE)
    RRA
    RR L
    RRA
    RR L
    RRA
    RR L
    OR A, IXL
    LD H, A
    INC E
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 3
    XOR A
    LD L, A
    LD A, (DE)
    RRA
    RR L
    RRA
    RR L
    RRA
    RR L
    OR A, IXL
    LD H, A
    INC E
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 4
    XOR A
    LD L, A
    LD A, (DE)
    RRA
    RR L
    RRA
    RR L
    RRA
    RR L
    OR A, IXL
    LD H, A
    INC E
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 5
    XOR A
    LD L, A
    LD A, (DE)
    RRA
    RR L
    RRA
    RR L
    RRA
    RR L
    OR A, IXL
    LD H, A
    INC E
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 6
    XOR A
    LD L, A
    LD A, (DE)
    RRA
    RR L
    RRA
    RR L
    RRA
    RR L
    OR A, IXL
    LD H, A
    INC E
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 7
    XOR A
    LD L, A
    LD A, (DE)
    RRA
    RR L
    RRA
    RR L
    RRA
    RR L
    OR A, IXL
    LD H, A
    .REPEAT $20
    OUTI
    .ENDR
    ; DEFAULT BANK
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    ;RET
    JP TileStreamRet


;   C - VDP PORTS
;   DE - N/A 
;   HL - BGTileQueue0 Ptr/Tile Data Ptr
;   IX - Offset into OUTI Block
StreamAnimatedBGTiles:
;   EXIT IF ON NES GFX
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JP NZ, TileStreamRet
;
    LD C, VDPCON_PORT
    LD IXH, >OutiBlock128
;   SLOT 0 (4 or less) [MAX CYCLES: 2235]
    ; CHECK ANIMATE FLAG
    LD HL, BGTileQueue0.UpdateFlag
    LD A, (HL)
    OR A
    JR Z, @CheckSlot1
    LD (HL), $00
    INC L
    ; SET VDP ADDRESS
    OUTI
    OUTI
    DEC C
    ; GET COUNT AND POINTER   
    LD A, (HL)
    LD IXL, A
    INC L
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    ; WRITE TO VRAM
    CALL IndirectCallIX
    INC C
@CheckSlot1:
;   SLOT 1 (4 or less) [MAX CYCLES: 2235]
    ; CHECK ANIMATE FLAG
    LD HL, BGTileQueue1.UpdateFlag
    LD A, (HL)
    OR A
    JR Z, @CheckSlot2
    LD (HL), $00
    INC L
    ; SET VDP ADDRESS
    OUTI
    OUTI
    DEC C
    ; GET COUNT AND POINTER   
    LD A, (HL)
    LD IXL, A
    INC L
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    ; WRITE TO VRAM
    CALL IndirectCallIX
    INC C
@CheckSlot2:
;   SLOT 2 (FIXED 4/6) [MAX CYCLES: 3250]
    ; CHECK ANIMATE FLAG
    LD HL, BGTileQueue2.UpdateFlag
    LD A, (HL)
    OR A
    JP Z, TileStreamRet
    LD (HL), $00
    INC L
    ; SET VDP ADDRESS
    OUTI
    OUTI
    DEC C
    ; GET POINTER   
    INC L
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    ; WRITE TO VRAM
    CALL OutiBlock128
    LD A, (BGTileQueue2GrassFlag)
    OR A
    CALL NZ, OutiBlock128 + $80
    JP TileStreamRet

;-------------------------------------------------------------------------------------

;   ASSET BANK, DATA ADDRESS, VRAM ADDRESS

.SECTION "Asset Table for All-Star GFX" BANK BANK_CODE SLOT 0 BITWINDOW 8 RETURNORG

AssetLoaderTable:
    .db :Tiles_BG_Comm
    .dw Tiles_BG_Comm, VRAM_ADR_BG_COMM | VRAMWRITE
    ;
    .db :Tiles_SPR_Comm
    .dw Tiles_SPR_Comm, VRAM_ADR_SPR_COMM | VRAMWRITE
    ;
    .db :Tiles_BG_Inter
    .dw Tiles_BG_Inter, VRAM_ADR_BG_INTER | VRAMWRITE
    ;
    .db :Tiles_BG_TitleScreen
    .dw Tiles_BG_TitleScreen, VRAM_ADR_BG_TITLE | VRAMWRITE
    ;
    .db :Tiles_Mario_Emblem
    .dw Tiles_Mario_Emblem, $28E0 | VRAMWRITE
    ;
    .db :Tiles_Luigi_Emblem
    .dw Tiles_Luigi_Emblem, $28E0 | VRAMWRITE
    ;
    .db :Tiles_BG_Overworld
    .dw Tiles_BG_Overworld, VRAM_ADR_BG_LVL | VRAMWRITE
    ;
    .db :Tiles_BG_Snow
    .dw Tiles_BG_Snow, $3300 | VRAMWRITE ;$3680 | VRAMWRITE
    ;
    .db :Tiles_BG_Underground
    .dw Tiles_BG_Underground, $3A80 | VRAMWRITE
    ;
    .db :Tiles_BG_Castle
    .dw Tiles_BG_Castle, $2F20 | VRAMWRITE
    ;
    .db :Tiles_BG_Water
    .dw Tiles_BG_Water, VRAM_ADR_BG_LVL | VRAMWRITE ;$3300 | VRAMWRITE
    ;
    .db :Tiles_BG_WaterCastle
    .dw Tiles_BG_WaterCastle, VRAM_ADR_BG_LVL | VRAMWRITE ;$3680 | VRAMWRITE
    ;
    .db :Tiles_SPR_Enemies
    .dw Tiles_SPR_Enemies, $0820 | VRAMWRITE
    ;
    .db :Tiles_SPR_Lakitu
    .dw Tiles_SPR_Lakitu, $1260 | VRAMWRITE
    ;
    .db :Tiles_SPR_Podoboo
    .dw Tiles_SPR_Podoboo, $0860 | VRAMWRITE
    ;
    .db :Tiles_SPR_Bowser
    .dw Tiles_SPR_Bowser, $1260 | VRAMWRITE
    ;
    .db :Tiles_Cloud
    .dw Tiles_Cloud, $0A40 | VRAMWRITE

.ENDS

.SECTION "Asset Table for NES GFX" BANK BANK_CODE SLOT 0 BITWINDOW 8 RETURNORG

AssetLoaderTableNES:
    .db :Tiles_BG_Comm_NES
    .dw Tiles_BG_Comm_NES, VRAM_ADR_BG_COMM | VRAMWRITE
    ;
    .db :Tiles_SPR_Comm_NES
    .dw Tiles_SPR_Comm_NES, VRAM_ADR_SPR_COMM | VRAMWRITE
    ;
    .db :Tiles_BG_Inter_NES
    .dw Tiles_BG_Inter_NES, VRAM_ADR_BG_INTER | VRAMWRITE
    ;
    .db :Tiles_BG_TitleScreen_NES
    .dw Tiles_BG_TitleScreen_NES, VRAM_ADR_BG_TITLE | VRAMWRITE
    ;
    .db :Tiles_Mario_Emblem_NES
    .dw Tiles_Mario_Emblem_NES, $28E0 | VRAMWRITE
    ;
    .db :Tiles_Luigi_Emblem_NES
    .dw Tiles_Luigi_Emblem_NES, $28E0 | VRAMWRITE
    ;
    .db :Tiles_BG_Overworld_NES
    .dw Tiles_BG_Overworld_NES, VRAM_ADR_BG_LVL | VRAMWRITE
    ;
    .db BANK_SLOT2
    .dw $0000, $0000
    ;
    .db BANK_SLOT2
    .dw $0000, $0000
    ;
    .db :Tiles_BG_Castle_NES
    .dw Tiles_BG_Castle_NES, $2F20 | VRAMWRITE
    ;
    .db :Tiles_BG_Water_NES
    .dw Tiles_BG_Water_NES, $3480 | VRAMWRITE
    ;
    .db :Tiles_BG_WaterCastle_NES
    .dw Tiles_BG_WaterCastle_NES, $3680 | VRAMWRITE
    ;
    .db :Tiles_SPR_Enemies_NES
    .dw Tiles_SPR_Enemies_NES, $0820 | VRAMWRITE
    ;
    .db :Tiles_SPR_Lakitu_NES
    .dw Tiles_SPR_Lakitu_NES, $1260 | VRAMWRITE
    ;
    .db :Tiles_SPR_Podoboo_NES
    .dw Tiles_SPR_Podoboo_NES, $0860 | VRAMWRITE
    ;
    .db :Tiles_SPR_Bowser_NES
    .dw Tiles_SPR_Bowser_NES, $1260 | VRAMWRITE
    ;
    .db :Tiles_Cloud_NES
    .dw Tiles_Cloud_NES, $0A40 | VRAMWRITE
.ENDS


;   INPUT: A - ASSET ID
;   OUTPUT: HL - SRC ADDRESS, DE - DEST ADDRESS, A - BANK
AssetLoader:
    LD HL, OptionBitflags
    BIT OPTFLAG_GFX, (HL)
    LD HL, AssetLoaderTable
    JR Z, +
    LD HL, AssetLoaderTableNES
+:
    LD B, A
    ADD A, A
    ADD A, A
    ADD A, B
    addAToHL8_M
    LD B, (HL)
    INC L
    LD E, (HL)
    INC L
    LD D, (HL)
    INC L
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    EX DE, HL
    LD A, B
    RET

;-------------------------------------------------------------------------------------
.SECTION "SDSC Tags" FREE
sdscName:
    .DB "Super Mario Bros.", 0
sdscDesc:
    .DB "A conversion for the Sega Master System", 0
sdscAuth:
    .DB "LackofTrack", 0
.ENDS

.SECTION "VDP Init. Data" FREE
;   VDP REG INIT. DATA
vdpInitData:
    .db $24         ; ENABLE MODE 4 AND HIDE LEFTMOST 8 PIXELS...
    .db $80         ; FOR REG 00 (MODE CONTROL 1)
    ;----------------------
    .db $A0         ; SET BIT 7 AND ENABLE LINE INTERRUPTS
    .db $81         ; FOR REG 01 (MODE CONTROL 2)
    ;----------------------
    .db ((VRAM_ADR_NAMETBL >> $0A) | $01) & $FF
    .db $82         ; FOR REG 02 (NAME TABLE BASE ADDR)
    ;----------------------
    .db $FF         ; VRAM COLOR TABLE BASE ADDR (NORMAL OPERATION)
    .db $83         ; FOR REG 03 (COLOR TABLE BASE ADDR)
    ;----------------------
    .db $FF         ; PATTERN GEN. TABLE BASE ADDR (NORMAL OPERATION)
    .db $84         ; FOR REG 04 (PATTERN GEN. TABLE BASE ADDR)
    ;----------------------
    .db ((VRAM_ADR_SPRTBL >> $07) | $01) & $FF
    .db $85         ; FOR REG 05 (SAT BASE ADDR)
    ;----------------------
    .db $FB         ; SPRITE PATTERN GENERATOR TABLE AT $0000 (256 SPRITE LIMIT)
    .db $86         ; FOR REG 06 (SPRITE PAT. GENERATOR TABLE BASE ADDR)
    ;----------------------
    .db $00         ; COLOR 0 FROM SPRITE PALETTE (BLACK)...
    .db $87         ; FOR REG 07 (OVERSCAN/BACKDROP COLOR)
    ;----------------------
    .db $00         ; NO X SCROLL...
    .db $88         ; FOR REG 08 (BACKGROUND X SCROLL)
    ;----------------------
    .db $00         ; NO Y SCROLL...
    .db $89         ; FOR REG 09 (BACKGROUND Y SCROLL)
    ;----------------------
    .db $07         ; LINE COUNTER AT $07
    .db $8A         ; FOR REG 0A (LINE COUNTER)
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "OUTI Blocks" BANK BANK_SLOT2 SLOT 2 FORCE ORG $0000

;   0x0000 - 0x0100
OutiBlock128:
WriteHoriBlock:
.REPT $80
    OUTI
.ENDR
    RET

;   0x0101 - 0x0341
; .REPT $40           ; 09 (8 + 1) bytes per iteration
;     EXX
;     OUT (C), L      ; WRITE VDP ADDRESS
;     OUT (C), H
;     ADD HL, DE      ; INCREMENT ADDRESS FOR NEXT ROW
;     EXX
;     OUTI            ; WRITE BYTE FOR CURRENT ROW
; .ENDR
; WriteVeriBlock_B:
;     RET
    
;   0x0342 - 0x0602
; .REPT $40           ; 11 (8 + 3) bytes per iteration
;     EXX
;     OUT (C), L      ; WRITE VDP ADDRESS
;     OUT (C), H
;     ADD HL, DE      ; INCREMENT ADDRESS FOR NEXT ROW
;     EXX
;     OUTI            ; WRITE WORD FOR CURRENT ROW
;     OUTI
; .ENDR
; WriteVeriBlock_W:
;     RET
    
WriteVeriBlock_W:
.REPT $17           ; 11 (8 + 3) bytes per iteration
    EXX
    OUT (C), L      ; WRITE VDP ADDRESS
    OUT (C), H
    ADD HL, DE      ; INCREMENT ADDRESS FOR NEXT ROW
    EXX
    OUTI            ; WRITE WORD FOR CURRENT ROW
    OUTI
.ENDR
    RET

.ENDS
;-------------------------------------------------------------------------------------

; PALETTE DATA LAYOUT:
;     VDP ADDRESS, BYTE COUNT, DATA, TERMINATOR

.SECTION "Water AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
WaterPaletteData:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $00, $22, $26, $27, $24, $28, $29, $2B, $25, $3E, $2F, $3A, $3F, $21, $2E
    .db $00, $00, $21, $27, $2B, $24, $2C, $26, $3B, $2F, $3A, $3F, $23, $22, $30, $28
    .db $00
.ENDS

.SECTION "Ground AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
GroundPaletteData:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $00, $01, $06, $0B, $04, $08, $0C, $05, $0A, $2E, $0F, $2A, $3F, $3A, $3E
    .db $00, $00, $01, $06, $0B, $24, $0C, $06, $1B, $0F, $2A, $3F, $03, $02, $10, $08
    .db $00
.ENDS

.SECTION "Underground AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
UndergroundPaletteData:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $00, $10, $24, $38, $04, $08, $0C, $05, $0A, $2E, $0F, $2A, $3F, $15, $3C;$3D
    .db $00, $00, $10, $24, $38, $24, $0C, $06, $1B, $0F, $2A, $3F, $03, $02, $10, $08
    .db $00
.ENDS

.SECTION "Castle AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
CastlePaletteData:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $00, $10, $15, $2A, $01, $06, $1B, $05, $0A, $2B, $0F, $02, $3F, $07, $2D
    .db $00, $00, $10, $15, $2A, $24, $0C, $06, $1B, $0F, $2A, $3F, $03, $02, $10, $08
    .db $00
.ENDS

.SECTION "Day Snow AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
DaySnowPaletteData:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $39, $00, $01, $16, $2B, $04, $18, $1C, $15, $1A, $3E, $1F, $2A, $3F, $3A, $3E
    ;.db $39, $00, $01, $16, $2B, $04, $18, $1C, $15, $1A, $3E, $1F, $2A, $3F, $3A, $3E
    .db $39, $00, $01, $16, $2B, $24, $0C, $06, $1B, $0F, $2A, $3F, $03, $02, $10, $08
    .db $00
.ENDS

.SECTION "Night Snow AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
NightSnowPaletteData:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $00, $01, $16, $2B, $04, $18, $1C, $15, $1A, $3E, $1F, $2A, $3F, $3A, $3E
    ;.db $00, $00, $01, $16, $2B, $04, $18, $1C, $15, $1A, $3E, $1F, $2A, $3F, $3A, $3E
    .db $00, $00, $01, $16, $2B, $24, $0C, $06, $1B, $0F, $2A, $3F, $03, $02, $10, $08
    .db $00
.ENDS

.SECTION "Mushroom AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
MushroomPaletteData:
    .dw swapBytes($C005)
    .db StripeCount($06)
    .db $01, $02, $03, $05, $0A, $2B
    .db $00
.ENDS

; .SECTION "Bowser Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
; BowserPaletteData:
    ; .dw swapBytes($C010)
    ; .db StripeCount($10)
    ; .db $00, $00, $04, $15, $2A, $24, $0E, $06, $1B, $0F, $07, $3F, $03, $02, $10, $09
    ; .db $00
; .ENDS

.SECTION "Retainer Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
RetainerPaletteData:
    .dw swapBytes($C010)
    .db StripeCount($10)
    .db $00, $00, $01, $32, $3A, $24, $0E, $06, $1B, $0F, $17, $3F, $03, $02, $10, $09
    .db $00
.ENDS


.SECTION "Princess Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
PrincessPaletteData:
    .dw swapBytes($C010)
    .db StripeCount($10)
    .db $00, $00, $13, $07, $3B, $24, $0E, $06, $1B, $0F, $2B, $3F, $03, $02, $10, $09
    .db $00
.ENDS

.SECTION "Options Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
OptionsPaletteData:
    .dw swapBytes($C010)
    .db StripeCount($10)
    .db $00, $00, $01, $06, $0B, $24, $0C, $06, $1B, $0F, $2A, $3F, $03, $02, $10, $08
    .db $00
.ENDS

;-------------------------------------------------------------------------------------

.SECTION "Water AreaType Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
WaterPaletteData_NES:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $13, $30, $27, $2E, $08, $00, $3F, $30, $00, $0B, $30, $00, $00, $00, $00
    .db $00, $03, $0B, $06, $2A, $3F, $0B, $03, $3F, $0B, $00, $3F, $2A, $03, $0B, $06
    .db $00
.ENDS

.SECTION "Ground AreaType Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
GroundPaletteData_NES:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $0E, $08, $00, $2B, $06, $00, $3F, $38, $00, $0B, $06, $00, $00, $00, $00
    .db $00, $03, $0B, $06, $08, $3F, $0B, $03, $3F, $0B, $00, $2B, $06, $03, $0B, $06
    .db $00
.ENDS

.SECTION "Underground AreaType Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
UndergroundPaletteData_NES:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $0E, $08, $04, $3D, $28, $00, $3F, $38, $28, $0B, $06, $28, $00, $00, $00
    .db $00, $03, $0B, $06, $28, $2B, $06, $03, $3F, $0B, $14, $3D, $28, $03, $0B, $06
    .db $00
.ENDS

.SECTION "Castle AreaType Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
CastlePaletteData_NES:
    .dw swapBytes($C000)
    .db StripeCount($20)
    .db $00, $3F, $2A, $15, $3F, $2A, $15, $3F, $03, $15, $0B, $06, $15, $00, $00, $00
    .db $00, $03, $0B, $06, $28, $2B, $06, $03, $3F, $0B, $15, $3F, $2A, $03, $0B, $06
    .db $00
.ENDS

.SECTION "Day Snow AreaType Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
DaySnowPaletteData_NES:
    .dw swapBytes($C000)
    .db StripeCount($04)
    .db $39, $3F, $15, $2A
    .dw swapBytes($C010)
    .db StripeCount($01)
    .db $39
    .db $00
.ENDS

.SECTION "Night Snow AreaType Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
NightSnowPaletteData_NES:
    .dw swapBytes($C000)
    .db StripeCount($04)
    .db $00, $3F, $15, $2A
    .db $00
.ENDS

.SECTION "Mushroom AreaType Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
MushroomPaletteData_NES:
    .dw swapBytes($C000)
    .db StripeCount($04)
    .db $39, $0B, $03, $00
    .db $00
.ENDS

; .SECTION "Bowser Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
; BowserPaletteData_NES:
    ; .dw swapBytes($C014)
    ; .db StripeCount($03)
    ; .db $08, $3F, $0B
    ; .db $00
; .ENDS

.SECTION "Options Palette Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
OptionsPaletteData_NES:
    .dw swapBytes($C010)
    .db StripeCount($10)
    .db $00, $03, $0B, $06, $08, $3F, $0B, $03, $3F, $0B, $00, $2B, $06, $03, $0B, $06
    .db $00
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "'Thank You Mario' MSG Data" BANK BANK_SLOT2 SLOT 2 FREE
MarioThanksMessage:
;"THANK YOU MARIO!"
    ; .db $25, $48, $10
    ; .db $1d, $11, $0a, $17, $14, $24
    ; .db $22, $18, $1e, $24
    ; .db $16, $0a, $1b, $12, $18, $2b
    ; .db $00
    .dw swapBytes(xyToNameTbl_M(8, 7))
    .db StripeCount($20)
    .dw $01F9, $0179, $01FA, $01FE, $017A, $0000
    .dw $017B, $01F7, $017C, $0000
    .dw $01F8, $01FA, $01FB, $017D, $01F7, $01FF
    .db $00
.ENDS

.SECTION "'Thank You Luigi' MSG Data" BANK BANK_SLOT2 SLOT 2 FREE
LuigiThanksMessage:
;"THANK YOU LUIGI!"
    ; .db $25, $48, $10
    ; .db $1d, $11, $0a, $17, $14, $24
    ; .db $22, $18, $1e, $24
    ; .db $15, $1e, $12, $10, $12, $2b
    ; .db $00
    .dw swapBytes(xyToNameTbl_M(8, 7))
    .db StripeCount($20)
    .dw $01F9, $0179, $01FA, $01FE, $017A, $0000
    .dw $017B, $01F7, $017C, $0000
    .dw $01F5, $017C, $017D, $01E7, $017D, $01FF
    .db $00
.ENDS

.SECTION "Mushroom Retainer MSG Data" BANK BANK_SLOT2 SLOT 2 FREE
MushroomRetainerSaved:
;"BUT OUR PRINCESS IS IN"
;     .db $25, $c5, $16
;     .db $0b, $1e, $1d, $24, $18, $1e, $1b, $24
;     .db $19, $1b, $12, $17, $0c, $0e, $1c, $1c, $24
;     .db $12, $1c, $24, $12, $17
; ;"ANOTHER CASTLE!"
;     .db $26, $05, $0f
;     .db $0a, $17, $18, $1d, $11, $0e, $1b, $24
;     .db $0c, $0a, $1c, $1d, $15, $0e, $2b, $00
;"BUT OUR PRINCESS IS IN"
    .dw swapBytes(xyToNameTbl_M(5, 11))
    .db StripeCount($2C)
    .dw $017E, $017C, $01F9, $0000
    .dw $01F7, $017C, $01FB, $0000
    .dw $01FC, $01FB, $017D, $01FE, $01F6, $01F4, $017F, $017F, $0000
    .dw $017D, $017F, $0000
    .dw $017D, $01FE
;"ANOTHER CASTLE!"
    .dw swapBytes(xyToNameTbl_M(5, 13))
    .db StripeCount($1E)
    .dw $01FA, $01FE, $01F7, $01F9, $0179, $01F4, $01FB, $0000
    .dw $01F6, $01FA, $017F, $01F9, $01F5, $01F4, $01FF
    .db $00
.ENDS

.SECTION "Princess Saved MSG 1 Data" BANK BANK_SLOT2 SLOT 2 FREE
PrincessSaved1:
;"YOUR QUEST IS OVER."
    ; .db $25, $a7, $13
    ; .db $22, $18, $1e, $1b, $24
    ; .db $1a, $1e, $0e, $1c, $1d, $24
    ; .db $12, $1c, $24, $18, $1f, $0e, $1b, $af
    ; .db $00
    .dw swapBytes(xyToNameTbl_M(7, 10))
    .db StripeCount($26)
    .dw $017B, $01F7, $017C, $01FB, $0000
    .dw $0180, $017C, $01F4, $017F, $01F9, $0000
    .dw $017D, $017F, $0000
    .dw $01F7, $0181, $01F4, $01FB, $01E6
    .db $00
.ENDS

.SECTION "Princess Saved MSG 2 Data" BANK BANK_SLOT2 SLOT 2 FREE
PrincessSaved2:
;"WE PRESENT YOU A NEW QUEST."
    ; .db $25, $e3, $1b
    ; .db $20, $0e, $24
    ; .db $19, $1b, $0e, $1c, $0e, $17, $1d, $24
    ; .db $22, $18, $1e, $24, $0a, $24, $17, $0e, $20, $24
    ; .db $1a, $1e, $0e, $1c, $1d, $af
    ; .db $00
    .dw swapBytes(xyToNameTbl_M(3, 12))
    .db StripeCount($36)
    .dw $0142, $01F4, $0000
    .dw $01FC, $01FB, $01F4, $017F, $01F4, $01FE, $01F9, $0000
    .dw $017B, $01F7, $017C, $0000
    .dw $01FA, $0000
    .dw $01FE, $01F4, $0142, $0000
    .dw $0180, $017C, $01F4, $017F, $01F9, $01E6
    .db $00
.ENDS

.SECTION "World Select MSG 1 Data" BANK BANK_SLOT2 SLOT 2 FREE
WorldSelectMessage1:
;"PUSH BUTTON B"
    ; .db $26, $4a, $0d
    ; .db $19, $1e, $1c, $11, $24
    ; .db $0b, $1e, $1d, $1d, $18, $17, $24, $0b
    ; .db $00
    .dw swapBytes(xyToNameTbl_M(10, 15))
    .db StripeCount($1A)
    .dw $01FC, $017C, $017F, $0179, $0000
    .dw $017E, $017C, $01F9, $01F9, $01F7, $01FE, $0000
    .dw $013A
    .db $00
.ENDS

.SECTION "World Select MSG 2 Data" BANK BANK_SLOT2 SLOT 2 FREE
WorldSelectMessage2:
;"TO SELECT A WORLD"
    ; .db $26, $88, $11
    ; .db $1d, $18, $24, $1c, $0e, $15, $0e, $0c, $1d, $24
    ; .db $0a, $24, $20, $18, $1b, $15, $0d
    ; .db $00
    .dw swapBytes(xyToNameTbl_M(8, 17))
    .db StripeCount($22)
    .dw $01F9, $01F7, $0000
    .dw $017F, $01F4, $01F5, $01F4, $01F6, $01F9, $0000
    .dw $01FA, $0000
    .dw $0142, $01F7, $01FB, $01F5, $0182
    .db $00
.ENDS

.SECTION "Title Screen TileMap Data" BANK BANK_SLOT2 SLOT 2 FREE
TitleScreenData:
;   ROW 0
    .dw swapBytes(xyToNameTbl_M(5, 1))
    .db StripeCount($2C)
    .dw $08B9, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BB
;   ROW 1
    .dw swapBytes(xyToNameTbl_M(5, 2))
    .db StripeCount($2C)
    .dw $08BC, $08BD, $08BE, $08BF, $08BF, $08C0, $0ABD, $08BD, $08C1, $08C0, $0ABD, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C3
;   ROW 2
    .dw swapBytes(xyToNameTbl_M(5, 3))
    .db StripeCount($2C)
    .dw $08BC, $08C4, $08C5, $08C6, $08C6, $08C6, $08C7, $08C8, $08C9, $08C6, $08CA, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C3
;   ROW 3
    .dw swapBytes(xyToNameTbl_M(5, 4))
    .db StripeCount($2C)
    .dw $08BC, $08CB, $08CC, $08CD, $08CE, $08CF, $08D0, $08CD, $08D1, $08CF, $08D2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C3
;   ROW 4
    .dw swapBytes(xyToNameTbl_M(5, 5))
    .db StripeCount($2C)
    .dw $08BC, $08D3, $08D4, $08D3, $08D4, $08D5, $08C2, $08D3, $08D6, $08D5, $08D6, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08D7, $08D8, $08C3
;   ROW 5
    .dw swapBytes(xyToNameTbl_M(5, 6))
    .db StripeCount($2C)
    .dw $08BC, $08BD, $08D9, $0ABD, $08BD, $0ABD, $08C0, $0ABD, $08BF, $08BD, $0ABD, $08C2, $08C0, $0ABD, $08C0, $0ABD, $08BD, $0ABD, $08BD, $0ABD, $08C2, $08C3
;   ROW 6
    .dw swapBytes(xyToNameTbl_M(5, 7))
    .db StripeCount($2C)
    .dw $08BC, $08DA, $08DB, $08DB, $08DA, $08DB, $08DA, $08DC, $08DA, $08DA, $08DC, $08C2, $08DA, $08DC, $08DA, $08DC, $08DA, $08DC, $08DA, $08DD, $08C2, $08C3
;   ROW 7
    .dw swapBytes(xyToNameTbl_M(5, 8))
    .db StripeCount($2C)
    .dw $08BC, $08DA, $08DA, $08DA, $08DA, $08DA, $08DA, $08DE, $08DA, $08DA, $08DA, $08C2, $08DA, $08DE, $08DA, $08DE, $08DA, $08DA, $08DF, $08E0, $08C2, $08C3
;   ROW 8
    .dw swapBytes(xyToNameTbl_M(5, 9))
    .db StripeCount($2C)
    .dw $08BC, $08C6, $08C6, $08C6, $08E1, $08E2, $08C6, $08E3, $08C6, $08C6, $08C6, $08C2, $08C6, $08E3, $08C6, $08E3, $08C6, $08C6, $08E4, $08E5, $08C2, $08C3
;   ROW 9
    .dw swapBytes(xyToNameTbl_M(5, 10))
    .db StripeCount($2C)
    .dw $08BC, $08CF, $08CF, $08CF, $08CF, $08E6, $08CF, $08CF, $08CF, $08CD, $08CE, $08C2, $08CF, $08E7, $08CF, $08CF, $08CD, $08CE, $08CD, $08CE, $08E8, $08C3
;   ROW A
    .dw swapBytes(xyToNameTbl_M(5, 11))
    .db StripeCount($2C)
    .dw $08E9, $08EA, $08EA, $08EA, $08EA, $08EA, $08EA, $08EA, $08EA, $08EB, $08EC, $08ED, $08EA, $08EE, $08EA, $08EA, $08EB, $08EC, $08EB, $08EC, $08EA, $08EF
;   "C1985 NINTENDO"
    .dw swapBytes(xyToNameTbl_M(13, 12))
    .db StripeCount($1C)
    .dw $08F0, BG_MACRO($0101), BG_MACRO($0109), BG_MACRO($0108), BG_MACRO($0105), BLANKTILE, $08F1, $08F2, $08F1, $08F3, $08F4, $08F1, $08F5, $08F6 
;   "1 PLAYER GAME"
    .dw swapBytes(xyToNameTbl_M(11, 15))
    .db StripeCount($1A)
    .dw BG_MACRO($0101), BLANKTILE, $08F7, $08F8, $08F9, $08FA, $08F4, $08FB, BLANKTILE, $08FC, $08F9, $08FD, $08F4
    
    .IF SINGLEPLAYERONLY == $00
;   "2 PLAYER GAME"
    .dw swapBytes(xyToNameTbl_M(11, 17))
    .db StripeCount($1A)
    .dw BG_MACRO($0102), BLANKTILE, $08F7, $08F8, $08F9, $08FA, $08F4, $08FB, BLANKTILE, $08FC, $08F9, $08FD, $08F4
    .ENDIF
;   "TOP-      0"
    .dw swapBytes(xyToNameTbl_M(12, 20))
    .db StripeCount($08)
    .dw $08F3, $08F6, $08F7, BG_MACRO($010B)
    .dw swapBytes(xyToNameTbl_M(22, 20))
    .db StripeCount($02)
    .dw BG_MACRO($0100)
;   COLOR
    .dw swapBytes($C013)
    .db StripeCount($01)
    .db $07


;   "V0.12"
    .dw swapBytes(xyToNameTbl_M(22, 13))
    .db StripeCount($0A)
    .dw $08B7, BG_MACRO($0100), $08B8, BG_MACRO($0101), BG_MACRO($0102)
;   TERMINATOR
    .db $00
.ENDS

.SECTION "Title Screen TileMap Data (NES)" BANK BANK_SLOT2 SLOT 2 FREE
TitleScreenData_NES:
;   ROW 0
    .dw swapBytes(xyToNameTbl_M(5, 1))
    .db StripeCount($2C)
    .dw $00B9, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BA, $00BB
;   ROW 1
    .dw swapBytes(xyToNameTbl_M(5, 2))
    .db StripeCount($2C)
    .dw $00BC, $00BD, $02BD, $00BE, $00BE, $00BF, $02BD, $00BD, $00C0, $00BF, $02BD, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C2
;   ROW 2
    .dw swapBytes(xyToNameTbl_M(5, 3))
    .db StripeCount($2C)
    .dw $00BC, $00C3, $00C4, $00C5, $00C5, $00C5, $00C6, $00C5, $00C7, $00C5, $00C8, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C2
;   ROW 3
    .dw swapBytes(xyToNameTbl_M(5, 4))
    .db StripeCount($2C)
    .dw $00BC, $00C9, $00CA, $00C9, $00C6, $00C5, $00CB, $00C9, $00C0, $00C5, $00CC, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C2
;   ROW 4
    .dw swapBytes(xyToNameTbl_M(5, 5))
    .db StripeCount($2C)
    .dw $00BC, $00CD, $00CE, $00CD, $00CE, $00CF, $00C1, $00CD, $00D0, $00CF, $00CF, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C1, $00C2
;   ROW 5
    .dw swapBytes(xyToNameTbl_M(5, 6))
    .db StripeCount($2C)
    .dw $00BC, $00BD, $00D1, $02BD, $00BD, $02BD, $00BF, $02BD, $00BE, $00BD, $02BD, $00C1, $00BF, $02BD, $00BF, $02BD, $00BD, $02BD, $00BD, $02BD, $00C1, $00C2
;   ROW 6
    .dw swapBytes(xyToNameTbl_M(5, 7))
    .db StripeCount($2C)
    .dw $00BC, $00C5, $00D2, $00D2, $00C5, $00D2, $00C5, $00D2, $00C5, $00C5, $00D2, $00C1, $00C5, $00D2, $00C5, $00D2, $00C5, $00D2, $00C5, $00D2, $00C1, $00C2
;   ROW 7
    .dw swapBytes(xyToNameTbl_M(5, 8))
    .db StripeCount($2C)
    .dw $00BC, $00C5, $00C5, $00C5, $00C5, $00C5, $00C5, $00C8, $00C5, $00C5, $00C5, $00C1, $00C5, $00C8, $00C5, $00C8, $00C5, $00C5, $00C3, $00D3, $00C1, $00C2
;   ROW 8
    .dw swapBytes(xyToNameTbl_M(5, 9))
    .db StripeCount($2C)
    .dw $00BC, $00C5, $00C5, $00C5, $00BF, $00D4, $00C5, $00CC, $00C5, $00C5, $00C5, $00C1, $00C5, $00D5, $00C5, $00CC, $00C5, $00C5, $00D6, $00D5, $00C1, $00C2
;   ROW 9
    .dw swapBytes(xyToNameTbl_M(5, 10))
    .db StripeCount($2C)
    .dw $00BC, $00C5, $00C5, $00C5, $00C5, $00D2, $00C5, $00C5, $00C5, $00C9, $00C6, $00C1, $00C5, $00C6, $00C5, $00C5, $00C9, $00C6, $00C9, $00C6, $00BE, $00C2
;   ROW A
    .dw swapBytes(xyToNameTbl_M(5, 11))
    .db StripeCount($2C)
    .dw $00D7, $00D8, $00D8, $00D8, $00D8, $00D8, $00D8, $00D8, $00D8, $00D9, $00DA, $00DB, $00D8, $00DC, $00D8, $00D8, $00D9, $00DA, $00D9, $00DA, $00D8, $00DD
;   "C1985 NINTENDO"
    .dw swapBytes(xyToNameTbl_M(13, 12))
    .db StripeCount($1C)
    .dw $00DE, $00ED, $00EE, $00EF, $00F0, BLANKTILE, $00DF, $00E0, $00DF, $00E1, $00E2, $00DF, $00E3, $00E4 
;   "1 PLAYER GAME"
    .dw swapBytes(xyToNameTbl_M(11, 15))
    .db StripeCount($1A)
    .dw BG_MACRO($0101), BLANKTILE, $00E5, $00E6, $00E7, $00E8, $00EC, $00E9, BLANKTILE, $00EA, $00E7, $00EB, $00EC
    
    .IF SINGLEPLAYERONLY == $00
;   "2 PLAYER GAME"
    .dw swapBytes(xyToNameTbl_M(11, 17))
    .db StripeCount($1A)
    .dw BG_MACRO($0102), BLANKTILE, $00E5, $00E6, $00E7, $00E8, $00EC, $00E9, BLANKTILE, $00EA, $00E7, $00EB, $00EC
    .ENDIF
;   "TOP-      0"
    .dw swapBytes(xyToNameTbl_M(12, 20))
    .db StripeCount($08)
    .dw $00F1, $00F2, $00E5, BG_MACRO($010B)
    .dw swapBytes(xyToNameTbl_M(22, 20))
    .db StripeCount($02)
    .dw BG_MACRO($0100)


;   "V0.12"
    .dw swapBytes(xyToNameTbl_M(22, 13))
    .db StripeCount($0A)
    .dw $00B7, BG_MACRO($0100), $00B8, BG_MACRO($0101), BG_MACRO($0102)
;   TERMINATOR
    .db $00
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Top Status Bar Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
TopStatusBarLine:
;   0x00 - 0x1C
    .db @end-TopStatusBarLine - 1
    ; MARIO ICON
    .dw swapBytes(xyToNameTbl_M(1, 0))
    .db StripeCount($02)
    .dw BG_MACRO($090F)
    ; 'W'
    .dw swapBytes(xyToNameTbl_M(19, 0))
    .db StripeCount($02)
    .dw BG_MACRO($010A)
    ; CLOCK ICON
    .dw swapBytes(xyToNameTbl_M(26, 0))
    .db StripeCount($02)
    .dw BG_MACRO($010E)
    ; '0  [COIN]x' 
    .dw swapBytes(xyToNameTbl_M(9, 0))
    .db StripeCount($0A)
    .dw BG_MACRO($0100), BLANKTILE, BLANKTILE, BG_MACRO($090D), BG_MACRO($010C)
@end:
.ENDS

;   CROWN = $0D, LIFE = $0F
;   WORLD = $20, LEVEL = $24

.SECTION "World & Lives Screen Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
WorldLivesDisplay:
;   0x1D - 
    .db @end-WorldLivesDisplay - 1
    ; '  x  [CROWN][LIFE]'
    .dw swapBytes(xyToNameTbl_M(13, 11))
    .db StripeCount($0E)
    .dw BLANKTILE, BLANKTILE, BG_MACRO($010C), BLANKTILE, BLANKTILE, BG_MACRO($0100), BLANKTILE
    ; 'WORLD [WORLD]-[LEVEL]'
    .dw swapBytes(xyToNameTbl_M(11, 07))
    .db StripeCount($12)
    .dw BG_MACRO($010A), BG_MACRO($0114), BG_MACRO($0112), BG_MACRO($0115), BG_MACRO($011C), BLANKTILE, BG_MACRO($0100), BG_MACRO($010B), BG_MACRO($0100)
    ; Clear "Time Up" Area
    .dw swapBytes(xyToNameTbl_M(12, 13))
    .db StripeCount($0E)
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE
@end:
.ENDS

; .SECTION "Two Player Timeup for Mario Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
; TwoPlayerTimeUp:
;     ;.db $21, $cd, $05, $16, $0a, $1b, $12, $18 ; "MARIO"
;     .db @end-TwoPlayerTimeUp - 1
;     .dw swapBytes(xyToNameTbl_M(13, 11))
;     .db $05 << $01
;     .dw BG_MACRO($0110), BG_MACRO($0111), BG_MACRO($0112), BG_MACRO($0113), BG_MACRO($0114)
; @end:
; .ENDS

; .SECTION "Timeup Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
; OnePlayerTimeUp:
;     ;.db $22, $0c, $07, $1d, $12, $16, $0e, $24, $1e, $19 ; "TIME UP"
;     ;.db $ff
;     .db @end-OnePlayerTimeUp - 1
;     .dw swapBytes(xyToNameTbl_M(12, 13))
;     .db $07 << $01
;     .dw BG_MACRO($011A), BG_MACRO($0113), BG_MACRO($0110), BG_MACRO($0118), BLANKTILE, BG_MACRO($0116), BG_MACRO($011B)
; @end:
; .ENDS

; .SECTION "Two Player GameOver for Mario Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
; TwoPlayerGameOver:
;     ;.db $21, $cd, $05, $16, $0a, $1b, $12, $18 ; "MARIO"
; .ENDS

; .SECTION "GameOver Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
; OnePlayerGameOver:
;     ;.db $22, $0b, $09, $10, $0a, $16, $0e, $24 ; "GAME OVER"
;     ;.db $18, $1f, $0e, $1b
;     ;.db $ff
;     .dw swapBytes(xyToNameTbl_M(11, 13))
;     .db $09 << $01
;     .dw BG_MACRO($0117), BG_MACRO($0111), BG_MACRO($0110), BG_MACRO($0118), BLANKTILE, BG_MACRO($0114), BG_MACRO($0119), BG_MACRO($0118), BG_MACRO($0112)
; .ENDS

.SECTION "GameOver Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
GameOverDisplay:
    ;.db $22, $0b, $09, $10, $0a, $16, $0e, $24 ; "GAME OVER"
    ;.db $18, $1f, $0e, $1b
    ;.db $ff
    .db @end-GameOverDisplay - 1
    .dw swapBytes(xyToNameTbl_M(13, 11))
    .db StripeCount($0A)
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE
    .dw swapBytes(xyToNameTbl_M(11, 13))
    .db StripeCount($12)
    .dw BG_MACRO($0117), BG_MACRO($0111), BG_MACRO($0110), BG_MACRO($0118), BLANKTILE, BG_MACRO($0114), BG_MACRO($0119), BG_MACRO($0118), BG_MACRO($0112)
@end:
.ENDS

.SECTION "Timeup Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
TimeUpDisplay:
    ;.db $22, $0c, $07, $1d, $12, $16, $0e, $24, $1e, $19 ; "TIME UP"
    ;.db $ff
    .db @end-TimeUpDisplay - 1
    .dw swapBytes(xyToNameTbl_M(13, 11))
    .db StripeCount($0A)
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE
    .dw swapBytes(xyToNameTbl_M(12, 13))
    .db StripeCount($0E)
    .dw BG_MACRO($011A), BG_MACRO($0113), BG_MACRO($0110), BG_MACRO($0118), BLANKTILE, BG_MACRO($0116), BG_MACRO($011B)
@end:
.ENDS

.SECTION "WarpZone Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
WarpZoneWelcome:
    ; .db $25, $84, $15, $20, $0e, $15, $0c, $18, $16 ; "WELCOME TO WARP ZONE!"
    ; .db $0e, $24, $1d, $18, $24, $20, $0a, $1b, $19
    ; .db $24, $23, $18, $17, $0e, $2b
    ; .db $26, $25, $01, $24         ; placeholder for left pipe
    ; .db $26, $2d, $01, $24         ; placeholder for middle pipe
    ; .db $26, $35, $01, $24         ; placeholder for right pipe
    ; .db $27, $d9, $46, $aa         ; attribute data
    ; .db $27, $e1, $45, $aa
    ; .db $ff
    .db @end-WarpZoneWelcome - 1
    ; "WELCOME TO WARP ZONE!"
    .dw swapBytes(xyToNameTbl_M(04, 09))
    .db StripeCount($2A)
    .dw $0142, $01F4, $01F5, $01F6, $01F7, $01F8, $01F4, BLANKTILE
    .dw $01F9, $01F7, BLANKTILE
    .dw $0142, $01FA, $01FB, $01FC, BLANKTILE
    .dw $01FD, $01F7, $01FE, $01F4, $01FF
    ; placeholder for left pipe
    .dw swapBytes(xyToNameTbl_M(05, 14))
    .db StripeCount($02)
    .dw $0000   ; $30
    ; placeholder for middle pipe
    .dw swapBytes(xyToNameTbl_M(13, 14))
    .db StripeCount($02)
    .dw $0000   ; $35
    ; placeholder for right pipe
    .dw swapBytes(xyToNameTbl_M(21, 14))
    .db StripeCount($02)
    .dw $0000   ; $3A
@end:
.ENDS


.SECTION "Mario Name Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
MarioName:
    ;.db $21, $cd, $05, $16, $0a, $1b, $12, $18 ; "MARIO"
    .dw BG_MACRO($0110), BG_MACRO($0111), BG_MACRO($0112), BG_MACRO($0113), BG_MACRO($0114)
.ENDS

.SECTION "Luigi Name Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
LuigiName:
    ;.db $15, $1e, $12, $10, $12    ; "LUIGI", no address or length
    .dw BG_MACRO($0115), BG_MACRO($0116), BG_MACRO($0113), BG_MACRO($0117), BG_MACRO($0113)
.ENDS

.SECTION "WarpZone Numbers Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
WarpZoneNumbers:
    ; .db $04, $03, $02, $00         ; warp zone numbers, note spaces on middle
    ; .db $24, $05, $24, $00         ; zone, partly responsible for
    ; .db $08, $07, $06, $00         ; the minus world
    .dw BG_MACRO($0104), BG_MACRO($0103), BG_MACRO($0102), $0000
    .dw BLANKTILE, BG_MACRO($0105), BLANKTILE, $0000
    .dw BG_MACRO($0108), BG_MACRO($0107), BG_MACRO($0106), $0000
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Metatile Graphics Tables" BANK BANK_SLOT2 SLOT 2 FREE ALIGN 256

;   ----- METATILE GRAPHICS TABLES-----
Palette0_MTiles:
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; blank
    ;.dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; black
    .dw BG_MACRO($0111), BG_MACRO($0112), BG_MACRO($0118), BG_MACRO($0112)  ; middle center
    ; Grass
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BG_MACRO($01B4)                    ; left
    .dw BG_MACRO($01B5), BG_MACRO($01B6), BG_MACRO($01B7), BG_MACRO($01B8)  ; middle
    .dw BLANKTILE, BG_MACRO($01B9), BLANKTILE, BLANKTILE                    ; right
    ; Mountain
    .dw BLANKTILE, BG_MACRO($0110), BG_MACRO($0110), BG_MACRO($0111)        ; left
    .dw BG_MACRO($0111), BG_MACRO($0112), BG_MACRO($0113), BG_MACRO($0112)  ; left bottom
    .dw BLANKTILE, BG_MACRO($0114), BLANKTILE, BG_MACRO($0115)              ; middle top
    .dw BG_MACRO($0116), BG_MACRO($0117), BLANKTILE, BG_MACRO($0116)        ; right
    .dw BG_MACRO($0113), BG_MACRO($0112), BG_MACRO($0117), BG_MACRO($0112)  ; right bottom
    .dw BG_MACRO($0112), BG_MACRO($0112), BG_MACRO($0112), BG_MACRO($0112)  ; middle bottom
    ;.dw
    ; Bridge guardrail
    .dw BLANKTILE, $015F, BLANKTILE, $015F                                  ; middle
    .dw BLANKTILE, $015E, BLANKTILE, $015F                                  ; left
    .dw BLANKTILE, $015F, BLANKTILE, $0160                                  ; right
    ; Chain
    .dw $00, $0194, $0194, $00
    ; Trees
    .dw BG_MACRO($0183), BG_MACRO($0189), BG_MACRO($0185), BG_MACRO($018A)  ; tall top, top half
    .dw BG_MACRO($0183), BG_MACRO($0184), BG_MACRO($0185), BG_MACRO($0186)  ; short top
    .dw BG_MACRO($0189), BG_MACRO($0184), BG_MACRO($018A), BG_MACRO($0186)  ; tall top, bottom half
    ; Latern (NEW)
    .dw BLANKTILE, BLANKTILE, BG_MACRO($01B8), BG_MACRO($01B4)              ; top left
    .dw BG_MACRO($01B9), BG_MACRO($01B6), BLANKTILE, BLANKTILE              ; top right
    .dw BLANKTILE, BLANKTILE, BG_MACRO($01B5), BLANKTILE                    ; bottom left
    .dw BG_MACRO($01B7), BLANKTILE, BLANKTILE, BLANKTILE                    ; bottom right
    ; --- METATILES WITH COLLISION START HERE ---
    ; Vertical Pipe
    .dw BG_MACRO($1160), BG_MACRO($1161), BG_MACRO($1162), BG_MACRO($1163)  ; warp pipe end left, points up
    .dw BG_MACRO($1164), BG_MACRO($1165), BG_MACRO($1166), BG_MACRO($1167)  ; warp pipe end right, points up
    .dw BG_MACRO($1160), BG_MACRO($1161), BG_MACRO($1162), BG_MACRO($1163)  ; decoration pipe end left, points up
    .dw BG_MACRO($1164), BG_MACRO($1165), BG_MACRO($1166), BG_MACRO($1167)  ; decoration pipe end right, points up
    .dw BG_MACRO($1168), BG_MACRO($1168), BG_MACRO($1169), BG_MACRO($1169)  ; pipe shaft left
    .dw BG_MACRO($116A), BG_MACRO($116A), BG_MACRO($116B), BG_MACRO($116B)  ; pipe shaft right
    ; Tree Ledge
    .dw BG_MACRO($012B), BG_MACRO($012C), BG_MACRO($012D), BG_MACRO($012E)  ; left edge
    .dw BG_MACRO($012D), BG_MACRO($012F), BG_MACRO($012D), BG_MACRO($0130)  ; middle
    .dw BG_MACRO($012D), BG_MACRO($012E), BG_MACRO($0131), BG_MACRO($0132)  ; right edge
    ; Mushroom Ledge
    .dw BG_MACRO($013D), BG_MACRO($013E), BG_MACRO($013F), BG_MACRO($0140)  ; left edge
    .dw BG_MACRO($0141), BG_MACRO($0142), BG_MACRO($0143), BG_MACRO($0144)  ; middle
    .dw BG_MACRO($0145), BG_MACRO($0146), BG_MACRO($0147), BG_MACRO($0148)  ; right edge
    ; Horizontal Pipe
    .dw BG_MACRO($116C), BG_MACRO($116D), BG_MACRO($116E), BG_MACRO($116F)  ; sideways pipe end top
    .dw BG_MACRO($1170), BG_MACRO($1171), BG_MACRO($1170), BG_MACRO($1171)  ; sideways pipe shaft top
    .dw BG_MACRO($1172), BG_MACRO($1173), BG_MACRO($1169), BG_MACRO($1169)  ; sideways pipe joint top
    .dw BG_MACRO($1174), BG_MACRO($1175), BG_MACRO($1176), BG_MACRO($1177)  ; sideways pipe end bottom
    .dw BG_MACRO($1178), BG_MACRO($1179), BG_MACRO($1178), BG_MACRO($1179)  ; sideways pipe shaft bottom
    .dw BG_MACRO($117A), BG_MACRO($117B), BG_MACRO($1169), BG_MACRO($1169)  ; sideways pipe joint bottom
    ; Seaplant
    .dw $01BB, $01BC, $01BD, $01BE
    ; Blank for bricks/blocks that are hit
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE
    ; All-Stars Castle MTs
    .dw $01C8, $01C9, $01CA, $01CB                                          ; ceiling left
    .dw $01CC, $01CD, $01CE, $01CF                                          ; ceiling right
    .dw $01C8, $01C9, $01CE, $01CF                                          ; ceiling single
    .dw $01B4, $01B5, $01B6, $01B7                                          ; floor top
    .dw $11B4, $11B5, $11B6, $11B7                                          ; floor top (PRI)
    .dw $01C0, $01BF, $01BC, $01BD                                          ; floor bottom

    .dw $01B8, $01B9, $01B6, $01B7                                          ; floor left top corner
    .dw $01BA, $01BB, $01BC, $01BD                                          ; floor left side
    .dw $01BE, $01BF, $01BC, $01BD                                          ; floor left bot corner

    .dw $01B4, $01B5, $01C1, $01C2                                          ; floor right top corner
    .dw $01C0, $01BF, $01C2, $01C2                                          ; floor right side
    .dw $01C0, $01BF, $01C3, $01BD                                          ; floor right bot corner

    .dw $01D0, $01D1, $01D2, $01D3                                          ; stairs end
    .dw $01D4, $01D5, $01D6, $01D7                                          ; stairs end low
    .dw $01D0, $01D1, $01D0, $01D1                                          ; stairs top
    .dw $01D4, $01D5, $01D5, $01D4                                          ; stairs bottom
    ; --- CLIMBABLE METATILES START HERE ---
    ; Flagpole
    .dw BLANKTILE, BG_MACRO($017C), BLANKTILE, BG_MACRO($017D)              ; ball
    .dw BG_MACRO($015A), BG_MACRO($015A), BG_MACRO($015B), BG_MACRO($015B)  ; shaft
    ; Blank for vines
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE

Palette1_MTiles:
    ; Rope
    .dw BG_MACRO($0154), BG_MACRO($0154), BG_MACRO($0155), BG_MACRO($0155)  ; vertical
    .dw BG_MACRO($0158), BLANKTILE, BG_MACRO($0158), BLANKTILE              ; horizontal
    ; Pulley
    .dw BLANKTILE, BG_MACRO($0154), BG_MACRO($0156), BG_MACRO($0157)        ; left
    .dw BG_MACRO($0356), BG_MACRO($0159), BLANKTILE, BG_MACRO($0155)        ; right
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; blank used for balance rope
    ; Castle
    .dw BG_MACRO($118B), BG_MACRO($11A4), BG_MACRO($118C), BG_MACRO($11A4)  ; top (PRI)
    .dw BG_MACRO($018B), BG_MACRO($01A4), BG_MACRO($018C), BG_MACRO($01A4)  ; top (NON PRI)
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($0191), BG_MACRO($0191)  ; window left
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; brick wall
    .dw BG_MACRO($0191), BG_MACRO($0191), BG_MACRO($01A4), BG_MACRO($01A4)  ; window right
    .dw BG_MACRO($118D), BG_MACRO($11A4), BG_MACRO($118E), BG_MACRO($11A4)  ; top with brick (PRI)
    .dw BG_MACRO($018D), BG_MACRO($01A4), BG_MACRO($018E), BG_MACRO($01A4)  ; top with brick (NON PRI)
    .dw BG_MACRO($018F), BG_MACRO($0191), BG_MACRO($0190), BG_MACRO($0191)  ; entry top
    .dw BG_MACRO($0191), BG_MACRO($0191), BG_MACRO($0191), BG_MACRO($0191)  ; entry bottom
    .dw BG_MACRO($11A4), BG_MACRO($11A4), BG_MACRO($11A4), BG_MACRO($11A4)  ; brick wall PRIORITY (NEW)
    ; Tree Ledge Stump
    .dw BG_MACRO($0135), BG_MACRO($0139), BG_MACRO($0134), BG_MACRO($0138)  ; STUMP CENTER TOP
    .dw BG_MACRO($0133), BG_MACRO($0137), BG_MACRO($0134), BG_MACRO($0138)  ; STUMP LEFT TOP
    .dw BG_MACRO($0135), BG_MACRO($0139), BG_MACRO($0136), BG_MACRO($013A)  ; STUMP RIGHT TOP
    .dw BG_MACRO($0133), BG_MACRO($0137), BG_MACRO($0136), BG_MACRO($013A)  ; STUMP SINGLE TOP
    .dw BG_MACRO($0738), BG_MACRO($0139), BG_MACRO($0739), BG_MACRO($0138)  ; STUMP CENTER BOTTOM
    .dw BG_MACRO($013B), BG_MACRO($0137), BG_MACRO($0739), BG_MACRO($0138)  ; STUMP LEFT BOTTOM
    .dw BG_MACRO($0738), BG_MACRO($0139), BG_MACRO($013C), BG_MACRO($013A)  ; STUMP RIGHT BOTTOM
    .dw BG_MACRO($013B), BG_MACRO($0137), BG_MACRO($013C), BG_MACRO($013A)  ; STUMP SINGLE BOTTOM
    ; Fence
    .dw BG_MACRO($017F), BG_MACRO($0180), BG_MACRO($0181), BG_MACRO($0182)
    ; Tree Trunk
    .dw BG_MACRO($0187), BG_MACRO($0187), BG_MACRO($0188), BG_MACRO($0188)
    ; Mushroom Stump
    .dw BG_MACRO($0149), BG_MACRO($014A), BG_MACRO($0349), BG_MACRO($034A)  ; top
    .dw BG_MACRO($014A), BG_MACRO($014A), BG_MACRO($034A), BG_MACRO($034A)  ; bottom
    ; --- METATILES WITH COLLISION START HERE ---
    ; Breakable bricks
    .dw BG_MACRO($019B), BG_MACRO($01A4), BG_MACRO($019B), BG_MACRO($01A4)  ; shiny
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; normal
    .dw BG_MACRO($11A4), BG_MACRO($11A4), BG_MACRO($11A4), BG_MACRO($11A4)  ; unused (now used for brick priority)
    ; Rock Terrain
    .dw BG_MACRO($019C), BG_MACRO($019D), BG_MACRO($019E), BG_MACRO($019F)
    .dw BG_MACRO($119C), BG_MACRO($119D), BG_MACRO($119E), BG_MACRO($119F)  ; rock PRIORITY (NEW)
    ; Bricks with something in them
    .dw BG_MACRO($019B), BG_MACRO($01A4), BG_MACRO($019B), BG_MACRO($01A4)  ; shiny with Power-UP
    .dw BG_MACRO($019B), BG_MACRO($01A4), BG_MACRO($019B), BG_MACRO($01A4)  ; shiny with Vine
    .dw BG_MACRO($019B), BG_MACRO($01A4), BG_MACRO($019B), BG_MACRO($01A4)  ; shiny with Star
    .dw BG_MACRO($019B), BG_MACRO($01A4), BG_MACRO($019B), BG_MACRO($01A4)  ; shiny with Coins
    .dw BG_MACRO($019B), BG_MACRO($01A4), BG_MACRO($019B), BG_MACRO($01A4)  ; shiny with 1-UP
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; normal with Power-UP
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; normal with Vine
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; normal with Star
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; normal with Coins
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; normal with 1-UP
    ; Hidden blocks
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; with Coins
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; with 1-UP
    ; Solid blocks
    .dw BG_MACRO($01A0), BG_MACRO($01A1), BG_MACRO($01A2), BG_MACRO($01A3)  ; 3D block
    .dw BG_MACRO($11A0), BG_MACRO($11A1), BG_MACRO($11A2), BG_MACRO($11A3)  ; 3D block PRIORITY (for pipes)
    .dw $01D8, $01D9, $01DA, $01DB                                          ; white wall (castle levels)
    .dw $11D8, $11D9, $11DA, $11DB                                          ; white wall (castle levels) PRI
    ; Bridge
    .dw BG_MACRO($017E), BLANKTILE, BG_MACRO($017E), BLANKTILE
    ; Bullet Bill
    .dw BG_MACRO($114B), BG_MACRO($114C), BG_MACRO($115C), BG_MACRO($114D)  ; barrel
    .dw BG_MACRO($014E), BG_MACRO($014F), BG_MACRO($0150), BG_MACRO($0151)  ; top
    .dw BG_MACRO($0152), BG_MACRO($0152), BG_MACRO($0153), BG_MACRO($0153)  ; bottom
    ; Jumpspring
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; blank for jumpspring
    .dw BLANKTILE, BG_MACRO($01A4), BLANKTILE, BG_MACRO($01A4)              ; half brick 
    ; Solid brick for water levels
    .dw $01BF, $01C0, $01C1, $01C2
    .dw $11BF, $11C0, $11C1, $11C2
    ; Half brick (unused?)
    ;.dw BLANKTILE, BG_MACRO($01A4), BLANKTILE, BG_MACRO($01A4)
    ; Water pipe
    .dw BG_MACRO($116C), BG_MACRO($116D), BG_MACRO($116E), BG_MACRO($116F)
    .dw BG_MACRO($1174), BG_MACRO($1175), BG_MACRO($1176), BG_MACRO($1177)
    ; --- CLIMBABLE METATILES START HERE ---
    ; Flagball (unused)
    .dw BLANKTILE, BG_MACRO($017C), BLANKTILE, BG_MACRO($017D)

    
Palette2_MTiles:
    ; Cloud
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BG_MACRO($0119)                    ; right
    .dw BG_MACRO($011A), BG_MACRO($011B), BG_MACRO($011C), BG_MACRO($011B)  ; middle
    .dw BLANKTILE, BG_MACRO($011D), BLANKTILE, BLANKTILE                    ; left
    .dw BLANKTILE, BLANKTILE, BG_MACRO($011E), BLANKTILE                    ; right bottom
    .dw BG_MACRO($011F), BLANKTILE, BG_MACRO($0120), BLANKTILE              ; middle bottom
    .dw BG_MACRO($0121), BLANKTILE, BLANKTILE, BLANKTILE                    ; left bottom
    ; Water
    .dw $01E5, $01E7, $01E6, $01E7                                          ; waves
    .dw $01E7, $01E7, $01E7, $01E7                                          ; body
    ; Lava
    .dw $01EC, $01ED, $01EE, $01EF                                          ; waves
    .dw $01E5, $01E5, $01E5, $01E5                                          ; body
    ; Stars for Night Levels
    .dw $0000, $0000, $0000, $01CA
    .dw $0000, $0000, $01CB, $0000
    .dw $0000, $0000, $01CC, $0000
    .dw $0000, $01CD, $0000, $0000
    .dw $01CD, $0000, $0000, $0000
    .dw $0000, $0000, $0000, $01CE
    .dw $0000, $0000, $0000, $01CF
    .dw $0000, $0000, $01CD, $0000
    .dw $0000, $0000, $01D0, $0000
    .dw $0000, $0000, $01CE, $0000
    .dw $0000, $01D0, $0000, $0000
    .dw $01CA, $0000, $0000, $0000
    .dw $01D0, $0000, $0000, $0000
    .dw $0000, $0000, $0000, $01CB
    .dw $0000, $01CE, $0000, $0000
    .dw $0000, $01CB, $0000, $0000
    .dw $0000, $0000, $0000, $01CD
    ; Background for Water Levels (Except area in W8-4)
    .dw $0148, $0149, $01E7, $014A
    .dw $014B, $014C, $014D, $014E
    .dw $014F, $0150, $0151, $0152
    .dw $01E7, $0153, $01E7, $01E7
    .dw $0154, $0155, $0156, $0157
    .dw $0158, $0150, $0159, $0152
    .dw $015A, $015B, $015C, $015D
    .dw $015E, $015F, $0160, $0161
    .dw $0162, $0150, $0163, $0152
    .dw $0164, $0165, $0166, $0167
    .dw $0168, $0169, $016A, $016B
    .dw $016C, $0155, $016D, $0157
    .dw $016E, $016F, $015C, $015D
    .dw $0170, $0171, $0172, $0161
    .dw $0164, $0165, $0173, $0174
    .dw $0168, $0169, $0175, $0176
    .dw $01E7, $01E7, $01E7, $0177
    .dw $01E7, $01E7, $0178, $0179
    .dw $017A, $017B, $017C, $017D
    .dw $017E, $0155, $017F, $0157
    .dw $0180, $0181, $0159, $0182
    .dw $0183, $014C, $0184, $014E
    .dw $0185, $0186, $0187, $017D
    .dw $0188, $0189, $0184, $018A
    ; --- METATILES WITH COLLISION START HERE ---
    ; Cloud Terrain
    .dw BG_MACRO($0129), BG_MACRO($012A), BG_MACRO($0329), BG_MACRO($032A)
    ; Bowser's bridge
    .dw $0195, $0196, $0195, $0197
    

Palette3_MTiles:
    ; Background for water area in W8-4
    .dw $0148, $0149, $014A, $014B
    .dw $014C, $014D, $014E, $014F
    .dw $01E7, $0150, $01E7, $0151
    .dw $0152, $0153, $0154, $0155
    .dw $01E7, $0156, $01E7, $0157
    .dw $0158, $0159, $015A, $015B
    .dw $01E7, $01E7, $01E7, $015C
    .dw $01E7, $0150, $015D, $015E
    .dw $01E7, $01E7, $015F, $0160
    .dw $0161, $0162, $0163, $0164
    .dw $0165, $0166, $0167, $0168
    .dw $0158, $0159, $0169, $015B
    .dw $016A, $016B, $016C, $016D
    .dw $016E, $016F, $0170, $0171
    .dw $016E, $0172, $0170, $0171
    .dw $0173, $0149, $0174, $014B
    .dw $0175, $0176, $0177, $0178
    .dw $0179, $017A, $017B, $01E7
    .dw $017C, $017D, $01E7, $017E
    .dw $017F, $014D, $0180, $014F
    .dw $016A, $0181, $016C, $0182
    .dw $037B, $01E7, $0183, $0184
    .dw $01E7, $0185, $015D, $015E
    .dw $0186, $0153, $0154, $0155
    .dw $0175, $0187, $0177, $0188
    .dw $0165, $0189, $0167, $0164
    .dw $018A, $016B, $018B, $018C
    .dw $018D, $018E, $0177, $0178
    .dw $018A, $018F, $0190, $0191
    .dw $016E, $016F, $01E7, $0171
    .dw $01E7, $0379, $01E7, $01E7
    .dw $0192, $017A, $01E7, $01E7
    .dw $01E7, $0185, $01E7, $0151
    .dw $0158, $0159, $0193, $0194
    .dw $0195, $0196, $0197, $0195
    .dw $01C4, $01C5, $01C6, $01C7
    .dw $01E7, $01DC, $015D, $01DD
    .dw $01DE, $01DF, $01E0, $01E1
    .dw $01E2, $0197, $0196, $01E2
    ; --- METATILES WITH COLLISION START HERE ---
    ; Question Blocks
    .dw BG_MACRO($01A9), BG_MACRO($01AA), BG_MACRO($01AB), BG_MACRO($01AC)  ; with coin
    .dw BG_MACRO($01A9), BG_MACRO($01AA), BG_MACRO($01AB), BG_MACRO($01AC)  ; with power-UP
    ; Coins
    .dw BG_MACRO($09B0), BG_MACRO($09B1), BG_MACRO($09B2), BG_MACRO($09B3)  ; normal
    .dw BG_MACRO($01B0), BG_MACRO($01B1), BG_MACRO($01B2), BG_MACRO($01B3)  ; underwater
    ; Empty Block
    .dw BG_MACRO($01A5), BG_MACRO($01A6), BG_MACRO($01A7), BG_MACRO($01A8)
    ; Axe
    .dw $01C4, $01C5, $01C6, $01C7

.ENDS

.INCDIR "ASSETS"
;-------------------------------------------------------------------------------------
.SECTION "Area & Enemy Object Data" BANK BANK_AREAENEMY SLOT 2 FREE 

;ENEMY OBJECT DATA
.INCLUDE "EnemyObjectData.inc"

;AREA OBJECT DATA
.INCLUDE "AreaObjectData.inc"

.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Player Emblem Tiles" BANK BANK_SLOT2 SLOT 2 FREE

Tiles_Mario_Emblem:
    .db $38 $38 $00 $38 $10 $10 $6C $7C $82 $82 $7C $FE $AA $AA $54 $FE $BA $BA $44 $FE $38 $38 $44 $7C $38 $38 $00 $38 $00 $00 $00 $00
Tiles_Luigi_Emblem:
    .db $38 $38 $00 $38 $5C $7C $20 $5C $DE $FE $20 $DE $DE $FE $20 $DE $DE $FE $20 $DE $44 $7C $38 $44 $38 $38 $00 $38 $00 $00 $00 $00

Tiles_Mario_Emblem_NES:
    .db $00 $00 $00 $38 $6C $6C $6C $10 $7C $7C $7C $82 $54 $54 $54 $AA $44 $44 $44 $BA $44 $44 $44 $38 $00 $00 $00 $38 $00 $00 $00 $00
Tiles_Luigi_Emblem_NES:
    .db $38 $00 $38 $00 $5C $00 $7C $00 $DE $00 $FE $00 $DE $00 $FE $00 $DE $00 $FE $00 $44 $00 $7C $00 $38 $00 $38 $00 $00 $00 $00 $00
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Cloud Platform Tiles" BANK BANK_SLOT2 SLOT 2 FREE

Tiles_Cloud:
    .db $3C $3C $00 $3C $7C $7E $00 $7E $BE $FF $00 $FF $BE $FF $00 $FF $9E $FF $00 $FF $CC $FF $00 $FF $78 $7E $00 $7E $00 $3C $00 $3C

Tiles_Cloud_NES:
    .db $00 $00 $00 $3C $02 $00 $00 $7E $41 $00 $00 $FF $41 $00 $00 $FF $61 $00 $00 $FF $33 $00 $00 $FF $06 $00 $00 $7E $3C $00 $00 $3C
.ENDS

;   COMPRESSED TILE DATA
;-------------------------------------------------------------------------------------
.SECTION "BG Common Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_BG_Comm:
    .INCBIN "BG_Comm.zx7"
.ENDS

.SECTION "BG Titlescreen Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_BG_TitleScreen:
    .INCBIN "BG_TitleScreen.zx7"
.ENDS

.SECTION "BG Intermediate Screen Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_BG_Inter:
    .INCBIN "BG_Inter.zx7"
.ENDS

.SECTION "BG Overworld Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_BG_Overworld:
    .INCBIN "BG_Overworld.zx7"
.ENDS

.SECTION "BG Underground Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_BG_Underground:
    .INCBIN "BG_Underground.zx7"
.ENDS

.SECTION "BG Snow Tiles" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_BG_Snow:
    .INCBIN "BG_Snow.zx7"
.ENDS

.SECTION "BG Water Tiles" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_BG_Water:
    .INCBIN "BG_Water.zx7"
.ENDS

.SECTION "BG Castle Tiles" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_BG_Castle:
    .INCBIN "BG_Castle.zx7"
.ENDS

.SECTION "BG Water Castle Tiles" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_BG_WaterCastle:
    .INCBIN "BG_WaterCastle.zx7"
.ENDS

.SECTION "SPR Common Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_SPR_Comm:
    .INCBIN "SPR_Comm.zx7"
.ENDS

.SECTION "Base Enemy Sprite Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_SPR_Enemies:
    .INCBIN "SPR_Enemies.zx7"
.ENDS

.SECTION "Lakitu Enemy Sprite Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_SPR_Lakitu:
    .INCBIN "SPR_Lakitu.zx7"
.ENDS

.SECTION "Podoboo Enemy Sprite Tiles" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_SPR_Podoboo:
    .INCBIN "SPR_Podoboo.zx7"
.ENDS

.SECTION "Bowser Enemy Sprite Tiles" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_SPR_Bowser:
    .INCBIN "SPR_Bowser.zx7"
.ENDS

.INCDIR "ASSETS/NES"
;   COMPRESSED TILE DATA (NES)
;-------------------------------------------------------------------------------------
.SECTION "BG Common Tiles (NES)" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_BG_Comm_NES:
    .INCBIN "BG_Comm.zx7"
.ENDS

.SECTION "BG Titlescreen Tiles (NES)" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_BG_TitleScreen_NES:
    .INCBIN "BG_TitleScreen.zx7"
.ENDS

.SECTION "BG Intermediate Screen Tiles (NES)" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_BG_Inter_NES:
    .INCBIN "BG_Inter.zx7"
.ENDS

.SECTION "BG Overworld Tiles (NES)" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_BG_Overworld_NES:
    .INCBIN "BG_Overworld.zx7"
.ENDS

.SECTION "BG Water Tiles (NES)" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_BG_Water_NES:
    .INCBIN "BG_Water.zx7"
.ENDS

.SECTION "BG Castle Tiles (NES)" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_BG_Castle_NES:
    .INCBIN "BG_Castle.zx7"
.ENDS

.SECTION "BG Water Castle Tiles (NES)" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_BG_WaterCastle_NES:
    .INCBIN "BG_WaterCastle.zx7"
.ENDS

.SECTION "SPR Common Tiles (NES)" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_SPR_Comm_NES:
    .INCBIN "SPR_Comm.zx7"
.ENDS

.SECTION "Base Enemy Sprite Tiles (NES)" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_SPR_Enemies_NES:
    .INCBIN "SPR_Enemies.zx7"
.ENDS

.SECTION "Lakitu Enemy Sprite Tiles (NES)" BANK BANK_PLAYERGFX05 SLOT 2 FREE

Tiles_SPR_Lakitu_NES:
    .INCBIN "SPR_Lakitu.zx7"
.ENDS

.SECTION "Podoboo Enemy Sprite Tiles (NES)" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_SPR_Podoboo_NES:
    .INCBIN "SPR_Podoboo.zx7"
.ENDS

.SECTION "Bowser Enemy Sprite Tiles (NES)" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_SPR_Bowser_NES:
    .INCBIN "SPR_Bowser.zx7"
.ENDS

.INCDIR "ASSETS"

.SECTION "Options BG Tiles" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Tiles_BG_Options:
    .INCBIN "BG_Options.zx7"
.ENDS

.SECTION "Options BG Tilemap" BANK BANK_PLAYERGFX04 SLOT 2 FREE

Map_BG_Options:
    .INCBIN "MAP_Options.zx7"
.ENDS

.SECTION "Options BG Palette" BANK BANK_PLAYERGFX04 SLOT 2 FREE
Pal_BG_Options:
    .db $00 $01 $02 $03 $06 $0B $0F $2B $3F
.ENDS

.SECTION "Options BG Sound Select TMAP" BANK BANK_PLAYERGFX04 SLOT 2 FREE
Map_BG_SoundSelect:
@Line1:
    .dw $0195, $0196, $0197
@Line2:
    .dw $0198, $0199, $0000
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Uncompressed Player Tiles - Mario [Right, Palette 0]" BANK BANK_PLAYERGFX00 SLOT 2 FORCE ORG $0000
.INCLUDE "SPR_Mario00.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Mario [Right, Palette 1]" BANK BANK_PLAYERGFX00 SLOT 2 FORCE ORG $1000
.INCLUDE "SPR_Mario01.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Mario [Right, Palette 2]" BANK BANK_PLAYERGFX00 SLOT 2 FORCE ORG $2000
.INCLUDE "SPR_Mario02.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Mario [Right, Palette 3]" BANK BANK_PLAYERGFX00 SLOT 2 FORCE ORG $3000
.INCLUDE "SPR_Mario03.inc"
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Uncompressed Player Tiles - Mario [Left, Palette 0]" BANK BANK_PLAYERGFX01 SLOT 2 FORCE ORG $0000
.INCLUDE "SPR_Mario10.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Mario [Left, Palette 1]" BANK BANK_PLAYERGFX01 SLOT 2 FORCE ORG $1000
.INCLUDE "SPR_Mario11.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Mario [Left, Palette 2]" BANK BANK_PLAYERGFX01 SLOT 2 FORCE ORG $2000
.INCLUDE "SPR_Mario12.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Mario [Left, Palette 3]" BANK BANK_PLAYERGFX01 SLOT 2 FORCE ORG $3000
.INCLUDE "SPR_Mario13.inc"
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Uncompressed Player Tiles - Luigi [Right, Palette 0]" BANK BANK_PLAYERGFX02 SLOT 2 FORCE ORG $0000
.INCLUDE "SPR_Luigi00.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Luigi [Right, Palette 1]" BANK BANK_PLAYERGFX02 SLOT 2 FORCE ORG $1000
.INCLUDE "SPR_Luigi01.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Luigi [Right, Palette 2]" BANK BANK_PLAYERGFX02 SLOT 2 FORCE ORG $2000
.INCLUDE "SPR_Luigi02.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Luigi [Right, Palette 3]" BANK BANK_PLAYERGFX02 SLOT 2 FORCE ORG $3000
.INCLUDE "SPR_Luigi03.inc"
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Uncompressed Player Tiles - Luigi [Left, Palette 0]" BANK BANK_PLAYERGFX03 SLOT 2 FORCE ORG $0000
.INCLUDE "SPR_Luigi10.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Luigi [Left, Palette 1]" BANK BANK_PLAYERGFX03 SLOT 2 FORCE ORG $1000
.INCLUDE "SPR_Luigi11.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Luigi [Left, Palette 2]" BANK BANK_PLAYERGFX03 SLOT 2 FORCE ORG $2000
.INCLUDE "SPR_Luigi12.inc"
.ENDS

.SECTION "Uncompressed Player Tiles - Luigi [Left, Palette 3]" BANK BANK_PLAYERGFX03 SLOT 2 FORCE ORG $3000
.INCLUDE "SPR_Luigi13.inc"
.ENDS

.INCDIR "ASSETS/NES"
;-------------------------------------------------------------------------------------
.SECTION "Uncompressed Player Tiles (NES) - Mario/Luigi [Left]" BANK BANK_PLAYERGFX04 SLOT 2 FORCE ORG $0000
    .INCLUDE "SPR_Mario00.inc"
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Uncompressed Player Tiles (NES) - Mario/Luigi [Right]" BANK BANK_PLAYERGFX05 SLOT 2 FORCE ORG $0000
    .INCLUDE "SPR_Mario10.inc"
.ENDS

.INCDIR "ASSETS"

;-------------------------------------------------------------------------------------
.INCLUDE "SND_Data_Comm.inc"

;-------------------------------------------------------------------------------------
.SECTION "Animated Background Tiles - BANK 00" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LavaFrame0:
; Tile index $000
.db $D7 $28 $28 $28 $E7 $10 $18 $18 $EF $00 $10 $10 $FF $00 $00 $00 $00 $FF $FF $FF $38 $C6 $FF $C7 $00 $78 $FF $FF $00 $27 $FF $FF
; Tile index $001
.db $0C $F2 $FF $F3 $01 $20 $FF $FE $80 $00 $FF $7F $C3 $00 $FF $3C $E7 $00 $FF $18 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00
; Tile index $002
.db $FF $00 $00 $00 $C7 $00 $38 $38 $A2 $19 $6D $7D $01 $78 $8E $FE $00 $91 $FF $FF $82 $01 $FF $7D $7C $00 $FF $83 $00 $9E $FF $FF
; Tile index $003
.db $00 $00 $FF $FF $B0 $00 $FF $4F $E0 $00 $FF $1F $83 $00 $FF $7C $C7 $00 $FF $38 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00

WaterA1Frame0:
; Tile index $000
.db $80 $00 $80 $80 $E0 $80 $E0 $E0 $7C $E0 $FC $FC $1F $FC $FF $FF $C3 $FF $FF $FF $00 $FF $FF $FF $C0 $FF $FF $FF $39 $FF $FF $FF
; Tile index $001
.db $01 $00 $01 $01 $07 $01 $07 $07 $3E $07 $3F $3F $F8 $3F $FF $FF $C0 $FF $FF $FF $0E $F3 $FF $FF $79 $8F $FF $FF $E0 $FF $FF $FF

WaterA0Frame0:
; Tile index $000
.db $80 $00 $80 $80 $60 $00 $60 $60 $9C $00 $9C $1C $E3 $00 $E3 $03 $3C $00 $3C $00 $FF $00 $FF $00 $3F $00 $3F $00 $C6 $00 $C6 $00
; Tile index $001
.db $01 $00 $01 $01 $06 $00 $06 $06 $39 $00 $39 $38 $C7 $00 $C7 $C0 $3F $00 $3F $00 $FD $00 $FD $0C $F6 $00 $F6 $70 $1F $00 $1F $00
.ENDS

.SECTION "Animated Background Tiles - BANK 01" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LavaFrame1:
; Tile index $004
.db $3F $80 $C0 $C0 $7E $01 $81 $81 $F6 $08 $09 $09 $FF $00 $00 $00 $00 $FF $FF $FF $00 $CE $FF $FF $00 $79 $FE $FF $01 $26 $FD $FF
; Tile index $005
.db $0C $F3 $FF $F3 $04 $20 $FF $FB $03 $00 $FF $FC $87 $00 $FF $78 $CF $00 $FF $30 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00
; Tile index $006
.db $EF $10 $10 $10 $7D $82 $82 $82 $3B $44 $FC $C4 $13 $28 $FE $EC $06 $B1 $FF $F9 $86 $21 $FF $79 $7C $80 $FF $83 $20 $C6 $FF $DF
; Tile index $007
.db $30 $00 $FF $CF $30 $00 $FF $CF $E2 $00 $FF $1D $06 $00 $FF $F9 $8F $00 $FF $70 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00

WaterA1Frame1:
; Tile index $002
.db $00 $00 $00 $00 $98 $00 $98 $98 $FF $18 $FF $FF $E7 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $E0 $FF $FF $FF $1F $FF $FF $FF
; Tile index $003
.db $0A $00 $0A $0A $1F $00 $1F $1F $0B $00 $0B $0B $FF $01 $FF $FF $FE $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $57 $FF $FF $FF

WaterA0Frame1:
; Tile index $002
.db $00 $00 $00 $00 $98 $00 $98 $98 $E7 $00 $E7 $E7 $18 $00 $18 $00 $FF $00 $FF $00 $FF $00 $FF $00 $1F $00 $1F $00 $E0 $00 $E0 $00
; Tile index $003
.db $0A $00 $0A $0A $1F $00 $1F $1F $0B $00 $0B $0B $FE $00 $FE $FE $01 $00 $01 $00 $FF $00 $FF $00 $FF $00 $FF $00 $A8 $00 $A8 $00
.ENDS

.SECTION "Animated Background Tiles - BANK 02" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LavaFrame2:
; Tile index $008
.db $BD $40 $42 $42 $F8 $02 $07 $07 $BD $40 $42 $42 $CF $30 $30 $30 $00 $FF $FF $FF $01 $7E $FF $FE $03 $30 $FF $FC $01 $E6 $FD $FE
; Tile index $009
.db $0C $33 $FE $F3 $04 $00 $FF $FB $E3 $00 $FF $1C $40 $00 $FF $BF $F7 $00 $FF $08 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00
; Tile index $00A
.db $D7 $28 $28 $28 $EF $10 $10 $10 $EF $10 $10 $10 $5F $20 $A0 $A0 $00 $BF $FF $FF $B8 $07 $FF $47 $40 $80 $7F $BF $20 $C6 $7F $DF
; Tile index $00B
.db $30 $80 $FF $CF $30 $00 $FF $CF $E0 $00 $FF $1F $00 $00 $FF $FF $E2 $00 $FF $1D $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00

WaterA1Frame2:
; Tile index $004
.db $00 $00 $00 $00 $1A $00 $1A $1A $FF $18 $FF $FF $E7 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $E0 $FF $FF $FF $1F $FF $FF $FF
; Tile index $005
.db $58 $00 $58 $58 $04 $00 $04 $04 $01 $00 $01 $01 $FF $01 $FF $FF $FE $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $57 $FF $FF $FF

WaterA0Frame2:
; Tile index $004
.db $00 $00 $00 $00 $1A $00 $1A $1A $E7 $00 $E7 $E7 $18 $00 $18 $00 $FF $00 $FF $00 $FF $00 $FF $00 $1F $00 $1F $00 $E0 $00 $E0 $00
; Tile index $005
.db $58 $00 $58 $58 $04 $00 $04 $04 $01 $00 $01 $01 $FE $00 $FE $FE $01 $00 $01 $00 $FF $00 $FF $00 $FF $00 $FF $00 $A8 $00 $A8 $00
.ENDS

.SECTION "Animated Background Tiles - BANK 03" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LavaFrame3:
; Tile index $00C
.db $FF $00 $00 $00 $DD $22 $22 $22 $FF $00 $00 $00 $CF $00 $30 $30 $00 $A3 $FF $FF $48 $04 $FB $B7 $32 $04 $FF $CD $01 $C6 $FD $FE
; Tile index $00D
.db $04 $03 $FE $FB $C3 $00 $FF $3C $B0 $00 $FF $4F $C3 $00 $FF $3C $9F $00 $FF $60 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00
; Tile index $00E
.db $FD $02 $02 $02 $F8 $06 $07 $07 $FD $00 $02 $02 $7D $00 $82 $82 $00 $BD $FF $FF $00 $27 $DF $FF $90 $6C $BF $6F $00 $C1 $7F $FF
; Tile index $00F
.db $40 $87 $FF $BF $80 $00 $FF $7F $0C $00 $FF $F3 $06 $00 $FF $F9 $8F $00 $FF $70 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00

WaterA1Frame3:
; Tile index $006
.db $09 $00 $09 $09 $00 $00 $00 $00 $01 $00 $01 $01 $FF $01 $FF $FF $FE $FF $FF $FF $60 $FF $FF $FF $0E $FF $FF $FF $FC $FF $FF $FF
; Tile index $007
.db $80 $00 $80 $80 $40 $00 $40 $40 $E0 $00 $E0 $E0 $FF $E0 $FF $FF $1F $FF $FF $FF $00 $FF $FF $FF $0E $FF $FF $FF $87 $FF $FF $FF

WaterA0Frame3:
; Tile index $006
.db $09 $00 $09 $09 $00 $00 $00 $00 $01 $00 $01 $01 $FE $00 $FE $FE $01 $00 $01 $00 $9F $00 $9F $00 $F1 $00 $F1 $00 $03 $00 $03 $00
; Tile index $007
.db $80 $00 $80 $80 $40 $00 $40 $40 $E0 $00 $E0 $E0 $1F $00 $1F $1F $E0 $00 $E0 $00 $FF $00 $FF $00 $F1 $00 $F1 $00 $78 $00 $78 $00
.ENDS

.SECTION "Animated Background Tiles - BANK 04" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LavaFrame4:
; Tile index $010
.db $FD $02 $02 $02 $FF $00 $00 $00 $FF $00 $00 $00 $DF $00 $30 $20 $08 $26 $FD $F7 $58 $01 $FE $A7 $30 $05 $FE $CF $00 $CA $FF $FF
; Tile index $011
.db $03 $00 $FF $FC $00 $00 $FF $FF $61 $00 $FF $9E $C1 $00 $FF $3E $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00
; Tile index $012
.db $FD $02 $02 $02 $FF $00 $00 $00 $EF $10 $10 $10 $6F $10 $90 $90 $00 $BF $7F $FF $00 $27 $DF $FF $80 $4C $FF $7F $00 $F1 $FF $FF
; Tile index $013
.db $80 $37 $FF $7F $00 $00 $FF $FF $06 $00 $FF $F9 $81 $00 $FF $7E $E3 $00 $FF $1C $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00

WaterA1Frame4:
; Tile index $008
.db $00 $00 $00 $00 $08 $00 $08 $08 $01 $00 $01 $01 $FF $01 $FF $FF $FE $FF $FF $FF $60 $FF $FF $FF $0E $FF $FF $FF $FC $FF $FF $FF
; Tile index $009
.db $00 $00 $00 $00 $00 $00 $00 $00 $E0 $00 $E0 $E0 $FF $E0 $FF $FF $1F $FF $FF $FF $00 $FF $FF $FF $0E $FF $FF $FF $87 $FF $FF $FF

WaterA0Frame4:
; Tile index $008
.db $00 $00 $00 $00 $08 $00 $08 $08 $01 $00 $01 $01 $FE $00 $FE $FE $01 $00 $01 $00 $9F $00 $9F $00 $F1 $00 $F1 $00 $03 $00 $03 $00
; Tile index $009
.db $00 $00 $00 $00 $00 $00 $00 $00 $E0 $00 $E0 $E0 $1F $00 $1F $1F $E0 $00 $E0 $00 $FF $00 $FF $00 $F1 $00 $F1 $00 $78 $00 $78 $00
.ENDS

.SECTION "Animated Background Tiles - BANK 05" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LavaFrame5:
; Tile index $014
.db $FF $00 $00 $00 $FF $00 $00 $00 $FE $01 $01 $01 $63 $80 $9C $9C $01 $98 $EE $FE $22 $80 $FF $DD $1C $00 $FF $E3 $00 $C3 $FF $FF
; Tile index $015
.db $00 $77 $FF $FF $0C $00 $FF $F3 $17 $00 $FF $E8 $A3 $00 $FF $5C $C7 $00 $FF $38 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00
; Tile index $016
.db $FF $00 $00 $00 $FF $00 $00 $00 $EA $05 $15 $15 $C7 $10 $38 $38 $00 $8F $FF $FF $00 $DF $FF $FF $00 $70 $FF $FF $00 $9E $FF $FF
; Tile index $017
.db $00 $68 $FF $FF $00 $1E $FF $FF $00 $00 $FF $FF $81 $00 $FF $7E $8F $00 $FF $70 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00

WaterA1Frame5:
; Tile index $00A
.db $00 $00 $00 $00 $2C $00 $2C $2C $10 $00 $10 $10 $FF $00 $FF $FF $FF $FF $FF $FF $00 $FF $FF $FF $01 $FF $FF $FF $8E $FF $FF $FF
; Tile index $00B
.db $00 $00 $00 $00 $18 $00 $18 $18 $FF $18 $FF $FF $E7 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $E0 $FF $FF $FF $1E $FF $FF $FF

WaterA0Frame5:
; Tile index $00A
.db $00 $00 $00 $00 $2C $00 $2C $2C $10 $00 $10 $10 $FF $00 $FF $FF $00 $00 $00 $00 $FF $00 $FF $00 $FE $00 $FE $00 $71 $00 $71 $00
; Tile index $00B
.db $00 $00 $00 $00 $18 $00 $18 $18 $E7 $00 $E7 $E7 $18 $00 $18 $00 $FF $00 $FF $00 $FF $00 $FF $00 $1F $00 $1F $00 $E1 $00 $E1 $00
.ENDS

.SECTION "Animated Background Tiles - BANK 06" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LavaFrame6:
; Tile index $018
.db $FF $00 $00 $00 $FF $00 $00 $00 $E2 $01 $1D $1D $41 $88 $BE $BE $00 $BC $E7 $FF $41 $80 $FF $BE $3F $00 $FF $C0 $00 $C1 $FF $FF
; Tile index $019
.db $00 $79 $FF $FF $71 $00 $FF $8E $F8 $00 $FF $07 $4C $00 $FF $B3 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00
; Tile index $01A
.db $FF $00 $00 $00 $FF $00 $00 $00 $EA $05 $15 $15 $C7 $10 $38 $38 $00 $8F $FF $FF $00 $DF $FF $FF $80 $70 $FF $7F $60 $9E $FF $9F
; Tile index $01B
.db $40 $28 $FF $BF $10 $00 $FF $EF $E0 $00 $FF $1F $01 $00 $FF $FE $E3 $00 $FF $1C $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00

WaterA1Frame6:
; Tile index $00C
.db $00 $00 $00 $00 $82 $00 $82 $82 $00 $00 $00 $00 $FF $00 $FF $FF $FF $FF $FF $FF $00 $FF $FF $FF $01 $FF $FF $FF $8E $FF $FF $FF
; Tile index $00D
.db $00 $00 $00 $00 $18 $00 $18 $18 $FF $18 $FF $FF $E7 $FF $FF $FF $00 $FF $FF $FF $00 $FF $FF $FF $E0 $FF $FF $FF $1E $FF $FF $FF

WaterA0Frame6:
; Tile index $00C
.db $00 $00 $00 $00 $82 $00 $82 $82 $00 $00 $00 $00 $FF $00 $FF $FF $00 $00 $00 $00 $FF $00 $FF $00 $FE $00 $FE $00 $71 $00 $71 $00
; Tile index $00D
.db $00 $00 $00 $00 $18 $00 $18 $18 $E7 $00 $E7 $E7 $18 $00 $18 $00 $FF $00 $FF $00 $FF $00 $FF $00 $1F $00 $1F $00 $E1 $00 $E1 $00
.ENDS

.SECTION "Animated Background Tiles - BANK 07" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LavaFrame7:
; Tile index $01C
.db $FF $00 $00 $00 $FF $00 $00 $00 $9C $63 $63 $63 $80 $3E $7F $7F $44 $88 $BF $BB $2E $41 $FF $D1 $1C $03 $FF $E3 $00 $7C $FF $FF
; Tile index $01D
.db $00 $22 $FF $FF $C0 $00 $FF $3F $B0 $00 $FF $4F $C3 $00 $FF $3C $9F $00 $FF $60 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00
; Tile index $01E
.db $FE $01 $01 $01 $C3 $04 $3C $3C $83 $38 $5C $7C $01 $12 $FE $FE $44 $83 $FF $BB $38 $C1 $FF $C7 $00 $80 $FF $FF $00 $E3 $FF $FF
; Tile index $01F
.db $00 $50 $FF $FF $40 $00 $FF $BF $01 $00 $FF $FE $03 $00 $FF $FC $8F $00 $FF $70 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $00

WaterA1Frame7:
; Tile index $00E
.db $80 $00 $80 $80 $E0 $80 $E0 $E0 $7D $E0 $FD $FD $1F $FC $FF $FF $C3 $FF $FF $FF $00 $FF $FF $FF $C0 $FF $FF $FF $39 $FF $FF $FF
; Tile index $00F
.db $01 $00 $01 $01 $07 $01 $07 $07 $3E $07 $3F $3F $F8 $3F $FF $FF $C0 $FF $FF $FF $0E $F3 $FF $FF $79 $8F $FF $FF $E0 $FF $FF $FF

WaterA0Frame7:
; Tile index $00E
.db $80 $00 $80 $80 $60 $00 $60 $60 $9D $00 $9D $1D $E3 $00 $E3 $03 $3C $00 $3C $00 $FF $00 $FF $00 $3F $00 $3F $00 $C6 $00 $C6 $00
; Tile index $00F
.db $01 $00 $01 $01 $06 $00 $06 $06 $39 $00 $39 $38 $C7 $00 $C7 $C0 $3F $00 $3F $00 $FD $00 $FD $0C $F6 $00 $F6 $70 $1F $00 $1F $00
.ENDS

.SECTION "Animated Background Tiles - BANK 10" BANK BANK_SLOT2 SLOT 2 ALIGN $100
CoinFrame0:
; Tile index $000
.db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $07 $07 $07 $07 $08 $06 $05 $04 $0A $0C $08 $08 $17 $0D $09 $09 $16 $0D $09 $09 $16
; Tile index $001
.db $0D $09 $09 $16 $0D $09 $09 $16 $0D $09 $09 $16 $0D $09 $09 $16 $0D $09 $09 $16 $06 $05 $04 $0A $07 $07 $07 $08 $03 $03 $03 $04
; Tile index $002
.db $00 $00 $00 $00 $00 $00 $00 $00 $00 $60 $00 $80 $C0 $F0 $C0 $00 $C0 $F0 $C0 $00 $60 $F8 $60 $00 $60 $F8 $60 $00 $60 $F8 $60 $00
; Tile index $003
.db $60 $F8 $60 $00 $60 $F8 $60 $00 $60 $F8 $60 $00 $60 $F8 $60 $00 $60 $F8 $60 $00 $C0 $F0 $C0 $00 $C0 $F0 $C0 $00 $80 $E0 $80 $00

WCoinFrame0:
; Tile index $000
.db $FF $00 $FF $00 $FF $00 $FF $00 $F8 $00 $F8 $07 $F7 $07 $F0 $08 $F6 $07 $F1 $0B $EC $0C $E0 $17 $ED $0D $E0 $16 $ED $0D $E0 $16
; Tile index $001
.db $ED $0D $E0 $16 $ED $0D $E0 $16 $ED $0D $E0 $16 $ED $0D $E0 $16 $ED $0D $E0 $16 $F6 $07 $F1 $0B $F7 $07 $F0 $08 $FB $03 $F8 $04
; Tile index $002
.db $FF $00 $FF $00 $FF $00 $FF $00 $1F $60 $7F $E0 $CF $F0 $3F $30 $CF $F0 $3F $30 $67 $F8 $9F $98 $67 $F8 $9F $98 $67 $F8 $9F $98
; Tile index $003
.db $67 $F8 $9F $98 $67 $F8 $9F $98 $67 $F8 $9F $98 $67 $F8 $9F $98 $67 $F8 $9F $98 $CF $F0 $3F $30 $CF $F0 $3F $30 $9F $E0 $7F $60
.ENDS

.SECTION "Animated Background Tiles - BANK 11" BANK BANK_SLOT2 SLOT 2 ALIGN $100
CoinFrame1:
; Tile index $004
.db $00 $00 $00 $00 $00 $00 $00 $00 $07 $00 $00 $07 $08 $00 $00 $0F $0B $03 $01 $0E $17 $04 $00 $1F $16 $04 $00 $1F $16 $04 $00 $1F
; Tile index $005
.db $16 $04 $00 $1F $16 $04 $00 $1F $16 $04 $00 $1F $16 $04 $00 $1F $16 $04 $00 $1F $0B $03 $01 $0E $08 $00 $00 $0F $04 $00 $00 $07
; Tile index $006
.db $00 $00 $00 $00 $00 $00 $00 $00 $E0 $60 $60 $80 $30 $30 $30 $C0 $30 $30 $30 $C0 $98 $98 $98 $60 $98 $98 $98 $60 $98 $98 $98 $60
; Tile index $007
.db $98 $98 $98 $60 $98 $98 $98 $60 $98 $98 $98 $60 $98 $98 $98 $60 $98 $98 $98 $60 $30 $30 $30 $C0 $30 $30 $30 $C0 $60 $60 $60 $80

WCoinFrame1:
; Tile index $004
.db $FF $00 $FF $00 $FF $00 $FF $00 $FF $07 $F8 $07 $F8 $08 $F0 $0F $FB $09 $F2 $0E $F7 $13 $E4 $1F $F6 $12 $E4 $1F $F6 $12 $E4 $1F
; Tile index $005
.db $F6 $12 $E4 $1F $F6 $12 $E4 $1F $F6 $12 $E4 $1F $F6 $12 $E4 $1F $F6 $12 $E4 $1F $FB $09 $F2 $0E $F8 $08 $F0 $0F $FC $04 $F8 $07
; Tile index $006
.db $FF $00 $FF $00 $FF $00 $FF $00 $FF $E0 $1F $80 $3F $30 $0F $C0 $3F $30 $0F $C0 $9F $98 $07 $60 $9F $98 $07 $60 $9F $98 $07 $60
; Tile index $007
.db $9F $98 $07 $60 $9F $98 $07 $60 $9F $98 $07 $60 $9F $98 $07 $60 $9F $98 $07 $60 $3F $30 $0F $C0 $3F $30 $0F $C0 $7F $60 $1F $80
.ENDS

.SECTION "Animated Background Tiles - BANK 12" BANK BANK_SLOT2 SLOT 2 ALIGN $100
CoinFrame2:
; Tile index $008
.db $00 $00 $00 $00 $00 $00 $00 $00 $07 $07 $00 $07 $0F $08 $00 $0F $0E $0A $00 $0F $1F $17 $00 $1F $1F $16 $00 $1F $1F $16 $00 $1F
; Tile index $009
.db $1F $16 $00 $1F $1F $16 $00 $1F $1F $16 $00 $1F $1F $16 $00 $1F $1F $16 $00 $1F $0E $0A $00 $0F $0F $08 $00 $0F $07 $04 $00 $07
; Tile index $00A
.db $00 $00 $00 $00 $00 $00 $00 $00 $80 $80 $00 $E0 $C0 $00 $00 $F0 $C0 $00 $00 $F0 $60 $00 $00 $F8 $60 $00 $00 $F8 $60 $00 $00 $F8
; Tile index $00B
.db $60 $00 $00 $F8 $60 $00 $00 $F8 $60 $00 $00 $F8 $60 $00 $00 $F8 $60 $00 $00 $F8 $C0 $00 $00 $F0 $C0 $00 $00 $F0 $80 $00 $00 $E0

WCoinFrame2:
; Tile index $008
.db $FF $00 $FF $00 $FF $00 $FF $00 $FF $00 $FF $07 $FF $07 $F8 $0F $FE $04 $FA $0F $FF $08 $F7 $1F $FF $09 $F6 $1F $FF $09 $F6 $1F
; Tile index $009
.db $FF $09 $F6 $1F $FF $09 $F6 $1F $FF $09 $F6 $1F $FF $09 $F6 $1F $FF $09 $F6 $1F $FE $04 $FA $0F $FF $07 $F8 $0F $FF $03 $FC $07
; Tile index $00A
.db $FF $00 $FF $00 $FF $00 $FF $00 $9F $00 $9F $E0 $CF $C0 $0F $F0 $CF $C0 $0F $F0 $67 $60 $07 $F8 $67 $60 $07 $F8 $67 $60 $07 $F8
; Tile index $00B
.db $67 $60 $07 $F8 $67 $60 $07 $F8 $67 $60 $07 $F8 $67 $60 $07 $F8 $67 $60 $07 $F8 $CF $C0 $0F $F0 $CF $C0 $0F $F0 $9F $80 $1F $E0
.ENDS

.SECTION "Animated Background Tiles - BANK 20" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LaternFrame0:
; Tile index $000
.db $F4 $03 $0F $0F $E8 $06 $1F $1F $C0 $0C $3F $3F $E3 $19 $10 $17 $87 $63 $10 $1F $0F $E3 $10 $1F $0F $C6 $11 $3F $3F $BE $01 $7F
; Tile index $001
.db $2F $86 $11 $7F $0F $C2 $11 $3F $0F $E3 $10 $1F $87 $63 $10 $1F $E3 $19 $10 $17 $E0 $1C $18 $1B $C0 $3E $3F $3F $E0 $1F $00 $00
; Tile index $002
.db $1F $E0 $E0 $E0 $0F $F0 $F0 $F0 $07 $78 $F8 $F8 $8F $30 $10 $D0 $C3 $8C $10 $F0 $E1 $8E $10 $F0 $E1 $C6 $10 $F8 $F9 $FA $00 $FC
; Tile index $003
.db $E9 $C2 $10 $FC $E1 $86 $10 $F8 $E1 $8E $10 $F0 $C3 $8C $10 $F0 $8F $30 $10 $D0 $0F $70 $30 $B0 $07 $F8 $F8 $F8 $07 $F8 $00 $00

QBlockFrame0:
; Tile index $000
.db $7F $00 $00 $7F $FF $10 $20 $FF $FF $3F $40 $FF $FF $38 $47 $FF $FF $70 $0C $FF $FF $31 $0C $FF $FF $31 $0C $FF $FF $38 $01 $FF
; Tile index $001
.db $FF $3E $01 $FF $FF $3F $00 $FF $FF $3E $01 $FF $FF $3E $01 $FF $FF $1F $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $7F $00 $00 $7F
; Tile index $002
.db $FE $00 $00 $FE $FF $00 $00 $FF $FF $F0 $00 $FF $FF $38 $C0 $FF $FF $18 $60 $FF $FF $88 $60 $FF $FF $08 $E0 $FF $FF $08 $80 $FF
; Tile index $003
.db $FF $38 $80 $FF $FF $38 $00 $FF $FF $78 $80 $FF $FF $38 $80 $FF $FF $38 $00 $FF $FF $00 $00 $FF $FF $00 $00 $FF $FE $00 $00 $FE
.ENDS

.SECTION "Animated Background Tiles - BANK 21" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LaternFrame1:
; Tile index $004
.db $F4 $03 $0F $0F $E8 $07 $1F $1F $C0 $0E $3F $3F $E9 $14 $10 $13 $E3 $19 $10 $17 $C3 $23 $10 $1F $87 $63 $10 $1F $BF $5F $00 $3F
; Tile index $005
.db $87 $43 $10 $3F $83 $63 $10 $1F $C3 $23 $10 $1F $E3 $19 $10 $17 $E9 $14 $10 $13 $E4 $1B $18 $18 $C0 $3F $3F $3F $E0 $1F $00 $00
; Tile index $006
.db $1F $E0 $E0 $E0 $0F $F0 $F0 $F0 $07 $F8 $F8 $F8 $2F $50 $10 $90 $8F $30 $10 $D0 $87 $88 $10 $F0 $C3 $8C $10 $F0 $FB $F4 $00 $F8
; Tile index $007
.db $C3 $84 $10 $F8 $83 $8C $10 $F0 $87 $88 $10 $F0 $8F $30 $10 $D0 $2F $50 $10 $90 $4F $B0 $30 $30 $07 $F8 $F8 $F8 $07 $F8 $00 $00

QBlockFrame1:
; Tile index $004
.db $00 $00 $00 $7F $30 $00 $20 $FF $7F $00 $40 $FF $7F $00 $47 $FF $7C $00 $0C $FF $3D $00 $0C $FF $3D $00 $0C $FF $39 $00 $01 $FF
; Tile index $005
.db $3F $00 $01 $FF $3F $00 $00 $FF $3F $00 $01 $FF $3F $00 $01 $FF $1F $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $7F
; Tile index $006
.db $00 $00 $00 $FE $00 $00 $00 $FF $F0 $00 $00 $FF $F8 $00 $C0 $FF $78 $00 $60 $FF $E8 $00 $60 $FF $E8 $00 $E0 $FF $88 $00 $80 $FF
; Tile index $007
.db $B8 $00 $80 $FF $38 $00 $00 $FF $F8 $00 $80 $FF $B8 $00 $80 $FF $38 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FE
.ENDS

.SECTION "Animated Background Tiles - BANK 22" BANK BANK_SLOT2 SLOT 2 ALIGN $100
LaternFrame2:
; Tile index $008
.db $F4 $03 $0F $0F $E8 $07 $1F $1F $C0 $0F $3F $3F $EC $12 $10 $11 $E9 $14 $10 $13 $E3 $1C $10 $13 $C3 $29 $10 $17 $9F $41 $00 $3F
; Tile index $009
.db $C3 $29 $10 $17 $E3 $1D $10 $13 $E3 $1C $10 $13 $E9 $14 $10 $13 $EC $12 $10 $11 $E6 $19 $18 $18 $C0 $3F $3F $3F $E0 $1F $00 $00
; Tile index $00A
.db $1F $E0 $E0 $E0 $0F $F0 $F0 $F0 $07 $F8 $F8 $F8 $6F $90 $10 $10 $2F $50 $10 $90 $8F $70 $10 $90 $87 $28 $10 $D0 $F3 $04 $00 $F8
; Tile index $00B
.db $87 $28 $10 $D0 $8F $70 $10 $90 $8F $70 $10 $90 $2F $50 $10 $90 $6F $90 $10 $10 $CF $30 $30 $30 $07 $F8 $F8 $F8 $07 $F8 $00 $00

QBlockFrame2:
; Tile index $008
.db $00 $00 $00 $7F $3F $10 $20 $FF $7F $3F $40 $FF $7F $38 $47 $FF $7C $70 $0C $FF $7D $31 $0C $FF $7D $31 $0C $FF $79 $38 $01 $FF
; Tile index $009
.db $7F $3E $01 $FF $7F $3F $00 $FF $7F $3E $01 $FF $7F $3E $01 $FF $7F $1F $00 $FF $3F $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $7F
; Tile index $00A
.db $00 $00 $00 $FE $F8 $00 $00 $FF $FC $F0 $00 $FF $FC $38 $C0 $FF $7C $18 $60 $FF $EC $88 $60 $FF $EC $08 $E0 $FF $8C $08 $80 $FF
; Tile index $00B
.db $BC $38 $80 $FF $3C $38 $00 $FF $FC $78 $80 $FF $BC $38 $80 $FF $3C $38 $00 $FF $F8 $00 $00 $FF $00 $00 $00 $FF $00 $00 $00 $FE
.ENDS

.SECTION "Animated Background Tiles - BANK 30" BANK BANK_SLOT2 SLOT 2 ALIGN $100
GrassFrame0:
; Tile index $000
.db $07 $00 $07 $00 $69 $07 $69 $06 $FE $61 $FF $00 $F3 $4E $F3 $0C $EF $BF $EF $10 $F3 $7F $FF $00 $FD $47 $FF $00 $DA $BF $DF $20
; Tile index $001
.db $00 $00 $00 $00 $01 $00 $01 $00 $02 $01 $02 $01 $05 $03 $05 $02 $35 $03 $35 $02 $4B $37 $4B $34 $EB $56 $EB $14 $FF $1A $FF $00
; Tile index $002
.db $3F $CA $3F $C0 $CF $35 $CF $30 $F7 $DA $F7 $08 $7F $DB $FF $00 $BE $6D $FF $00 $DE $BD $FF $00 $DE $BF $FF $00 $9C $FF $FF $00
; Tile index $003
.db $40 $00 $40 $00 $A0 $40 $A0 $40 $C0 $80 $C0 $00 $B0 $00 $B0 $00 $F8 $30 $F8 $00 $F6 $40 $F6 $00 $BB $C6 $FB $04 $AE $DC $EE $10
; Tile index $004
.db $9C $F8 $DC $20 $B9 $F0 $F9 $00 $6A $F1 $FA $01 $EF $F1 $FF $00 $D7 $EB $FF $00 $D6 $EF $FF $00 $44 $FF $FF $00 $18 $FF $FF $00
; Tile index $005
.db $E0 $00 $E0 $00 $70 $E0 $70 $80 $FC $C0 $FC $00 $DA $8C $DA $04 $34 $D8 $F4 $08 $78 $B0 $F8 $00 $E8 $70 $F8 $00 $10 $E0 $F0 $00
.ENDS

.SECTION "Animated Background Tiles - BANK31" BANK BANK_SLOT2 SLOT 2 ALIGN $100
GrassFrame1:
; Tile index $006
.db $27 $03 $27 $00 $7E $21 $7F $00 $63 $1E $63 $1C $FF $4F $FF $00 $FF $93 $FF $00 $DD $2B $DF $20 $FE $2D $FF $00 $FA $B7 $FF $00
; Tile index $007
.db $00 $00 $00 $00 $00 $00 $00 $00 $08 $00 $08 $00 $14 $08 $14 $08 $25 $18 $25 $18 $3A $15 $3A $05 $3F $1B $3F $00 $DF $2B $DF $20
; Tile index $008
.db $8E $F7 $8F $70 $F5 $BA $F7 $08 $75 $DA $F7 $08 $BB $6D $FB $04 $BF $6D $FF $00 $DE $BD $FF $00 $DE $BF $FF $00 $3C $FF $FF $00
; Tile index $009
.db $00 $00 $00 $00 $00 $00 $00 $00 $30 $00 $30 $00 $F8 $30 $F8 $00 $70 $E0 $70 $80 $F0 $C0 $F0 $00 $F8 $B0 $F8 $00 $D7 $60 $F7 $00
; Tile index $00A
.db $9B $67 $FB $04 $A7 $DC $E7 $18 $DD $B8 $DD $20 $BA $F1 $BA $41 $E5 $FB $FD $02 $EF $FF $FF $00 $44 $FF $FF $00 $10 $FF $FF $00
; Tile index $00B
.db $80 $00 $80 $00 $38 $00 $38 $00 $CE $38 $CE $30 $7C $E0 $7C $80 $FE $9C $FE $00 $FF $72 $FF $00 $72 $E0 $F2 $00 $90 $E0 $F0 $00
.ENDS

.SECTION "Animated Background Tiles - BANK 32" BANK BANK_SLOT2 SLOT 2 ALIGN $100
GrassFrame2:
; Tile index $00C
.db $5F $00 $5F $00 $FC $4F $FC $03 $FF $53 $FF $00 $FE $1D $FF $00 $9F $EE $FF $00 $BF $56 $FF $00 $FE $35 $FF $00 $FA $B7 $FF $00
; Tile index $00D
.db $00 $00 $00 $00 $00 $00 $00 $00 $03 $00 $03 $00 $14 $03 $14 $03 $6B $16 $6B $14 $BE $54 $BE $40 $DB $66 $DF $20 $6F $32 $6F $10
; Tile index $00E
.db $75 $3A $77 $08 $F7 $38 $F7 $08 $3B $DD $3B $C4 $BB $DD $BB $44 $5F $ED $DF $20 $7E $ED $FF $00 $2E $FF $FF $00 $A4 $FF $FF $00
; Tile index $00F
.db $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $00 $8C $00 $8C $00 $7A $8C $7A $84 $DD $36 $DD $22 $B5 $7A $BD $42 $6B $F4 $7F $80
; Tile index $010
.db $DF $E0 $FF $00 $F1 $CF $F1 $0E $ED $BE $EF $10 $7A $BD $FE $01 $65 $FB $FD $02 $CF $F7 $FF $00 $43 $FE $FF $00 $10 $FF $FF $00
; Tile index $011
.db $80 $00 $80 $00 $F0 $80 $F0 $00 $C8 $70 $C8 $30 $74 $E8 $74 $88 $BE $C0 $FE $00 $FF $1E $FF $00 $7E $F0 $FE $00 $94 $E8 $FC $00
.ENDS