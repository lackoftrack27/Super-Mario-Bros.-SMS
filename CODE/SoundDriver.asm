;   CHANNEL CONTROL BITS
.DEFINE CHANCON_REST        1
.DEFINE CHANCON_SFX         2
.DEFINE CHANCON_MOD         3
.DEFINE CHANCON_NOATK       4
.DEFINE CHANCON_DRUMMODE    5
.DEFINE CHANCON_PLAYING     7

;   REGISTER BITS
.DEFINE OP_BIT      $04     ; 0 - FREQUENCY, 1 - VOLUME
.DEFINE CHAN_BIT0   $05
.DEFINE CHAN_BIT1   $06
.DEFINE LATCH_BIT   $07

;   PSG CHANNEL BITS
.DEFINE CHAN0_BITS  $00
.DEFINE CHAN1_BITS  $01 << CHAN_BIT0
.DEFINE CHAN2_BITS  $01 << CHAN_BIT1
.DEFINE CHAN3_BITS  ($01 << CHAN_BIT0) | ($01 << CHAN_BIT1)
.DEFINE CHANALL_BITS    CHAN3_BITS
.DEFINE LATCH_VOL   ($01 << OP_BIT) | ($01 << LATCH_BIT)


;   PSG NOISE TYPES
.DEFINE NOISE_TONE0 $00
.DEFINE NOISE_TONE1 $01
.DEFINE NOISE_TONE2 $02
.DEFINE NOISE_PULSE $03

;   COUNTS
.DEFINE TRACK_COUNT $07 ; 4 MUSIC, 3 SFX
.DEFINE CHAN_COUNT  $04

;   STARTING COORDINATION FLAG ID
.DEFINE CF_START    $E0

;-------------------------------------------------------------------------------------

SoundEngine:
;   SILENCE CHANNELS IF IN TITLE SCREEN MODE
    LD A, (OperMode)
    OR A
    JP Z, SndStopAll@WritePSG
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
    ; UPDATE ONLY SFX TRACK 0 FOR PAUSE SFX
    LD A, BANK_SOUND
    LD (MAPPER_SLOT2), A
    LD H, >SFXTrack0
    CALL SndChannelProcessSFXTone
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    XOR A
    LD (SFXTrack0.SoundQueue), A
    ; STOP HERE IF GAME IS PAUSED
    LD A, (GamePauseStatus)
    RRA
    RET C
    ; CHECK IF PAUSE SFX HAS FINISHED PLAYING
    LD A, (SFXTrack0.Control)
    AND A, $01 << CHANCON_PLAYING
    RET NZ
    ; CLEAR SOUND FLAG (NORMAL OPERATION WILL RESUME)
    XOR A
    LD (SndPauseFlag), A
    RET

RunSoundSubroutines:
    LD A, BANK_SOUND
    LD (MAPPER_SLOT2), A
;   SFX UPDATE
    ; SFX TRACK 0
    LD H, >SFXTrack0
    CALL SndChannelProcessSFXTone
    ; SFX TRACK 1
    LD H, >SFXTrack1
    CALL SndChannelProcessSFXTone
    ; SFX TRACK 2
    LD H, >SFXTrack2
    CALL SndChannelProcessSFXTone
;   MUSIC UPDATE
    CALL SndChannelProcessMUS
    XOR A
    LD (MusicTrack0.SoundQueue), A
    ; TEMPO WAIT (ONLY FOR MUSIC)
    LD A, (SndCurrentTempo)
    LD HL, SndTempoTimeout
    ADD A, (HL)
    LD (HL), A
    JP NC, SkipSoundRoutines
    LD HL, MusicTrack0.Duration
    INC (HL)
    INC H
    INC (HL)
    INC H
    INC (HL)
    INC H
    INC (HL)
;
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
    LD DE, _sizeof_SndTrack
-:
    LD (HL), A
    ADD HL, DE
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

SndInitMemory:
;   TRACK MEMORY
    LD H, >MusicTrack0
    LD C, $07   ; 4 MUSIC, 3 SFX
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
;   GLOBAL MEMORY
    LD HL, SndTempoTimeout
    LD B, $08
-:
    LD (HL), A
    INC L
    DJNZ -
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
    RET

;-------------------------------------------------------------------------------------

.SECTION "Sound Driver Code in Sound Bank" BANK BANK_SOUND SLOT 2 FREE

SndChannelProcessSFXTone:
;   PROCESS QUEUE IF IT ISN'T EMPTY
    LD L, <SFXTrack0.SoundQueue
    LD A, (HL)
    OR A
    CALL NZ, SndProcessQueueSFX
;   TRACK PLAYING CHECK
    LD L, <SFXTrack0.Control
    BIT CHANCON_PLAYING, (HL)
    RET Z
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
    JP SndWriteChannelData@UpdateEnvelope
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
    LD HL, MusicTrack0.SoundQueue
    LD A, (HL)
    OR A
    CALL NZ, SndProcessQueueMusic
;   CHECK SECONDARY QUEUE (FOR HURRY UP)
    LD HL, MusicTrack0.Control
    BIT CHANCON_PLAYING, (HL)
    JP NZ, +
    LD HL, MusicTrack1.SoundQueue
    LD A, (HL)
    DEC H
    OR A
    CALL NZ, SndProcessQueueMusic
    XOR A
    LD (MusicTrack1.SoundQueue), A
+:
;   TRACK 0 (NEVER INTERRUPTED BY SFX)
    LD HL, MusicTrack0.Control
    BIT CHANCON_PLAYING, (HL)
    CALL NZ, SndChannelProcessSFXTone@TrackUpdate
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
    JP SndWriteChannelData@UpdateEnvelope
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
    INC L           ; SoundPlaying
    LD (HL), A
    SUB A, $81
    ADD A, A
;
    LD L, <SFXTrack0.Control
    LD (HL), $01 << CHANCON_PLAYING
    INC L
    EX DE, HL       ; DE - TRACK RAM, HL - TRACK DATA
    LD HL, SndIndexTable
    addAToHL_M
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
    EX DE, HL
    XOR A
    LD (HL), A      ; SavedDuration
    INC L
    LD (HL), A      ; Detune
    INC L
    LD (HL), $01    ; Duration
;   SET SFX OVERRIDE BIT ON MUSIC TRACK THAT SHARES CHANNEL
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
    INC L           ; SoundPlaying
    LD (HL), A
    SUB A, $81    
    ADD A, A
;
    EX DE, HL       ; DE - TRACK RAM, HL - TRACK DATA
    LD HL, SndIndexTable
    addAToHL_M
;
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
;
    INC HL          ; UNUSED (FM VOICE)
    INC HL          ; UNUSED (FM VOICE)
    INC HL          ; UNUSED
    INC HL          ; CHANNEL COUNT
    INC HL          ; TICK MULTIPLIER
;   SETUP TEMPO
    XOR A
    LD (SndTempoTimeout), A
    /*
    LD E, <MusicTrack0.SoundPlaying
    LD A, (DE)
    SUB A, SNDID_WATER
    LD BC, SpeedUpTempoTable
    addAToBC8_M
    */
    LD A, (SndHurryUpFlag)
    OR A
    LD A, (HL)
    JP Z, +
    XOR A ;LD A, (BC)
+:
    LD (SndCurrentTempo), A
    INC HL
;   LOOP START
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
;   SET SFX OVERRIDE FLAG IF SFX IS PLAYING ON THE SAME CHANNEL
    LD E, <SFXTrack0.Control
    LD A, D
    CP A, >MusicTrack0
    LD A, $01 << CHANCON_PLAYING 
    JP Z, +
    INC D
    INC D
    INC D
    LD A, (DE)
    DEC D
    DEC D
    DEC D
    RLCA
    LD A, $01 << CHANCON_PLAYING
    JP NC, +
    LD A, $01 << CHANCON_PLAYING | $01 << CHANCON_SFX
+:
    LD (DE), A
    INC E
    INC D           ; Point to next music track
    DJNZ @ChanSetupLoop
    EX DE, HL
    RET

;--------------------------------

SndReadTrackStream:
;   CLEAR 'NO ATTACK' FLAG && REST FLAG
    LD L, <SFXTrack0.Control
    LD A, (HL)
    AND A, ~($01 << CHANCON_NOATK | $01 << CHANCON_REST)
    LD (HL), A
;   GET TRACK POINTER
    INC L
    LD C, (HL)
    INC L
    LD B, (HL)
;   START OF TRACK READ LOOP
@SndReadLoop:
    ; GET NEXT BYTE
    LD A, (BC)
    INC BC
    ; CHECK IF BYTE IS COORDINATION FLAG
    CP A, CF_START
    JP NC, SndProcessCF
;   END OF TRACK READ LOOP
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
;   RETURN IF 'NO ATTACK' FLAG IS SET
    LD L, <SFXTrack0.Control
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
    LD DE, SndFreqTable
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
;   SET REST FLAG AND INVALIDATE FREQUENCIES
    LD L, <SFXTrack0.Control
    SET CHANCON_REST, (HL)
;   SILENCE CHANNEL
    JP SndStopChannel@SilenceChan
@SetNoiseFreq:
    EX AF, AF'
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
    OR A, $01 << LATCH_BIT
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

@UpdateEnvelope:
;   SAVE CHANNEL VOLUME IN B
    LD L, <SFXTrack0.Volume
    LD B, (HL)
;   CHECK IF TRACK IS USING AN ENVELOPE. IF NOT, SKIP ENVELOPE UPDATE 
    LD L, <SFXTrack0.Envelope
    LD A, (HL)
    OR A
    JP Z, @SndUpdateVolume
;   GET TABLE OF ENVELOPE AND ADD CURRENT INDEX
    EX DE, HL   ; DE - TRACK RAM, HL - N/A
    LD HL, PSGIndexTable
    DEC A
    ADD A, A
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    DEC E       ; EnvelopeIndex
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
    JP C, @SndUpdateVolume
    LD B, $0F
@SndUpdateVolume:
;   ONLY SEND VOLUME IF TRACK ISN'T OVERRIDDEN BY SFX
    LD L, <SFXTrack0.Control
    BIT CHANCON_SFX, (HL)
    RET NZ
+:
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


;-------------------------------------------------------------------------------------

;   HL - TRACK RAM, BC - TRACK DATA POINTER
SndProcessCF:
;   PUSH RETURN ADDRESS
    LD DE, CoordFlagTable@return
    PUSH DE
;   CONVERT FLAG INTO OFFSET
    SUB A, CF_START
    LD E, A
    ADD A, A
    ADD A, E
;   ADD TO TABLE
    LD IX, CoordFlagTable
    addAToIX_M
    LD A, (BC)
    JP (IX)

CoordFlagTable:
    JP @return              ; $E0 (AMS/FMS/PANNING)
    JP @cfDetune            ; $E1 (DETUNE)
    JP @return              ; $E2 (SET COMMUNICATION)
    JP @return              ; $E3 (CALL RETURN)
    JP @return              ; $E4 (FADE IN)
    JP @return              ; $E5 (SET TEMPO DIVIDER SINGLE)
    JP @return              ; $E6 (CHANGE FM VOL)
    JP @cfNoAtk             ; $E7 (NO ATTACK NOTE)
    JP @return              ; $E8 (NOTE TIMEOUT)
    JP @return              ; $E9 (CHANGE TRANSPOSITION)
    JP @return              ; $EA (SET TEMPO)
    JP @return              ; $EB (SET TEMPO DIVIDER ALL)
    JP @cfChangePSGVol      ; $EC (CHANGE PSG VOL)
    JP @cfDrumMode          ; $ED (CH4 DRUM MODE)
    JP @return              ; $EE (READ LITERAL MODE)
    JP @return              ; $EF (SET FM VOICE)
    JP @cfModSetup          ; $F0 (MODULATION SETUP/ON)
    JP @cfModOn             ; $F1 (MODULATION ON)
    JP @cfStopTrack         ; $F2 (STOP TRACK)
    JP @return              ; $F3 (SET PSG NOISE)
    JP @cfModOff            ; $F4 (MODULATION OFF)
    JP @cfSetEnvelope       ; $F5 (SET PSG ENVELOPE)
    JP @cfJumpTo            ; $F6 (JUMP TO)
    JP @return              ; $F7 (LOOP SECTION)
    JP @return              ; $F8 (CALL)


@return:
    ; ADVANCE TRACK POINTER AND CONTINUE READING IT
    INC BC
    JP SndReadTrackStream@SndReadLoop
;   ---------------------------------------------
;   E1 - CHANGE DETUNE
@cfDetune:
    ; SET DETUNE
    LD L, <SFXTrack0.Detune
    LD (HL), A
    RET
;   ---------------------------------------------
;   E7 - SET NO ATTACK FLAG
@cfNoAtk:
    DEC BC  ; NO PARAMETER BYTES
    LD L, <SFXTrack0.Control
    SET CHANCON_NOATK, (HL)
    RET
;   ---------------------------------------------
;   EC - VOLUME CHANGE
@cfChangePSGVol:
    ; SET VOLUME
    LD L, <SFXTrack0.Volume
    ADD A, (HL)
    LD (HL), A
    RET
;   ED - CH4 DRUM MODE
@cfDrumMode:
    DEC BC  ; NO PARAMETER BYTES
    LD L, <SFXTrack0.Control
    SET CHANCON_DRUMMODE, (HL)
    RET
;   ---------------------------------------------
;   F0 - MODULATION SETUP + ON
@cfModSetup:
    LD L, <SFXTrack0.Control
    SET CHANCON_MOD, (HL)
    LD L, <SFXTrack0.ModPointer
    LD (HL), C
    INC L
    LD (HL), B
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
    LD L, <SFXTrack0.Control
    SET CHANCON_MOD, (HL)
    RET
;   ---------------------------------------------
;   F2 - STOP
@cfStopTrack:
    LD L, <SFXTrack0.Control
    ; CLEAR SFX OVERRIDE BIT ON MUSIC TRACK IF CURRENTLY PROCESSING A SFX TRACK
    LD A, H
    CP A, >SFXTrack0
    JP C, +
    DEC H
    DEC H
    DEC H
    RES CHANCON_SFX, (HL)
    SET CHANCON_REST, (HL)
    INC H
    INC H
    INC H
+:
    ; CLEAR NO ATTACK BIT && PLAYING BIT    
    LD A, (HL)
    AND A, ~($01 << CHANCON_NOATK | $01 << CHANCON_PLAYING)
    LD (HL), A
    ; CLEAR SOUND ID
    LD L, <SFXTrack0.SoundPlaying
    LD (HL), $00
    ; SILENCE CHANNEL
    CALL SndStopChannel@SilenceChan
    ; REMOVE CALLERS (EXIT OUT OF SndChannelProcessXXXX)
    POP DE  ; CF RETURN CALLER
    POP DE  ; READ STREAM CALLER
    RET
;   ---------------------------------------------
;   F1 - MODULATION OFF
@cfModOff:
    DEC BC  ; NO PARAMETER BYTES
    LD L, <SFXTrack0.Control
    RES CHANCON_MOD, (HL)
    RET
;   ---------------------------------------------
;   F5 - SET PSG ENVELOPE
@cfSetEnvelope:
    LD L, <SFXTrack0.Envelope
    LD (HL), A
    RET
;   ---------------------------------------------
;   F6 - JUMP TO ADDRESS
@cfJumpTo:
    ; SET TRACK POINTER TO GIVEN ADDRESS
    LD E, A
    INC BC
    LD A, (BC)
    LD C, E
    LD B, A
    DEC BC
    RET

;-------------------------------------------------------------------------------------

SndStopChannel:
@SilenceChan:
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

.ENDS

;-------------------------------------------------------------------------------------

.SECTION "Sound Index Table" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
SndIndexTable:
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

    .dw Mus_Water       ; WATER
    .dw Mus_Overworld
    .dw Mus_Underground ; UNDERGROUND
    .dw Mus_Castle      ; CASTLE
    .dw Mus_Cloud       ; CLOUD
    .dw Mus_PipeIntro   ; PIPE INTRO
    .dw Mus_Invincible  ; INVINCIBLE

    .dw Mus_HurryUp     ; TIME RUNNING OUT    
    .dw Mus_LevelVictory; LEVEL VICTORY
    .dw Mus_WorldVictory; CASTLE VICTORY
    .dw Mus_GameVictory ; PRINCESS SAVED
    .dw Mus_GameOver    ; GAME OVER
    .dw Mus_Death       ; DEATH
    .dw Mus_Silence     ; SILENCE
.ENDS

.SECTION "Sound PSG Frequency Table" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
SndFreqTable:
;         C     C#    D     Eb    E     F     F#    G     G#    A     Bb    B
    .dw $03FF,$03FF,$03FF,$03FF,$03FF,$03FF,$03FF,$03FF,$03FF,$03F9,$03C0,$038A; Octave 2 - (81 - 8C)   0
	.dw $0357,$0327,$02FA,$02CF,$02A7,$0281,$025D,$023B,$021B,$01FC,$01E0,$01C5; Octave 3 - (8D - 98)   1
	.dw $01AC,$0194,$017D,$0168,$0153,$0140,$012E,$011D,$010D,$00FE,$00F0,$00E2; Octave 4 - (99 - A4)   2
	.dw $00D6,$00CA,$00BE,$00B4,$00AA,$00A0,$0097,$008F,$0087,$007F,$0078,$0071; Octave 5 - (A5 - B0)   3
	.dw $006B,$0065,$005F,$005A,$0055,$0050,$004C,$0047,$0043,$0040,$003C,$0039; Octave 6 - (B1 - BC)   4
	.dw $0035,$0032,$0030,$002D,$002A,$0028,$0026,$0024,$0022,$0020,$001E,$001C; Octave 7 - (BD - C8)   5
	.dw $001B,$0019,$0018,$0016,$0015,$0014,$0013,$0012,$0011,$0010,$000F,$000E; Octave 8 - (C9 - D4)   6
	.dw $000D,$000D,$000C,$000B,$000B,$000A,$0009,$0009,$0008,$0008,$0007,$0007; Octave 9 - (D5 - E0)   7
    .dw $0000								                                   ; Note (E1)
.ENDS

.SECTION "Sound PSG Envelope Table" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGIndexTable:
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

.SECTION "Sound PSG Envelope 01 - SFX PAUSE" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv01:
    .db $00, $01, $01, $01, $01, $02, $02, $03, $03, $03, $04, $05, $06, $07, $07, $09
    .db $0C, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 02 - SFX COIN" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv02:
    .db $00, $00, $00, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $01, $02, $02
    .db $02, $02, $02, $02, $02, $03, $03, $03, $03, $03, $03, $03, $04, $04, $04, $05
    .db $05, $05, $05, $06, $06, $06, $07, $07, $07, $07, $09, $09, $09, $0C, $0C, $0C
    .db $0C, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 03 - SFX 1UP" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv03:
    .db $00, $01, $01, $02, $03, $03, $04, $06, $80
.ENDS

.SECTION "Sound PSG Envelope 04 - SFX SWIM" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv04:
    .db $09, $06, $05, $04, $03, $01, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 05 - SFX FLAME" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv05:
    .db $06, $04, $04, $03, $03, $02, $02, $01, $01, $01, $01, $00, $00, $00, $00, $00
    .db $00, $00, $00, $01, $01, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $01, $01, $01, $01, $01, $01, $02, $02, $02, $02, $02
    .db $02, $02, $02, $03, $03, $03, $03, $03, $03, $04, $04, $04, $04, $05, $05, $0F
    .db $80
.ENDS

.SECTION "Sound PSG Envelope 06 - SFX JUMP" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv06:
    .db $00, $01, $01, $00, $00, $00, $00, $00, $00, $00, $00, $03, $03, $03, $03, $04
    .db $04, $04, $05, $05, $06, $06, $07, $07, $09, $09, $09, $0C, $0C, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 07 - MUSIC 00" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv07:
    .db $0F, $03, $03, $04, $05, $05, $06, $06, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 08 - MUSIC 01" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv08:
    .db $05, $07, $06, $05, $05, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $05, $05, $05, $05, $05, $05, $06, $06, $06, $06
    .db $06, $06, $07, $07, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 09 - MUSIC 02" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv09:
    .db $0F, $03, $03, $04, $05, $05, $06, $06, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0A - MUSIC 03" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv0A:
    .db $05, $07, $06, $05, $05, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $04, $04, $04, $05, $05, $05, $05, $05, $05, $06, $06, $06, $06
    .db $06, $06, $07, $07, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0B - MUSIC 04" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv0B:
    .db $00, $01, $01, $03, $06, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0C - MUSIC 05" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv0C:
    .db $00, $01, $01, $02, $03, $03, $04, $06, $07, $09, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0D - MUSIC 06" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv0D:
    .db $00, $01, $02, $02, $03, $80
.ENDS

.SECTION "Sound PSG Envelope 0E - MUSIC 07" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv0E:
    .db $00, $00, $00, $00, $00, $00, $00, $00, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 0F - DRUM 00" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv0F:
    .db $00, $00, $00, $00, $00, $0F, $80
.ENDS

.SECTION "Sound PSG Envelope 10 - DRUM 01" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGEnv10:
    .db $00, $0F, $80
.ENDS

.SECTION "Sound PSG Drum Table" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
PSGDrumTable:
    .db $E4, $0F    ; NOISE HIGH,   ENVELOPE $0F (5 TICKS)
    .db $E4, $10    ; NOISE HIGH,   ENVELOPE $10 (1 TICK)
    .db $E5, $10    ; NOISE MID,    ENVELOPE $10 (1 TICK)
.ENDS

/*
.SECTION "Speed Up Tempo Table" BANK BANK_SOUND SLOT 2 FREE BITWINDOW 8
SpeedUpTempoTable:
    .db $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $00, $00
.ENDS
*/