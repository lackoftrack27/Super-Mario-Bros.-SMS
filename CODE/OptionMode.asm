;-------------------------------------------------------------------------------------

.DEFINE MUSHROOM_TILE       VRAM_IDX_BG + $0062
.DEFINE DIGIT_TILE_START    VRAM_IDX_BG + $0063

OptionMode:
    ; LOAD BACKGROUND DATA
    LD A, :Tiles_BG_Options
    LD (MAPPER_SLOT2), A
    LD HL, Tiles_BG_Options
    LD DE, VRAM_ADR_BG | VRAMWRITE
    CALL zx7_decompressVRAM
    LD HL, Map_BG_Options
    LD DE, VRAM_ADR_NAMETBL + OPTION_OFFSET | VRAMWRITE
    CALL zx7_decompressVRAM
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD HL, Pal_BG_Options
    LD BC, _sizeof_Pal_BG_Options * $100 + VDPDATA_PORT
    OTIR
    ; DISPLAY SOUND SELECTION IF FM CHIP IS DETECTED
    LD A, (FMDetectedFlag)
    OR A
    JR Z, InitializeMenu
    LD HL, VRAM_ADR_NAMETBL + $0048 + OPTION_OFFSET | VRAMWRITE
    RST setVDPAddress
    LD HL, Map_BG_SoundSelect@Line1
    LD B, $06
    OTIR
    LD HL, VRAM_ADR_NAMETBL + $00C8 + OPTION_OFFSET | VRAMWRITE
    RST setVDPAddress
    LD HL, Map_BG_SoundSelect@Line2
    LD B, $06
    OTIR
InitializeMenu:
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    ; INITIALIZE MENU MEMORY
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
    LD A, $20
    LD (Player_Rel_XPos), A
    ADD A, SMS_PIXELYOFFSET + (OPTION_OFFSET / 8)
    LD (Player_Rel_YPos), A
    CALL PlayerGfxHandler
    ;
    CALL waitForVblank
    IN A, (VDPCON_PORT)             ;clear any pending VDP interrupts
    EI

    ; Temp_Bytes + $00 - Previous Input
    ; Temp_Bytes + $01 - Leaving Options Flag
    ; Temp_Bytes + $02 - Sound Test Flag
    ; Temp_Bytes + $03 - Sound ID
OptionsLoop:
    LD A, (Temp_Bytes + $01)        ;check if leaving options menu
    OR A
    JR Z, OptionsCheckJoypad        ;if not, skip
    LD A, (SFXTrack0.Control)       ;check if sfx has finished playing
    OR A
    JP P, MainGameInit              ;if so, go to main game
    ; FALL THROUGH

OptionsCheckJoypad:
    LD HL, SavedJoypad1Bits         ;debounce inputs
    LD B, (HL)
    LD A, (Temp_Bytes + $00)
    XOR A, (HL)
    AND A, (HL)
    LD (HL), A
    LD A, B
    LD (Temp_Bytes + $00), A
    ; ONLY DO SOUND DEBUG IF FLAG IS SET
    LD A, (Temp_Bytes + $02)
    OR A
    JR NZ, OptionCheckPause_Debug
    ; --- BUTTON UP/DOWN PROCESS ---
    LD A, (HL)
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
    JP OptionUpdateSettings

    ; --- BUTTON 1 PROCESS ---
OptionCheckBtn1:
    LD A, (SavedJoypad1Bits)        ;check if button 1 is being pressed
    AND A, bitValue(SMS_BTN_1)
    JR Z, OptionCheckBtn2           ;if not, skip
    LD A, $01                       ;set flag to signal that we are leaving the options menu
    LD (Temp_Bytes + $01), A
    LD A, SNDID_BEEP                ;do beep sfx
    LD (SFXTrack0.SoundQueue), A
    JP OptionUpdateSettings

    ; --- BUTTON 2 PROCESS ---
OptionCheckBtn2:
    LD A, (FMDetectedFlag)          ;skip if FM addon isn't detected
    OR A
    JR Z, OptionCheckPause_Debug
    LD A, (SavedJoypad1Bits)        ;skip if button 2 isn't being pressed
    AND A, bitValue(SMS_BTN_2)
    JR Z, OptionCheckPause_Debug
    LD A, (OptionBitflags)          ;toggle FM flag
    XOR A, bitValue(OPTFLAG_FM)
    LD (OptionBitflags), A
    LD A, SNDID_BEEP                ;do beep sfx
    LD (SFXTrack0.SoundQueue), A
    JP OptionUpdateSettings

    ; --- PAUSE BUTTON PROCESS ---
OptionCheckPause_Debug:
    ; PAUSE BUTTON LOGIC
    LD A, (SavedJoypad1Bits)
    AND A, bitValue(SMS_BTN_START)
    JR Z, @CheckSndFlag
        ; TOGGLE SOUND TEST FLAG
    LD A, (Temp_Bytes + $02)
    XOR A, $01
    LD (Temp_Bytes + $02), A
    JR NZ, @EnterSoundTest
    ; EXIT SOUND TEST
        ; STOP ALL SOUND
    CALL SndStopAll         ; PSG, CLEARS FLAGS
    CALL SilenceAllSound    ; FM, CLEARS FLAGS (ALSO REDUNDANTLY STOPS PSG)
        ; RESET MUSHROOM SELECTOR
    LD HL, VRAM_ADR_NAMETBL + $0584 + OPTION_OFFSET | VRAMWRITE
    RST setVDPAddress
    LD B, $08
    XOR A
    CALL MemsetVRAM8
    JP OptionUpdateSettings

@EnterSoundTest:
    ; START SOUND TEST
        ; RESET SOUND ID
    XOR A
    LD (Temp_Bytes + $03), A
        ; SET SELECTOR FOR SOUND TEST
    LD HL, VRAM_ADR_NAMETBL + $0584 + OPTION_OFFSET | VRAMWRITE
    RST setVDPAddress
    LD A, <MUSHROOM_TILE
    OUT (VDPDATA_PORT), A
    LD A, >MUSHROOM_TILE
    OUT (VDPDATA_PORT), A
        ; DRAW SOUND ID
    LD HL, Temp_Bytes + $03
    JR @DrawSndID

@CheckSndFlag:
    LD A, (Temp_Bytes + $02)
    OR A
    JP Z, OptionUpdateSettings
@PauseControllerChk:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    LD B, $0E + $13   ; PSG LIMIT
    JR Z, +
    LD B, $16 + $13   ; FM LIMIT
+:
    LD HL, Temp_Bytes + $03
    LD A, (SavedJoypad1Bits)
    ; BUTTON 1 CHECK    [Play Music]
    BIT SMS_BTN_1, A
    JR NZ, @PlaySndID 
    ; BUTTON 2 CHECK    [Stop Music]
    BIT SMS_BTN_2, A
    JR Z, +
    LD A, SNDID_SILENCE
    JR @OverrideID
+:
    ; RIGHT CHECK       [Increment ID]
    BIT SMS_BTN_RIGHT, A
    JR Z, +
    INC (HL)
    JR @DrawSndID
+:
    ; LEFT CHECK        [Decrement ID]
    BIT SMS_BTN_LEFT, A
    JR Z, +
    DEC (HL)
    JR @DrawSndID
+:
    ; UP CHECK          [Set Hurry Up]
    BIT SMS_BTN_UP, A
    JP Z, OptionDrawPlayer
    LD A, SNDID_HURRYUP
    JR @OverrideID

@DrawSndID:
    ; GATE SND ID
    LD A, (HL)
    CP A, B
    JR C, +
    LD (HL), $00
+:
    OR A
    JP P, +
    DEC B
    LD (HL), B
+:
    ; DRAW SND ID
    EX DE, HL
    LD HL, VRAM_ADR_NAMETBL + $0588 + OPTION_OFFSET | VRAMWRITE
    RST setVDPAddress
        ; LEFT DIGIT
    LD A, (DE)
    AND A, $F0
    RRCA
    RRCA
    RRCA
    RRCA
    ADD A, <DIGIT_TILE_START
    OUT (VDPDATA_PORT), A
    LD A, (IX + 0)                  ;vdp delay
    LD A, $01
    OUT (VDPDATA_PORT), A
        ; RIGHT DIGIT
    LD A, (DE)
    AND A, $0F
    ADD A, <DIGIT_TILE_START
    OUT (VDPDATA_PORT), A
    LD A, (IX + 0)                  ;vdp delay
    LD A, $01
    OUT (VDPDATA_PORT), A
    JP OptionDrawPlayer

@PlaySndID:
    ; PLAY SND ID
    LD A, (HL)
    ADD A, $81                      ;SND START
    CP A, SNDID_FMDUPS+$03          ;layered SFX (Noise)
    JR NC, @LayeredNoiseID
    CP A, SNDID_FMDUPS              ;layered SFX (Tone)
    JR NC, @LayeredToneID
    CP A, SNDID_WATER               ;PSG/FM music
    JR NC, @OverrideID
    CP A, SNDID_SHATTER             ;Noise SFX (Brick shatter)
    JR Z, @NoiseID
    CP A, SNDID_FLAME               ;Tone SFX
    JR NZ, @ToneID
    JR @NoiseID                     ;Noise SFX (Flame)

@LayeredNoiseID:
    ADD A, $0E
@NoiseID:
    LD (SFXTrack2.SoundQueue), A
    JP OptionDrawPlayer
@LayeredToneID:
    ADD A, $0E
@ToneID:
    LD (SFXTrack0.SoundQueue), A
    JP OptionDrawPlayer
@OverrideID:
    LD (MusicTrack0.SoundQueue), A
    JP OptionDrawPlayer
; ---

OptionUpdateSettings:
    LD A, (OptionBitflags)          ;set values depending on bit 0 of option bit flags
    AND A, bitValue(OPTFLAG_GFX)
    JR NZ, +
    LD A, BANK_PLAYERGFX00
    LD (PlayerGfxBank), A
    LD A, VRAMTBL_OPTIONPAL
    LD (VRAM_Buffer_AddrCtrl), A
    LD A, $20 + SMS_PIXELYOFFSET + (OPTION_OFFSET / 8)
    LD (Player_Rel_YPos), A
    LD HL, AnimateBGTiles
    LD (AnimateRoutine), HL
    LD HL, BowserGfxDraw
    LD (BowserDrawRoutine), HL
    JR @UpdateFMSettings
+:
    LD A, BANK_PLAYERGFX04
    LD (PlayerGfxBank), A
    LD A, VRAMTBL_OPTIONPAL_NES
    LD (VRAM_Buffer_AddrCtrl), A
    LD A, $20 + $68 + SMS_PIXELYOFFSET + (OPTION_OFFSET / 8)
    LD (Player_Rel_YPos), A
    LD HL, ColorRotation
    LD (AnimateRoutine), HL
    LD HL, BowserGfxDraw_NES
    LD (BowserDrawRoutine), HL
    ; FALL THROUGH

; ---
@UpdateFMSettings:
    LD A, (FMDetectedFlag)          ;skip FM sound setting update if FM module not detected
    OR A
    JR Z, OptionDrawPlayer
    CALL SndInitMemory@InitChanBits ;set channel bits (only done for sound test)
    LD A, (OptionBitflags)          ;set values depending on bit 1 of option bit flags
    AND A, bitValue(OPTFLAG_FM)
    JR NZ, +
    LD HL, SndChannelProcessMUS     ;FM music update routine
    LD (MusicRoutine), HL
    LD DE, <MUSHROOM_TILE
    JR @DrawSelector
+:
    LD HL, SndChannelProcessFM      ;PSG music update routine
    LD (MusicRoutine), HL
    LD DE, <MUSHROOM_TILE * $100
@DrawSelector:
    LD HL, VRAM_ADR_NAMETBL + $0044 + OPTION_OFFSET | VRAMWRITE
    RST setVDPAddress
    LD BC, $0100 + VDPDATA_PORT
    OUT (C), E
    LD A, (IX + 0)                  ;vdp delay
    OUT (C), B
    LD HL, VRAM_ADR_NAMETBL + $00C4 + OPTION_OFFSET | VRAMWRITE
    RST setVDPAddress
    OUT (C), D
    LD A, (IX + 0)                  ;vdp delay
    OUT (C), B
; ---
    ; FALL THROUGH

OptionDrawPlayer:
    LD HL, PlayerAnimTimer          ;update timer for walking animation
    DEC (HL)
    CALL PlayerGfxHandler           ;draw player
    LD A, $01                       ;signal that we have completed a frame on time
    LD (FrameDoneFlag), A

OptionNMIWait:
    LD A, (FrameDoneFlag)           ;busy loop until NMI has triggered
    OR A
    JR NZ, OptionNMIWait
    JP OptionsLoop