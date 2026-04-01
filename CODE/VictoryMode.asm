;-------------------------------------------------------------------------------------

VictoryMode:
    RET
/*
    CALL VictoryModeSubroutines     ;run victory mode subroutines
    LD A, (OperMode_Task)           ;get current task of victory mode
    OR A
    JP Z, @AutoPlayer               ;if on bridge collapse, skip enemy processing
    XOR A
    LD (ObjectOffset), A            ;otherwise reset enemy object offset 
    LD B, A
    CALL EnemiesAndLoopsCore        ;and run enemy code
@AutoPlayer:
    CALL RelativePlayerPosition     ;get player's relative coordinates
    JP PlayerGfxHandler             ;draw the player, then leave

VictoryModeSubroutines:
    LD A, (OperMode_Task)
    RST JumpEngine

    .dw BridgeCollapse
    .dw SetupVictoryMode
    .dw PlayerVictoryWalk
    .dw PrintVictoryMessages
    .dw PlayerEndWorld

;-------------------------------------------------------------------------------------

SetupVictoryMode:
    LD A, (ScreenRight_PageLoc)     ;get page location of right side of screen
    INC A                           ;increment to next page
    LD (DestinationPageLoc), A      ;store here
    LD A, EndOfCastleMusic
    LD (EventMusicQueue), A         ;play win castle music
    JP IncModeTask_B                ;jump to set next major task in victory mode

;-------------------------------------------------------------------------------------

PlayerVictoryWalk:
    XOR A                           ;set value here to not walk player by default
    LD (VictoryWalkControl), A
    LD C, A
    LD A, (Player_PageLoc)          ;get player's page location
    LD HL, DestinationPageLoc       ;compare with destination page location
    CP A, (HL)
    JP NZ, @PerformWalk             ;if page locations don't match, branch
    LD A, (Player_X_Position)       ;otherwise get player's horizontal position
    CP A, $60                       ;compare with preset horizontal position
    JP NC, @DontWalk                ;if still on other page, branch ahead
@PerformWalk:
    LD HL, VictoryWalkControl       ;otherwise increment value and Y
    INC (HL)
    INC C                           ;note Y will be used to walk the player
@DontWalk:
    LD A, C                         ;put contents of Y in A and
    CALL AutoControlPlayer          ;use A to move player to the right or not
    LD A, (ScreenLeft_PageLoc)      ;check page location of left side of screen
    LD HL, DestinationPageLoc       ;against set value here
    CP A, (HL)
    JP Z, @ExitVWalk                ;branch if equal to change modes if necessary
    LD A, (ScrollFractional)
    ADD A, $80                      ;do fixed point math on fractional part of scroll
    LD (ScrollFractional), A        ;save fractional movement amount
    LD A, $01                       ;set 1 pixel per frame
    ADC A, $00                      ;add carry from previous addition
    LD C, A                         ;use as scroll amount
    CALL ScrollScreen               ;do sub to scroll the screen
    CALL UpdScrollVar               ;do another sub to update screen and scroll variables
    LD HL, VictoryWalkControl       ;increment value to stay in this routine
    INC (HL)
@ExitVWalk:
    LD A, (VictoryWalkControl)      ;load value set here
    OR A
    JP Z, PrintVictoryMessages@IncModeTask_A    ;if zero, branch to change modes
    RET                             ;otherwise leave     

;-------------------------------------------------------------------------------------

PrintVictoryMessages:
    LD A, (SecondaryMsgCounter)     ;load secondary message counter
    OR A
    JP NZ, @IncMsgCounter           ;if set, branch to increment message counters
    LD A, (PrimaryMsgCounter)       ;otherwise load primary message counter
    OR A
    JP Z, @ThankPlayer              ;if set to zero, branch to print first message
    ;CP A, $09                       ;if at 9 or above, branch elsewhere (this comparison
    ;JP NC, @IncMsgCounter           ;is residual code, counter never reaches 9)
    LD E, A
    LD A, (WorldNumber)             ;check world number
    CP A, World8
    LD A, E
    JP NZ, @MRetainerMsg            ;if not at world 8, skip to next part
    CP A, $03                       ;check primary message counter again
    JP C, @IncMsgCounter            ;if not at 3 yet (world 8 only), branch to increment
    DEC A                           ;otherwise subtract one
    JP @ThankPlayer                 ;and skip to next part
@MRetainerMsg:
    CP A, $02                       ;check primary message counter
    JP C, @IncMsgCounter            ;if not at 2 yet (world 1-7 only), branch
@ThankPlayer:
    OR A
    LD C, A                         ;put primary message counter into Y
    JP NZ, @SecondPartMsg           ;if counter nonzero, skip this part, do not print first message
    LD A, (CurrentPlayer)           ;otherwise get player currently on the screen
    OR A
    JP Z, @EvalForMusic             ;if mario, branch
    INC C                           ;otherwise increment Y once for luigi and
    JP NZ, @EvalForMusic            ;do an unconditional branch to the same place
@SecondPartMsg:
    INC C                           ;increment Y to do world 8's message
    LD A, (WorldNumber)
    CP A, World8                    ;check world number
    JP Z, @EvalForMusic             ;if at world 8, branch to next part
    DEC C                           ;otherwise decrement Y for world 1-7's message
    LD A, C
    CP A, $04                       ;if counter at 4 (world 1-7 only)
    JP NC, @SetEndTimer             ;branch to set victory end timer
    CP A, $03                       ;if counter at 3 (world 1-7 only)
    JP NC, @IncMsgCounter           ;branch to keep counting
@EvalForMusic:
    LD A, C
    CP A, $03                       ;if counter not yet at 3 (world 8 only), branch
    JP NZ, @PrintMsg                ;to print message only (note world 1-7 will only
    LD A, VictoryMusic              ;reach this code if counter = 0, and will always branch)
    LD (EventMusicQueue), A         ;otherwise load victory music first (world 8 only)
@PrintMsg:
    LD A, C                         ;put primary message counter in A
    ADD A, $0C                      ;add $0c or 12 to counter thus giving an appropriate value, ($0c-$0d = first), ($0e = world 1-7's), ($0f-$12 = world 8's)
    LD (VRAM_Buffer_AddrCtrl), A    ;write message counter to vram address controller
@IncMsgCounter:
    LD A, (SecondaryMsgCounter)
    ADD A, $04                      ;add four to secondary message counter
    LD (SecondaryMsgCounter), A
    LD A, (PrimaryMsgCounter)
    ADC A, $00                      ;add carry to primary message counter
    LD (PrimaryMsgCounter), A
    CP A, $07                       ;check primary counter one more time
    RET C                           ;if not reached value yet, branch to leave
@SetEndTimer:
    LD A, $06
    LD (WorldEndTimer), A           ;otherwise set world end timer
@IncModeTask_A:
    LD HL, OperMode_Task            ;move onto next task in mode
    INC (HL)
    RET                             ;leave

;-------------------------------------------------------------------------------------

PlayerEndWorld:
    LD A, (WorldEndTimer)           ;check to see if world end timer expired
    OR A
    RET NZ                          ;branch to leave if not
    LD A, (WorldNumber)             ;check world number
    CP A, World8                    ;if on world 8, player is done with game, 
    JP NC, @EndChkBButton           ;thus branch to read controller
    XOR A
    LD (AreaNumber), A              ;otherwise initialize area number used as offset
    LD (LevelNumber), A             ;and level number control to start at area 1
    LD (OperMode_Task), A           ;initialize secondary mode of operation
    LD HL, WorldNumber              ;increment world number to move onto the next world
    INC (HL)
    CALL LoadAreaPointer            ;get area address offset for the next area
    LD HL, FetchNewGameTimerFlag    ;set flag to load game timer from header
    INC (HL)
    LD A, MODE_GAMEPLAY
    LD (OperMode), A                ;set mode of operation to game mode
    RET                             ;and leave
@EndChkBButton:
    LD A, (SavedJoypad1Bits)
    LD HL, SavedJoypad2Bits         ;check to see if B button was pressed on
    OR A, (HL)                      ;either controller
    AND A, bitValue(SMS_BTN_2)
    RET Z                           ;branch to leave if not
    LD A, $01                       ;otherwise set world selection flag
    LD (WorldSelectEnableFlag), A
    LD A, $FF                       ;remove onscreen player's lives
    LD (NumberofLives), A
    JP TerminateGame                ;do sub to continue other player or end game


;-------------------------------------------------------------------------------------
*/