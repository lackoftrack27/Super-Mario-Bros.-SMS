/*
-----------------------------------------------------------
                    MACROS AND ENUMS
-----------------------------------------------------------
*/
;   UNUSED, CHANNEL COUNT, TEMPO MULTIPLIER, TEMPO
.MACRO smpsHeader ARGS unused chan mult tempo
    .DW $0000               ; UNUSED
    .DB unused, chan, mult, tempo
.ENDM

;   ABSOLUTE ADDRESS OF CHANNEL DATA, NOTE OFFSET, INITIAL VOLUME, UNUSED, ENVELOPE
.MACRO smpsChanHeader ARGS loc offset vol unused env
    .DW loc
    .DB offset, vol, unused, env
.ENDM

;   CF
.MACRO smpsDetune ARGS data
    .DB $E1, data
.ENDM

.MACRO smpsRet
    .db $E3
.ENDM

.MACRO smpsNoAtk
    .db $E7
.ENDM

.MACRO smpsTranspose ARGS data
    .db $E9, data
.ENDM

.MACRO smpsChangeVol ARGS data
    .DB $EC, data
.ENDM

.MACRO smpsNoiseDrumMode
    .DB $ED
.ENDM

.MACRO smpsLiteralRead  ARGS data
    .DB $EE, data
.ENDM

.MACRO smpsModSetup     ARGS wait, speed, delta, steps
    .db $F0, wait, speed, delta, steps
.ENDM

.MACRO smpsModOn
    .db $F1
.ENDM

.MACRO smpsStop
    .DB $F2
.ENDM

.MACRO smpsSetNoise ARGS data
    .DB $F3, data
.ENDM

.MACRO smpsModOff
    .db $F4
.ENDM

.MACRO smpsPSGVoice ARGS data
    .DB $F5, data
.ENDM

.MACRO smpsJump ARGS loc
    .DB $F6
    .DW loc
.ENDM

.MACRO smpsCall ARGS loc
    .db $F8
    .dw loc
.ENDM

.MACRO smpsLoop ARGS index, count, loc
    .db $F7, index, count
    .dw loc
.ENDM


;   NOTE DEFS (TONE)
.ENUM $80
    nRst    DB
    nC0     DB nCs0   DB nD0   DB nEb0  DB nE0   DB nF0   DB nFs0  DB nG0   DB nGs0  DB nA0    DB nBb0   DB nB0    DB   ; 0 (C2)
    nC1     DB nCs1   DB nD1   DB nEb1  DB nE1   DB nF1   DB nFs1  DB nG1   DB nGs1  DB nA1    DB nBb1   DB nB1    DB   ; 1 (C3)
    nC2     DB nCs2   DB nD2   DB nEb2  DB nE2   DB nF2   DB nFs2  DB nG2   DB nGs2  DB nA2    DB nBb2   DB nB2    DB   ; 2 (C4)
    nC3     DB nCs3   DB nD3   DB nEb3  DB nE3   DB nF3   DB nFs3  DB nG3   DB nGs3  DB nA3    DB nBb3   DB nB3    DB   ; 3 (C5)
    nC4     DB nCs4   DB nD4   DB nEb4  DB nE4   DB nF4   DB nFs4  DB nG4   DB nGs4  DB nA4    DB nBb4   DB nB4    DB   ; 4 (C6)
    nC5     DB nCs5   DB nD5   DB nEb5  DB nE5   DB nF5   DB nFs5  DB nG5   DB nGs5  DB nA5    DB nBb5   DB nB5    DB   ; 5 (C7)
    nC6     DB nCs6   DB nD6   DB nEb6  DB nE6   DB nF6   DB nFs6  DB nG6   DB nGs6  DB nA6    DB nBb6   DB nB6    DB   ; 6 (C8)
    nC7     DB nCs7   DB nD7   DB nEb7  DB nE7   DB nF7   DB nFs7  DB nG7   DB nGs7  DB nA7    DB nBb7   DB nB7    DB   ; 7 (C9)
.ENDE

;   NOTE DEFS (NOISE)
.ENUM $81
    ; PERIODIC
    nHiP    db
    nMidP   db
    nLowP   db
    nCh2P   db
    ; NOISE
    nHi     DB
    nMid    DB
    nLow    DB
    nCh2    DB
.ENDE

;   DRUM DEFS
.ENUM $81
    nDrumH5 db
    nDrumH1 db
    nDrumM1 db
.ENDE


.ENUM $80
    SNDID_STOP      DB
;
    SNDID_JUMPBIG   DB
    SNDID_BUMP      DB
    SNDID_SWIM      DB
    SNDID_KICK      DB
    SNDID_PIPE      DB
    SNDID_FIREBALL  DB
    SNDID_FLAGPOLE  DB
    SNDID_JUMPSMALL DB
;
    SNDID_COIN      DB
    SNDID_ITEM      DB
    SNDID_VINE      DB
    SNDID_CANNON    DB
    SNDID_BEEP      DB
    SNDID_POWERUP   DB
    SNDID_1UP       DB
    SNDID_FALL      DB
;
    SNDID_SHATTER   DB
    SNDID_FLAME     DB
    SNDID_PAUSE     DB      ; ON PSG CHANNEL 1
;
    SNDID_WATER         DB  ; $94, $13
    SNDID_OVERWORLD     DB
    SNDID_UNDERGROUND   DB
    SNDID_CASTLE        DB
    SNDID_CLOUD         DB
    SNDID_PIPEINTRO     DB
    SNDID_INVINCIBLE    DB
;
    SNDID_HURRYUP       DB
    SNDID_LEVELDONE     DB
    SNDID_WORLDDONE     DB
    SNDID_GAMEDONE      DB
    SNDID_GAMEOVER      DB
    SNDID_DEATH         DB
    SNDID_SILENCE       DB
.ENDE


/*
-----------------------------------------------------------
                    SOUND EFFECT DATA
-----------------------------------------------------------
*/

.SECTION "SFX Data - 1UP" BANK BANK_SOUND SLOT 2 FREE
SFX_1UP:
    smpsChanHeader  SFX_1UP + 6,            $00 $00 $00 $03
    .db nE4, $08, nG4, nE5, nC5, nD5, nG5
    smpsStop
.ENDS

.SECTION "SFX Data - Score Tick" BANK BANK_SOUND SLOT 2 FREE
SFX_Beep:
    smpsChanHeader  SFX_Beep + 6,           $00 $03 $00 $00
    .db nB3, $04 ;$05
    smpsChangeVol $03
    .db $01
    smpsChangeVol $FD
    smpsStop
.ENDS

.SECTION "SFX Data - Bump" BANK BANK_SOUND SLOT 2 FREE
SFX_Bump:
    smpsChanHeader  SFX_Bump + 6,           $00 $00 $00 $00
    smpsModSetup    $00, $01, $3B, $FF
    .db nG1, $04
    smpsNoAtk
    smpsModSetup    $00, $02, $C0, $FF
    .db $05
    smpsStop
.ENDS

.SECTION "SFX Data - Cannon, Fireworks" BANK BANK_SOUND SLOT 2 FREE
SFX_Cannon:
    smpsChanHeader  SFX_Cannon + 6,         $00 $00 $00 $00
    smpsModSetup    $00, $01, $1D, $FF
    .db nD1, $08
    smpsModSetup    $00, $01, $2E, $FF
    .db nD2, $0D
    smpsStop
.ENDS

.SECTION "SFX Data - Coin" BANK BANK_SOUND SLOT 2 FREE
SFX_Coin:
    smpsChanHeader  SFX_Coin + 6,           $00 $00 $00 $02
    .db nB3, $05
    .db nE4, $2B
    smpsStop
.ENDS

.SECTION "SFX Data - Fireball" BANK BANK_SOUND SLOT 2 FREE
SFX_Fireball:
    smpsChanHeader  SFX_Fireball + 6,       $00 $00 $00 $00
    .db nG1, $01, nG2, nG3, nG4
    smpsStop
.ENDS

.SECTION "SFX Data - Flagpole" BANK BANK_SOUND SLOT 2 FREE
SFX_Flagpole:
    smpsChanHeader  SFX_Flagpole + 6,       $00 $02 $00 $00
    smpsModSetup    $00, $02, $F3, $FF
    .db nA1, $41
    smpsStop
.ENDS

.SECTION "SFX Data - Flame" BANK BANK_SOUND SLOT 2 FREE
SFX_Flame:
    smpsChanHeader  SFX_Flame + 6,          $00 $00 $00 $05
    .db nLow, $3F
    smpsStop
.ENDS

.SECTION "SFX Data - Item Reveal" BANK BANK_SOUND SLOT 2 FREE
SFX_Item:
    smpsChanHeader  SFX_Item + 6,           $00 $01 $00 $00
    .db nC2, $03, nG2, $02, nGs2
    .db nCs2, $04, nGs2, $02, nA2
    .db nD2, $04, nA2, $02, nBb2
    .db nEb2, $04, nBb2, $02, nB2
    smpsStop
.ENDS

.SECTION "SFX Data - Big Jump" BANK BANK_SOUND SLOT 2 FREE
SFX_JumpBig:
    smpsChanHeader  SFX_JumpBig + 6,        $00 $00 $00 $06
    smpsModSetup    $00, $01, $02, $FF
    .db nD2, $03
    smpsNoAtk
    smpsModSetup    $00, $04, $03, $FF
    .db $05
    smpsNoAtk
    smpsModSetup    $00, $02, $ED, $FF
    .db $15
    smpsStop
.ENDS

.SECTION "SFX Data - Small Jump" BANK BANK_SOUND SLOT 2 FREE
SFX_JumpSml:
    smpsChanHeader  SFX_JumpSml + 6,        $00 $00 $00 $06
    smpsModSetup    $00, $01, $01, $FF
    .db nA2, $03
    smpsNoAtk
    smpsModSetup    $00, $04, $02, $FF
    .db $05
    smpsNoAtk
    smpsModSetup    $00, $02, $F3, $FF
    .db $15
    smpsStop
.ENDS

.SECTION "SFX Data - Kick" BANK BANK_SOUND SLOT 2 FREE
SFX_Kick:
    smpsChanHeader  SFX_Kick + 6,           $00 $00 $00 $00
    .db nBb2, $01
    .db nRst, $05
    .db nF3, $01
    smpsStop
.ENDS

.SECTION "SFX Data - Pause" BANK BANK_SOUND SLOT 2 FREE
SFX_Pause:
    smpsChanHeader  SFX_Pause + 6,          $00 $00 $00 $01
    .db nE4, $06, nC4, nE4
    .db nC4, $12
    smpsStop
.ENDS

.SECTION "SFX Data - Pipe" BANK BANK_SOUND SLOT 2 FREE
SFX_Pipe:
    smpsChanHeader  SFX_Pipe + 6,           $00 $02 $00 $00
    .db nRst, $03
    .db nE4, $01, nA3, nD3, nG2, nE4, nA3, nD3, nG2, nC2, nF1
    .db nRst, $06
    .db nE4, $01, nA3, nD3, nG2, nE4, nA3, nD3, nG2, nC2, nF1
    .db nRst, $06
    .db nE4, $01, nA3, nD3, nG2, nE4, nA3, nD3, nG2, nC2, nF1
    smpsStop
.ENDS

.SECTION "SFX Data - Powerup" BANK BANK_SOUND SLOT 2 FREE
SFX_Powerup:
    smpsChanHeader  SFX_Powerup + 6,        $00 $01 $00 $00
    .db nC3, $02, nG2, nC3, nF3, nG3, nC4, nG3
    .db nGs2, nC3, nEb3, nGs3, nEb3, nGs3, nC4, nEb4, nGs4, nEb4
    .db nBb2, nD3, nF3, nBb3, nF3, nBb3, nD4, nF4, nBb4, nF4
    smpsStop
.ENDS

.SECTION "SFX Data - Brick Shatter" BANK BANK_SOUND SLOT 2 FREE
SFX_Shatter:
    smpsChanHeader  SFX_Shatter + 6,        $00 $00 $00 $00
    .db nRst, $01, nLow, nRst, nHi, nLow, nRst
    smpsChangeVol   $01
    .db nHi, nRst, nLow, nRst, nHi, nRst
    smpsChangeVol   $01
    .db nHi, nRst, nMid, nRst, nLow, nRst, nLow, nRst
    smpsChangeVol   $01
    .db nHi, nRst, nMid, nRst, nLow, nRst
    smpsChangeVol   $01
    .db nLow, nRst, nLow, nRst
    smpsStop
.ENDS

.SECTION "SFX Data - Swim, Stomp" BANK BANK_SOUND SLOT 2 FREE
SFX_Swim:
    smpsChanHeader  SFX_Swim + 6,           $00 $00 $00 $04
    smpsModSetup    $01, $01, $F8, $FF
    .db nA2, $05
    .db nRst, $03
    .db nF3, $06
    smpsStop
.ENDS

.SECTION "SFX Data - Vine" BANK BANK_SOUND SLOT 2 FREE
SFX_Vine:
    smpsChanHeader  SFX_Vine + 6,           $00 $01 $00 $00
    .db nC2, $03, nG2, $02, nGs2
    .db nCs2, $04, nGs2, $02, nA2
    .db nD2, $04, nA2, $02, nBb2
    .db nEb2, $04, nBb2, $02, nB2
    .db nE2, $04, nB2, $02, nC3
    .db nF2, $04, nC3, $02, nCs3
    .db nFs2, $04, nCs3, $02, nD3
    .db nG2, $04, nD3, $02, nEb3
    smpsStop
.ENDS

.SECTION "SFX Data - Bowser Fall" BANK BANK_SOUND SLOT 2 FREE
SFX_BowserFall:
    smpsChanHeader  SFX_BowserFall + $06,   $00 $00 $00 $00
    smpsModSetup    $00, $02, $17, $FF
    .db nD2, $37
    smpsStop
.ENDS

/*
-----------------------------------------------------------
                    COMMON MUSIC DATA
-----------------------------------------------------------
*/

.SECTION "MUS Data - Silence" BANK BANK_SOUND SLOT 2 FREE
Mus_Silence:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00
@ch0:
    smpsStop
.ENDS

.SECTION "MUS Data - Hurry Up" BANK BANK_SOUND SLOT 2 FREE
Mus_HurryUp:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_HurryUp@ch0,    $00, $03, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_HurryUp@ch1,    $00, $00, $00, $0A  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_HurryUp@ch2,    $00, $00, $00, $0A  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,    $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nB1, $06, nB2, $08, nRst, $04, nB2, $0E, nRst, $04
    smpsTranspose $01
    smpsLoop $00, $03, Mus_HurryUp@ch0
    smpsTranspose $FD

    .db nG1, $08, nRst, $04, nG1, $30
    smpsStop
@ch1:
    .db nE1, $06, nGs2, $0C, $06, $0C
    smpsTranspose $01
    smpsLoop $00, $03, Mus_HurryUp@ch1
    smpsTranspose $FD
    
    .db nB2, $0C, $31
    smpsStop
@ch2:
    .db nE2, $06, nD3, $0C, $06, $0C
    smpsTranspose $01
    smpsLoop $00, $03, Mus_HurryUp@ch2
    smpsTranspose $FD
    
    .db nF3, $0C, $31
    smpsStop
.ENDS

.SECTION "MUS Data - Game Victory" BANK BANK_SOUND SLOT 2 FREE
Mus_GameVictory:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_GameVictory@ch0,    $00, $03, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_GameVictory@ch1,    $00, $00, $00, $0A  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_GameVictory@ch2,    $00, $00, $00, $0A  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,        $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    smpsDetune  $FC
    .db nB0, $18, nC1, $30, nD1, $18, nEb1, nE1, nC1, nA1, nG1, nF1, nE1, nD1, nF1, nG1
    .db $18, $18, nC1
    smpsJump Mus_GameVictory@ch0
@ch1:
    .db nG2, $08, nFs2, nG2, nE2, $30, nF2, $18, nFs2, nG2, $30, nC3, $18, nE3, $12, $06
    .db nD3, $18, nE3, nF3, nB2, nD3, $30, nC3, $18
    smpsJump Mus_GameVictory@ch1
@ch2:
    .db nRst, $18
@@loopPoint:
    .db nG1, $30, nA1, $18, nBb1, nB1, $30, nE2, $18, nG2, nF2, nG2, nA2, nD2
    .db nF2, $30, nE2
    smpsJump Mus_GameVictory@ch2@loopPoint
.ENDS

/*
-----------------------------------------------------------
                REGION DEPENDENT MUSIC DATA
-----------------------------------------------------------
*/

.IF PALBUILD == $00
    .INCLUDE "SND_Data_NTSC.inc"
.ELSE
    .INCLUDE "SND_Data_PAL.inc"
.ENDIF