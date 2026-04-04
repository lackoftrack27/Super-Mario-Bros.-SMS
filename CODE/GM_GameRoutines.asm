;-------------------------------------------------------------------------------------

GameRoutines:
    LD A, (GameEngineSubroutine)        ;run routine based on number (a few of these routines are
    RST JumpEngine                     ;merely placeholders as conditions for other routines)

    .dw Entrance_GameTimerSetup
    .dw Vine_AutoClimb
    .dw SideExitPipeEntry
    .dw VerticalPipeEntry
    .dw FlagpoleSlide
    .dw PlayerEndLevel
    .dw PlayerLoseLife
    .dw PlayerEntrance
    .dw PlayerCtrlRoutine
    .dw PlayerChangeSize
    .dw PlayerInjuryBlink
    .dw PlayerDeath
    .dw PlayerFireFlower

;-------------------------------------------------------------------------------------

.SECTION "Player Initial X Pos TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PlayerStarting_X_Pos:
    .db $28, $18
    .db $38, $28

AltYPosOffset:
    .db $08, $00
.ENDS

.SECTION "Player Initial Y Pos TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PlayerStarting_Y_Pos:
    ;.db $00, $20, $b0, $50, $00, $00, $b0, $b0
    ;.db $f0
    .db $00, $08, $98, $38, $00, $00, $98, $98
    .db $D8
.ENDS

.SECTION "Player Priority TBL & Game Timer TBL" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PlayerBGPriorityData:
    .db $00, $20, $00, $00, $00, $00, $00, $00

GameTimerData:
    .db $20 ;dummy byte, used as part of bg priority data
    .db $04, $03, $02
.ENDS

Entrance_GameTimerSetup:
    LD A, (ScreenLeft_PageLoc)          ;set current page for area objects
    LD (Player_PageLoc), A              ;as page location for player
;
    LD A, $28                           ;store value here
    LD (VerticalForceDown), A           ;for fractional movement downwards if necessary
;
    LD A, $01                           ;set high byte of player position and
    LD (PlayerFacingDir), A             ;set facing direction so that player faces right
    LD (Player_Y_HighPos), A
;
    XOR A                               ;set player state to on the ground by default
    LD (Player_State), A
;
    LD HL, Player_CollisionBits         ;initialize player's collision bits
    DEC (HL)
;
    LD (HalfwayPage), A                 ;initialize halfway page
;
    LD A, (AreaType)                    ;check area type
    OR A
    LD A, $00
    JP NZ, ChkStPos                     ;if water type, set swimming flag, otherwise do not set
    INC A
ChkStPos:
    LD (SwimmingFlag), A
;
    LD A, (PlayerEntranceCtrl)          ;get starting position loaded from header
    LD B, A
    LD A, (AltEntranceControl)          ;check alternate mode of entry flag for 0 or 1
    OR A
    JP Z, SetStPos
    CP A, $01
    JP Z, SetStPos
    LD HL, AltYPosOffset-2
    addAToHL8_M
    LD B, (HL)                          ;if not 0 or 1, override $0710 with new offset in X
SetStPos:
    LD A, (AltEntranceControl)
    LD HL, PlayerStarting_X_Pos
    addAToHL8_M
    LD A, (HL)                          ;load appropriate horizontal position
    LD (Player_X_Position), A           ;and vertical positions for the player, using
;
    LD HL, PlayerStarting_Y_Pos
    LD A, B
    addAToHL8_M
    LD A, (HL)                          ;AltEntranceControl as offset for horizontal and either $0710
    LD (Player_Y_Position), A           ;or value that overwrote $0710 as offset for vertical
;
    LD HL, PlayerBGPriorityData
    LD A, B
    addAToHL8_M
    LD A, (HL)
    LD (Player_SprAttrib), A
;
    CALL GetPlayerColors                ;get appropriate player palette
;
    LD A, (GameTimerSetting)            ;get timer control value from header
    OR A
    JP Z, ChkOverR                      ;if set to zero, branch (do not use dummy byte for this)
    LD A, (FetchNewGameTimerFlag)       ;do we need to set the game timer? if not, use 
    OR A
    JP Z, ChkOverR                      ;old game timer setting
;
    LD HL, GameTimerData
    LD A, (GameTimerSetting)
    addAToHL8_M
    LD A, (HL)                          ;if game timer is set and game timer flag is also set,

    .IF SHORTTIMER != $00
    LD A, $02                           ;shorter timer to quickly get to 'Hurry Up'
    .ENDIF

    LD (GameTimerDisplay), A            ;use value of game timer control for first digit of game timer
    LD A, $01
    LD (GameTimerDisplay+2), A          ;set last digit of game timer to 1
    XOR A
    LD (GameTimerDisplay+1), A          ;set second digit of game timer
    LD (FetchNewGameTimerFlag), A       ;clear flag for game timer reset
    LD (StarInvincibleTimer), A         ;clear star mario timer
ChkOverR:
    LD A, (JoypadOverride)              ;if controller bits not set, branch to skip this part
    OR A
    JP Z, ChkSwimE
    LD A, $03                           ;set player state to climbing
    LD (Player_State), A
    LD H, $C0 + OBJ_BLOCK1              ;set offset for first slot, for block object
    CALL InitBlock_XY_Pos
    LD A, $F0                           ;set vertical coordinate for block object
    LD (Block_Y_Position), A
    LD H, $C0 + OBJ_SLOT6               ;set offset in X for last enemy object buffer slot, set offset in Y for object coordinates used earlier
    LD D, $C0 + OBJ_BLOCK1
    CALL Setup_Vine_NOPOP               ;do a sub to grow vine
ChkSwimE:
    LD A, (AreaType)                    ;if level is water-type,
    OR A
    CALL Z, SetupBubble                 ;execute sub to set up air bubbles
    LD A, $07                           ;set to run player entrance subroutine
    LD (GameEngineSubroutine), A        ;on the next frame of game engine
    RET

;-------------------------------------------------------------------------------------

Vine_AutoClimb:
    LD A, (Player_Y_HighPos)            ;check to see whether player reached position
    OR A
    JP NZ, AutoClimb                    ;above the status bar yet and if so, set modes
    LD A, (Player_Y_Position)
    CP A, $E4 - SMS_PIXELYOFFSET
    JP C, SetEntr
AutoClimb:
    LD A, %00001000                     ;set controller bits override to up
    LD (JoypadOverride), A
    LD A, $03                           ;set player state to climbing
    LD (Player_State), A
    JP AutoControlPlayer
SetEntr:
    LD A, $02                           ;set starting position to override
    LD (AltEntranceControl), A
    JP ChgAreaMode                      ;set modes

;-------------------------------------------------------------------------------------

SideExitPipeEntry:
    CALL EnterSidePipe                  ;execute sub to move player to the right
    LD C, $02
ChgAreaPipe:
    LD HL, ChangeAreaTimer              ;decrement timer for change of area
    DEC (HL)
    RET NZ
    LD HL, AltEntranceControl           ;when timer expires set mode of alternate entry
    LD (HL), C
ChgAreaMode:
   XOR A
   LD (OperMode_Task), A                ;set secondary mode of operation
   LD (Sprite0HitDetectFlag), A         ;disable sprite 0 check
   INC A
   LD (DisableScreenFlag), A            ;set flag to disable screen output
   RET

EnterSidePipe:
    LD A, $08                           ;set player's horizontal speed
    LD (Player_X_Speed), A
    LD C, $01                           ;set controller right button by default
    LD A, (Player_X_Position)           ;mask out higher nybble of player's
    AND A, %00001111                    ;horizontal position
    JP NZ, RightPipe
    LD (Player_X_Speed), A              ;if lower nybble = 0, set as horizontal speed
    LD C, A                             ;and nullify controller bit override here
RightPipe:
    LD A, C                             ;use contents of Y to
    JP AutoControlPlayer                ;execute player control routine with ctrl bits nulled

;-------------------------------------------------------------------------------------

VerticalPipeEntry:
    LD A, $01                           ;set 1 as movement amount
    CALL MovePlayerYAxis                ;do sub to move player downwards
    CALL ScrollHandler                  ;do sub to scroll screen with saved force if necessary
    LD C, $00                           ;load default mode of entry
    LD A, (WarpZoneControl)             ;check warp zone control variable/flag
    OR A
    JP NZ, ChgAreaPipe                  ;if set, branch to use mode 0
    INC C
    LD A, (AreaType)                    ;check for castle level type
    CP A, $03
    JP NZ, ChgAreaPipe                  ;if not castle type level, use mode 1
    INC C
    JP ChgAreaPipe                      ;otherwise use mode 2

;   MOVETHIS??
MovePlayerYAxis:
    LD HL, Player_Y_Position            ;add contents of A to player position
    ADD A, (HL)
    LD (HL), A
    RET

;-------------------------------------------------------------------------------------

FlagpoleSlide:
    LD A, (Enemy_ID + $05 * $100)       ;check special use enemy slot
    CP A, OBJECTID_FlagpoleFlagObject   ;for flagpole flag object
    JP NZ, NoFPObj                      ;if not found, branch to something residual
    LD A, (FlagpoleSoundQueue)          ;load flagpole sound
    LD (SFXTrack0.SoundQueue), A        ;into square 1's sfx queue
    XOR A
    LD (FlagpoleSoundQueue), A          ;init flagpole sound queue
    LD A, (Player_Y_Position)
    CP A, $9E - SMS_PIXELYOFFSET        ;check to see if player has slid down
    LD A, $00
    JP NC, SlidePlayer                  ;far enough, and if so, branch with no controller bits set
    LD A, bitValue(SMS_BTN_DOWN)        ;otherwise force player to climb down (to slide)
SlidePlayer:
    JP AutoControlPlayer                ;jump to player control routine
NoFPObj:
    LD HL, GameEngineSubroutine         ;increment to next routine (this may
    INC (HL)                            ;be residual code)
    RET

;-------------------------------------------------------------------------------------

.SECTION "Hidden1UpCoinAmts" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
Hidden1UpCoinAmts:
    .db $15, $23, $16, $1b, $17, $18, $23, $63
.ENDS
    
PlayerEndLevel:
    LD A, $01                           ;force player to walk to the right
    CALL AutoControlPlayer
    LD A, (Player_Y_Position)           ;check player's vertical position
    CP A, $AE - SMS_PIXELYOFFSET
    JP C, ChkStop                       ;if player is not yet off the flagpole, skip this part
    LD A, (ScrollLock)                  ;if scroll lock not set, branch ahead to next part
    OR A
    JP Z, ChkStop                       ;because we only need to do this part once
    LD A, SNDID_LEVELDONE               ;load win level music in event music queue
    LD (MusicTrack0.SoundQueue), A      ; EVENT
    XOR A                               ;turn off scroll lock to skip this part later
    LD (ScrollLock), A
ChkStop:
    LD A, (Player_CollisionBits)        ;get player collision bits
    SRL A                               ;check for d0 set
    JP C, RdyNextA                      ;if d0 set, skip to next part
    LD A, (StarFlagTaskControl)         ;if star flag task control already set,
    OR A
    JP NZ, InCastle                     ;go ahead with the rest of the code
    INC A
    LD (StarFlagTaskControl), A         ;otherwise set task control now (this gets ball rolling!)
InCastle:
    ;LD A, (Player_SprAttrib)
    ;OR A, %00100000                    ;set player's background priority bit to
    ;LD (Player_SprAttrib), A           ;give illusion of being inside the castle
    LD A, $01                           ;(SMS)set flag to hide player since sprites can't have attributes
    LD (HidePlayerFlag), A
RdyNextA:
    LD A, (StarFlagTaskControl)         ;if star flag task control not yet set
    CP A, $05                           
    RET NZ                              ;beyond last valid task number, branch to leave
    LD HL, LevelNumber                  ;increment level number used for game logic
    INC (HL)
    LD A, (HL)
    CP A, $03                           ;check to see if we have yet reached level -4
    JP NZ, NextArea                     ;and skip this last part here if not
    LD HL, Hidden1UpCoinAmts
    LD A, (WorldNumber)                 ;get world number as offset
    addAToHL8_M
    LD A, (CoinTallyFor1Ups)            ;check third area coin tally for bonus 1-ups
    CP A, (HL)                          ;against minimum value, if player has not collected
    JP C, NextArea                      ;at least this number of coins, leave flag clear
    LD HL, Hidden1UpFlag                ;otherwise set hidden 1-up box control flag
    INC (HL)
NextArea:
    LD HL, AreaNumber                   ;increment area number used for address loader
    INC (HL)
    CALL LoadAreaPointer                ;get new level pointer
    LD HL, FetchNewGameTimerFlag        ;set flag to load new game timer
    INC (HL)
    CALL ChgAreaMode                    ;do sub to set secondary mode, disable screen and sprite 0
    XOR A
    LD (HalfwayPage), A                 ;reset halfway page to 0 (beginning)
    LD A, SNDID_SILENCE
    LD (MusicTrack0.SoundQueue), A      ; EVENT

    .IF SMSPOWERCOMP != $00
    JP BootVector                       ;reset game after 1st level
    .ENDIF
    RET

;-------------------------------------------------------------------------------------

;page numbers are in order from -1 to -4
.SECTION "HalfwayPageNybbles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
HalfwayPageNybbles:
    .db $56, $40
    .db $65, $70
    .db $66, $40
    .db $66, $40
    .db $66, $40
    .db $66, $60
    .db $65, $70
    .db $00, $00
.ENDS

PlayerLoseLife:
    XOR A
    LD (Sprite0HitDetectFlag), A        ;disable screen and sprite 0 check
    LD (SndHurryUpFlag), A
    INC A
    LD (DisableScreenFlag), A
    LD A, SNDID_SILENCE
    LD (MusicTrack0.SoundQueue), A      ; EVENT
    LD HL, NumberofLives                ;take one life from player
    DEC (HL)
    JP P, StillInGame                   ;if player still has lives, branch
    XOR A
    LD (OperMode_Task), A               ;initialize mode task,
    LD A, MODE_GAMEOVER                 ;switch to game over mode
    LD (OperMode), A
    RET
StillInGame:
    LD A, (WorldNumber)                 ;multiply world number by 2 and use
    ADD A, A                            ;as offset
    LD B, A
    LD A, (LevelNumber)                 ;if in area -3 or -4, increment
    AND A, $02                          ;offset by one byte, otherwise
    JP Z, GetHalfway                    ;leave offset alone
    INC B
GetHalfway:
    LD A, B
    LD HL, HalfwayPageNybbles
    addAToHL8_M
    LD C, (HL)                          ;get halfway page number with offset
    LD A, (LevelNumber)                 ;check area number's LSB
    SRL A
    LD A, C                             ;if in area -2 or -4, use lower nybble
    JP C, MaskHPNyb
    RRCA                                ;move higher nybble to lower if area
    RRCA                                ;number is -1 or -3
    RRCA
    RRCA
MaskHPNyb:
    AND A, %00001111                    ;mask out all but lower nybble
    LD HL, ScreenLeft_PageLoc
    CP A, (HL)
    JP Z, SetHalfway                    ;left side of screen must be at the halfway page,
    JP C, SetHalfway                    ;otherwise player must start at the
    XOR A                               ;beginning of the level
SetHalfway:
    LD (HalfwayPage), A                 ;store as halfway page for player
    CALL TransposePlayers               ;switch players around if 2-player game
    JP ContinueGame                     ;continue the game

;-------------------------------------------------------------------------------------

PlayerEntrance:
    LD A, (AltEntranceControl)          ;check for mode of alternate entry
    CP A, $02
    JP Z, EntrMode2                     ;if found, branch to enter from pipe or with vine
    LD A, (Player_Y_Position)           ;if vertical position above a certain
    CP A, $30 - SMS_PIXELYOFFSET        ;point, nullify controller bits and continue
    LD C, A
    LD A, $00
    JP C, AutoControlPlayer             ;with player movement code, do not return
    LD A, (PlayerEntranceCtrl)          ;check player entry bits from header
    CP A, $06
    JP Z, ChkBehPipe                    ;if set to 6 or 7, execute pipe intro code
    CP A, $07                           ;otherwise branch to normal entry
    JP NZ, PlayerRdy
ChkBehPipe:
    LD A, (Player_SprAttrib)            ;check for sprite attributes
    AND A, %00100000
    JP NZ, IntroEntr                    ;branch if found
    LD A, $01
    JP AutoControlPlayer                ;force player to walk to the right
IntroEntr:
    CALL EnterSidePipe                  ;execute sub to move player to the right
    LD HL, ChangeAreaTimer              ;decrement timer for change of area
    DEC (HL)
    RET NZ                              ;branch to exit if not yet expired
    LD HL, DisableIntermediate          ;set flag to skip world and lives display
    INC (HL)
    JP NextArea                         ;jump to increment to next area and set modes
EntrMode2:
    LD A, (JoypadOverride)              ;if controller override bits set here,
    OR A
    JP NZ, VineEntr                     ;branch to enter with vine
    LD A, $FF                           ;otherwise, set value here then execute sub
    CALL MovePlayerYAxis                ;to move player upwards (note $ff = -1)
    LD A, (Player_Y_Position)           ;check to see if player is at a specific coordinate
    CP A, $91 - SMS_PIXELYOFFSET        ;if player risen to a certain point (this requires pipes
    JP C, PlayerRdy                     ;to be at specific height to look/function right) branch
    RET                                 ;to the last part, otherwise leave
VineEntr:
    LD A, (VineHeight)                  
    CP A, $60                           ;check vine height
    RET NZ                              ;if vine not yet reached maximum height, branch to leave
    LD A, (Player_Y_Position)           ;get player's vertical coordinate
    CP A, $99 - SMS_PIXELYOFFSET        ;check player's vertical coordinate against preset value
    LD C, $00                           ;load default values to be written to 
    LD A, $01                           ;this value moves player to the right off the vine
    JP C, OffVine                       ;if vertical coordinate < preset value, use defaults
    LD A, $03
    LD (Player_State), A                ;otherwise set player state to climbing
    INC C                               ;increment value in Y
    LD A, $08                           ;set block in block buffer to cover hole, then
    LD (Block_Buffer_1+$b4), A  ; CHANGE??? ;use same value to force player to climb
OffVine:
    LD HL, DisableCollisionDet
    LD (HL), C                          ;set collision detection disable flag
    CALL AutoControlPlayer              ;use contents of A to move player up or right, execute sub
    LD A, (Player_X_Position)
    CP A, $48                           ;check player's horizontal position
    RET C                               ;if not far enough to the right, branch to leave
PlayerRdy:
    LD A, $08                           ;set routine to be executed by game engine next frame
    LD (GameEngineSubroutine), A
    LD A, $01                           ;set to face player to the right
    LD (PlayerFacingDir), A
    XOR A                               ;init A
    LD (AltEntranceControl), A          ;init mode of entry
    LD (DisableCollisionDet), A         ;init collision detection disable flag
    LD (JoypadOverride), A              ;nullify controller override bits
    RET

;-------------------------------------------------------------------------------------
;$07 (IXL) - used to hold upper limit of high byte when player falls down hole

;   A - CONTROL INPUT
AutoControlPlayer:
    LD (SavedJoypadBits), A             ;override controller bits with contents of A if executing here

PlayerCtrlRoutine:
    LD A, (GameEngineSubroutine)        ;check task here
    CP A, $0B                           ;if certain value is set, branch to skip controller bit loading
    JP Z, SizeChk
;
    LD A, (AreaType)                    ;are we in a water type area?
    OR A
    JP NZ, SaveJoyp                     ;if not, branch
;
    LD A, (Player_Y_HighPos)
    DEC A                               ;if not in vertical area between
    JP NZ, DisJoyp                      ;status bar and bottom, branch
;
    LD A, (Player_Y_Position)
    CP A, $D0 - SMS_PIXELYOFFSET        ;if nearing the bottom of the screen or
    JP C, SaveJoyp                      ;not in the vertical area between status bar or bottom,
DisJoyp:
    XOR A                               ;disable controller bits
    LD (SavedJoypadBits), A
SaveJoyp:
    LD HL, SavedJoypadBits
    LD A, (HL)                          ;otherwise store A and B buttons in $0a
    AND A, %11000000
    LD (A_B_Buttons), A
    LD A, (HL)                          ;store left and right buttons in $0c
    AND A, %00000011
    LD (Left_Right_Buttons), A
    LD A, (HL)                          ;store up and down buttons in $0b
    AND A, %00001100
    LD (Up_Down_Buttons), A
    AND A, %00000100                    ;check for pressing down
    JP Z, SizeChk                       ;if not, branch
    LD A, (Player_State)                ;check player's state
    OR A
    JP NZ, SizeChk                      ;if not on the ground, branch
    LD A, (Left_Right_Buttons)          ;check left and right
    OR A
    JP Z, SizeChk                       ;if neither pressed, branch
    XOR A
    LD (Left_Right_Buttons), A          ;if pressing down while on the ground,
    LD (Up_Down_Buttons), A             ;nullify directional bits
SizeChk:
    CALL PlayerMovementSubs             ;run movement subroutines
    LD C, $01                           ;is player small?
    LD A, (PlayerSize)
    OR A
    JP NZ, ChkMoveDir
    LD C, $00                           ;check for if crouching
    LD A, (CrouchingFlag)
    OR A
    JP Z, ChkMoveDir                    ;if not, branch ahead
    LD C, $02                           ;if big and crouching, load y with 2
ChkMoveDir:
    LD A, C
    LD (Player_BoundBoxCtrl), A         ;set contents of Y as player's bounding box size control
    LD A, (Player_X_Speed)              ;check player's horizontal speed
    OR A
    LD A, $01                           ;set moving direction to right by default
    JP Z, PlayerSubs                    ;if not moving at all horizontally, skip this part
    JP P, SetMoveDir                    ;if moving to the right, use default moving direction
    ADD A, A                            ;otherwise change to move to the left
SetMoveDir:
    LD (Player_MovingDir), A            ;set moving direction
PlayerSubs:
    CALL ScrollHandler                  ;move the screen if necessary
    CALL GetPlayerOffscreenBits         ;get player's offscreen bits
    CALL RelativePlayerPosition         ;get coordinates relative to the screen
    LD H, >Player_BoundBoxCtrl          ;set offset for player object
    LD D, H
    CALL BoundingBoxCore                ;get player's bounding box coordinates
    CALL PlayerBGCollision              ;do collision detection and process
    LD A, (Player_Y_Position)
    CP A, $40 - SMS_PIXELYOFFSET        ;check to see if player is higher than 64th pixel
    JP C, PlayerHole                    ;if so, branch ahead
    LD A, (GameEngineSubroutine)
    CP A, $05                           ;if running end-of-level routine, branch ahead
    JP Z, PlayerHole
    CP A, $07                           ;if running player entrance routine, branch ahead
    JP Z, PlayerHole
    CP A, $04                           ;if running routines $00-$03, branch ahead
    JP C, PlayerHole
    LD A, (Player_SprAttrib)
    AND A, %11011111                    ;otherwise nullify player's
    LD (Player_SprAttrib), A            ;background priority flag
PlayerHole:
    LD A, (Player_Y_HighPos)            ;check player's vertical high byte
    CP A, $02                           ;for below the screen
    RET M                               ;branch to leave if not that far down
    LD A, $01                           ;set scroll lock
    LD (ScrollLock), A
    LD IXL, $04                         ;set value here
    LD B, $00                           ;use X as flag, and clear for cloud level
    LD A, (GameTimerExpiredFlag)        ;check game timer expiration flag
    OR A
    JP NZ, HoleDie                      ;if set, branch
    LD A, (CloudTypeOverride)           ;check for cloud type override
    OR A
    JP NZ, ChkHoleX                     ;skip to last part if found
HoleDie:
    INC B                               ;set flag in X for player death
    LD A, (GameEngineSubroutine)
    CP A, $0B                           ;check for some other routine running
    JP Z, ChkHoleX                      ;if so, branch ahead
    LD A, (DeathMusicLoaded)            ;check value here
    OR A
    JP NZ, HoleBottom                   ;if already set, branch to next part
    INC A
    LD (DeathMusicLoaded), A            ;and set value here
    LD A, SNDID_DEATH
    LD (MusicTrack0.SoundQueue), A      ; EVENT
HoleBottom:
    LD IXL, $06                         ;change value here
ChkHoleX:
    LD A, (Player_Y_HighPos)
    CP A, IXL                           ;compare vertical high byte with value set here
    RET M                               ;if less, branch to leave
    DEC B                               ;otherwise decrement flag in X
    JP M, CloudExit                     ;if flag was clear, branch to set modes and other values
    ;LD A, (EventMusicBuffer)            ;check to see if music is still playing
    ;OR A
    ;RET NZ                              ;branch to leave if so
    LD A, (MusicTrack0.SoundPlaying)
    CP A, SNDID_GAMEOVER
    RET Z

    LD A, $06                           ;otherwise set to run lose life routine
    LD (GameEngineSubroutine), A        ;on next frame
    RET

CloudExit:
    XOR A
    LD (JoypadOverride), A              ;clear controller override bits if any are set
    CALL SetEntr                        ;do sub to set secondary mode
    LD HL, AltEntranceControl           ;set mode of entry to 3
    INC (HL)
    RET

;-------------------------------------------------------------------------------------

PlayerChangeSize:
    LD A, (TimerControl)                ;check master timer control
    CP A, $F8                           ;for specific moment in time
    JP Z, InitChangeSize                ;branch if before or after that point
    CP A, $C4                           ;check again for another specific moment
    RET NZ                              ;and branch to leave if before or after that point
    JP DonePlayerTask                   ;otherwise do sub to init timer control and set routine

;-------------------------------------------------------------------------------------

PlayerInjuryBlink:
    LD A, (TimerControl)                ;check master timer control
    CP A, $F0                           ;for specific moment in time
    JP NC, ExitBlink                    ;branch if before that point
    CP A, $C8                           ;check again for another specific point
    JP Z, DonePlayerTask                ;branch if at that point, and not before or after
    JP PlayerCtrlRoutine                ;otherwise run player control routine

ExitBlink:
    RET NZ
InitChangeSize:
    LD A, (PlayerChangeSizeFlag)        ;if growing/shrinking flag already set
    OR A
    RET NZ                              ;then branch to leave
    LD (PlayerAnimCtrl), A              ;otherwise initialize player's animation frame control
    LD HL, PlayerChangeSizeFlag         ;set growing/shrinking flag
    INC (HL)
    LD A, (PlayerSize)                  ;invert player's size
    XOR A, $01
    LD (PlayerSize), A
    RET

;-------------------------------------------------------------------------------------

PlayerDeath:
    LD A, (TimerControl)                ;check master timer control
    CP A, $F0                           ;for specific moment in time
    RET NC                              ;branch to leave if before that point
    JP PlayerCtrlRoutine                ;otherwise run player control routine

DonePlayerTask:
    XOR A
    LD (TimerControl), A                ;initialize master timer control to continue timers
    LD A, $08
    LD (GameEngineSubroutine), A        ;set player control routine to run next frame
    RET

;-------------------------------------------------------------------------------------
;$00 (IXL) - used in CyclePlayerPalette to store current palette to cycle

PlayerFireFlower:
    LD A, (TimerControl)                ;check master timer control
    CP A, $C0                           ;for specific moment in time
    JP Z, ResetPalFireFlower            ;branch if at moment, not before or after
    LD A, (FrameCounter)                ;get frame counter
    RRCA                                ;divide by four to change every four frames
    RRCA                             

CyclePlayerPalette:
    AND A, $03                          ;mask out all but d1-d0 (previously d3-d2)
    LD IXL, A                           ;store result here to use as palette bits
    LD A, (Player_SprAttrib)            ;get player attributes
    AND A, %11111100                    ;save any other bits but palette bits
    OR A, IXL                           ;add palette bits
    LD (Player_SprAttrib), A            ;store as new player attributes
    RET

ResetPalFireFlower:
    LD A, (Player_SprAttrib)
    AND A, %11111100
    OR A, $02
    LD (Player_SprAttrib), A
    JP DonePlayerTask                 ;do sub to init timer control and run player control routine
    ;CALL DonePlayerTask

ResetPalStar:
    /*
    LD A, (Player_SprAttrib)
    AND A, %00000011
    RET Z
    LD A, (PlayerStatus)
    CP A, $02
    RET Z
;
    LD A, (Player_SprAttrib)            ;get player attributes
    AND A, %11111100                    ;mask out palette bits to force palette 0
    LD (Player_SprAttrib), A            ;store as new player attributes
    RET
    */
    ;LD A, (Player_SprAttrib)
    ;AND A, %00000011
    ;RET Z
    ;JP GetPlayerColors



















;-------------------------------------------------------------------------------------
;These apply to all routines in this section unless otherwise noted:
;$00 - used to store metatile from block buffer routine
;$02(IXL) - used to store vertical high nybble offset from block buffer routine
;$05 - used to store metatile stored in A at beginning of PlayerHeadCollision
;$06-$07 - used as block buffer address indirect

.SECTION "BlockYPosAdderData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BlockYPosAdderData:
    .db $04, $12                    ; BIG, SMALL/CROUCH
    ;.db $12, $12, $12, $12
.ENDS

PlayerHeadCollision:
    PUSH AF                         ;store metatile number to stack
;
    LD A, (SprDataOffset_Ctrl)      ;load offset control bit here
    ADD A, $C0 + OBJ_BLOCK1
    LD H, A
;
    LD A, (PlayerSize)              ;check player's size
    OR A
    LD A, $11                       ;load unbreakable block object state by default
    JP NZ, DBlockSte
    INC A                           ;otherwise load breakable block object state
DBlockSte:
    LD L, <Block_State
    LD (HL), A                      ;store into block object buffer
;
    PUSH HL                         ;(SMS) save offset control bit
    LD HL, (Temp_Bytes + $06)       ;(SMS) load block buffer addr for DestroyBlockMetatile
    CALL DestroyBlockMetatile       ;store blank metatile in vram buffer to write to name table
    POP HL                          ;(SMS) get offset control bit back
;
    LD L, <Block_Orig_YPos
    LD A, IXL                       ;get vertical high nybble offset used in block buffer routine
    LD (HL), A                      ;set as vertical coordinate for block object
;
    LD L, <Block_BBuf_Low
    LD DE, (Temp_Bytes + $06)       ;get low byte of block buffer address used in same routine
    LD (HL), E                      ;save as offset here to be used later
;
    LD A, IXL
    addAToDE_M
    LD A, (DE)                      ;get contents of block buffer at old address at $06, $07
    CALL BlockBumpedChk             ;do a sub to check which block player bumped head on
;
    LD (Temp_Bytes + $00), A        ;store metatile here
    LD C, A
    LD A, (PlayerSize)              ;check player's size
    BIT 0, A
    JP NZ, ChkBrick                 ;if small, use metatile itself as contents of A
    LD C, A                         ;otherwise init metatile
ChkBrick:
    JP C, PutMTileB                 ;if no match was found in previous sub, skip ahead
;
    LD L, <Block_State              ;otherwise load unbreakable state into block object buffer
    LD (HL), $11                    ;note this applies to both player sizes
;
    LD C, MT_EMPTYBLK               ;load empty block metatile into A for now
    LD A, (Temp_Bytes + $00)        ;get metatile from before
    CP A, MT_SBRICK_COIN            ;is it brick with coins (with line)?
    JP Z, StartBTmr                 ;if so, branch
    CP A, MT_BRICK_COIN             ;is it brick with coins (without line)?
    JP NZ, PutMTileB                ;if not, branch ahead to store empty block metatile
;
StartBTmr:
    LD C, A
    LD A, (BrickCoinTimerFlag)      ;check brick coin timer flag
    OR A
    JP NZ, ContBTmr                 ;if set, timer expired or counting down, thus branch
;
    LD A, $0B
    LD (BrickCoinTimer), A          ;if not set, set brick coin timer
    LD A, $01
    LD (BrickCoinTimerFlag), A      ;and set flag linked to it
;
ContBTmr:
    LD A, (BrickCoinTimer)          ;check brick coin timer
    OR A
    JP NZ, PutMTileB                ;if not yet expired, branch to use current metatile
    LD C, MT_EMPTYBLK               ;otherwise use empty block metatile
PutMTileB:
    LD L, <Block_Metatile
    LD (HL), C                      ;store whatever metatile be appropriate here
;
    CALL InitBlock_XY_Pos           ;get block object horizontal coordinates saved
;
    LD DE, (Temp_Bytes + $06)
    LD A, IXL                       ;get vertical high nybble offset
    addAToDE_M
    LD A, MT_HITBLANK
    LD (DE), A                      ;write blank metatile to block buffer
;
    LD A, $10
    LD (BlockBounceTimer), A        ;set block bounce timer
;
    POP AF                          ;pull original metatile from stack
    LD (Temp_Bytes + $05), A        ;and save here
;
    LD DE, BlockYPosAdderData       ;set default offset
    LD A, (CrouchingFlag)           ;add crouching flag to offset
    addAToDE8_M
    LD A, (PlayerSize)              ;add player size to offset
    addAToDE8_M
    LD A, (Player_Y_Position)       ;get player's vertical coordinate
    ADD A, SMS_PIXELYOFFSET
    EX DE, HL
    ADD A, (HL)                     ;add value determined by size
    EX DE, HL
    AND A, $F0                      ;mask out low nybble to get 16-pixel correspondence
    ;SUB A, $08                      ;(SMS)add 8 due to status bar size difference
    SUB A, SMS_PIXELYOFFSET
    LD L, <Block_Y_Position
    LD (HL), A                      ;save as vertical coordinate for block object
;
    LD L, <Block_State              ;get block object state
    LD A, (HL)
    CP A, $11
    JP Z, Unbreak                   ;if set to value loaded for unbreakable, branch
    CALL BrickShatter               ;execute code for breakable brick
    JP InvOBit                      ;skip subroutine to do last part of code here
Unbreak:
    CALL BumpBlock                  ;execute code for unbreakable brick or question block
;
InvOBit:
    LD A, (SprDataOffset_Ctrl)      ;invert control bit used by block objects
    XOR A, $01                      ;and floatey numbers
    LD (SprDataOffset_Ctrl), A
    RET

;--------------------------------

InitBlock_XY_Pos:
    LD A, (Player_X_Position)       ;get player's horizontal coordinate
    ADD A, $08                      ;add eight pixels
    LD C, A                         ;save new position for later
    LD A, (Player_PageLoc)
    ADC A, $00                      ;add carry to page location of player
    LD L, <Block_PageLoc            ;save as page location of block object
    LD (HL), A
    LD L, <Block_PageLoc2           ;save elsewhere to be used later
    LD (HL), A
    LD A, C                         ;get altered position back
    AND A, $F0                      ;mask out low nybble to give 16-pixel correspondence
    LD L, <Block_X_Position         ;save as horizontal coordinate for block object
    LD (HL), A
;
    LD A, (Player_Y_HighPos)        ;save vertical high byte of player into
    LD L, <Block_Y_HighPos          ;vertical high byte of block object and leave
    LD (HL), A
    RET

;--------------------------------

BumpBlock:
    CALL CheckTopOfBlock            ;check to see if there's a coin directly above this block
;
    LD A, SNDID_BUMP                ;play bump sound
    LD (SFXTrack0.SoundQueue), A
;
    XOR A
    LD L, <Block_X_Speed            ;initialize horizontal speed for block object
    LD (HL), A
    LD L, <Block_Y_MoveForce        ;init fractional movement force
    LD (HL), A
    LD (Player_Y_Speed), A          ;init player's vertical speed
    LD L, <Block_Y_Speed            ;set vertical speed for block object
    LD (HL), $FE
;
    LD A, (Temp_Bytes + $05)        ;get original metatile from stack
    CALL BlockBumpedChk             ;do a sub to check which block player bumped head on
    RET C                           ;if no match was found, branch to leave
;
    LD A, B                         ;move block number to A
    DEC A
    CP A, $09                       ;if block number was within 0-8 range,
    JP C, BlockCode                 ;branch to use current number
    SUB A, $05                      ;otherwise subtract 5 for second set to get proper number
BlockCode:
    PUSH HL
    RST JumpEngine                 ;run appropriate subroutine depending on block number

    .dw MushFlowerBlock
    .dw CoinBlock
    .dw CoinBlock
    .dw ExtraLifeMushBlock
    .dw MushFlowerBlock
    .dw VineBlock
    .dw StarBlock
    .dw CoinBlock
    .dw ExtraLifeMushBlock

;--------------------------------

MushFlowerBlock:
    POP HL
    XOR A
    LD (PowerUpType), A
    JP SetupPowerUp

StarBlock:
    POP HL
    LD A, $02
    LD (PowerUpType), A
    JP SetupPowerUp

ExtraLifeMushBlock:
    POP HL
    LD A, $03
    LD (PowerUpType), A
    JP SetupPowerUp

VineBlock:
    POP HL
    LD H, OBJ_SLOT6
    LD A, (SprDataOffset_Ctrl)
    ADD A, $C0 + OBJ_BLOCK1
    LD D, A
    JP Setup_Vine_NOPOP

;--------------------------------

.SECTION "BrickQBlockMetatiles" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BrickQBlockMetatiles:
    ;used by question blocks
    .db MT_QBLK_PUP, MT_QBLK_COIN, MT_HIDDENBLK_COIN, MT_HIDDENBLK_1UP
    ;these two sets are functionally identical, but look different
    .db MT_SBRICK_PUP, MT_SBRICK_VINE, MT_SBRICK_STAR, MT_SBRICK_COIN, MT_SBRICK_1UP
    .db MT_BRICK_PUP, MT_BRICK_VINE, MT_BRICK_STAR, MT_BRICK_COIN, MT_BRICK_1UP
.ENDS

;   INPUT:  A - METATILE
;   OUTPUT: NC - BLOCK FOUND, C - BLOCK NOT FOUND
BlockBumpedChk:
    LD DE, BrickQBlockMetatiles + $0D   ;start at end of metatile data
    LD B, $0E
    EX DE, HL
BumpChkLoop:
    CP A, (HL)                          ;check to see if current metatile matches
    JP Z, MatchBump                     ;metatile found in block buffer, branch if so
    DEC L                               ;otherwise move onto next metatile
    DJNZ BumpChkLoop                    ;do this until all metatiles are checked
    SCF                                 ;if none match, return with carry set
MatchBump:
    EX DE, HL
    RET                                 ;note carry is clear if found match
    
;--------------------------------

BrickShatter:
    CALL CheckTopOfBlock
;
    LD L, <Block_RepFlag
    LD (HL), $01
;
    LD A, SNDID_SHATTER
    LD (SFXTrack2.SoundQueue), A
;
    CALL SpawnBrickChunks
;
    LD A, $FE
    LD (Player_Y_Speed), A
    LD A, $05
    LD (DigitModifier + $05 * $100), A
;
    CALL AddToScore
;
    LD A, (SprDataOffset_Ctrl)
    ADD A, $C0 + OBJ_BLOCK1
    LD H, A
    RET

;--------------------------------

CheckTopOfBlock:
    LD A, (SprDataOffset_Ctrl)
    ADD A, $C0 + OBJ_BLOCK1
    LD H, A
;
    LD A, IXL
    OR A
    RET Z
;
    SUB A, $10
    LD IXL, A
    LD DE, (Temp_Bytes + $06)
    addAToDE_M
    LD A, (DE)
    CP A, MT_COIN
    RET NZ
;
    XOR A
    LD (DE), A
    LD HL, (Temp_Bytes + $06)           ;(SMS)put block buffer addr into HL for PutBlockMetatile
    CALL RemoveCoin_Axe
    LD A, (SprDataOffset_Ctrl)
    ADD A, $C0 + OBJ_BLOCK1
    LD H, A
    JP SetupJumpCoin

;--------------------------------

SpawnBrickChunks:
    LD L, <Block_X_Position
    LD A, (HL)
    INC H 
    INC H
    LD (HL), A
;
    DEC H
    DEC H
    LD L, <Block_Orig_XPos
    LD (HL), A
;
    LD L, <Block_X_Speed
    LD (HL), $F0
    LD L, <Block_Y_Speed
    LD (HL), $FA
    LD L, <Block_Y_MoveForce
    LD (HL), $00
    INC H
    INC H
    LD (HL), $00
    LD L, <Block_Y_Speed
    LD (HL), $FC
    LD L, <Block_X_Speed
    LD (HL), $F0
;
    DEC H
    DEC H
    LD L, <Block_PageLoc
    LD A, (HL)
    INC H
    INC H
    LD (HL), A
;
    DEC H
    DEC H
    LD L, <Block_Y_Position
    LD A, (HL)
    ADD A, $08
    INC H
    INC H
    LD (HL), A
;
    DEC H
    DEC H
    RET


;-------------------------------------------------------------------------------------

PlayerMovementSubs:
    LD A, (PlayerSize)                  ;is player small?
    OR A
    LD A, $00                           ;set A to init crouch flag by default
    JP NZ, SetCrouch                    ;if so, branch
;
    LD A, (Player_State)                ;check state of player
    OR A
    JP NZ, ProcMove                     ;if not on the ground, branch
;
    LD A, (Up_Down_Buttons)             ;load controller bits for up and down
    AND A, %00000100                    ;single out bit for down button
    RRCA
    RRCA
SetCrouch:
    LD (CrouchingFlag), A               ;store value in crouch flag
ProcMove:
    CALL PlayerPhysicsSub               ;run sub related to jumping and swimming
    LD A, (PlayerChangeSizeFlag)        ;if growing/shrinking flag set,
    OR A
    RET NZ                              ;branch to leave
;
    LD A, (Player_State)                ;get player state
    CP A, $03
    JP Z, MoveSubs                      ;if climbing, branch ahead, leave timer unset
    LD HL, ClimbSideTimer               ;otherwise reset timer now
    LD (HL), $18
MoveSubs:
    RST JumpEngine

    .dw OnGroundStateSub
    .dw JumpSwimSub
    .dw FallingSub
    .dw ClimbingSub


;-------------------------------------------------------------------------------------
;$00 - used by ClimbingSub to store high vertical adder

OnGroundStateSub:
    CALL GetPlayerAnimSpeed             ;do a sub to set animation frame timing
;
    LD A, (Left_Right_Buttons)
    OR A
    JP Z, GndMove                       ;if left/right controller bits not set, skip instruction
    LD (PlayerFacingDir), A             ;otherwise set new facing direction
GndMove:
    CALL ImposeFriction                 ;do a sub to impose friction on player's walk/run
    CALL MovePlayerHorizontally         ;do another sub to move player horizontally
    LD (Player_X_Scroll), A             ;set returned value as player's movement speed for scroll
    RET

;--------------------------------

FallingSub:
    LD A, (VerticalForceDown)
    LD (VerticalForce), A               ;dump vertical movement force for falling into main one
    JP LRAir                            ;movement force, then skip ahead to process left/right movement

;--------------------------------

JumpSwimSub:
    LD A, (Player_Y_Speed)              ;if player's vertical speed zero
    OR A
    JP P, DumpFall                      ;or moving downwards, branch to falling
;
    LD A, (A_B_Buttons)
    AND A, bitValue(SMS_BTN_2)          ;check to see if A button is being pressed
    LD HL, PreviousA_B_Buttons
    AND A, (HL)                         ;and was pressed in previous frame
    JP NZ, ProcSwim                     ;if so, branch elsewhere
;
    LD A, (JumpOrigin_Y_Position)       ;get vertical position player jumped from
    LD HL, Player_Y_Position
    SUB A, (HL)                         ;subtract current from original vertical coordinate
    LD HL, DiffToHaltJump
    CP A, (HL)                          ;compare to value set here to see if player is in mid-jump
    JP C, ProcSwim                      ;or just starting to jump, if just starting, skip ahead
DumpFall:
    LD A, (VerticalForceDown)           ;otherwise dump falling into main fractional
    LD (VerticalForce), A
ProcSwim:
    LD A, (SwimmingFlag)                ;if swimming flag not set,
    OR A
    JP Z, LRAir                         ;branch ahead to last part
;
    CALL GetPlayerAnimSpeed             ;do a sub to get animation frame timing
    LD A, (Player_Y_Position)
    CP A, $14 - SMS_PIXELYOFFSET        ;check vertical position against preset value
    JP NC, LRWater                      ;if not yet reached a certain position, branch ahead
;
    LD A, $18
    LD (VerticalForce), A               ;otherwise set fractional
LRWater:
    LD A, (Left_Right_Buttons)          ;check left/right controller bits (check for swimming)
    OR A
    JP Z, LRAir                         ;if not pressing any, skip
    LD (PlayerFacingDir), A             ;otherwise set facing direction accordingly
LRAir:
    LD A, (Left_Right_Buttons)          ;check left/right controller bits (check for jumping/falling)
    OR A
    JP Z, JSMove                        ;if not pressing any, skip
    CALL ImposeFriction                 ;otherwise process horizontal movement
JSMove:
    CALL MovePlayerHorizontally         ;do a sub to move player horizontally
    LD (Player_X_Scroll), A             ;set player's speed here, to be used for scroll later
;
    LD A, (GameEngineSubroutine)        ;check for specific routine selected
    CP A, $0B
    JP NZ, MovePlayerVertically         ;branch if not set to run
;
    LD A, $28                           ;otherwise set fractional
    LD (VerticalForce), A
    JP MovePlayerVertically             ;jump to move player vertically, then leave

;--------------------------------

.SECTION "ClimbAdderLow/High" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
ClimbAdderLow:
    .db $0e, $04, $fc, $f2
ClimbAdderHigh:
    .db $00, $00, $ff, $ff
.ENDS

ClimbingSub:
    LD C, $00
    LD A, (Player_Y_Speed)
    OR A
    JP P, +
    DEC C
+:
    LD HL, Player_YMF_Dummy
    LD A, (Player_Y_MoveForce)
    ADD A, (HL)
    LD (HL), A
;MoveOnVine:
    LD A, (Player_Y_Speed)
    LD HL, Player_Y_Position
    ADC A, (HL)
    LD (HL), A
;
    LD A, (Player_Y_HighPos)
    ADC A, C
    LD (Player_Y_HighPos), A
;
    LD A, (Left_Right_Buttons)
    LD HL, Player_CollisionBits
    AND A, (HL)
    JP Z, InitCSTimer
;
    LD E, A                     ;save to E
    LD A, (ClimbSideTimer)
    OR A
    RET NZ
;
    LD A, $18
    LD (ClimbSideTimer), A
    LD B, $00
    LD A, (PlayerFacingDir)
    SRL E
    JP C, ClimbFD
    INC B
    INC B
ClimbFD:
    DEC A
    JP Z, CSetFDir
    INC B
CSetFDir:
    LD A, B
    LD HL, ClimbAdderLow
    addAToHL8_M
    LD A, (Player_X_Position)
    ADD A, (HL)
    LD (Player_X_Position), A
;
    INC L
    INC L
    INC L
    INC L
    LD A, (Player_PageLoc)
    ADC A, (HL)
    LD (Player_PageLoc), A
;
    LD A, (Left_Right_Buttons)
    XOR A, %00000011
    LD (PlayerFacingDir), A
    RET
InitCSTimer:
    LD (ClimbSideTimer), A
    RET

;-------------------------------------------------------------------------------------
;$00 - used to store offset to friction data

.SECTION "Player Physics TBLs" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
JumpMForceData:
    .db $20, $20, $1e, $28, $28, $0d, $04

FallMForceData:
    .db $70, $70, $60, $90, $90, $0a, $09

InitMForceData:
    .db $00, $00, $00, $00, $00, $80, $00

PlayerYSpdData:
    .db $fc, $fc, $fc, $fb, $fb, $fe, $ff

MaxLeftXSpdData:
    .db $d8, $e8, $f0

MaxRightXSpdData:
    .db $28, $18, $10
    .db $0c ;used for pipe intros

FrictionData:
    .db $e4, $98, $d0

Climb_Y_SpeedData:
    .db $00, $ff, $01

Climb_Y_MForceData:
    .db $00, $20, $ff
.ENDS

PlayerPhysicsSub:
    LD A, (Player_State)                ;check player state
    CP A, $03
    JP NZ, CheckForJumping              ;if not climbing, branch
;
    LD DE, Climb_Y_MForceData
    LD A, (Up_Down_Buttons)             ;get controller bits for up/down
    LD HL, Player_CollisionBits
    AND A, (HL)                         ;check against player's collision detection bits
    JP Z, ProcClimb                     ;if not pressing up or down, branch
;
    INC E
    AND A, %00001000                    ;check for pressing up
    JP NZ, ProcClimb
;
    INC E
ProcClimb:
    LD A, (DE)                          ;load value here
    LD (Player_Y_MoveForce), A          ;store as vertical movement force
;
    DEC E
    DEC E
    DEC E                               ;Climb_Y_SpeedData
    LD A, (DE)                          ;load some other value here
    LD (Player_Y_Speed), A              ;store as vertical speed
    OR A
    LD A, $08                           ;load default animation timing
    JP M, SetCAnim                      ;if climbing down, use default animation timing value
    RRCA                                ;otherwise divide timer setting by 2
SetCAnim:
    LD (PlayerAnimTimerSet), A          ;store animation timer setting and leave
    RET

CheckForJumping:
    LD A, (JumpspringAnimCtrl)          ;if jumpspring animating,
    OR A
    JP NZ, X_Physics                    ;skip ahead to something else
;
    LD A, (A_B_Buttons)                 ;check for A button press
    AND A, bitValue(SMS_BTN_2)
    JP Z, X_Physics                     ;if not, branch to something else
;
    LD HL, PreviousA_B_Buttons          ;if button not pressed in previous frame, branch
    AND A, (HL)
    JP NZ, X_Physics                    ;otherwise, jump to something else

ProcJumping:
    LD A, (Player_State)                ;check player state
    OR A
    JP Z, InitJS                        ;if on the ground, branch
;
    LD A, (SwimmingFlag)                ;if swimming flag not set, jump to do something else
    OR A
    JP Z, X_Physics                     ;to prevent midair jumping, otherwise continue
;
    LD A, (JumpSwimTimer)               ;if jump/swim timer nonzero, branch
    OR A
    JP NZ, InitJS
;
    LD A, (Player_Y_Speed)              ;check player's vertical speed
    OR A
    JP M, X_Physics                     ;if timer at zero and player still rising, do not swim
InitJS:
    LD A, $20                           ;set jump/swim timer
    LD (JumpSwimTimer), A
;
    XOR A                               ;initialize vertical force and dummy variable
    LD (Player_YMF_Dummy), A
    LD (Player_Y_MoveForce), A
;   
    LD A, (Player_Y_HighPos)            ;get vertical high and low bytes of jump origin
    LD (JumpOrigin_Y_HighPos), A        ;and store them next to each other here
;
    LD A, (Player_Y_Position)
    LD (JumpOrigin_Y_Position), A
;
    LD A, $01                           ;set player state to jumping/swimming
    LD (Player_State), A
;
    LD DE, JumpMForceData
    LD A, (Player_XSpeedAbsolute)       ;check value related to walking/running speed
    CP A, $09
    JP C, ChkWtr                        ;branch if below certain values, increment Y
    INC E                               ;for each amount equal or exceeded
    CP A, $10
    JP C, ChkWtr
    INC E
    CP A, $19
    JP C, ChkWtr
    INC E
    CP A, $1C
    JP C, ChkWtr                        ;note that for jumping, range is 0-4 for Y
    INC E
ChkWtr:
    LD A, $01                           ;set value here (apparently always set to 1)
    LD (DiffToHaltJump), A
    LD A, (SwimmingFlag)                ;if swimming flag disabled, branch
    OR A
    JP Z, GetYPhy
    LD E, <JumpMForceData + $05         ;otherwise set Y to 5, range is 5-6
    LD A, (Whirlpool_Flag)              ;if whirlpool flag not set, branch
    OR A
    JP Z, GetYPhy
    INC E                               ;otherwise increment to 6
GetYPhy:
    LD A, (DE)                          ;store appropriate jump/swim
    LD (VerticalForce), A               ;data here
;
    LD A, $07
    ADD A, E
    LD E, A                             ;FallMForceData
    LD A, (DE)
    LD (VerticalForceDown), A
;
    LD A, $07
    ADD A, E
    LD E, A                             ;InitMForceData
    LD A, (DE)
    LD (Player_Y_MoveForce), A
;
    LD A, $07
    ADD A, E
    LD E, A                             ;PlayerYSpdData
    LD A, (DE)
    LD (Player_Y_Speed), A
;
    LD A, (SwimmingFlag)                ;if swimming flag disabled, branch
    OR A
    JP Z, PJumpSnd
    LD A, SNDID_SWIM                    ;load swim/goomba stomp sound into
    LD (SFXTrack0.SoundQueue), A        ;square 1's sfx queue
    LD A, (Player_Y_Position)           ;check vertical low byte of player position
    CP A, $14 - SMS_PIXELYOFFSET
    JP NC, X_Physics                    ;if below a certain point, branch
    XOR A                               ;otherwise reset player's vertical speed
    LD (Player_Y_Speed), A              ;and jump to something else to keep player
    JP X_Physics                        ;from swimming above water level
PJumpSnd:
    LD A, (PlayerSize)                  ;is mario big?
    OR A
    LD A, SNDID_JUMPBIG                 ;load big mario's jump sound by default
    JP Z, SJumpSnd
    LD A, SNDID_JUMPSMALL               ;if not, load small mario's jump sound
SJumpSnd:
    LD (SFXTrack0.SoundQueue), A
X_Physics:
    LD DE, MaxLeftXSpdData              ;init value here
    LD BC, FrictionData
    LD A, (Player_State)                ;if mario is on the ground, branch
    OR A
    JP Z, ProcPRun
;
    LD A, (Player_XSpeedAbsolute)       ;check something that seems to be related
    CP A, $19                           ;to mario's speed
    JP NC, GetXPhy                      ;if =>$19 branch here
    JP C, ChkRFast                      ;if not branch elsewhere
ProcPRun:
    INC E                               ;if mario on the ground, increment Y
    LD A, (AreaType)                    ;check area type
    OR A
    JP Z, ChkRFast                      ;if water type, branch
    DEC E                               ;decrement Y by default for non-water type area
;
    LD A, (Left_Right_Buttons)          ;get left/right controller bits
    LD HL, Player_MovingDir
    CP A, (HL)                          ;check against moving direction
    JP NZ, ChkRFast                     ;if controller bits <> moving direction, skip this part
;
    LD A, (A_B_Buttons)                 ;check for b button pressed
    AND A, bitValue(SMS_BTN_1)
    JP NZ, SetRTmr                      ;if pressed, skip ahead to set timer
;
    LD A, (RunningTimer)                ;check for running timer set
    OR A
    JP NZ, GetXPhy                      ;if set, branch
ChkRFast:
    INC E                               ;if running timer not set or level type is water, 
    INC C                               ;increment Y again and temp variable in memory
    LD A, (RunningSpeed)
    OR A
    JP NZ, FastXSp                      ;if running speed set here, branch
;
    LD A, (Player_XSpeedAbsolute)
    CP A, $21                           ;otherwise check player's walking/running speed
    JP C, GetXPhy                       ;if less than a certain amount, branch ahead
FastXSp:
    INC C                               ;if running speed set or speed => $21 increment $00
    JP GetXPhy                          ;and jump ahead
SetRTmr:
    LD A, $0A                           ;if b button pressed, set running timer
    LD (RunningTimer), A
GetXPhy:
    LD A, (DE)                          ;get maximum speed to the left
    LD (MaximumLeftSpeed), A
    INC E
    INC E
    INC E                               ;MaxRightXSpdData
    LD A, (GameEngineSubroutine)        ;check for specific routine running
    CP A, $07                           ;(player entrance)
    JP NZ, GetXPhy2                     ;if not running, skip and use old value of Y
    LD E, <MaxRightXSpdData + $03       ;otherwise set Y to 3
GetXPhy2:
    LD A, (DE)                          ;get maximum speed to the right
    LD (MaximumRightSpeed), A
    LD A, (BC)                          ;get value using value in memory as offset            
    LD (FrictionAdderLow), A
;
    XOR A
    LD (FrictionAdderHigh), A           ;init something here
;
    LD A, (PlayerFacingDir)
    LD HL, Player_MovingDir
    CP A, (HL)                          ;check facing direction against moving direction
    RET Z                               ;if the same, branch to leave
;
    LD HL, (FrictionAdderLow)           ;otherwise shift d7 of friction adder low into carry
    ADD HL, HL                          ;then rotate carry onto d0 of friction adder high
    LD (FrictionAdderLow), HL           ;(16 bit *2)
    RET

;-------------------------------------------------------------------------------------

.SECTION "PlayerAnimTmrData" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
PlayerAnimTmrData:
    .db $02, $04, $07
.ENDS

GetPlayerAnimSpeed:
    LD DE, PlayerAnimTmrData            ;initialize offset in Y
    LD A, (Player_XSpeedAbsolute)       ;check player's walking/running speed
    CP A, $1C                           ;against preset amount
    JP NC, SetRunSpd                    ;if greater than a certain amount, branch ahead
;
    INC E                               ;otherwise increment Y
    CP A, $0E                           ;compare against lower amount
    JP NC, ChkSkid                      ;if greater than this but not greater than first, skip increment
    INC E                               ;otherwise increment Y again
ChkSkid:
    LD A, (SavedJoypadBits)             ;get controller bits
    AND A, %01111111                    ;mask out A button
    JP Z, SetAnimSpd                    ;if no other buttons pressed, branch ahead of all this
;
    AND A, $03                          ;mask out all others except left and right
    LD HL, Player_MovingDir
    CP A, (HL)                          ;check against moving direction
    JP NZ, ProcSkid                     ;if left/right controller bits <> moving direction, branch
    XOR A                               ;otherwise set zero value here
SetRunSpd:
    LD (RunningSpeed), A                ;store zero or running speed here
    JP SetAnimSpd
ProcSkid:
    LD A, (Player_XSpeedAbsolute)       ;check player's walking/running speed
    CP A, $0B                           ;against one last amount
    JP NC, SetAnimSpd                   ;if greater than this amount, branch
;
    LD A, (PlayerFacingDir)
    LD (Player_MovingDir), A            ;otherwise use facing direction to set moving direction
    XOR A
    LD (Player_X_Speed), A              ;nullify player's horizontal speed
    LD (Player_X_MoveForce), A          ;and dummy variable for player
SetAnimSpd:
    LD A, (DE)                          ;get animation timer setting using Y as offset
    LD (PlayerAnimTimerSet), A
    RET

;-------------------------------------------------------------------------------------

ImposeFriction:
    LD HL, Player_CollisionBits         ;perform AND between left/right controller bits and collision flag
    AND A, (HL)
    JP NZ, JoypFrict                    ;if any bits set, branch to next part
;
    LD A, (Player_X_Speed)
    OR A
    JP Z, SetAbsSpd                     ;if player has no horizontal speed, branch ahead to last part
    JP P, RghtFrict                     ;if player moving to the right, branch to slow
    JP M, LeftFrict                     ;otherwise logic dictates player moving left, branch to slow
JoypFrict:
    SRL A                               ;put right controller bit into carry
    JP NC, RghtFrict                    ;if left button pressed, carry = 0, thus branch
LeftFrict:
    LD A, (Player_X_MoveForce)          ;load value set here
    LD HL, FrictionAdderLow
    ADD A, (HL)                         ;add to it another value set here
    LD (Player_X_MoveForce), A          ;store here
;
    LD A, (Player_X_Speed)
    INC L                               ;FrictionAdderHigh
    ADC A, (HL)                         ;add value plus carry to horizontal speed
    LD (Player_X_Speed), A              ;set as new horizontal speed
;
    LD HL, MaximumRightSpeed
    CP A, (HL)                          ;compare against maximum value for right movement
    JP M, XSpdSign                      ;if horizontal speed greater negatively, branch
;
    LD A, (HL)                          ;otherwise set preset value as horizontal speed
    LD (Player_X_Speed), A              ;thus slowing the player's left movement down
    JP SetAbsSpd                        ;skip to the end
RghtFrict:
    LD A, (Player_X_MoveForce)          ;load value set here
    LD HL, FrictionAdderLow
    SUB A, (HL)                         ;subtract from it another value set here
    LD (Player_X_MoveForce), A          ;store here
;
    LD A, (Player_X_Speed)
    INC L                               ;FrictionAdderHigh
    SBC A, (HL)                         ;subtract value plus borrow from horizontal speed
    LD (Player_X_Speed), A              ;set as new horizontal speed
;
    LD HL, MaximumLeftSpeed
    CP A, (HL)                          ;compare against maximum value for left movement
    JP P, XSpdSign                      ;if horizontal speed greater positively, branch
;
    LD A, (HL)                          ;otherwise set preset value as horizontal speed
    LD (Player_X_Speed), A              ;thus slowing the player's right movement down
XSpdSign:
    OR A                                ;if player not moving or moving to the right,
    JP P, SetAbsSpd                     ;branch and leave horizontal speed value unmodified
    NEG                                 ;otherwise get two's compliment to get absolute
SetAbsSpd:
    LD (Player_XSpeedAbsolute), A       ;store walking/running speed here and leave
    RET