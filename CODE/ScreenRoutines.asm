;-------------------------------------------------------------------------------------

ScreenRoutines:
    LD A, (ScreenRoutineTask)       ;run one of the following subroutines
    RST JumpEngine

    .dw InitScreen
    .dw SetupIntermediate
    .dw WriteTopStatusLine
    .dw WriteBottomStatusLine
    .dw DisplayTimeUp
    .dw ResetSpritesAndScreenTimer
    .dw DisplayIntermediate
    .dw ResetSpritesAndScreenTimer
    .dw AreaParserTaskControl
    .dw GetAreaPalette
    .dw GetBackgroundColor
    .dw GetAlternatePalette1
    .dw DrawTitleScreen
    .dw ClearBuffersDrawIcon
    .dw WriteTopScore

;-------------------------------------------------------------------------------------

InitScreen:
    CALL MoveAllSpritesOffscreen    ;initialize all sprites including sprite #0
    CALL InitializeNameTables       ;and erase both name and attribute tables
    LD A, (OperMode)
    OR A
    JP Z, IncSubtask                ;if mode still 0, do not load
    LD A, VRAMTBL_UNDERPAL          ;into buffer pointer
    LD (VRAM_Buffer_AddrCtrl), A    ;store offset into buffer control
    JP IncSubtask                   ;move onto next task

;-------------------------------------------------------------------------------------

SetupIntermediate:
    LD A, (BackgroundColorCtrl)     ;save current background color control
    PUSH AF                         ;and player status to stack
    LD A, (PlayerStatus)
    PUSH AF
    XOR A                           ;set background color to black
    LD (PlayerStatus), A            ;and player status to not fiery
    LD A, $02                       ;this is the ONLY time background color control
    LD (BackgroundColorCtrl), A     ;is set to less than 4
    CALL GetPlayerColors
    POP AF                          ;we only execute this routine for
    LD (PlayerStatus), A            ;the intermediate lives display
    POP AF                          ;and once we're done, we return bg
    LD (BackgroundColorCtrl), A     ;color ctrl and player status from stack
    JP IncSubtask                   ;then move onto the next task

;-------------------------------------------------------------------------------------

WriteTopStatusLine:
    XOR A                           ;select main status bar
    CALL WriteGameText              ;output it
    JP IncSubtask                   ;onto the next task

;-------------------------------------------------------------------------------------

WriteBottomStatusLine:
    CALL GetSBNybbles               ;write player's score and coin tally to screen
    LD HL, (VRAM_Buffer1_Ptr)
    LD B, $01                       ;VALUE FOR ATTRIBUTE BYTES
    LD (HL), >xyToNameTbl_M(20, 0)  ;write address for world-area number on screen
    INC L
    LD (HL), <xyToNameTbl_M(20, 0)
    INC L
    LD (HL), StripeCount($06)       ;write length for it [$03]
    INC L
    LD A, (WorldNumber)             ;first the world number
    ADD A, BG_TILE_OFFSET + $01
    LD (HL), A
    INC L
    LD (HL), B                      ;USE UPPER BANK FOR TILE
    INC L
    LD (HL), BG_TILE_OFFSET + $0B   ;next the dash
    INC L
    LD (HL), B                      ;USE UPPER BANK FOR TILE
    INC L
    LD A, (LevelNumber)             ;next the level number
    ADD A, BG_TILE_OFFSET + $01
    LD (HL), A
    INC L
    LD (HL), B                      ;USE UPPER BANK FOR TILE
    INC L
    LD (HL), $00                    ;put null terminator on
    LD (VRAM_Buffer1_Ptr), HL
    JP IncSubtask

;-------------------------------------------------------------------------------------

DisplayTimeUp:
    LD A, (GameTimerExpiredFlag)    ;if game timer not expired, increment task
    OR A
    JP Z, NoTimeUp                  ;control 2 tasks forward, otherwise, stay here
    XOR A
    LD (GameTimerExpiredFlag), A    ;reset timer expiration flag
    LD A, $02                       ;output time-up screen to buffer
    JP OutputInter
NoTimeUp:
    LD HL, ScreenRoutineTask        ;increment control task 2 tasks forward
    INC (HL)
    JP IncSubtask

;-------------------------------------------------------------------------------------

ResetSpritesAndScreenTimer:
    LD A, (ScreenTimer)             ;check if screen timer has expired
    OR A
    RET NZ                          ;if not, branch to leave
    CALL MoveAllSpritesOffscreen    ;otherwise reset sprites now

ResetScreenTimer:
    LD A, $07                       ;reset timer again
    LD (ScreenTimer), A
    LD HL, ScreenRoutineTask        ;move onto next task
    INC (HL)
    RET

;-------------------------------------------------------------------------------------

DisplayIntermediate:
    LD A, (OperMode)                ;check primary mode of operation
    OR A
    JP Z, NoInter                   ;if in title screen mode, skip this
    CP A, MODE_GAMEOVER             ;are we in game over mode?
    JP Z, GameOverInter             ;if so, proceed to display game over screen
    LD A, (AltEntranceControl)      ;otherwise check for mode of alternate entry
    OR A
    JP NZ, NoInter                  ;and branch if found
    LD A, (AreaType)                ;check if we are on castle level
    CP A, $03                       ;and if so, branch (possibly residual)
    JP Z, PlayerInter
    LD A, (DisableIntermediate)     ;if this flag is set, skip intermediate lives display
    OR A
    JP NZ, NoInter                  ;and jump to specific task, otherwise
PlayerInter:
    CALL DrawPlayer_Intermediate    ;put player in appropriate place for
    LD A, $01                       ;lives display, then output lives display to buffer
OutputInter:
    CALL WriteGameText
    CALL ResetScreenTimer
    LD A, $40
    LD (DisableScreenFlag), A       ;reenable screen output
    ;upload intermediate graphics
    DI
    LD A, :Tiles_BG_Inter
    LD (MAPPER_SLOT2), A
    LD HL, VRAM_ADR_BG_INTER | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_BG_Inter
    LD BC, _sizeof_Tiles_BG_Inter
    CALL copyToVDP
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    EI
    ;
    RET
GameOverInter:
    LD A, $12                       ;set screen timer
    LD (ScreenTimer), A
    LD A, $03                       ;output game over screen to buffer
    CALL WriteGameText
    ;upload intermediate graphics
    DI
    LD A, :Tiles_BG_Inter
    LD (MAPPER_SLOT2), A
    LD HL, VRAM_ADR_BG_INTER | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_BG_Inter
    LD BC, _sizeof_Tiles_BG_Inter
    CALL copyToVDP
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    EI
    ;
    JP IncModeTask_B
NoInter:
    LD A, $08                       ;set for specific task and leave
    LD (ScreenRoutineTask), A
    RET

;-------------------------------------------------------------------------------------

AreaParserTaskControl:
    LD A, (TileDataLoadedFlag)
    OR A
    CALL Z, LoadLevelTileData
    XOR A
    LD (DisableScreenFlag), A
    INC A
    LD (TileDataLoadedFlag), A    
;
TaskLoop:
    CALL AreaParserTaskHandler      ;render column set of current area
    LD HL, ColumnSets               ;do we need to render more column sets?
    DEC (HL)
    RET P ;JP P, OutputCol
    LD HL, ScreenRoutineTask        ;if not, move on to the next task
    INC (HL)
    LD A, <VRAM_ADR_NAMETBL + $42
    LD (CurrentNTAddr), A
    RET

;-------------------------------------------------------------------------------------

.SECTION "Area Palette VRAM Command Table" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
AreaPalette:
    .db $01, $02, $03, $04
.ENDS

GetAreaPalette:
    LD A, (AreaType)                ;select appropriate palette to load
    LD HL, AreaPalette              ;based on area type
    addAToHL8_M
    LD A, (HL)
    LD (VRAM_Buffer_AddrCtrl), A    ;store offset into buffer control
    JP IncSubtask                   ;move onto next task

;-------------------------------------------------------------------------------------

.SECTION "Backdrop Palette VRAM Command Table" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BGColorCtrl_Addr:
    .db $00, $00, $00, $00  ; PADDING
    .db $00, $09, $0a, $04  ; NIGHT, DAYSNOW, NIGHTSNOW, CASTLE
.ENDS

.SECTION "Background Colors for AreaTypes" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8
BackgroundColors:
    .db $39, $39, $00, $00  ; Backdrop colors for Area Type (Water, Overworld, Underground, Castle)
    .db $00, $39, $00, $00  ; Backdrop colors for color control override
    ;.db $22, $22, $0f, $0f ;used by area type if bg color ctrl not set
    ;.db $0f, $22, $0f, $0f ;used by background color control if set
.ENDS

;PlayerColors:
    ;.db $22, $16, $27, $18 ;mario's colors
    ;.db $22, $30, $27, $19 ;luigi's colors
    ;.db $22, $37, $27, $16 ;fiery (used by both)

GetBackgroundColor:
    LD A, (BackgroundColorCtrl)     ;check background color control
    OR A
    JP Z, NoBGColor                 ;if not set, increment task and fetch palette
    LD HL, BGColorCtrl_Addr         ;put appropriate palette into vram
    addAToHL8_M
    LD A, (HL)
    LD (VRAM_Buffer_AddrCtrl), A    ;note that if set to 5-7, $0301 will not be read
NoBGColor:
    LD HL, ScreenRoutineTask        ;increment to next subtask and plod on through
    INC (HL)

;   $00 - MARIO (RIGHT)
    ; 0, 1, 2, 3
    ; NORMAL, INVERT0, FIRE, INVERT1
;   $01 - MARIO (LEFT)
    ; 0, 1, 2, 3
;   $02 - LUIGI (RIGHT)
    ; 0, 1, 2, 3
;   $03 - LUIGI (LEFT)
    ; 0, 1, 2, 3

GetPlayerColors:
    LD BC, $0000 | BANK_PLAYERGFX00 ; B = PALETTE, C = BANK
    LD A, (CurrentPlayer)           ;check which player is on the screen
    OR A
    JP Z, ChkFiery
    INC C                           ;load offset for luigi
    INC C
ChkFiery:
    LD A, (PlayerStatus)            ;check player status
    CP A, $02
    JP NZ, StartClrGet
    INC B                           ;if fiery, load alternate offset for fiery player
    INC B
StartClrGet:
    LD A, (PlayerGfxBank)
    AND A, %11111101                ;remove old player bit
    OR A, C                         ;OR with new player bit
    LD (PlayerGfxBank), A
;
    LD A, B
    ;JP CyclePlayerPalette
    AND A, $03                      ;mask out all but d1-d0 (previously d3-d2)
    LD B, A                         ;store result here to use as palette bits
    LD A, (Player_SprAttrib)        ;get player attributes
    AND A, %11111100                ;save any other bits but palette bits
    OR A, B                         ;add palette bits
    LD (Player_SprAttrib), A        ;store as new player attributes
    RET
;
;     LD HL, (VRAM_Buffer1_Ptr)       ;get current buffer offset
;     LD A, (BackgroundColorCtrl)     ;if this value is four or greater, it will be set
;     OR A
;     JP NZ, SetBGColor               ;therefore use it as offset to background color
;     LD A, (AreaType)                ;otherwise use area type bits from area offset as offset
; SetBGColor:
;     LD (HL), $C0
;     INC L
;     LD (HL), $10
;     INC L
;     LD (HL), $01
;     INC L
;     LD DE, BackgroundColors
;     addAToDE8_M
;     LD A, (DE)
;     LD (HL), A
;     INC L
;     LD (HL), $00
;     LD (VRAM_Buffer1_Ptr), HL
;     RET

;-------------------------------------------------------------------------------------

GetAlternatePalette1:
    LD A, (AreaStyle)                   ;check for mushroom level style
    CP A, $01
    JP NZ, IncSubtask
    LD A, VRAMTBL_MUSHROOMPAL           ;if found, load appropriate palette
    LD (VRAM_Buffer_AddrCtrl), A
    JP IncSubtask                       ;now onto the next task

;-------------------------------------------------------------------------------------

DrawTitleScreen:
    LD A, (OperMode)                    ;are we in title screen mode?
    OR A
    JP NZ, IncModeTask_B                ;if not, exit
;   Load graphics for TitleScreen
    DI
    ; Logo
    LD A, :Tiles_BG_TitleScreen
    LD (MAPPER_SLOT2), A
    LD HL, (VRAM_ADR_SPR + $B7 * SMS_TILE_SIZE) | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_BG_TitleScreen
    LD BC, _sizeof_Tiles_BG_TitleScreen
    CALL copyToVDP
    ; Text and Icons (16 Tiles)
    LD BC, $0000 + VDPDATA_PORT
    OTIR
    OTIR
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    EI
;   Set Buffer control
    LD A, VRAMTBL_TITLESCREEN           ;set buffer transfer control to $0300,
    LD (VRAM_Buffer_AddrCtrl), A
    JP IncSubtask                       ;increment task and exit

;-------------------------------------------------------------------------------------

ClearBuffersDrawIcon:
    LD A, (OperMode)                    ;check game mode
    OR A
    JP NZ, IncModeTask_B                ;if not title screen mode, leave
    /*
;   !!! THIS IS TO CLEAR TITLE SCREEN DATA FROM LAST SCREEN ROUTINE !!!
;   !!! THIS IS PROBABLY NOT NEEDED !!!
    XOR A                               ;otherwise, clear buffer space
    LD B, A
    LD HL, VRAM_Buffer1-1
    LD DE, VRAM_Buffer1-1+$100
TScrClear:
    LD (HL), A
    LD (DE), A
    INC L
    INC E
    DJNZ TScrClear
    LD HL, VRAM_Buffer1
    LD (VRAM_Buffer1_Ptr), HL
;   !!!
    */
    CALL DrawMushroomIcon               ;draw player select icon
IncSubtask:
    LD HL, ScreenRoutineTask            ;move onto next task
    INC (HL)
    RET 

;-------------------------------------------------------------------------------------

WriteTopScore:
    LD A, $FA                           ;run display routine to display top score on title
    CALL UpdateNumber
IncModeTask_B:
    LD HL, OperMode_Task                ;move onto next mode
    INC (HL)
    RET
    



LoadLevelTileData:
;   TURN OFF INTERRUPTS
    DI
;   MANUALLY TURN OFF THE SCREEN
    LD A, %10100000
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A
;   LOAD ENEMY SPRITES
    CALL LoadEnemySprites
;   UPLOAD TILES FOR AREA
    ; ALWAYS LOAD COIN INTO SLOT 0 OF ANIMATED TILE QUEUE
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
    LD HL, AnimatedBGTileInits@Coin
    LD DE, BGTileQueue0 + $01
    LD BC, $0008
    LDIR
    ; LOAD OVERWORLD GFX AS BASE
    LD A, :Tiles_BG_Overworld
    LD (MAPPER_SLOT2), A
    LD HL, VRAM_ADR_BG_LVL | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_BG_Overworld
    LD BC, _sizeof_Tiles_BG_Overworld
    CALL copyToVDP
    ; LOAD SPECIAL TILES DEPENDING ON AREATYPE
    LD A, (AreaType)
    OR A
    JP Z, WaterAreaSetup
    DEC A
    JP Z, OverWorldSetup
    DEC A
    JP Z, UndergroundSetup
CastleSetup:
    ; UNIQUE TILES FOR CASTLE AREA
    ; PODOBOO SPRITE
    ; FIRE PROJECTILE SPRITES
    ; BOWSER SPRITES
    ; RETAINER/PRINCESS SPRITE
    JP TileLoadDone
WaterAreaSetup:
    ; UNIQUE TILES FOR WATER AREA
    JP TileLoadDone
OverWorldSetup:
    ; NOTHING FOR SLOT 1
    LD HL, BGTileQueue1.Timer
    LD (HL), $FF
    LD HL, BGTileQueue1.UpdateFlag
    LD (HL), $00
    ; SLOT 2 'GRASS'
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
    LD HL, AnimatedBGTileInits@Grass
    LD DE, BGTileQueue2 + $01
    LD BC, $0008
    LDIR
    JP TileLoadDone
UndergroundSetup:
    ; UNIQUE TILES FOR UNDERGROUND AREA
    LD A, :Tiles_BG_Underground
    LD (MAPPER_SLOT2), A
    LD HL, $3A80 | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_BG_Underground
    LD BC, _sizeof_Tiles_BG_Underground
    CALL copyToVDP
    ; SLOT 1 'LATERN'
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
    LD HL, AnimatedBGTileInits@Latern
    LD DE, BGTileQueue1 + $01
    LD BC, $0008
    LDIR
    ; NOTHING FOR SLOT 2
    LD HL, BGTileQueue2.Timer
    LD (HL), $FF
    LD HL, BGTileQueue2.UpdateFlag
    LD (HL), $00
TileLoadDone:
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    EI
    RET


LoadEnemySprites:
;   LOAD BASE ENEMY SPRITE SHEET
    LD A, :Tiles_SPR_Enemies
    LD (MAPPER_SLOT2), A
    LD HL, VRAM_ADR_SPR_EMY | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_SPR_Enemies
    LD BC, _sizeof_Tiles_SPR_Enemies
    CALL copyToVDP
;   LOAD LAKITU ON CERTAIN LEVELS (4-1,6-1,8-2)
    LD A, (WorldNumber)
    LD H, A
    LD A, (LevelNumber)
    LD L, A
    OR A
    LD DE, $0300
    SBC HL, DE
    JP Z, LoadLakitu
    ADD HL, DE
    OR A
    LD DE, $0500
    SBC HL, DE
    JP Z, LoadLakitu
    ADD HL, DE
    OR A
    LD DE, $0701
    SBC HL, DE
    JP NZ, CheckHammerLevels
LoadLakitu:
    PUSH HL
    LD A, :Tiles_SPR_Lakitu
    LD (MAPPER_SLOT2), A
    LD HL, $1380 | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_SPR_Lakitu
    LD BC, _sizeof_Tiles_SPR_Lakitu
    CALL copyToVDP
    POP HL
CheckHammerLevels:
;   LOAD HAMMER BRO ON CERTAIN LEVELS (3-1,5-2,7-1,8-3,8-4)
    ADD HL, DE
    OR A
    LD DE, $0200
    SBC HL, DE
    JP Z, LoadHammerBro
    ADD HL, DE
    OR A
    LD DE, $0401
    SBC HL, DE
    JP Z, LoadHammerBro
    ADD HL, DE
    OR A
    LD DE, $0600
    SBC HL, DE
    JP Z, LoadHammerBro
    ADD HL, DE
    OR A
    LD DE, $0702
    SBC HL, DE
    JP Z, LoadHammerBro
    ADD HL, DE
    OR A
    LD DE, $0703
    SBC HL, DE
    RET NZ
LoadHammerBro:
    LD A, :Tiles_SPR_Hammerbro
    LD (MAPPER_SLOT2), A
    LD HL, $1900 | VRAMWRITE
    RST setVDPAddress
    LD HL, Tiles_SPR_Hammerbro
    LD BC, _sizeof_Tiles_SPR_Hammerbro
    JP copyToVDP