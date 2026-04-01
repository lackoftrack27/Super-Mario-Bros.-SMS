;-------------------------------------------------------------------------------------

GameOverMode:
    LD A, (OperMode_Task)
    RST JumpEngine

    .dw SetupGameOver
    .dw ScreenRoutines
    .dw RunGameOver

;-------------------------------------------------------------------------------------

SetupGameOver:
    XOR A                           ;reset screen routine task control for title screen, game,
    LD (ScreenRoutineTask), A       ;and game over modes
    LD (Sprite0HitDetectFlag), A    ;disable sprite 0 check
    INC A
    LD (DisableScreenFlag), A       ;disable screen output
    LD (OperMode_Task), A           ;set secondary mode to 1
    LD A, SNDID_GAMEOVER
    LD (MusicTrack0.SoundQueue), A    ; EVENT
    RET

;-------------------------------------------------------------------------------------

RunGameOver:
    XOR A                           ;reenable screen
    LD (DisableScreenFlag), A
    LD A, (SavedJoypad1Bits)
    AND A, bitValue(SMS_BTN_1)      ;check controller for start pressed (button 1)
    JP NZ, TerminateGame
    LD A, (ScreenTimer)             ;if not pressed, wait for
    OR A                            ;screen timer to expire
    RET NZ
TerminateGame:
    LD A, SNDID_SILENCE
    LD (MusicTrack0.SoundQueue), A  ; EVENT
    CALL TransposePlayers           ;check if other player can keep
    JP C, ContinueGame              ;going, and do so if possible
    LD A, (WorldNumber)             ;otherwise put world number of current
    LD (ContinueWorld), A           ;player into secret continue function variable
    XOR A
    LD (OperMode_Task), A           ;reset all modes to title screen
    LD (ScreenTimer), A
    LD (OperMode), A
    RET

ContinueGame:
    CALL LoadAreaPointer            ;update level pointer with
    LD A, $01                       ;actual world and area numbers, then
    LD (PlayerSize), A              ;reset player's size, status, and
    LD HL, FetchNewGameTimerFlag    ;set game timer flag to reload
    INC (HL)
    XOR A                           ;game timer from header
    LD (TimerControl), A            ;also set flag for timers to count again
    LD (PlayerStatus), A
    LD (GameEngineSubroutine), A    ;reset task for game core
    LD (OperMode_Task), A           ;set modes and leave
    INC A                           ;if in game over mode, switch back to
    LD (OperMode), A                ;game mode, because game is still on
    RET

TransposePlayers:
    LD A, (NumberOfPlayers)         ;if only a 1 player game, leave
    OR A
    RET Z
    LD A, (OffScr_NumberofLives)    ;does offscreen player have any lives left?
    OR A
    RET M                           ;branch if not
    LD A, (CurrentPlayer)           ;invert bit to update
    XOR A, $01                      ;which player is on the screen
    LD (CurrentPlayer), A
    LD HL, OnscreenPlayerInfo       ;transpose the information
    LD DE, OffscreenPlayerInfo      ;of the onscreen player
    LD B, $07                       ;with that of the offscreen player
TransLoop:
    LD C, (HL)
    LD A, (DE)
    LD (HL), A
    LD A, C
    LD (DE), A
    INC L
    INC E
    DJNZ TransLoop
    SCF                             ;set carry flag to get game going
    RET