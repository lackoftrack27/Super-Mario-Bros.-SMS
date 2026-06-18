; -----------------------------------------------------------
;                   FM MUSIC DATA (NSTC)
; -----------------------------------------------------------

.SECTION "MUS Data - Hurry Up (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_HurryUp_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $16
    smpsChanHeader  Mus_HurryUp_FM@ch0,  $00, $00, $00, $00
    smpsChanHeader  Mus_HurryUp_FM@ch0,  $FA, $00, $00, $00
    smpsChanHeader  Mus_HurryUp_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_HurryUp_FM@ch2,  $FA, $02, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00

;   --- CHANNEL 2/3 DATA ---
@ch2:
    smpsDetune $01
    ; FALL THROUGH

;   --- CHANNEL 0/1 DATA ---
@ch0:
    smpsFMVoice $01
    .db nB4, $04, nRst, $02, nGs5, $04, nRst, $02
    smpsChangeVol $07
    .db nGs5, $04, nRst, $02
    smpsChangeVol $F9
    .db nGs5, $04, nRst, $02, nGs5, $0A, nRst, $02, nC5, $04, nRst, $02, nA5, $04, nRst, $02
    smpsChangeVol $07
    .db nA5, $04, nRst, $02
    smpsChangeVol $F9
    .db nA5, $04, nRst, $02, nA5, $0A, nRst, $02, nBb5, $04, nRst, $02
    smpsChangeVol $07
    .db nBb5, $04, nRst, $02
    smpsChangeVol $F9
    .db nBb5, $18
    smpsStop
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Game Victory (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_GameVictory_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $AD
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_GameVictory_FM@ch0,  $00, $00, $00, $00
    smpsChanHeader  Mus_GameVictory_FM@ch1,  $00, $00, $00, $00
    smpsChanHeader  Mus_GameVictory_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_GameVictory_FM@ch3,  $00, $02, $00, $00
    smpsChanHeader  Mus_GameVictory_FM@ch4,  $00, $02, $00, $00
    smpsChanHeader  Mus_GameVictory_FM@ch5,  $00, $05, $00, $00
    smpsChanHeader  Mus_GameVictory_FM@ch6,  $00, $04, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00

;   --- CHANNEL 6 (0) DATA ---
@ch6:
    smpsDetune $01
    .db nRst, $03
    ; FALL THROUGH

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsFMVoice $01
@ch0LoopPoint:
    smpsCall    Mus_GameVictory_FM@ch0Call1
    smpsCall    Mus_GameVictory_FM@ch0Call1
    smpsCall    Mus_GameVictory_FM@ch0Call2
    smpsCall    Mus_GameVictory_FM@ch0Call1
    smpsJump    Mus_GameVictory_FM@ch0LoopPoint
;   CHANNEL 0 SUBROUTINES
@ch0Call1:
    .db nG4, $03, nRst, $01, nFs4, $03, nRst, $01, nG4, $03, nRst, $01, nE4, $15, nRst, $03
    .db nF4, $0A, nRst, $02, nFs4, $0A, nRst, $02, nG4, $15, nRst, $03, nC5, $0A, nRst, $02
    .db nE5, $07, nRst, $01, nE5, $03, nRst, $01, nD5, $0A, nRst, $02, nE5, $0A, nRst, $02
    .db nF5, $0A, nRst, $02, nB4, $0A, nRst, $02, nD5, $15, nRst, $03, nC5, $0A, nRst, $02
    ;.db nF5, $0A, nRst, $02, nB4, $0A, nRst, $02, nD5, $18, nC5, $0A, nRst, $02
    smpsRet

@ch0Call2:
    .db nE5, $07
    .db nRst, $01, nE5, $03, nRst, $01, nE5, $15, nRst, $03, nB4, $0F, nRst, $03, nD5, $05
    .db nRst, $01, nD5, $0E, nRst, $02, nC5, $03, nRst, $01, nB4, $03, nRst, $01, nC5, $0A
    .db nRst, $02, nF5, $07, nRst, $01, nF5, $03, nRst, $01, nF5, $15, nRst, $03, nC5, $0F
    .db nRst, $03, nD5, $05, nRst, $01, nE5, $15, nRst, $03, nD5, $0A, nRst, $02
    smpsRet

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $01
@ch1LoopPoint:
    .db nB1, $0A, nRst, $02
    smpsCall    Mus_GameVictory_FM@ch1Call1
    .db $0C
    ;
    smpsCall    Mus_GameVictory_FM@ch1Call1
    .db $0C
    ;
    .db nE2, $05, nRst, $01, nEb2, $05, nRst, $01, nE2, $05, nRst, $01
    .db nFs2, $05, nRst, $01, nGs2, $05, nRst, $01, nA2, $05, nRst, $01, nB2, $05, nRst, $01
    .db nGs2, $05, nRst, $01, nA2, $05, nRst, $01, nE2, $05, nRst, $01, nA2, $05, nRst, $01
    .db nGs2, $05, nRst, $01, nA2, $05, nRst, $01, nG2, $05, nRst, $01, nF2, $05, nRst, $01
    .db nE2, $05, nRst, $01, nF2, $05, nRst, $01, nE2, $05, nRst, $01, nD2, $05, nRst, $01
    .db nE2, $05, nRst, $01, nF2, $05, nRst, $01, nG2, $05, nRst, $01, nGs2, $05, nRst, $01
    .db nF2, $05, nRst, $01, nG2, $05, nRst, $01, nFs2, $05, nRst, $01, nG2, $05, nRst, $01
    .db nD2, $05, nRst, $01, nG2, $05, nRst, $01, nF2, $05, nRst, $01, nE2, $05, nRst, $01
    .db nD2, $05, nRst, $01
    ;
    smpsCall    Mus_GameVictory_FM@ch1Call1
    smpsJump    Mus_GameVictory_FM@ch1LoopPoint
;   CHANNEL 1 SUBROUTINES
@ch1Call1:
    .db nC2, $15, nRst, $03, nD2, $0A, nRst, $02, nEb2, $0A, nRst, $02, nE2, $0A, nRst, $02
    .db nC2, $0A, nRst, $02, nA2, $0A, nRst, $02, nG2, $0A, nRst, $02, nF2, $0A, nRst, $02
    .db nE2, $0A, nRst, $02, nD2, $0A, nRst, $02, nF2, $0A, nRst, $02, nG2, $0A, nRst, $02
    .db nG1, $0A, nRst, $02, nC2, $0A, nRst, $02
    smpsRet

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsFMVoice $01
@ch2LoopPoint:
    smpsCall    Mus_GameVictory_FM@ch2Call1
    .db nB4, $15, nRst, $03, nG4, $0A, nRst, $02
    ;
    smpsCall    Mus_GameVictory_FM@ch2Call1
    .db nB4, $15, nRst, $03, nG4, $0A, nRst, $02
    ;
    .db nG4, $07, nRst, $01, nG4, $03, nRst, $01, nB4, $15, nRst, $03, nF4, $0F
    .db nRst, $03, nGs4, $05, nRst, $01, nB4, $0E, nRst, $02, nB4, $03, nRst, $01, nF4, $03
    .db nRst, $01, nA4, $0A, nRst, $02, nC5, $07, nRst, $01, nC5, $03, nRst, $01, nC5, $15
    .db nRst, $03, nC5, $0F, nRst, $03, nB4, $05, nRst, $01, nC5, $15, nRst, $03, nB4, $0A
    .db nRst, $02
    ;
    smpsCall    Mus_GameVictory_FM@ch2Call1
    .db nB3, $15, nRst, $03, nG3, $0A, nRst, $02
    smpsJump    Mus_GameVictory_FM@ch2LoopPoint
;   CHANNEL 2 SUBROUTINES
@ch2Call1:
    .db nRst, $0C, nC4, $15, nRst, $03, nD4, $0A, nRst, $02, nEb4, $0A, nRst, $02, nE4, $15
    .db nRst, $03, nA4, $0A, nRst, $02, nC4, $0A, nRst, $02, nC5, $0A, nRst, $02, nC5, $0A
    .db nRst, $02, nD5, $0A, nRst, $02, nG4, $0A, nRst, $02
    smpsRet

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsFMVoice $01
@ch3LoopPoint:
    .db nRst, $0C
    smpsCall    Mus_GameVictory_FM@ch3Call1
    ;
    .db nRst, $0C
    smpsCall    Mus_GameVictory_FM@ch3Call1
    ;
    .db nG4, $07, nRst, $01, nG4, $03, nRst, $01, nGs4, $15, nRst, $03, nD4, $0F
    .db nRst, $03, nF4, $05, nRst, $01, nF4, $0E, nRst, $02, nE4, $03, nRst, $01, nD4, $03
    .db nRst, $01, nE4, $0A, nRst, $02, nA4, $07, nRst, $01, nA4, $03, nRst, $01, nA4, $15
    .db nRst, $03, nGs4, $15, nRst, $03, nG4, $15, nRst, $03, nF4, $0A, nRst, $02
    ;
    .db nB3, $0A, nRst, $02
    smpsCall    Mus_GameVictory_FM@ch3Call1
    smpsJump    Mus_GameVictory_FM@ch3LoopPoint
;   CHANNEL 3 SUBROUTINES
@ch3Call1:
    .db nB3, $15, nRst, $03, nC4, $0A, nRst, $02, nCs4, $0A, nRst, $02, nD4, $15
    .db nRst, $03, nG4, $0A, nRst, $02, nB4, $0A, nRst, $02, nA4, $0A, nRst, $02, nB4, $0A
    .db nRst, $02, nC5, $0A, nRst, $02, nF4, $0A, nRst, $02, nG4, $15, nRst, $03, nG4, $0A
    .db nRst, $02
    smpsRet

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsFMVoice $01
@ch4LoopPoint:
    smpsCall    Mus_GameVictory_FM@ch4Call1
    ;
    smpsCall    Mus_GameVictory_FM@ch4Call1
    ;
    .db nE4, $07, nRst, $01, nE4, $03, nRst, $7F, $36
    ;
    smpsCall    Mus_GameVictory_FM@ch4Call1
    smpsJump    Mus_GameVictory_FM@ch4LoopPoint
;   CHANNEL 4 SUBROUTINES
@ch4Call1:
    .db nRst, $0C, nG3, $15, nRst, $03, nA3, $0A, nRst, $02, nBb3, $0A, nRst, $02, nB3, $15
    .db nRst, $03, nE4, $0A, nRst, $02, nG4, $0A, nRst, $02, nF4, $0A, nRst, $02, nG4, $0A
    .db nRst, $02, nA4, $0A, nRst, $02, nD4, $0A, nRst, $02, nF4, $15, nRst, $03, nE4, $0A
    .db nRst, $02
    smpsRet

;   --- CHANNEL 5 (0) DATA ---
@ch5:
    smpsDetune $01
    smpsFMVoice $13 ; UPLOAD CUSTOM INSTRUMENT
@ch5LoopPoint:
    .db nRst, $7F, $7F, $7F, $03
    smpsCall    Mus_GameVictory_FM@ch0Call2
    .db nRst, $7F, $41
    smpsJump    Mus_GameVictory_FM@ch5LoopPoint
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Underwater (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Water_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $62
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Water_FM@ch0,  $00, $02, $00, $00
    smpsChanHeader  Mus_Water_FM@ch1,  $00, $02, $00, $00
    smpsChanHeader  Mus_Water_FM@ch2,  $00, $01, $00, $00
    smpsChanHeader  Mus_Water_FM@ch3,  $00, $03, $00, $00
    smpsChanHeader  Mus_Water_FM@ch4,  $00, $04, $00, $00
    smpsChanHeader  Mus_Water_FM@ch5,  $00, $06, $00, $00
    smpsChanHeader  Mus_Water_FM@ch6,  $00, $03, $00, $00
    smpsChanHeader  Mus_Water_FM@ch7,  $00, $03, $00, $00
    ;smpsChanHeader  Mus_Water_FM@ch8,  $00, $05, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsFMVoice $14 ; UPLOAD CUSTOM INSTRUMENT
    smpsModSetup    $10, $01, $FF, $03
    smpsCall    Mus_Water_FM@ch0Call1
@ch0LoopPoint:
    smpsFMVoice $00
    smpsCall    Mus_Water_FM@ch0Call2
    ;
    smpsFMVoice $01
    smpsChangeVol $FF
    smpsCall    Mus_Water_FM@ch0Call3
    .db nRst, $05
    smpsChangeVol $01
    smpsJump    Mus_Water_FM@ch0LoopPoint
;   CHANNEL 0 SUBROUTINES
@ch0Call1:
    .db nD3, $0A, nRst, $02, nE3, $0A, nRst, $02, nFs3, $0A, nRst, $02, nG3, $0A, nRst, $02
    .db nA3, $0A, nRst, $02, nBb3, $0A, nRst, $02, nB3, $05, nRst, $01, nB3, $05, nRst, $01
    .db nB3, $0A, nRst, $02, nB3, $0A, nRst, $02, nB3, $15, nRst, $03, nG3, $0A, nRst, $02
    smpsRet

@ch0Call2:
    .db nE4, $1F, nRst, $05, nEb4, $1F, nRst, $05, nE4, $1F, nRst, $0B
    .db nG3, $05, nRst, $01, nA3, $05, nRst, $01, nB3, $05, nRst, $01, nC4, $05, nRst, $01, nD4, $05, nRst, $01
    .db nE4, $1F, nRst, $05, nEb4, $15, nRst, $03, nF4, $0A, nRst, $02, nE4, $2B, nRst, $11
    .db nG3, $0A, nRst, $02, nD4, $1F, nRst, $05, nCs4, $1F, nRst, $05, nD4, $1F, nRst, $0B
    .db nG3, $05, nRst, $01, nA3, $05, nRst, $01, nB3, $05, nRst, $01, nC4, $05, nRst, $01, nCs4, $05, nRst, $01
    .db nD4, $1F, nRst, $05, nG3, $15, nRst, $03, nF4, $0A, nRst, $02
    .db nE4, $2B, nRst, $11
    smpsRet

@ch0Call3:
    .db nG4, $0A, nRst, $02, nG5, $1F, nRst, $05, nG5, $1F, nRst, $05, nG5, $1F, nRst, $05
    .db nG5, $0A, nRst, $02, nA5, $05, nRst, $0D, nG5, $05, nRst, $01, nF5, $1F, nRst, $05
    .db nF5, $1F, nRst, $05, nF5, $1F, nRst, $05, nF5, $0A, nRst, $02, nG5, $05, nRst, $0D
    .db nF5, $05, nRst, $01, nE5, $1F, nRst, $05, nA4, $0A, nRst, $02, nB4, $0A, nRst, $02
    .db nF5, $0A, nRst, $02, nE5, $05, nRst, $01, nE5, $05, nRst, $01, nE5, $05, nRst, $0D
    .db nB4, $05, nRst, $01, nC5, $1F
    smpsRet

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsPatchEnv $00
    smpsFMVoice $00
    .db nRst, $0C, nCs3, $0A, nRst, $02, nC3, $0A, nRst, $02, nB2, $0A, nRst, $02, nC3, $0A
    .db nRst, $02, nCs3, $0A, nRst, $02, nD3, $05, nRst, $01, nD3, $05, nRst, $01, nD3, $0A
    .db nRst, $02, nE3, $0A, nRst, $02, nF3, $15, nRst, $03, nF3, $0A, nRst, $02
    smpsPatchEnv $01
    smpsChangeVol $01 ;$02
@ch1LoopPoint:
    .db nRst, $0C
    smpsCall    Mus_Water_FM@ch1Call1
    smpsCall    Mus_Water_FM@ch1Call2
    smpsCall    Mus_Water_FM@ch1Call1
    smpsCall    Mus_Water_FM@ch1Call1
    smpsCall    Mus_Water_FM@ch1Call1
    smpsCall    Mus_Water_FM@ch1Call2
@ch1Loop1:
    smpsCall    Mus_Water_FM@ch1Call1
    smpsLoop    $00, $09, Mus_Water_FM@ch1Loop1
    .db nG5, $05, nRst, $07, nG5, $05, nRst, $07
    .db nRst, $06
    ;
    smpsPatchEnv $05
    ;smpsChangeVol $FF
@ch1Loop2:
    .db nG4, $04, nRst, $02, nB4, $04, nRst, $02, nC5, $04, nRst, $02, nE5, $04, nRst, $02, nG5, $04, nRst, $08
    smpsLoop    $00, $02, Mus_Water_FM@ch1Loop2
    
    .db nG4, $04, nRst, $02, nBb4, $04, nRst, $02, nCs5, $04, nRst, $02, nE5, $04, nRst, $02, nG5, $04, nRst, $08
    .db nG4, $04, nRst, $02, nA4, $04, nRst, $02, nCs5, $04, nRst, $02, nE5, $04, nRst, $02, nG5, $04, nRst, $08
@ch1Loop3:
    .db nA4, $04, nRst, $02, nCs5, $04, nRst, $02, nD5, $04, nRst, $02, nF5, $04, nRst, $02, nA5, $04, nRst, $08
    smpsLoop    $00, $03, Mus_Water_FM@ch1Loop3
    .db nA4, $04, nRst, $02, nB4, $04, nRst, $02, nD5, $04, nRst, $02, nF5, $04, nRst, $02, nA5, $04, nRst, $0E
    ;
    smpsPatchEnv $01
    ;smpsChangeVol $01
    smpsCall    Mus_Water_FM@ch5Call1
    .db nF5, $05, nRst, $07, nF5, $05, nRst, $07
    .db nE5, $05, nRst, $01, nE5, $05, nRst, $01, nE5, $05, nRst, $0D, nG5, $05, nRst, $01
    .db nG5, $0A, nRst, $1A
    smpsJump    Mus_Water_FM@ch1LoopPoint

@ch1Call1:
    .db nG5, $05, nRst, $07, nG5, $05, nRst, $13
    smpsRet

@ch1Call2:
    .db nG5, $05, nRst, $07, nFs5, $05, nRst, $13
    smpsRet


;   --- CHANNEL 2 DATA ---
@ch2:
    smpsPatchEnv $0C
    .db nRst, $60
    .db nG2, $05, nRst, $07, nG2, $11, nRst, $07, nG2, $0A, nRst, $02
@ch2LoopPoint:
@ch2Loop1:
    .db nC3, $0A, nRst, $1A, nG2, $0A, nRst, $1A
    smpsLoop    $00, $04, Mus_Water_FM@ch2Loop1

    .db nB2, $0A, nRst, $1A, nBb2, $0A, nRst, $1A

@ch2Loop2:
    .db nB2, $0A, nRst, $1A, nG2, $0A, nRst, $1A
    smpsLoop    $00, $02, Mus_Water_FM@ch2Loop2
    
    .db nC3, $0A, nRst, $1A, nG2, $0A, nRst, $1A

    .db nC3, $0A, nRst, $1A, nB2, $0A, nRst, $1A, nBb2, $0A, nRst, $1A, nA2, $0A, nRst, $0E
    .db nCs3, $0A, nRst, $02
    
    .db nD3, $0A, nRst, $1A, nCs3, $0A, nRst, $1A, nC3, $0A, nRst, $1A, nB2, $0A, nRst, $0E
    .db nG2, $0A, nRst, $02
    
    .db nC3, $0A, nRst, $1A, nF2, $0A, nRst, $1A, nG2, $05
    .db nRst, $01, nG2, $05, nRst, $01, nG2, $05, nRst, $0D, nB2, $05, nRst, $01, nC3, $15
    .db nRst, $0F
    smpsJump    Mus_Water_FM@ch2LoopPoint

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsDetune $01
    smpsFMVoice $00
    .db nRst, $6C, nD3, $15, nRst, $03, nD3, $0A, nRst, $06
    smpsChangeVol $02
@ch3LoopPoint:
    .db nRst, $05
    smpsFMVoice $00
    smpsCall    Mus_Water_FM@ch0Call2
    ;
    smpsFMVoice $01
    smpsChangeVol $FF
    smpsCall    Mus_Water_FM@ch0Call3
    ;
    smpsChangeVol $01
    smpsJump    Mus_Water_FM@ch3LoopPoint

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsPatchEnv $01
    .db nRst, $7F, $11
@ch4LoopPoint:
    .db nRst, $0C
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call3
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call3
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call2
    .db nBb4, $05, nRst, $07, nBb4, $05, nRst, $13
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call2
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call1
    smpsCall    Mus_Water_FM@ch4Call2
    smpsCall    Mus_Water_FM@ch4Call2
    smpsCall    Mus_Water_FM@ch4Call2
    .db nG4, $05, nRst, $07, nE5, $05, nRst, $13
    .db nF5, $05, nRst, $07, nF5, $05, nRst, $13
    smpsCall    Mus_Water_FM@ch5Call1
    smpsCall    Mus_Water_FM@ch5Call2
    .db nD5, $05, nRst, $07, nB4, $0A, nRst, $0E
    smpsCall    Mus_Water_FM@ch4Call2
    ;
    .db nA4, $05, nRst, $07, nA4, $05, nRst, $07
    .db nG4, $05, nRst, $01, nG4, $05, nRst, $01
    .db nG4, $05, nRst, $0D, nB4, $05, nRst, $01
    .db nB4, $0A, nRst, $1A
    smpsJump    Mus_Water_FM@ch4LoopPoint

@ch4Call1:
    .db nB4, $05, nRst, $07, nB4, $05, nRst, $13
    smpsRet

@ch4Call2:
    .db nG4, $05, nRst, $07, nG4, $05, nRst, $13
    smpsRet

@ch4Call3:
    .db nB4, $05, nRst, $07, nBb4, $05, nRst, $13
    smpsRet

;   --- CHANNEL 5 DATA ---
@ch5:
    smpsDetune $01
    smpsPatchEnv $00
    smpsFMVoice $00
    .db nRst, $09
    smpsCall    Mus_Water_FM@ch0Call1
    .db $03
    smpsPatchEnv $01
    smpsChangeVol $FD ;$FE
@ch5LoopPoint:
    smpsCall    Mus_Water_FM@ch5Call1
    smpsCall    Mus_Water_FM@ch5Call3
    smpsCall    Mus_Water_FM@ch5Call1
    smpsCall    Mus_Water_FM@ch5Call1
    smpsCall    Mus_Water_FM@ch5Call1
    smpsCall    Mus_Water_FM@ch5Call3
    smpsCall    Mus_Water_FM@ch5Call1
    smpsCall    Mus_Water_FM@ch5Call1
    smpsCall    Mus_Water_FM@ch5Call2
    .db nCs5, $05, nRst, $07, nCs5, $05, nRst, $13
    smpsCall    Mus_Water_FM@ch5Call2
    smpsCall    Mus_Water_FM@ch5Call2
    smpsCall    Mus_Water_FM@ch5Call2
    smpsCall    Mus_Water_FM@ch5Call2

@ch5Loop1:
    smpsCall    Mus_Water_FM@ch5Call1
    smpsLoop    $00, $05, Mus_Water_FM@ch5Loop1

    .db nE5, $05, nRst, $07, nG5, $05, nRst, $13

@ch5Loop2:
    .db nA5, $05, nRst, $07, nA5, $05, nRst, $13
    smpsLoop    $00, $03, Mus_Water_FM@ch5Loop2

    .db nA5, $05, nRst, $07, nG5, $05, nRst, $01
    .db nF5, $05, nRst, $0D, nB4, $05, nRst, $07
    .db nB4, $05, nRst, $13, nC5, $05, nRst, $07
    .db nC5, $05, nRst, $07, nB4, $05, nRst, $01
    .db nB4, $05, nRst, $01, nB4, $05, nRst, $0D
    .db nD5, $05, nRst, $01, nD5, $0A, nRst, $26
    smpsJump    Mus_Water_FM@ch5LoopPoint

@ch5Call1:
    .db nE5, $05, nRst, $07, nE5, $05, nRst, $13
    smpsRet

@ch5Call2:
    .db nD5, $05, nRst, $07, nD5, $05, nRst, $13
    smpsRet

@ch5Call3:
    .db nE5, $05, nRst, $07, nEb5, $05, nRst, $13
    smpsRet

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsDetune $01
    smpsFMVoice $03
    .db nRst, $7F, $11
@ch6LoopPoint:
    .db nRst, $60, $60, $60, $60, $60, $54
    ;
    smpsCall    Mus_Water_FM@ch0Call3
    .db nRst, $05
    smpsJump    Mus_Water_FM@ch6LoopPoint

;   --- CHANNEL 7 DATA ---
@ch7:
    smpsModSetup    $10, $01, $FF, $03
    .db nRst, $7F, $11
@ch7LoopPoint:
    smpsDetune $01
    smpsFMVoice $00
    .db nG3, $1F, nRst, $05, nFs3, $1F, nRst, $05, nG3, $1F, nRst, $0B, nG3
    .db $05, nRst, $01, nA3, $05, nRst, $01, nB3, $05, nRst, $01, nC4, $05, nRst, $01, nD4
    .db $05, nRst, $01, nG3, $1F, nRst, $05, nFs3, $15, nRst, $03, nA3, $0A, nRst, $02, nG3
    .db $2B, nRst, $1D, nF3, $1F, nRst, $05, nE3, $1F, nRst, $05, nF3, $1F, nRst, $0B, nG3
    .db $05, nRst, $01, nA3, $05, nRst, $01, nB3, $05, nRst, $01, nC4, $05, nRst, $01, nCs4
    .db $05, nRst, $01, nF3, $1F, nRst, $05, nB2, $15, nRst, $03, nA3, $0A, nRst, $02, nG3
    .db $2B, nRst, $1D
    ;
    smpsDetune $00
    smpsFMVoice $01
    ;smpsChangeVol $FF
    .db nE5, $1F, nRst, $05
    .db nD5, $1F, nRst, $05
    .db nCs5, $1F, nRst, $29
    .db nD5, $1F, nRst, $05
    .db nCs5, $1F, nRst, $05
    .db nC5, $1F, nRst, $29
    .db nC5, $1F, nRst, $05
    .db nF4, $0A, nRst, $02
    .db nG4, $0A, nRst, $02
    .db nB4, $0A, nRst, $02
    .db $05, nRst, $01, nB4, $05, nRst, $01, nB4, $05, nRst, $0D, nF4, $05, nRst, $01, nE4
    .db $1F, nRst, $05
    ;smpsChangeVol $01
    smpsJump    Mus_Water_FM@ch7LoopPoint

;   --- CHANNEL 8 DATA ---
; @ch8:
;     smpsDetune $01
;     smpsPatchEnv $05
;     .db nRst, $7F, $11
; @ch8LoopPoint:
;     .db nRst, $74, $7F, $7F, $7F, $5B

; @ch8Loop1:
;     .db nG6, $02, nRst, $04, nB6, $02, nRst, $04, nC7, $02, nRst, $04, nE7, $02, nRst, $04, nG7, $02, nRst, $0A
;     smpsLoop    $00, $02, Mus_Water_FM@ch8Loop1
    
;     .db nG6, $02, nRst, $04, nBb6, $02, nRst, $04, nCs7, $02, nRst, $04, nE7, $02, nRst, $04, nG7, $02, nRst, $0A
;     .db nG6, $02, nRst, $04, nA6, $02, nRst, $04, nCs7, $02, nRst, $04, nE7, $02, nRst, $04, nG7, $02, nRst, $0A
    
; @ch8Loop2:
;     .db nA6, $02, nRst, $04, nCs7, $02, nRst, $04, nD7, $02, nRst, $04, nF7, $02, nRst, $04, nA7, $02, nRst, $0A
;     smpsLoop    $00, $03, Mus_Water_FM@ch8Loop2

;     .db nA6, $02, nRst, $04, nB6, $02, nRst, $04, nD7, $02, nRst, $04, nF7, $02, nRst, $04, nA7, $02

;     .db nRst, $7F, $15
;     smpsJump    Mus_Water_FM@ch8LoopPoint
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Overworld (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Overworld_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $4D
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Overworld_FM@ch0,  $0C, $00, $00, $00
    smpsChanHeader  Mus_Overworld_FM@ch1,  $00, $01, $00, $00
    smpsChanHeader  Mus_Overworld_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_Overworld_FM@ch3,  $00, $00, $00, $00
    smpsChanHeader  Mus_Overworld_FM@ch4,  $00, $02, $00, $00
    smpsChanHeader  Mus_Overworld_FM@ch5,  $00, $01, $00, $00
    smpsChanHeader  Mus_Overworld_FM@ch6,  $00, $00, $00, $00
    smpsChanHeader  Mus_Overworld_FM@ch7,  $00, $01, $00, $00
    smpsChanHeader  Mus_Overworld_FM@ch8,  $00, $08, $00, $00

    ; --- CHANNEL 0 DATA ---
@ch0:
    smpsCall    Mus_Overworld_FM@ch0Call5
    ; ---
    smpsFMVoice $0E
    smpsChangeVol $02
@ch0LoopPoint:
    smpsCall Mus_Overworld_FM@ch0Call1
    smpsCall Mus_Overworld_FM@ch0Call1
    ;
    smpsCall Mus_Overworld_FM@ch0Call2
    smpsCall Mus_Overworld_FM@ch0Call2
    ;
    smpsCall Mus_Overworld_FM@ch0Call3
    ;
    smpsCall Mus_Overworld_FM@ch0Call1
    smpsCall Mus_Overworld_FM@ch0Call1
    ;
    smpsCall Mus_Overworld_FM@ch0Call4
    smpsCall Mus_Overworld_FM@ch0Call4
    ;
    smpsCall Mus_Overworld_FM@ch0Call3
    ;
    smpsCall Mus_Overworld_FM@ch0Call4
    smpsJump Mus_Overworld_FM@ch0LoopPoint
    ; CHANNEL 0 SUBROUTINES
@ch0Call1:
    .db nC1, $0C, nRst, $06, nE1, $12, nG1, $06, nRst, $0C, nF1, $06, nRst, nG1, $0C, nFs1
    .db $06, nF1, $0C, nE1, $08, nC2, nE2, nF2, $0C, nD2, $06, nE2, nRst, nC2, nRst, nA1
    .db nRst, nB1, nG1, $0C
    smpsRet

@ch0Call2:
    .db nC1, $0C, nRst, $06, nE1, $12, nG1, $06, nRst, nF1
    .db $0C, nRst, $06, nC2, $12, nF1, $06, nRst, nC1, $0C, nRst, $06, nE1, $12, nG1, $06
    .db nRst, nF1, $0C, nRst, $06, nBb0, $12, nB0, $06, nRst, nC1, $0C, nRst, $06, nE1, $12
    .db nG1, $06, nRst, nF1, $0C, nRst, $06, nC2, $12, nF1, $06, nRst, nC1, $0C, nGs1, $06
    .db nRst, $0C, nBb1, $06, nRst, $0C, nC2, nFs1, $06, nG1, nC2, $18
    smpsRet

@ch0Call3:
    .db nF1, $0C, nRst, nFs1, nRst, nG1, nRst, nA1, nE1, $06, nEb1, nD1, $0C, nRst
    .db nG1, nRst, nC1, $12, $06, nRst, nC1, nD1, nE1, nF1, $0C, nRst, nFs1, nRst, nG1, nRst
    .db nA1, $06, nA0, nB0, nCs1
    smpsChangeVol $FF
    .db nD0, $05, nRst, $01, nD0, $05, nRst, $07, nD0, $05, nRst, $07, nD0, $05, nRst, $01
    .db nD0, $05, nRst, $07, nG0, $04, nRst, $14, nG0, $0A, nRst, $0E
    smpsChangeVol $01
    smpsRet

@ch0Call4:
    .db nC1, $0C, nRst, $06, nFs1, nG1, $0C, nC2, nD1, nD1
    .db nA1, $06, $06, nD1, $0C, nG1, nRst, $06, nG0, nA0, $0C, nB0, nC1, nC1, nG1, $06
    .db $06, nC1, $0C, $0C, nRst, $06, nFs1, nG1, $0C, nC2, nD1, nD1, nA1, $06, $06, nD1
    .db $0C, nG1, nRst, $06, nG1, nG1, $08, nA1, nB1, nC2, $0C, nFs1, $06, nG1, nC2, $18
    smpsRet


@ch0Call5:
    smpsChangeVol $01
    smpsFMVoice $07
    ;smpsFMVoice $01
    .db nD1, $06, $05, nRst, $07, nD1, $05, nRst, $07, nD1, $05, nRst, $01, nD1, $05, nRst
    .db $07, nG1, $04, nRst, $14, nG0, $0A, nRst, $0E
    smpsChangeVol $FF
    smpsRet
    
    ; --- CHANNEL 1 DATA ---
@ch1:
    smpsCall    Mus_Overworld_FM@ch1Call5
    ; ---
    smpsChangeVol $FB
@ch1LoopPoint:
    smpsPatchEnv $00
    smpsFMVoice $07
    smpsCall    Mus_Overworld_FM@ch1Call1
    .db nRst, $0C
    ;
    smpsPatchEnv $0D
    smpsCall    Mus_Overworld_FM@ch1Call2
    .db nRst, $0C
    smpsCall    Mus_Overworld_FM@ch1Call2
    ;
    smpsCall    Mus_Overworld_FM@ch1Call3
    ;
    smpsCall    Mus_Overworld_FM@ch1Call1
    ;
    smpsCall    Mus_Overworld_FM@ch1Call4
    smpsCall    Mus_Overworld_FM@ch1Call4
    ;
    smpsCall    Mus_Overworld_FM@ch1Call3
    ;
    smpsCall    Mus_Overworld_FM@ch1Call4
    smpsJump Mus_Overworld_FM@ch1LoopPoint
    ; CHANNEL 1 SUBROUTINES
@ch1Call1:
    .db nC4, $07, nRst, $0B, nG3, $07, nRst, $0B, nE3, $06, nRst, $0C, nA3, $06, nRst, nB3
    .db $0C, nBb3, $06
    .db nA3, $0C, nG3, $06, nRst, $02
    .db nE4, $06, nRst, $02, nG4, $06, nRst, $02, nA4, $07, nRst, $05, nF4, $04, nRst, $02
    .db nG4, $04, nRst, $08, nE4, $06, nRst, nC4, nRst, nD4, nB3, $0C

    .db nC4, $07, nRst, $0B, nG3, $07, nRst, $0B, nE3, $06, nRst, $0C, nA3, $06, nRst, nB3
    .db $0C, nBb3, $06
    .db nA3, nRst, nG3, nRst, $02
    .db nE4, $06, nRst, $02, nG4, $06, nRst, $02, nA4, $07, nRst, $05, nF4, $04, nRst, $02
    .db nG4, $04, nRst, $08, nE4, $06, nRst, nC4, nRst, nD4, nB3, $0C
    smpsRet

@ch1Call2:
    smpsChangeVol $01
    .db nG4, $06, nFs4, nF4, nEb4, nRst, nE4, nRst, nGs3, nA3, nC4, nRst, nA3, nC4, nD4, nRst
    .db $0C, nG4, $06, nFs4, nF4, nEb4, nRst, nE4, nRst, nC5, nRst, nC5, nC5, $07, nRst, $1D, nG4
    .db $06, nFs4, nF4, nEb4, nRst, nE4, nRst, nA3, nC4, $03, nD4, nC4, nA3, nC4, $06, nRst
    .db nD4, nRst, $12, nEb4, $06, nRst, $0C, nD4, $06, nRst, $0C, nC4, nRst, $24
    smpsChangeVol $FF
    smpsRet

@ch1Call3:
    smpsModSetup    $08, $01, $FF, $03
    smpsPatchEnv $0C
    .db nC4, $05, nRst, $01, nC4, $05, nRst, $07, nC4, $05, nRst, $07, nC4, $05, nRst, $01
    .db nD4, $0A, nRst, $02, nE4, $05, nRst, $01, nC4, $05, nRst, $07, nA3, $05, nRst, $01
    .db nG3, $0A, nRst, $0E, nC4, $05, nRst, $01, nC4, $05, nRst, $07, nC4, $05, nRst, $07
    .db nC4, $05, nRst, $01, nD4, $05, nRst, $01, nE4, $17, nRst, $01
    smpsPatchEnv $05
    smpsChangeVol $02
    .db nE6, $05, nRst, $07, nD6, $0F, nRst, $03
    smpsPatchEnv $0C
    smpsChangeVol $FE
    .db nC4, $05, nRst, $01, nC4, $05, nRst, $07, nC4, $05, nRst, $07, nC4, $05, nRst, $01
    .db nD4, $0A, nRst, $02, nE4, $05, nRst, $01, nC4, $05, nRst, $07, nA3, $05, nRst, $01
    .db nG3, $0A, nRst, $0E
    smpsChangeVol $FF
    smpsModOff
    .db nE4, $05, nRst, $01, nE4, $05, nRst, $07, nE4, $05, nRst, $07, nC4, $05, nRst, $01
    .db nE4, $05, nRst, $07, nG4, $04, nRst, $14
    smpsPatchEnv $00
    smpsFMVoice $07
    smpsChangeVol $01
    .db nG5, $06
    smpsChangeVol $05
    .db $04, nRst, $0E
    smpsChangeVol $FB
    smpsRet

@ch1Call4:
    smpsChangeVol $01
    smpsPatchEnv $0D
    .db nE4, $05, nRst, $01, nC4, $05, nRst, $07, nG3, $0F, nRst, $03, nGs3, $0A, nRst, $02
    .db nA3, $05, nRst, $01, nF4, $05, nRst, $07, nF4, $05, nRst, $01, nA3, $0A, nRst, $0E
    .db nB3, $07, nRst, $01, nA4, $07, nRst, $01, nA4, $07, nRst, $01, nA4, $07, nRst, $01
    .db nG4, $07, nRst, $01, nF4, $07, nRst, $01, nE4, $05, nRst, $01, nC4, $05, nRst, $07
    .db nA3, $05, nRst, $01, nG3, $0A, nRst, $0E, nE4, $05, nRst, $01, nC4, $05, nRst, $07
    .db nG3, $0F, nRst, $03, nGs3, $0A, nRst, $02, nA3, $05, nRst, $01, nF4, $05, nRst, $07
    .db nF4, $05, nRst, $01, nA3, $0A, nRst, $0E, nB3, $05, nRst, $01, nF4, $05, nRst, $07
    .db nF4, $05, nRst, $01, nF4, $07, nRst, $01, nE4, $07, nRst, $01, nD4, $07, nRst, $01
    .db nC4, $15, nRst, $1B
    smpsChangeVol $FF
    smpsRet

@ch1Call5:
    smpsFMVoice $07
    .db nE5, $05, nRst, $01, nE5, $05, nRst, $07, nE5, $05, nRst, $07, nC5, $05, nRst, $01
    .db nE5, $05, nRst, $07, nG5, $05, nRst, $13, nG5, $06
    smpsChangeVol $05
    .db $04, nRst, $0E
    smpsRet

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsFMVoice $10 ; UPLOAD CUSTOM INSTRUMENT
    smpsDetune  $01
    smpsCall    Mus_Overworld_FM@ch2Call1
    .db nG1, $0C, nRst
    smpsDetune  $00
    smpsChangeVol $02
@ch2LoopPoint:
@ch2Loop1:
    smpsCall    Mus_Overworld_FM@ch2Call2
    smpsLoop    $00, $0F, Mus_Overworld_FM@ch2Loop1
    smpsModOff
    smpsVolEnv  $00
    ;
    ;smpsChangeVol $02
    smpsDetune  $01
    smpsTranspose   $F4
    smpsCall    Mus_Overworld_FM@ch2Call1
    smpsTranspose   $0C
    .db nG1, $0C, nRst
    smpsDetune  $00
    ;
    smpsChangeVol $02
@ch2Loop2:
    smpsCall    Mus_Overworld_FM@ch2Call2
    smpsLoop    $00, $0F, Mus_Overworld_FM@ch2Loop2
    smpsModOff
    smpsVolEnv  $00
    ;
    ;smpsChangeVol $02
    smpsDetune  $01
    smpsTranspose   $F4
    smpsCall    Mus_Overworld_FM@ch2Call1
    smpsTranspose   $0C
    .db nG1, $0C, nRst
    smpsDetune  $00
    ;
    smpsChangeVol $02
@ch2Loop3:
    smpsCall    Mus_Overworld_FM@ch2Call2
    smpsLoop    $00, $04, Mus_Overworld_FM@ch2Loop3
    smpsJump    Mus_Overworld_FM@ch2LoopPoint
;   CHANNEL 2 SUBROUTINES
@ch2Call1:
    smpsPatchEnv $05
    .db nE6, $05, nRst, $01, nE6, $05, nRst, $07, nE6, $05, nRst, $07, nC6, $05, nRst, $01
    .db nE6, $05, nRst, $07, nG6, $04, nRst, $14
    smpsPatchEnv $00
    smpsFMVoice $0A
    smpsChangeVol $FE
    smpsRet

@ch2Call2:
    smpsVolEnv  $03
    smpsPatchEnv    $13
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $2C, $10, $08, $04

    ;smpsChangeVol   $FF
    smpsVolEnv  $00
    smpsPatchEnv    $0F
    smpsModSetup    $00, $01, $E4, $FF
    .db nD2, $18
    ;smpsChangeVol   $01
    smpsRet
;   --- CHANNEL 3 DATA ---
@ch3:
    smpsCall    Mus_Overworld_FM@ch3Call5
    ; ---
@ch3LoopPoint:
    smpsChangeVol $FF
    smpsCall    Mus_Overworld_FM@ch3Call1
    .db nRst, $0C
    ;
    smpsVolEnv $00
    smpsPatchEnv $0D
    smpsChangeVol $02
    smpsCall    Mus_Overworld_FM@ch3Call2
    .db $0C
    smpsCall    Mus_Overworld_FM@ch3Call2
    ;
    smpsChangeVol $01
    smpsCall    Mus_Overworld_FM@ch3Call3
    ;
    smpsChangeVol $FF
    smpsCall    Mus_Overworld_FM@ch3Call1
    ;
    smpsChangeVol $01
    smpsCall    Mus_Overworld_FM@ch3Call4
    smpsCall    Mus_Overworld_FM@ch3Call4
    ;
    smpsChangeVol $02
    smpsCall    Mus_Overworld_FM@ch3Call3
    ;
    smpsChangeVol   $01
    smpsCall    Mus_Overworld_FM@ch3Call4
    smpsChangeVol   $FF
    smpsJump Mus_Overworld_FM@ch3LoopPoint
;   CHANNEL 3 SUBROUTINES
@ch3Call1:
    smpsVolEnv $02
    smpsPatchEnv $07
    smpsDetune  $01
    .db nG3, $0C, nRst, $06, nD3, $12, nC3, $06, nRst, $0C, nE3, $06, nRst, nF3, $0C, nE3
    .db $06, nEb3, $0C, nD3, $08, nC4, $08, $08, nE4, $0C, nC4, $06, nD4, nRst, nB3, nRst
    .db nG3, nRst, nA3, nG3, $0C

    .db nG3, $0C, nRst, $06, nD3, $12, nC3, $06, nRst, $0C, nE3, $06, nRst, nF3, $0C, nE3
    .db $06, nEb3, nRst, nD3, $08, nC4, $08, $08, nE4, $0C, nC4, $06, nD4, nRst, nB3, nRst
    .db nG3, nRst, nA3, nG3, $0C
    smpsRet

@ch3Call2:
    .db nE5, $06, nEb5, nD5, nB4, nRst, nC5, nRst, nE4, nF4, nG4, nRst, nC4, nE4
    .db nF4, nRst, $0C, nE5, $06, nEb5, nD5, nB4, nRst, nC5, nRst, nF5, nRst, nF5, $06, $0C
    .db nRst, $18, nE5, $06, nEb5, nD5, nB4, nRst, nC5, nRst, nE4, nF4, nG4, nE4, nRst, nF4
    .db nRst, $12, nC5, $06, nRst, $0C, nF5, $06, nRst, $0C, nE5, nRst, $24
    smpsRet

@ch3Call3:
    smpsModSetup    $08, $01, $FF, $03
    smpsDetune  $00
    smpsPatchEnv $0C
    .db nA3, $05, nRst, $01, nA3, $05, nRst, $07, nA3, $05, nRst, $07, nA3, $05, nRst, $01
    .db nA3, $0A, nRst, $02, nC4, $05, nRst, $01, nA3, $05, nRst, $07, nG3, $05, nRst, $01
    .db nE3, $0A, nRst, $0E, nA3, $05, nRst, $01, nA3, $05, nRst, $07, nA3, $05, nRst, $07
    .db nA3, $05, nRst, $01, nA3, $05, nRst, $01, nB3, $17, nRst, $01
    smpsPatchEnv $05
    .db nC6, $05, nRst, $07, nBb5, $0F, nRst, $03
    smpsPatchEnv $0C
    smpsChangeVol $FF
    .db nA3, $05, nRst, $01, nA3, $05, nRst, $07, nA3, $05, nRst, $07, nA3, $05, nRst, $01
    .db nA3, $0A, nRst, $02, nC4, $05, nRst, $01, nA3, $05, nRst, $07, nG3, $05, nRst, $01
    .db nE3, $0A, nRst, $0E
    smpsChangeVol $FE
    .db nFs3, $05, nRst, $01, nFs3, $05, nRst, $07, nFs3, $05, nRst, $07, nD3, $05, nRst, $01
    .db nFs3, $05, nRst, $07, nD4, $04, nRst, $14
    smpsPatchEnv $00
    smpsFMVoice $07
    smpsChangeVol $01
    smpsModSetup    $0C, $01, $D4, $FF ;$D5, $FF
    smpsDetune  $01
    .db nG4, $0A;, nRst, $0E
    smpsModOff

    smpsChangeVol $05
    .db nG3, $02
    .db nRst, $0C
    smpsChangeVol $FB
    smpsRet

@ch3Call4:
    smpsVolEnv  $00
    smpsPatchEnv    $0D
    smpsDetune  $01
    .db nC4, $05, nRst, $01, nA3, $05, nRst, $07, nE3, $0F, nRst, $03, nEb3, $0A, nRst, $02
    .db nD3, $05, nRst, $01, nA3, $05, nRst, $07, nA3, $05, nRst, $01, nD3, $0A, nRst, $0E
    .db nG3, $07, nRst, $01, nF4, $07, nRst, $01, nF4, $07, nRst, $01, nF4, $07, nRst, $01
    .db nE4, $07, nRst, $01, nD4, $07, nRst, $01, nC4, $05, nRst, $01, nA3, $05, nRst, $07
    .db nEb3, $05, nRst, $01, nE3, $0A, nRst, $0E, nC4, $05, nRst, $01, nA3, $05, nRst, $07
    .db nE3, $0F, nRst, $03, nEb3, $0A, nRst, $02, nD3, $05, nRst, $01, nA3, $05, nRst, $07
    .db nA3, $05, nRst, $01, nD3, $0A, nRst, $0E, nG3, $05, nRst, $01, nD4, $05, nRst, $07
    .db nD4, $05, nRst, $01, nD4, $07, nRst, $01, nC4, $07, nRst, $01, nB3, $07, nRst, $01
    .db nG3, $05, nRst, $01, nE3, $05, nRst, $07, nE3, $05, nRst, $01, nC3, $15, nRst, $03
    smpsRet

@ch3Call5:
    smpsFMVoice $07
    .db nFs4, $05, nRst, $01, nFs4, $05, nRst, $07, nFs4, $05, nRst, $07, nD4, $05, nRst, $01
    smpsChangeVol $01
    .db nFs4, $05, nRst, $07, nD5, $04, nRst, $14
    smpsModSetup    $0C, $01, $D4, $FF ;$D5, $FF
    smpsDetune  $01
    .db nG4, $0A;, nRst, $0E
    smpsModOff

    smpsChangeVol $05
    .db nG3, $02
    .db nRst, $0C
    smpsChangeVol $FB
    smpsRet
;   --- CHANNEL 4 DATA ---
@ch4:
    smpsDetune $01
    .db nRst, $60
@ch4LoopPoint:
    .db nRst, $1F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $7F, $69
    ;
    smpsCall    Mus_Overworld_FM@ch4Call1
    ;
    .db nRst, $7F, $7F, $7F, $63
    ;
    smpsChangeVol $03
    smpsCall    Mus_Overworld_FM@ch4Call2
    smpsChangeVol $FB
    smpsCall    Mus_Overworld_FM@ch4Call2
    ;
    smpsChangeVol $F8
    smpsCall    Mus_Overworld_FM@ch4Call1
    ;
    .db nRst, $60
    ;
    smpsChangeVol $03
    smpsCall    Mus_Overworld_FM@ch4Call2
    smpsChangeVol $F7
    smpsJump    Mus_Overworld_FM@ch4LoopPoint
;   CHANNEL 4 SUBROUTINES
@ch4Call1:
    smpsVolEnv $01
    smpsPatchEnv $00
    smpsFMVoice $01
    .db nC4, $30, $30, $30, $30, $30, $30
    smpsRet

@ch4Call2:
    smpsVolEnv $00
    smpsPatchEnv $0B

    smpsCall    Mus_Overworld_FM@ch4Call3
    smpsCall    Mus_Overworld_FM@ch4Call3
    smpsCall    Mus_Overworld_FM@ch4Call3

    .db $14
    .db nC5, $03, nRst, $01
    smpsChangeVol $05
    .db nC5, $04, nRst
    smpsChangeVol $FB
    .db nC5, $03, nRst, $01
    
    smpsCall    Mus_Overworld_FM@ch4Call3
    smpsCall    Mus_Overworld_FM@ch4Call3

    smpsCall    Mus_Overworld_FM@ch4Call4
    smpsCall    Mus_Overworld_FM@ch4Call4
    smpsCall    Mus_Overworld_FM@ch4Call4

    .db $12

    smpsCall    Mus_Overworld_FM@ch4Call3

    .db nC5, $05, nRst, $01

    smpsCall    Mus_Overworld_FM@ch4Call3
    smpsCall    Mus_Overworld_FM@ch4Call3
    smpsCall    Mus_Overworld_FM@ch4Call3
    smpsCall    Mus_Overworld_FM@ch4Call3
    smpsCall    Mus_Overworld_FM@ch4Call3

    .db $12

    smpsCall    Mus_Overworld_FM@ch4Call3

    .db nC5, $05, nRst, $01

    smpsCall    Mus_Overworld_FM@ch4Call3
    smpsCall    Mus_Overworld_FM@ch4Call3

    smpsCall    Mus_Overworld_FM@ch4Call4
    smpsCall    Mus_Overworld_FM@ch4Call4
    smpsCall    Mus_Overworld_FM@ch4Call4

    .db $12

    smpsCall    Mus_Overworld_FM@ch4Call3

    .db nC5, $05, nRst, $01

    smpsCall    Mus_Overworld_FM@ch4Call3

    .db nC5, $05, nRst, $01
    smpsChangeVol $05
    .db nC5, $04, nRst, $02
    smpsRet

@ch4Call3:
    .db nC5, $05, nRst, $01
    smpsChangeVol $05
    .db nC5, $04, nRst, $02
    smpsChangeVol $FB
    smpsRet

@ch4Call4:
    .db nB4, $05, nRst, $01
    smpsChangeVol $05
    .db nB4, $04, nRst, $02
    smpsChangeVol $FB
    smpsRet

;   --- CHANNEL 5 DATA ---
@ch5:
    smpsCall    Mus_Overworld_FM@ch5Call5
    ; ---
@ch5LoopPoint:
    smpsChangeVol $03
    smpsCall    Mus_Overworld_FM@ch5Call1
    smpsCall    Mus_Overworld_FM@ch5Call1
    ;
    smpsChangeVol $01
    smpsCall    Mus_Overworld_FM@ch5Call2
    smpsChangeVol $FB
    smpsCall    Mus_Overworld_FM@ch5Call2
    ;
    smpsCall    Mus_Overworld_FM@ch5Call3
    ;
    smpsChangeVol $03
    smpsCall    Mus_Overworld_FM@ch5Call1
    smpsCall    Mus_Overworld_FM@ch5Call1
    ;
    smpsChangeVol $01
    smpsCall    Mus_Overworld_FM@ch5Call4
    smpsChangeVol $FB
    smpsCall    Mus_Overworld_FM@ch5Call4
    ;
    smpsCall    Mus_Overworld_FM@ch5Call3
    ;
    smpsChangeVol $04
    smpsCall    Mus_Overworld_FM@ch5Call4
    smpsChangeVol $F7
    smpsJump    Mus_Overworld_FM@ch5LoopPoint
;   CHANNEL 5 SUBROUTINES
@ch5Call1:
    smpsPatchEnv $00
    smpsDetune $00
    smpsFMVoice $0C
    .db nG5, $09, nRst, nD5, nRst, nB4, nRst, nE5, $04, nRst, $08, nFs5, $09, nRst, $03, nF5
    .db $04, nRst, $02, nE5, $04, nRst, $08, nD5, $06, nRst, $02, nB5, $06, nRst, $02, nD6
    .db $06, nRst, $02, nE6, $09, nRst, $03, nC6, $04, nRst, $02, nD6, $04, nRst, $08, nB5
    .db $04, nRst, $08, nG5, $04, nRst, $08, nA5, $04, nRst, $02, nFs5, $09, nRst, $03
    smpsRet

@ch5Call2:
    smpsPatchEnv $0B
    smpsDetune $00

    .db nE5, $05, nRst, $01
    smpsChangeVol $05
    .db nE5, $04, nRst, $08
    smpsChangeVol $FB

    .db nE5, $05, nRst, $01
    
    .db nE5, $05, nRst, $01
    smpsChangeVol $05
    .db nE5, $04, nRst, $08
    smpsChangeVol $FB

    .db $0C

    .db nF5, $05, nRst, $01
    smpsChangeVol $05
    .db nF5, $04, nRst, $02
    smpsChangeVol $FB

    .db nF5, $05, nRst, $01

    .db nF5, $05, nRst, $01
    smpsChangeVol $05
    .db nF5, $04, nRst, $02
    smpsChangeVol $FB

    .db $0C

    .db nE5, $05, nRst, $01
    smpsChangeVol $05
    .db nE5, $04, nRst, $08
    smpsChangeVol $FB

    .db nE5, $05, nRst, $01

    .db nE5, $05, nRst, $01
    smpsChangeVol $05
    .db nE5, $04, nRst, $08
    smpsChangeVol $FB

    .db $0C

    .db nF5, $05, nRst, $01
    smpsChangeVol $05
    .db nF5, $04, nRst, $02
    smpsChangeVol $FB

    .db nF5, $05, nRst, $01

    .db nF5, $05, nRst, $01
    smpsChangeVol $05
    .db nF5, $04, nRst, $02
    smpsChangeVol $FB

    .db $0C

    .db nE5, $05, nRst, $01
    smpsChangeVol $05
    .db nE5, $04, nRst, $08
    smpsChangeVol $FB

    .db nE5, $05, nRst, $01

    .db nE5, $05, nRst, $01
    smpsChangeVol $05
    .db nE5, $04, nRst, $08
    smpsChangeVol $FB

    .db $0C

    .db nF5, $05, nRst, $01
    smpsChangeVol $05
    .db nF5, $04, nRst, $02
    smpsChangeVol $FB

    .db nF5, $05, nRst, $01

    .db nF5, $05, nRst, $01
    smpsChangeVol $05
    .db nF5, $04, nRst, $02
    smpsChangeVol $FB

    .db $18

    .db nEb5, $05, nRst, $01
    smpsChangeVol $05
    .db nEb5, $04, nRst, $08
    smpsChangeVol $FB

    .db nF5, $05, nRst, $01
    smpsChangeVol $05
    .db nF5, $04, nRst, $02
    smpsChangeVol $FB

    .db $06

    .db nE5, $05, nRst, $01
    smpsChangeVol $05
    .db nE5, $04, nRst, $26
    smpsRet

@ch5Call3:
    smpsModSetup    $08, $01, $FF, $03
    smpsPatchEnv $0C
    smpsChangeVol $F9
    .db nE4, $05, nRst, $01, nE4, $05, nRst, $07, nE4, $05, nRst, $07, nE4, $05, nRst, $01
    .db nE4, $0A, nRst, $02, nG4, $05, nRst, $01, nE4, $05, nRst, $07, nC4, $05, nRst, $01
    .db nD4, $0A, nRst, $02, nCs4, $0A, nRst, $02, nF4, $05, nRst, $01, nF4, $05, nRst, $07
    .db nF4, $05, nRst, $07, nF4, $05, nRst, $01, nF4, $05, nRst, $01, nG4, $17, nRst, $01
    smpsPatchEnv $05
    .db nBb4, $05, nRst, $07, nBb4, $0F, nRst, $03
    smpsPatchEnv $0C
    .db nE4, $05, nRst, $01, nE4, $05, nRst, $07, nE4, $05, nRst, $07, nE4, $05, nRst, $01
    .db nE4, $0A, nRst, $02
    smpsPatchEnv $01
    .db nC5, $05, nRst, $01, nB4, $05, nRst, $01, nBb4, $05, nRst, $01, nA4, $1A, nRst, $04
    smpsPatchEnv $0C
    smpsChangeVol $FE
    .db nC4, $05, nRst, $01, nC4, $05, nRst, $07, nC4, $05, nRst, $07, nA3, $05, nRst, $01
    .db nC4, $05, nRst, $07, nF4, $04, nRst, $14
    smpsPatchEnv $00
    smpsFMVoice $07
    smpsDetune $FF
    smpsModSetup   $0C, $01, $D5, $FF
    .db nG3, $0A;, nRst, $0E
    smpsModOff

    smpsChangeVol $05
    .db nG2, $02
    .db nRst, $0C
    smpsChangeVol $FB
    smpsRet

@ch5Call4:
    smpsPatchEnv $0B
    smpsDetune  $00

    smpsCall    Mus_Overworld_FM@ch5Call6
    smpsCall    Mus_Overworld_FM@ch5Call6
    smpsCall    Mus_Overworld_FM@ch5Call6

    .db $14
    .db nF5, $03, nRst, $01
    smpsChangeVol $05
    .db nF5, $04, nRst
    smpsChangeVol $FB

    .db nF5, $03, nRst, $01

    smpsCall    Mus_Overworld_FM@ch5Call7
    smpsCall    Mus_Overworld_FM@ch5Call7
    smpsCall    Mus_Overworld_FM@ch5Call7
    smpsCall    Mus_Overworld_FM@ch5Call7
    smpsCall    Mus_Overworld_FM@ch5Call7

    .db $12

    smpsCall    Mus_Overworld_FM@ch5Call6

    .db nE5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch5Call6
    smpsCall    Mus_Overworld_FM@ch5Call6
    smpsCall    Mus_Overworld_FM@ch5Call6
    smpsCall    Mus_Overworld_FM@ch5Call6
    smpsCall    Mus_Overworld_FM@ch5Call6

    .db $12

    smpsCall    Mus_Overworld_FM@ch5Call7

    .db nF5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch5Call7
    smpsCall    Mus_Overworld_FM@ch5Call7
    smpsCall    Mus_Overworld_FM@ch5Call7
    smpsCall    Mus_Overworld_FM@ch5Call7
    smpsCall    Mus_Overworld_FM@ch5Call7

    .db $12

    smpsCall    Mus_Overworld_FM@ch5Call6

    .db nE5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch5Call6

    .db nE5, $04, nRst, $02
    smpsChangeVol $05
    .db nE5, $04, nRst, $02
    smpsRet

@ch5Call5:
    smpsFMVoice $07
    .db nC5, $05, nRst, $01, nC5, $05, nRst, $07, nC5, $05, nRst, $07, nA4, $05, nRst, $01
    .db nC5, $05, nRst, $07, nF5, $05, nRst, $13
    smpsDetune $FF
    smpsModSetup   $0C, $01, $D5, $FF
    .db nG3, $0A;, nRst, $0E
    smpsModOff

    smpsChangeVol $05
    .db nG2, $02
    .db nRst, $0C
    smpsChangeVol $FB
    smpsRet

@ch5Call6:
    .db nE5, $04, nRst, $02
    smpsChangeVol $05
    .db nE5, $04, nRst, $02
    smpsChangeVol $FB
    smpsRet

@ch5Call7:
    .db nF5, $04, nRst, $02
    smpsChangeVol $05
    .db nF5, $04, nRst, $02
    smpsChangeVol $FB
    smpsRet

;   --- CHANNEL 6 DATA ---
@ch6:
@ch6LoopPoint:
    .db nRst, $60
    smpsCall    Mus_Overworld_FM@ch6Call1
    ;
    smpsChangeVol $05
    smpsCall    Mus_Overworld_FM@ch6Call2
    smpsChangeVol $FB
    smpsCall    Mus_Overworld_FM@ch6Call2
    ;
    smpsChangeVol $F8
    smpsCall    Mus_Overworld_FM@ch6Call3
    ;
    smpsChangeVol $FE
    smpsCall    Mus_Overworld_FM@ch6Call1
    ;
    .db nRst, $7F, $7F, $7F, $7F, $7F, $7F, $06
    ;
    smpsChangeVol $02
    smpsCall    Mus_Overworld_FM@ch6Call3
    ;
    .db $60, $60, $60
    smpsChangeVol $FE
    smpsJump    Mus_Overworld_FM@ch6LoopPoint
;   CHANNEL 6 SUBROUTINES
@ch6Call1:
    smpsVolEnv $02
    smpsPatchEnv $07
    smpsDetune $00
    .db nE3, $0C, nRst, $06, nC3, $12, nG2, $06, nRst, $0C, nC3, $06, nRst, nD3, $0C, nCs3
    .db $06, nC3, $0C, $08, nG3, nB3, nC4, $0C, nA3, $06, nB3, nRst, nG3, nRst, nE3, nRst
    .db nF3, $06, $0C, nE3, nRst, $06, nC3, $12, nG2, $06, nRst, $0C, nC3, $06, nRst, nD3
    .db $0C, nCs3, $06, nC3, nRst, nC3, $08, nG3, nB3, nC4, $0C, nA3, $06, nB3, nRst, nG3
    .db nRst, nE3, nRst, nF3, nD3, $0C
    smpsRet

@ch6Call2:
    smpsVolEnv $00
    smpsPatchEnv $0B

    smpsCall    Mus_Overworld_FM@ch6Call4

    .db nG5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch6Call4

    .db $0C

    smpsCall    Mus_Overworld_FM@ch6Call5

    .db nA5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch6Call5

    .db $0C

    smpsCall    Mus_Overworld_FM@ch6Call4

    .db nG5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch6Call4

    .db $0C

    smpsCall    Mus_Overworld_FM@ch6Call5

    .db nA5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch6Call5

    .db $0C

    smpsCall    Mus_Overworld_FM@ch6Call4

    .db nG5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch6Call4

    .db $0C

    smpsCall    Mus_Overworld_FM@ch6Call5

    .db nA5, $04, nRst, $02

    smpsCall    Mus_Overworld_FM@ch6Call5

    .db $18

    .db nGs5, $04, nRst, $02
    smpsChangeVol $05
    .db nGs5, $04, nRst, $08
    smpsChangeVol $FB

    .db nBb5, $04, nRst, $02
    smpsChangeVol $05
    .db nBb5, $04, nRst, $08
    smpsChangeVol $FB

    .db nC6, $04, nRst, $02
    smpsChangeVol $05
    .db nC6, $04, nRst, $26
    smpsRet

@ch6Call3:
    smpsVolEnv $01
    smpsPatchEnv $00
    smpsFMVoice $01
    .db nA4, $30, nG4, nF4, nE4, nA4, nG4
    .db nRst, $60
    smpsRet

@ch6Call4:
    .db nG5, $04, nRst, $02
    smpsChangeVol $05
    .db nG5, $04, nRst, $08
    smpsChangeVol $FB
    smpsRet

@ch6Call5:
    .db nA5, $04, nRst, $02
    smpsChangeVol $05
    .db nA5, $04, nRst, $02
    smpsChangeVol $FB
    smpsRet

;   --- CHANNEL 7 DATA ---
@ch7:
    smpsDetune $FF
    smpsFMVoice $07
    smpsCall    Mus_Overworld_FM@ch7Call1
    ;smpsChangeVol $01

    smpsChangeVol   $02
@ch7Loop1:
@ch7LoopPoint:
    smpsCall    Mus_Overworld_FM@ch7Call2
    smpsLoop    $00, $1E, Mus_Overworld_FM@ch7Loop1
    ;
    smpsChangeVol   $FF
    smpsTranspose   $F4
    ;smpsDetune  $00
    smpsVolEnv  $00
    smpsPatchEnv $0C
    smpsCall    Mus_Overworld_FM@ch7Call1
    smpsTranspose   $0C
    ;
    smpsChangeVol   $01
@ch7Loop2:
    smpsCall    Mus_Overworld_FM@ch7Call2
    smpsLoop    $00, $1E, Mus_Overworld_FM@ch7Loop2
    ;
    smpsChangeVol   $FF
    smpsTranspose   $F4
    smpsVolEnv  $00
    smpsPatchEnv $0C
    smpsCall    Mus_Overworld_FM@ch7Call1
    smpsTranspose   $0C
    ;
    smpsChangeVol   $01
@ch7Loop3:
    smpsCall    Mus_Overworld_FM@ch7Call2
    smpsLoop    $00, $08, Mus_Overworld_FM@ch7Loop3
    smpsJump    Mus_Overworld_FM@ch7LoopPoint
;   CHANNEL 7 SUBROUTINE
@ch7Call1:
    .db nA4, $05, nRst, $01, nA4, $05, nRst, $07, nA4, $05, nRst, $07, nFs4, $05, nRst, $01
    .db nA4, $05, nRst, $07, nC5, $05, nRst, $2B
    smpsRet

@ch7Call2:
    ;smpsDetune  $7F
    smpsPatchEnv $09
    smpsVolEnv  $04
    .db nBb7, $0C, $08, $04

    smpsVolEnv  $05
    .db nBb7, $0C

    smpsVolEnv  $04
    .db nBb7, $08, $04
    smpsRet

;   --- CHANNEL 8 DATA ---
@ch8:
    .db nRst, $60
    smpsDetune $01
@ch8LoopPoint:
    smpsCall    Mus_Overworld_FM@ch8Call1
    ;
    smpsChangeVol $FA
    smpsCall    Mus_Overworld_FM@ch8Call2
    smpsCall    Mus_Overworld_FM@ch8Call2
    .db nRst, $60, $60, $60, $60
    ;
    smpsChangeVol $06
    smpsCall    Mus_Overworld_FM@ch8Call1
    ;
    smpsChangeVol $FA
    smpsCall    Mus_Overworld_FM@ch8Call3
    smpsCall    Mus_Overworld_FM@ch8Call3
    .db nRst, $60, $60, $60, $60
    ;
    smpsCall    Mus_Overworld_FM@ch8Call3
    smpsChangeVol $06
    smpsJump    Mus_Overworld_FM@ch8LoopPoint
;   CHANNEL 8 SUBROUTINES
@ch8Call1:
    smpsPatchEnv $00
    smpsFMVoice $07
    .db nRst, $06
    .db nC4, $07, nRst, $0B, nG3, $07, nRst, $0B, nE3, $06, nRst, $0C, nA3, $06
    .db nRst, nB3, $0C, nBb3, $06, nA3, $0C, nG3, $06, nRst, $02, nE4, $06, nRst, $02, nG4
    .db $06, nRst, $02, nA4, $07, nRst, $05, nF4, $04, nRst, $02, nG4, $04, nRst, $08, nE4
    .db $06, nRst, nC4, nRst, nD4, nB3, $0C

    .db nC4, $07, nRst, $0B, nG3, $07, nRst, $0B, nE3, $06, nRst, $0C, nA3, $06
    .db nRst, nB3, $0C, nBb3, $06, nA3, nRst, nG3, nRst, $02, nE4, $06, nRst, $02, nG4, $06
    .db nRst, $02, nA4, $07, nRst, $05, nF4, $04, nRst, $02, nG4
    .db $04, nRst, $08, nE4, $06, nRst, nC4, nRst, nD4, nB3
    smpsRet

@ch8Call2:
    smpsPatchEnv $0D
    .db nRst, $0D
    .db nG5, $06, nFs5, nF5, nEb5, nRst, nE5, nRst, nGs4, nA4, nC5, nRst, nA4, nC5, nD5, nRst
    .db $0C, nG5, $06, nFs5, nF5, nEb5, nRst, nE5, nRst, nC6, nRst, nC6, $06, $07, nRst, $1D
    .db nG5, $06, nFs5, nF5, nEb5, nRst, nE5, nRst, nA4, nC5, $03, nD5, nC5, nA4, nC5, $06
    .db nRst, nD5, nRst, $12, nEb5, $06, nRst, $0C, nD5, $06, nRst, $0C, nC5, nRst, $23
    smpsRet

@ch8Call3:
    smpsPatchEnv $0D
    .db nRst, $01
    .db nE5, $05, nRst, $01, nC5, $05, nRst, $07, nG4, $0F, nRst, $03, nGs4, $0A, nRst, $02
    .db nA4, $05, nRst, $01, nF5, $05, nRst, $07, nF5, $05, nRst, $01, nA4, $0A, nRst, $0E
    .db nB4, $07, nRst, $01, nA5, $07, nRst, $01, nA5, $07, nRst, $01, nA5, $07, nRst, $01
    .db nG5, $07, nRst, $01, nF5, $07, nRst, $01, nE5, $05, nRst, $01, nC5, $05, nRst, $07
    .db nA4, $05, nRst, $01, nG4, $0A, nRst, $0E, nE5, $05, nRst, $01, nC5, $05, nRst, $07
    .db nG4, $0F, nRst, $03, nGs4, $0A, nRst, $02, nA4, $05, nRst, $01, nF5, $05, nRst, $07
    .db nF5, $05, nRst, $01, nA4, $0A, nRst, $0E, nB4, $05, nRst, $01, nF5, $05, nRst, $07
    .db nF5, $05, nRst, $01, nF5, $07, nRst, $01, nE5, $07, nRst, $01, nD5, $07, nRst, $01
    .db nC5, $15, nRst, $1A
    smpsRet
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Underground (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Underground_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $AD
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Underground_FM@ch0,  $00, $00, $00, $00
    smpsChanHeader  Mus_Underground_FM@ch1,  $00, $00, $00, $00
    smpsChanHeader  Mus_Underground_FM@ch2,  $00, $05, $00, $00
    smpsChanHeader  Mus_Underground_FM@ch3,  $00, $07, $00, $00
    smpsChanHeader  Mus_Underground_FM@ch4,  $00, $03, $00, $00
    smpsChanHeader  Mus_Underground_FM@ch5,  $00, $02, $00, $00
    smpsChanHeader  Mus_Underground_FM@ch6,  $00, $01, $00, $00
    smpsChanHeader  Mus_Underground_FM@ch7,  $00, $06, $00, $00
    smpsChanHeader  Mus_Underground_FM@ch8,  $00, $06, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
@ch0LoopPoint:
    smpsPatchEnv    $11
    .db nRst, $60
    ;
    smpsCall    Mus_Underground_FM@ch0Call1
    .db $06
    smpsCall    Mus_Underground_FM@ch0Call1
    .db $06
    ;
    smpsTranspose   $F9
    smpsCall    Mus_Underground_FM@ch0Call1
    .db $06
    smpsCall    Mus_Underground_FM@ch0Call1
    ;
    smpsTranspose   $07
    .db nEb2, $02, nD2, nCs2
    .db nC2, $06, nEb2, nD2, nGs1, nG1, nCs2
    .db nC2, $01, nRst, $01
    .db nFs2, $01, nRst, $01
    .db nF2, $01, nRst, $01
    .db nE2, $01, nRst, $01
    .db nBb2, $01, nRst, $01
    .db nA2, $01, nRst, $01
    .db nGs2, $01, nRst, $03
    .db nEb2, $01, nRst, $03
    .db nB1, $01, nRst, $03
    .db nBb1, $01, nRst, $03
    .db nA1, $01, nRst, $03
    .db nGs1, $01, nRst, $03
    .db nRst, $18
    smpsJump    Mus_Underground_FM@ch0LoopPoint

@ch0Call1:
    .db nC2, $03, nC3, $01, nRst, $02
    .db nA1, $03, nA2, $01, nRst, $02
    .db nBb1, $03, nBb2, $01, nRst, $02
    .db nRst, $18
    smpsRet

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsDetune  $FF
    smpsJump    Mus_Underground_FM@ch0LoopPoint

;   --- CHANNEL 2 DATA ---
@ch2:
    .db nRst, $06
    smpsDetune  $01
    smpsJump    Mus_Underground_FM@ch0LoopPoint

;   --- CHANNEL 3 DATA ---
@ch3:
    .db nRst, $06
    smpsDetune  $00
    smpsJump    Mus_Underground_FM@ch2

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsPatchEnv    $09
    smpsVolEnv  $04
@ch4LoopPoint:
@ch4Loop1:
    .db nBb7, $03
    smpsJump    Mus_Underground_FM@ch4LoopPoint

;   --- CHANNEL 5 DATA ---
@ch5:
    smpsVolEnv  $03
    smpsPatchEnv    $13
@ch5LoopPoint:
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $0C
    
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $08, nRst, $04

    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03, $03, $06

    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $08, nRst, $04

    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $0C
    
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $08, nRst, $01

    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $06, $06, $03

    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $06, $03, $03
    smpsJump    Mus_Underground_FM@ch5LoopPoint

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsPatchEnv    $0F
    smpsFMVoice $10 ; UPLOAD CUSTOM INSTRUMENT
    smpsModSetup    $00, $01, $E4, $FF
@ch6LoopPoint:
    .db nRst, $0C, nD2, nRst, nD2, nRst, nD2, $09, nRst, $0F, nD2, $06, $03, $03
    smpsJump    Mus_Underground_FM@ch6LoopPoint

;   --- CHANNEL 7 DATA ---
@ch7:
    .db nRst, $02
    smpsDetune  $01
    smpsJump    Mus_Underground_FM@ch6

;   --- CHANNEL 8 DATA ---
@ch8:
    .db nRst, $02
    smpsDetune  $01
    smpsVolEnv  $03
    smpsPatchEnv    $13
    smpsModSetup    $00, $01, $E8, $FF
@ch8LoopPoint:
    .db nRst, $0C, nC4, nRst, nC4, nRst, nC4, $09, nRst, $0F, nC4, $06, $03, $03
    smpsJump    Mus_Underground_FM@ch8LoopPoint
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Castle (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Castle_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $83
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Castle_FM@ch0,  $00, $03, $00, $00
    smpsChanHeader  Mus_Castle_FM@ch1,  $00, $08, $00, $00
    smpsChanHeader  Mus_Castle_FM@ch2,  $00, $08, $00, $00
    smpsChanHeader  Mus_Castle_FM@ch3,  $0C, $07, $00, $00
    smpsChanHeader  Mus_Castle_FM@ch4,  $00, $0C, $00, $00
    smpsChanHeader  Mus_Castle_FM@ch5,  $0C, $03, $00, $00
    smpsChanHeader  Mus_Castle_FM@ch6,  $00, $0C, $00, $00
    smpsChanHeader  Mus_Castle_FM@ch7,  $00, $08, $00, $00
    smpsChanHeader  Mus_Castle_FM@ch7,  $0C, $08, $00, $00

;   --- CHANNEL 3 (0) DATA ---
@ch3:
    smpsModSetup    $10, $01, $FF, $04
    .db nRst, $08
    ; FALL THROUGH

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsVolEnv $06
    smpsFMVoice $07
@ch0LoopPoint:
    .db nEb2, $30
    smpsChangeVol $FF
    .db nD2, $18, nFs2
    smpsChangeVol $FF
    .db nF2, $30
    
    smpsNoAtk
    .db nE2, $0C
    smpsVolEnv $00
    smpsChangeVol $01
    .db $0C

    smpsVolEnv $06
    .db nBb2, $18
    
    smpsNoAtk
    .db nA2, $0C
    smpsVolEnv $00
    smpsChangeVol $01
    .db $0C

    smpsVolEnv $06
    .db nE2, $18, nEb2, nE2
    smpsJump    Mus_Castle_FM@ch0LoopPoint

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $13 ; UPLOAD CUSTOM INSTRUMENT
@ch1LoopPoint:
    smpsVolEnv  $0B
    .db nG4, $03, nBb4, nG4, nA4
    .db nG4, nGs4, nG4, nA4
    .db nG4, nBb4, nG4, nB4
    .db nG4, nBb4, nG4, nA4
    smpsChangeVol $FF
    smpsLoop    $00, $02, Mus_Castle_FM@ch1LoopPoint
    ;
    .db nFs4, nA4, nFs4, nGs4
    .db nFs4, nA4, nFs4, nBb4
    .db nFs4, nA4, nFs4, nGs4
    .db nFs4, nA4, nFs4, nBb4
    ;
    .db nFs4, nA4, nFs4, nGs4
    smpsChangeVol $01
    .db nFs4, nA4, nFs4, nBb4
    .db nFs4, nA4, nFs4, nGs4
    .db nFs4, nA4, nFs4, nBb4
    ;
    .db nBb4, nD5, nBb4, nEb5
    smpsChangeVol $01
    .db nBb4, nD5, nBb4, nCs5
    .db nBb4, nD5, nBb4, nCs5
    .db nBb4, nC5, nBb4, nCs5
    ;
    .db nBb4, nD5, nBb4, nEb5
    .db nBb4, nD5, nBb4, nCs5
    .db nBb4, nD5, nBb4, nCs5
    .db nBb4, nC5, nBb4, nCs5
    smpsJump    Mus_Castle_FM@ch1LoopPoint

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsDetune $01
    smpsFMVoice $00
@ch2LoopPoint:
    smpsVolEnv  $0B
    .db nG4, $03, nD5, nG4, nCs5
    .db nG4, nC5, nG4, nCs5
    .db nG4, nD5, nG4, nEb5
    .db nG4, nD5, nG4, nCs5
    smpsChangeVol $FF
    smpsLoop    $00, $02, Mus_Castle_FM@ch2LoopPoint
    ;
    .db nFs4, nCs5, nFs4, nC5
    .db nFs4, nCs5, nFs4, nD5
    .db nFs4, nCs5, nFs4, nD5
    .db nFs4, nCs5, nFs4, nC5
    ;
    .db nFs4, nCs5, nFs4, nC5
    smpsChangeVol $01
    .db nFs4, nCs5, nFs4, nD5
    .db nFs4, nCs5, nFs4, nD5
    .db nFs4, nCs5, nFs4, nC5
    ;
    .db nBb4, nF5, nBb4, nFs5
    smpsChangeVol $01
    .db nBb4, nF5, nBb4, nE5
    .db nBb4, nF5, nBb4, nE5
    .db nBb4, nEb5, nBb4, nE5
    ;
    .db nBb4, nF5, nBb4, nFs5
    .db nBb4, nF5, nBb4, nE5
    .db nBb4, nF5, nBb4, nE5
    .db nBb4, nEb5, nBb4, nE5
    smpsJump    Mus_Castle_FM@ch2LoopPoint

;   --- CHANNEL 4 (1) DATA ---
@ch4:
    smpsDetune $01
    .db nRst, $03
    smpsJump    Mus_Castle_FM@ch1

;   --- CHANNEL 5 (0) DATA ---
@ch5:
    smpsDetune $01
    smpsJump    Mus_Castle_FM@ch0

;   --- CHANNEL 6 (2) DATA ---
@ch6:
    .db nRst, $03
    smpsFMVoice $00
    smpsJump    Mus_Castle_FM@ch2LoopPoint

;   --- CHANNEL 7 (0) DATA ---
@ch7:
    .db nRst, $06
    smpsDetune $FF
    smpsJump    Mus_Castle_FM@ch0
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Pipe Intro (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_PipeIntro_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $4D
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_PipeIntro_FM@ch0,  $0C, $00, $00, $00
    smpsChanHeader  Mus_PipeIntro_FM@ch1,  $00, $01, $00, $00
    smpsChanHeader  Mus_PipeIntro_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_PipeIntro_FM@ch3,  $00, $00, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_PipeIntro_FM@ch5,  $00, $01, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_PipeIntro_FM@ch7,  $00, $01, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00

@ch0:
    smpsCall    Mus_Overworld_FM@ch0Call5
    smpsStop

@ch1:
    smpsCall    Mus_Overworld_FM@ch1Call5
    smpsStop

@ch2:
    smpsDetune  $01
    smpsCall    Mus_Overworld_FM@ch2Call1
    .db nG1, $0C, nRst
    smpsStop

@ch3:
    smpsCall    Mus_Overworld_FM@ch3Call5
    smpsStop

@ch5:
    smpsCall    Mus_Overworld_FM@ch5Call5
    smpsStop

@ch7:
    smpsDetune $FF
    smpsFMVoice $07
    smpsCall    Mus_Overworld_FM@ch7Call1
    smpsStop
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Invincible (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Invincible_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $74
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Invincible_FM@ch0,  $00, $01, $00, $00
    smpsChanHeader  Mus_Invincible_FM@ch1,  $00, $04, $00, $00
    smpsChanHeader  Mus_Invincible_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_Invincible_FM@ch3,  $00, $03, $00, $00
    smpsChanHeader  Mus_Invincible_FM@ch4,  $00, $02, $00, $00
    smpsChanHeader  Mus_Invincible_FM@ch5,  $F4, $02, $00, $00
    smpsChanHeader  Mus_Invincible_FM@ch6,  $00, $03, $00, $00
    smpsChanHeader  Mus_Invincible_FM@ch7,  $0C, $04, $00, $00
    smpsChanHeader  Mus_Invincible_FM@ch8,  $00, $08, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsPatchEnv $11
@ch0LoopPoint:
    .db nD2, $0C, nA2, $09, nD3, $09
    smpsChangeVol $05
    .db $06
    smpsChangeVol $FB
    .db nA2, nD3
    smpsTranspose   $FE
    smpsLoop    $00, $02, Mus_Invincible_FM@ch0LoopPoint
    
    smpsTranspose   $04
    smpsJump    Mus_Invincible_FM@ch0LoopPoint

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $02
@ch1LoopPoint:
    .db nA3, $03, nRst
    smpsChangeVol $FF
    .db nA3, nRst
    smpsChangeVol $FF
    .db nA3, $04, nRst, $05, nA3, $01, nRst, $05
    smpsChangeVol $02
    .db nA3, $03, nRst
    smpsChangeVol $FF
    .db nA3, $01, nRst, $02
    smpsChangeVol $FF
    .db nA3, $09, nRst, $03
    smpsChangeVol $02
    smpsTranspose   $FE
    smpsLoop    $00, $02, Mus_Invincible_FM@ch1LoopPoint

    smpsTranspose   $04
    smpsJump    Mus_Invincible_FM@ch1LoopPoint

;   --- CHANNEL 7 (2) DATA ---
@ch7:
    smpsDetune $01
    ;.db nRst, $01
    ; FALL THROUGH

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsFMVoice $02
@ch2LoopPoint:
    .db nC4, $03, nRst
    smpsChangeVol $FF
    .db nC4, nRst
    smpsChangeVol $FF
    .db nC4, $04, nRst, $05, nC4, $01, nRst, $05
    smpsChangeVol $02
    .db nC4, $03, nRst
    smpsChangeVol $FF
    .db nC4, $01, nRst, $02
    smpsChangeVol $FF
    .db nC4, $0A, nRst, $02
    smpsChangeVol $02
    smpsTranspose   $FF
    smpsLoop    $00, $02, Mus_Invincible_FM@ch2LoopPoint

    smpsTranspose   $02
    smpsJump    Mus_Invincible_FM@ch2LoopPoint

;   --- CHANNEL 8 (3) DATA ---
@ch8:
    smpsDetune $01
    .db nRst, $03
    ; FALL THROUGH

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsFMVoice $02
@ch3LoopPoint:
    .db nF4, $03, nRst
    smpsChangeVol $FF
    .db nF4, nRst, nF4, nRst
    smpsChangeVol $FF
    .db nD4, $01, nRst, $02, nF4, $03, nRst
    smpsChangeVol $02
    .db nF4, nRst
    smpsChangeVol $FF
    .db nD4, $01, nRst, $02
    smpsChangeVol $FF
    .db nF4, $01, nRst, $02, nD4, $01, nRst, $02, nF4, $03, nRst
    smpsChangeVol $02
    .db nE4, nRst
    smpsChangeVol $FF
    .db nE4, nRst, nE4, nRst
    smpsChangeVol $FF
    .db nC4, $01, nRst, $02, nE4, $03, nRst
    smpsChangeVol $02
    .db nE4, nRst
    smpsChangeVol $FF
    .db nC4, $01, nRst, $02
    smpsChangeVol $FF
    .db nE4, $01, nRst, $02, nC4, $01, nRst, $02, nE4, $03, nRst
    smpsChangeVol $02
    smpsJump    Mus_Invincible_FM@ch3LoopPoint

@ch4:
    smpsFMVoice $11 ; UPLOAD CUSTOM INSTRUMENT
@ch4LoopPoint:
    .db nD3, $01, nRst, $02, nD3, $01, nRst, $02, nD3, $01, nRst, $02, nD3, $01, nRst, $02
    .db nD3, $01, nRst, $02, nB2, $01, nRst, $02
    smpsChangeVol $02
    .db nB2, $01, nRst, $02
    smpsChangeVol $FE
    .db nD3, $01, nRst, $02
    smpsChangeVol $02
    .db nD3, $01, nRst, $02
    smpsChangeVol $FE
    .db nB2, $01, nRst, $02, nB2, $01, nRst, $02, nD3, $01, nRst, $02, nD3, $01, nRst, $02
    .db nB2, $01, nRst, $02, nD3, $01, nRst, $02
    smpsChangeVol $02
    .db nD3, $01, nRst, $02
    smpsChangeVol $FE
    .db nD3, $01, nRst, $02, nD3, $01, nRst, $02, nD3, $01, nRst, $02, nD3, $01, nRst, $02
    .db nD3, $01, nRst, $02, nB2, $01, nRst, $02
    smpsChangeVol $02
    .db nB2, $01, nRst, $02
    smpsChangeVol $FE
    .db nD3, $01, nRst, $02, nD3, $01, nRst, $02, nB2, $01, nRst, $02, nB2, $01, nRst, $02
    .db nD3, $01, nRst, $02, nD3, $01, nRst, $02, nB2, $01, nRst, $02, nD3, $01, nRst, $02
    smpsChangeVol $02
    .db nD3, $01, nRst, $02
    smpsChangeVol $FE
    smpsJump    Mus_Invincible_FM@ch4LoopPoint

;   --- CHANNEL 5 (0) DATA ---
@ch5:
    smpsDetune $02
    smpsFMVoice $07
    smpsJump    Mus_Invincible_FM@ch0LoopPoint

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsPatchEnv    $09
    smpsVolEnv  $05
@ch6LoopPoint:
    .db nRst, $0C
    .db nBb7, $09, $09
    .db nRst, $06
    .db nBb7
    .db nRst
    smpsJump    Mus_Invincible_FM@ch6LoopPoint
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Level Victory (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_LevelVictory_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $16
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_LevelVictory_FM@ch0,  $00, $01, $00, $00
    smpsChanHeader  Mus_LevelVictory_FM@ch1,  $00, $02, $00, $00
    smpsChanHeader  Mus_LevelVictory_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_LevelVictory_FM@ch3,  $00, $02, $00, $00
    smpsChanHeader  Mus_LevelVictory_FM@ch4,  $F4, $02, $00, $00
    smpsChanHeader  Mus_LevelVictory_FM@ch5,  $00, $06, $00, $00
    smpsChanHeader  Mus_LevelVictory_FM@ch6,  $00, $06, $00, $00
    smpsChanHeader  Mus_LevelVictory_FM@ch7,  $00, $06, $00, $00
    smpsChanHeader  Mus_LevelVictory_FM@ch8, $00, $0F, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsFMVoice $07
    .db nRst, $18, nC2, $05, nRst, $03, nE2, $05, nRst, $03, nG2, $05, nRst, $03, nE2, $15
    .db nRst, $03, nC2, $15, nRst, $1B, nC2, $05, nRst, $03, nEb2, $05, nRst, $03, nGs2, $05
    .db nRst, $03, nEb2, $15, nRst, $03, nC2, $15, nRst, $1B, nD2, $05, nRst, $03, nF2, $05
    .db nRst, $03, nBb2, $05, nRst, $03, nF3, $15, nRst, $03, nD3, $05, nRst, $03, nD3, $05
    .db nRst, $03, nD3, $05, nRst, $03, nC3, $42
    smpsStop

;   --- CHANNEL 5 (1) DATA ---
@ch5:
    .db nRst, $06
    smpsModSetup   $0C, $01, $FF, $03
    ; FALL THROUGH

;   --- CHANNEL 4 (1) DATA ---
@ch4:
    smpsDetune $01
    ; FALL THROUGH

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $07
    .db nG3, $05, nRst, $03, nC4, $05, nRst, $03, nE4, $05, nRst, $03, nG4, $05, nRst, $03
    .db nC5, $05, nRst, $03, nE5, $05, nRst, $03, nG5, $15, nRst, $03, nE5, $15, nRst, $03
    .db nGs3, $05, nRst, $03, nC4, $05, nRst, $03, nEb4, $05, nRst, $03, nGs4, $05, nRst, $03
    .db nC5, $05, nRst, $03, nEb5, $05, nRst, $03, nGs5, $15, nRst, $03, nEb5, $15, nRst, $03
    .db nBb3, $05, nRst, $03, nD4, $05, nRst, $03, nF4, $05, nRst, $03, nBb4, $05, nRst, $03
    .db nD5, $05, nRst, $03, nF5, $05, nRst, $03, nBb5, $15, nRst, $03, nBb5, $05, nRst, $03
    .db nBb5, $05, nRst, $03, nBb5, $05, nRst, $03, nC6, $42
    smpsStop

;   --- CHANNEL 6 (2) DATA ---
@ch6:
    .db nRst, $06
    smpsModSetup   $0C, $01, $FF, $03
    smpsDetune $01
    ; FALL THROUGH

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsFMVoice $07
    .db nE2, $05, nRst, $03, nG2, $05, nRst, $03, nC3, $05, nRst, $03, nE3, $05, nRst, $03
    .db nG3, $05, nRst, $03, nC4, $05, nRst, $03, nE4, $15, nRst, $03, nC4, $15, nRst, $03
    .db nEb2, $05, nRst, $03, nGs2, $05, nRst, $03, nC3, $05, nRst, $03, nEb3, $05, nRst, $03
    .db nGs3, $05, nRst, $03, nC4, $05, nRst, $03, nEb4, $15, nRst, $03, nC4, $15, nRst, $03
    .db nF2, $05, nRst, $03, nBb2, $05, nRst, $03, nD3, $05, nRst, $03, nF3, $05, nRst, $03
    .db nBb3, $05, nRst, $03, nD4, $05, nRst, $03, nF4, $0F, nRst, $09, nF4, $05, nRst, $03
    .db nF4, $05, nRst, $03, nF4, $05, nRst, $03, nE4, $48
    smpsStop

;   --- CHANNEL 7 (3) DATA ---
@ch7:
    .db nRst, $06
    smpsModSetup   $0C, $01, $FF, $03
    smpsDetune $01
    ; FALL THROUGH

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsFMVoice $07
    .db nRst, $08, nE2, $05, nRst, $03, nG2, $05, nRst, $03, nC3, $05, nRst, $03, nE3, $05
    .db nRst, $03, nG3, $05, nRst, $03, nC4, $27, nRst, $11, nFs2, $05, nRst, $03, nGs2, $05
    .db nRst, $03, nC3, $05, nRst, $03, nEb3, $05, nRst, $03, nGs3, $05, nRst, $03, nC4, $15
    .db nRst, $03, nGs3, $15, nRst, $0B, nF2, $05, nRst, $03, nBb2, $05, nRst, $03, nD3, $05
    .db nRst, $03, nF3, $05, nRst, $03, nBb3, $05, nRst, $03, nD4, $15, nRst, $03, nD4, $15
    .db nRst, $03, nC4, $42
    smpsStop

@ch8:
    .db nRst, $60, $60, $60, $48
    smpsStop
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Death (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Death_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $48
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Death_FM@ch0,  $00, $01, $00, $00
    smpsChanHeader  Mus_Death_FM@ch1,  $00, $02, $00, $00
    smpsChanHeader  Mus_Death_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_Death_FM@ch3,  $00, $02, $00, $00
    smpsChanHeader  Mus_Death_FM@ch4,  $00, $01, $00, $00
    smpsChanHeader  Mus_Death_FM@ch5,  $F4, $00, $00, $00
    smpsChanHeader  Mus_Death_FM@ch6,  $00, $06, $00, $00
    smpsChanHeader  Mus_Death_FM@ch1Jump1,  $00, $07, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
@ch0Jump1:
    smpsModSetup    $00, $02, $FF, $03
    smpsFMVoice $02
    smpsVolEnv  $07
    .db nRst, $14, nB4, $05, nRst, $01, nF5, $05, nRst, $07, nF5, $05, nRst, $01, nF5, $07
    .db nRst, $01, nE5, $07, nRst, $01, nD5, $07, nRst, $01, nC5, $10
    smpsStop

;   --- CHANNEL 1/7 DATA ---
@ch1:
    smpsDetune $01
@ch1Jump1:
    smpsFMVoice $02
    smpsVolEnv  $07
    .db nRst, $14, nG4, $05, nRst, $01, nD5, $05, nRst, $07, nD5, $05, nRst, $01, nD5, $07
    .db nRst, $01, nC5, $07, nRst, $01, nB4, $07, nRst, $01, nG4, $05, nRst, $01, nE4, $05
    .db nRst, $07, nE4, $05, nRst, $01, nC4, $0A
    smpsStop

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsFMVoice $0E
    .db nRst, $14, nG2, $0A, nRst, $0E, nG2, $07, nRst, $01, nA2, $07, nRst, $01, nB2, $07
    .db nRst, $01, nC3, $0A, nRst, $02, nG2, $0A, nRst, $02, nC2, $0A
    smpsStop

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsFMVoice $11 ; UPLOAD CUSTOM INSTRUMENT
    .db nRst, $14, nG2, $05, nRst, $01, nG2, $05, nRst, $07, nG2, $05, nRst, $01, nG2, $07
    .db nRst, $01, nG2, $07, nRst, $01, nG2, $07, nRst, $01, nG2, $05, nRst, $01, nG2, $05
    .db nRst, $07, nG2, $05, nRst, $01, nG2, $0A
    smpsStop

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsFMVoice $02
@ch4Jump1:
    smpsModSetup    $00, $01, $1E, $FF
    .db nF5, $02, nFs5, nG5
    smpsChangeVol $0B
    .db nF5
    smpsStop

;   --- CHANNEL 5 (4) DATA ---
@ch5:
    smpsDetune $01
    smpsFMVoice $09
    smpsJump    Mus_Death_FM@ch4Jump1

;   --- CHANNEL 6 (0) DATA ---
@ch6:
    smpsDetune $01
    smpsJump    Mus_Death_FM@ch0Jump1
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Game Over (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_GameOver_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $7A
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_GameOver_FM@ch0,  $00, $01, $00, $00
    smpsChanHeader  Mus_GameOver_FM@ch1,  $00, $01, $00, $00
    smpsChanHeader  Mus_GameOver_FM@ch2,  $00, $01, $00, $00
    smpsChanHeader  Mus_GameOver_FM@ch3,  $00, $01, $00, $00
    smpsChanHeader  Mus_GameOver_FM@ch4,  $0C, $03, $00, $00
    smpsChanHeader  Mus_GameOver_FM@ch5,  $00, $08, $00, $00
    smpsChanHeader  Mus_GameOver_FM@ch6,  $00, $08, $00, $00
    smpsChanHeader  Mus_GameOver_FM@ch7,  $00, $08, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsFMVoice $07
    .db nG2, $05, nRst, $0D, nE2, $05, nRst, $0D, nC2, $0A, nRst, $02, nF2, $15, nRst, $03
    .db nCs2, $21, nRst, $03, nC2, ;$4F
    smpsNoAtk
    .db $2A
    smpsJump    Mus_GameOver_FM@chAllFadeOut

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $07
@ch1Jump1:
    .db nC5, $05, nRst, $0D, nG4, $05, nRst, $0D, nE4, $0A, nRst, $02, nA4, $07, nRst, $01
    .db nB4, $07, nRst, $01, nA4, $07, nRst, $01, nGs4, $0A, nRst, $02, nBb4, $0A, nRst, $02
    .db nGs4, $0A, nRst, $02, nG4, ;$4F
    smpsNoAtk
    .db $2A
    smpsJump    Mus_GameOver_FM@chAllFadeOut

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsFMVoice $07
    .db nG4, $05, nRst, $0D, nE4, $05, nRst, $0D, nC4, $0A, nRst, $02, nC4, $07, nRst, $01
    .db nC4, $07, nRst, $01, nC4, $07, nRst, $01, nC4, $0A, nRst, $02, nC4, $0A, nRst, $02
    .db nC4, $0A, nRst, $02, nC4, ;$4F
    smpsNoAtk
    .db $2A
    smpsJump    Mus_GameOver_FM@chAllFadeOut

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsFMVoice $07
    .db nE4, $05, nRst, $0D, nC4, $05, nRst, $0D, nG3, $0A, nRst, $02, nE4, $15, nRst, $03
    .db nEb4, $21, nRst, $03, nE4, $05, nRst, $01, nD4, $05, nRst, $01, nE4, ;$43
    smpsNoAtk
    .db $1E
    smpsJump    Mus_GameOver_FM@chAllFadeOut

;   --- CHANNEL 4 (1) DATA ---
@ch4:
    smpsDetune $01
    smpsFMVoice $0C
    smpsJump    Mus_GameOver_FM@ch1Jump1

;   --- CHANNEL 5 (1) DATA ---
@ch5:
    smpsDetune $01
    .db nRst, $06
    smpsJump    Mus_GameOver_FM@ch1

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsDetune $01
    .db nRst, $06
    smpsJump    Mus_GameOver_FM@ch2

;   --- CHANNEL 7 DATA ---
@ch7:
    smpsDetune $01
    .db nRst, $06
    smpsJump    Mus_GameOver_FM@ch3

;   --- CHANNEL FADE OUT DATA ---
@chAllFadeOut:
    smpsNoAtk
    smpsChangeVol   $01
    .db $03
    smpsLoop    $00, $0B, Mus_GameOver_FM@chAllFadeOut
    smpsNoAtk
    .db $01
    smpsStop
.ENDS

;   ----------------------------------

.SECTION "MUS Data - World Victory (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_WorldVictory_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $6A
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_WorldVictory_FM@ch0,  $00, $02, $00, $00
    smpsChanHeader  Mus_WorldVictory_FM@ch1,  $00, $01, $00, $00
    smpsChanHeader  Mus_WorldVictory_FM@ch2,  $00, $01, $00, $00
    smpsChanHeader  Mus_WorldVictory_FM@ch3,  $00, $03, $00, $00
    smpsChanHeader  Mus_WorldVictory_FM@ch4,  $00, $00, $00, $00
    smpsChanHeader  Mus_WorldVictory_FM@ch5,  $0C, $02, $00, $00
    smpsChanHeader  Mus_WorldVictory_FM@ch6,  $00, $00, $00, $00
    smpsChanHeader  Mus_WorldVictory_FM@ch7,  $00, $04, $00, $00
    smpsChanHeader  Mus_WorldVictory_FM@ch8,  $00, $07, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsFMVoice $07
    .db nC3, $1F, nRst, $05, nC3, nRst, $01, nC3, nRst, $02, nC3, $01, nRst, $02, nC3, $03
    .db nRst, nC3, $05, nRst, $01, nC3, $05, nRst, $01, nC3, $05, nRst, $01, nCs3, $1F, nRst
    .db $05, nCs3, nRst, $01, nCs3, nRst, $02, nCs3, $01, nRst, $02, nCs3, $03, nRst, nCs3, $05
    .db nRst, $01, nCs3, $05, nRst, $01, nCs3, $05, nRst, $01, nBb3, $05, nRst, $01, nG3, $05
    .db nRst, $01, nEb3, $05, nRst, $01, nBb3, $05, nRst, $01, nG3, $05, nRst, $01, nEb3, $05
    .db nRst, $01, nBb3, $05, nRst, $01, nBb3, nRst, $02, nBb3, $01, nRst, $02, nBb3, $05, nRst
    .db $01, nC4, $0A, nRst, $02, nC4, $0A, nRst, $02, nC4, $0A, nRst, $02, nD4, $3A
    smpsStop

;   --- CHANNEL 7 (1) DATA ---
@ch7:
    .db nRst, $05
    ; FALL THROUGH

;   --- CHANNEL 5 (1) DATA ---
@ch5:
    smpsDetune $01
    .db nRst, $01
    ; FALL THROUGH

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $07
    .db nC4, $04, nRst, $02, nG3, $04, nRst, $02, nE3, $04, nRst, $02, nC4, $04, nRst, $02
    .db nG3, $04, nRst, $02, nE3, $04, nRst, $02, nC4, $18, nRst, $0C, nCs4, $04, nRst, $02
    .db nGs3, $04, nRst, $02, nF3, $04, nRst, $02, nCs4, $04, nRst, $02, nGs3, $04, nRst, $02
    .db nF3, $04, nRst, $02, nCs4, $18, nRst, $0C, nEb4, $04, nRst, $02, nBb3, $04, nRst, $02
    .db nG3, $04, nRst, $02, nEb4, $04, nRst, $02, nBb3, $04, nRst, $02, nG3, $04, nRst, $02
    .db nEb4, $0D, nRst, $05, nF4, $07, nRst, $05, nF4, $07, nRst, $05, nF4, $07, nRst, $05
    .db nG4, $3C
    smpsStop

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsFMVoice $07
    .db nG4, $04, nRst, $02, nE4, $04, nRst, $02, nC4, $04, nRst, $02, nG4, $04, nRst, $02
    .db nE4, $04, nRst, $02, nC4, $04, nRst, $02, nG4, $18, nRst, $0C, nGs4, $04, nRst, $02
    .db nF4, $04, nRst, $02, nCs4, $04, nRst, $02, nGs4, $04, nRst, $02, nF4, $04, nRst, $02
    .db nCs4, $04, nRst, $02, nGs4, $18, nRst, $0C, nBb4, $04, nRst, $02, nG4, $04, nRst, $02
    .db nEb4, $04, nRst, $02, nBb4, $04, nRst, $02, nG4, $04, nRst, $02, nEb4, $04, nRst, $02
    .db nBb4, $0D, nRst, $05, nA4, $07, nRst, $05, nA4, $07, nRst, $05, nA4, $07, nRst, $05
    .db nB4, $3C
    smpsStop

;   --- CHANNEL 8 (3) DATA ---
@ch8:
    smpsDetune $01
    .db nRst, $06
    ; FALL THROUGH

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsFMVoice $07
    .db nE4, $04, nRst, $02, nC4, $04, nRst, $02, nG3, $04, nRst, $02, nE4, $04, nRst, $02
    .db nC4, $04, nRst, $02, nG3, $04, nRst, $02, nE4, $06, $01, nRst, $02, nE4, $01, nRst
    .db $02, nE4, $06, $04, nRst, $02, nE4, $04, nRst, $02, nE4, $04, nRst, $02, nF4, $04
    .db nRst, $02, nCs4, $04, nRst, $02, nGs3, $04, nRst, $02, nF4, $04, nRst, $02, nCs4, $04
    .db nRst, $02, nGs3, $04, nRst, $02, nF4, $04, nRst, $02, nF4, $01, nRst, $02, nF4, $01
    .db nRst, $02, nF4, $04, nRst, $02, nF4, $04, nRst, $02, nF4, $04, nRst, $02, nF4, $04
    .db nRst, $02, nG4, $04, nRst, $02, nEb4, $04, nRst, $02, nBb3, $04, nRst, $02, nG4, $04
    .db nRst, $02, nEb4, $04, nRst, $02, nBb3, $04, nRst, $02, nG4, $04, nRst, $02, nG4, $01
    .db nRst, $02, nG4, $01, nRst, $02, nG4, $04, nRst, $02
    smpsDetune $FF
    .db nA4, $07, nRst, $05, nA4, $07, nRst, $05, nA4, $07, nRst, $05, nB4, $3C
    smpsStop

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsFMVoice $12 ; UPLOAD CUSTOM INSTRUMENT
    .db nBb2, $24, $24, $24, $24, $24, $12, $0C, $0C, $0C, $04, $04, $04, $04, $04, $04
    .db $04, $04, $04, $30
    smpsStop

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsFMVoice $00
    .db nRst, $7F, $6D, nBb2, $04, $04, $04, $04, $04, $04, $04, $04, $04, $30
    smpsStop
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Cloud/Bonus (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Cloud_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $38
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Cloud_FM@ch0,  $00, $03, $00, $00
    smpsChanHeader  Mus_Cloud_FM@ch1,  $00, $02, $00, $00
    smpsChanHeader  Mus_Cloud_FM@ch2,  $00, $01, $00, $00
    smpsChanHeader  Mus_Cloud_FM@ch3,  $00, $03, $00, $00
    smpsChanHeader  Mus_Cloud_FM@ch4,  $00, $01, $00, $00
    smpsChanHeader  Mus_Cloud_FM@ch5,  $00, $04, $00, $00
    smpsChanHeader  Mus_Cloud_FM@ch6,  $00, $08, $00, $00
    smpsChanHeader  Mus_Cloud_FM@ch7,  $00, $02, $00, $00
    smpsChanHeader  Mus_Cloud_FM@ch8,  $00, $01, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsFMVoice $07
    smpsModSetup    $10, $01, $FE, $03
    smpsCall    Mus_Cloud_FM@ch0Call1
    .db nB5, $1A, nRst, $04
    smpsPatchEnv $0D
    smpsChangeVol $FE
@ch0LoopPoint:
@ch0Jump2:
    .db nC4, $0C
    smpsChangeVol $05
    .db $06, nRst, $03
    smpsChangeVol $FB
    .db nG3, $04, nRst, $02
    smpsChangeVol $05
    .db nG3, $04, nRst, $05
    smpsChangeVol $FB
    .db nE3, $0C, nA3, $0C
    smpsChangeVol $05
    .db $06, nRst
    smpsChangeVol $FB
    .db nA3, $09, nB3, $01, nRst, $02, nA3, $0C, nG3, $0C, $0C, $0C, $0C, $09
    smpsChangeVol $03
    .db $03, nRst, $09, nG3, $01, nRst, $0B
    smpsChangeVol $FD
    .db nG3, $0F, nA3, $0C
    smpsChangeVol $05
    .db $06, nRst, $03
    smpsChangeVol $FB
    .db nE3, nRst
    smpsChangeVol $05
    .db nE3, nRst, $06
    smpsChangeVol $FB
    .db nC3, $0C, nD3, $0C
    smpsChangeVol $05
    .db $06, nRst
    smpsChangeVol $FB
    .db nD3, $09, nE3, $01, nRst, $02, nF3, $0C, nG3, $0C
    smpsChangeVol $05
    .db $06, nRst, $03
    smpsChangeVol $FB
    .db nD3, nRst
    smpsChangeVol $05
    .db nD3, nRst, $06
    smpsChangeVol $FB
    .db nB2, $0C, nC3, $0C
    smpsChangeVol $05
    .db $06, nRst
    smpsChangeVol $FB
    .db nC3, $09, nD3, $03, nE3, $0C, nFs3, $12, nG3, nA3, $0C, nD3, $12, nE3, nFs3, $0C
    .db nG3, $0C
    smpsChangeVol $05
    .db $06, nRst
    smpsChangeVol $FB
    .db nG3, $09
    smpsChangeVol $03
    .db nA3, $01, nRst, $02
    smpsChangeVol $FD
    .db nG3, $09, nF3, $01, nRst, $02
    smpsChangeVol $05
    .db nG3, $03, nF3, $01, nRst, $05
    smpsChangeVol $FB
    .db nE3, $03, nRst
    smpsChangeVol $05
    .db nE3, nRst
    smpsChangeVol $FD
    .db nD3, nRst
    smpsChangeVol $03
    .db nD3, nRst
    smpsChangeVol $FB
    .db nG3, $0F
    ;smpsChangeVol $02
    smpsJump    Mus_Cloud_FM@ch0LoopPoint

@ch0Call1:
    .db nF5, $0A, nRst, $02, nF5, $0A, nRst, $02, nG5, $0A, nRst, $02, nG5, $0A, nRst, $02
    .db nA5, $05, nRst, $01, nA5, $05, nRst, $07
    smpsRet

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $0E
    .db nD2, $0A, nRst, $02, nD2, $0A, nRst, $02, nE2, $0A, nRst, $02, nE2, $0A, nRst, $02
    .db nF2, $05, nRst, $01, nF2, $05, nRst, $07, nG2, $1A, nRst, $04
@ch1LoopPoint:
    .db nC2, $0A, nRst, $0B, nC2, $02, nRst, $01, nE2, $0A, nRst, $0B, nE2, $02, nRst, $01
    .db nD2, $0A, nRst, $0E, nG2, $0A, nRst, $02, nF2, $0A, nRst, $02, nE2, $0A, nRst, $02
    .db nE2, $0A, nRst, $02, nEb2, $0A, nRst, $02, nEb2, $0A, nRst, $02, nD2, $07, nRst, $02
    .db nD2, nRst, $0A, nG2, $02, nRst, $0A, nG2, $0D, nRst, $02, nF2, $0A, nRst, $0B, nF2
    .db $02, nRst, $01, nF2, $0A, nRst, $0B, nF2, $02, nRst, $01, nF2, $0A, nRst, $0B, nF2
    .db $02, nRst, $01, nF2, $0A, nRst, $0B, nF2, $02, nRst, $01, nE2, $0A, nRst, $0B, nE2
    .db $02, nRst, $01, nE2, $0A, nRst, $0B, nE2, $02, nRst, $01, nE2, $0A, nRst, $0B, nE2
    .db $02, nRst, $01, nE2, $0A, nRst, $0B, nE2, $02, nRst, $01, nD2, $0A, nRst, $0B, nE2
    .db $02, nRst, $0D, nFs2, $0A, nRst, $02, nD2, $0A, nRst, $32, nG2, $0A, nRst, $0E, nG2
    .db $0A, nRst, $0E, nG2, $0A, nRst, $0E, nG2, $0A, nRst, $02
    smpsJump    Mus_Cloud_FM@ch1LoopPoint

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsVolEnv $07
    smpsFMVoice $02
    .db nC5, $0A, nRst, $02, nC5, $0A, nRst, $02, nD5, $0A, nRst, $02, nD5, $0A, nRst, $02
    .db nF5, $05, nRst, $01, nF5, $05, nRst, $07, nG5, $1A, nRst, $04
    smpsVolEnv $08
    smpsChangeVol $02
@ch2LoopPoint:
    .db nE5, $0C, $09, $03, $0C, $09, $03, nF5, $0C, $09, $03, $0C, $09, $03, nD5, $0C
    .db $0C, nCs5, $0C, $0C, nC5, $09, $03, nRst, $09, nC5, $03, nRst, $09, nB4, $0F, nE5
    .db $0C, $09, $03, $0C, $09, $03, nD5, $0C, $09, $03, $0C, $09, $03, $0C, $09, $03
    .db $0C, $09, $03, nC5, $0C, $09, $03, $0C, $09, $03, nD5, $12, nE5, $12, $0C, nA4
    .db $12, nC5, nD5, $0C, nRst, nF5, nRst, nF5, nRst, nF5, nRst, nF5
    smpsJump    Mus_Cloud_FM@ch2LoopPoint

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsFMVoice $02
    .db nRst, $60
    smpsVolEnv $08
@ch3LoopPoint:
    .db nB4, $0C, $09, $03, $0C, $09, $03, nC5, $0C, $09, $03, nB4, $0C, $09, $03, $0C
    .db $0C, nBb4, $0C, $0C, nA4, $09, $03, nRst, $09, nA4, $03, nRst, $09, nG4, $0F, nC5
    .db $0C, $09, $03, $0C, $09, $03, nB4, $0C, $09, $03, $0C, $09, $03, $0C, $09, $03
    .db $0C, $09, $03, nG4, $0C, $09, $03, $0C, $09, $03, nA4, $12, nB4, nC5, $0C, nFs4
    .db $12, nG4, nA4, $0C, nRst, nC5, nRst, nC5, nRst, nC5, nRst, nC5
    smpsJump    Mus_Cloud_FM@ch3LoopPoint

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsVolEnv $07
    smpsFMVoice $02
    .db nA4, $0A, nRst, $02, nA4, $0A, nRst, $02, nB4, $0A, nRst, $02, nB4, $0A, nRst, $02
    .db nC5, $05, nRst, $01, nC5, $05, nRst, $07, nD5, $1A, nRst, $04
    smpsVolEnv $08
    smpsChangeVol $02
@ch4LoopPoint:
    smpsDetune $00
    .db nRst, $7F, $11
    .db nF5, $09, $03, nRst, $09, nF5, $03, nRst, $09, nF5, $0F
    smpsDetune $01
    smpsChangeVol $02
    .db nC5, $0C, $09, $01, nRst, $02, nC5, $0C, $09, $01, nRst, $02, nB4, $0C, $09, $01
    .db nRst, $02, nB4, $0C, $09, $01, nRst, $02, nB4, $0C, $09, $03, $0C, $09, $01, nRst
    .db $02, nG4, $0C, $09, $03, $0C, $09, $01, nRst, $02, nA4, $12, nB4, nC5, $0C, nFs4
    .db $12, nG4, nA4, $0C, nRst, nC5, nRst, nC5, nRst, nC5, nRst, nC5
    smpsChangeVol $FE
    smpsJump    Mus_Cloud_FM@ch4LoopPoint

;   --- CHANNEL 5 DATA ---
@ch5:
    smpsDetune $FF
    smpsFMVoice $0C
    smpsCall    Mus_Cloud_FM@ch0Call1
    .db nB5, $1A, nRst, $04
    smpsChangeVol $FE
    smpsTranspose   $0C
    smpsJump    Mus_Cloud_FM@ch0Jump2

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsDetune $01
    smpsFMVoice $07
    smpsModSetup    $10, $01, $FE, $03
    .db nRst, $06
    smpsCall    Mus_Cloud_FM@ch0Call1
    .db nB5, $18
    smpsPatchEnv $0D
    smpsChangeVol $F9
    smpsTranspose   $0C
    smpsJump    Mus_Cloud_FM@ch0Jump2

;   --- CHANNEL 7 DATA ---
@ch7:
    .db nRst, $60
    smpsVolEnv  $03
    smpsPatchEnv    $13
@ch7LoopPoint:
    smpsCall    Mus_Cloud_FM@ch7Call1
    ;
    .db nC4, $0C, $0C, $0C, $0C, $09, $03
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $09
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $03
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $09
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $03, $0C
    ;
    smpsCall    Mus_Cloud_FM@ch7Call1
    ;
    smpsCall    Mus_Cloud_FM@ch7Call1
    ;
@ch7Loop1:
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $0C, $0C, $0C
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $09
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03
    smpsLoop    $00, $02, Mus_Cloud_FM@ch7Loop1
    ;
    .db nC3, $0C
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $09, $03
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $0C
    smpsJump    Mus_Cloud_FM@ch7LoopPoint

@ch7Call1:
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $0C
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $09
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03, $0C
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $09
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03, $09
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $03, $0C
    smpsRet

;   --- CHANNEL 8 DATA ---
@ch8:
    smpsPatchEnv    $0F
    smpsFMVoice $10 ; UPLOAD CUSTOM INSTRUMENT
    smpsModSetup    $00, $01, $E4, $FF
    .db nRst, $60
@ch8LoopPoint:
    smpsCall    Mus_Cloud_FM@ch8Call1
    ;
    .db nD2, $0C, $0C, $0C, $0C, $09, $03
    .db nRst, $09
    .db nD2, $03
    .db nRst, $09
    .db nD2, $03, $0C
    ;
    smpsCall    Mus_Cloud_FM@ch8Call1
    ;
    smpsCall    Mus_Cloud_FM@ch8Call1
    ;
@ch8Loop1:
    .db nRst, $0C, $0C, $0C
    .db nD2, $09
    .db nRst, $03
    smpsLoop    $00, $02, Mus_Cloud_FM@ch8Loop1
    ;
    .db nRst, $0C
    .db nD2
    .db nRst
    .db nD2
    .db nRst
    .db nD2
    .db nRst, $09, $03
    .db nD2, $0C
    smpsJump    Mus_Cloud_FM@ch8LoopPoint

@ch8Call1:
    .db nRst, $0C
    .db nD2, $09
    .db nRst, $03, $0C
    .db nD2
    .db nRst
    .db nD2, $09
    .db nRst, $03, $09
    .db nD2, $03, $0C
    smpsRet
.ENDS


;   ----------------------------------

.SECTION "MUS Data - Bowser (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Bowser_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $8F
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Bowser_FM@ch0,  $00, $02, $00, $00
    smpsChanHeader  Mus_Bowser_FM@ch1,  $00, $01, $00, $00
    smpsChanHeader  Mus_Bowser_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_Bowser_FM@ch3,  $00, $02, $00, $00
    smpsChanHeader  Mus_Bowser_FM@ch4,  $00, $02, $00, $00
    smpsChanHeader  Mus_Bowser_FM@ch5,  $00, $07, $00, $00
    smpsChanHeader  Mus_Bowser_FM@ch6,  $00, $05, $00, $00
    smpsChanHeader  Mus_Bowser_FM@ch7,  $00, $02, $00, $00
    smpsChanHeader  Mus_Bowser_FM@ch8,  $00, $01, $00, $00

;   --- CHANNEL 5 (0) DATA ---
@ch5:
    smpsDetune $01
    .db nRst, $06

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsModSetup    $10, $01, $FF, $03
    smpsPatchEnv $15
    .db nRst, $0C
    .db nE3, nG3, nA3
    
    ;smpsChangeVol   $FF
    smpsVolEnv $09
    .db nBb3, $30
    smpsVolEnv $00
@ch0LoopPoint:
    .db nRst, $27
    smpsPatchEnv $00
    smpsFMVoice $07
    smpsChangeVol $01
    .db nE4, $02, nRst, $01
    smpsChangeVol $FF
    .db nA4, $02, nRst, $01, nE5, $02, nRst, $01, nF5, $06, nRst, $03, nF5, $02, nRst, $07
    .db nG5, $09, nRst, $03, nF5, $04, nRst, $02, nE5, $04, nRst, $02, nD5, $04, nRst, $02
    .db nE5, nRst, $01, nC5, $02, nRst, $04, nE5, $02, nRst, $0D, nE6, $02, nRst, $01, nC6
    .db $02, nRst, $04, nE6, $02, nRst, $0D, nF5, $02, nRst, $01, nF5, $02, nRst, $04, nF5
    .db $1D, nRst, $0A
    smpsJump    Mus_Bowser_FM@ch0LoopPoint

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $0E
    .db nRst, $0C, nA2, nC3, nD3

    ;smpsChangeVol   $FF
    smpsVolEnv $09
    .db nEb3, $30
    smpsVolEnv $00

    ;smpsChangeVol   $01
@ch1LoopPoint:
    smpsPatchEnv $11
    ;smpsChangeVol $FF
    .db nA2, $0C, nE2, nA2, $09, nC3, $03
    smpsChangeVol $05
    .db $03
    smpsChangeVol $FB
    .db $03, nB2, nA2, nBb2, $0C, nF2, nBb2, $09, nF3, $03
    smpsChangeVol $05
    .db $03
    smpsChangeVol $FB
    .db nCs3, nC3, nBb2, nA2, $0C, nE2, nA2, $09, nC3, $03
    smpsChangeVol $05
    .db $03
    smpsChangeVol $FB
    .db $03, nB2, nA2, nBb2, $0C, nF2, nBb2, $09, nF3, $03
    smpsChangeVol $05
    .db $03
    smpsChangeVol $FB
    .db nCs3, nC3, nBb2
    ;smpsChangeVol $01
    smpsJump    Mus_Bowser_FM@ch1LoopPoint

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsModSetup    $10, $01, $FF, $03
    smpsPatchEnv $15
    .db nRst, $0C
    .db nC3, nE3, nFs3

    ;smpsChangeVol $FF
    smpsVolEnv $09
    .db nG3, $30
    smpsVolEnv $00
    smpsStop

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsModSetup    $10, $01, $FF, $03
    smpsPatchEnv $15
    .db nRst, $0C
    .db nG2, nC3, nD3

    ;smpsChangeVol $FF
    smpsVolEnv $09
    .db nEb3, $30
    smpsVolEnv $00

    smpsPatchEnv $00
    ;smpsChangeVol $01 ;$02
    smpsFMVoice $02
    smpsModOff
@ch3LoopPoint:
    .db nRst, $06
    .db nE4, $06, $09, $03, nRst, nE4, nRst, nE4, $03, $06, $06, nRst, nF4, $06, $09, $03
    .db nRst, nF4, nRst, nF4, nG4, $06, nF4, nRst, nE4, $06, $09, $03, nRst, nE4, nRst, nE4
    .db $03, $06, $06, nRst, nF4, $06, $09, $03, nRst, nF4, nRst, nF4, nG4, $06, nF4
    smpsJump    Mus_Bowser_FM@ch3LoopPoint

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsVolEnv $00
    smpsFMVoice $02
    .db nRst, $60
@ch4LoopPoint:
    .db nRst, $06, nC4, $06, $09, $03, nRst, nC4, nRst, nC4, $03, $06, $06, nRst, nCs4, $06
    .db $09, $03, nRst, nCs4, nRst, nCs4, $03, $06, $06, nRst, nC4, $06, $09, $03, nRst, nC4
    .db nRst, nC4, $03, $06, $06, nRst, nCs4, $06, $09, $03, nRst, nCs4, nRst, nCs4, $03, $06
    .db $06
    smpsJump    Mus_Bowser_FM@ch4LoopPoint

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsPatchEnv $14
    smpsVolEnv $04
    .db nRst, $30
    .db nEb4, $01, nRst
    smpsChangeVol $FF
    .db nEb4, nRst
    smpsChangeVol $FF
    .db nEb4, nRst, nEb4, nRst
    smpsChangeVol $FF
    .db nEb4, nRst, nEb4, nRst
    smpsChangeVol $FF
    .db nEb4, nRst, nEb4, nRst
    smpsChangeVol $FF
    .db nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst
    .db nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst, nEb4, nRst
    smpsChangeVol $02
@ch6LoopPoint:
    .db nG4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01, nB4, $02, nRst, $01
    .db nG4, $02, nRst, $01, nB4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01
    .db nG4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01
    .db nB4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01
    smpsJump    Mus_Bowser_FM@ch6LoopPoint

;   --- CHANNEL 7 DATA ---
@ch7:
    smpsPatchEnv $13
    smpsVolEnv $03
    .db nRst, $0C, nRst, $54
@ch7LoopPoint:
    smpsCall    Mus_Bowser_FM@ch7Call1
    smpsCall    Mus_Bowser_FM@ch7Call1
    smpsCall    Mus_Bowser_FM@ch7Call1
    ;
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $06, $06
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $06
    smpsChangeVol $03
    .db nC4, $03
    smpsChangeVol $FF
    .db $03, $03
    smpsChangeVol $FF
    .db $03, $03
    smpsChangeVol $FF
    .db $03, $03
    smpsJump    Mus_Bowser_FM@ch7LoopPoint

@ch7Call1:
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $06, $06
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $06
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsRet

;   --- CHANNEL 8 DATA ---
@ch8:
    smpsPatchEnv    $0F
    smpsFMVoice $10 ; UPLOAD CUSTOM INSTRUMENT
    smpsModSetup    $00, $01, $E4, $FF
    .db nRst, $0C, nRst, $54
@ch8LoopPoint:
    smpsCall    Mus_Bowser_FM@ch8Call1
    smpsCall    Mus_Bowser_FM@ch8Call1
    smpsCall    Mus_Bowser_FM@ch8Call1
    ;
    .db nRst, $06, $06
    .db nD2
    .db nRst, $03
    .db nD2, $06
    smpsChangeVol $03
    .db nD2, $03
    smpsChangeVol $FF
    .db $03, $03
    smpsChangeVol $FF
    .db $03, $03
    smpsChangeVol $FF
    .db $03, $03
    smpsJump    Mus_Bowser_FM@ch8LoopPoint

@ch8Call1:
    .db nRst, $06, $06
    .db nD2
    .db nRst, $03
    .db nD2
    .db nRst
    .db nD2
    .db nRst, $06
    .db nD2
    .db nRst, $03
    .db nD2
    smpsRet
.ENDS

;   ----------------------------------

.SECTION "MUS Data - Final Bowser (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_FinalBowser_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $8F
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_FinalBowser_FM@ch0,  $00, $02, $00, $00
    smpsChanHeader  Mus_FinalBowser_FM@ch1,  $00, $02, $00, $00
    smpsChanHeader  Mus_FinalBowser_FM@ch2,  $00, $02, $00, $00
    smpsChanHeader  Mus_FinalBowser_FM@ch3,  $00, $02, $00, $00
    smpsChanHeader  Mus_FinalBowser_FM@ch4,  $00, $00, $00, $00
    smpsChanHeader  Mus_FinalBowser_FM@ch5,  $00, $02, $00, $00
    smpsChanHeader  Mus_FinalBowser_FM@ch6,  $00, $0F, $00, $00
    smpsChanHeader  Mus_FinalBowser_FM@ch7,  $00, $02, $00, $00
    smpsChanHeader  Mus_FinalBowser_FM@ch8,  $00, $05, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsModSetup    $10, $01, $FE, $03
    smpsPatchEnv $15
    .db nG3, $09, nBb3, $03, nRst, $06

    ;smpsChangeVol $FF
    smpsVolEnv $09
    .db nA3, $24
    smpsVolEnv $00
    ;smpsChangeVol $01

    .db $06, $06, $06, $03, $03, nRst, nA3, nRst, nGs3, $09

    smpsChangeVol $01
@ch0LoopPoint:
    smpsPatchEnv $15
    .db nRst, $0C, nD4, $09, nCs4, $03, nRst, $0C, nA3, $09
    
    smpsModSetup    $10, $01, $FC, $FF
    smpsVolEnv $0A
    .db nG3, $18
    smpsVolEnv $00
    smpsModOff

    smpsChangeVol $06
    .db nG2, $01, nRst, $26
    smpsChangeVol $FA
    .db nD4, $09, nCs4, $03, nRst, $0C, nA3, $09

    smpsModOn
    smpsVolEnv $0A
    .db nB3, $18
    smpsVolEnv $00
    smpsModOff

    smpsChangeVol $06
    .db nB2, $01, nRst, $1A
    ;
    smpsPatchEnv $00
    smpsFMVoice $07
    smpsChangeVol $FB
    .db nFs4, $01, nRst, $02, nFs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs4, $03, nRst
    smpsChangeVol $03
    .db nFs4, $01, nRst, $02, nFs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs4, $03, nRst, nFs4, nRst, nEb4, nRst
    smpsChangeVol $03
    .db nE4, $01, nRst, $02, nE4, $01, nRst, $02
    smpsChangeVol $FF
    .db nE4, $01, nRst, $02
    smpsChangeVol $FF
    .db nE4, $01, nRst, $02
    smpsChangeVol $FF
    .db nE4, $03, nRst
    smpsChangeVol $03
    .db nE4, $01, nRst, $02, nE4, $01, nRst, $02
    smpsChangeVol $FF
    .db nE4, $01, nRst, $02
    smpsChangeVol $FF
    .db nE4, $01, nRst, $02
    smpsChangeVol $FF
    .db nE4, $03, nRst, nE4, nRst, nCs4, nRst

    smpsChangeVol $02
    smpsJump    Mus_FinalBowser_FM@ch0LoopPoint

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsFMVoice $0E
    .db nA2, $09, nC3, $03, nRst, $06
    
    ;smpsChangeVol $FF
    smpsVolEnv $09
    .db nB2, $24
    smpsVolEnv $00
    ;smpsChangeVol $01
    
    .db $06, $06, $06, $03, $03, nRst, nB2, nRst, nBb2, $09

    smpsPatchEnv $11
    smpsChangeVol $FF
@ch1LoopPoint:
    .db nA2, $09, nE2, $03, nRst, $06, nD3, $0C, nCs3, $06, nD3, $03, nE4, nE2, $06, nF2, $09
    .db nC2, $03, nRst, $06, nBb2, $0C, nA2, $06, nBb2, $03, nC3, nC2, $06, nA2, $09, nE2
    .db $03, nRst, $06, nD3, $0C, nCs3, $06, nD3, $03, nE4, nE2, $06, nF2, $09, nC2, $03
    .db nRst, $06, nBb2, $0C, nA2, $06, nBb2, $03, nC3, nC2, $06, nEb3, $01, nRst, $02, nEb3
    .db $01, nRst, $02, nEb3, $01, nRst, $02, nEb3, $01, nRst, $02, nEb3, $03, nRst, nEb3, $01
    .db nRst, $02, nEb3, $01, nRst, $02, nEb3, $01, nRst, $02, nEb3, $01, nRst, $02, nEb3, $03
    .db nRst, nEb3, nRst, nC3, nRst, nCs3, $01, nRst, $02, nCs3, $01, nRst, $02, nCs3, $01, nRst
    .db $02, nCs3, $01, nRst, $02, nCs3, $03, nRst, nCs3, $01, nRst, $02, nCs3, $01, nRst, $02
    .db nCs3, $01, nRst, $02, nCs3, $01, nRst, $02, nCs3, $03, nRst, nCs3, nRst, nB2, nRst
    smpsJump    Mus_FinalBowser_FM@ch1LoopPoint

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsModSetup    $10, $01, $FE, $03
    smpsPatchEnv $15
    .db nD3, $09, nF3, $03, nRst, $06

    ;smpsChangeVol $FF
    smpsVolEnv $09
    .db nE3, $24
    smpsVolEnv $00
    ;smpsChangeVol $01
    
    .db $06, $06, $06, $03, $03, nRst, nE3, nRst, nEb3, $09

    smpsChangeVol $01
@ch2LoopPoint:
    smpsDetune $00
    smpsPatchEnv $15
    .db nRst, $0C, nA3, $09, $03, nRst, $0C, nE3, $09
    
    smpsModSetup    $10, $01, $FC, $FF
    smpsVolEnv $0A
    .db nD3, $18
    smpsVolEnv $00
    smpsModOff

    smpsChangeVol $06
    .db nD2, $03, nRst, $24
    smpsChangeVol $FA
    .db nA3, $09, $03, nRst, $0C, nE3, $09
    
    smpsModOn
    smpsVolEnv $0A
    .db nFs3, $18
    smpsVolEnv $00
    smpsModOff

    smpsChangeVol $06
    .db nFs2, $03, nRst, $18
    ;
    smpsDetune $01
    smpsFMVoice $07
    smpsPatchEnv $00
    smpsChangeVol $FB
    .db nCs4, $01, nRst, $02, nCs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nCs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nCs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nCs4, $03, nRst
    smpsChangeVol $03
    .db nCs4, $01, nRst, $02, nCs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nCs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nCs4, $01, nRst, $02
    smpsChangeVol $FF
    .db nCs4, $03, nRst, nCs4, nRst, nBb3, nRst
    smpsChangeVol $03
    .db nB3, $01, nRst, $02, nB3, $01, nRst, $02
    smpsChangeVol $FF
    .db nB3, $01, nRst, $02
    smpsChangeVol $FF
    .db nB3, $01, nRst, $02
    smpsChangeVol $FF
    .db nB3, $03, nRst
    smpsChangeVol $03
    .db nB3, $01, nRst, $02, nB3, $01, nRst, $02
    smpsChangeVol $FF
    .db nB3, $01, nRst, $02
    smpsChangeVol $FF
    .db nB3, $01, nRst, $02
    smpsChangeVol $FF
    .db nB3, $03, nRst, nB3, nRst, nGs3, nRst

    smpsChangeVol $02
    smpsJump    Mus_FinalBowser_FM@ch2LoopPoint

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsModSetup    $10, $01, $FE, $03
    smpsPatchEnv $15
    .db nE3, $09, nG3, $03, nRst, $06
    
    ;smpsChangeVol $FF
    smpsVolEnv $09
    .db nFs3, $24
    smpsVolEnv $00
    ;smpsChangeVol $01
    
    .db $06, $06, $06, $03, $03, nRst, nFs3, nRst, nF3, $09

    smpsChangeVol $FE
    smpsPatchEnv $00
@ch3LoopPoint:
    smpsFMVoice $01
    .db nA2, $03, nB2, nD3, nE3, nRst, $06, nA2, $03, nB2, nD3, nE3, nRst, nA2, nRst, $06
    .db nA3
    
    smpsModSetup    $10, $01, $FC, $FF
    smpsVolEnv $0A
    .db nGs3, $18
    smpsVolEnv $00
    smpsModOff

    smpsChangeVol $07
    .db nGs2, $02, nRst, $16
    smpsChangeVol $F9
    .db nA2, $03, nB2, nD3, nE3, nRst, $06, nA2, $03, nB2, nD3, nE3, nRst, nA2, nRst, $06
    .db nA3

    smpsModOn
    smpsVolEnv $0A
    .db nBb3, $18
    smpsVolEnv $00
    smpsModOff

    smpsChangeVol $07
    .db nBb2, $02, nRst, $16
    ;
    smpsFMVoice $07
    smpsChangeVol $FD ;$FC
    .db nGs3, $01, nRst, $02, nGs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nGs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nGs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nGs3, $03, nRst
    smpsChangeVol $03
    .db nGs3, $01, nRst, $02, nGs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nGs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nGs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nGs3, $03, nRst, nGs3, nRst, nF3, nRst
    smpsChangeVol $03
    .db nFs3, $01, nRst, $02, nFs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs3, $03, nRst
    smpsChangeVol $03
    .db nFs3, $01, nRst, $02, nFs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs3, $01, nRst, $02
    smpsChangeVol $FF
    .db nFs3, $03, nRst, nFs3, nRst, nEb3, nRst
    
    smpsChangeVol $FF
    smpsJump    Mus_FinalBowser_FM@ch3LoopPoint

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsFMVoice $01
    .db nRst, $60
@ch4LoopPoint:
    .db nD3, $03, nE3, nG3, nA3, nRst, $06, nD3, $03, nE3, nG3, nA3, nRst, nD3, nRst, $06
    .db nD4

    smpsModSetup    $10, $01, $FC, $FF
    smpsVolEnv $0A
    .db nCs4, $18
    smpsVolEnv $00
    smpsModOff

    smpsChangeVol $07
    .db nCs3, $03, nRst, $15
    smpsChangeVol $F9
    .db nD3, $03, nE3, nG3, nA3, nRst, $06, nD3, $03, nE3, nG3, nA3, nRst, nD3, nRst, $06
    .db nD4
    
    smpsModOn
    smpsVolEnv $0A
    .db nEb4, $18
    smpsVolEnv $00
    smpsModOff

    smpsChangeVol $07
    .db nEb3, $03, nRst, $75
    smpsChangeVol $F9
    smpsJump    Mus_FinalBowser_FM@ch4LoopPoint

;   --- CHANNEL 5 DATA ---
@ch5:
    smpsModSetup    $10, $01, $FE, $03
    smpsPatchEnv $15
    .db nC3, $09, nEb3, $03, nRst, $06

    ;smpsChangeVol $FF
    smpsVolEnv $09
    .db nD3, $24
    smpsVolEnv $00
    ;smpsChangeVol $01
    
    .db $06, $06, $06, $03, $03, nRst, nD3, nRst, nCs3, $09
    smpsModOff
    smpsChangeVol $01
    smpsPatchEnv $14
    smpsVolEnv $04
@ch5LoopPoint:
    .db nG4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01, nB4, $02, nRst, $01
    .db nG4, $02, nRst, $01, nB4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01
    .db nG4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01
    .db nB4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01, nG4, $02, nRst, $01
    smpsJump    Mus_FinalBowser_FM@ch5LoopPoint

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsStop

;   --- CHANNEL 7 DATA ---
@ch7:
    .db nRst, $60
    smpsPatchEnv $13
    smpsVolEnv $03
@ch7LoopPoint:
    smpsCall    Mus_FinalBowser_FM@ch7Call1
    smpsCall    Mus_FinalBowser_FM@ch7Call1
    smpsCall    Mus_FinalBowser_FM@ch7Call1
    smpsCall    Mus_FinalBowser_FM@ch7Call2
    smpsCall    Mus_FinalBowser_FM@ch7Call1
    smpsCall    Mus_FinalBowser_FM@ch7Call2
    smpsJump    Mus_FinalBowser_FM@ch7LoopPoint

@ch7Call1:
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $06, $06
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $06
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsRet
    
@ch7Call2:
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $06, $06
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $03
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $06
    smpsModSetup    $00, $01, $E8, $FF
    .db nC4, $06, $03, $03
    smpsRet

;   --- CHANNEL 8 DATA ---
@ch8:
    smpsPatchEnv    $0F
    smpsFMVoice $10 ; UPLOAD CUSTOM INSTRUMENT
    smpsModSetup    $00, $01, $E4, $FF
    .db nRst, $36, nFs2, $06
    smpsChangeVol $FF
    .db $06
    smpsChangeVol $FE
    .db $06, $03, $03, nRst, nFs2, nRst, nFs2, nEb2, $03, $03

    smpsChangeVol $FF
@ch8LoopPoint:
    smpsCall    Mus_FinalBowser_FM@ch8Call1
    smpsCall    Mus_FinalBowser_FM@ch8Call1
    smpsCall    Mus_FinalBowser_FM@ch8Call1
    smpsCall    Mus_FinalBowser_FM@ch8Call2
    smpsCall    Mus_FinalBowser_FM@ch8Call1
    smpsCall    Mus_FinalBowser_FM@ch8Call2
    smpsJump    Mus_FinalBowser_FM@ch8LoopPoint

@ch8Call1:
    .db nRst, $06, $06
    .db nD2
    .db nRst, $03
    .db nD2
    .db nRst
    .db nD2
    .db nRst, $06
    .db nD2
    .db nRst, $03
    .db nD2
    smpsRet
    
@ch8Call2:
    .db nRst, $06, $06
    .db nD2
    .db nRst, $03
    .db nD2
    .db nRst
    .db nD2
    .db nRst, $06
    .db nD2, $06, $03, $03
    smpsRet

.ENDS

;   ----------------------------------

.SECTION "MUS Data - Title (FM)" BANK BANK_SOUND SLOT 2 FREE
Mus_Title_FM:
    ; MAIN HEADER
    smpsHeader      $00, $09, $01, $6A
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Title_FM@ch0,  $00, $00, $00, $00
    smpsChanHeader  Mus_Title_FM@ch1,  $00, $03, $00, $00
    smpsChanHeader  Mus_Title_FM@ch2,  $00, $03, $00, $00
    smpsChanHeader  Mus_Title_FM@ch3,  $00, $03, $00, $00
    smpsChanHeader  Mus_Title_FM@ch4,  $00, $06, $00, $00
    smpsChanHeader  Mus_Title_FM@ch5,  $00, $00, $00, $00
    smpsChanHeader  Mus_Title_FM@ch6,  $00, $03, $00, $00
    smpsChanHeader  Mus_Title_FM@ch7,  $00, $02, $00, $00
    smpsChanHeader  Mus_Title_FM@ch8,  $00, $04, $00, $00

;   --- CHANNEL 0 DATA ---
@ch0:
    smpsFMVoice $01
    smpsVolEnv  $06
@ch0LoopPoint:
    .db nC3, $23, nRst, $01, nC3, $23, nRst, $01, nC3, $23, nRst, $01
    ;.db nG3, $07, nRst, $05
    ;smpsChangeVol $03
    ;.db nG3, $17, nRst, $01
    ;smpsChangeVol $FD

    smpsTempo $6B
    smpsNoAtk
    .db nG3, $01
    smpsTempo $6C
    smpsNoAtk
    .db $01
    smpsTempo $6E
    smpsNoAtk
    .db $01
    smpsTempo $6F
    smpsNoAtk
    .db $01
    smpsTempo $71
    smpsNoAtk
    .db $01
    smpsTempo $73
    smpsNoAtk
    .db $01
    smpsTempo $74
    smpsNoAtk
    .db $01
    smpsTempo $76
    smpsNoAtk
    .db nRst, $01
    smpsTempo $77
    smpsNoAtk
    .db $01
    smpsTempo $79
    smpsNoAtk
    .db $01
    smpsTempo $7A
    smpsNoAtk
    .db $01
    smpsTempo $7C
    smpsNoAtk
    .db $01
    smpsChangeVol $03
    smpsTempo $7E
    smpsNoAtk
    .db nG3, $01
    smpsTempo $7F
    smpsNoAtk
    .db $01
    smpsTempo $81
    smpsNoAtk
    .db $01
    smpsTempo $82
    smpsNoAtk
    .db $01
    smpsTempo $84
    smpsNoAtk
    .db $01
    smpsTempo $85
    smpsNoAtk
    .db $01
    smpsTempo $87
    smpsNoAtk
    .db $01
    smpsTempo $88
    smpsNoAtk
    .db $01
    smpsChangeVol $FF
    smpsTempo $8A
    smpsNoAtk
    .db nG3, $01
    smpsTempo $8C
    smpsNoAtk
    .db $01
    smpsTempo $8D
    smpsNoAtk
    .db $01
    smpsTempo $8F
    smpsNoAtk
    .db $05
    smpsChangeVol $FF
    .db nG3, $08
    smpsChangeVol $FF
    ;
    smpsTempo $6A
    smpsCall Mus_Title_FM@ch0Call1
    smpsJump Mus_Title_FM@ch0LoopPoint


@ch0Call1:
    smpsModSetup    $10, $01, $01, $02
    .db nE6, $20, nRst, $04, nEb6, $20, nRst, $04
    smpsChangeVol $01
    .db nE6, $29, nRst, $01
    ;
    smpsPatchEnv $05
    smpsVolEnv  $00
    .db nG5, $01, nRst, $05, nA5, $01, nRst, $05, nB5, $01, nRst, $05, nC6, $01, nRst, $05
    .db nD6, $01, nRst, $05
    smpsChangeVol $FF
    ;
    smpsPatchEnv $00
    smpsVolEnv  $06
    smpsFMVoice $01
    .db nE6, $20, nRst, $04, nEb6, $15, nRst, $03, nF6, $0A, nRst, $02
    smpsChangeVol $01
    .db nE6, $29, nRst, $01
    ;
    smpsPatchEnv $05
    smpsVolEnv  $00
    .db nG5, $01, nRst, $05, nA5, $01, nRst, $05, nB5, $01, nRst, $05, nC6, $01, nRst, $05
    .db nCs6, $01, nRst, $05
    smpsChangeVol $FF
    ;
    smpsPatchEnv $00
    smpsVolEnv  $06
    smpsFMVoice $01
    .db nD6, $20, nRst, $04, nCs6, $20, nRst, $04
    smpsChangeVol $01
    .db nD6, $29, nRst, $01
    ;
    smpsPatchEnv $05
    smpsVolEnv  $00
    .db nG5, $01, nRst, $05, nA5, $01, nRst, $05, nB5, $01, nRst, $05, nC6, $01, nRst, $05
    .db nCs6, $01, nRst, $05
    smpsChangeVol $FF
    ;
    smpsPatchEnv $00
    smpsVolEnv  $06
    smpsFMVoice $01
    .db nD6, $20, nRst, $04, nG5, $15, nRst, $03, nF6, $0A, nRst, $02
    smpsChangeVol $01
    .db nE6, $29, nRst, $01
    ;
    smpsPatchEnv $05
    smpsVolEnv  $00
    .db nG5, $01, nRst, $05, nA5, $01, nRst, $05, nB5, $01, nRst, $05, nC6, $01, nRst, $05
    .db nD6, $01, nRst, $05
    smpsChangeVol $FF
    ;
    smpsPatchEnv $00
    smpsVolEnv  $06
    smpsFMVoice $01
    .db nG6, $20, nRst, $04, nG6, $20, nRst, $04
    smpsChangeVol $01
    .db nG6, $20, nRst, $04
    ;
    smpsPatchEnv $05
    smpsVolEnv  $00
    .db nG6, $01, nRst, $05, nG5, $01, nRst, $05, nG6, $01, nRst, $05, nA6, $01, nRst, $05
    .db nG5, $01, nRst, $05, nG6, $01, nRst, $05
    smpsChangeVol $FF
    ;
    smpsPatchEnv $00
    smpsVolEnv  $06
    smpsFMVoice $01
    .db nF6, $20, nRst, $04, nF6, $20, nRst, $04
    smpsChangeVol $01
    .db nF6, $20, nRst, $04
    ;
    smpsPatchEnv $05
    smpsVolEnv  $00
    .db nF6, $01, nRst, $05, nF5, $01, nRst, $05, nF6, $01, nRst, $05, nG6, $01, nRst, $05
    .db nG5, $01, nRst, $05, nF6, $01, nRst, $05
    smpsChangeVol $FF
    ;
    smpsPatchEnv $00
    smpsVolEnv  $06
    smpsFMVoice $01
    .db nE6, $20, nRst, $04, nA5, $0A, nRst, $02, nB5, $0A, nRst, $02, nF6, $0A, nRst, $02
    .db nE6, $0A, nRst, $02, nE6, $10, nRst, $02, nB5, $05, nRst, $01, nC6, $20, nRst, $04
    smpsModOff
    smpsRet

;   --- CHANNEL 1 DATA ---
@ch1:
    smpsVolEnv  $06
    smpsPatchEnv $01
    .db nRst, $0C, nE6, $0B, nRst, $01, nE6, $0B, nRst, $0D, nF6, $0B, nRst, $01, nF6, $0B
    .db nRst, $0D, nG6, $0B, nRst, $01, nG6, $0B, nRst, $01, nF6, $07, nRst, $05
    ;smpsChangeVol $05
    ;.db nF6, $17, nRst, $01
    ;smpsChangeVol $F9

    smpsChangeVol $04
    smpsNoAtk
    .db nF6, $06
    smpsChangeVol $FF
    smpsNoAtk
    .db $06
    smpsChangeVol $FF
    smpsNoAtk
    .db $06
    smpsChangeVol $FF
    .db $06
    smpsChangeVol $FC ;FC

    smpsModSetup    $10, $01, $01, $02
    smpsPatchEnv $00
    smpsFMVoice $01
    .db nC3, $23, nRst, $01, nG2, $17, nRst, $01, nB2, $0B, nRst, $01, nC3, $23, nRst, $01
    .db nG2, $23, nRst, $01, nC3, $23, nRst, $01, nG2, $17, nRst, $01, nB2, $0B, nRst, $01
    .db nC3, $23, nRst, $01, nG2, $23, nRst, $01, nB2, $23, nRst, $01, nBb2, $23, nRst, $01
    .db nB2, $23, nRst, $01, nG2, $23, nRst, $01, nB2, $23, nRst, $01, nG2, $17, nRst, $01
    .db nB2, $0B, nRst, $01, nC3, $23, nRst, $01, nG2, $23, nRst, $01, nC3, $23, nRst, $01
    .db nBb2, $23, nRst, $01, nA2, $23, nRst, $01, nG2, $23, nRst, $01, nD3, $23, nRst, $01
    .db nCs3, $23, nRst, $01, nC3, $23, nRst, $01, nB2, $23, nRst, $01, nC3, $23, nRst, $01
    .db nF2, $23, nRst, $01, nG2, $23, nRst, $01, nC3, $23, nRst, $01
    smpsChangeVol $03 ;$03
    smpsModOff
    smpsJump    Mus_Title_FM@ch1

;   --- CHANNEL 2 DATA ---
@ch2:
    smpsPatchEnv $01
@ch2LoopPoint:
    .db nRst, $0C
    smpsCall    Mus_Title_FM@ch2Call1
    .db nC6, $0B, nRst, $01, nC6, $0B, nRst, $0D
    .db nD6, $0B, nRst, $01, nD6, $0B, nRst, $01, nC6, $07, nRst, $05
    ;smpsChangeVol $05
    ;.db nC6, $17, nRst, $01
    ;smpsChangeVol $FB

    smpsChangeVol $04
    smpsNoAtk
    .db nC6, $06
    smpsChangeVol $FF
    smpsNoAtk
    .db $06
    smpsChangeVol $FF
    smpsNoAtk
    .db $06
    smpsChangeVol $FF
    .db $06
    smpsChangeVol $FF

    .db nRst, $0C
    smpsCall    Mus_Title_FM@ch2Call1
    .db nA5, $05, nRst, $01, nA5, $05, nRst, $01, nA5, $0B, nRst, $0D
    smpsCall    Mus_Title_FM@ch2Call1
    smpsCall    Mus_Title_FM@ch2Call2
    smpsCall    Mus_Title_FM@ch2Call2
    .db nA5, $0B, nRst, $01, nA5, $0B, nRst, $0D
    smpsCall    Mus_Title_FM@ch2Call2
    smpsCall    Mus_Title_FM@ch2Call1
    smpsCall    Mus_Title_FM@ch2Call3
    
@ch2Loop1:
    .db nG5, $05, nRst, $01, nG5, $05, nRst, $01, nG5, $0B, nRst, $0D
    smpsLoop    $00, $05, Mus_Title_FM@ch2Loop1
    
    .db nG5, $05, nRst, $01, nG5, $05, nRst, $01, nG5, $0B, nRst, $01
    .db nB5, $0B, nRst, $01, nC6, $0B, nRst, $01, nD6, $0B, nRst, $0D

    smpsCall    Mus_Title_FM@ch2Call3
    .db nG5, $05, nRst, $01, nG5, $05, nRst, $01, nG5, $0B, nRst, $0D
    smpsCall    Mus_Title_FM@ch2Call3
    .db nG5, $0B, nRst, $19
    .db nF5, $05, nRst, $01, nF5, $05, nRst, $01, nF5, $0B, nRst, $0D
    .db nF5, $0B, nRst, $01, nF5, $0B, nRst, $0D
    .db nD5, $05, nRst, $01, nD5, $05, nRst, $01, nD5, $0B, nRst, $0D
    .db nD5, $0B, nRst, $19
    .db nE5, $0B, nRst, $01, nE5, $0B, nRst, $01
    
    .db nF5, $0B, nRst, $01, nF5, $0B, nRst, $01, nF5, $0B, nRst, $01
    .db nC5, $0B, nRst, $01, nB4, $11, nRst, $01
    .db nF4, $05, nRst, $01, nE4, $23, nRst, $01
    smpsJump    Mus_Title_FM@ch2LoopPoint

@ch2Call1:
    .db nB5, $0B, nRst, $01, nB5, $0B, nRst, $0D
    smpsRet

@ch2Call2:
    .db nB5, $05, nRst, $01, nB5, $05, nRst, $01, nB5, $0B, nRst, $0D
    smpsRet

@ch2Call3:
    .db nG5, $0B, nRst, $01, nG5, $0B, nRst, $0D
    smpsRet

;   --- CHANNEL 3 DATA ---
@ch3:
    smpsPatchEnv $01
@ch3LoopPoint:
    .db nRst, $0C
    smpsCall    Mus_Title_FM@ch2Call3
    .db nA5, $0B, nRst, $01, nA5, $0B, nRst, $0D
    .db nB5, $0B, nRst, $01, nB5, $0B, nRst, $01, nA5, $07, nRst, $05
    ;smpsChangeVol $05
    ;.db nA5, $17, nRst, $01
    ;smpsChangeVol $FB

    smpsChangeVol $04
    smpsNoAtk
    .db nA5, $06
    smpsChangeVol $FF
    smpsNoAtk
    .db $06
    smpsChangeVol $FF
    smpsNoAtk
    .db $06
    smpsChangeVol $FF
    .db $06
    smpsChangeVol $FF

    .db nRst, $0C
    smpsCall    Mus_Title_FM@ch2Call3
    .db nFs5, $05, nRst, $01, nFs5, $05, nRst, $01, nFs5, $0B, nRst, $0D
    smpsCall    Mus_Title_FM@ch2Call3

@ch3Loop1:
    .db nG5, $05, nRst, $01, nG5, $05, nRst, $01, nG5, $0B, nRst, $0D
    smpsLoop    $00, $02, Mus_Title_FM@ch3Loop1

    .db nFs5, $05, nRst, $01, nFs5, $05, nRst, $01, nFs5, $0B, nRst, $0D

@ch3Loop2:
    .db nG5, $05, nRst, $01, nG5, $05, nRst, $01, nG5, $0B, nRst, $0D
    smpsLoop    $00, $02, Mus_Title_FM@ch3Loop2

    .db nG4, $0B, nRst, $01, nG4, $0B, nRst, $0D
    .db nCs5, $05, nRst, $01, nCs5, $05, nRst, $01, nCs5, $0B, nRst, $0D
    .db nD5, $0B, nRst, $01, nD5, $0B, nRst, $0D
    
@ch3Loop3:
    .db nD5, $05, nRst, $01, nD5, $05, nRst, $01, nD5, $0B, nRst, $0D
    smpsLoop    $00, $03, Mus_Title_FM@ch3Loop3
    
    smpsCall    Mus_Title_FM@ch3Call1
    
    .db nG4, $05, nRst, $01, nA4, $05, nRst, $01, nB4, $0B, nRst, $0D
    .db nE5, $0B, nRst, $01, nE5, $0B, nRst, $0D
    
    .db nA4, $05, nRst, $01, nA4, $05, nRst, $01, nA4, $0B, nRst, $0D
    
    .db nCs5, $0B, nRst, $01, nCs5, $0B, nRst, $0D
    .db nA4, $0B, nRst, $19
    
    smpsCall    Mus_Title_FM@ch3Call1
    .db nC5, $0B, nRst, $01, nC5, $0B, nRst, $0D
    smpsCall    Mus_Title_FM@ch3Call1
    
    .db nC5, $0B, nRst, $19
    
    .db nC5, $0B, nRst, $01, nC5, $0B, nRst, $01

    ;
    .db nF5, $0B, nRst, $01, nG5, $0B, nRst, $01
    .db nC6, $0B, nRst, $01, nC6, $0B, nRst, $01
    .db nB5, $11, nRst, $01, nF5, $05, nRst, $01, nE5, $23, nRst, $01
    smpsJump    Mus_Title_FM@ch3LoopPoint

@ch3Call1:
    .db nC5, $05, nRst, $01, nC5, $05, nRst, $01, nC5, $0B, nRst, $0D
    smpsRet

;   --- CHANNEL 4 DATA ---
@ch4:
    smpsFMVoice $0C
@ch4LoopPoint:
    .db nRst, $0C
    .db nFs5, $0B, nRst, $01, nFs5, $0B, nRst, $0D
    smpsCall    Mus_Title_FM@ch2Call3
    .db nA5, $0B, nRst, $01, nA5, $0B, nRst, $01, nG5, $07, nRst, $05

    ;smpsChangeVol $02
    ;.db nG5, $17, nRst, $0D
    ;smpsChangeVol $FA

    smpsChangeVol $04
    smpsNoAtk
    .db nG5, $06
    smpsChangeVol $FF
    smpsNoAtk
    .db $06
    smpsChangeVol $FF
    smpsNoAtk
    .db $06
    smpsChangeVol $FF
    .db $06
    smpsChangeVol $FF

    smpsChangeVol $FD
    .db nRst, $0C
    smpsCall    Mus_Title_FM@ch4Call5
    smpsCall    Mus_Title_FM@ch4Call1

@ch4Loop1:
    smpsCall    Mus_Title_FM@ch4Call2
    smpsLoop    $00, $03, Mus_Title_FM@ch4Loop1

    smpsCall    Mus_Title_FM@ch4Call1

@ch4Loop2:
    smpsCall    Mus_Title_FM@ch4Call2
    smpsLoop    $00, $02, Mus_Title_FM@ch4Loop2

    .db nD5, $0B, nRst, $01, nD5, $0B, nRst, $0D
    
    smpsCall    Mus_Title_FM@ch4Call2
    .db nF5, $0B, nRst, $01, nF5, $0B, nRst, $0D
       
    
    smpsCall    Mus_Title_FM@ch4Call3
    smpsCall    Mus_Title_FM@ch4Call3
    .db nF5, $0B, nRst, $01, nF5, $0B, nRst, $0D
    
    .db nE5, $05, nRst, $01, nE5, $05, nRst, $01, nE5, $0B, nRst, $01
    .db nB4, $0B, nRst, $01, nC5, $0B, nRst, $01, nD5, $0B, nRst, $0D
    .db nC5, $0B, nRst, $01, nC5, $0B, nRst, $0D
    
    smpsCall    Mus_Title_FM@ch4Call4
    
    smpsCall    Mus_Title_FM@ch4Call5
    .db nE5, $0B, nRst, $19
    smpsCall    Mus_Title_FM@ch4Call4
    
    smpsCall    Mus_Title_FM@ch4Call5
    
    smpsCall    Mus_Title_FM@ch4Call3
    .db nF5, $0B, nRst, $19
    
    .db nG4, $0B, nRst, $01, nG4, $0B, nRst, $01
    
    .db nC5, $0B, nRst, $01, nD5, $0B, nRst, $01
    .db nA5, $0B, nRst, $01, nG5, $0B, nRst, $01, nF5, $11, nRst, $01
    .db nD5, $05, nRst, $01, nC5, $23, nRst, $01
    smpsChangeVol $03
    smpsJump    Mus_Title_FM@ch4LoopPoint

@ch4Call1:
    .db nEb5, $05, nRst, $01, nEb5, $05, nRst, $01, nEb5, $0B, nRst, $0D
    smpsRet

@ch4Call2:
    .db nE5, $05, nRst, $01, nE5, $05, nRst, $01, nE5, $0B, nRst, $0D
    smpsRet

@ch4Call3:
    .db nF5, $05, nRst, $01, nF5, $05, nRst, $01, nF5, $0B, nRst, $0D
    smpsRet

@ch4Call4:
    .db nD5, $05, nRst, $01, nD5, $05, nRst, $01, nD5, $0B, nRst, $0D
    smpsRet

@ch4Call5:
    .db nE5, $0B, nRst, $01, nE5, $0B, nRst, $0D
    smpsRet

;   --- CHANNEL 5 DATA ---
@ch5:
    smpsFMVoice $01
    smpsVolEnv  $06
    smpsPatchEnv $00
    smpsModSetup    $10, $01, $01, $02
@ch5LoopPoint:
    .db nRst, $7F, $11
    .db nG5, $20, nRst, $04, nFs5, $20, nRst, $04
    smpsChangeVol $01
    .db nG5, $29, nRst, $01
    ;
    smpsVolEnv  $00
    smpsDetune $02
    smpsPatchEnv $05
    smpsChangeVol $01
    .db nG5, $01, nRst, $05, nA5, $01, nRst, $05, nB5, $01, nRst, $05, nC6, $01, nRst, $05
    .db nD6, $01, nRst, $05
    smpsChangeVol $FE
    ;
    smpsDetune $00
    smpsFMVoice $01
    smpsPatchEnv $00
    smpsVolEnv  $06
    .db nG5, $20, nRst, $04, nFs5, $15, nRst, $03, nA5, $0A, nRst, $02
    smpsChangeVol $01
    .db nG5, $29, nRst, $01
    ;
    smpsVolEnv  $00
    smpsDetune $02
    smpsPatchEnv $05
    smpsChangeVol $01
    .db nG5, $01, nRst, $05, nA5, $01, nRst, $05, nB5, $01, nRst, $05, nC6, $01, nRst, $05
    .db nCs6, $01, nRst, $05
    smpsChangeVol $FE
    ;
    smpsDetune $00
    smpsFMVoice $01
    smpsPatchEnv $00
    smpsVolEnv  $06
    .db nG5, $20, nRst, $04, nFs5, $20, nRst, $04
    smpsChangeVol $01
    .db nG5, $29, nRst, $01
    ;
    smpsVolEnv  $00
    smpsDetune $02
    smpsPatchEnv $05
    smpsChangeVol $01
    .db nG5, $01, nRst, $05, nA5, $01, nRst, $05, nB5, $01, nRst, $05, nC6, $01, nRst, $05
    .db nCs6, $01, nRst, $05
    smpsChangeVol $FE
    ;
    smpsDetune $00
    smpsFMVoice $01
    smpsPatchEnv $00
    smpsVolEnv  $06
    .db nG5, $20, nRst, $04, nF5, $15, nRst, $03, nB5, $0A, nRst, $02
    smpsChangeVol $01
    .db nC6, $29, nRst, $01
    ;
    smpsVolEnv  $00
    smpsDetune $02
    smpsPatchEnv $05
    smpsChangeVol $01
    .db nG5, $01, nRst, $05, nA5, $01, nRst, $05, nB5, $01, nRst, $05, nC6, $01, nRst, $05
    .db nD6, $01, nRst, $05
    smpsChangeVol $FE
    ;
    smpsDetune $00
    smpsFMVoice $01
    smpsPatchEnv $00
    smpsVolEnv  $06
    .db nE6, $20, nRst, $04, nD6, $20, nRst, $04
    smpsChangeVol $01
    .db nCs6, $20, nRst, $04
    ;
    smpsVolEnv  $00
    smpsDetune $02
    smpsPatchEnv $05
    smpsChangeVol $01
    .db nG6, $01, nRst, $05, nG5, $01, nRst, $05, nG6, $01, nRst, $05, nA6, $01, nRst, $05
    .db nG5, $01, nRst, $05, nG6, $01, nRst, $05
    smpsChangeVol $FE
    ;
    smpsDetune $00
    smpsFMVoice $01
    smpsPatchEnv $00
    smpsVolEnv  $06
    .db nD6, $20, nRst, $04, nCs6, $20, nRst, $04
    smpsChangeVol $01
    .db nC6, $20, nRst, $04
    ;
    smpsVolEnv  $00
    smpsDetune $02
    smpsPatchEnv $05
    smpsChangeVol $01
    .db nF6, $01, nRst, $05, nF5, $01, nRst, $05, nF6, $01, nRst, $05, nG6, $01, nRst, $05
    .db nG5, $01, nRst, $05, nF6, $01, nRst, $05
    smpsChangeVol $FE
    ;
    smpsDetune $00
    smpsFMVoice $01
    smpsPatchEnv $00
    smpsVolEnv  $06
    .db nC6, $20, nRst, $04, nF5, $0A, nRst, $02, nG5, $0A, nRst, $02, nC6, $0A, nRst, $02
    .db nC6, $0A, nRst, $02, nC6, $10, nRst, $02, nF5, $05, nRst, $01, nE5, $20, nRst, $04
    smpsJump    Mus_Title_FM@ch5LoopPoint

;   --- CHANNEL 6 DATA ---
@ch6:
    smpsFMVoice $10
@ch6LoopPoint:
    smpsCall    Mus_Title_FM@ch6Call3
    ;
    smpsCall    Mus_Title_FM@ch6Call1

    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call2

    smpsCall    Mus_Title_FM@ch6Call1

    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call2

    smpsCall    Mus_Title_FM@ch6Call1
    smpsCall    Mus_Title_FM@ch6Call1

    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call2
    ;
    smpsCall    Mus_Title_FM@ch6Call3
    ;
    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call1
    smpsCall    Mus_Title_FM@ch6Call1
    smpsJump    Mus_Title_FM@ch6LoopPoint

@ch6Call1:  ; 3
    smpsVolEnv  $03
    smpsPatchEnv    $13
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $0C

    smpsVolEnv  $00
    smpsPatchEnv    $0F
    smpsModSetup    $00, $01, $E4, $FF
    .db nD2, nD2
    smpsRet

@ch6Call2:  ; 2
    smpsVolEnv  $03
    smpsPatchEnv    $13
    smpsModSetup    $00, $02, $E8, $FF
    .db nC3, $0C

    smpsVolEnv  $00
    smpsPatchEnv    $0F
    smpsModSetup    $00, $01, $E4, $FF
    .db nD2, $06, nD2, nD2, $0C
    smpsRet

@ch6Call3:
    smpsCall    Mus_Title_FM@ch6Call1
    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call2
    smpsCall    Mus_Title_FM@ch6Call1
    smpsLoop    $00, $02, Mus_Title_FM@ch6Call3
    smpsRet

;   --- CHANNEL 7 DATA ---
@ch7:
    smpsPatchEnv $09
    smpsVolEnv  $05
@ch7LoopPoint:
@ch7Loop1:
    .db nBb7, $24
    smpsLoop    $00, $13, Mus_Title_FM@ch7Loop1

    .db nRst

@ch7Loop2:
    .db nBb7
    smpsLoop    $00, $0C, Mus_Title_FM@ch7Loop2
    smpsJump    Mus_Title_FM@ch7LoopPoint

;   --- CHANNEL 8 DATA ---
@ch8:
    smpsDetune $01
    smpsFMVoice $01
    smpsVolEnv  $06
    .db nRst, $04

@ch8LoopPoint:
    .db nC3, $23, nRst, $01, nC3, $23, nRst, $01, nC3, $23, nRst, $01

    .db nG3, $07
    .db nRst, $05
    smpsNoAtk
    smpsChangeVol $03
    smpsNoAtk
    .db nG3, $08
    smpsChangeVol $FF
    smpsNoAtk
    .db nG3, $08
    smpsChangeVol $FF
    .db nG3, $08
    smpsChangeVol $FF

    smpsCall Mus_Title_FM@ch0Call1
    smpsJump Mus_Title_FM@ch8LoopPoint
.ENDS