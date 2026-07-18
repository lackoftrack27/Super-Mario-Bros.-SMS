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
;
    CALL IncSubtask
    LD A, (OperMode)
    OR A
    RET Z                           ;if mode still 0, do not load background palette
;
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JR Z, +
    LD A, VRAMTBL_UNDERPAL
    LD (VRAM_Buffer_AddrCtrl), A    ;for NES GFX, store offset into buffer control
    RET
+:
    LD HL, UndergroundPaletteData   ;else, load palette into fade buffer
    LD DE, PaletteFadeBuffer
    LD BC, $20
    LDIR
    RET

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
;
    CALL IncSubtask
    LD A, (OptionBitflags)          ;exit if on default gfx
    AND A, bitValue(OPTFLAG_GFX)
    RET Z
    LD A, $01                       ;else, make coin tile use bg palette
    LD (VRAM_Buffer1 + $19), A
    RET                             ;onto the next task

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
    JR Z, NoTimeUp                  ;control 2 tasks forward, otherwise, stay here
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
    CALL FadeInScreen               ;fade in for intermediate screens (except game over)
;
    LD A, (ScreenTimer)             ;check if screen timer has expired
    OR A
    RET NZ                          ;if not, branch to leave
    CALL FadeOutScreen              ;fade out for intermediate screens (except game over)
    CALL MoveAllSpritesOffscreen    ;otherwise reset sprites now

ResetScreenTimer:
    LD A, $07                       ;reset timer again
    LD (ScreenTimer), A
    LD HL, ScreenRoutineTask        ;move onto next task
    INC (HL)
    RET

;-------------------------------------------------------------------------------------

DisplayIntermediate:
    LD A, %10100000                 ;turn off screen for now
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A
;
    LD A, (OperMode)                ;check primary mode of operation
    OR A
    JR Z, NoInter                   ;if in title screen mode, skip this
    CP A, MODE_GAMEOVER             ;are we in game over mode?
    JR Z, GameOverInter             ;if so, proceed to display game over screen
    LD A, (AltEntranceControl)      ;otherwise check for mode of alternate entry
    OR A
    JR NZ, NoInter                  ;and branch if found
    LD A, (AreaType)                ;check if we are on castle level
    CP A, $03                       ;and if so, branch (possibly residual)
    JR Z, PlayerInter
    LD A, (DisableIntermediate)     ;if this flag is set, skip intermediate lives display
    OR A
    JR NZ, NoInter                  ;and jump to specific task, otherwise
PlayerInter:
    CALL DrawPlayer_Intermediate    ;put player in appropriate place for
    LD A, $01                       ;lives display, then output lives display to buffer
OutputInter:
    CALL WriteGameText
    CALL ResetScreenTimer
    LD A, $40
    LD (DisableScreenFlag), A       ;reenable screen output
    ;
    DI
    ; upload intermediate graphics
    LD A, ASSET_INTERMEDIATE
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    ; UPLOAD PLAYER EMBLEM
    LD A, (CurrentPlayerGfx)
    ADD A, ASSET_EMBLEM_M
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    EX DE, HL
    RST setVDPAddress
    EX DE, HL
    LD BC, $20 * $100 + VDPDATA_PORT
    OTIR
    ; RESET BANK, ENABLE INTS
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    IN A, (VDPCON_PORT)             ;clear any pending VDP interrupts
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
    LD A, ASSET_INTERMEDIATE
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    ;
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    IN A, (VDPCON_PORT)             ;clear any pending VDP interrupts
    EI
    ;
    JP IncModeTask_B
NoInter:
    LD A, $08                       ;set for specific task and leave
    LD (ScreenRoutineTask), A
    RET

;-------------------------------------------------------------------------------------

AreaParserTaskControl:
    XOR A
    LD (DisableScreenFlag), A
    CALL FadeOutScreen
TaskLoop:
    CALL AreaParserTaskHandler      ;render column set of current area
    LD A, (AreaParserTaskNum)
    OR A
    JP NZ, TaskLoop
    LD HL, ColumnSets               ;do we need to render more column sets?
    DEC (HL)
    RET P
    LD HL, ScreenRoutineTask        ;if not, move on to the next task
    INC (HL)
    JP LoadLevelTileData

;-------------------------------------------------------------------------------------

.SECTION "Area Palette VRAM Command Table" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
AreaPalette:
    .db $01, $02, $03, $04
.ENDS

.SECTION "SPR Color Rotation Palettes" BANK BANK_SLOT2 SLOT 2 BITWINDOW 8 RETURNORG
SPRColorRotatePalettes:
    .db $00, $00, $00, $00, $2A, $3F, $0B, $00, $03, $3F, $0B, $00, $00, $3F, $2A, $00
    .db $00, $00, $00, $00, $08, $3F, $0B, $00, $03, $3F, $0B, $00, $00, $2B, $06, $00
    .db $00, $00, $00, $00, $28, $2B, $06, $00, $03, $3F, $0B, $00, $14, $3D, $28, $00
    .db $00, $00, $00, $00, $28, $2B, $06, $00, $03, $3F, $0B, $00, $15, $3F, $2A, $00
.ENDS

.SECTION "Palette Table For Fades" BANK BANK_SLOT2 SLOT 2 BITWINDOW 8 RETURNORG
FadeTable:
    .dw WaterPaletteData
    .dw GroundPaletteData
    .dw UndergroundPaletteData
    .dw CastlePaletteData
    ;
    .dw GroundPaletteData
    .dw DaySnowPaletteData
    .dw NightSnowPaletteData
    .dw CastlePaletteData
.ENDS

GetAreaPalette:
;   for NES GFX, load AreaType's palette animation data
    LD A, (AreaType)
    ADD A, A
    ADD A, A
    ADD A, A
    ADD A, A
    LD HL, SPRColorRotatePalettes + $03
    addAToHL8_M
    LD DE, SpritePaletteCopy + $03  ;skip first 3 bytes as those are set later based on player
    LD BC, $0D
    LDIR
;
    CALL IncSubtask                 ;move onto next task
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JR Z, +
    LD A, (AreaType)                ;for NES GFX, select appropriate palette to load
    LD HL, AreaPalette              ;based on area type
    addAToHL8_M
    LD A, (HL)
    LD (VRAM_Buffer_AddrCtrl), A    ;store offset into buffer control
    RET
+:
    LD A, (AreaType)                ;else, load appropriate palette to fade buffer
    ADD A, A
    LD HL, FadeTable
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    LD DE, PaletteFadeBuffer
    LD BC, $20
    LDIR
    RET

;-------------------------------------------------------------------------------------

.SECTION "Backdrop Palette VRAM Command Table" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
BGColorCtrl_Addr:
    .db $00, $00, $00, $00  ; PADDING
    .db $00, $09, $0a, $04  ; NIGHT, DAYSNOW, NIGHTSNOW, CASTLE
.ENDS

.SECTION "Background Colors for AreaTypes" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
BackgroundColors:
    .db $39, $39, $00, $00  ; Backdrop colors for Area Type (Water, Overworld, Underground, Castle)
    .db $00, $39, $00, $00  ; Backdrop colors for color control override
    ;.db $22, $22, $0f, $0f ;used by area type if bg color ctrl not set
    ;.db $0f, $22, $0f, $0f ;used by background color control if set
.ENDS

.SECTION "PlayerColors (NES)" BANK BANK_SLOT2 SLOT 2 FREE BITWINDOW 8 RETURNORG
PlayerColors:
    .db $03, $0B, $06, $00       ;mario's colors
    .db $3F, $0B, $08, $00       ;luigi's colors
    .db $1F, $0B, $03, $00       ;fiery (used by both)
    ;.db $22, $16, $27, $18 ;mario's colors
    ;.db $22, $30, $27, $19 ;luigi's colors
    ;.db $22, $37, $27, $16 ;fiery (used by both)
.ENDS

GetBackgroundColor:
    LD A, (BackgroundColorCtrl)     ;check background color control
    OR A
    JR Z, NoBGColor                 ;if not set, increment task and fetch palette
;
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    LD A, (HL)
    JR Z, +
    LD HL, BGColorCtrl_Addr         ;for NES GFX, put appropriate palette into vram
    addAToHL8_M
    LD (VRAM_Buffer_AddrCtrl), A    ;note that if set to 5-7, $0301 will not be read
    JR NoBGColor
+:
    LD A, (BackgroundColorCtrl)     ;else, load appropriate palette into fade buffer
    ADD A, A
    LD HL, FadeTable
    addAToHL8_M
    LD A, (HL)
    INC L
    LD H, (HL)
    LD L, A
    LD DE, PaletteFadeBuffer
    LD BC, $20
    LDIR
;
NoBGColor:
    LD HL, ScreenRoutineTask        ;increment to next subtask and plod on through
    INC (HL)
;
    LD HL, (VRAM_Buffer1_Ptr)
    LD A, (BackgroundColorCtrl)     ;if this value is four or greater, it will be set
    OR A
    JR NZ, SetBGColor               ;therefore use it as offset to background color
    LD A, (AreaType)                ;otherwise use area type bits from area offset as offset
SetBGColor:
    LD DE, BackgroundColors
    addAToDE8_M
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    LD A, (DE)
    JR Z, +
    LD (HL), $C0                    ;for NES GFX, write BG color to VRAM_Buffer1
    INC L
    LD (HL), $00
    INC L
    LD (HL), StripeCount($01)
    INC L
    LD (HL), A
    INC L
    LD (HL), $C0
    INC L
    LD (HL), $10
    INC L
    LD (HL), StripeCount($01)
    INC L
    LD (HL), A
    INC L
    LD (HL), $00
    LD (VRAM_Buffer1_Ptr), HL
+:
    LD (PaletteFadeBuffer), A       ;else, write BG color to fade buffer
    LD (PaletteFadeBuffer + $10), A
    ; FALL THROUGH


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
    LD A, (CurrentPlayerGfx)        ;check which player is on the screen
    OR A
    JR Z, ChkFiery
    INC C                           ;load offset for luigi
    INC C
ChkFiery:
    LD A, (PlayerStatus)            ;check player status
    CP A, $02
    JR NZ, StartClrGet
    INC B                           ;if fiery, load alternate offset for fiery player
    INC B
StartClrGet:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JR NZ, GetPlayerColors_NES
    LD A, (PlayerGfxBank)
    AND A, %11111101                ;remove old player bit
    OR A, C                         ;OR with new player bit
    LD (PlayerGfxBank), A
;
    LD A, (Player_SprAttrib)        ;get player attributes
    AND A, %11111100                ;save any other bits but palette bits
    OR A, B                         ;add palette bits
    LD (Player_SprAttrib), A        ;store as new player attributes
    RET
;
GetPlayerColors_NES:
    LD DE, PlayerColors + $08 + $02 ;set default color to firey
    BIT 1, B
    JR NZ, SavePlayerColors         ;jump if player is firey
    LD E, <PlayerColors + $02       ;else use C as index into PlayerColors 
    LD A, C                         ;to get colors for either Mario or Luigi
    SUB A, BANK_PLAYERGFX00
    ADD A, A
    addAToDE8_M
    ; FALL THROUGH
    
SavePlayerColors:
    LD HL, SpritePaletteCopy + $02  ;save player colors to sprite palette RAM copy
    EX DE, HL                       ;do backwards so next routine can iterate through
    LDD                             ;PlayerColors normally
    LDD
    LD A, (HL)
    LD (DE), A
    EX DE, HL
    ; FALL THROUGH

WritePlayerClrStripeCmd:
    LD HL, (VRAM_Buffer1_Ptr)
    LD (HL), $C0
    INC L
    LD (HL), $11
    INC L
    LD (HL), StripeCount($03)
    INC L
    EX DE, HL
    LDI
    LDI
    LDI
    XOR A
    LD (DE), A
    LD (VRAM_Buffer1_Ptr), DE
    RET

;-------------------------------------------------------------------------------------

GetAlternatePalette1:
    CALL IncSubtask                     ;now onto the next task
    LD A, (AreaStyle)                   ;check for mushroom level style
    CP A, $01
    RET NZ                              ;exit if not found
;
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JR Z, +
    LD A, VRAMTBL_MUSHROOMPAL           ;for NES GFX, load appropriate palette via buffer control
    LD (VRAM_Buffer_AddrCtrl), A
    RET
+:
    LD HL, MushroomPaletteData          ;else, load appropriate palette to fade buffer
    LD DE, PaletteFadeBuffer + $05
    LD BC, $06
    LDIR
    RET

;-------------------------------------------------------------------------------------

DrawTitleScreen:
    LD A, (OperMode)                    ;are we in title screen mode?
    OR A
    JR NZ, IncModeTask_B                ;if not, exit
;
    LD A, (TitleLoadedFlag)             ;don't bother with loading tile data 
    OR A                                ;if after initial load on title screen
    JR NZ, @SkipTileLoad
;   Load graphics for TitleScreen
    DI
    LD A, ASSET_TITLESCREEN
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
;   UPLOAD PLAYER EMBLEM
    LD A, (CurrentPlayerGfx)
    ADD A, ASSET_EMBLEM_M
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    EX DE, HL
    RST setVDPAddress
    EX DE, HL
    LD BC, $20 * $100 + VDPDATA_PORT
    OTIR
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    IN A, (VDPCON_PORT)                 ;clear any pending VDP interrupts
    EI
@SkipTileLoad:
;   Set Buffer control
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    LD A, VRAMTBL_TITLESCREEN           ;set buffer transfer control based on GFX mode
    JR Z, +
    LD A, VRAMTBL_TITLESCREEN_NES
+:
    LD (VRAM_Buffer_AddrCtrl), A
    JP IncSubtask                       ;increment task and exit

;-------------------------------------------------------------------------------------

ClearBuffersDrawIcon:
    LD A, (OperMode)                    ;check game mode
    OR A
    JR NZ, IncModeTask_B                ;if not title screen mode, leave
;   !!! THIS IS TO CLEAR TITLE SCREEN DATA FROM LAST SCREEN ROUTINE !!!
;   !!! THIS IS PROBABLY NOT NEEDED !!!
;     XOR A                               ;otherwise, clear buffer space
;     LD B, A
;     LD HL, VRAM_Buffer1-1
;     LD DE, VRAM_Buffer1-1+$100
; TScrClear:
;     LD (HL), A
;     LD (DE), A
;     INC L
;     INC E
;     DJNZ TScrClear
;     LD HL, VRAM_Buffer1
;     LD (VRAM_Buffer1_Ptr), HL
;   !!!
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

;-------------------------------------------------------------------------------------

LoadLevelTileData:
;
    LD A, (TitleLoadedFlag)             ;don't bother loading tile data
    OR A                                ;if after initial load on title screen
    RET NZ
;   TURN OFF INTERRUPTS
    DI
;   LOAD ENEMY SPRITES
    CALL LoadEnemySprites
;   UPLOAD TILES FOR AREA
    ; CLEAR GRASS FLAG (BGTileQueue2 will do 4 tiles)
    XOR A
    LD (BGTileQueue2GrassFlag), A
    ; ALWAYS LOAD COIN INTO SLOT 0 OF ANIMATED TILE QUEUE
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
    LD HL, AnimatedBGTileInits@Coin
    LD DE, BGTileQueue0 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
    ; LOAD OVERWORLD GFX AS BASE
    LD A, ASSET_BGOVERWORLD
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    ; LOAD CLOUD PLATFORM IF NEEDED
    LD A, (CloudTypeOverride)
    OR A
    JR Z, +
    LD A, ASSET_SPRCLOUD
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    EX DE, HL
    RST setVDPAddress
    EX DE, HL
    LD BC, $20 * $100 + VDPDATA_PORT
    OTIR
    ; LOAD SPECIAL TILES DEPENDING ON AREATYPE
+:
    LD A, (AreaType)
    OR A
    JR Z, WaterAreaSetup
    DEC A
    JP Z, OverWorldSetup
    DEC A
    JP Z, UndergroundSetup
CastleSetup:
    ; ANIMATED TILES
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
        ; LAVA FOR SLOT 1
    LD HL, AnimatedBGTileInits@Lava
    LD DE, BGTileQueue1 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
        ; SLOT 2 'QUESTION BLOCK' (4 TILE)
    LD HL, AnimatedBGTileInits@QBlock
    LD DE, BGTileQueue2 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
    ; UNIQUE TILES FOR CASTLE AREA
    LD A, ASSET_BGCASTLE
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    ; PODOBOO & FLAME SPRITE
    LD A, ASSET_SPRPODOBOO
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    ; BOWSER SPRITES
    LD A, ASSET_SPRBOWSER
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    ; RETAINER/PRINCESS SPRITE
    JP TileLoadDone
WaterAreaSetup:
    ; ANIMATED TILES
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
        ; WATER COIN FOR SLOT 0
    LD HL, AnimatedBGTileInits@WaterCoin
    LD DE, BGTileQueue0 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
        ; WATER FOR SLOT 1
    LD HL, AnimatedBGTileInits@WaterA0
    LD DE, BGTileQueue1 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
        ; NOTHING FOR SLOT 2
    LD HL, BGTileQueue2.Timer
    LD (HL), $FF
    LD HL, BGTileQueue2.UpdateFlag
    LD (HL), $00
    ; UNIQUE TILES FOR WATER AREA
    LD A, ASSET_BGWATER
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    ; CLEAR BG AREA WITH WATER TILE FOR NES GFX MODE
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JR Z, +
    LD HL, VRAM_ADR_BG_LVL | VRAMWRITE
    RST setVDPAddress
    LD BC, $8003
-:
    XOR A
    OUT (VDPDATA_PORT), A
    OUT (VDPDATA_PORT), A
    OUT (VDPDATA_PORT), A
    DEC A
    OUT (VDPDATA_PORT), A
    DJNZ -
    DEC C
    JP NZ, -
+:
    ; LOAD WATER CASTLE TILES IF ON W8-4
    LD A, (WorldNumber)
    LD H, A
    LD A, (LevelNumber)
    LD L, A
    OR A
    LD DE, $0703
    SBC HL, DE
    JP NZ, TileLoadDone
    LD A, ASSET_BGWATERCASTLE
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    JP TileLoadDone
OverWorldSetup:
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JP NZ, TileLoadDone
    ; DO DIFFERENT SETUP FOR SNOW LEVELS
    LD A, (BackgroundColorCtrl)
    CP A, $05
    JR Z, SnowOverworldSetup
    CP A, $06
    JR Z, SnowOverworldSetup
    ; ANIMATED TILES
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
        ; SLOT 1 'QUESTION BLOCK'
    LD HL, AnimatedBGTileInits@QBlock
    LD DE, BGTileQueue1 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
        ; SLOT 2 'GRASS' (6 TILE)
    LD HL, BGTileQueue2.Timer           ; ASSUME NO GRASS
    LD (HL), $FF
    LD HL, BGTileQueue2.UpdateFlag
    LD (HL), $00
    LD A, (BackgroundScenery)           ; IF BACKGROUND DOESN'T HAVE GRASS, SKIP
    AND A, $03
    CP A, $02
    JR NZ, TileLoadDone
    LD HL, AnimatedBGTileInits@Grass
    LD DE, BGTileQueue2 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
    LD A, $01                           ; SET GRASS FLAG (BGTileQueue2 will do 6 tiles)
    LD (BGTileQueue2GrassFlag), A
    JR TileLoadDone
SnowOverworldSetup:
    ; ANIMATED TILES
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
        ; WATER FOR SLOT 1
    LD HL, AnimatedBGTileInits@WaterA1
    LD DE, BGTileQueue1 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
        ; SLOT 2 'QUESTION BLOCK' (4 TILE)
    LD HL, AnimatedBGTileInits@QBlock
    LD DE, BGTileQueue2 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
    ; UPLOAD TILES FOR SNOW (ONLY FOR DEFAULT GFX)
    LD A, ASSET_BGSNOW
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    JR TileLoadDone
UndergroundSetup:
    ; UNIQUE TILES FOR UNDERGROUND AREA (ONLY FOR DEFAULT GFX)
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    JR NZ, @ClearLaternArea
    LD A, ASSET_BGUNDERGROUND
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
    ; ANIMATED TILES
    LD A, :AnimatedBGTileInits
    LD (MAPPER_SLOT2), A
        ; SLOT 1 'LATERN'
    LD HL, AnimatedBGTileInits@Latern
    LD DE, BGTileQueue1 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
        ; SLOT 2 'QUESTION BLOCK' (4 TILE)
    LD HL, AnimatedBGTileInits@QBlock
    LD DE, BGTileQueue2 + $01
    LD BC, _sizeof__AnimatedBGTileQueue - $01
    LDIR
    JR TileLoadDone
    ; FOR NES GFX, CLEAR OUT LATERN GFX AREA
@ClearLaternArea:
    LD HL, $3D80 | VRAMWRITE
    RST setVDPAddress
    LD B, $C0
    XOR A
-:
    OUT (VDPDATA_PORT), A
    DJNZ -
TileLoadDone:
    LD A, BANK_SLOT2
    LD (MAPPER_SLOT2), A
    IN A, (VDPCON_PORT)             ;clear any pending VDP interrupts
    EI
    RET


LoadEnemySprites:
;   LOAD BASE ENEMY SPRITE SHEET
    LD A, ASSET_SPRENEMY
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    CALL zx7_decompressVRAM
;   LOAD LAKITU ON CERTAIN LEVELS (4-1,6-1,8-2)
    LD A, (WorldNumber)
    LD H, A
    LD A, (LevelNumber)
    LD L, A
    OR A
    LD DE, $0300
    SBC HL, DE
    JR Z, LoadLakitu
    ADD HL, DE
    OR A
    LD DE, $0500
    SBC HL, DE
    JR Z, LoadLakitu
    ADD HL, DE
    OR A
    LD DE, $0701
    SBC HL, DE
    RET NZ
LoadLakitu:
    LD A, ASSET_SPRLAKITU
    CALL AssetLoader
    LD (MAPPER_SLOT2), A
    JP zx7_decompressVRAM
    
;-------------------------------------------------------------------------------------

FadeInScreen:
;   EXIT IF DOING NES GFX
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    RET NZ
;   EXIT IF SCREEN HAS ALREADY FADED IN
    LD A, (PaletteFadeFlag)
    DEC A
    RET Z
;   CLEAR ALL COLORS
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD B, $20
    XOR A
-:
    OUT (VDPDATA_PORT), A
    DJNZ -
;   TURN SCREEN ON
    LD A, %11100000
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A
;   BLUE FADE IN
    LD DE, $0310
--:
    CALL WaitForNewScreen
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD HL, PaletteFadeBuffer
    LD B, $20
-:
    LD A, (HL)              ;get final color's blue component
    AND A, %00110000
    CP A, E                 ;skip if it's less than current step
    JR C, +
    LD A, E                 ;else, put current step into A
+:
    OUT (VDPDATA_PORT), A   ;write to VDP
    INC L                   ;inner loop check for all colors within palette
    DJNZ -
    LD A, E                 ;increment current step
    ADD A, %00010000
    LD E, A
    DEC D                   ;outer loop check for all steps of color component
    JR NZ, --
;   GREEN FADE IN
    LD DE, $0304
--:
    CALL WaitForNewScreen
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD HL, PaletteFadeBuffer
    LD B, $20
-:
    LD A, (HL)              ;store final color's blue component in C
    AND A, %00110000
    LD C, A
    LD A, (HL)              ;get final color's green component
    AND A, %00001100
    CP A, E                 ;skip if it's less than current step
    JR C, +
    LD A, E                 ;else, put current step into A
+:
    OR A, C                 ;OR with modified final color
    OUT (VDPDATA_PORT), A   ;write to VDP
    INC L                   ;inner loop check for all colors within palette
    DJNZ -
    LD A, E                 ;increment current step
    ADD A, %00000100
    LD E, A
    DEC D                   ;outer loop check for all steps of color component
    JR NZ, --
;   RED FADE IN
    LD DE, $0301
--:
    CALL WaitForNewScreen
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD HL, PaletteFadeBuffer
    LD B, $20
-:
    LD A, (HL)              ;store final color's green and blue components in C
    AND A, %00111100
    LD C, A
    LD A, (HL)              ;get final color's red component
    AND A, %00000011
    CP A, E                 ;skip if it's less than current step
    JR C, +
    LD A, E                 ;else, put current step into A
+:
    OR A, C                 ;OR with modified final color
    OUT (VDPDATA_PORT), A   ;write to VDP
    INC L                   ;inner loop check for all colors within palette
    DJNZ -
    INC E                   ;increment current step
    DEC D                   ;outer loop check for all steps of color component
    JR NZ, --
    LD A, $01
    LD (PaletteFadeFlag), A
    RET



FadeOutScreen:
;   EXIT IF DOING NES GFX
    LD A, (OptionBitflags)
    AND A, bitValue(OPTFLAG_GFX)
    RET NZ
;   EXIT IF SCREEN HAS ALREADY BEEN FADED OUT
    LD A, (PaletteFadeFlag)
    CP A, $02
    RET Z
;   RED FADE OUT
    LD DE, $0301
--:
    CALL WaitForNewScreen
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD HL, PaletteFadeBuffer
    LD B, $20
-:
    LD A, (HL)              ;store final color without red component in C
    AND A, %00111100
    LD C, A
    LD A, (HL)              ;get final color's red component and subtract step offset
    AND A, %00000011
    SUB A, E
    JR NC, +                ;skip if no overflow occured
    XOR A                   ;else, limit lower bound to 0
+:
    OR A, C                 ;OR with modified final color
    OUT (VDPDATA_PORT), A   ;send to VDP
    INC L                   ;inner loop check for all colors within palette
    DJNZ -
    INC E                   ;increment step offset
    DEC D                   ;outer loop check for all steps of color component
    JR NZ, --
;   GREEN FADE OUT
    LD DE, $0304
--:
    CALL WaitForNewScreen
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD HL, PaletteFadeBuffer
    LD B, $20
-:
    LD A, (HL)              ;store final color without red and green components in C
    AND A, %00110000
    LD C, A
    LD A, (HL)              ;get final color's green component and subtract step offset
    AND A, %00001100
    SUB A, E
    JR NC, +                ;skip if no overflow occured
    XOR A                   ;else, limit lower bound to 0
+:
    OR A, C                 ;OR with modified final color
    OUT (VDPDATA_PORT), A   ;send to VDP
    INC L                   ;inner loop check for all colors within palette
    DJNZ -
    LD A, E                 ;increment step offset
    ADD A, %00000100
    LD E, A
    DEC D                   ;outer loop check for all steps of color component
    JR NZ, --
;   BLUE FADE OUT
    LD DE, $0310
--:
    CALL WaitForNewScreen
    LD HL, $0000 | CRAMWRITE
    RST setVDPAddress
    LD HL, PaletteFadeBuffer
    LD B, $20
-:
    LD A, (HL)              ;remove final color's red and green components
    AND A, %00110000
    SUB A, E                ;subtract step offset
    JR NC, +                ;skip if no overflow occured
    XOR A                   ;else, limit lower bound to 0
+:
    OUT (VDPDATA_PORT), A   ;send to VDP
    INC L                   ;inner loop check for all colors within palette
    DJNZ -
    LD A, E                 ;increment step offset
    ADD A, %00010000
    LD E, A
    DEC D                   ;outer loop check for all steps of color component
    JR NZ, --
    LD A, $02
    LD (PaletteFadeFlag), A
    RET

WaitForNewScreen:
    HALT
    LD A, (VDPStatus)
    OR A
    JP P, WaitForNewScreen
    RET