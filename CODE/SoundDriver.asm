;   CHANNEL CONTROL BITS
.DEFINE CHANCON_REST        1
.DEFINE CHANCON_SFX         2
.DEFINE CHANCON_MOD         3
.DEFINE CHANCON_NOATK       4
.DEFINE CHANCON_DRUMMODE    5
.DEFINE CHANCON_FMSUSTAIN   6
.DEFINE CHANCON_PLAYING     7

;   REGISTER BITS
.DEFINE OP_BIT      $04     ; 0 - FREQUENCY, 1 - VOLUME
.DEFINE CHAN_BIT0   $05
.DEFINE CHAN_BIT1   $06
.DEFINE LATCH_BIT   $07

;   PSG CHANNEL BITS
.DEFINE CHAN0_BITS  $00
.DEFINE CHAN1_BITS  bitValue(CHAN_BIT0)
.DEFINE CHAN2_BITS  bitValue(CHAN_BIT1)
.DEFINE CHAN3_BITS  bitValue(CHAN_BIT0) | bitValue(CHAN_BIT1)
.DEFINE CHANALL_BITS    CHAN3_BITS
.DEFINE LATCH_VOL   bitValue(OP_BIT) | bitValue(LATCH_BIT)

;   PSG NOISE TYPES
.DEFINE NOISE_TONE0 $00
.DEFINE NOISE_TONE1 $01
.DEFINE NOISE_TONE2 $02
.DEFINE NOISE_PULSE $03

;   COUNTS
.DEFINE TRACK_COUNT $07 ; 4 MUSIC, 3 SFX
.DEFINE CHAN_COUNT  $04
.DEFINE FM_COUNT    $09

;   STARTING COORDINATION FLAG ID
.DEFINE CF_START    $E0

;   FM REGISTERS
.DEFINE FMREG_CUSTOM0   $00
.DEFINE FMREG_CUSTOM1   $01
.DEFINE FMREG_CUSTOM2   $02
.DEFINE FMREG_CUSTOM3   $03
.DEFINE FMREG_CUSTOM4   $04
.DEFINE FMREG_CUSTOM5   $05
.DEFINE FMREG_CUSTOM6   $06
.DEFINE FMREG_CUSTOM7   $07

.DEFINE FMREG_FNUMLSB   $10
.DEFINE FMREG_FNUMKEY   $20
.DEFINE FMREG_INSTVOL   $30

;   FM CHANNEL BITS
.DEFINE FM_CHAN0_BITS   $00
.DEFINE FM_CHAN1_BITS   $01
.DEFINE FM_CHAN2_BITS   $02
.DEFINE FM_CHAN3_BITS   $03
.DEFINE FM_CHAN4_BITS   $04
.DEFINE FM_CHAN5_BITS   $05
.DEFINE FM_CHAN6_BITS   $06
.DEFINE FM_CHAN7_BITS   $07
.DEFINE FM_CHAN8_BITS   $08

;-------------------------------------------------------------------------------------

SoundEngine:
;   SET FREQUENCY TABLE PTR TO PSG
    LD HL, PSGFreqTable
    LD (SndFreqTablePtr), HL
;   CHECK IF PAUSE OPERATION FLAG IS SET
    LD A, (SndPauseFlag)
    OR A
    JP Z, RunSoundSubroutines
    ; SILENCE ALL CHANNELS EXCEPT CHANNEL 0
    LD A, ~CHANALL_BITS | CHAN1_BITS
    OUT (PSG_PORT), A
    ADD A, CHAN1_BITS
    OUT (PSG_PORT), A
    ADD A, CHAN1_BITS
    OUT (PSG_PORT), A
    ; SILENCE ALL FM CHANNELS
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    CALL NZ, SndStopAllFM@WriteFM
    ; UPDATE ONLY SFX TRACK 0 FOR PAUSE SFX
    LD A, BANK_SOUND
    LD (MAPPER_SLOT2), A
    LD HL, SFXTrack0.SoundQueue
    LD A, (HL)
    LD (HL), $00
    CP A, SNDID_PAUSE
    CALL Z, SndProcessQueueSFX
    CALL SndChannelProcessSFX
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    ; STOP HERE IF GAME IS PAUSED
    LD A, (GamePauseStatus)
    RRA
    RET C
    ; CHECK IF PAUSE SFX HAS FINISHED PLAYING
    LD A, (SFXTrack0.Control)
    AND A, bitValue(CHANCON_PLAYING)
    RET NZ
    ; CLEAR SOUND FLAG (NORMAL OPERATION WILL RESUME)
    XOR A
    LD (SndPauseFlag), A
    RET

RunSoundSubroutines:
    LD A, BANK_SOUND
    LD (MAPPER_SLOT2), A
;   SKIP SFX ON TITLE SCREEN/DEMO
    LD A, (OperMode)
    OR A
    JR Z, SkipSFX
;   SFX UPDATE
    ; HANDLE ALL QUEUES
    LD HL, SFXTrack0.SoundQueue
    LD A, (HL)
    OR A
    CALL NZ, SndProcessQueueSFX
    LD HL, SFXTrack1.SoundQueue
    LD A, (HL)
    OR A
    CALL NZ, SndProcessQueueSFX
    LD HL, SFXTrack2.SoundQueue
    LD A, (HL)
    OR A
    CALL NZ, SndProcessQueueSFX
    ; SFX TRACK 0 (TONE)
    LD HL, SFXTrack0
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessSFX
    ; SFX TRACK 1 (TONE)
    LD HL, SFXTrack1
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessSFX
    ; SFX TRACK 2 (NOISE)
    LD HL, SFXTrack2
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessSFX
    ; LAYERED SFX (ONLY IN FM MODE)
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    JR Z, SkipSFX
    LD HL, MusicTrack3
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessSFX
;   MUSIC UPDATE
SkipSFX:
    LD HL, (MusicRoutine)
    CALL IndirectCallHL
    XOR A
    LD (MusicTrack0.SoundQueue), A
    ; TEMPO WAIT (ONLY FOR MUSIC)
    LD A, (SndCurrentTempo)
    LD HL, SndTempoTimeout
    ADD A, (HL)
    LD (HL), A
    JR NC, SkipSoundRoutines
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    LD HL, MusicTrack0.Duration
    JR Z, TempoWaitPSG
    LD H, >FMTrack0
    INC (HL)
    INC H
    INC (HL)
    INC H
    INC (HL)
    INC H
    INC (HL)
    INC H
    INC (HL)
    INC H
TempoWaitPSG:
    INC (HL)
    INC H
    INC (HL)
    INC H
    INC (HL)
    INC H
    INC (HL)
    ; FALL THROUGH

SkipSoundRoutines:
    XOR A
    LD HL, SFXTrack0.SoundQueue
    LD (HL), A
    INC H
    LD (HL), A
    INC H
    LD (HL), A
;
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    RET

SndStopAll:
;   CLEAR ALL TRACK CONTROL FLAGS
    XOR A
    LD B, TRACK_COUNT
    LD HL, MusicTrack0.Control
-:
    LD (HL), A
    INC H
    DJNZ -
;   WRITE MAX ATTENUATION TO ALL CHANNELS
@WritePSG:
    LD A, ~CHANALL_BITS
    OUT (PSG_PORT), A
    ADD A, CHAN1_BITS
    OUT (PSG_PORT), A
    ADD A, CHAN1_BITS
    OUT (PSG_PORT), A
    ADD A, CHAN1_BITS
    OUT (PSG_PORT), A
    RET

SilenceAllSound:
;   MUTE ALL PSG CHANNELS (BUT DON'T CLEAR THEIR FLAGS)
    CALL SndStopAll@WritePSG
    ; FALL THROUGH

SndStopAllFM:
;   CLEAR ALL FM TRACK CONTROL FLAGS
    XOR A
    LD B, FM_COUNT
    LD HL, FMTrack0.Control
-:
    LD (HL), A
    INC H
    DJNZ -
@WriteFM:
    LD BC, $0900 + (FMREG_INSTVOL | FM_CHAN0_BITS)
    LD D, FMREG_FNUMKEY
-:
    LD A, C
    OUT (OPLLREG_PORT), A
    LD A, %00001111         ; INSTRUMENT: 0, VOLUME: $0F
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    INC C
    LD A, D
    INC D
    OUT (OPLLREG_PORT), A
    XOR A                   ; KEY OFF
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    DJNZ -
    RET

SndInitMemory:
;   TRACK MEMORY
    LD H, >MusicTrack0
    LD C, $04 + $03 + $09   ; 4 MUSIC, 3 SFX, 9 FM
    XOR A
--:
    LD L, <MusicTrack0
    LD B, _sizeof_SndTrack
-:
    LD (HL), A
    INC L
    DJNZ -
    INC H
    DEC C
    JP NZ, --
@InitSndLinearMem:
;   GLOBAL MEMORY
    LD HL, SndTempoTimeout
    LD DE, SndTempoTimeout + $01
    LD (HL), $00
    LD BC, $0007
    LDIR
@InitChanBits:
    ; MUSIC TRACKS
    LD HL, MusicTrack0.ChanBits
    LD A, CHAN2_BITS    ; MUSIC TRACK 0 ON PSG CHANNEL 2
    LD (HL), A
    LD A, CHAN0_BITS    ; MUSIC TRACK 1 ON PSG CHANNEL 0
    INC H
    LD (HL), A
    LD A, CHAN1_BITS    ; MUSIC TRACK 2 ON PSG CHANNEL 1
    INC H
    LD (HL), A
    LD A, CHAN3_BITS    ; MUSIC TRACK 3 ON PSG CHANNEL 3
    INC H
    LD (HL), A
    ; SFX TRACKS
    LD A, CHAN0_BITS    ; SFX TRACK 0 ON PSG CHANNEL 0
    INC H
    LD (HL), A
    LD A, CHAN1_BITS    ; SFX TRACK 1 ON PSG CHANNEL 1
    INC H
    LD (HL), A
    LD A, CHAN3_BITS    ; SFX TRACK 2 ON PSG CHANNEL 3
    INC H
    LD (HL), A
    ; FM TRACKS
    LD BC, $0900 + FM_CHAN0_BITS
-:
    INC H
    LD (HL), C
    INC C
    DJNZ -
    ; PUT ON MUSIC TRACK 3 ON PSG CHANNEL 2 IN FM MODE
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    RET Z
    LD A, CHAN2_BITS
    LD (MusicTrack3.ChanBits), A
    RET

;-------------------------------------------------------------------------------------

SndChannelProcessSFX:
@TrackUpdate:
;   TRACK UPDATE
    LD L, <SFXTrack0.Duration
    DEC (HL)
    JP NZ, +
    ; NEW NOTE...
        ; READ FROM SOUND DATA
    CALL SndReadTrackStream
        ; EXIT IF AT REST
    LD L, <SFXTrack0.Control
    BIT CHANCON_REST, (HL)
    RET NZ
        ; FREQUENCY UPDATE
    LD L, <SFXTrack0.Frequency
    LD E, (HL)
    INC L
    LD D, (HL)
    LD L, <SFXTrack0.Control
    BIT CHANCON_MOD, (HL)
    CALL NZ, SndApplyModulation
    CALL SndWriteChannelData@UpdateFreq
        ; VOLUME UPDATE
    JP SndWriteChannelData@UpdateVolume
+:
    ; NOTE IS GOING...
        ; EXIT IF AT REST
    LD L, <SFXTrack0.Control
    BIT CHANCON_REST, (HL)
    RET NZ
        ; ONLY UPDATE VOLUME IF ENVELOPE IS BEING USED
    LD L, <SFXTrack0.Envelope
    LD A, (HL)
    OR A
    CALL NZ, SndWriteChannelData@UpdateEnvelope
        ; ONLY UPDATE FREQUENCY IF MODULATION IS APPLIED
    LD L, <SFXTrack0.Control
    BIT CHANCON_MOD, (HL)
    RET Z
    LD L, <SFXTrack0.Frequency
    LD E, (HL)
    INC L
    LD D, (HL)
    CALL SndApplyModulation    
    JP SndWriteChannelData@UpdateFreq


SndChannelProcessMUS:
;   PROCESS QUEUE IF IT ISN'T EMPTY
    LD A, (MusicTrack0.SoundQueue)
    OR A
    CALL NZ, SndProcessQueueMusic
;   CHECK SECONDARY QUEUE (FOR HURRY UP)
    LD A, (MusicTrack0.Control)
    AND A, bitValue(CHANCON_PLAYING)
    JP NZ, +
    LD A, (MusicTrack1.SoundQueue)
    OR A
    CALL NZ, SndProcessQueueMusic
    XOR A
    LD (MusicTrack1.SoundQueue), A
+:
;   TRACK 0 (NEVER INTERRUPTED BY SFX)
    LD HL, MusicTrack0.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessSFX@TrackUpdate
;   TRACK 1
    LD HL, MusicTrack1.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessMUS@TrackUpdate
;   TRACK 2
    LD HL, MusicTrack2.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessMUS@TrackUpdate
;   TRACK 3
    LD HL, MusicTrack3.Control
    BIT CHANCON_PLAYING, (HL)
    RET Z
    ; FALL THROUGH

@TrackUpdate:
    LD L, <SFXTrack0.Duration
    DEC (HL)
    JP NZ, +
;   NEW NOTE...
    ; READ FROM SOUND DATA
    CALL SndReadTrackStream
    ; EXIT IF AT REST
    LD L, <SFXTrack0.Control
    BIT CHANCON_REST, (HL)
    RET NZ
    ; FREQUENCY UPDATE
    LD L, <SFXTrack0.Frequency
    LD E, (HL)
    INC L
    LD D, (HL)
    LD L, <SFXTrack0.Control
    BIT CHANCON_MOD, (HL)
    CALL NZ, SndApplyModulation
    ; ONLY SEND FREQUENCY IF NOT BEING OVERRIDDEN BY SFX
    LD L, <SFXTrack0.Control
    BIT CHANCON_SFX, (HL)
    CALL Z, SndWriteChannelData@UpdateFreq
    ; VOLUME UPDATE
    JP SndWriteChannelData@UpdateVolume
;   NOTE IS GOING...
+:
    ; EXIT IF AT REST
    LD L, <SFXTrack0.Control
    BIT CHANCON_REST, (HL)
    RET NZ
    ; ONLY UPDATE VOLUME IF ENVELOPE IS BEING USED
    LD L, <SFXTrack0.Envelope
    LD A, (HL)
    OR A
    CALL NZ, SndWriteChannelData@UpdateEnvelope
    ; ONLY UPDATE FREQUENCY IF MODULATION IS APPLIED
    LD L, <SFXTrack0.Control
    BIT CHANCON_MOD, (HL)
    RET Z
    LD L, <SFXTrack0.Frequency
    LD E, (HL)
    INC L
    LD D, (HL)
    CALL SndApplyModulation
    ; ONLY SEND FREQUENCY IF NOT BEING OVERRIDDEN BY SFX
    LD L, <SFXTrack0.Control
    BIT CHANCON_SFX, (HL)
    JP Z, SndWriteChannelData@UpdateFreq
    RET



;--------------------------------

SndProcessQueueSFX:
    LD B, A
;   EXIT IF CURRENTLY PLAYING '1UP' SFX (FOR SFXTrack1)
    INC L           ; SoundPlaying
    LD A, (HL)
    CP A, SNDID_1UP
    RET Z
;   DO ADDITIONAL PROCESSING IF DOING LAYERED SFX IN FM MODE
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    JR Z, @GetSFXData
    LD A, (HL)
    CP A, SNDID_JUMPBIG_01
    JR C, @GetSFXData
    ; SKIP IF SFX IS REPLAYING
    DEC L           ; SoundQueue
    CP A, (HL)
    JR Z, @GetSFXData
    ; ELSE, SILENCE 2ND LAYER
    XOR A
    LD (MusicTrack3.Control), A
    LD A, ~CHANALL_BITS | CHAN2_BITS
    OUT (PSG_PORT), A
@GetSFXData:
;   USE AS OFFSET INTO SndIndexTable
    LD L, <SFXTrack0.SoundPlaying
    LD A, B
    LD (HL), A
    SUB A, $81
    ADD A, A
    LD L, <SFXTrack0.Control
    LD (HL), bitValue(CHANCON_PLAYING)
    INC L
    EX DE, HL       ; DE - TRACK RAM, HL - TRACK DATA
    LD HL, SndIndexTable
    addAToHL8_M
;
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
;
    LDI             ; DataPointer
    LDI             ; DataPointer + $01
    LDI             ; Transpose
    LDI             ; Volume
    LDI             ; EnvelopeIndex (Doesn't matter)
    LDI             ; Envelope
;
    EX DE, HL       ; DE - TRACK DATA, HL - TRACK RAM
    XOR A
    LD (HL), A      ; SavedDuration
    INC L
    LD (HL), A      ; Detune
    INC L
    LD (HL), $01    ; Duration
;   INCREMENT VOLUME BY 1 IF DOING FM MUSIC
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    JP Z, +
    LD L, <SFXTrack0.Volume
    INC (HL)
;   SET UP 2ND LAYER IF DOING LAYERED SFX IN FM MODE
    LD L, <SFXTrack0.SoundPlaying
    LD A, (HL)
    CP A, SNDID_JUMPBIG_01
    RET C
    LD HL, MusicTrack3.Control
    LD (HL), bitValue(CHANCON_PLAYING)
    INC L
    EX DE, HL       ; DE - TRACK RAM, HL - TRACK DATA
    LDI             ; DataPointer
    LDI             ; DataPointer + $01
    LDI             ; Transpose
    LDI             ; Volume
    LDI             ; EnvelopeIndex (Doesn't matter)
    LDI             ; Envelope
    EX DE, HL       ; DE - TRACK DATA, HL - TRACK RAM
    XOR A
    LD (HL), A      ; SavedDuration
    INC L
    LD (HL), A      ; Detune
    INC L
    LD (HL), $01    ; Duration
    RET
+:
;   SET SFX OVERRIDE BIT ON MUSIC TRACK THAT SHARES CHANNEL (PSG MODE ONLY)
    DEC H
    DEC H
    DEC H
    LD L, <SFXTrack0.Control
    SET CHANCON_SFX, (HL)
    INC H
    INC H
    INC H
    RET

SndProcessQueueMusic:
    LD HL, MusicTrack0.SoundPlaying
    LD (HL), A
;   STOP SFX TRACK 0 AND 1 IF QUEUEING DEATH MUSIC
    CP A, SNDID_DEATH
    JP NZ, +
    XOR A
    LD DE, SFXTrack0
    LD (DE), A
    INC D
    LD (DE), A
    LD A, (HL)
;   COPY GLOBAL TRACK DATA
+:
    SUB A, $81    
    ADD A, A
    EX DE, HL       ; DE - TRACK RAM, HL - TRACK DATA
    LD HL, SndIndexTable
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    INC HL          ; UNUSED (FM VOICE)
    INC HL          ; UNUSED (FM VOICE)
    INC HL          ; UNUSED
    INC HL          ; CHANNEL COUNT
    INC HL          ; TICK MULTIPLIER
;   SET SPEED FLAG DEPENDING ON ID
    LD A, (MusicTrack0.SoundPlaying)
    CP A, SNDID_SILENCE + $01
    JP NC, @TempoSetup
    CP A, SNDID_HURRYUP
    JP C, @TempoSetup
    LD A, $00
    LD (SndHurryUpFlag), A
    JP NZ, @TempoSetup
    INC A
    LD (SndHurryUpFlag), A
;   SETUP TEMPO
@TempoSetup:
    XOR A
    LD (SndTempoTimeout), A
    ; LD E, <MusicTrack0.SoundPlaying
    ; LD A, (DE)
    ; SUB A, SNDID_WATER
    ; LD BC, SpeedUpTempoTable
    ; addAToBC8_M
    LD A, (SndHurryUpFlag)
    OR A
    LD A, (HL)
    JP Z, +
    XOR A ;LD A, (BC)
+:
    LD (SndCurrentTempo), A
    INC HL
;   CHANNEL LOOP START
    LD BC, $04FF
    LD E, <MusicTrack0.DataPointer
@ChanSetupLoop:
    LDI             ; DataPointer
    LDI             ; DataPointer + $01
    LDI             ; Transpose
    LDI             ; Volume
    LDI             ; EnvelopeIndex (Doesn't matter)
    LDI             ; Envelope
;
    XOR A
    LD (DE), A      ; SavedDuration
    INC E
    LD (DE), A      ; Detune
    INC E
    INC A
    LD (DE), A      ; Duration
    ; SET LOOP COUNTERS AND CALL STACK
    XOR A
    LD E, <MusicTrack0.LoopCounters
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD A, <MusicTrack0.GoSubStack
    LD (DE), A
    ; SET SFX OVERRIDE FLAG IF SFX IS PLAYING ON THE SAME CHANNEL
    LD E, <SFXTrack0.Control
    LD A, D
    CP A, >MusicTrack0
    LD A, bitValue(CHANCON_PLAYING)
    JP Z, +
    INC D
    INC D
    INC D
    LD A, (DE)
    DEC D
    DEC D
    DEC D
    RLCA
    LD A, bitValue(CHANCON_PLAYING)
    JP NC, +
    LD A, bitValue(CHANCON_PLAYING) | bitValue(CHANCON_SFX)
+:
    LD (DE), A
    INC E
    INC D           ; Point to next music track
    DJNZ @ChanSetupLoop
    EX DE, HL
    RET

;--------------------------------

SndReadTrackStream:
;
    LD L, <FMTrack0.FinalFreqMSB
    SET 7, (HL)
;   DO NOTE OFF IF DOING FM TRACK && NO ATK FLAG ISN'T SET
    LD L, <SFXTrack0.Control
    BIT CHANCON_NOATK, (HL)
    JP NZ, +
    LD A, H
    CP A, >FMTrack0
    CALL NC, SndStopChannel@SilenceFM
+:
;   CLEAR 'NO ATTACK' FLAG && REST FLAG
    LD L, <SFXTrack0.Control
    LD A, (HL)
    AND A, ~(bitValue(CHANCON_NOATK) | bitValue(CHANCON_REST))
    LD (HL), A
;   GET TRACK POINTER
    INC L
    LD C, (HL)
    INC L
    LD B, (HL)
;   --- START OF TRACK READ LOOP ---
@SndReadLoop:
    ; GET NEXT BYTE
    LD A, (BC)
    INC BC
    ; CHECK IF BYTE IS COORDINATION FLAG
    CP A, CF_START
    JP NC, SndProcessCF
;   --- END OF TRACK READ LOOP ---
;   CHECK IF BYTE IS DURATION
    OR A
    JP P, @SndUpdateDuration
;   IF NOT, BYTE IS NOTE. SET CHANNEL FREQUENCY
    CALL SndSetFrequency
;   GET NEXT BYTE AND CHECK IF IT'S NOT A DURATION
    LD A, (BC)
    OR A
    JP M, +
;   ELSE, ADVANCE POINTER
    INC BC
@SndUpdateDuration:
;   SET NEW DURATION VALUE
    LD L, <SFXTrack0.SavedDuration
    LD (HL), A
    LD L, <SFXTrack0.Duration
    LD (HL), A
+:
;   SET DURATION TO RESET VALUE (POINTLESS IF DIDN'T BRANCH HERE)
    LD L, <SFXTrack0.SavedDuration
    LD A, (HL)
    LD L, <SFXTrack0.Duration
    LD (HL), A
;   UPDATE TRACK POINTER
    LD L, <SFXTrack0.DataPointer
    LD (HL), C
    INC L
    LD (HL), B
;   SET FINAL VOLUME TO CURRENT VOLUME
    LD L, <FMTrack0.Volume
    LD A, (HL)
    LD L, <FMTrack0.FinalVolume
    LD (HL), A
;   RESET FM PATCH INDEX
    LD L, <SFXTrack0.PatchEnvIndex
    LD (HL), $00
;   SET REST FLAG IF FREQUENCY IS INVALID
    LD L, <SFXTrack0.Frequency + $01
    LD A, (HL)
    OR A
    LD L, <SFXTrack0.Control
    JP P, +
    SET CHANCON_REST, (HL)
+:
;   RETURN IF 'NO ATTACK' FLAG IS SET
    ;LD L, <SFXTrack0.Control
    BIT CHANCON_NOATK, (HL)
    RET NZ
;   RESET ENVELOPE INDEX
    LD L, <SFXTrack0.EnvelopeIndex
    LD (HL), $00
;   RETURN IF 'MODULATION' FLAG IS CLEAR
    LD L, <SFXTrack0.Control
    BIT CHANCON_MOD, (HL)
    RET Z
;   SET MODULATION VALUES (FOR NEW NOTE)
    LD L, <SFXTrack0.ModPointer
    LD C, (HL)
    INC L
    LD B, (HL)
    LD A, (BC)
    JP CoordFlagTable@cfModSetup@SndSetModulation


SndSetFrequency:
;   CHECK IF NOTE IS REST NOTE
    SUB A, $81
    JP C, @RestNote
;   CHECK IF TRACK IS USING NOISE CHANNEL
    EX AF, AF'
    LD L, <SFXTrack0.ChanBits
    LD A, (HL)
    CP A, CHAN3_BITS
    JP Z, @SetNoiseFreq
    EX AF, AF'
;   USE NOTE + TRANSPOSE VALUE AS OFFSET INTO FREQUENCY TABLE TO SET NEW FREQUENCY
    LD L, <SFXTrack0.Transpose
    ADD A, (HL)
    ADD A, A
    LD DE, (SndFreqTablePtr)
    addAToDE8_M
    LD L, <SFXTrack0.Frequency
    LD A, (DE)
    LD (HL), A
    INC L
    INC E
    LD A, (DE)
    LD (HL), A
    RET
@RestNote:
;   SET REST FLAG
    LD L, <SFXTrack0.Control
    SET CHANCON_REST, (HL)
;   INVALIDATE FREQUENCY
    LD L, <SFXTrack0.Frequency + $01
    LD (HL), $FF
;   SILENCE CHANNEL
    JP SndStopChannel@SilenceChan
@SetNoiseFreq:
    EX AF, AF'
;   CLEAR HIGH BYTE OF FREQUENCY
    LD L, <SFXTrack0.Frequency + $01
    LD (HL), $00
;   CHECK IF TRACK IS IN DRUM MODE
    LD L, <SFXTrack0.Control
    BIT CHANCON_DRUMMODE, (HL)
    LD L, <SFXTrack0.Frequency
    JP NZ, @SetupNoiseDrum
;   NOT IN DRUM MODE, SO USE VALUE AS NOISE TYPE/FREQUENCY
    AND A, $07
    OR A, $E0           ; ADD LATCH BIT, CHANNEL 3 BITS
    LD (HL), A
    RET
@SetupNoiseDrum:
    ADD A, A
    LD DE, PSGDrumTable
    addAToDE8_M
    LD A, (DE)
    LD (HL), A
    INC E
    LD A, (DE)
    LD L, <SFXTrack0.Envelope
    LD (HL), A
    RET


SndWriteChannelData:
@UpdateFreq:
;   CHECK IF TRACK IS USING NOISE CHANNEL
    LD L, <SFXTrack0.ChanBits
    LD A, (HL)
    CP A, CHAN3_BITS
    JP NZ, @UpdateToneFreq
    LD A, E
    OUT (PSG_PORT), A
    RET
@UpdateToneFreq:
;   ADD DETUNE TO TRACK FREQUENCY
    LD L, <SFXTrack0.Detune
    LD A, (HL)
    addAToDES_M
;   WRITE FREQUENCY TO PSG
    LD A, E
    AND A, $0F
    OR A, bitValue(LATCH_BIT)
    LD L, <SFXTrack0.ChanBits
    OR A, (HL)
    OUT (PSG_PORT), A
    LD A, E
    SRL D
    RRA
    SRL D
    RRA
    RRA
    RRA
    AND A, $3F
    OUT (PSG_PORT), A
    RET

@UpdateVolume:
;   SAVE CHANNEL VOLUME IN B
    LD L, <SFXTrack0.Volume
    LD B, (HL)
;   CHECK IF TRACK IS USING AN ENVELOPE. IF NOT, SKIP ENVELOPE UPDATE 
    LD L, <SFXTrack0.Envelope
    LD A, (HL)
    OR A
    JP Z, @WriteVolume
@UpdateEnvelope:
;   SAVE CHANNEL VOLUME IN B
    LD L, <SFXTrack0.Volume
    LD B, (HL)
;   GET TABLE OF ENVELOPE AND ADD CURRENT INDEX
    EX DE, HL   ; DE - TRACK RAM, HL - N/A
    LD HL, VolumeEnvTable
    DEC A
    ADD A, A
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    LD E, <SFXTrack0.EnvelopeIndex
    LD A, (DE)
    addAToHL8_M
;   CHECK IF AT VALUE >= $80. IF SO, DON'T UPDATE VOLUME
    BIT 7, (HL)
    EX DE, HL   ; DE - IDX VALUE, HL - TRACK RAM
    RET M
;   INCREMENT INDEX AND ADD VALUE TO VOLUME
    INC (HL)
    LD A, (DE)
    ADD A, B
;   LIMIT VOLUME TO <= $0F
    CP A, $10
    LD B, A
    JP C, @WriteVolume
    LD B, $0F
@WriteVolume:
;   ONLY SEND VOLUME IF TRACK ISN'T OVERRIDDEN BY SFX
    LD L, <SFXTrack0.Control
    BIT CHANCON_SFX, (HL)
    RET NZ
;   SEND VOLUME TO PSG
    LD A, B
    LD L, <SFXTrack0.ChanBits
    OR A, (HL)
    OR A, LATCH_VOL
    OUT (PSG_PORT), A
    RET


SndApplyModulation:
    LD L, <SFXTrack0.ModFreq
    LD C, (HL)
    INC L
    LD B, (HL)
    EX DE, HL   ; DE - TRACK PTR, HL - FREQ
    ADD HL, BC
    EX DE, HL   ; DE - FREQ + MOD, HL - TRACK PTR
;   CONTINUE IF MODULATION WAIT IS 0
    LD L, <SFXTrack0.ModWait
    LD A, (HL)
    OR A
    JP Z, +
;   ELSE, DECREMENT AND EXIT
    DEC (HL)
    RET
;   DECREMENT MODULATION SPEED AND CONTINUE IF 0
+:
    INC L
    DEC (HL)
    RET NZ
;   GET MODULATION POINTER TO RESET SPEED
    LD L, <SFXTrack0.ModPointer
    LD C, (HL)
    INC L
    LD B, (HL)
    INC BC
    LD A, (BC)
    LD L, <SFXTrack0.ModSpeed
    LD (HL), A
;   CHECK IF STEPS ISN'T 0
    LD L, <SFXTrack0.ModSteps
    LD A, (HL)
    OR A
    JP NZ, +
;   ELSE, RESET STEPS, NEGATE DELTA AND EXIT
    INC BC
    INC BC
    LD A, (BC)
    LD (HL), A
    DEC L
    LD A, (HL)
    NEG
    LD (HL), A
    RET
;   DECREMENT STEPS
+:
    DEC (HL)
;   GET MODULATION OFFSET AND ADD DELTA TO IT
    LD L, <SFXTrack0.ModDelta
    LD A, (HL)
    LD L, <SFXTrack0.ModFreq
    LD C, (HL)
    INC L
    LD B, (HL)
    addAToBCS_M
    LD (HL), B
    DEC L
    LD (HL), C
;   ADD TO BASE FREQUENCY
    LD L, <SFXTrack0.ModDelta
    LD A, (HL)
    addAToDES_M
    RET

;-----------------------------------------
;               FM ROUTINES
;-----------------------------------------

SndProcessQueueMusicFM:
    CP A, SNDID_SILENCE
    JP Z, SilenceAllSound
;
    LD HL, MusicTrack0.SoundPlaying
    LD (HL), A
;   COPY GLOBAL TRACK DATA
    LD H, >FMTrack0
    SUB A, $81 - $0E
    ADD A, A
    EX DE, HL       ; DE - TRACK RAM, HL - TRACK DATA
    LD HL, SndIndexTable
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    INC HL          ; UNUSED (FM VOICE)
    INC HL          ; UNUSED (FM VOICE)
    INC HL          ; UNUSED
    INC HL          ; CHANNEL COUNT
    INC HL          ; TICK MULTIPLIER
;   SET SPEED FLAG DEPENDING ON ID
    LD A, (MusicTrack0.SoundPlaying)
    CP A, SNDID_SILENCE + $01
    JP NC, @TempoSetup
    CP A, SNDID_HURRYUP
    JP C, @TempoSetup
    LD A, $00
    LD (SndHurryUpFlag), A
    JP NZ, @TempoSetup
    INC A
    LD (SndHurryUpFlag), A
;   SETUP TEMPO
@TempoSetup:
    XOR A
    LD (SndTempoTimeout), A
    LD A, (MusicTrack0.SoundPlaying)
    SUB A, SNDID_WATER
    LD BC, SpeedUpTempoTableFM
    addAToBC8_M
    LD A, (SndHurryUpFlag)
    OR A
    LD A, (HL)
    JP Z, +
    LD A, (BC)
+:
    LD (SndCurrentTempo), A
    INC HL
;   CHANNEL LOOP START
    LD BC, $09FF
    LD E, <FMTrack0.DataPointer
@ChanSetupLoop:
    LDI             ; DataPointer
    LDI             ; DataPointer + $01
    LDI             ; Transpose
    LDI             ; Volume
    LDI             ; EnvelopeIndex (Doesn't matter) USED AS PatchEnvelope
    LDI             ; Envelope
;
    XOR A
    LD (DE), A      ; SavedDuration
    INC E
    LD (DE), A      ; Detune
    INC E
    INC A
    LD (DE), A      ; Duration
    LD E, <FMTrack0.Instrument  ; default instrument is Violin
    LD (DE), A
    ;
    LD E, <FMTrack0.EnvelopeIndex
    LD A, (DE)
    LD E, <FMTrack0.PatchEnvelope
    LD (DE), A
    ; SET LOOP COUNTERS AND CALL STACK
    XOR A
    LD E, <FMTrack0.LoopCounters
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD (DE), A
    INC E
    LD A, <FMTrack0.GoSubStack
    LD (DE), A
    ; SET PLAYING FLAG
    LD E, <FMTrack0.Control
    LD A, bitValue(CHANCON_PLAYING)
    LD (DE), A
    INC E
    INC D           ; Point to next music track
    DJNZ @ChanSetupLoop
    EX DE, HL
    RET

SndChannelProcessFM:
;   SET FREQUENCY TABLE PTR TO FM
    LD HL, FMFreqTable
    LD (SndFreqTablePtr), HL
;   PROCESS QUEUE IF IT ISN'T EMPTY
    LD A, (MusicTrack0.SoundQueue)
    OR A
    CALL NZ, SndProcessQueueMusicFM
;   CHECK SECONDARY QUEUE (FOR HURRY UP)
    LD A, (FMTrack0.Control)
    AND A, bitValue(CHANCON_PLAYING)
    JP NZ, +
    LD A, (MusicTrack1.SoundQueue)
    OR A
    CALL NZ, SndProcessQueueMusicFM
    XOR A
    LD (MusicTrack1.SoundQueue), A
+:
;   FM TRACK 0
    LD HL, FMTrack0.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessFM@TrackUpdate
;   FM TRACK 1
    LD HL, FMTrack1.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessFM@TrackUpdate
;   FM TRACK 2
    LD HL, FMTrack2.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessFM@TrackUpdate
;   FM TRACK 3
    LD HL, FMTrack3.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessFM@TrackUpdate
;   FM TRACK 4
    LD HL, FMTrack4.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessFM@TrackUpdate
;   FM TRACK 5
    LD HL, FMTrack5.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessFM@TrackUpdate
;   FM TRACK 6
    LD HL, FMTrack6.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessFM@TrackUpdate
;   FM TRACK 7
    LD HL, FMTrack7.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessFM@TrackUpdate
;   FM TRACK 8
    LD HL, FMTrack8.Control
    BIT CHANCON_PLAYING, (HL)
    RET Z
;   FALL THROUGH

@TrackUpdate:
    LD L, <FMTrack0.Duration
    DEC (HL)
    ; READ FROM SOUND DATA IF DURATION EXPIRED
    CALL Z, SndReadTrackStream
    ; EXIT IF AT REST
    LD L, <FMTrack0.Control
    BIT CHANCON_REST, (HL)
    RET NZ
    ; ONLY UPDATE VOLUME IF ENVELOPE IS BEING USED
    LD L, <FMTrack0.FinalVolume
    LD B, (HL)
    LD L, <FMTrack0.Envelope
    LD A, (HL)
    OR A
    CALL NZ, SndWriteChannelDataFM@UpdateEnvelope
    ; ONLY UPDATE PATCH IF ENVELOPE IS BEING USED
    LD L, <FMTrack0.PatchEnvelope
    LD A, (HL)
    OR A
    CALL NZ, SndWriteChannelDataFM@UpdatePatchEnv
    ; WRITE VOLUME AND INSTRUMENT TO FM CHIP
    CALL SndWriteChannelDataFM@WriteVolumeInst
    ; FREQUENCY UPDATE
    LD L, <FMTrack0.Frequency
    LD E, (HL)
    INC L
    LD D, (HL)
    ; IF BIT 7 IS SET, ALWAYS UPDATE FREQUENCY (NOTE ON OCCURRED)
    LD L, <FMTrack0.FinalFreqMSB
    BIT 7, (HL)
    LD L, <FMTrack0.Control
    JP NZ, +
    ; ELSE, ONLY UPDATE FREQUENCY IF MODULATION IS APPLIED
    BIT CHANCON_MOD, (HL)
    RET Z
+:
    BIT CHANCON_MOD, (HL)   ; REDUNDANT IF FELL THROUGH
    CALL NZ, SndApplyModulation
    ; SEND FREQUENCY TO FM CHIP
    ; FALL THROUGH

SndWriteChannelDataFM:
@UpdateFreq:
;   ADD DETUNE TO TRACK FREQUENCY
    LD L, <FMTrack0.Detune
    LD A, (HL)
    addAToDES_M
;   SAVE FREQUENCY MSB
    LD L, <FMTrack0.FinalFreqMSB
    LD (HL), D
;   WRITE FREQUENCY TO FM
    LD A, FMREG_FNUMLSB
    LD L, <FMTrack0.ChanBits
    OR A, (HL)
    OUT (OPLLREG_PORT), A
    LD A, E
    OUT (OPLLDATA_PORT), A
    EX (SP), HL
    EX (SP), HL
    PUSH HL
    POP HL
    LD A, FMREG_FNUMKEY
    OR A, (HL)
    OUT (OPLLREG_PORT), A
    LD L, <FMTrack0.Control
    LD A, (HL)
    RRCA
    AND A, %00100000
    OR A, %00010000
    OR A, D
    OUT (OPLLDATA_PORT), A
    RET

@UpdateEnvelope:
;   SAVE CHANNEL VOLUME TO B (REDUNDANT IF FELL THROUGH)
    LD L, <FMTrack0.Volume
    LD B, (HL)
;   GET TABLE OF ENVELOPE AND ADD CURRENT INDEX
    EX DE, HL   ; DE - TRACK RAM, HL - N/A
    LD HL, FMVolumeEnvTable
    DEC A
    ADD A, A
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    LD E, <FMTrack0.EnvelopeIndex
    LD A, (DE)
    addAToHL8_M
;   CHECK IF AT VALUE >= $80. IF SO, DON'T UPDATE VOLUME
    BIT 7, (HL)
    EX DE, HL   ; DE - IDX VALUE, HL - TRACK RAM
    RET M
;   INCREMENT INDEX AND ADD VALUE TO VOLUME
    INC (HL)
    LD A, (DE)
    ADD A, B
;   LIMIT FINAL VOLUME TO <= $0F
    LD L, <FMTrack0.FinalVolume
    CP A, $10
    LD (HL), A
    RET C
    LD (HL), $0F
    RET

@UpdatePatchEnv:    
;   GET TABLE OF ENVELOPE AND ADD CURRENT INDEX
    EX DE, HL   ; DE - TRACK RAM, HL - N/A
    LD HL, FMPatchEnvTable
    DEC A
    ADD A, A
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    LD E, <FMTrack0.PatchEnvIndex
    LD A, (DE)
    addAToHL8_M
;   CHECK IF AT VALUE >= $80. IF SO, DON'T UPDATE PATCH
    BIT 7, (HL)
    EX DE, HL   ; DE - IDX VALUE, HL - TRACK RAM
    RET M
;   INCREMENT INDEX AND USE VALUE AS PATCH
    INC (HL)
    LD A, (DE)
    LD L, <FMTrack0.Instrument
    LD (HL), A
    RET

@WriteVolumeInst:
;   SEND VOLUME AND INSTRUMENT TO FM
    LD A, FMREG_INSTVOL
    LD L, <FMTrack0.ChanBits
    OR A, (HL)
    OUT (OPLLREG_PORT), A
    LD L, <FMTrack0.Instrument
    LD A, (HL)
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    LD L, <FMTrack0.FinalVolume
    OR A, (HL)
    OUT (OPLLDATA_PORT), A
    RET

;-------------------------------------------------------------------------------------

;   HL - TRACK RAM, BC - TRACK DATA POINTER
SndProcessCF:
;   CONVERT FLAG INTO OFFSET
    SUB A, CF_START
    LD E, A
    ADD A, A
    ADD A, E
;   ADD TO TABLE
    ;LD IX, CoordFlagTable
    ;addAToIX8_M
    ;LD A, (BC)
    ;JP (IX)
    LD E, H
    LD HL, CoordFlagTable
    addAToHL8_M
    LD A, (BC)
    JP (HL)


.SECTION "Coordination Flag Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
CoordFlagTable:
    JP @cfSetPatchEnv       ; $E0 (SET FM PATCH ENVELOPE)
    JP @cfDetune            ; $E1 (DETUNE)
    JP @cfSusOn             ; $E2 (FM SUSTAIN ON)
    JP @cfCallReturn        ; $E3 (CALL RETURN)
    JP @return              ; $E4 (FADE IN)
    JP @return              ; $E5 (SET TEMPO DIVIDER SINGLE)
    JP @cfSusOff            ; $E6 (FM SUSTAIN OFF)
    JP @cfNoAtk             ; $E7 (NO ATTACK NOTE)
    JP @return              ; $E8 (NOTE TIMEOUT)
    JP @cfTranspose         ; $E9 (CHANGE TRANSPOSITION)
    JP @cfTempo             ; $EA (SET TEMPO)
    JP @return              ; $EB (SET TEMPO DIVIDER ALL)
    JP @cfChangePSGVol      ; $EC (CHANGE PSG VOL)
    JP @cfDrumMode          ; $ED (CH4 DRUM MODE)
    JP @return              ; $EE (READ LITERAL MODE)
    JP @cfSetFMInst         ; $EF (SET FM VOICE)
    JP @cfModSetup          ; $F0 (MODULATION SETUP/ON)
    JP @cfModOn             ; $F1 (MODULATION ON)
    JP @cfStopTrack         ; $F2 (STOP TRACK)
    JP @return              ; $F3 (SET PSG NOISE)
    JP @cfModOff            ; $F4 (MODULATION OFF)
    JP @cfSetEnvelope       ; $F5 (SET PSG ENVELOPE)
    JP @cfJumpTo            ; $F6 (JUMP TO)
    JP @cfLoop              ; $F7 (LOOP SECTION)
    JP @cfCall              ; $F8 (CALL)
.ENDS

@return:
    ; ADVANCE TRACK POINTER AND CONTINUE READING IT
    INC BC
    JP SndReadTrackStream@SndReadLoop
;   ---------------------------------------------
;   E0 - SET FM PATCH ENVELOPE
@cfSetPatchEnv:
    LD H, E
    LD L, <FMTrack0.PatchEnvelope
    LD (HL), A
    JR @return
;   ---------------------------------------------
;   E1 - CHANGE DETUNE
@cfDetune:
    LD H, E
    LD L, <SFXTrack0.Detune
    LD (HL), A
    JR @return
;   ---------------------------------------------
;   E2 - FM SUSTAIN ON
@cfSusOn:
    DEC BC  ; NO PARAMETER BYTES
    LD H, E
    LD L, <FMTrack0.Control
    SET CHANCON_FMSUSTAIN, (HL)
    JR @return
;   ---------------------------------------------
;   E3 - CALL RETURN
@cfCallReturn:
    ; POP RETURN ADDRESS OFF THE STACK
    LD H, E
    LD L, <SFXTrack0.StackPointer
    LD L, (HL)
    LD B, (HL)
    INC L
    LD C, (HL)
    INC L
    LD A, L
    LD L, <SFXTrack0.StackPointer
    LD (HL), A
    JR @return
;   ---------------------------------------------
;   E6 - FM SUSTAIN OFF
@cfSusOff:
    DEC BC  ; NO PARAMETER BYTES
    LD H, E
    LD L, <FMTrack0.Control
    RES CHANCON_FMSUSTAIN, (HL)
    JR @return
;   ---------------------------------------------
;   E7 - SET NO ATTACK FLAG
@cfNoAtk:
    DEC BC  ; NO PARAMETER BYTES
    LD H, E
    LD L, <SFXTrack0.Control
    SET CHANCON_NOATK, (HL)
    JR @return
;   ---------------------------------------------
;   E9 - TRANSPOSITION CHANGE
@cfTranspose:
    LD H, E
    LD L, <SFXTrack0.Transpose
    ADD A, (HL)
    LD (HL), A
    JR @return
;   ---------------------------------------------
;   EA - SET TEMPO
@cfTempo:
    LD H, E
    LD (SndCurrentTempo), A
    JR @return
;   ---------------------------------------------
;   EC - VOLUME CHANGE
@cfChangePSGVol:
    LD H, E
    LD L, <SFXTrack0.Volume
    ADD A, (HL)
    LD (HL), A
    CP A, $0F
    JR C, @return
    LD (HL), $0F
    JR @return
;   ---------------------------------------------
;   ED - CH4 DRUM MODE
@cfDrumMode:
    DEC BC  ; NO PARAMETER BYTES
    LD H, E
    LD L, <SFXTrack0.Control
    SET CHANCON_DRUMMODE, (HL)
    JR @return
;   ---------------------------------------------
;   EF - SET FM VOICE
@cfSetFMInst:
    ; SET INSTRUMENT
    LD H, E
    LD L, <FMTrack0.Instrument
    LD (HL), A
    ; EXIT IF USING BUILT IN INSTRUMENTS
    CP A, $10
    JR C, @return
    ; ELSE, SET INSTRUMENT TO CUSTOM
    LD (HL), $00
    ; USE VALUE AS INDEX INTO INSTRUMENT TABLE
    SUB A, $10
    ADD A, A
    ADD A, A
    ADD A, A
    LD DE, FMInstrumentTable
    addAToDE8_M
    ; WRITE DATA TO FM CHIP
    LD A, FMREG_CUSTOM0
    OUT (OPLLREG_PORT), A
    LD A, (DE)
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    INC E
    LD A, FMREG_CUSTOM1
    OUT (OPLLREG_PORT), A
    LD A, (DE)
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    INC E
    LD A, FMREG_CUSTOM2
    OUT (OPLLREG_PORT), A
    LD A, (DE)
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    INC E
    LD A, FMREG_CUSTOM3
    OUT (OPLLREG_PORT), A
    LD A, (DE)
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    INC E
    LD A, FMREG_CUSTOM4
    OUT (OPLLREG_PORT), A
    LD A, (DE)
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    INC E
    LD A, FMREG_CUSTOM5
    OUT (OPLLREG_PORT), A
    LD A, (DE)
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    INC E
    LD A, FMREG_CUSTOM6
    OUT (OPLLREG_PORT), A
    LD A, (DE)
    OUT (OPLLDATA_PORT), A
    RST SndFMWriteDelay
    INC E
    LD A, FMREG_CUSTOM7
    OUT (OPLLREG_PORT), A
    LD A, (DE)
    OUT (OPLLDATA_PORT), A
    JP @return
;   ---------------------------------------------
;   F0 - MODULATION SETUP + ON
@cfModSetup:
    LD H, E
    LD L, <SFXTrack0.Control
    SET CHANCON_MOD, (HL)
    LD L, <SFXTrack0.ModPointer
    LD (HL), C
    INC L
    LD (HL), B
    LD DE, CoordFlagTable@return
    PUSH DE
@@SndSetModulation: ; (FOR IF MODULATION IS TURNED ON DURING A NOTE)
    ; PUT TRACK ADR INTO HL AND ADD OFFSET TO MODULATION SETTINGS
    INC L
    ; WRITE STREAM INFO TO MOD SETTINGS
    LD (HL), A
    INC L
    INC BC
    LD A, (BC)
    LD (HL), A
    INC L
    INC BC
    LD A, (BC)
    LD (HL), A
    INC L
    INC BC
    LD A, (BC)
    SRL A
    LD (HL), A
    ; EXIT IF 'NO ATTACK' FLAG IS SET
    LD L, <SFXTrack0.Control
    BIT CHANCON_NOATK, (HL)
    RET NZ
    ; CLEAR MODULATION VALUE/OFFSET
    XOR A
    LD L, <SFXTrack0.ModFreq
    LD (HL), A
    INC L
    LD (HL), A
    RET
;   ---------------------------------------------
;   F1 - MODULATION ON
@cfModOn:
    DEC BC  ; NO PARAMETER BYTES
    LD H, E
    LD L, <SFXTrack0.Control
    SET CHANCON_MOD, (HL)
    JP @return
;   ---------------------------------------------
;   F2 - STOP
@cfStopTrack:
    ; CLEAR NO ATTACK BIT && PLAYING BIT
    LD H, E
    LD L, <SFXTrack0.Control
    LD A, (HL)
    AND A, ~(bitValue(CHANCON_NOATK) | bitValue(CHANCON_PLAYING))
    LD (HL), A
    ; CLEAR SOUND ID
    LD L, <SFXTrack0.SoundPlaying
    LD (HL), $00
    ; SILENCE CHANNEL
    CALL SndStopChannel@SilenceChan
    ; REMOVE CALLERS (EXIT OUT OF SndChannelProcessXXX)
    ;POP DE  ; CF RETURN CALLER
    POP DE  ; READ STREAM CALLER
    ; CLEAR SFX OVERRIDE BIT ON MUSIC TRACK IF CURRENTLY PROCESSING A SFX TRACK
    LD A, H
    CP A, >FMTrack0
    JP NC, +
    CP A, >SFXTrack0
    RET C
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_FM)
    RET NZ
    LD L, <SFXTrack0.Control
    DEC H
    DEC H
    DEC H
    RES CHANCON_SFX, (HL)
    SET CHANCON_REST, (HL)
    RET
+:
    RET NZ
    XOR A
    LD (MusicTrack0.SoundPlaying), A
    RET
;   ---------------------------------------------
;   F1 - MODULATION OFF
@cfModOff:
    DEC BC  ; NO PARAMETER BYTES
    LD H, E
    LD L, <SFXTrack0.Control
    RES CHANCON_MOD, (HL)
    JP @return
;   ---------------------------------------------
;   F5 - SET PSG ENVELOPE
@cfSetEnvelope:
    LD H, E
    LD L, <SFXTrack0.Envelope
    LD (HL), A
    JP @return
;   ---------------------------------------------
;   F6 - JUMP TO ADDRESS
@cfJumpTo:
    ; SET TRACK POINTER TO GIVEN ADDRESS
    LD H, E
    LD E, A
    INC BC
    LD A, (BC)
    LD C, E
    LD B, A
    DEC BC
    JP @return
;   ---------------------------------------------
;   F7 - LOOP SECTION
@cfLoop:
    INC BC
    ; GET LOOP COUNTER AND CHECK IF NEEDS TO BE SET
    LD H, E
    ADD A, <SFXTrack0.LoopCounters
    LD L, A
    LD A, (HL)
    OR A
    JP NZ, +
    LD A, (BC)
    LD (HL), A
+:
    ; JUMP TO ADDRESS IF COUNTER HASN'T EXPIRED
    INC BC
    LD A, (BC)
    DEC (HL)
    JP NZ, @cfJumpTo
    ; ELSE, CONTINUE ON
    INC BC
    JP @return
;   ---------------------------------------------
;   F8 - CALL SUBROUTINE
@cfCall:
    ; SAVE GIVEN ADDRESS IN DE
    LD H, E
    LD E, A
    INC BC
    LD A, (BC)
    LD D, A
    ; PUSH RETURN ADDRESS TO THE STACK
    LD L, <SFXTrack0.StackPointer
    LD L, (HL)
    DEC L
    LD (HL), C
    DEC L
    LD (HL), B
    LD A, L
    LD L, <SFXTrack0.StackPointer
    LD (HL), A
    ; SET TRACK POINTER TO GIVEN ADDRESS
    LD C, E
    LD B, D
    DEC BC
    JP @return

;-------------------------------------------------------------------------------------

SndStopChannel:
@SilenceChan:
;   DO DIFFERENT THING IF DOING FM TRACK
    LD A, H
    CP A, >FMTrack0
    JP NC, @SilenceFM
;   ONLY SEND VOLUME IF TRACK ISN'T OVERRIDDEN BY SFX
    LD L, <SFXTrack0.Control
    BIT CHANCON_SFX, (HL)
    RET NZ
;   SILENCE CHANNEL
    LD A, ~CHANALL_BITS
    LD L, <SFXTrack0.ChanBits
    OR A, (HL)
    OUT (PSG_PORT), A
    RET

@SilenceFM:
;   SEND KEY OFF
    LD A, FMREG_FNUMKEY
    LD L, <FMTrack0.ChanBits
    OR A, (HL)
    OUT (OPLLREG_PORT), A
    LD L, <FMTrack0.Control
    LD A, (HL)
    RRCA
    AND A, %00100000
    LD L, <FMTrack0.FinalFreqMSB
    OR A, (HL)
    OUT (OPLLDATA_PORT), A
    RET

;-------------------------------------------------------------------------------------

.SECTION "Sound Index Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
SndIndexTable:
    ; SFX START ($00 - $12)
    .dw SFX_JumpBig
    .dw SFX_Bump
    .dw SFX_Swim
    .dw SFX_Kick
    .dw SFX_Pipe
    .dw SFX_Fireball
    .dw SFX_Flagpole
    .dw SFX_JumpSml

    .dw SFX_Coin
    .dw SFX_Item
    .dw SFX_Vine
    .dw SFX_Cannon
    .dw SFX_Beep
    .dw SFX_Powerup
    .dw SFX_1UP
    .dw SFX_BowserFall

    .dw SFX_Shatter
    .dw SFX_Flame
    .dw SFX_Pause
    ; PSG MUSIC START ($13 - $20)
    .dw Mus_Water
    .dw Mus_Overworld
    .dw Mus_Underground
    .dw Mus_Castle
    .dw Mus_Cloud
    .dw Mus_PipeIntro
    .dw Mus_Invincible

    .dw Mus_HurryUp 
    .dw Mus_LevelVictory
    .dw Mus_WorldVictory
    .dw Mus_GameVictory
    .dw Mus_GameOver
    .dw Mus_Death
    .dw Mus_Silence
    ; FM MUSIC START ($21 - $31)
    .dw Mus_Water_FM
    .dw Mus_Overworld_FM
    .dw Mus_Underground_FM
    .dw Mus_Castle_FM
    .dw Mus_Cloud_FM
    .dw Mus_PipeIntro_FM
    .dw Mus_Invincible_FM

    .dw Mus_HurryUp_FM
    .dw Mus_LevelVictory_FM
    .dw Mus_WorldVictory_FM
    .dw Mus_GameVictory_FM
    .dw Mus_GameOver_FM
    .dw Mus_Death_FM
    .dw Mus_Silence
    .dw Mus_Bowser_FM
    .dw Mus_FinalBowser_FM
    .dw Mus_Title_FM
    ; ADDITIONAL SFX ($32 - $34)
    .dw SFX_JumpBig_P1
    .dw SFX_JumpSml_P1
    .dw SFX_Powerup_P1
.ENDS

;--------------------------------

.SECTION "Sound PSG Frequency Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGFreqTable:
;         C     C#    D     Eb    E     F     F#    G     G#    A     Bb    B
    .dw $03FF,$03FF,$03FF,$03FF,$03FF,$03FF,$03FF,$03FF,$03FF,$03F9,$03C0,$038A; Octave 2 - (81 - 8C)   0
	.dw $0357,$0327,$02FA,$02CF,$02A7,$0281,$025D,$023B,$021B,$01FC,$01E0,$01C5; Octave 3 - (8D - 98)   1
	.dw $01AC,$0194,$017D,$0168,$0153,$0140,$012E,$011D,$010D,$00FE,$00F0,$00E2; Octave 4 - (99 - A4)   2
	.dw $00D6,$00CA,$00BE,$00B4,$00AA,$00A0,$0097,$008F,$0087,$007F,$0078,$0071; Octave 5 - (A5 - B0)   3
	.dw $006B,$0065,$005F,$005A,$0055,$0050,$004C,$0047,$0043,$0040,$003C,$0039; Octave 6 - (B1 - BC)   4
	.dw $0035,$0032,$0030,$002D,$002A,$0028,$0026,$0024,$0022,$0020,$001E,$001C; Octave 7 - (BD - C8)   5
	.dw $001B,$0019,$0018,$0016,$0015,$0014,$0013,$0012,$0011,$0010,$000F,$000E; Octave 8 - (C9 - D4)   6
	.dw $000D,$000D,$000C,$000B,$000B,$000A,$0009,$0009,$0008,$0008,$0007,$0007; Octave 9 - (D5 - E0)   7
.ENDS

.SECTION "Sound FM Frequency Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMFreqTable:
;         C     C#    D     Eb    E     F     F#    G     G#    A     Bb    B
    .dw $00AC,$00B7,$00C2,$00CD,$00D9,$00E6,$00F4,$0102,$0112,$0122,$0133,$0146; Octave 0 - (81 - 8C)   0
	.dw $02AC,$02B7,$02C2,$02CD,$02D9,$02E6,$02F4,$0302,$0312,$0322,$0333,$0346; Octave 1 - (8D - 98)   1
	.dw $04AC,$04B7,$04C2,$04CD,$04D9,$04E6,$04F4,$0502,$0512,$0522,$0533,$0546; Octave 2 - (99 - A4)   2
	.dw $06AC,$06B7,$06C2,$06CD,$06D9,$06E6,$06F4,$0702,$0712,$0722,$0733,$0746; Octave 3 - (A5 - B0)   3
	.dw $08AC,$08B7,$08C2,$08CD,$08D9,$08E6,$08F4,$0902,$0912,$0922,$0933,$0946; Octave 4 - (B1 - BC)   4
	.dw $0AAC,$0AB7,$0AC2,$0ACD,$0AD9,$0AE6,$0AF4,$0B02,$0B12,$0B22,$0B33,$0B46; Octave 5 - (BD - C8)   5
	.dw $0CAC,$0CB7,$0CC2,$0CCD,$0CD9,$0CE6,$0CF4,$0D02,$0D12,$0D22,$0D33,$0D46; Octave 6 - (C9 - D4)   6
	.dw $0EAC,$0EB7,$0EC2,$0ECD,$0ED9,$0EE6,$0EF4,$0F02,$0F12,$0F22,$0FFF,$0FFF;$0F33,$0F46; Octave 7 - (D5 - E0)   7
.ENDS

;--------------------------------

.SECTION "Volume Envelope Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
VolumeEnvTable:
    .dw PSGEnv01    ; SFX PAUSE
    .dw PSGEnv02    ; SFX COIN
    .dw PSGEnv03    ; SFX 1UP
    .dw PSGEnv04    ; SFX SWIM & STOMP
    .dw PSGEnv05    ; SFX FLAME
    .dw PSGEnv06    ; SFX JUMP
    .dw PSGEnv07    ; MUS 0 (Overworld, Underground, Castle)
    .dw PSGEnv08    ; MUS 1 (Level Victory)
    .dw PSGEnv09    ; MUS 2 (Invincible)
    .dw PSGEnv0A    ; MUS 3 (Game Over, Hurry Up, Underwater, Game Victory)
    .dw PSGEnv0B    ; MUS 4 (Death 0)
    .dw PSGEnv0C    ; MUS 5 (Death 1)
    .dw PSGEnv0D    ; MUS 6 (World Victory)
    .dw PSGEnv0E    ; MUS 7 (Common Triangle)

    .dw PSGEnv0F    ; DRUM 0
    .dw PSGEnv10    ; DRUM 1
.ENDS

.SECTION "Sound PSG Envelope 01 - SFX PAUSE" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv01:
    .db $00, $01, $01, $01, $01, $02, $02, $03, $03, $03, $04, $05, $06, $07, $07, $09
    .db $0C, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 02 - SFX COIN" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv02:
    .db $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02
    .db $02, $02, $02, $02, $02, $03, $03, $03, $03, $03, $03, $03, $04, $04, $04, $05
    .db $05, $05, $05, $06, $06, $06, $07, $07, $07, $07, $09, $09, $09, $0C, $0C, $0C
    .db $0C, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 03 - SFX 1UP" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv03:
    .db $00, $01, $01, $02, $03, $03, $04, $06, $80
.ENDS

.SECTION "Sound PSG Envelope 04 - SFX SWIM" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv04:
    .db $09, $06, $05, $04, $03, $01, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 05 - SFX FLAME" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv05:
    .db $06, $04, $04, $03, $03, $02, $02, $01, $01, $01, $01, $00, $00, $00, $00, $00
    .db $00, $00, $00, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02
    .db $02, $02, $02, $03, $03, $03, $03, $03, $03, $04, $04, $04, $04, $05, $05, $0F
    .db $80
.ENDS

.SECTION "Sound PSG Envelope 06 - SFX JUMP" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv06:
    .db $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $04
    .db $04, $04, $05, $05, $06, $06, $07, $07, $09, $09, $09, $0C, $0C, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 07 - MUSIC 00" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv07:
    .db $0F, $03, $03, $04, $05, $05, $06, $06, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 08 - MUSIC 01" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv08:
    .db $05, $07, $06, $05, $05, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $05, $05, $05, $05, $05, $05, $06, $06, $06, $06
    .db $06, $06, $07, $07, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 09 - MUSIC 02" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv09:
    .db $0F, $03, $03, $04, $05, $05, $06, $06, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0A - MUSIC 03" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv0A:
    .db $05, $07, $06, $05, $05, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $05, $05, $05, $05, $05, $05, $06, $06, $06, $06
    .db $06, $06, $07, $07, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0B - MUSIC 04" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv0B:
    .db $00, $01, $01, $03, $06, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0C - MUSIC 05" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv0C:
    .db $00, $01, $01, $02, $03, $03, $04, $06, $07, $09, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0D - MUSIC 06" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv0D:
    .db $00, $01, $02, $02, $03, $80
.ENDS

.SECTION "Sound PSG Envelope 0E - MUSIC 07" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv0E:
    .db $00, $00, $00, $00, $00, $00, $00, $00, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0F - DRUM 00" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv0F:
    .db $00, $00, $00, $00, $00, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 10 - DRUM 01" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGEnv10:
    .db $00, $0F, $80
.ENDS

;--------------------------------

.SECTION "Sound PSG Drum Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PSGDrumTable:
    .db $E4, $0F    ; NOISE HIGH,   ENVELOPE $0F (5 TICKS)
    .db $E4, $10    ; NOISE HIGH,   ENVELOPE $10 (1 TICK)
    .db $E5, $10    ; NOISE MID,    ENVELOPE $10 (1 TICK)
.ENDS

;--------------------------------

.SECTION "Speed Up Tempo Table (FM)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
SpeedUpTempoTableFM:
    .db TempoFunc($38), TempoFunc($23), TempoFunc($83)
    .db TempoFunc($59)
.IF PALBUILD == $00
    .db TempoFunc($0E)
.ELSE
    .db TempoFunc($87)
.ENDIF
    .db TempoFunc($23), TempoFunc($5F)
    ;
    .db TempoFunc($8B), TempoFunc($8B), TempoFunc($6A)
    .db TempoFunc($AD), TempoFunc($7A), TempoFunc($48), $00
    ;
    .db TempoFunc($66), TempoFunc($66), $00
.ENDS

;--------------------------------

.SECTION "Patch Envelope Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMPatchEnvTable:
    .dw PatchEnv01
    .dw PatchEnv02
    .dw PatchEnv03
    .dw PatchEnv04
    .dw PatchEnv05
    .dw PatchEnv06
    .dw PatchEnv07
    .dw PatchEnv08
    .dw PatchEnv09
    .dw PatchEnv0A
    .dw PatchEnv0B
    .dw PatchEnv0C
    .dw PatchEnv0D
    .dw PatchEnv0E
    .dw PatchEnv0F
    .dw PatchEnv10
    .dw PatchEnv11
    .dw PatchEnv12
    .dw PatchEnv13
    .dw PatchEnv14
    .dw PatchEnv15
    .dw PatchEnv16
    .dw PatchEnv17
    .dw PatchEnv18
    .dw PatchEnv19
    .dw PatchEnv1A
.ENDS

.SECTION "PatchEnv01" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv01:
    .db $04, $05, $80
.ENDS

.SECTION "PatchEnv02" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv02:
    .db $02, $01, $80
.ENDS

.SECTION "PatchEnv03" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv03:
    .db $02, $01, $80
.ENDS

.SECTION "PatchEnv04" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv04:
    .db $0C, $0B, $80
.ENDS

.SECTION "PatchEnv05" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv05:
    .db $0C, $03, $80
.ENDS

.SECTION "PatchEnv06" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv06:
    .db $07, $01, $80
.ENDS

.SECTION "PatchEnv07" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv07:
    .db $07, $01, $80
.ENDS

.SECTION "PatchEnv08" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv08:
    .db $0C, $08, $80
.ENDS

.SECTION "PatchEnv09 (HI-HAT)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv09:
    .db $05, $04, $80
.ENDS

.SECTION "PatchEnv0A (HI-HAT)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv0A:
    .db $05, $04, $80
.ENDS

.SECTION "PatchEnv0B" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv0B:
    .db $07, $03, $80
.ENDS

.SECTION "PatchEnv0C" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv0C:
    .db $09, $08, $80
.ENDS

.SECTION "PatchEnv0D" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv0D:
    ;.db $0E, $02, $80
    .db $0C, $02, $80
.ENDS

.SECTION "PatchEnv0E" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv0E:
    .db $0C, $03, $80
.ENDS

.SECTION "PatchEnv0F (SNARE)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv0F:
    .db $0F, $00, $80
.ENDS

.SECTION "PatchEnv10" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv10:
    .db $04, $07, $80
.ENDS

.SECTION "PatchEnv11" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv11:
    .db $0D, $0A, $80
.ENDS

.SECTION "PatchEnv12 (POWER SNARE)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv12:
    .db $00, $80
.ENDS

.SECTION "PatchEnv13 (KICK)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv13:
    .db $0A, $04, $80 ;$05, $80
.ENDS

.SECTION "PatchEnv14 (CONGA)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv14:
    .db $0C, $05, $80
.ENDS

.SECTION "PatchEnv15 (OVERDRIVEN GUITAR)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv15:
    .db $0B, $04, $80;$0E, $0A, $80
.ENDS

.SECTION "PatchEnv16 (ORCH HIT)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv16:
    .db $00, $80
.ENDS

.SECTION "PatchEnv17 (CLAP?)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv17:
    .db $00, $80
.ENDS

.SECTION "PatchEnv18 (DRUM?)" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv18:
    .db $00, $80
.ENDS

.SECTION "PatchEnv19" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv19:
    .db $00, $80
.ENDS

.SECTION "PatchEnv1A" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
PatchEnv1A:
    .db $00, $80
.ENDS

;--------------------------------

.SECTION "FM Volume Envelope Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolumeEnvTable:
    .dw FMVolEnv01  ; OVERWORLD (IDX)
    .dw FMVolEnv02  ; OVERWORLD (IDX)
    .dw FMVolEnv03  ; KICK
    .dw FMVolEnv04  ; CLOSED HIHAT
    .dw FMVolEnv05  ; OPEN HIHAT
    .dw FMVolEnv06  ; FADE IN (CASTLE)
    .dw FMVolEnv07  ;
    .dw FMVolEnv08  ; PIANO
    .dw FMVolEnv09  ; BOWSER FADE IN
    .dw FMVolEnv0A  ; BOWSER FADE OUT
    .dw FMVolEnv0B  ; CASTLE 3 DUR
.ENDS

.SECTION "FMVolEnv01" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv01:
    .db $03, $01, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02, $02
    .db $02, $02, $02, $02, $02, $02, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
    .db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
    .db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $05, $05, $05
    .db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05
    .db $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $05, $06, $06, $06, $06, $06
    .db $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $06
    .db $06, $06, $06, $06, $06, $06, $06, $06, $06, $06, $07, $07, $07, $07, $07, $07
    .db $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07, $07
    .db $07, $07, $07, $07, $07, $07, $07, $07, $08, $08, $08, $08, $08, $08, $08, $08
    .db $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $08, $09, $09
    .db $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $09, $0A, $0A, $0A
    .db $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0A, $0B, $0B, $0B, $0B, $0B, $0B, $0B, $0B
    .db $0C, $0C, $0C, $0C, $0C, $0D, $0D, $0D, $0D, $0E, $0E, $0E, $0F, $80
.ENDS

.SECTION "FMVolEnv02" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv02:
    .db $00, $00, $00, $00, $00, $00, $01, $01, $01, $02, $02, $03, $03, $04, $04, $05
    .db $05, $06, $07, $08, $0C, $0F, $80
.ENDS

.SECTION "FMVolEnv03" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv03:
    .db $00, $00, $00, $00, $00, //$00, $00, $00, $00, 
    .db $03, $06, $09, $0C, $0F, $80
.ENDS

.SECTION "FMVolEnv04" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv04:
    .db $00, $03, $09, $0C, $0F, $80
.ENDS

.SECTION "FMVolEnv05" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv05:
    .db $00, $01, $03, $05, $09, $0C, $0F, $80
.ENDS

.SECTION "FMVolEnv06" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv06:
    .db $04, $04, $02, $02, $00, $80
.ENDS

.SECTION "FMVolEnv07" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv07:
    .db $00, $00, $01, $01, $01, $02, $02, $02, $02, $03, $03, $03, $04, $80
.ENDS

.SECTION "FMVolEnv08" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv08:
    .db $00, $01, $01, $02, $02, $02, $02, $02, $03, $03, $03, $03, $04, $04, $04, $04
    .db $04, $04, $06, $80
.ENDS

.SECTION "FMVolEnv09" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv09:
    .db $04, $04, $04, $04, $04, $03, $03, $03, $03, $03, $02, $02, $02, $02, $02, $01
    .db $01, $01, $01, $01, $00, $80
.ENDS

.SECTION "FMVolEnv0A" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv0A:
    .db $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02, $03
    .db $03, $03, $03, $03, $04, $80
.ENDS

.SECTION "FMVolEnv0B" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMVolEnv0B:
    .db $00, $00, $80
.ENDS

;--------------------------------

.SECTION "Custom Instrument Table" BANK BANK_CODE SLOT 0 FREE BITWINDOW 8 RETURNORG
FMInstrumentTable:
    .db $0F, $08, $00, $07, $F1, $F7, $1F, $FF  ; SNARE
    .db $06, $04, $1E, $0F, $F9, $F8, $FF, $FF  ; CONGA
    .db $01, $00, $40, $18, $F8, $F0, $26, $05  ; TIMPANI
    .db $37, $34, $28, $05, $F1, $F2, $85, $65  ; GLOCKENSPIEL (CASTLE, ENDING)
    .db $37, $34, $28, $05, $F1, $A2, $85, $65  ; GLOCKENSPIEL (WATER)
.ENDS