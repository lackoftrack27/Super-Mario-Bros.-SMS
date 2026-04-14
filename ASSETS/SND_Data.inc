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

.MACRO smpsNoAtk
    .db $E7
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
                        MUSIC DATA
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

.SECTION "MUS Data - Water" BANK BANK_SOUND SLOT 2 FREE
Mus_Water:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $40  ; $40, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Water@ch0,  $00, $03, $00, $0E  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Water@ch1,  $00, $00, $00, $0A  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Water@ch2,  $00, $00, $00, $0A  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Water@ch3,  $00, $02, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nRst, $60, nG1, $0C, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
    .db nC1, $0C, nG1, nC2, nB0, nG1, nB1, nC1, nG1, nC2, nE1, nG1, nC2, nC1, nG1, nC2
    .db nB0, nG1, nB1, nC1, nG1, nC2, nE1, nG1, nC2, nD1, nG1, nB1, nCs1, nFs1, nBb1, nD1
    .db nG1, nB1, nB0, nG1, nB1, nD1, nG1, nB1, nB0, nG1, nB1, nC1, nG1, nC2, nG1, $0C
    .db $0C, nC2, nC1, nG1, nE2, nB0, nG1, nD2, nBb0, nG1, nCs2, nCs1, nG1, nE2, nD1, nA1
    .db nF2, nCs1, nA1, nF2, nC1, nA1, nF2, nB0, nG1, nF2, nC1, nG1, nE2, nG1, $0C, $0C
    .db $0C, nF1, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, nB0, $06, nC1, $03
    .db $03, $03, $03, $03, $03, $03, $03, $03, $03, $03, $03
    smpsJump Mus_Water@ch0
@ch1:
    .db nD2, $0C, nCs2, nC2, nB1, nC2, nCs2, nD2, $06, $06, $06, nRst, nE2, nRst, nF2, $24
    .db nG2, nFs2, nG2, $48, $24, nFs2, $18, nA2, $0C, nG2, $48, nF2, $24, nE2, nF2, $48
    .db $24, nB1, $18, nA2, $0C, nG2, $48, nE3, $24, nD3, nCs3, $48, nD3, $24, nCs3, nC3
    .db $48, nC2, $24, nF2, $0C, nG2, nB2, $0C, $06, $06, $12, nF2, $06, nE2, $24
    smpsJump Mus_Water@ch1
@ch2:
    .db nRst, $0C, nE2, nFs2, nG2, nA2, nBb2, nB2, $06, $06, $06, nRst, nB2, nRst, nB2, $18
    .db nG2, $0C, nE3, $24, nEb3, nE3, $2A, nG2, $06, nA2, nB2, nC3, nD3, nE3, $24, nEb3
    .db $18, nF3, $0C, nE3, $42, nG2, $06, nD3, $24, nCs3, nD3, $2A, nG2, $06, nA2, nB2
    .db nC3, nCs3, nD3, $24, nG2, $18, nF3, $0C, nE3, $42, nG2, $06, nG3, $24, $24, $24
    .db $0C, nA3, $06, nRst, $0C, nG3, $06, nF3, $24, $24, $24, $0C, nG3, $06, nRst, $0C
    .db nF3, $06, nE3, $24, nA2, $0C, nB2, nF3, nE3, $06, $06, $12, nB2, $06, nC3, $24
    smpsJump Mus_Water@ch2
@ch3:
    smpsNoiseDrumMode
    .db nRst, $0C, nDrumH1, nDrumH5, $18, nDrumH1, $06, $06, nDrumH5, $0C
    smpsJump Mus_Water@ch3
.ENDS

.SECTION "MUS Data - Overworld" BANK BANK_SOUND SLOT 2 FREE
Mus_Overworld:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $55  ; $55, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Overworld@ch0,  $00, $03, $00, $0E  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Overworld@ch1,  $00, $00, $00, $07  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Overworld@ch2,  $00, $00, $00, $07  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Overworld@ch3,  $00, $02, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nD1, $06, $0C, $0C, $06, $0C, nG2, $18, nG1
@@loopPoint:
    .db nG1, $12, nE1, nC1, nF1, $0C, nG1
    .db nFs1, $06, nF1, $0C, nE1, $08, nC2, nE2, nF2, $0C, nD2, $06, nE2, $0C, nC2, nA1
    .db $06, nB1, nG1, $12, $12, nE1, nC1, nF1, $0C, nG1, nFs1, $06, nF1, $0C, nE1, $08
    .db nC2, nE2, nF2, $0C, nD2, $06, nE2, $0C, nC2, nA1, $06, nB1, nG1, $12, nC1, nG1
    .db nC2, $0C, nF1, $12, nC2, $06, $0C, nF1, nC1, $12, nE1, nG1, $06, nC2, $0C, nG3
    .db $0C, $06, $0C, nG1, nC1, $12, nG1, nC2, $0C, nF1, $12, nC2, $06, $0C, nF1, nC1
    .db nGs1, $12, nBb1, nC2, nG1, $06, $0C, nC1, $0C, $12, nG1, nC2, $0C, nF1, $12, nC2
    .db $06, $0C, nF1, nC1, $12, nE1, nG1, $06, nC2, $0C, nG3, $0C, $06, $0C, nG1, nC1
    .db $12, nG1, nC2, $0C, nF1, $12, nC2, $06, $0C, nF1, nC1, nGs1, $12, nBb1, nC2, nG1
    .db $06, $0C, nC1, nGs1, $12, nEb1, nGs1, $0C, nG1, $12, nC1, nG1, $0C, nGs1, $12, nEb1
    .db nGs1, $0C, nG1, $12, nC1, nG1, $0C, nGs1, $12, nEb1, nGs1, $0C, nG1, $12, nC1, nG1
    .db $0C, nD1, $06, $0C, $0C, $06, $0C, nG2, $18, nG1, $18, $12, nE1, nC1, nF1, $0C
    .db nG1, nFs1, $06, nF1, $0C, nE1, $08, nC2, nE2, nF2, $0C, nD2, $06, nE2, $0C, nC2
    .db nA1, $06, nB1, nG1, $12, $12, nE1, nC1, nF1, $0C, nG1, nFs1, $06, nF1, $0C, nE1
    .db $08, nC2, nE2, nF2, $0C, nD2, $06, nE2, $0C, nC2, nA1, $06, nB1, nG1, $12, nC1
    .db nFs1, $06, nG1, $0C, nC2, nF1, $0C, $0C, nC2, $06, $06, nF1, $0C, nD1, $12, nF1
    .db $06, nG1, $0C, nB1, nG1, $0C, $0C, nC2, $06, $06, nG1, $0C, nC1, $12, nFs1, $06
    .db nG1, $0C, nC2, nF1, $0C, $0C, nC2, $06, $06, nF1, $0C, nG1, $12, $06, $08, nA1
    .db nB1, nC2, $0C, nG1, nC1, $18, $12, nFs1, $06, nG1, $0C, nC2, nF1, $0C, $0C, nC2
    .db $06, $06, nF1, $0C, nD1, $12, nF1, $06, nG1, $0C, nB1, nG1, $0C, $0C, nC2, $06
    .db $06, nG1, $0C, nC1, $12, nFs1, $06, nG1, $0C, nC2, nF1, $0C, $0C, nC2, $06, $06
    .db nF1, $0C, nG1, $12, $06, $08, nA1, nB1, nC2, $0C, nG1, nC1, $18, nGs1, $12, nEb1
    .db nGs1, $0C, nG1, $12, nC1, nG1, $0C, nGs1, $12, nEb1, nGs1, $0C, nG1, $12, nC1, nG1
    .db $0C, nGs1, $12, nEb1, nGs1, $0C, nG1, $12, nC1, nG1, $0C, nD1, $06, $0C, $0C, $06
    .db $0C, nG2, $18, nG1, nC1, $12, nFs1, $06, nG1, $0C, nC2, nF1, $0C, $0C, nC2, $06
    .db $06, nF1, $0C, nD1, $12, nF1, $06, nG1, $0C, nB1, nG1, $0C, $0C, nC2, $06, $06
    .db nG1, $0C, nC1, $12, nFs1, $06, nG1, $0C, nC2, nF1, $0C, $0C, nC2, $06, $06, nF1
    .db $0C, nG1, $12, $06, $08, nA1, nB1, nC2, $0C, nG1, nC1, $18
    smpsJump Mus_Overworld@ch0@loopPoint
@ch1:
    .db nFs2, $06, $0C, $0C, $06, $0C, nB2, $18, nG2
@@loopPoint:
    .db nE2, $12, nC2, nG1, nC2, $0C, nD2
    .db nCs2, $06, nC2, $0C, $08, nG2, nB2, nC3, $0C, nA2, $06, nB2, $0C, nA2, nE2, $06
    .db nF2, nD2, $12, nE2, nC2, nG1, nC2, $0C, nD2, nCs2, $06, nC2, $0C, $08, nG2, nB2
    .db nC3, $0C, nA2, $06, nB2, $0C, nA2, nE2, $06, nF2, nD2, $1E, nE3, $06, nEb3, nD3
    .db nB2, $0C, nC3, nE2, $06, nF2, nG2, $0C, nC2, $06, nE2, nF2, $12, nE3, $06, nEb3
    .db nD3, nB2, $0C, nC3, nF3, $0C, $06, $24, nE3, $06, nEb3, nD3, nB2, $0C, nC3, nE2
    .db $06, nF2, nG2, $0C, nC2, $06, nE2, nF2, $12, nGs2, nF2, nE2, $3C, nE3, $06, nEb3
    .db nD3, nB2, $0C, nC3, nE2, $06, nF2, nG2, $0C, nC2, $06, nE2, nF2, $12, nE3, $06
    .db nEb3, nD3, nB2, $0C, nC3, nF3, $0C, $06, $24, nE3, $06, nEb3, nD3, nB2, $0C, nC3
    .db nE2, $06, nF2, nG2, $0C, nC2, $06, nE2, nF2, $12, nGs2, nF2, nE2, $30, nGs2, $06
    .db $0C, $0C, $06, nBb2, $0C, nG2, $06, nE2, $0C, $06, nC2, $18, nGs2, $06, $0C, $0C
    .db $06, nBb2, nG2, $36, nGs2, $06, $0C, $0C, $06, nBb2, $0C, nG2, $06, nE2, $0C, $06
    .db nC2, $18, nFs2, $06, $0C, $0C, $06, $0C, nB2, $18, nG2, nE2, $12, nC2, nG1, nC2
    .db $0C, nD2, nCs2, $06, nC2, $0C, $08, nG2, nB2, nC3, $0C, nA2, $06, nB2, $0C, nA2
    .db nE2, $06, nF2, nD2, $12, nE2, nC2, nG1, nC2, $0C, nD2, nCs2, $06, nC2, $0C, $08
    .db nG2, nB2, nC3, $0C, nA2, $06, nB2, $0C, nA2, nE2, $06, nF2, nD2, $12, nC3, $06
    .db nA2, $0C, nE2, $12, $0C, nF2, $06, nC3, $0C, $06, nF2, $18, nG2, $08, nF3, $08
    .db $08, $08, nE3, nD3, nC3, $06, nA2, $0C, nF2, $06, nE2, $18, nC3, $06, nA2, $0C
    .db nE2, $12, $0C, nF2, $06, nC3, $0C, $06, nF2, $18, nG2, $06, nD3, $0C, $06, $08
    .db nC3, nB2, nG2, $06, nE2, $0C, $06, nC2, $18, nC3, $06, nA2, $0C, nE2, $12, $0C
    .db nF2, $06, nC3, $0C, $06, nF2, $18, nG2, $08, nF3, $08, $08, $08, nE3, nD3, nC3
    .db $06, nA2, $0C, nF2, $06, nE2, $18, nC3, $06, nA2, $0C, nE2, $12, $0C, nF2, $06
    .db nC3, $0C, $06, nF2, $18, nG2, $06, nD3, $0C, $06, $08, nC3, nB2, nG2, $06, nE2
    .db $0C, $06, nC2, $18, nGs2, $06, $0C, $0C, $06, nBb2, $0C, nG2, $06, nE2, $0C, $06
    .db nC2, $18, nGs2, $06, $0C, $0C, $06, nBb2, nG2, $36, nGs2, $06, $0C, $0C, $06, nBb2
    .db $0C, nG2, $06, nE2, $0C, $06, nC2, $18, nFs2, $06, $0C, $0C, $06, $0C, nB2, $18
    .db nG2, nC3, $06, nA2, $0C, nE2, $12, $0C, nF2, $06, nC3, $0C, $06, nF2, $18, nG2
    .db $08, nF3, $08, $08, $08, nE3, nD3, nC3, $06, nA2, $0C, nF2, $06, nE2, $18, nC3
    .db $06, nA2, $0C, nE2, $12, $0C, nF2, $06, nC3, $0C, $06, nF2, $18, nG2, $06, nD3
    .db $0C, $06, $08, nC3, nB2, nG2, $06, nE2, $0C, $06, nC2, $18
    smpsJump Mus_Overworld@ch1@loopPoint
@ch2:
    .db nE3, $06, $0C, $0C, nC3, $06, nE3, $0C, nG3, $30
@@loopPoint:
    .db nC3, $12, nG2, nE2, nA2, $0C
    .db nB2, nBb2, $06, nA2, $0C, nG2, $08, nE3, nG3, nA3, $0C, nF3, $06, nG3, $0C, nE3
    .db nC3, $06, nD3, nB2, $12, nC3, nG2, nE2, nA2, $0C, nB2, nBb2, $06, nA2, $0C, nG2
    .db $08, nE3, nG3, nA3, $0C, nF3, $06, nG3, $0C, nE3, nC3, $06, nD3, nB2, $1E, nG3
    .db $06, nFs3, nF3, nEb3, $0C, nE3, nGs2, $06, nA2, nC3, $0C, nA2, $06, nC3, nD3, $12
    .db nG3, $06, nFs3, nF3, nEb3, $0C, nE3, nC4, $0C, $06, $24, nG3, $06, nFs3, nF3, nEb3
    .db $0C, nE3, nGs2, $06, nA2, nC3, $0C, nA2, $06, nC3, nD3, $12, nEb3, nD3, nC3, $3C
    .db nG3, $06, nFs3, nF3, nEb3, $0C, nE3, nGs2, $06, nA2, nC3, $0C, nA2, $06, nC3, nD3
    .db $12, nG3, $06, nFs3, nF3, nEb3, $0C, nE3, nC4, $0C, $06, $24, nG3, $06, nFs3, nF3
    .db nEb3, $0C, nE3, nGs2, $06, nA2, nC3, $0C, nA2, $06, nC3, nD3, $12, nEb3, nD3, nC3
    .db $30, $06, $0C, $0C, $06, nD3, $0C, nE3, $06, nC3, $0C, nA2, $06, nG2, $18, nC3
    .db $06, $0C, $0C, $06, nD3, nE3, $36, nC3, $06, $0C, $0C, $06, nD3, $0C, nE3, $06
    .db nC3, $0C, nA2, $06, nG2, $18, nE3, $06, $0C, $0C, nC3, $06, nE3, $0C, nG3, $30
    .db nC3, $12, nG2, nE2, nA2, $0C, nB2, nBb2, $06, nA2, $0C, nG2, $08, nE3, nG3, nA3
    .db $0C, nF3, $06, nG3, $0C, nE3, nC3, $06, nD3, nB2, $12, nC3, nG2, nE2, nA2, $0C
    .db nB2, nBb2, $06, nA2, $0C, nG2, $08, nE3, nG3, nA3, $0C, nF3, $06, nG3, $0C, nE3
    .db nC3, $06, nD3, nB2, $12, nE3, $06, nC3, $0C, nG2, $12, nGs2, $0C, nA2, $06, nF3
    .db $0C, $06, nA2, $18, nB2, $08, nA3, $08, $08, $08, nG3, nF3, nE3, $06, nC3, $0C
    .db nA2, $06, nG2, $18, nE3, $06, nC3, $0C, nG2, $12, nGs2, $0C, nA2, $06, nF3, $0C
    .db $06, nA2, $18, nB2, $06, nF3, $0C, $06, $08, nE3, nD3, nC3, $30, nE3, $06, nC3
    .db $0C, nG2, $12, nGs2, $0C, nA2, $06, nF3, $0C, $06, nA2, $18, nB2, $08, nA3, $08
    .db $08, $08, nG3, nF3, nE3, $06, nC3, $0C, nA2, $06, nG2, $18, nE3, $06, nC3, $0C
    .db nG2, $12, nGs2, $0C, nA2, $06, nF3, $0C, $06, nA2, $18, nB2, $06, nF3, $0C, $06
    .db $08, nE3, nD3, nC3, $30, $06, $0C, $0C, $06, nD3, $0C, nE3, $06, nC3, $0C, nA2
    .db $06, nG2, $18, nC3, $06, $0C, $0C, $06, nD3, nE3, $36, nC3, $06, $0C, $0C, $06
    .db nD3, $0C, nE3, $06, nC3, $0C, nA2, $06, nG2, $18, nE3, $06, $0C, $0C, nC3, $06
    .db nE3, $0C, nG3, $30, nE3, $06, nC3, $0C, nG2, $12, nGs2, $0C, nA2, $06, nF3, $0C
    .db $06, nA2, $18, nB2, $08, nA3, $08, $08, $08, nG3, nF3, nE3, $06, nC3, $0C, nA2
    .db $06, nG2, $18, nE3, $06, nC3, $0C, nG2, $12, nGs2, $0C, nA2, $06, nF3, $0C, $06
    .db nA2, $18, nB2, $06, nF3, $0C, $06, $08, nE3, nD3, nC3, $30
    smpsJump Mus_Overworld@ch2@loopPoint
@ch3:
    smpsNoiseDrumMode
    .db nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06
@@loopPoint:
    .db nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5
    .db $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C
    .db nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1
    .db $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08
    .db $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04
    .db nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5
    .db $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C
    .db nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1
    .db $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08
    .db $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04
    .db nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5
    .db $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C
    .db nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1
    .db $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08
    .db $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04
    .db nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06
    .db nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06
    .db nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06
    .db nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06
    .db nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5
    .db $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C
    .db nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1
    .db $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08
    .db $04, nDrumH5, $0C, nDrumH1, $08, $04, nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04
    .db $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C
    .db nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06
    .db nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C
    .db $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C
    .db nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06
    .db nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, nDrumH5
    .db nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06, nDrumH5, $0C
    .db nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06, nDrumH5, $0C
    .db nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06, nDrumH5, $0C
    .db nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06, $12, $06
    .db nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C
    .db $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C
    .db nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1, $0C, $12, $06, nDrumH5, $0C, nDrumH1
    smpsJump Mus_Overworld@ch3@loopPoint
.ENDS

.SECTION "MUS Data - Underground" BANK BANK_SOUND SLOT 2 FREE
Mus_Underground:
    /*
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $55  ; $55, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Underground@ch0, $00, $03, $00, $0E   ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00   ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Underground@ch2, $00, $00, $00, $07   ; PULSE 2  (CH1)
    smpsChanHeader  Mus_Silence@ch0, $00, $0F, $00, $00   ; NOISE     (CH3)
@ch0:
    .db nC1, $06, nC2, nA0, nA1, nBb0, nBb1, $2A, nC1, $06, nC2, nA0, nA1, nBb0, nBb1, $2A
    .db nF1, $06, nF2, nD1, nD2, nEb1, nEb2, $2A, nF1, $06, nF2, nD1, nD2, nEb1, nEb2, $1E
    .db nEb1, $04, nD1, nCs1, nC1, $0C, nEb1, nD1, nGs1, nG1, nCs1, nC1, $04, nFs1, nF1, nE1
    .db nBb1, nA1, nGs1, $08, nEb1, nB0, nBb0, nA0, nGs1, $50
    smpsJump Mus_Underground@ch0
@ch2:
    .db nC2, $06, nC3, nA1, nA2, nBb1, nBb2, $2A, nC2, $06, nC3, nA1, nA2, nBb1, nBb2, $2A
    .db nF2, $06, nF3, nD2, nD3, nEb2, nEb3, $2A, nF2, $06, nF3, nD2, nD3, nEb2, nEb3, $1E
    .db nEb2, $04, nD2, nCs2, nC2, $0C, nEb2, nD2
    smpsDetune  $FA
    .db nGs1, nG1
    smpsDetune  $00
    .db nCs2, nC2, $04, nFs2, nF2, nE2, nBb2, nA2, nGs2, $08, nEb2, nB1, nBb1, nA1
    smpsDetune  $FA
    .db nGs1, $50
    smpsDetune  $00
    smpsJump Mus_Underground@ch2
    */
    
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $55  ; $55, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Underground@ch0,    $18, $0F, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Silence@ch0,        $00, $0F, $00, $00  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Underground@ch0,    $00, $00, $00, $07  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Underground@ch3,    $00, $02, $00, $0E  ; NOISE     (CH3)
@ch0:
    .db nC2, $06, nC3, nA1, nA2, nBb1, nBb2, $2A, nC2, $06, nC3, nA1, nA2, nBb1, nBb2, $2A
    .db nF1, $06, nF2, nD1, nD2, nEb1, nEb2, $2A, nF1, $06, nF2, nD1, nD2, nEb1, nEb2, $1E
    .db $04, nD2, nCs2, nC2, $0C, nEb2, nD2
    .db nGs1, nG1
    .db nCs2, nC2, $04, nFs2, nF2, nE2, nBb2, nA2, nGs2, $08, nEb2, nB1, nBb1, nA1
    .db nGs1, $50
    smpsJump Mus_Underground@ch0
@ch3:
    .db nCh2P, $06, $06, $06, $06, $06, $2A, $06, $06, $06, $06, $06, $2A
    .db $06, $06, $06, $06, $06, $2A, $06, $06, $06, $06, $06, $1E
    .db $04, $04, $04, $0C, $0C, $0C
    .db $0C, $0C
    .db $0C, $04, $04, $04, $04
    .db $04, $04, $08, $08, $08, $08, $08
    .db $50
    smpsJump Mus_Underground@ch3
.ENDS

.SECTION "MUS Data - Castle" BANK BANK_SOUND SLOT 2 FREE
Mus_Castle:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $33  ; $33, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Castle@ch0,     $00, $03, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Castle@ch1,     $00, $00, $00, $07  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Castle@ch2,     $00, $00, $00, $07  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,    $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nEb1, $40, nD1, $20, nFs1, nF1, $40, nE1, $20, nBb1, nA1, nE1, nEb1, nE1
    smpsJump Mus_Castle@ch0
@ch1:
    .db nRst, $04
    .db nD3, $08, nCs3, nC3, nCs3, nD3, nEb3, nD3, nCs3, nD3, nCs3, nC3, nCs3, nD3
    .db nEb3, nD3, nCs3, $08, $08, nC3, nCs3, nD3, nCs3, nD3, nCs3, nC3, nCs3, nC3, nCs3, nD3
    .db nCs3, nD3, nCs3, nC3, nF3, nFs3, nF3, nE3, nF3, nE3, nEb3, nE3, nF3, nFs3, nF3, nE3
    .db nF3, nE3, nEb3, nE3, $04
    smpsJump Mus_Castle@ch1
@ch2:
    .db nG2, $04, nBb2, nG2, nA2, nG2, nGs2, nG2, nA2, nG2, nBb2, nG2, nB2, nG2, nBb2, nG2
    .db nA2, nG2, nBb2, nG2, nA2, nG2, nGs2, nG2, nA2, nG2, nBb2, nG2, nB2, nG2, nBb2, nG2
    .db nA2, nFs2, nA2, nFs2, nGs2, nFs2, nA2, nFs2, nBb2, nFs2, nA2, nFs2, nBb2, nFs2, nA2, nFs2
    .db nGs2, nFs2, nA2, nFs2, nGs2, nFs2, nA2, nFs2, nBb2, nFs2, nA2, nFs2, nBb2, nFs2, nA2, nFs2
    .db nGs2, nBb2, nD3, nBb2, nEb3, nBb2, nD3, nBb2, nCs3, nBb2, nD3, nBb2, nCs3, nBb2, nC3, nBb2
    .db nCs3, nBb2, nD3, nBb2, nEb3, nBb2, nD3, nBb2, nCs3, nBb2, nD3, nBb2, nCs3, nBb2, nC3, nBb2
    .db nCs3
    smpsJump Mus_Castle@ch2
.ENDS

.SECTION "MUS Data - Invincible" BANK BANK_SOUND SLOT 2 FREE
Mus_Cloud:
Mus_Invincible:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $80  ; $80, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Invincible@ch0, $00, $03, $00, $0E  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Invincible@ch1, $00, $00, $00, $09  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Invincible@ch2, $00, $00, $00, $09  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Invincible@ch3, $00, $02, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nD1, $0C, nA1, $09, nD2, $0F, nA1, $06, nD2, nC1, $0C, nG1, $09, nC2, $0F, nG1
    .db $06, nC2
    smpsJump Mus_Invincible@ch0
@ch1:
    .db nF2, $06, $06, $06, nD2, $03, nF2, $06, $06, nD2, $03, nF2, nD2, nF2, $06, nE2
    .db $06, $06, $06, nC2, $03, nE2, $06, $06, nC2, $03, nE2, nC2, nE2, $06
    smpsJump Mus_Invincible@ch1
@ch2:
    .db nC3, $06, $06, $09, $06, $09, $06, $06, nB2, $06, $06, $09, $06, $09, $06, $06
    smpsJump Mus_Invincible@ch2
@ch3:
    smpsNoiseDrumMode
    .db nDrumM1, $06, nDrumH1, $04, $02, nDrumH5, $06, nDrumH1, $04, $02, nDrumM1, $06, nDrumH1, $04, $02, nDrumH5
    .db $06, nDrumH1, $04, $02, nDrumM1, $06, nDrumH1, $04, $02, nDrumH5, $06, nDrumH1, $04, $02, nDrumM1, $06
    .db nDrumH1, $04, $02, nDrumH5, $06, nDrumH1, $04, $02
    smpsJump Mus_Invincible@ch3
.ENDS


.SECTION "MUS Data - Pipe Intro" BANK BANK_SOUND SLOT 2 FREE
Mus_PipeIntro:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $55  ; $55, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_PipeIntro@ch0,  $00, $03, $00, $0E  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_PipeIntro@ch1,  $00, $00, $00, $07  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_PipeIntro@ch2,  $00, $00, $00, $07  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_PipeIntro@ch3,  $00, $02, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nD1, $06, $0C, $0C, $06, $0C, nG2, $18, nG1
    smpsStop
@ch1:
    .db nFs2, $06, $0C, $0C, $06, $0C, nB2, $18, nG2
    smpsStop
@ch2:
    .db nE3, $06, $0C, $0C, nC3, $06, nE3, $0C, nG3, $30
    smpsStop
@ch3:
    smpsNoiseDrumMode
    .db nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06
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
    .db nB1, $06, nB2, $08, nRst, $04, nB2, $0E, nRst, $04, nC2, $06, nC3, $08, nRst, $04
    .db nC3, $0E, nRst, $04, nCs2, $06, nCs3, $08, nRst, $04, nCs3, $0E, nRst, $04, nG1, $08
    .db nRst, $04, nG1, $30
    smpsStop
@ch1:
    .db nE1, $06, nGs2, $0C, $06, $0C, nF1, $06, nA2, $0C, $06, $0C, nFs1, $06, nBb2, $0C
    .db $06, $0C, nB2, $0C, $31
    smpsStop
@ch2:
    .db nE2, $06, nD3, $0C, $06, $0C, nF2, $06, nEb3, $0C, $06, $0C, nFs2, $06, nE3, $0C
    .db $06, $0C, nF3, $0C, $31
    smpsStop
.ENDS


.SECTION "MUS Data - Level Victory" BANK BANK_SOUND SLOT 2 FREE
Mus_LevelVictory:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_LevelVictory@ch0,   $00, $03, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_LevelVictory@ch1,   $00, $00, $00, $08  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_LevelVictory@ch2,   $00, $00, $00, $08  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,        $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nRst, $18
    .db nC1, $08, nE1, nG1, nE2, $18, nC2, $08, nRst, $28, nC1, $08, nEb1, nGs1, nEb2, $18
    .db nC2, $08, nRst, $28, nD1, $08, nF1, nBb1, nF2, $18, nD2, nC2, $24
    smpsStop
@ch1:
    .db nG1, $08, nC2, nE2, nG2, nC3, nE3, nG3, $18, nE3, nGs1, $08, nC2, nEb2, nGs2, nC3, nEb3, nGs3, $18, nEb3
    .db nBb1, $08, nD2, nF2, nBb2, nD3, nF3, nBb3, $18, $08, $08, $08, nE3, $25
    smpsStop
@ch2:
    .db nRst, $08
    .db nE1, nG1, nC2, nE2, nG2, nC3, $18, nG2, $20, nEb1, $08, nGs1, nC2, nEb2, nGs2, nC3, $18
    .db nGs2, $20, nF1, $08, nBb1, nD2, nF2, nBb2, nD3, $18, $18, nC4, $25
    smpsStop
.ENDS


.SECTION "MUS Data - Death" BANK BANK_SOUND SLOT 2 FREE
Mus_Death:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Death@ch0,      $00, $03, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Death@ch1,      $00, $00, $00, $0B  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Death@ch2,      $00, $00, $00, $0C  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,    $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nRst, $24
    .db nG1, $08, nRst, $13, nG1, $08, nRst, $01, nG1, $08, nRst, $04, nA1, $08, nRst, $04
    .db nB1, $08, nRst, $04, nC2, $08, nRst, $0A, nG1, $08, nRst, $0A, nC1, $08
    smpsStop
@ch1:
    smpsModSetup    $00, $01, $10, $FF
    .db nBb2, $03, nB2, nC3, $1E
    smpsModSetup    $00, $01, $12, $FF
    smpsPSGVoice    $0C
    .db nG2, $09, nD3, $12, $09, $0C, nC3, nB2, nG2, $09, nE2, $12, $09, nC2, $0B
    smpsStop
@ch2:
    .db nRst, $24
    .db nB2, $09, nF3, $12, $09, $0C, nE3, nD3, nC3, $2F
    smpsStop
.ENDS

.SECTION "MUS Data - Game Over" BANK BANK_SOUND SLOT 2 FREE
Mus_GameOver:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_GameOver@ch0,   $00, $03, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_GameOver@ch1,   $00, $00, $00, $0A  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_GameOver@ch2,   $00, $00, $00, $0A  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,    $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nG1, $08, nRst, $13, nE1, $08, nRst, $13, nC1, $12, nF1, $24, nCs1, $36, nC1
    smpsStop
@ch1:
    .db nE2, $09, nRst, $12, nC2, $09, nRst, $12, nG1, nF2, $24, $36, nE2, $09, nD2, nE2, $25
    smpsStop
@ch2:
    smpsDetune  $FF
    .db nC3, $09, nRst, $12, nG2, $09, nRst, $12, nE2, nA2, $0C, nB2, nA2, nGs2, $12, nBb2, nGs2, nG2, $37
    smpsStop
.ENDS

.SECTION "MUS Data - World Victory" BANK BANK_SOUND SLOT 2 FREE
Mus_WorldVictory:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_WorldVictory@ch0,   $00, $03, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_WorldVictory@ch1,   $00, $00, $00, $0D  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_WorldVictory@ch2,   $00, $00, $00, $0D  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,        $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nC1, $34, nRst, $04, nC1, $0C, nRst, $04, nC1, nRst, nC1, nRst, nC1, nRst, nCs1, $34
    .db nRst, $04, nCs1, $0C, nRst, $04, nCs1, nRst, nCs1, nRst, nCs1, nRst, nBb1, nRst, nG1, nRst
    .db nEb1, nRst, nBb1, nRst, nG1, nRst, nEb1, nRst, nBb1, nRst, nBb1, $0C, nRst, $04, nC2, nRst
    .db $08, nC2, $04, nRst, $08, nC2, $04, nRst, $08, nD2, $40
    smpsStop
@ch1:
    .db nE2, $08, nC2, nG1, nE2, nC2, nG1, nE2, $08, $04, $04, $08, $08, $08, $08, nF2
    .db nCs2, nGs1, nF2, nCs2, nGs1, nF2, $08, $04, $04, $08, $08, $08, $08, nG2, nEb2, nBb1
    .db nG2, nEb2, nBb1, nG2, $08, $04, $04, $08, nA2, $0C, $0C, $0C, nB2, $41
    smpsStop
@ch2:
    .db nC3, $08, nG2, nE2, nC3, nG2, nE2, nC3, $30, nCs3, $08, nGs2, nF2, nCs3, nGs2, nF2
    .db nCs3, $30, nEb3, $08, nBb2, nG2, nEb3, nBb2, nG2, nEb3, $18, nF3, $0C, $0C, $0C, nG3
    .db $41
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


