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


;   INFO: GIVEN HL, HL WILL BE REPLACE WITH (HL)
;   INPUT: HL - VALUE,
;   OUTPUT: HL - (VALUE)
;   USES: HL, A
.ORG $0018
getDataAtHL:
    LD A, (HL)
    INC HL
    LD H, (HL)
    LD L, A
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
;   USES: HL, AF
.ORG $0028
JumpEngine:
    POP HL                      ;pull saved return address from stack
    ADD A, A                    ;shift bit from contents of A
    addAToHL_M                  ;load pointer from indirect
    LD A, (HL)                  ;note that if an RTS is performed in next routine
    INC HL                      ;it will return to the execution before the sub
    LD H, (HL)                  ;that called this routine
    LD L, A
    JP (HL)                     ;jump to the address we loaded
    .db $00, $00, $00, $00      ;FILL

;-------------------------------------------------------------------------------------
;   VDP VECTOR
.ORGA $0038
VdpVector:
    ;JP NonMaskableInterrupt     ; NOT REALLY NON MASKABLE...
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
    LD A, %00100100                 ;TURN OFF H-INTS
    OUT (VDPCON_PORT), A
    LD A, $80
    OUT (VDPCON_PORT), A
    LD A, (HorizontalScroll)        ;UPDATE VDP HSCROLL
    NEG
    LD (VDPHScroll), A
    JP NMIDone


;-------------------------------------------------------------------------------------
;   PAUSE BUTTON VECTOR
.ORGA $0066
PauseBtnVector:
    PUSH AF                     ; SAVE AF
    LD A, $01 << SMS_BTN_START
    LD (PauseButtonFlag), A
    POP AF                      ; RESTORE AF
    RETN                        ; RETURN FROM NMI

;-------------------------------------------------------------------------------------
;   MAIN PROGRAM START
Start:
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
;   LOAD CONSTANT BACKGROUND TILES
    LD A, :Tiles_BG_Comm
    LD (MAPPER_SLOT2), A 
    LD HL, VRAM_ADR_BG_COMM | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_BG_Comm
    LD BC, _sizeof_Tiles_BG_Comm
    CALL copyToVDP
;   LOAD (mostly) CONSTANT SPRITE TILES
    LD A, :Tiles_SPR_Comm
    LD (MAPPER_SLOT2), A
    LD HL, VRAM_ADR_SPR_COMM | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_SPR_Comm
    LD BC, _sizeof_Tiles_SPR_Comm
    CALL copyToVDP
;   LOAD (most) ENEMY SPRITE TILES
    LD A, :Tiles_SPR_Enemies
    LD (MAPPER_SLOT2), A
    LD HL, VRAM_ADR_SPR_EMY | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_SPR_Enemies
    LD BC, _sizeof_Tiles_SPR_Enemies
    CALL copyToVDP
    /*
;   LOAD LEVEL BACKGROUND TILES (TEST)
    LD A, :Tiles_BG_Overworld
    LD (MAPPER_SLOT2), A
    LD HL, VRAM_ADR_BG_LVL | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_BG_Overworld
    LD BC, _sizeof_Tiles_BG_Overworld
    CALL copyToVDP
    */
    /*
;   LOAD BACKGROUND PALETTE (TEST)
    LD A, :GroundPaletteData
    LD (MAPPER_SLOT2), A 
    LD HL, $C000 | VRAMWRITE
    RST setVDPAddress
    LD HL, GroundPaletteData + $03
    LD BC, $2000 + VDPDATA_PORT
    OTIR
    */
;
    LD A, BANK_SLOT2                ; restore bank
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
    LD A, $A5
    LD (WarmBootValidation), A      ;set warm boot flag
    LD (PseudoRandomBitReg), A      ;set seed for pseudorandom register
    CALL MoveAllSpritesOffscreen
    CALL InitializeNameTables       ;initialize name table
    LD A, $01                       ;set flag to disable screen output
    LD (DisableScreenFlag), A
    LD A, (Mirror_VDP_REG1)         ;enable NMIs
    OR A, %10100000
    LD (Mirror_VDP_REG1), A         ;write contents of A to PPU register 1
    OUT (VDPCON_PORT), A            ;and its mirror
    LD A, $81
    OUT (VDPCON_PORT), A

    ; SET LINE COUNTER
    LD A, $07
    OUT (VDPCON_PORT), A
    LD A, $8A
    OUT (VDPCON_PORT), A

    XOR A
    LD (FrameDoneFlag), A

    CALL waitForVblank
    IN A, (VDPCON_PORT)             ;clear any pending VDP interrupts
    EI                              ;enable Z80 interrupts
EndlessLoop:
    ; SKIP TO PAUSE ROUTINE IF GAME IS PAUSED
    LD A, (GamePauseStatus)
    RRCA
    JP C, DoPauseRoutine
    ; DO MAIN GAME EXEC
    CALL OperModeExecutionTree
    ; UPDATE TOP SCORES
    LD DE, PlayerScoreDisplay + $05     ;start with mario's score
    CALL TopScoreCheck
    LD DE, OffScr_ScoreDisplay + $05    ;now do luigi's score
    CALL TopScoreCheck
    ; DO TIMER UPDATE
    LD HL, TimerControl
    LD A, (HL)
    OR A                            ;if master timer control not set, decrement
    JP Z, DecTimers                 ;all frame and interval timers
    DEC (HL)
    JP NZ, NoDecTimers
DecTimers:
    LD DE, Timers + $14             ;load end offset for end of frame timers
    LD B, $15
    LD HL, IntervalTimerControl
    DEC (HL)                        ;decrement interval timer control,
    JP P, DecTimersLoop             ;if not expired, only frame timers will decrement
    LD (HL), $14                    ;if control for interval timers expired,
    LD DE, Timers + $23             ;interval timers will decrement along with frame timers
    LD B, $24
DecTimersLoop:
    LD A, (DE)                      ;check current timer
    OR A
    JP Z, SkipExpTimer              ;if current timer expired, branch to skip,
    DEC A                           ;otherwise decrement the current timer
    LD (DE), A
SkipExpTimer:
    DEC E                           ;move onto next timer
    DJNZ DecTimersLoop              ;do this until all timers are dealt with   
NoDecTimers:
    LD HL, FrameCounter             ;increment frame counter
    INC (HL)
;   PAUSE ROUTINE
DoPauseRoutine:
    LD A, (OperMode)                ;are we in victory mode?
    CP A, MODE_VICTORY              ;if so, go ahead
    JP Z, ChkPauseTimer
    CP A, MODE_GAMEPLAY             ;are we in game mode?
    JP NZ, TickPRNG                 ;if not, leave
    LD A, (OperMode_Task)           ;if we are in game mode, are we running game engine?
    CP A, $03
    JP NZ, TickPRNG
ChkPauseTimer:
    LD A, (GamePauseTimer)          ;check if pause timer is still counting down
    OR A
    JP Z, ChkStart
    DEC A
    LD (GamePauseTimer), A          ;if so, decrement and leave
    JP TickPRNG
ChkStart:
    LD A, (SavedJoypad1Bits)        ;check to see if start is pressed
    AND A, $01 << SMS_BTN_START
    JP Z, ClrPauseTimer
    LD A, (GamePauseStatus)         ;check to see if timer flag is set
    AND A, $80                      ;and if so, do not reset timer
    JP NZ, TickPRNG
    LD A, $2B                       ;set pause timer
    LD (GamePauseTimer), A
    LD A, SNDID_PAUSE
    LD (SFXTrack0.SoundQueue), A
    LD A, $01
    LD (SndPauseFlag), A
    LD A, (GamePauseStatus)
    XOR A, $01                      ;invert d0 and set d7
    OR A, $80
    JP SetPause                    ;unconditional branch
ClrPauseTimer:
    LD A, (GamePauseStatus)         ;clear timer flag if timer is at zero and start button
    AND A, $7F                      ;is not pressed
SetPause:
    LD (GamePauseStatus), A
;   PRNG UPDATE
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

    CALL SoundEngine
;   MAIN LOOP WAIT
    LD HL, FrameDoneFlag
    INC (HL)
NMIWait:
    LD A, (FrameDoneFlag)
    OR A
    JP NZ, NMIWait

    JP EndlessLoop                  ;endless loop, need I say more?

;-------------------------------------------------------------------------------------

.SECTION "VRAM Action Table" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
VRAM_AddrTable:
    .dw VRAM_Buffer1, WaterPaletteData, GroundPaletteData,
    .dw UndergroundPaletteData, CastlePaletteData, TitleScreenData
    .dw VRAM_Buffer2, VRAM_Buffer2, BowserPaletteData                   ; Second VRAM_Buffer2 is never used?
    .dw DaySnowPaletteData, NightSnowPaletteData, MushroomPaletteData
    .dw MarioThanksMessage, LuigiThanksMessage, MushroomRetainerSaved
    .dw PrincessSaved1, PrincessSaved2, WorldSelectMessage1
    .dw WorldSelectMessage2
.ENDS

NonMaskableInterrupt:
;   SAVE ALL REGISTERS
    PUSH BC
    PUSH DE
    PUSH HL
    PUSH IX
;   INITIALIZE H SCROLL REG
InitHScroll:
    XOR A
    OUT (VDPCON_PORT), A
    LD A, $88
    OUT (VDPCON_PORT), A
;   CHECK FOR LAG FRAME
    LD A, (FrameDoneFlag)
    SRL A
    JP NC, LagFrame
    LD (FrameDoneFlag), A
;   TURN OFF SCREEN IF FLAG IS SET
CheckScreenFlag:
    LD A, (Mirror_VDP_REG1)         ;disable display in mirror reg
    AND A, %10111111                ;save all other bits
    LD HL, DisableScreenFlag        ;get screen disable flag
    BIT 0, (HL)
    JP NZ, ScreenOff                ;if set, used bits as-is
    OR A, %01000000                 ;otherwise reenable display bit and save them
ScreenOff:
    LD (Mirror_VDP_REG1), A         ;save bits for later but not in register at the moment
    AND A, %10111111                ;disable screen for now
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A
;   SPRITE UPDATE       [CPU TIME: 10 LINES]
    ; WRITE Y POSITIONS
    XOR A
    OUT (VDPCON_PORT), A
    LD A, >VRAM_ADR_SPRTBL | >VRAMWRITE
    OUT (VDPCON_PORT), A
    LD HL, Sprite_Y_Position
    LD C, VDPDATA_PORT
    CALL OutiBlock128 + $80   ; SKIP THE FIRST 64 OUTIs
    ; WRITE X POSITIONS AND TILE INDEXES
    LD A, <VRAM_ADR_SPRTBL + $80
    OUT (VDPCON_PORT), A
    LD A, >VRAM_ADR_SPRTBL | >VRAMWRITE
    OUT (VDPCON_PORT), A
    LD L, <Sprite_X_Position
    CALL OutiBlock128
;   NAMETABLE UPDATE
    LD A, (VRAM_Buffer_AddrCtrl)    ;load control for pointer to buffer contents
    LD B, A                         ; SAVE
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
    JP Z, +                         ;if not used, skip
    LD HL, VRAM_Buffer1
    LD (VRAM_Buffer1_Ptr), HL
+:
    LD (HL), $00                    ;clear buffer header
    XOR A
    LD (VRAM_Buffer_AddrCtrl), A    ;reinit address control to $0301 (VRAM_Buffer1)
;   TILE STREAMING
    LD HL, TileStreamRet
    PUSH HL
    LD HL, (PlayerGfxOffset_Old)
    LD DE, (PlayerGfxOffset)
    SBC HL, DE
    JP NZ, StreamPlayerTiles        ;[CPU TIME: 20 LINES]
    JP StreamAnimatedBGTiles        ;[CPU TIME: ~25 LINES]
TileStreamRet:
    LD A, (Mirror_VDP_REG1)         ;this is where the screen is re-enabled if DisableScreenFlag is clear  
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A
    CALL ReadJoypads
;   DO SPRITE SHUFFLE IF (SPRITE 0 FLAG ISN'T SET && GAME ISN'T PAUSED)
    LD A, (Sprite0HitDetectFlag)
    OR A
    JP Z, DoSound
    LD A, (GamePauseStatus)
    RRCA
    CALL NC, SpriteShuffler
LagFrame:
;   ONLY SET H-INT IF FLAG IS SET
    LD A, (Sprite0HitDetectFlag)
    OR A
    JP Z, DoSound
    LD A, %00110100
    OUT (VDPCON_PORT), A
    LD A, $80
    OUT (VDPCON_PORT), A
DoSound:
    ;CALL SoundEngine
;   RESTORE REGISTERS
    POP IX
    POP HL
    POP DE
    POP BC
NMIDone:
    POP AF
;   NMI END
    EI                              ;enable Z80 interrupts
    RET



;-------------------------------------------------------------------------------------

.ORGA $0700

.SECTION "Nibble Bit Order Flip TBL for ReadJoypads" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
NibbleBitFlipTable:
    .db $00, $08, $04, $0C, $02, $0A, $06, $0E, $01, $09, $05, $0D, $03, $0B, $07, $0F
.ENDS

ReadJoypads:
;   SET PORT 1'S TH TO HIGH OUTPUT
    LD A, ~($01 << P1_TH_DIR)
    OUT (IO_CONTROL), A
;   CONTROL 1
    IN A, (CONTROLPORT1)
    CPL                             ; INVERT SO 1 = PRESSED, 0 = NO PRESS
    LD D, A                         ; SAVE FOR LATER
    AND A, %00111111                ; REMOVE CONTROLLER 2'S BITS
    LD B, A                         ; AND STORE IN B
    AND A, %00110000                ; KEEP ONLY BTN 1 & 2
    ADD A, A                        ; MOVE D5,D4 TO D7,D6
    ADD A, A
    LD C, A                         ; STORE IN C
    LD A, B
    AND A, $0F                      ; KEEP ONLY LOWER NIBBLE (DIRECTIONALS)
    LD HL, NibbleBitFlipTable       ; REVERSE BIT ORDER TO MATCH NES DIRECTIONALS
    addAToHL8_M
    LD A, (HL)
    OR A, C                         ; COMBINE NEW DIRECTIONS AND BUTTONS

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
    LD A, D                         ; GET CONTROLLER 2'S DOWN, UP
    RLCA                            ; AND MOVE THEM FROM D7,D6 TO D1,D0
    RLCA
    AND A, %00000011                ; ISOLATE AND STORE IN B
    LD B, A
    IN A, (CONTROLPORT2)            ; GET OTHER BITS FOR CONTROLLER 2
    CPL
    BIT 4, A                        ; CHECK IF RESET BUTTON IS PRESSED
    JP NZ, BootVector               ; IF SO, RESET THE GAME
    ADD A, A                        ; MOVE D1,D0 TO D3,D2
    ADD A, A
    LD C, A                         ; STORE IN C
    AND A, %00001100                ; ISOLATE BITS AND OR WITH DOWN,UP
    OR A, B
    LD HL, NibbleBitFlipTable       ; REVERSE BIT ORDER TO MATCH NES DIRECTIONALS
    addAToHL8_M
    LD B, (HL)
    LD A, C                         ; MOVE D5,D4 TO D7,D6
    ADD A, A
    ADD A, A
    AND A, %11000000                ; ISOLATE AND COMBINE WITH DIRECTIONALS
    OR A, B

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
;   ACCOUNT FOR PAUSE BUTTON
    LD HL, SavedJoypad1Bits
    LD A, (PauseButtonFlag)
    OR A, (HL)
    LD (HL), A
    XOR A
    LD (PauseButtonFlag), A
;   MD CONTROLLER PAUSE CHECK
    LD HL, MDControllerBits
    ; SET PORT 1'S TH TO LOW OUTPUT
    LD A, ~($01 << P1_TH_LVL | $01 << P1_TH_DIR)
    OUT (IO_CONTROL), A
    ; GET INPUTS (A, START)
    ;LD A, (IX + 0)  ; TIME WASTE
    ;LD A, (IX + 0)  ; TIME WASTE
    ;NOP             ; TIME WASTE
    IN A, CONTROLPORT1
    CPL
    LD (HL), A
    ; EXIT IF MD CONTROLLER ISN'T PLUGGED IN
    AND A, $01 << P1_DIR_LEFT | $01 << P1_DIR_RIGHT
    CP A, $01 << P1_DIR_LEFT | $01 << P1_DIR_RIGHT
    RET NZ
    ; DEBOUNCE INPUTS AND SET START BUTTON IF NEWLY PRESSED
    LD B, (HL)
    LD A, (MDControllerBitsOld)
    XOR A, (HL)
    AND A, (HL)
    LD (HL), A
    LD HL, SavedJoypad1Bits
    AND A, $01 << P1_BTN_2
    RRCA            ; MOVE TO SMS_BTN_START INDEX
    OR A, (HL)
    LD (HL), A
    LD A, B
    LD (MDControllerBitsOld), A
    RET

;-------------------------------------------------------------------------------------

;   EDITED STRIPE FORMAT: 
;   D7 - 0 = WRITE HORIZONTALLY, 1 = WRITE VERTICALLY
;   D6 - 0 = WRITE BYTE, 1 = WRITE WORD
;   D5->D0 = LENGTH

;   00 - WRITE BYTES HORIZONTAL
;   01 - WRITE WORDS HORIZONTAL
;   02 - WRITE BYTES VERTICAL
;   03 - WRITE WORDS VERTICAL

UpdateScreen:
    LD A, B
    CP A, VRAMTBL_BUFFER2
    JP Z, WriteVertColumnBuff2
    LD IXH, >WriteHoriBlock
@SkipBuff2Chk:
;   Push new return address after writing is done
    ;LD DE, ScreenWriteReturn
    ;PUSH DE
;   Write Address to VDP
    INC HL
    LD A, (HL)
    OUT (VDPCON_PORT), A        ;write low byte
    DEC HL
    LD A, (HL)
    OUT (VDPCON_PORT), A        ;write high byte
    INC HL
;   Do appropriate mode (horizontal)
    INC HL
    LD A, (HL)                  ;get write type
    AND A, %11000000            ;and check if write mode is 2 or greater (D7 set)
    ;JP M, VertWritePrep         ;if so, prepare to do vertical write
    LD A, (HL)
    JP Z, HoriWriteMode_B       ; 40
HoriWriteMode_W:    ; OVERHEAD: 50
    ADD A, A                    ; count*4
HoriWriteMode_B:    ; OVERHEAD: 46
    ADD A, A                    ; count*2
    NEG
    LD IXL, A
    INC HL
    LD C, VDPDATA_PORT
    CALL IndirectCallIX
ScreenWriteReturn:
;   check if buffer is empty
    LD A, (HL)
    OR A
    JP NZ, UpdateScreen@SkipBuff2Chk    ; if not, keep updating screen
    RET


WriteVertColumnBuff2:
;   ADVANCE POINTER TO TILE DATA
    INC L
    INC L
    LD C, VDPDATA_PORT
;   PREPARE SHADOW REGS
    EXX
    LD HL, (VRAM_Buffer2)
    LD A, L
    LD L, H
    LD H, A
    LD C, VDPCON_PORT
    LD DE, $0040
    EXX
;   WRITE 23 WORDS VERTICALLY
    JP WriteVeriBlock_W ;- 11 * 23   ; 11 bytes per word

IndirectCallIX:
    JP (IX)

IndirectCallIY:
    JP (IY)

;-------------------------------------------------------------------------------------

TopScoreCheck:
    LD HL, TopScoreDisplay + $05        ;start with the lowest digit
    LD B, $06
GetScoreDiff:
    LD A, (DE)                          ;subtract each player digit from each high score digit
    SBC A, (HL)                         ;from lowest to highest, if any top score digit exceeds
    DEC E                               ;any player digit, borrow will be set until a subsequent
    DEC L                               ;subtraction clears it (player digit is higher than top)
    DJNZ GetScoreDiff
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
;   
    LD BC, $0F0A                ;load preset value which will put it at sprite #10
    LD A, (SprShuffleAmtOffset)
    ADD A, $C0
    LD H, A
    LD L, <SprShuffleAmt
    LD DE, SprDataOffset + (SPRDATA_FIRE2 * $100)  ;start at the end of OAM data offsets
@ShuffleLoop:
    LD A, (DE)                  ;check for offset value against
    CP A, C                     ;the preset value
    JP C, @NextSprOffset        ;if less, skip this part
    ADD A, (HL)                 ;add shuffle amount to current sprite offset
    CP A, $40                   
    JP C, @StrSprOffset         ;if not exceeded $3f, skip second add
    AND A, %00111111
    ADD A, C                    ;otherwise add preset value to offset
@StrSprOffset:
    LD (DE), A                  ;store new offset here or old one if branched to here
@NextSprOffset:
    DEC D                       ;move backwards to next one
    DJNZ @ShuffleLoop
    LD A, (SprShuffleAmtOffset) ;load offset
    INC A
    CP A, $03                   ;check if offset + 1 goes to 3
    JP NZ, @SetAmtOffset        ;if offset + 1 not 3, store
    XOR A                       ;otherwise, init to 0
@SetAmtOffset:
    LD (SprShuffleAmtOffset), A
    LD DE, SprDataOffset + (SPRDATA_MISC7 * $100)
    LD HL, SprDataOffset + (SPRDATA_SLOT7 * $100)
    ;LD B, $03
;@SetMiscOffset:
.REPEAT $03
    LD A, (HL)  ; OFFSET: SLOT 7*, SLOT 6, SLOT 5   *I don't think slot 7 is used/valid      
    LD (DE), A  ; OFFSET: MISC 7, MISC 4, MISC 1
    ADD A, $02  ; $08
    INC D
    LD (DE), A  ; OFFSET: MISC 8, MISC 5, MISC 2
    ADD A, $02  ; $08
    INC D
    LD (DE), A  ; OFFSET: MISC 9, MISC 6, MISC 3
    LD A, D
    SUB A, $05
    LD D, A
    DEC H
.ENDR
    ;DJNZ @SetMiscOffset         ;do this until all misc spr offsets are loaded
    RET

;-------------------------------------------------------------------------------------

MoveAllSpritesOffscreen:
MoveSpritesOffscreen:
    LD HL, Sprite_Y_Position
    LD DE, Sprite_Y_Position + $01
    LD (HL), YPOS_OFFSCREEN
    ;LD BC, $003F
    ;LDIR
    .REPEAT $3F
    LDI
    .ENDR
    RET

;-------------------------------------------------------------------------------------

GetAreaMusic:
    LD A, (OperMode)
    OR A
    RET Z
;
    LD A, (AltEntranceControl)
    CP A, $02
    JP Z, ChkAreaType
;
    LD C, $05
    LD A, (PlayerEntranceCtrl)
    CP A, $06
    JP Z, StoreMusic
    CP A, $07
    JP Z, StoreMusic
ChkAreaType:
    LD A, (AreaType)
    LD C, A
    LD A, (CloudTypeOverride)
    OR A
    JP Z, StoreMusic
    LD C, $04
StoreMusic:
    LD A, C
    ADD A, SNDID_WATER
    LD (MusicTrack0.SoundQueue), A
    RET


;-------------------------------------------------------------------------------------

InitializeNameTables:
    LD HL, VRAM_ADR_NAMETBL | VRAMWRITE
    CALL setVDPAddress
    LD BC, lobyte(NAMETABLE_SIZE) * $100 + hibyte(NAMETABLE_SIZE)
    XOR A                                    ;clear name table with blank tile
@writeLoop:
    OUT (VDPDATA_PORT), A
    DJNZ @writeLoop
    DEC C
    JP NZ, @writeLoop
;
    LD HL, VRAM_Buffer1
    LD (VRAM_Buffer1_Ptr), HL
    ;LD HL, VRAM_Buffer2
    ;LD (VRAM_Buffer2_Ptr), HL
    LD (VRAM_Buffer1), A
;
    LD (HorizontalScroll), A
    LD (VDPHScroll), A
    OUT (VDPCON_PORT), A
    LD A, $88
    OUT (VDPCON_PORT), A
    RET

;-------------------------------------------------------------------------------------
;   HL - RAM Address to start initializing

InitializeMemory:
-:
    LD (HL), $00
    DEC HL
    BIT 6, H
    JP NZ, -
;
    LD HL, VRAM_Buffer1
    LD (VRAM_Buffer1_Ptr), HL
    ;LD HL, VRAM_Buffer2
    ;LD (VRAM_Buffer2_Ptr), HL
;
    LD A, BANK_PLAYERGFX00
    LD (PlayerGfxBank), A
    LD HL, PlayerGraphicsTable@smlStand
    LD (PlayerGfxOffset), HL
;
    JP SndInitMemory@InitChanBits
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

;   ENEMY PARSER (SPRITE OBJECTS)
.INCLUDE "EnemyParser.asm"

;   MASTER SYSTEM VDP STUFF
.INCLUDE "smsFunctions.asm"

;   SOUND DRIVER
.INCLUDE "SoundDriver.asm"

;-------------------------------------------------------------------------------------

.SECTION "Game Text Stripe Data TBL" BANK BANK_SLOT2 SLOT 2 FREE
GameTextOffsets:
    .dw TopStatusBarLine, TopStatusBarLine
    .dw WorldLivesDisplay, WorldLivesDisplay
    .dw TimeUpDisplay, TimeUpDisplay
    .dw GameOverDisplay, GameOverDisplay
    ;.dw TwoPlayerTimeUp, OnePlayerTimeUp
    ;.dw TwoPlayerGameOver, OnePlayerGameOver
    .dw WarpZoneWelcome, WarpZoneWelcome
.ENDS

WriteGameText:
    PUSH AF                                 ;save text number to stack
    ADD A, A                                ;multiply by 2 and use as offset
    /*
    CP A, $04                               ;if set to do top status bar or world/lives display,
    JP C, @LdGameText                       ;branch to use current offset as-is
    CP A, $08                               ;if set to do time-up or game over,
    JP C, @Chk2Players                      ;branch to check players
    LD A, $08                               ;otherwise warp zone, therefore set offset
@Chk2Players:                               ;check for number of players
    LD HL, NumberOfPlayers
    BIT 0, (HL)
    JP NZ, @LdGameText                      ;if there are two, use current offset to also print name
    INC A                                   ;otherwise increment offset by one to not print name
    */
@LdGameText:
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
@EndGameText:
    XOR A                                   ;put null terminator at end
    LD (DE), A
    POP AF                                  ;pull original text number from stack
    CP A, $04                               ;are we printing warp zone?
    JP NC, @PrintWarpZoneNumbers
    DEC A                                   ;are we printing the world/lives display?
    JP NZ, @CheckPlayerName                 ;if not, branch to check player's name
    LD A, (NumberofLives)                   ;otherwise, check number of lives
    INC A                                   ;and increment by one for display
    CP A, $10                               ;more than 9 lives?
    JP C, @PutLives
    SUB A, $10                              ;if so, subtract 10 and put a crown tile
    LD HL, VRAM_Buffer1 + $0F               ;next to the difference...strange things happen if
    LD (HL), BG_MACRO($0E)                  ;the number of lives exceeds 19
    INC L
    LD (HL), $01
@PutLives:
    ADD A, BG_TILE_OFFSET
    LD (VRAM_Buffer1 + $0D), A                    
    LD A, (WorldNumber)                     ;write world and level numbers (incremented for display)
    ADD A, BG_TILE_OFFSET + $01             ;to the buffer in the spaces surrounding the dash
    LD (VRAM_Buffer1 + $20), A
    LD A, (LevelNumber)
    ADD A, BG_TILE_OFFSET + $01
    LD (VRAM_Buffer1 + $24), A              ;we're done here
    RET

@CheckPlayerName:
    LD A, (NumberOfPlayers)
    OR A
    RET Z
;
    LD HL, MarioName
    LD A, (CurrentPlayer)
    OR A
    JP Z, +
    LD HL, LuigiName
+:
    LD C, (HL)                              ;LOAD BYTE COUNT
    LD B, $00
    INC HL
    LD DE, VRAM_Buffer1 + $15
    LDIR                                    ;WRITE MESSAGE DATA TO BUFFER
    RET

@PrintWarpZoneNumbers:
    RET
    /*
    SUB A, $04                              ;subtract 4 and then shift to the left
    ADD A, A                                ;twice to get proper warp zone number
    ADD A, A                                ;offset
    LD HL, WarpZoneNumbers
    addAToHL_M
    LD DE, VRAM_Buffer1 + 27
    LD B, $0C
@WarpNumLoop:
    LD A, (HL)                              ;print warp zone numbers into the
    LD (DE), A                              ;placeholders from earlier
    INC HL
    INC E                                   ;put a number in every fourth space
    INC E
    INC E
    INC E
    DJNZ @WarpNumLoop
    LD A, $2C                               ;load new buffer pointer at end of message
    JP SetVRAMOffset
    */

;-------------------------------------------------------------------------------------
;$00(IXL) - used to store status bar nybbles
;$02 - used as temp vram offset
;$03 - used to store length of status bar number

.SECTION "Status Bar VDP Address and Length Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
StatusBarData:
    /*
    .db $f0, $06 ; top score display on title screen
    .db $62, $06 ; player score
    .db $62, $06
    .db $6d, $02 ; coin tally
    .db $6d, $02
    .db $7a, $03 ; game timer
    */
    .dw swapBytes(xyToNameTbl_M(16, 20)), $0C   ; top score display on title screen
    .dw swapBytes(xyToNameTbl_M(3, 0)), $0C     ; player score
    .dw swapBytes(xyToNameTbl_M(3, 0)), $0C     ; 2nd player score
    .dw swapBytes(xyToNameTbl_M(14, 0)), $04    ; coin tally
    .dw swapBytes(xyToNameTbl_M(14, 0)), $04    ; 2nd coin tally
    .dw swapBytes(xyToNameTbl_M(27, 0)), $06    ; game timer
.ENDS

.SECTION "Status Bar RAM Offsets Data" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
;   RAM ADDRESSES FOR DIGITS
StatusBarOffset:
    ;.db $06, $0c, $12, $18, $1e, $24
    .dw TopScoreDisplay                         ; top score display on title screen
    .dw PlayerScoreDisplay                      ; player score
    .dw OffScr_ScoreDisplay                     ; 2nd player score
    .dw PlayerCoinDisplay                       ; coin tally
    .dw OffScr_CoinDisplay                      ; 2nd coin tally
    .dw GameTimerDisplay                        ; game timer
    ;.dw DisplayDigits+($06-$06) ; top score display on title screen
    ;.dw DisplayDigits+($0C-$06) ; player score
    ;.dw DisplayDigits+($12-$06)
    ;.dw DisplayDigits+($18-$02) ; coin tally
    ;.dw DisplayDigits+($1E-$02)
    ;.dw DisplayDigits+($24-$03) ; game timer
.ENDS

PrintStatusBarNumbers:
    LD IXL, A ;LD I, A                     ;store player-specific offset
    CALL OutputNumbers          ;use first nybble to print the coin display
    LD A, IXL ;LD A, I
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
    LD B, (HL)                  ;STORE COUNT IN B FOR LATER
    SRL B
    LDI                         ;WRITE COUNT
    POP AF
    ADD A, A ;
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
    INC HL
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
    LD HL, DigitModifier + ($05 * $100)
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
;
EraseDMods:
    XOR A
    LD HL, DigitModifier + ($05 * $100)
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
;   PlayerGfxOffset - %PPMMMMMMMMMMMMMM [P = PALETTE, M = MAPPING POINTER]
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
    AND A, %11000000
    RRCA
    RRCA
    LD IXL, A
    LD A, D
    AND A, %00111111
    LD D, A
;   WRITE TILE DATA
    ; TILE 0 [38 + 512 = 550]
    LD A, (DE)
    LD L, A
    INC DE
    LD A, (DE)
    OR A, IXL
    LD H, A
    INC DE
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 1 [38 + 512 = 550]
    LD A, (DE)
    LD L, A
    INC DE
    LD A, (DE)
    OR A, IXL
    LD H, A
    INC DE
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 2 [38 + 512 = 550]
    LD A, (DE)
    LD L, A
    INC DE
    LD A, (DE)
    OR A, IXL
    LD H, A
    INC DE
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 3 [38 + 512 = 550]
    LD A, (DE)
    LD L, A
    INC DE
    LD A, (DE)
    OR A, IXL
    LD H, A
    INC DE
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 4 [38 + 512 = 550]
    LD A, (DE)
    LD L, A
    INC DE
    LD A, (DE)
    OR A, IXL
    LD H, A
    INC DE
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 5 [38 + 512 = 550]
    LD A, (DE)
    LD L, A
    INC DE
    LD A, (DE)
    OR A, IXL
    LD H, A
    INC DE
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 6 [38 + 512 = 550]
    LD A, (DE)
    LD L, A
    INC DE
    LD A, (DE)
    OR A, IXL
    LD H, A
    INC DE
    .REPEAT $20
    OUTI
    .ENDR
    ; TILE 7 [32 + 512 = 544]
    LD A, (DE)
    LD L, A
    INC DE
    LD A, (DE)
    OR A, IXL
    LD H, A
    .REPEAT $20
    OUTI
    .ENDR
    ; DEFAULT BANK
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    RET


;   BC
;   DE
;   HL
;   IXL
StreamAnimatedBGTiles:
    LD C, VDPDATA_PORT
;   SLOT 0 (4 or less)
    ; CHECK ANIMATE FLAG
    LD DE, BGTileQueue0.UpdateFlag
    LD A, (DE)
    OR A
    JP Z, @CheckSlot1
    XOR A
    LD (DE), A
    INC E
    ; SET VDP ADDRESS
    LD A, (DE)
    INC E
    OUT (VDPCON_PORT), A
    LD A, (DE)
    INC E
    OUT (VDPCON_PORT), A
    ; GET COUNT AND POINTER   
    LD A, (DE)
    INC E
    ADD A, A
    NEG
    LD IXL, A
    LD A, (DE)
    INC E
    LD L, A
    LD A, (DE)
    LD H, A
    ; DEREFERENCE POINTER
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    ; WRITE TO VRAM
    LD IXH, >OutiBlock128
    CALL IndirectCallIX
@CheckSlot1:
;   SLOT 1 (FIXED 6)
    ;RET
    ; CHECK ANIMATE FLAG
    LD DE, BGTileQueue1.UpdateFlag
    LD A, (DE)
    OR A
    RET Z;JP Z, @CheckSlot1
    XOR A
    LD (DE), A
    INC E
    ; SET VDP ADDRESS
    LD A, (DE)
    INC E
    OUT (VDPCON_PORT), A
    LD A, (DE)
    INC E
    OUT (VDPCON_PORT), A
    ; GET COUNT AND POINTER   
    LD A, (DE)
    INC E
    LD B, A
    LD A, (DE)
    INC E
    LD L, A
    LD A, (DE)
    LD H, A
    ; DEREFERENCE POINTER
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    ; WRITE TO VRAM
    CALL OutiBlock128
    JP OutiBlock128 + $80

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
    .db $80         ; SET BIT 7...
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
    .db $FF         ; DISABLE LINE COUNTER...
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

    /*
;   0x0101 - 0x0341
.REPT $40           ; 09 (8 + 1) bytes per iteration
    EXX
    OUT (C), L      ; WRITE VDP ADDRESS
    OUT (C), H
    ADD HL, DE      ; INCREMENT ADDRESS FOR NEXT ROW
    EXX
    OUTI            ; WRITE BYTE FOR CURRENT ROW
.ENDR
WriteVeriBlock_B:
    RET
    */
    /*
;   0x0342 - 0x0602
.REPT $40           ; 11 (8 + 3) bytes per iteration
    EXX
    OUT (C), L      ; WRITE VDP ADDRESS
    OUT (C), H
    ADD HL, DE      ; INCREMENT ADDRESS FOR NEXT ROW
    EXX
    OUTI            ; WRITE WORD FOR CURRENT ROW
    OUTI
.ENDR
WriteVeriBlock_W:
    RET
    */
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
;.SECTION "jUNK!!!!" BANK BANK_SLOT2 SLOT 2 FORCE ORG $0700

/*
PALETTE DATA LAYOUT:
    VDP ADDRESS, BYTE COUNT, DATA, TERMINATOR
*/
.SECTION "Water AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
WaterPaletteData:
    .dw swapBytes($C000)
    .db $10
    .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00
.ENDS

.SECTION "Ground AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
GroundPaletteData:
    .dw swapBytes($C000)
    .db $20
    .db $39, $00, $01, $06, $0B, $04, $08, $0C, $05, $0A, $2E, $0F, $2A, $3F, $18, $2D
    .db $39, $00, $01, $06, $0B, $24, $0C, $06, $1B, $0F, $2A, $3F, $03, $02, $10, $08
    .db $00
.ENDS

.SECTION "Underground AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
UndergroundPaletteData:
    .dw swapBytes($C000)
    .db $20
    .db $00, $00, $10, $24, $38, $04, $08, $0C, $05, $0A, $2E, $0F, $2A, $3F, $18, $3C;$3D
    .db $00, $00, $10, $24, $38, $24, $0C, $06, $1B, $0F, $2A, $3F, $03, $02, $10, $08
    .db $00
.ENDS

.SECTION "Castle AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
CastlePaletteData:
    .dw swapBytes($C000)
    .db $10
    .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00
.ENDS

.SECTION "Day Snow AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
DaySnowPaletteData:
    .dw swapBytes($C000)
    .db $10
    .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00
.ENDS

.SECTION "Night Snow AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
NightSnowPaletteData:
    .dw swapBytes($C000)
    .db $10
    .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00
.ENDS

.SECTION "Mushroom AreaType Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
MushroomPaletteData:
    .dw swapBytes($C000)
    .db $10
    .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00
.ENDS

.SECTION "Bowser Palette Data" BANK BANK_SLOT2 SLOT 2 FREE
BowserPaletteData:
    .dw swapBytes($C000)
    .db $10
    .db $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00
.ENDS

.SECTION "'Thank You Mario' MSG Data" BANK BANK_SLOT2 SLOT 2 FREE
MarioThanksMessage:
;"THANK YOU MARIO!"
    .db $25, $48, $10
    .db $1d, $11, $0a, $17, $14, $24
    .db $22, $18, $1e, $24
    .db $16, $0a, $1b, $12, $18, $2b
    .db $00
.ENDS

.SECTION "'Thank You Luigi' MSG Data" BANK BANK_SLOT2 SLOT 2 FREE
LuigiThanksMessage:
;"THANK YOU LUIGI!"
    .db $25, $48, $10
    .db $1d, $11, $0a, $17, $14, $24
    .db $22, $18, $1e, $24
    .db $15, $1e, $12, $10, $12, $2b
    .db $00
.ENDS

.SECTION "Mushroom Retainer MSG Data" BANK BANK_SLOT2 SLOT 2 FREE
MushroomRetainerSaved:
;"BUT OUR PRINCESS IS IN"
    .db $25, $c5, $16
    .db $0b, $1e, $1d, $24, $18, $1e, $1b, $24
    .db $19, $1b, $12, $17, $0c, $0e, $1c, $1c, $24
    .db $12, $1c, $24, $12, $17
;"ANOTHER CASTLE!"
    .db $26, $05, $0f
    .db $0a, $17, $18, $1d, $11, $0e, $1b, $24
    .db $0c, $0a, $1c, $1d, $15, $0e, $2b, $00
.ENDS

.SECTION "Princess Saved MSG 1 Data" BANK BANK_SLOT2 SLOT 2 FREE
PrincessSaved1:
;"YOUR QUEST IS OVER."
    .db $25, $a7, $13
    .db $22, $18, $1e, $1b, $24
    .db $1a, $1e, $0e, $1c, $1d, $24
    .db $12, $1c, $24, $18, $1f, $0e, $1b, $af
    .db $00
.ENDS

.SECTION "Princess Saved MSG 2 Data" BANK BANK_SLOT2 SLOT 2 FREE
PrincessSaved2:
;"WE PRESENT YOU A NEW QUEST."
    .db $25, $e3, $1b
    .db $20, $0e, $24
    .db $19, $1b, $0e, $1c, $0e, $17, $1d, $24
    .db $22, $18, $1e, $24, $0a, $24, $17, $0e, $20, $24
    .db $1a, $1e, $0e, $1c, $1d, $af
    .db $00
.ENDS

.SECTION "World Select MSG 1 Data" BANK BANK_SLOT2 SLOT 2 FREE
WorldSelectMessage1:
;"PUSH BUTTON B"
    .db $26, $4a, $0d
    .db $19, $1e, $1c, $11, $24
    .db $0b, $1e, $1d, $1d, $18, $17, $24, $0b
    .db $00
.ENDS

.SECTION "World Select MSG 2 Data" BANK BANK_SLOT2 SLOT 2 FREE
WorldSelectMessage2:
;"TO SELECT A WORLD"
    .db $26, $88, $11
    .db $1d, $18, $24, $1c, $0e, $15, $0e, $0c, $1d, $24
    .db $0a, $24, $20, $18, $1b, $15, $0d
    .db $00
.ENDS

.SECTION "Title Screen TileMap Data" BANK BANK_SLOT2 SLOT 2 FREE
TitleScreenData:
;   ROW 0
    .dw swapBytes(xyToNameTbl_M(5, 1))
    .db $16 | STRIPE_HWRITE_W
    .dw $08B9, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BA, $08BB
;   ROW 1
    .dw swapBytes(xyToNameTbl_M(5, 2))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08BD, $08BE, $08BF, $08BF, $08C0, $0ABD, $08BD, $08C1, $08C0, $0ABD, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C3
;   ROW 2
    .dw swapBytes(xyToNameTbl_M(5, 3))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08C4, $08C5, $08C6, $08C6, $08C6, $08C7, $08C8, $08C9, $08C6, $08CA, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C3
;   ROW 3
    .dw swapBytes(xyToNameTbl_M(5, 4))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08CB, $08CC, $08CD, $08CE, $08CF, $08D0, $08CD, $08D1, $08CF, $08D2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C3
;   ROW 4
    .dw swapBytes(xyToNameTbl_M(5, 5))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08D3, $08D4, $08D3, $08D4, $08D5, $08C2, $08D3, $08D6, $08D5, $08D6, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08C2, $08D7, $08D8, $08C3
;   ROW 5
    .dw swapBytes(xyToNameTbl_M(5, 6))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08BD, $08D9, $0ABD, $08BD, $0ABD, $08C0, $0ABD, $08BF, $08BD, $0ABD, $08C2, $08C0, $0ABD, $08C0, $0ABD, $08BD, $0ABD, $08BD, $0ABD, $08C2, $08C3
;   ROW 6
    .dw swapBytes(xyToNameTbl_M(5, 7))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08DA, $08DB, $08DB, $08DA, $08DB, $08DA, $08DC, $08DA, $08DA, $08DC, $08C2, $08DA, $08DC, $08DA, $08DC, $08DA, $08DC, $08DA, $08DD, $08C2, $08C3
;   ROW 7
    .dw swapBytes(xyToNameTbl_M(5, 8))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08DA, $08DA, $08DA, $08DA, $08DA, $08DA, $08DE, $08DA, $08DA, $08DA, $08C2, $08DA, $08DE, $08DA, $08DE, $08DA, $08DA, $08DF, $08E0, $08C2, $08C3
;   ROW 8
    .dw swapBytes(xyToNameTbl_M(5, 9))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08C6, $08C6, $08C6, $08E1, $08E2, $08C6, $08E3, $08C6, $08C6, $08C6, $08C2, $08C6, $08E3, $08C6, $08E3, $08C6, $08C6, $08E4, $08E5, $08C2, $08C3
;   ROW 9
    .dw swapBytes(xyToNameTbl_M(5, 10))
    .db $16 | STRIPE_HWRITE_W
    .dw $08BC, $08CF, $08CF, $08CF, $08CF, $08E6, $08CF, $08CF, $08CF, $08CD, $08CE, $08C2, $08CF, $08E7, $08CF, $08CF, $08CD, $08CE, $08CD, $08CE, $08E8, $08C3
;   ROW A
    .dw swapBytes(xyToNameTbl_M(5, 11))
    .db $16 | STRIPE_HWRITE_W
    .dw $08E9, $08EA, $08EA, $08EA, $08EA, $08EA, $08EA, $08EA, $08EA, $08EB, $08EC, $08ED, $08EA, $08EE, $08EA, $08EA, $08EB, $08EC, $08EB, $08EC, $08EA, $08EF
;   "C1985 NINTENDO"
    .dw swapBytes(xyToNameTbl_M(13, 12))
    .db $0E | STRIPE_HWRITE_W
    .dw $08F0, BG_MACRO($0101), BG_MACRO($0109), BG_MACRO($0108), BG_MACRO($0105), BLANKTILE, $08F1, $08F2, $08F1, $08F3, $08F4, $08F1, $08F5, $08F6 
;   "1 PLAYER GAME"
    .dw swapBytes(xyToNameTbl_M(11, 15))
    .db $0D | STRIPE_HWRITE_W
    .dw BG_MACRO($0101), BLANKTILE, $08F7, $08F8, $08F9, $08FA, $08F4, $08FB, BLANKTILE, $08FC, $08F9, $08FD, $08F4
    
    .IF SMSPOWERCOMP == $00
;   "2 PLAYER GAME"
    .dw swapBytes(xyToNameTbl_M(11, 17))
    .db $0D | STRIPE_HWRITE_W
    .dw BG_MACRO($0102), BLANKTILE, $08F7, $08F8, $08F9, $08FA, $08F4, $08FB, BLANKTILE, $08FC, $08F9, $08FD, $08F4
    .ENDIF

;   "V0.12"
    .dw swapBytes(xyToNameTbl_M(22, 13))
    .db $05 | STRIPE_HWRITE_W
    .dw $00B7, BG_MACRO($0100), $00B8, BG_MACRO($0101), BG_MACRO($0102)
;   "TOP-      0"
    .dw swapBytes(xyToNameTbl_M(12, 20))
    .db $04 | STRIPE_HWRITE_W
    .dw $08F3, $08F6, $08F7, BG_MACRO($010B)
    .dw swapBytes(xyToNameTbl_M(22, 20))
    .db $01 | STRIPE_HWRITE_W
    .dw BG_MACRO($0100)
;   COLOR
    .dw swapBytes($C013)
    .db $01
    .db $07
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
    .db $01 << $01
    .dw BG_MACRO($090F)
    ; 'W'
    .dw swapBytes(xyToNameTbl_M(19, 0))
    .db $01 << $01
    .dw BG_MACRO($010A)
    ; CLOCK ICON
    .dw swapBytes(xyToNameTbl_M(26, 0))
    .db $01 << $01
    .dw BG_MACRO($010E)
    ; '0  [COIN]x' 
    .dw swapBytes(xyToNameTbl_M(9, 0))
    .db $05 << $01
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
    .db $07 << $01
    .dw BLANKTILE, BLANKTILE, BG_MACRO($010C), BLANKTILE, BLANKTILE, BG_MACRO($0100), BLANKTILE
    ; 'WORLD [WORLD]-[LEVEL]'
    .dw swapBytes(xyToNameTbl_M(11, 07))
    .db $09 << $01
    .dw BG_MACRO($010A), BG_MACRO($0114), BG_MACRO($0112), BG_MACRO($0115), BG_MACRO($011C), BLANKTILE, BG_MACRO($0100), BG_MACRO($010B), BG_MACRO($0100)
    ; Clear "Time Up" Area
    .dw swapBytes(xyToNameTbl_M(12, 13))
    .db $07 << $01
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE
@end:
.ENDS

/*
.SECTION "Two Player Timeup for Mario Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
TwoPlayerTimeUp:
    ;.db $21, $cd, $05, $16, $0a, $1b, $12, $18 ; "MARIO"
    .db @end-TwoPlayerTimeUp - 1
    .dw swapBytes(xyToNameTbl_M(13, 11))
    .db $05 << $01
    .dw BG_MACRO($0110), BG_MACRO($0111), BG_MACRO($0112), BG_MACRO($0113), BG_MACRO($0114)
@end:
.ENDS

.SECTION "Timeup Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
OnePlayerTimeUp:
    ;.db $22, $0c, $07, $1d, $12, $16, $0e, $24, $1e, $19 ; "TIME UP"
    ;.db $ff
    .db @end-OnePlayerTimeUp - 1
    .dw swapBytes(xyToNameTbl_M(12, 13))
    .db $07 << $01
    .dw BG_MACRO($011A), BG_MACRO($0113), BG_MACRO($0110), BG_MACRO($0118), BLANKTILE, BG_MACRO($0116), BG_MACRO($011B)
@end:
.ENDS

.SECTION "Two Player GameOver for Mario Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
TwoPlayerGameOver:
    ;.db $21, $cd, $05, $16, $0a, $1b, $12, $18 ; "MARIO"
.ENDS

.SECTION "GameOver Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
OnePlayerGameOver:
    ;.db $22, $0b, $09, $10, $0a, $16, $0e, $24 ; "GAME OVER"
    ;.db $18, $1f, $0e, $1b
    ;.db $ff
    .dw swapBytes(xyToNameTbl_M(11, 13))
    .db $09 << $01
    .dw BG_MACRO($0117), BG_MACRO($0111), BG_MACRO($0110), BG_MACRO($0118), BLANKTILE, BG_MACRO($0114), BG_MACRO($0119), BG_MACRO($0118), BG_MACRO($0112)
.ENDS
*/

.SECTION "GameOver Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
GameOverDisplay:
    ;.db $22, $0b, $09, $10, $0a, $16, $0e, $24 ; "GAME OVER"
    ;.db $18, $1f, $0e, $1b
    ;.db $ff
    .db @end-GameOverDisplay - 1
    .dw swapBytes(xyToNameTbl_M(11, 13))
    .db $09 << $01
    .dw BG_MACRO($0117), BG_MACRO($0111), BG_MACRO($0110), BG_MACRO($0118), BLANKTILE, BG_MACRO($0114), BG_MACRO($0119), BG_MACRO($0118), BG_MACRO($0112)
@end:
.ENDS

.SECTION "Timeup Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
TimeUpDisplay:
    ;.db $22, $0c, $07, $1d, $12, $16, $0e, $24, $1e, $19 ; "TIME UP"
    ;.db $ff
    .db @end-TimeUpDisplay - 1
    .dw swapBytes(xyToNameTbl_M(12, 13))
    .db $07 << $01
    .dw BG_MACRO($011A), BG_MACRO($0113), BG_MACRO($0110), BG_MACRO($0118), BLANKTILE, BG_MACRO($0116), BG_MACRO($011B)
@end:
.ENDS

.SECTION "WarpZone Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
WarpZoneWelcome:
    .db $25, $84, $15, $20, $0e, $15, $0c, $18, $16 ; "WELCOME TO WARP ZONE!"
    .db $0e, $24, $1d, $18, $24, $20, $0a, $1b, $19
    .db $24, $23, $18, $17, $0e, $2b
    .db $26, $25, $01, $24         ; placeholder for left pipe
    .db $26, $2d, $01, $24         ; placeholder for middle pipe
    .db $26, $35, $01, $24         ; placeholder for right pipe
    .db $27, $d9, $46, $aa         ; attribute data
    .db $27, $e1, $45, $aa
    .db $ff
.ENDS


.SECTION "Mario Name Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
MarioName:
    ;.db $21, $cd, $05, $16, $0a, $1b, $12, $18 ; "MARIO"
    .db @end-MarioName - 1
    .dw swapBytes(xyToNameTbl_M(13, 11))
    .db $05 << $01
    .dw BG_MACRO($0110), BG_MACRO($0111), BG_MACRO($0112), BG_MACRO($0113), BG_MACRO($0114)
@end:
.ENDS

.SECTION "Luigi Name Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
LuigiName:
    ;.db $15, $1e, $12, $10, $12    ; "LUIGI", no address or length
    .db @end-LuigiName - 1
    .dw swapBytes(xyToNameTbl_M(13, 11))
    .db $05 << $01
    .dw BG_MACRO($0115), BG_MACRO($0116), BG_MACRO($0113), BG_MACRO($0117), BG_MACRO($0113)
@end:
.ENDS

.SECTION "WarpZone Numbers Stripe Data" BANK BANK_SLOT2 SLOT 2 FREE
WarpZoneNumbers:
    .db $04, $03, $02, $00         ; warp zone numbers, note spaces on middle
    .db $24, $05, $24, $00         ; zone, partly responsible for
    .db $08, $07, $06, $00         ; the minus world
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
    .dw $00, $00, $00, $00
    ;.dw
    ;.dw
    ; Chain
    .dw $00, $00, $00, $00
    ; Trees
    .dw BG_MACRO($0183), BG_MACRO($0189), BG_MACRO($0185), BG_MACRO($018A)  ; tall top, top half
    .dw BG_MACRO($0183), BG_MACRO($0184), BG_MACRO($0185), BG_MACRO($0186)  ; short top
    .dw BG_MACRO($0189), BG_MACRO($0184), BG_MACRO($018A), BG_MACRO($0186)  ; tall top, bottom half
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
    .dw $00, $00, $00, $00
    ; Blank for bricks/blocks that are hit
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE
    ; Flagpole
    .dw BLANKTILE, BG_MACRO($017C), BLANKTILE, BG_MACRO($017D)              ; ball
    .dw BG_MACRO($0154), BG_MACRO($0154), BG_MACRO($0155), BG_MACRO($0155)  ; shaft
    ; Blank for vines
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE

    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00
    .dw $00, $00, $00, $00


Palette1_MTiles:
    ; Rope
    .dw BG_MACRO($0154), BG_MACRO($0154), BG_MACRO($0155), BG_MACRO($0155)  ; vertical
    .dw BG_MACRO($0959), BLANKTILE, BG_MACRO($0959), BLANKTILE              ; horizontal
    ; Pulley
    .dw BLANKTILE, BG_MACRO($0956), BG_MACRO($0957), BG_MACRO($0958)        ; left
    .dw BG_MACRO($0B57), BG_MACRO($095A), BLANKTILE, BG_MACRO($095B)        ; right
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; blank used for balance rope
    ; Castle
    .dw BG_MACRO($118B), BG_MACRO($11A4), BG_MACRO($118C), BG_MACRO($11A4)  ; top
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($0191), BG_MACRO($0191)  ; window left
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; brick wall
    .dw BG_MACRO($0192), BG_MACRO($0192), BG_MACRO($0193), BG_MACRO($0193)  ; window right
    .dw BG_MACRO($118D), BG_MACRO($11A4), BG_MACRO($118E), BG_MACRO($11A4)  ; top with brick
    .dw BG_MACRO($018F), BG_MACRO($0192), BG_MACRO($0190), BG_MACRO($0192)  ; entry top
    .dw BG_MACRO($0192), BG_MACRO($0192), BG_MACRO($0192), BG_MACRO($0192)  ; entry bottom
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
    .dw BG_MACRO($0149), BG_MACRO($014A), BG_MACRO($0249), BG_MACRO($024A)  ; top
    .dw BG_MACRO($014A), BG_MACRO($014A), BG_MACRO($024A), BG_MACRO($024A)  ; bottom
    ; --- METATILES WITH COLLISION START HERE ---
    ; Breakable bricks
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; shiny
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; normal
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; unused
    ; Rock Terrain
    .dw BG_MACRO($019C), BG_MACRO($019D), BG_MACRO($019E), BG_MACRO($019F)
    .dw BG_MACRO($119C), BG_MACRO($119D), BG_MACRO($119E), BG_MACRO($119F)  ; rock PRIORITY (NEW)
    ; Bricks with something in them
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; shiny with Power-UP
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; shiny with Vine
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; shiny with Star
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; shiny with Coins
    .dw BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4), BG_MACRO($01A4)  ; shiny with 1-UP
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
    .dw $00, $00, $00, $00                                                  ; white wall (castle levels)
    ; Bridge
    .dw BG_MACRO($017E), BLANKTILE, BG_MACRO($017E), BLANKTILE
    ; Bullet Bill
    .dw BG_MACRO($014B), BG_MACRO($014C), BG_MACRO($024B), BG_MACRO($014D)  ; barrel
    .dw BG_MACRO($014E), BG_MACRO($014F), BG_MACRO($0150), BG_MACRO($0151)  ; top
    .dw BG_MACRO($0152), BG_MACRO($0152), BG_MACRO($0153), BG_MACRO($0153)  ; bottom
    ; Jumpspring
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BLANKTILE                          ; blank for jumpspring
    .dw BLANKTILE, BG_MACRO($01A4), BLANKTILE, BG_MACRO($01A4)              ; half brick 
    ; Solid brick for water levels
    .dw $00, $00, $00, $00
    ; Half brick (unused?)
    .dw BLANKTILE, BG_MACRO($01A4), BLANKTILE, BG_MACRO($01A4)
    ; Water pipe
    .dw $00, $00, $00, $00
    ; Flagball (unused)
    .dw BLANKTILE, BG_MACRO($017C), BLANKTILE, BG_MACRO($017D)

    
Palette2_MTiles:
    ; Cloud
    .dw BLANKTILE, BLANKTILE, BLANKTILE, BG_MACRO($0919)                    ; right
    .dw BG_MACRO($091A), BG_MACRO($091B), BG_MACRO($091C), BG_MACRO($091B)  ; middle
    .dw BLANKTILE, BG_MACRO($091D), BLANKTILE, BLANKTILE                    ; left
    .dw BLANKTILE, BLANKTILE, BG_MACRO($091E), BLANKTILE                    ; right bottom
    .dw BG_MACRO($091F), BLANKTILE, BG_MACRO($0920), BLANKTILE              ; middle bottom
    .dw BG_MACRO($0921), BLANKTILE, BLANKTILE, BLANKTILE                    ; left bottom
    ; Water/Lava
    .dw BG_MACRO($09BA), BG_MACRO($0912), BG_MACRO($09BB), BG_MACRO($0912)  ; waves
    .dw BG_MACRO($0912), BG_MACRO($0912), BG_MACRO($0912), BG_MACRO($0912)  ; body
    ; --- METATILES WITH COLLISION START HERE ---
    ; Cloud Terrain
    .dw BG_MACRO($0929), BG_MACRO($092A), BG_MACRO($0B29), BG_MACRO($0B2A)
    ; Bowser's bridge
    .dw $00, $00, $00, $00
    

Palette3_MTiles:
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
    .dw $00, $00, $00, $00

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
.SECTION "BG Common Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_BG_Comm:
    .INCLUDE "BG_Comm.inc"

Tiles_BG_Overworld:
    .INCLUDE "BG_Overworld.inc"

Tiles_BG_TitleScreen:
    .INCLUDE "BG_TitleScreenVer.inc"
    .INCLUDE "BG_TitleScreen.inc"

Tiles_BG_TitleScreenText:
    .INCLUDE "BG_TitleScreenText.inc"

Tiles_BG_Inter:
    .INCLUDE "BG_Inter.inc"

.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Underground BG Tiles" BANK BANK_SLOT2 SLOT 2 FREE

Tiles_BG_Underground:
    .INCLUDE "BG_Underground.inc"

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
.SECTION "Uncompressed Player Tiles - Luigi [Left]" BANK BANK_PLAYERGFX02 SLOT 2 FREE
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Uncompressed Player Tiles - Luigi [Right]" BANK BANK_PLAYERGFX03 SLOT 2 FREE
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Common Sprite Tiles" BANK BANK_AREAENEMY SLOT 2 FREE

Tiles_SPR_Comm:
    .INCLUDE "SPR_Comm.inc"
    .INCLUDE "SPR_Comm_01.inc"
.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Enemy Sprite Tiles" BANK 6 SLOT 2 FREE

Tiles_SPR_Enemies:
    .INCLUDE "SPR_Enemies.inc"

.ENDS

;-------------------------------------------------------------------------------------
.SECTION "Animated Background Tiles" BANK BANK_SLOT2 SLOT 2 FREE

    .INCLUDE "ANI_Coin.inc"
    .INCLUDE "ANI_Grass.inc"

.ENDS

;-------------------------------------------------------------------------------------
.INCLUDE "SND_Data.inc"