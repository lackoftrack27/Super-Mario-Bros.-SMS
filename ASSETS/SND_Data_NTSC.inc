/*
-----------------------------------------------------------
                    NTSC MUSIC DATA
-----------------------------------------------------------
*/

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
    .db nRst, $60
    .db nG1, $0C
    smpsPSGVoice $00
    .db $24
    smpsPSGVoice $0E

@ch0Loop1:
    .db nC1, $0C, nG1, nC2, nB0, nG1, nB1, nC1, nG1, nC2, nE1, nG1, nC2
    smpsLoop $00, $02, Mus_Water@ch0Loop1
    
    .db nD1, nG1, nB1, nCs1, nFs1, nBb1
    
@ch0Loop2:
    .db nD1, nG1, nB1, nB0, nG1, nB1
    smpsLoop $00, $02, Mus_Water@ch0Loop2
    
    .db nC1, nG1, nC2, nG1, nG1, nC2
    
    .db nC1, nG1, nE2, nB0, nG1, nD2, nBb0, nG1, nCs2, nCs1, nG1, nE2, nD1, nA1
    .db nF2, nCs1, nA1, nF2, nC1, nA1, nF2, nB0, nG1, nF2, nC1, nG1, nE2
    
    .db nG1, $0C, $0C, $0C
    smpsPSGVoice $00
    .db nF1, $1E
    .db nB0, $06
    .db nC1, $24
    smpsPSGVoice $0E
    smpsJump Mus_Water@ch0

@ch1:
    .db nD2, $0C, nCs2, nC2, nB1, nC2, nCs2, nD2, $06, $06, $06, nRst, nE2, nRst, nF2, $24
    .db nG2, nFs2, nG2, $48, $24, nFs2, $18, nA2, $0C, nG2, $48, nF2, $24, nE2, nF2, $48
    .db $24, nB1, $18, nA2, $0C, nG2, $48, nE3, $24, nD3, nCs3, $48, nD3, $24, nCs3, nC3
    .db $48, nC2, $24, nF2, $0C, nG2, nB2, $0C, $06, $06, $12, nF2, $06, nE2, $24
    smpsJump Mus_Water@ch1
@ch2:
    .db nRst, $0C, nE2, nFs2, nG2, nA2, nBb2, nB2, $06, $06, $06, nRst, nB2, nRst, nB2, $18, nG2, $0C

    .db nE3, $24, nEb3, nE3, $2A, nG2, $06, nA2, nB2, nC3, nD3, nE3, $24, nEb3, $18, nF3, $0C, nE3, $42, nG2, $06
    .db nD3, $24, nCs3, nD3, $2A, nG2, $06, nA2, nB2, nC3, nCs3, nD3, $24, nG2, $18, nF3, $0C, nE3, $42, nG2, $06
    
@ch2Loop1:
    .db nG3, $24, $24, $24, $0C, nA3, $06, nRst, $0C, nG3, $06
    smpsTranspose $FE
    smpsLoop $00, $02, Mus_Water@ch2Loop1
    smpsTranspose $04

    .db nE3, $24, nA2, $0C, nB2, nF3, nE3, $06, $06, $12, nB2, $06, nC3, $24
    smpsJump Mus_Water@ch2
@ch3:
    smpsNoiseDrumMode
@ch3LoopPoint:
    .db nRst, $0C, nDrumH1, nDrumH5, $18, nDrumH1, $06, $06, nDrumH5, $0C
    smpsJump Mus_Water@ch3LoopPoint
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
    ; CHANNEL 0 DATA
@ch0:
    smpsCall Mus_Overworld@ch0Call1
@ch0LoopPoint:
    smpsCall Mus_Overworld@ch0Call2
    smpsCall Mus_Overworld@ch0Call3
    smpsCall Mus_Overworld@ch0Call4

    smpsCall Mus_Overworld@ch0Call1
    smpsCall Mus_Overworld@ch0Call2
    smpsCall Mus_Overworld@ch0Call5
    smpsCall Mus_Overworld@ch0Call5
    smpsCall Mus_Overworld@ch0Call4

    smpsCall Mus_Overworld@ch0Call1
    smpsCall Mus_Overworld@ch0Call5
    smpsJump Mus_Overworld@ch0LoopPoint
    ; CHANNEL 0 SUBROUTINES
@ch0Call1:
    .db nD1, $06, $0C, $0C, $06, $0C, nG2, $18, nG1
    smpsRet

@ch0Call2:
    .db nG1, $12, nE1, nC1, nF1, $0C, nG1, nFs1, $06, nF1, $0C, nE1, $08, nC2, nE2, nF2, $0C, nD2, $06, nE2, $0C, nC2, nA1, $06, nB1, nG1, $12
    smpsLoop $00, $02, Mus_Overworld@ch0Call2
    smpsRet

@ch0Call3i:
    .db nC1, $12, nG1, nC2, $0C, nF1, $12, nC2, $06, $0C, nF1
    smpsRet
@ch0Call3ii:
    .db nC1, $12, nE1, nG1, $06, nC2, $0C, nG3, $0C, $06, $0C, nG1
    smpsRet
@ch0Call3:
    smpsCall Mus_Overworld@ch0Call3i
    smpsCall Mus_Overworld@ch0Call3ii
    smpsCall Mus_Overworld@ch0Call3i
    .db nC1, nGs1, $12, nBb1, nC2, nG1, $06, $0C, nC1
    smpsLoop $00, $02, Mus_Overworld@ch0Call3
    smpsRet

@ch0Call4:
    .db nGs1, $12, nEb1, nGs1, $0C, nG1, $12, nC1, nG1, $0C
    smpsLoop $00, $03, Mus_Overworld@ch0Call4
    smpsRet

@ch0Call5i:
    .db nC1, $12, nFs1, $06, nG1, $0C, nC2, nF1, $0C, $0C, nC2, $06, $06, nF1, $0C
    smpsRet
@ch0Call5ii:
    .db nD1, $12, nF1, $06, nG1, $0C, nB1, nG1, $0C, $0C, nC2, $06, $06, nG1, $0C
    smpsRet
@ch0Call5:
    smpsCall Mus_Overworld@ch0Call5i
    smpsCall Mus_Overworld@ch0Call5ii
    smpsCall Mus_Overworld@ch0Call5i
    .db nG1, $12, $06, $08, nA1, nB1, nC2, $0C, nG1, nC1, $18
    smpsRet
    ; CHANNEL 1 DATA
@ch1:
    smpsCall Mus_Overworld@ch1Call1
@ch1LoopPoint:
    smpsCall Mus_Overworld@ch1Call2
    smpsNoAtk
    .db $0C
    smpsCall Mus_Overworld@ch1Call3
    smpsNoAtk
    .db $0C
    smpsCall Mus_Overworld@ch1Call3
    smpsCall Mus_Overworld@ch1Call4

    smpsCall Mus_Overworld@ch1Call1
    smpsCall Mus_Overworld@ch1Call2
    smpsCall Mus_Overworld@ch1Call5
    smpsCall Mus_Overworld@ch1Call5
    smpsCall Mus_Overworld@ch1Call4

    smpsCall Mus_Overworld@ch1Call1
    smpsCall Mus_Overworld@ch1Call5
    smpsJump Mus_Overworld@ch1LoopPoint
    ; CHANNEL 1 SUBROUTINES
@ch1Call1:
    .db nFs2, $06, $0C, $0C, $06, $0C, nB2, $18, nG2 
    smpsRet

@ch1Call2:
    .db nE2, $12, nC2, nG1, nC2, $0C, nD2, nCs2, $06, nC2, $0C, $08, nG2, nB2, nC3, $0C, nA2, $06, nB2, $0C, nA2, nE2, $06, nF2, nD2, $12
    smpsLoop $00, $02, Mus_Overworld@ch1Call2
    smpsRet

@ch1Call3i:
    .db nE3, $06, nEb3, nD3, nB2, $0C, nC3, nE2, $06, nF2, nG2, $0C, nC2, $06, nE2, nF2, $12
    smpsRet
@ch1Call3:
    smpsCall Mus_Overworld@ch1Call3i
    .db nE3, $06, nEb3, nD3, nB2, $0C, nC3, nF3, $0C, $06, $24
    smpsCall Mus_Overworld@ch1Call3i
    .db nGs2, nF2, nE2, $30
    smpsRet

@ch1Call4:
    smpsCall Mus_Overworld@ch1Call4i
    .db nGs2, $06, $0C, $0C, $06, nBb2, nG2, $36
@ch1Call4i:
    .db nGs2, $06, $0C, $0C, $06, nBb2, $0C, nG2, $06, nE2, $0C, $06, nC2, $18
    smpsRet

@ch1Call5i:
    .db nC3, $06, nA2, $0C, nE2, $12, $0C, nF2, $06, nC3, $0C, $06, nF2, $18
    smpsRet
@ch1Call5ii:
    .db nG2, $08, nF3, $08, $08, $08, nE3, nD3, nC3, $06, nA2, $0C, nF2, $06, nE2, $18
    smpsRet
@ch1Call5:
    smpsCall Mus_Overworld@ch1Call5i
    smpsCall Mus_Overworld@ch1Call5ii
    smpsCall Mus_Overworld@ch1Call5i
    .db nG2, $06, nD3, $0C, $06, $08, nC3, nB2, nG2, $06, nE2, $0C, $06, nC2, $18
    smpsRet
    ; CHANNEL 2 DATA
@ch2:
    smpsCall Mus_Overworld@ch2Call1
@ch2LoopPoint:
    smpsCall Mus_Overworld@ch2Call2
    smpsNoAtk
    .db $0C
    smpsCall Mus_Overworld@ch2Call3
    smpsNoAtk
    .db $0C
    smpsCall Mus_Overworld@ch2Call3
    smpsCall Mus_Overworld@ch2Call4

    smpsCall Mus_Overworld@ch2Call1
    smpsCall Mus_Overworld@ch2Call2
    smpsCall Mus_Overworld@ch2Call5
    smpsCall Mus_Overworld@ch2Call5
    smpsCall Mus_Overworld@ch2Call4

    smpsCall Mus_Overworld@ch2Call1
    smpsCall Mus_Overworld@ch2Call5
    smpsJump Mus_Overworld@ch2LoopPoint
    ; CHANNEL 2 SUBROUTINES
@ch2Call1:
    .db nE3, $06, $0C, $0C, nC3, $06, nE3, $0C, nG3, $30
    smpsRet

@ch2Call2:
    .db nC3, $12, nG2, nE2, nA2, $0C, nB2, nBb2, $06, nA2, $0C, nG2, $08, nE3, nG3, nA3, $0C, nF3, $06, nG3, $0C, nE3, nC3, $06, nD3, nB2, $12
    smpsLoop $00, $02, Mus_Overworld@ch2Call2
    smpsRet

@ch2Call3i:
    .db nG3, $06, nFs3, nF3, nEb3, $0C, nE3, nGs2, $06, nA2, nC3, $0C, nA2, $06, nC3, nD3, $12
    smpsRet
@ch2Call3:
    smpsCall Mus_Overworld@ch2Call3i
    .db nG3, $06, nFs3, nF3, nEb3, $0C, nE3, nC4, $0C, $06, $24
    smpsCall Mus_Overworld@ch2Call3i
    .db nEb3, nD3, nC3, $30
    smpsRet

@ch2Call4:
    smpsCall Mus_Overworld@ch2Call4i
    .db nC3, $06, $0C, $0C, $06, nD3, nE3, $36
@ch2Call4i:
    .db nC3, $06, $0C, $0C, $06, nD3, $0C, nE3, $06, nC3, $0C, nA2, $06, nG2, $18
    smpsRet

@ch2Call5i:
    .db nE3, $06, nC3, $0C, nG2, $12, nGs2, $0C, nA2, $06, nF3, $0C, $06, nA2, $18
    smpsRet
@ch2Call5ii:
    .db nB2, $08, nA3, $08, $08, $08, nG3, nF3, nE3, $06, nC3, $0C, nA2, $06, nG2, $18
    smpsRet
@ch2Call5:
    smpsCall Mus_Overworld@ch2Call5i
    smpsCall Mus_Overworld@ch2Call5ii
    smpsCall Mus_Overworld@ch2Call5i
    .db nB2, $06, nF3, $0C, $06, $08, nE3, nD3, nC3, $30
    smpsRet
    ; CHANNEL 3 DATA
@ch3:
    smpsNoiseDrumMode
    smpsCall Mus_Overworld@ch3Call1
@ch3LoopPoint:
@ch3Loop1:
    smpsCall Mus_Overworld@ch3Call2
    smpsLoop $00, $18, Mus_Overworld@ch3Loop1

@ch3Loop2:
    smpsCall Mus_Overworld@ch3Call1
    smpsLoop $00, $04, Mus_Overworld@ch3Loop2

@ch3Loop3:
    smpsCall Mus_Overworld@ch3Call2
    smpsLoop $00, $08, Mus_Overworld@ch3Loop3

@ch3Loop4:
    smpsCall Mus_Overworld@ch3Call3
    smpsLoop $00, $10, Mus_Overworld@ch3Loop4

@ch3Loop5:
    smpsCall Mus_Overworld@ch3Call1
    smpsLoop $00, $04, Mus_Overworld@ch3Loop5

@ch3Loop6:
    smpsCall Mus_Overworld@ch3Call3
    smpsLoop $00, $08, Mus_Overworld@ch3Loop6

    smpsJump Mus_Overworld@ch3LoopPoint
    ; CHANNEL 3 SUBROUTINES
@ch3Call1:
    .db nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, nDrumH1, $06, nDrumH5, $0C, $12, $0C, nDrumH1, $06, $06, $06
    smpsRet

@ch3Call2:
    .db nDrumM1, $0C, nDrumH1, $08, $04, nDrumH5, $0C, nDrumH1, $08, $04
    smpsRet

@ch3Call3:
    .db nDrumH1, $12, $06, nDrumH5, $0C, nDrumH1 
    smpsRet
.ENDS

.SECTION "MUS Data - Underground" BANK BANK_SOUND SLOT 2 FREE
Mus_Underground:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $55  ; $55, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Underground@ch0,    $18, $0F, $00, $00  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Silence@ch0,        $00, $0F, $00, $00  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Underground@ch0,    $00, $00, $00, $07  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Underground@ch3,    $00, $02, $00, $0E  ; NOISE     (CH3)
    ; CHANNEL 0/2 DATA
@ch0:
    .db nC2, $06, nC3, nA1, nA2, nBb1, nBb2, $2A
    .db nC2, $06, nC3, nA1, nA2, nBb1, nBb2, $2A

    .db nF1, $06, nF2, nD1, nD2, nEb1, nEb2, $2A
    .db nF1, $06, nF2, nD1, nD2, nEb1, nEb2, $1E

    .db $04, nD2, nCs2, nC2, $0C, nEb2, nD2
    .db nGs1, nG1
    .db nCs2, nC2, $04, nFs2, nF2, nE2, nBb2, nA2, nGs2, $08, nEb2, nB1, nBb1, nA1
    .db nGs1, $50
    smpsJump Mus_Underground@ch0
    ; CHANNEL 3 DATA (USED FOR VOLUME ONLY)
@ch3:
    .db nCh2P, $06, $06, $06, $06, $06, $2A 
    .db nCh2P, $06, $06, $06, $06, $06, $2A

    .db $06, $06, $06, $06, $06, $2A
    .db $06, $06, $06, $06, $06, $1E

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
    ; CHANNEL 0 DATA
@ch0:
    .db nEb1, $40, nD1, $20, nFs1, nF1, $40, nE1, $20, nBb1, nA1, nE1, nEb1, nE1
    smpsJump Mus_Castle@ch0
    ; CHANNEL 1 DATA
@ch1:
    .db nRst, $04

@ch1Loop1:
    .db nD3, $08, nCs3, nC3, nCs3, nD3, nEb3, nD3, nCs3
    smpsLoop $00, $02, Mus_Castle@ch1Loop1

@ch1Loop2:
    .db nCs3, nC3, nCs3, nD3, nCs3, nD3, nCs3, nC3
    smpsLoop $00, $02, Mus_Castle@ch1Loop2
    
@ch1Loop3:
    .db nF3, nFs3, nF3, nE3, nF3, nE3, nEb3, nE3
    smpsLoop $00, $02, Mus_Castle@ch1Loop3
    smpsJump Mus_Castle@ch1Loop1
    ; CHANNEL 2 DATA
@ch2:
    .db nG2, $04, nBb2, nG2, nA2, nG2, nGs2, nG2, nA2, nG2, nBb2, nG2, nB2, nG2, nBb2, nG2, nA2
    smpsLoop $00, $02, Mus_Castle@ch2
    
@ch2Loop2:
    .db nFs2, nA2, nFs2, nGs2, nFs2, nA2, nFs2, nBb2, nFs2, nA2, nFs2, nBb2, nFs2, nA2, nFs2, nGs2
    smpsLoop $00, $02, Mus_Castle@ch2Loop2
    
@ch2Loop3:
    .db nBb2, nD3, nBb2, nEb3, nBb2, nD3, nBb2, nCs3, nBb2, nD3, nBb2, nCs3, nBb2, nC3, nBb2, nCs3
    smpsLoop $00, $02, Mus_Castle@ch2Loop3
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
    .db nD1, $0C, nA1, $09, nD2, $0F, nA1, $06, nD2
    .db nC1, $0C, nG1, $09, nC2, $0F, nG1, $06, nC2
    smpsJump Mus_Invincible@ch0
@ch1:
    .db nF2, $06, $06, $06, nD2, $03, nF2, $06, $06, nD2, $03, nF2, nD2, nF2, $06
    .db nE2, $06, $06, $06, nC2, $03, nE2, $06, $06, nC2, $03, nE2, nC2, nE2, $06
    smpsJump Mus_Invincible@ch1
@ch2:
    .db nC3, $06, $06, $09, $06, $09, $06, $06
    .db nB2, $06, $06, $09, $06, $09, $06, $06
    smpsJump Mus_Invincible@ch2
@ch3:
    smpsNoiseDrumMode
@ch3LoopPoint:
    .db nDrumM1, $06, nDrumH1, $04, $02, nDrumH5, $06, nDrumH1, $04, $02
    smpsJump Mus_Invincible@ch3LoopPoint
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
    smpsCall Mus_Overworld@ch0Call1
    smpsStop
@ch1:
    smpsCall Mus_Overworld@ch1Call1
    smpsStop
@ch2:
    smpsCall Mus_Overworld@ch2Call1
    smpsStop
@ch3:
    smpsNoiseDrumMode
    smpsCall Mus_Overworld@ch3Call1
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
    .db nC1, $08, nE1, nG1, nE2, $18, nC2, $08, nRst, $28
    .db nC1, $08, nEb1, nGs1, nEb2, $18, nC2, $08, nRst, $28
    .db nD1, $08, nF1, nBb1, nF2, $18, nD2, nC2, $24
    smpsStop
@ch1:
    .db nG1, $08, nC2, nE2, nG2, nC3, nE3, nG3, $18, nE3
    .db nGs1, $08, nC2, nEb2, nGs2, nC3, nEb3, nGs3, $18, nEb3
    .db nBb1, $08, nD2, nF2, nBb2, nD3, nF3, nBb3, $18, $08, $08, $08
    .db nE3, $25
    smpsStop
@ch2:
    .db nRst, $08
    .db nE1, nG1, nC2, nE2, nG2, nC3, $18, nG2, $20
    .db nEb1, $08, nGs1, nC2, nEb2, nGs2, nC3, $18, nGs2, $20
    .db nF1, $08, nBb1, nD2, nF2, nBb2, nD3, $18, $18, nC4, $25
    smpsStop
.ENDS


.SECTION "MUS Data - Death" BANK BANK_SOUND SLOT 2 FREE
Mus_Death:
    ; MAIN HEADER
    smpsHeader      $00, $04, $01, $00
    ; CHANNEL HEADERS
    smpsChanHeader  Mus_Death@ch0,      $00, $03, $00, $0E  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_Death@ch1,      $00, $00, $00, $0B  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_Death@ch2,      $00, $00, $00, $0C  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,    $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nRst, $24
    .db nG1, $1B, $09, $0C, nA1, nB1, nC2, $12, nG1, nC1
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
    smpsChanHeader  Mus_GameOver@ch0,   $00, $03, $00, $0E  ; TRIANGLE  (CH2)
    smpsChanHeader  Mus_GameOver@ch1,   $00, $00, $00, $0A  ; PULSE 1   (CH0)
    smpsChanHeader  Mus_GameOver@ch2,   $00, $00, $00, $0A  ; PULSE 2   (CH1)
    smpsChanHeader  Mus_Silence@ch0,    $00, $0F, $00, $00  ; NOISE     (CH3)
@ch0:
    .db nG1, $1B, nE1
    smpsPSGVoice $00
    .db nC1, $12, nF1, $24, nCs1, $36, nC1
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
    ; CHANNEL 0 DATA
@ch0:
    .db nC1, $34, nRst, $04, nC1, $0C, nRst, $04, nC1, nRst, nC1, nRst, nC1, nRst
    smpsTranspose $01
    smpsLoop $00, $02, Mus_WorldVictory@ch0
    smpsTranspose $FE

@ch0Loop2:
    .db nBb1, nRst, nG1, nRst, nEb1, nRst
    smpsLoop $00, $02, Mus_WorldVictory@ch0Loop2
    
    .db nBb1, nRst, nBb1, $0C, nRst, $04, nC2, nRst, $08, nC2, $04, nRst, $08, nC2, $04, nRst, $08, nD2, $40
    smpsStop
    ; CHANNEL 1 DATA
@ch1:
    smpsCall Mus_WorldVictory@ch1Call1
    .db $08, $08, $08
    smpsTranspose $01
    smpsLoop $00, $02, Mus_WorldVictory@ch1

    smpsTranspose $01
    smpsCall Mus_WorldVictory@ch1Call1
    
    smpsTranspose $FD
    .db nA2, $0C, $0C, $0C, nB2, $41
    smpsStop
    ; CHANNEL 1 SUBROUTINE
@ch1Call1:
    .db nE2, $08, nC2, nG1, nE2, nC2, nG1, nE2, $08, $04, $04, $08
    smpsRet
    ; CHANNEL 2 DATA
@ch2:
    smpsCall Mus_WorldVictory@ch2Call1
    smpsNoAtk
    .db $18
    smpsTranspose $01
    smpsLoop $00, $02, Mus_WorldVictory@ch2

    smpsTranspose $01
    smpsCall Mus_WorldVictory@ch2Call1

    smpsTranspose $FD
    .db nF3, $0C, $0C, $0C, nG3, $41
    smpsStop
    ; CHANNEL 2 SUBROUTINE
@ch2Call1:
    .db nC3, $08, nG2, nE2, nC3, nG2, nE2, nC3, $18
    smpsRet
.ENDS