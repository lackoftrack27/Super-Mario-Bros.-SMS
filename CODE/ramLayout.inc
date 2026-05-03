;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 00" SLOT 03
    ObjectOffset:                   dsb $02

    FrameCounter:                   dsb $01
    A_B_Buttons:                    dsb $01
    Up_Down_Buttons:                dsb $01
    Left_Right_Buttons:             dsb $01
    PreviousA_B_Buttons:            dsb $01
    GameEngineSubroutine:           dsb $01
    DestinationPageLoc:             dsb $01
    VictoryWalkControl:             dsb $01
    MaximumLeftSpeed:               dsb $01
    MaximumRightSpeed:              dsb $01
    Whirlpool_Offset:               .dsb $01 ; Cannon_Offset
    Cannon_Offset:                  dsb $01
    ; $0D
    AreaObjOffsetBuffer:            dsb $01 ; [$03]
    AreaObjectLength:               dsb $01 ; [$03]
    MushroomLedgeHalfLen:           dsb $01 ; [$03]
    ; $10
    VineObjOffset:                  dsb $01 ; [$02]
    VineFlagOffset:                 dsb $01
    VineHeight:                     dsb $01
    ;VineStart_Y_Position:           dsb $01
    TreeLedgeLength:                dsb $01
    ; $14
    SprShuffleAmt:                  dsb $01 ; [$03]
    BalPlatformAlignment:           dsb $01
    Platform_X_Scroll:              dsb $01
    ; $17
    PowerUpType:                    dsb $01
    PlayerFacingDir:                dsb $01 
    Player_MovingDir:               dsb $01
    Player_CollisionBits:           dsb $01
    Player_State:                   dsb $01
    ; $1C
    SprObject_X_Speed:              dsb $01 ; [$16]
    SprObject_PageLoc:              dsb $01 ; [$19]
    SprObject_X_Position:           dsb $01 ; [$19]
    SprObject_Y_Speed:              dsb $01 ; [$16]
    SprObject_Y_Position:           dsb $01 ; [$19]
    SprObject_Y_HighPos:            dsb $01 ; [$19]
    SprObject_X_MoveForce:          dsb $01 ; [$16]
    SprObject_YMF_Dummy:            dsb $01 ; [$19]
    SprObject_Y_MoveForce:          dsb $01 ; [$16]

    ;SprObject_X_MoveForce:          dsb $01 ; [$16]
    ;SprObject_X_Speed:              dsb $01 ; [$16]
    ;SprObject_X_Position:           dsb $01 ; [$19]
    ;SprObject_PageLoc:              dsb $01 ; [$19]
    ;SprObject_YMF_Dummy:            dsb $01 ; [$19]
    ;SprObject_Y_MoveForce:          dsb $01 ; [$16]
    ;SprObject_Y_Speed:              dsb $01 ; [$16]
    ;SprObject_Y_Position:           dsb $01 ; [$19]
    ;SprObject_Y_HighPos:            dsb $01 ; [$19]

    SprObj_BoundBoxCtrl:            dsb $01 ; [$12]
    BoundingBox_UL_XPos:            .dsb $01
    BoundingBox_UL_Corner:          dsb $01 ; [$12]
    BoundingBox_UL_YPos:            dsb $01 ; [$12]
    BoundingBox_DR_XPos:            .dsb $01
    BoundingBox_LR_Corner:          dsb $01 ; [$12]
    BoundingBox_DR_YPos:            dsb $01 ; [$12]
    ; $2A
    SprObject_Rel_XPos:             dsb $01 ; [$07] *
    SprObject_Rel_YPos:             dsb $01 ; [$07] *
    SprObject_OffscrBits:           dsb $01 ; [$07] *
    ; $2D
    SprDataOffset:                  dsb $01 ; [$17] *
    ; $2E
    Whirlpool_Flag:                 dsb $01
    ;VRAM_Buffer2:                   dsb $D2 ; (23 * 2) * 4 + 3 == $BB
    VRAM_Buffer1_Ptr:               dsb $02
    VRAM_Buffer1:                   dsb $80
.ENDS

.DEFINE Player_X_Speed              SprObject_X_Speed
.DEFINE Player_PageLoc              SprObject_PageLoc              
.DEFINE Player_X_Position           SprObject_X_Position          
.DEFINE Player_Y_Speed              SprObject_Y_Speed              
.DEFINE Player_Y_HighPos            SprObject_Y_HighPos
.DEFINE Player_Y_Position           SprObject_Y_Position
;.DEFINE Player_X_MoveForce          SprObject_X_MoveForce
.DEFINE Player_YMF_Dummy            SprObject_YMF_Dummy ;Player_YMoveForceFractional
.DEFINE Player_Y_MoveForce          SprObject_Y_MoveForce
.DEFINE Player_Rel_XPos             SprObject_Rel_XPos
.DEFINE Player_Rel_YPos             SprObject_Rel_YPos
.DEFINE Player_OffscrBits           SprObject_OffscrBits
.DEFINE Player_SprDataOffset        SprDataOffset
.DEFINE Player_BoundBoxCtrl         SprObj_BoundBoxCtrl

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 01" SLOT 04
    EnemyOffscrBitsMasked:          dsb $01 ; [6]
    VerticalFlipFlag:               dsb $01
    FlagpoleFNum_Y_Pos:             dsb $01
    FlagpoleFNum_YMFDummy:          dsb $01
    FlagpoleScore:                  dsb $01
    BowserBodyControls:             dsb $01
    BowserFeetCounter:              dsb $01
    BowserMovementSpeed:            dsb $01
    BowserOrigXPos:                 dsb $01
    BowserFlameTimerCtrl:           dsb $01
    BowserFront_Offset:             dsb $01
    BridgeCollapseOffset:           dsb $01
    BowserGfxFlag:                  dsb $01
    ; $0D
    AreaObjOffsetBuffer_01:         dsb $01 ; AreaObjOffsetBuffer[01]
    AreaObjectLength_01:            dsb $01 ; AreaObjectLength[01]
    MushroomLedgeHalfLen_01:        dsb $01 ; MushroomLedgeHalfLen[01]
    ; $10
    VineObjOffset_01:               dsb $01 ; VineObjOffset[1]
    BowserHitPoints:                dsb $01
    StompChainCounter:              dsb $01
    .                               dsb $01 ; TreeLedgeLength[1]
    ; $14
    SprShuffleAmt_01:               dsb $01 ; SprShuffleAmt[1]
    FirebarSpinSpeed:               dsb $01 ; [6]
    FirebarSpinDirection:           dsb $01 ; [6]
    ; $17
    Enemy_Flag:                     dsb $01 ; [6]
    Enemy_ID:                       dsb $01 ; [6]
    Enemy_MovingDir:                dsb $01 ; [6]
    Enemy_CollisionBits:            dsb $01 ; [6]
    Enemy_State:                    dsb $01 ; [6]
    ; $1C
        ; ---
    Enemy_X_Speed:                  .dsb $01 ; [$16]
    LakituMoveSpeed:                .dsb $01
    PiranhaPlant_Y_Speed:           .dsb $01
    ExplosionGfxCounter:            .dsb $01
    Jumpspring_FixedYPos:           .dsb $01
    RedPTroopaCenterYPos:           .dsb $01
    BlooperMoveSpeed:               .dsb $01
    XMoveSecondaryCounter:          .dsb $01
    CheepCheepMoveMFlag:            .dsb $01
    FirebarSpinState_Low:           .dsb $01
    YPlatformCenterYPos:            dsb $01
        ; ---
    Enemy_PageLoc:                  dsb $01 ; [$19]
    Enemy_X_Position:               dsb $01 ; [$19]
        ; ---
    Enemy_Y_Speed:                  .dsb $01 ; [$16]
    FirebarSpinState_High:          .dsb $01
    XMovePrimaryCounter:            .dsb $01
    BlooperMoveCounter:             .dsb $01
    LakituMoveDirection:            .dsb $01
    ExplosionTimerCounter:          .dsb $01
    PiranhaPlant_MoveFlag:          dsb $01
        ; ---
    Enemy_Y_Position:               dsb $01 ; [$19]
    Enemy_Y_HighPos:                dsb $01 ; [$19]
    YPlatformTopYPos:               .dsb $01
    RedPTroopaOrigXPos:             .dsb $01
    Enemy_X_MoveForce:              dsb $01 ; [$16]
    BowserFlamePRandomOfs:          .dsb $01
    PiranhaPlantUpYPos:             .dsb $01
    Enemy_YMF_Dummy:                dsb $01 ; [$19]
    CheepCheepOrigYPos:             .dsb $01
    PiranhaPlantDownYPos:           .dsb $01
    Enemy_Y_MoveForce:              dsb $01 ; [$16]
    Enemy_BoundBoxCtrl:             dsb $01 ; [$12]
    EnemyBoundingBoxCoord:          dsb $04 ; [$12]
    ; $2A
    Enemy_Rel_XPos:                 dsb $01 ; [$07] *
    Enemy_Rel_YPos:                 dsb $01 ; [$07] *
    Enemy_OffscrBits:               dsb $01 ; [$07] *
    ; $2D
    Enemy_SprDataOffset:            dsb $01 ; [$17] *
    ; $2E
    HammerBroJumpTimer:             dsb $01 ; [6]
    HammerThrowingTimer:            .dsb $01 ; [6]   PlatformCollisionFlag[6]
    PlatformCollisionFlag:          dsb $01
    FloateyNum_Control:             dsb $01 ; [6]
    FloateyNum_X_Pos:               dsb $01 ; [6]
    FloateyNum_Y_Pos:               dsb $01 ; [6]
    FloateyNum_Timer:               dsb $01 ; [6]
    ShellChainCounter:              dsb $01 ; [6]
    ; $35
    Cannon_PageLoc:                 .dsb $01
    Whirlpool_PageLoc:              dsb $01 ; [6]
    Cannon_X_Position:              .dsb $01
    Whirlpool_LeftExtent            dsb $01 ; [6]
    Cannon_Y_Position:              .dsb $01
    Whirlpool_Length:               dsb $01 ; [6]
    Cannon_Timer:                   .dsb $01
    ; $38
    DigitModifier:                  dsb $01 ; [6]

    .                               dsb $07
    ; $40
    MusicTrack0                     INSTANCEOF SndTrack
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 02" SLOT 05
    EnemyOffscrBitsMasked_01:       dsb $01 ; [6]
    Temp_Bytes:                     dsb $0C ; $00 - $07, $EB - $EF
    ; $0D
    .                               dsb $01 ; AreaObjOffsetBuffer[02]
    .                               dsb $01 ; AreaObjectLength[02]
    .                               dsb $01 ; MushroomLedgeHalfLen[02]
    ; $10
    .                               dsb $02 ; UNUSED
    VineStart_Y_Position:           dsb $01
    .                               dsb $01 ; TreeLedgeLength[02]
    ; $14
    SprShuffleAmt_02:               dsb $01 ; SprShuffleAmt[2]
    FirebarSpinSpeed_01:            dsb $01
    FirebarSpinDirection_01:        dsb $01
    ; $17
    Enemy_Flag_01:                  dsb $01 ; [6]
    Enemy_ID_01:                    dsb $01 ; [6]
    Enemy_MovingDir_01:             dsb $01 ; [6]
    Enemy_CollisionBits_01:         dsb $01 ; [6]
    Enemy_State_01:                 dsb $01 ; [6]
    ; $1C
    .                               dsb $0E ; SprObject_XXX for enemy slot 2
    ; $2A
    Fireball_Rel_XPos:              dsb $01 ; [$07] *
    Fireball_Rel_YPos:              dsb $01 ; [$07] *
    Fireball_OffscrBits:            dsb $01 ; [$07] *
    ; $2D
    Enemy_SprDataOffset_01:         dsb $01 ; [$17] *
    ; $2E
    HammerBroJumpTimer_01:          dsb $01 
    HammerThrowingTimer_01:         .dsb $01
    PlatformCollisionFlag_01:       dsb $01
    FloateyNum_Control_01:          dsb $01 ; [6]
    FloateyNum_X_Pos_01:            dsb $01 ; [6]
    FloateyNum_Y_Pos_01:            dsb $01 ; [6]
    FloateyNum_Timer_01:            dsb $01 ; [6]
    ShellChainCounter_01:           dsb $01 ; [6]
    ; $35
    .                               dsb $03
    ; $38
    DigitModifier_01:               dsb $01 ; [6]
    
    .                               dsb $07
    ; $40
    MusicTrack1                     INSTANCEOF SndTrack
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 03" SLOT 06
    EnemyOffscrBitsMasked_02:       dsb $01 ; [6]
    .                               dsb $0C ; UNUSED
    ; $0D
    AreaObjOffsetBuffer_02:         dsb $01 ; AreaObjOffsetBuffer[02]
    AreaObjectLength_02:            dsb $01 ; AreaObjectLength[02]
    MushroomLedgeHalfLen_02:        dsb $01 ; MushroomLedgeHalfLen[02]
    ; $10
    .                               dsb $04 ; UNUSED
    ; $14
    .                               dsb $01 ; UNUSED
    FirebarSpinSpeed_02:            dsb $01
    FirebarSpinDirection_02:        dsb $01
    ; $17
    Enemy_Flag_02:                  dsb $01 ; [6]
    Enemy_ID_02:                    dsb $01 ; [6]
    Enemy_MovingDir_02:             dsb $01 ; [6]
    Enemy_CollisionBits_02:         dsb $01 ; [6]
    Enemy_State_02:                 dsb $01 ; [6]
    ; $1C
    .                               dsb $0E ; SprObject_XXX for enemy slot 3
    ; $2A
    Bubble_Rel_XPos:                dsb $01 ; [$07] *
    Bubble_Rel_YPos:                dsb $01 ; [$07] *
    Bubble_OffscrBits:              dsb $01 ; [$07] *
    ; $2D
    Enemy_SprDataOffset_02:         dsb $01 ; [$17] *
    ; $2E
    HammerBroJumpTimer_02:          dsb $01 
    HammerThrowingTimer_02:         .dsb $01
    PlatformCollisionFlag_02:       dsb $01
    FloateyNum_Control_02:          dsb $01 ; [6]
    FloateyNum_X_Pos_02:            dsb $01 ; [6]
    FloateyNum_Y_Pos_02:            dsb $01 ; [6]
    FloateyNum_Timer_02:            dsb $01 ; [6]
    ShellChainCounter_02:           dsb $01 ; [6]
    ; $35
    .                               dsb $03
    ; $38
    DigitModifier_02:               dsb $01 ; [6]
    
    .                               dsb $07
    ; $40
    MusicTrack2                     INSTANCEOF SndTrack
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 04" SLOT 07
    EnemyOffscrBitsMasked_03:       dsb $01 ; [6]
    .                               dsb $0C ; UNUSED
    ; $0D
    .                               dsb $03 ; UNUSED
    ; $10
    .                               dsb $04 ; UNUSED
    ; $14
    .                               dsb $01 ; UNUSED
    FirebarSpinSpeed_03:            dsb $01
    FirebarSpinDirection_03:        dsb $01
    ; $17
    Enemy_Flag_03:                  dsb $01 ; [6]
    Enemy_ID_03:                    dsb $01 ; [6]
    Enemy_MovingDir_03:             dsb $01 ; [6]
    Enemy_CollisionBits_03:         dsb $01 ; [6]
    Enemy_State_03:                 dsb $01 ; [6]
    ; $1C
    .                               dsb $0E ; SprObject_XXX for enemy slot 4
    ; $2A
    Block_Rel_XPos:                 dsb $01 ; [$07] *
    Block_Rel_YPos:                 dsb $01 ; [$07] *
    Block_OffscrBits:               dsb $01 ; [$07] *
    ; $2D
    Enemy_SprDataOffset_03:         dsb $01 ; [$17] *
    ; $2E
    HammerBroJumpTimer_03:          dsb $01 
    HammerThrowingTimer_03:         .dsb $01
    PlatformCollisionFlag_03:       dsb $01
    FloateyNum_Control_03:          dsb $01 ; [6]
    FloateyNum_X_Pos_03:            dsb $01 ; [6]
    FloateyNum_Y_Pos_03:            dsb $01 ; [6]
    FloateyNum_Timer_03:            dsb $01 ; [6]
    ShellChainCounter_03:           dsb $01 ; [6]
    ; $35
    .                               dsb $03
    ; $38
    DigitModifier_03:               dsb $01 ; [6]
    
    .                               dsb $07
    ; $40
    MusicTrack3                     INSTANCEOF SndTrack
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 05" SLOT 08
    EnemyOffscrBitsMasked_04:       dsb $01 ; [6]
    .                               dsb $0C ; UNUSED
    ; $0D
    .                               dsb $03 ; UNUSED
    ; $10
    .                               dsb $04 ; UNUSED
    ; $14
    .                               dsb $01 ; UNUSED
    FirebarSpinSpeed_04:            dsb $01
    FirebarSpinDirection_04:        dsb $01
    ; $17
    Enemy_Flag_04:                  dsb $01 ; [6]
    Enemy_ID_04:                    dsb $01 ; [6]
    Enemy_MovingDir_04:             dsb $01 ; [6]
    Enemy_CollisionBits_04:         dsb $01 ; [6]
    Enemy_State_04:                 dsb $01 ; [6]
    ; $1C
    .                               dsb $0E ; SprObject_XXX for enemy slot 5
    ; $2A
    Block_Rel_XPos_01:              dsb $01 ; [$07] *
    Block_Rel_YPos_01:              dsb $01 ; [$07] *
    Block_OffscrBits_01:            dsb $01 ; [$07] * UNUSED
    ; $2D
    Enemy_SprDataOffset_04:         dsb $01 ; [$17] *
    ; $2E
    HammerBroJumpTimer_04:          dsb $01 
    HammerThrowingTimer_04:         .dsb $01
    PlatformCollisionFlag_04:       dsb $01
    FloateyNum_Control_04:          dsb $01 ; [6]
    FloateyNum_X_Pos_04:            dsb $01 ; [6]
    FloateyNum_Y_Pos_04:            dsb $01 ; [6]
    FloateyNum_Timer_04:            dsb $01 ; [6]
    ShellChainCounter_04:           dsb $01 ; [6]
    ; $35
    .                               dsb $03
    ; $38
    DigitModifier_04:               dsb $01 ; [6]
    
    .                               dsb $07
    ; $40
    SFXTrack0                       INSTANCEOF SndTrack
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 06" SLOT 09
    EnemyOffscrBitsMasked_05:       dsb $01 ; [6]
    .                               dsb $0C ; UNUSED
    ; $0D
    .                               dsb $03 ; UNUSED
    ; $10
    .                               dsb $04 ; UNUSED
    ; $14
    .                               dsb $01 ; UNUSED
    FirebarSpinSpeed_05:            dsb $01
    FirebarSpinDirection_05:        dsb $01
    ; $17
    Enemy_Flag_05:                  dsb $01 ; [6]
    Enemy_ID_05:                    dsb $01 ; [6]
    Enemy_MovingDir_05:             dsb $01 ; [6]
    Enemy_CollisionBits_05:         dsb $01 ; [6]
    Enemy_State_05:                 dsb $01 ; [6]
    ; $1C
    .                               dsb $0E ; SprObject_XXX for enemy slot 6
    ; $2A
    Misc_Rel_XPos:                  dsb $01 ; [$07] * END
    Misc_Rel_YPos:                  dsb $01 ; [$07] * END
    Misc_OffscrBits:                dsb $01 ; [$07] * END
    ; $2D
    Enemy_SprDataOffset_05:         dsb $01 ; [$17] *
    ; $2E
    HammerBroJumpTimer_05:          dsb $01 
    HammerThrowingTimer_05:         .dsb $01
    PlatformCollisionFlag_05:       dsb $01
    FloateyNum_Control_05:          dsb $01 ; [6]
    FloateyNum_X_Pos_05:            dsb $01 ; [6]
    FloateyNum_Y_Pos_05:            dsb $01 ; [6]
    FloateyNum_Timer_05:            dsb $01 ; [6]
    ShellChainCounter_05:           dsb $01 ; [6]
    ; $35
    .                               dsb $03
    ; $38
    DigitModifier_05:               dsb $01 ; [6]
    
    .                               dsb $07
    ; $40
    SFXTrack1                       INSTANCEOF SndTrack
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 07" SLOT 10
    .                               dsb $1A ; UNUSED
    FireballBouncingFlag:           dsb $01 ; [$02]
    Fireball_State:                 dsb $01 ; [$02]
    ; $1C
    Fireball_X_Speed:               dsb $01 ; [$16]
    Fireball_PageLoc:               dsb $01 ; [$19]
    Fireball_X_Position:            dsb $01 ; [$19]
    Fireball_Y_Speed:               dsb $01 ; [$16]
    Fireball_Y_Position:            dsb $01 ; [$19]
    Fireball_Y_HighPos:             dsb $01 ; [$19]
    Fireball_X_MoveForce:           dsb $01 ; [$16]
    Fireball_YMF_Dummy:             dsb $01 ; [$19]
    Fireball_Y_MoveForce:           dsb $01 ; [$16]
    Fireball_BoundBoxCtrl:          dsb $01 ; [$12]
    .                               dsb $04 ; Fireball_BoundingBox...
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    Enemy_SprDataOffset_06:         dsb $01 ; [$17] *
    ; $2E
    .                               dsb $07
    ; $35
    .                               dsb $03
    ; $38
    .                               dsb $01
    
    .                               dsb $07
    ; $40
    SFXTrack2                       INSTANCEOF SndTrack
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 08" SLOT 11
    .                               dsb $1A ; UNUSED
    .                               dsb $02 ; BouncingFlag & State for Fireball 2
    ; $1C
    .                               dsb $0E ; SprObject_XXX for Fireball 2
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    Alt_SprDataOffset:              .dsb $01
    Block_SprDataOffset:            dsb $01 ; [$17] *
    ; $2E
    .                               dsb $07
    ; $35
    .                               dsb $03
    ; $38
    .                               dsb $01
    
    .                               dsb $07
    ; $40
.ENDS

;.DEFINE Alt_SprDataOffset           Block_SprDataOffset

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 09" SLOT 12
    .                               dsb $14 ; UNUSED
    SprDataOffset_Ctrl:             dsb $01
    Block_Orig_YPos:                dsb $01 ; [2]
    Block_BBuf_Low:                 dsb $01 ; [2]
    Block_Metatile:                 dsb $01 ; [2]
    Block_PageLoc2:                 dsb $01 ; [2]
    Block_RepFlag:                  dsb $01 ; [2]
    Block_Orig_XPos:                dsb $01 ; [2]
    Block_State:                    dsb $01 ; [$04] ONLY FIRST TWO ARE USED...
    ; $1C
    Block_X_Speed:                  dsb $01 ; [$16]
    Block_PageLoc:                  dsb $01 ; [$19]
    Block_X_Position:               dsb $01 ; [$19]
    Block_Y_Speed:                  dsb $01 ; [$16]
    Block_Y_Position:               dsb $01 ; [$19]
    Block_Y_HighPos:                dsb $01 ; [$19]
    Block_X_MoveForce:              dsb $01 ; [$16]
    Block_YMF_Dummy:                dsb $01 ; [$19]
    Block_Y_MoveForce:              dsb $01 ; [$16]
    .                               dsb $01 ; UNUSED
    .                               dsb $04 ; UNUSED
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    Block_SprDataOffset_01:         dsb $01 ; [$17] *
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 0A" SLOT 13
    .                               dsb $14 ; UNUSED
    .                               dsb $01 ; UNUSED
    .                               dsb $07 ; BLOCK 2 STUFF...
    ; $1C
    .                               dsb $09 ; BLOCK 2 STUFF...
    .                               dsb $01 ; UNUSED
    .                               dsb $04 ; UNUSED
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    Bubble_SprDataOffset:           dsb $01 ; [$17] *
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 0B" SLOT 14
    .                               dsb $14 ; UNUSED
    .                               dsb $01 ; UNUSED
    .                               dsb $07 ; UNUSED...
    ; $1C
    .                               dsb $09 ; BLOCK 1 EX STUFF...
    .                               dsb $01 ; UNUSED
    .                               dsb $04 ; UNUSED
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    Bubble_SprDataOffset_01:        dsb $01 ; [$17] *
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 0C" SLOT 15
    .                               dsb $14 ; UNUSED
    .                               dsb $01 ; UNUSED
    .                               dsb $07 ; UNUSED...
    ; $1C
    .                               dsb $09 ; BLOCK 2 EX STUFF...
    .                               dsb $01 ; UNUSED
    .                               dsb $04 ; UNUSED
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    Bubble_SprDataOffset_02:        dsb $01 ; [$17] *
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 0D" SLOT 16
    .                               dsb $19 ; UNUSED
    HammerEnemyOffset:              dsb $01 ; [9]
    Misc_Collision_Flag:            dsb $01 ; [9]
    Misc_State:                     dsb $01 ; [9]
    ; $1C
    Misc_X_Speed:                   dsb $01 ; [$16]
    Misc_PageLoc:                   dsb $01 ; [$19]
    Misc_X_Position:                dsb $01 ; [$19]
    Misc_Y_Speed:                   dsb $01 ; [$16]
    Misc_Y_Position:                dsb $01 ; [$19]
    Misc_Y_HighPos:                 dsb $01 ; [$19]
    Misc_X_MoveForce:               dsb $01 ; [$16]
    Misc_YMF_Dummy:                 dsb $01 ; [$19]
    Misc_Y_MoveForce:               dsb $01 ; [$16]
    Misc_BoundBoxCtrl:              dsb $01 ; [$12]
    .                               dsb $04 ; Misc_BoundingBox...
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    FBall_SprDataOffset:            dsb $01 ; [$17] *
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 0E" SLOT 17
    .                               dsb $19 ; UNUSED
    .                               dsb $03 ; MISC 1...
    ; $1C
    .                               dsb $0E ; MISC 1...
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    FBall_SprDataOffset_01:         dsb $01 ; [$17] *
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 0F" SLOT 18
    .                               dsb $19 ; UNUSED
    .                               dsb $03 ; MISC 2...
    ; $1C
    .                               dsb $0E ; MISC 2...
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    Misc_SprDataOffset:             dsb $01 ; [$17] *
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 16" SLOT 25
    .                               dsb $1C ; UNUSED
    ; $1C
    .                               dsb $01 ; UNUSED
    Bubble_PageLoc:                 dsb $01
    Bubble_X_Position:              dsb $01
    .                               dsb $01 ; UNUSED
    Bubble_Y_Position:              dsb $01
    Bubble_Y_HighPos:               dsb $01
    .                               dsb $01 ; UNUSED
    Bubble_YMF_Dummy:               dsb $01
    .                               dsb $01 ; UNUSED
    .                               dsb $01 ; UNUSED
    .                               dsb $04 ; UNUSED
    ; $2A
    .                               dsb $03 ; UNUSED
    ; $2D
    Misc_SprDataOffset_07:          dsb $01 ; [$17] *
    ; $2E
    MetaTileBuffer_EXOffset:        dsb $01
    MetaTileBuffer_EX:              dsb $60 ; $0C * $08
    ;
    ; 9 bytes per entry (VDP ADDRESS, COUNT, TILE ADDRESS, CURRENT COUNT)
    BGTileQueue0                    INSTANCEOF _AnimatedBGTileQueue
    BGTileQueue1                    INSTANCEOF _AnimatedBGTileQueue
    BGTileQueue2                    INSTANCEOF _AnimatedBGTileQueue
.ENDS

;   --- END OF 2D ARRAY MEM LAYOUT ---
;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 19" SLOT 28
    Block_Buffer_1:                 dsb $D0 ; $C0
    Block_Buffer_2:                 dsb $30 ; $C0
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 1A" SLOT 29
    .                               dsb $A0 ; Block_Buffer_2
    ; $60 bytes left (SOUND?)
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 1B" SLOT 30
    AreaDataBank:                   dsb $100
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 1C" SLOT 31
    EnemyDataBank:                  dsb $100
.ENDS

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 1D" SLOT 32
    Sprite_Y_Position:              dsb $40
    ;VRAM_Buffer1:                   dsb $40
    VRAM_Buffer2:                   dsb $40 ;only uses $30 bytes (23 * 2) + 2
    Sprite_X_Position:              dsb $80 ;actually holds X Pos & Tile ID
.ENDS

.DEFINE Sprite_Data                 Sprite_Y_Position
.DEFINE Sprite_Tilenumber           Sprite_X_Position + $01    

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 1E" SLOT 33
    ;VRAM_Buffer2:                   dsb $BB ; (23 * 2) * 4 + 3
    ;VRAM_Buffer2_Ptr:               dsb $02
    ;VRAM_Buffer1_Ptr:               dsb $02    
    ;AreaData:                       dsb $02
    ;EnemyData:                      dsb $02

    TileDataLoadedFlag:             dsb $01
    PauseButtonFlag:                dsb $01
    BlockBufferColumnPos:           dsb $01
    MetatileBuffer:                 dsb $0D
    JumpCoinMiscOffset:             dsb $01
    BrickCoinTimerFlag:             dsb $01
    EnemyFrenzyBuffer:              dsb $01
    SecondaryHardMode:              dsb $01
    EnemyFrenzyQueue:               dsb $01
    FireballCounter:                dsb $01
    DuplicateObj_Offset:            dsb $02
    LakituReappearTimer:            dsb $01
    ;ColorRotateOffset:              dsb $01
    PlayerGfxOffset:                dsb $02 ; became absolute address
    PlayerGfxOffset_Old:            dsb $02 ; for detecting sprite changes
    PlayerGfxBank:                  dsb $01 ; determines player character
    Player_SprAttrib:               dsb $01 ; only controls palette for player
    HidePlayerFlag:                 dsb $01
    WarpZoneControl:                dsb $01
    FireworksCounter:               dsb $01
    MultiLoopCorrectCntr:           dsb $01
    MultiLoopPassCntr:              dsb $01
    JumpspringForce:                dsb $01
    MaxRangeFromOrigin:             dsb $01
    BitMFilter:                     dsb $01
    ChangeAreaTimer:                dsb $01
    SprShuffleAmtOffset:            dsb $01
    SavedJoypad1Bits:               dsb $01
    SavedJoypad2Bits:               dsb $01
    Player_X_Scroll:                dsb $01
    Player_XSpeedAbsolute:          dsb $01
    FrictionAdderLow:               dsb $01
    FrictionAdderHigh:              dsb $01
    RunningSpeed:                   dsb $01
    SwimmingFlag:                   dsb $01
    Player_X_MoveForce:             dsb $01
    DiffToHaltJump:                 dsb $01
    JumpOrigin_Y_Position:          dsb $01
    JumpOrigin_Y_HighPos:           dsb $01
    VerticalForce:                  dsb $01
    VerticalForceDown:              dsb $01
    PlayerChangeSizeFlag:           dsb $01
    PlayerAnimTimerSet:             dsb $01
    PlayerAnimCtrl:                 dsb $01
    JumpspringAnimCtrl:             dsb $01
    JumpspringAnimCtrl_Old:         dsb $01
    FlagpoleCollisionYPos:          dsb $01
    PlayerEntranceCtrl:             dsb $01
    FireballThrowingTimer:          dsb $01
    DeathMusicLoaded:               dsb $01
    FlagpoleSoundQueue:             dsb $01
    CrouchingFlag:                  dsb $01
    GameTimerSetting:               dsb $01
    DisableCollisionDet:            dsb $01
    DemoAction:                     dsb $01
    DemoActionTimer:                dsb $01
    PrimaryMsgCounter:              dsb $01
    ScreenEdge_PageLoc:             .dsb $01
    ScreenLeft_PageLoc:             dsb $01
    ScreenRight_PageLoc:            dsb $01
    ScreenEdge_X_Pos:               .dsb $01
    ScreenLeft_X_Pos:               dsb $01
    ScreenRight_X_Pos:              dsb $01

    ColumnSets:                     dsb $01
    ColumnSide:                     dsb $01
    ;AreaParserTaskNum:              dsb $01
    ;UseDelayedMTBuffFlag:           dsb $01

    CurrentNTAddr:                  dsb $02 ; ptr
    Sprite0HitDetectFlag:           dsb $01
    ScrollLock:                     dsb $01
    CurrentPageLoc:                 dsb $01
    CurrentColumnPos:               dsb $01
    TerrainControl:                 dsb $01
    BackloadingFlag:                dsb $01
    BehindAreaParserFlag:           dsb $01
    AreaObjectPageLoc:              dsb $01
    AreaObjectPageSel:              dsb $01
    AreaDataOffset:                 dsb $01
    AreaStyle:                      dsb $01
    StaircaseControl:               dsb $01
    AreaObjectHeight:               dsb $01
    EnemyDataOffset:                dsb $01
    EnemyObjectPageLoc:             dsb $01
    EnemyObjectPageSel:             dsb $01
    ScreenRoutineTask:              dsb $01
    ScrollThirtyTwo:                dsb $01
    HorizontalScroll:               dsb $01
    ;VerticalScroll:                 dsb $01
    VDPHScroll:                     dsb $01
    ForegroundScenery:              dsb $01
    BackgroundScenery:              dsb $01
    CloudTypeOverride:              dsb $01
    BackgroundColorCtrl:            dsb $01
    LoopCommand:                    dsb $01
    StarFlagTaskControl:            dsb $01
    TimerControl:                   dsb $01
    CoinTallyFor1Ups:               dsb $01
    SecondaryMsgCounter:            dsb $01
    JoypadBitMask:                  dsb $02
    ; InitializeArea clears everything ABOVE here
    AreaType:                       dsb $01 ; 0 = WATER, 1 = GND, 2 = UNDERGROUND, 3 = CASTLE
    AreaAddrsLOffset:               dsb $01
    AreaPointer:                    dsb $01
    EntrancePage:                   dsb $01
    AltEntranceControl:             dsb $01
    CurrentPlayer:                  dsb $01 ; 0 = mario, 1 = luigi
    PlayerSize:                     dsb $01 ; 0 = big, 1 = small
    Player_Pos_ForScroll:           dsb $01
    PlayerStatus:                   dsb $01 ; 0 = small, 1 = super, 2 = firey
    FetchNewGameTimerFlag:          dsb $01
    JoypadOverride:                 dsb $01
    GameTimerExpiredFlag:           dsb $01
    ; ACTIVE PLAYER INFO
    OnscreenPlayerInfo:             .dsb $01
    NumberofLives:                  dsb $01
    HalfwayPage:                    dsb $01
    LevelNumber:                    dsb $01
    Hidden1UpFlag:                  dsb $01
    CoinTally:                      dsb $01
    WorldNumber:                    dsb $01
    AreaNumber:                     dsb $01
    ; INACTIVE PLAYER INFO
    OffscreenPlayerInfo:            .dsb $01
    OffScr_NumberofLives:           dsb $01
    OffScr_HalfwayPage:             dsb $01
    OffScr_LevelNumber:             dsb $01
    OffScr_Hidden1UpFlag:           dsb $01
    OffScr_CoinTally:               dsb $01
    OffScr_WorldNumber:             dsb $01
    OffScr_AreaNumber:              dsb $01
    ;
    ScrollFractional:               dsb $01
    DisableIntermediate:            dsb $01
    PrimaryHardMode:                dsb $01
    WorldSelectNumber:              dsb $01
    ; InitializeGame clears everything ABOVE here
    OperMode:                       dsb $01
    OperMode_Task:                  dsb $01
    VRAM_Buffer_AddrCtrl:           dsb $01
    DisableScreenFlag:              dsb $01
    ScrollAmount:                   dsb $01
    GamePauseStatus:                dsb $01
    GamePauseTimer:                 dsb $01
    ;Mirror_PPU_CTRL:                .dsb $01
    ;Mirror_VDP_REG0:                dsb $01
    ;Mirror_PPU_MASK:                .dsb $01
    ;Mirror_VDP_REG1:                dsb $01
    NumberOfPlayers:                dsb $01
    IntervalTimerControl:           dsb $01

    Timers:                         .dsb $01
    SelectTimer:                    dsb $01
    PlayerAnimTimer:                dsb $01
    JumpSwimTimer:                  dsb $01
    RunningTimer:                   dsb $01
    BlockBounceTimer:               dsb $01
    SideCollisionTimer:             dsb $01
    JumpspringTimer:                dsb $01
    GameTimerCtrlTimer:             dsb $02
    ClimbSideTimer:                 dsb $01
    EnemyFrameTimer:                dsb $05
    FrenzyEnemyTimer:               dsb $01
    BowserFireBreathTimer:          dsb $01
    StompTimer:                     dsb $01
    AirBubbleTimer:                 dsb $03 ; 20 bytes away from Timer

    ScrollIntervalTimer:            dsb $01 ; UNUSED
    EnemyIntervalTimer:             dsb $07
    BrickCoinTimer:                 dsb $01
    InjuryTimer:                    dsb $01
    StarInvincibleTimer:            dsb $01
    ScreenTimer:                    dsb $01
    WorldEndTimer:                  dsb $01
    DemoTimer:                      dsb $05
    PseudoRandomBitReg:             dsb $09
    ; SoundMemory:                    dsb $01
    ; MusicOffset_Noise:              .dsb $01
    ; EventMusicBuffer:               dsb $01
    ; PauseSoundBuffer:               dsb $01
    ; Squ2_NoteLenBuffer:             dsb $01
    ; Squ2_NoteLenCounter:            dsb $01
    ; Squ2_EnvelopeDataCtrl:          dsb $01
    ; Squ1_NoteLenCounter:            dsb $01
    ; Squ1_EnvelopeDataCtrl:          dsb $01
    ; Tri_NoteLenBuffer:              dsb $01
    ; Tri_NoteLenCounter:             dsb $01
    ; Noise_BeatLenCounter:           dsb $01
    ; Squ1_SfxLenCounter:             dsb $02
    ; Squ2_SfxLenCounter:             dsb $01
    ; Sfx_SecondaryCounter:           dsb $01
    ; Noise_SfxLenCounter:            dsb $01
    ; DAC_Counter:                    dsb $01
    ; NoiseDataLoopbackOfs:           dsb $03
    ; NoteLengthTblAdder:             dsb $01
    ; AreaMusicBuffer_Alt:            dsb $01
    ; PauseModeFlag:                  dsb $01
    ; GroundMusicHeaderOfs:           dsb $03
    ; AltRegContentFlag:              dsb $0C
    ; Warm boot clears everything ABOVE here
    TopScoreDisplay:                dsb $06
    PlayerScoreDisplay:             dsb $06
    OffScr_ScoreDisplay:            dsb $06
    PlayerCoinDisplay:              dsb $02
    OffScr_CoinDisplay:             dsb $02           
    GameTimerDisplay:               dsb $03
    WorldSelectEnableFlag:          dsb $01
    ContinueWorld:                  dsb $01
    ; Cold boot clears everything ABOVE here
    WarmBootValidation:             dsb $01
.ENDS

.DEFINE SavedJoypadBits             SavedJoypad1Bits

;-------------------------------------------------------------------------------------
.RAMSECTION "RAM Page 1F" SLOT 34
    FrameDoneFlag:                  dsb $01
;
    MDControllerBits:               dsb $01
    MDControllerBitsOld:            dsb $01
;
    SndTempoTimeout:                dsb $01
    SndCurrentTempo:                dsb $01
    SndPauseFlag:                   dsb $01
    SndHurryUpFlag:                 dsb $01
.ENDS