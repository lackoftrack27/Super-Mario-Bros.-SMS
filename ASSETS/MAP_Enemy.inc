;-------------------------------------------------------------------------------------

.SECTION "EnemyGraphicsTable" BANK BANK_ENEMYTBL SLOT 2 FORCE ORG $0000
;tiles arranged in top left, right, middle left, right, bottom left, right order
EnemyGraphicsTable_Arr0:
@Beetle:
    .db $00, $00, $00, $00, $00, $00  ;buzzy beetle frame 1     [$0000]
    .db $00, $00, $00, $00, $00, $00  ;             frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@GKoopa:
    .db $00, $00, $00, $00, $00, $00  ;koopa troopa frame 1     [$0018]
    .db $00, $00, $00, $00, $00, $00  ;             frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@GPKoopa:
    .db $00, $00, $00, $00, $00, $00  ;koopa paratroopa frame 1 [$0030]
    .db $00, $00, $00, $00, $00, $00  ;                 frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $A8, $A9, $AA, $AB  ;spiny death frame
@Spiny:
    .db $00, $00, $A8, $A9, $AA, $AB  ;spiny frame 1            [$004E]
    .db $00, $00, $00, $00, $00, $00  ;      frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@SpinyEgg:
    .db $00, $00, $00, $00, $00, $00  ;spiny's egg frame 1      [$0066]
    .db $00, $00, $00, $00, $00, $00  ;            frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $9A, $9B, $9C, $9D  ;blooper death frame
@Blooper:
    .db $00, $00, $9A, $9B, $9C, $9D  ;bloober frame 1          [$0084]
    .db $00, $00, $00, $00, $00, $00  ;        frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@GCheep:
    .db $00, $00, $00, $00, $00, $00  ;cheep-cheep frame 1      [$00A2]
    .db $00, $00, $00, $00, $00, $00  ;cheep-cheep frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@RCheep:
    .db $00, $00, $00, $00, $00, $00  ;cheep-cheep frame 1 (red)[$00C0]
    .db $00, $00, $00, $00, $00, $00  ;            frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $9E, $9F, $A0, $A1  ;goomba death frame
@Goomba:
    .db $00, $00, $9E, $9F, $A0, $A1  ;goomba                   [$00DE]
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip

    .db $00, $00, $AC, $AD, $AE, $AF  ;death frame
@GKoopaUSD:
    .db $00, $00, $AC, $AD, $AE, $AF  ;koopa shell frame 1 (upside-down) [$00F6]
    .db $00, $00, $00, $00, $00, $00  ;            frame 2
    .db $00, $00, $AC, $AD, $AE, $AF  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $AC, $AD, $AE, $AF  ;death frame
@GKoopaRSU:
    .db $00, $00, $AC, $AD, $AE, $AF  ;koopa shell frame 1 (rightsideup) [$0114]
    .db $00, $00, $00, $00, $00, $00  ;            frame 2
    .db $00, $00, $AC, $AD, $AE, $AF  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $B0, $B1, $B2, $B3  ;death frame
@BeetleRSU:
    .db $00, $00, $B0, $B1, $B2, $B3 ;buzzy beetle shell frame 1 (rightsideup) [$0132]
    .db $00, $00, $00, $00, $00, $00  ;                   frame 2
    .db $00, $00, $B0, $B1, $B2, $B3  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $B0, $B1, $B2, $B3  ;death frame
@BeetleUSD:
    .db $00, $00, $B0, $B1, $B2, $B3  ;buzzy beetle shell frame 1 (upside-down) [$0150]
    .db $00, $00, $00, $00, $00, $00  ;                   frame 2
    .db $00, $00, $B0, $B1, $B2, $B3  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@GoombaDefeat:
    .db $00, $00, $00, $00, $00, $00  ;defeated goomba          [$0168]
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip

    .db $A2, $A3, $A4, $A5, $A6, $A7  ;lakitu death frame
@Lakitu:
    .db $A2, $A3, $A4, $A5, $A6, $A7  ;lakitu frame 1           [$0180]
@LakituAlt:
    .db $00, $00, $00, $00, $00, $00  ;       frame 2           [$0186]
    .db $A2, $A3, $A4, $A5, $A6, $A7  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $94, $95, $96, $97, $98, $99  ;hammer bro death frame
@HammerBro:
    .db $78, $79, $7A, $7B, $7C, $7D  ;hammer bro frame 1       [$019E]
    .db $78, $79, $7E, $7F, $80, $81  ;           frame 2
    .db $86, $87, $88, $89, $8A, $8B  ;frame 1 Hflip
    .db $86, $87, $8C, $8D, $8E, $8F  ;frame 2 Hflip

    .db $94, $95, $96, $97, $98, $99  ;hammer bro death frame
@HammerBro_Alt:
    .db $82, $83, $84, $85, $7C, $7D  ;           frame 3       [$01BC]
    .db $82, $83, $84, $85, $80, $81  ;           frame 4
    .db $90, $91, $92, $93, $8A, $8B  ;frame 3 Hflip
    .db $90, $91, $92, $93, $8E, $8F  ;frame 4 Hflip

@Piranha:
    .db $6E, $6F, $70, $71, $72, $73  ;piranha plant frame 1    [$01D4]
    .db $74, $75, $76, $77, $72, $73  ;              frame 2
    .db $6E, $6F, $70, $71, $72, $73  ;frame 1 Hflip
    .db $74, $75, $76, $77, $72, $73  ;frame 2 Hflip

@RKoopa:
    .db $00, $00, $00, $00, $00, $00  ;koopa troopa frame 1 (red)[$01EC]
    .db $00, $00, $00, $00, $00, $00  ;             frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@RPKoopa:
    .db $00, $00, $00, $00, $00, $00  ;koopa paratroopa frame 1 (red) [$0204]
    .db $00, $00, $00, $00, $00, $00  ;                 frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@Bullet:
    .db $00, $00, $00, $00, $00, $00  ;bullet bill              [$021C]
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@RKoopaUSD:
    .db $00, $00, $00, $00, $00, $00  ;koopa shell frame 1 (upside-down) (red) [$0234]
    .db $00, $00, $00, $00, $00, $00  ;            frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@RKoopaRSU:
    .db $00, $00, $00, $00, $00, $00  ;koopa shell frame 1 (rightsideup) [$0252]
    .db $00, $00, $00, $00, $00, $00  ;            frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip
.ENDS

;-------------------------------------------------------------------------------------

.SECTION "EnemyGraphicsTable_01" BANK BANK_ENEMYTBL SLOT 2 FORCE ORG $0400
;tiles arranged in top left, right, middle left, right, bottom left, right order
EnemyGraphicsTable_Arr1:
@Beetle:
    .db $00, $00, $5E, $5F, $60, $61  ;buzzy beetle frame 1
    .db $00, $00, $62, $63, $64, $65  ;             frame 2
    .db $00, $00, $66, $67, $68, $69  ;frame 1 Hflip
    .db $00, $00, $6A, $6B, $6C, $6D  ;frame 2 Hflip

@GKoopa:
    .db $00, $76, $77, $78, $79, $7A  ;koopa troopa frame 1
    .db $00, $7B, $7C, $7D, $7E, $7F  ;             frame 2
    .db $84, $00, $85, $86, $87, $88  ;frame 1 Hflip
    .db $89, $00, $8A, $8B, $8C, $8D  ;frame 2 Hflip

@GPKoopa:
    .db $80, $76, $81, $78, $79, $7A  ;koopa paratroopa frame 1
    .db $82, $7B, $83, $7D, $7E, $7F  ;                 frame 2
    .db $84, $8E, $85, $8F, $87, $88  ;frame 1 Hflip
    .db $89, $90, $8A, $91, $8C, $8D  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@Spiny:
    .db $00, $00, $00, $00, $00, $00  ;spiny frame 1
    .db $00, $00, $00, $00, $00, $00  ;      frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@SpinyEgg:
    .db $00, $00, $00, $00, $00, $00  ;spiny's egg frame 1  [X, $30]
    .db $00, $00, $00, $00, $00, $00  ;            frame 2  [X]
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@Blooper:
    .db $00, $00, $00, $00, $00, $00  ;bloober frame 1
    .db $00, $00, $00, $00, $00, $00  ;        frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@GCheep:
    .db $00, $00, $00, $00, $00, $00  ;cheep-cheep frame 1
    .db $00, $00, $00, $00, $00, $00  ;cheep-cheep frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@RCheep:
    .db $00, $00, $00, $00, $00, $00  ;cheep-cheep frame 1 (red)
    .db $00, $00, $00, $00, $00, $00  ;            frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $5A, $5B, $5C, $5D  ;death frame
@Goomba:
    .db $00, $00, $52, $53, $54, $55  ;goomba
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $52, $53, $56, $57  ;frame 1 Hflip

    .db $00, $00, $92, $93, $94, $95  ;death frame (USD)
@GKoopaUSD:
    .db $00, $00, $98, $99, $9A, $9B  ;koopa shell frame 1 (upside-down)
    .db $00, $00, $9C, $9D, $9A, $9B  ;            frame 2
    .db $00, $00, $98, $99, $9A, $9B  ;frame 1 Hflip
    .db $00, $00, $9C, $9D, $9A, $9B  ;frame 2 Hflip

    .db $00, $00, $98, $99, $9A, $9B  ;death frame
@GKoopaRSU:
    .db $00, $00, $92, $93, $94, $95  ;shell frame 1 (upside-down)
    .db $00, $00, $92, $93, $96, $97  ;      frame 2
    .db $00, $00, $92, $93, $94, $95  ;frame 1 Hflip
    .db $00, $00, $92, $93, $96, $97  ;frame 2 Hflip

    .db $00, $00, $72, $73, $74, $75  ;death frame
@BeetleRSU:
    .db $00, $00, $6E, $6F, $70, $71  ;buzzy beetle shell frame 1 (rightsideup)
    .db $00, $00, $6E, $6F, $70, $71  ;                   frame 2
    .db $00, $00, $6E, $6F, $70, $71  ;frame 1 Hflip
    .db $00, $00, $6E, $6F, $70, $71  ;frame 2 Hflip

    .db $00, $00, $6E, $6F, $70, $71  ;death frame
@BeetleUSD:
    .db $00, $00, $72, $73, $74, $75  ;buzzy beetle shell frame 1 (upside-down)
    .db $00, $00, $72, $73, $74, $75  ;                   frame 2
    .db $00, $00, $72, $73, $74, $75  ;frame 1 Hflip
    .db $00, $00, $72, $73, $74, $75  ;frame 2 Hflip

@GoombaDefeat:
    .db $00, $00, $00, $00, $58, $59  ;defeated goomba
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $00, $00, $58, $59  ;frame 1 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@Lakitu:
    .db $00, $00, $00, $00, $00, $00  ;lakitu frame 1
@LakituAlt:
    .db $00, $00, $00, $00, $00, $00  ;       frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $F8, $F9, $FA, $FB, $FC, $FD  ;death frame
@HammerBro:
    .db $DC, $DD, $DE, $DF, $E0, $E1  ;hammer bro frame 1
    .db $DC, $DD, $E2, $E3, $E4, $E5  ;           frame 2
    .db $EA, $EB, $EC, $ED, $EE, $EF  ;frame 1 Hflip
    .db $EA, $EB, $F0, $F1, $F2, $F3  ;frame 2 Hflip

    .db $F8, $F9, $FA, $FB, $FC, $FD  ;death frame
@HammerBro_Alt:
    .db $E6, $E7, $E8, $E9, $E0, $E1  ;           frame 3
    .db $E6, $E7, $E8, $E9, $E4, $E5  ;           frame 4
    .db $F4, $F5, $F6, $F7, $EE, $EF  ;frame 3 Hflip
    .db $F4, $F5, $F6, $F7, $F2, $F3  ;frame 4 Hflip

@Piranha:
    .db $9E, $9F, $A0, $A1, $A2, $A3  ;piranha plant frame 1
    .db $A4, $A5, $A6, $A7, $A2, $A3  ;              frame 2
    .db $9E, $9F, $A0, $A1, $A2, $A3  ;frame 1 Hflip
    .db $A4, $A5, $A6, $A7, $A2, $A3  ;frame 2 Hflip

@RKoopa:
    .db $00, $B4, $B5, $B6, $B7, $B8  ;koopa troopa frame 1 (red)
    .db $00, $B9, $BA, $BB, $BC, $BD  ;             frame 2 (red)
    .db $C2, $00, $C3, $C4, $C5, $C6  ;frame 1 Hflip
    .db $C7, $00, $C8, $C9, $CA, $CB  ;frame 2 Hflip

@RPKoopa:
    .db $BE, $B4, $BF, $B6, $B7, $B8  ;koopa paratroopa frame 1 (red)
    .db $C0, $B9, $C1, $BB, $BC, $BD  ;                 frame 2 (red)
    .db $C2, $CC, $C3, $CD, $C5, $C6  ;frame 1 Hflip
    .db $C7, $CE, $C8, $CF, $CA, $CB  ;frame 2 Hflip

@Bullet:
    .db $00, $00, $A8, $A9, $AA, $AB  ;bullet bill
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $AC, $AD, $AE, $AF  ;frame 1 Hflip

    .db $00, $00, $D0, $D1, $D2, $D3  ;death frame (USD)
@RKoopaUSD:
    .db $00, $00, $D6, $D7, $D8, $D9  ;shell frame 1 (upside-down) (red)
    .db $00, $00, $DA, $DB, $D8, $D9  ;      frame 2 (red)
    .db $00, $00, $D6, $D7, $D8, $D9  ;frame 1 Hflip
    .db $00, $00, $DA, $DB, $D8, $D9  ;frame 2 Hflip

    .db $00, $00, $D6, $D7, $D8, $D9  ;death frame (RSU)
@RKoopaRSU:
    .db $00, $00, $D0, $D1, $D2, $D3  ;shell frame 1 (rightsideup) (red)
    .db $00, $00, $D0, $D1, $D4, $D5  ;      frame 2 (red)
    .db $00, $00, $D0, $D1, $D2, $D3  ;frame 1 Hflip
    .db $00, $00, $D0, $D1, $D4, $D5  ;frame 2 Hflip
.ENDS

;-------------------------------------------------------------------------------------

.SECTION "EnemyGraphicsTable_02" BANK BANK_ENEMYTBL SLOT 2 FORCE ORG $0800
;tiles arranged in top left, right, middle left, right, bottom left, right order
EnemyGraphicsTable_Arr2:
@Beetle:
    .db $00, $00, $5E, $5F, $60, $61  ;buzzy beetle frame 1
    .db $00, $00, $62, $63, $64, $65  ;             frame 2
    .db $00, $00, $66, $67, $68, $69  ;frame 1 Hflip
    .db $00, $00, $6A, $6B, $6C, $6D  ;frame 2 Hflip

@GKoopa:
    .db $00, $76, $77, $78, $79, $7A  ;koopa troopa frame 1
    .db $00, $7B, $7C, $7D, $7E, $7F  ;             frame 2
    .db $84, $00, $85, $86, $87, $88  ;frame 1 Hflip
    .db $89, $00, $8A, $8B, $8C, $8D  ;frame 2 Hflip

@GPKoopa:
    .db $80, $76, $81, $78, $79, $7A  ;koopa paratroopa frame 1
    .db $82, $7B, $83, $7D, $7E, $7F  ;                 frame 2
    .db $84, $8E, $85, $8F, $87, $88  ;frame 1 Hflip
    .db $89, $90, $8A, $91, $8C, $8D  ;frame 2 Hflip

    .db $00, $00, $EE, $EF, $F0, $F1  ;spiny death frame
@Spiny:
    .db $00, $00, $D4, $D5, $D6, $D7  ;spiny frame 1
    .db $00, $00, $D8, $D9, $DA, $DB  ;      frame 2
    .db $00, $00, $E0, $E1, $E2, $E3  ;spiny frame 1 Hflip
    .db $00, $00, $E4, $E5, $E6, $E7  ;spiny frame 2 Hflip

@SpinyEgg:
    .db $00, $00, $CC, $CD, $CE, $CF  ;spiny egg frame 1
    .db $00, $00, $D0, $D1, $D2, $D3  ;          frame 2
    .db $00, $00, $CC, $CD, $CE, $CF  ;egg frame 1 Hflip
    .db $00, $00, $D0, $D1, $D2, $D3  ;egg frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@Blooper:
    .db $00, $00, $00, $00, $00, $00  ;bloober frame 1
    .db $00, $00, $00, $00, $00, $00  ;        frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@GCheep:
    .db $00, $00, $00, $00, $00, $00  ;cheep-cheep frame 1
    .db $00, $00, $00, $00, $00, $00  ;cheep-cheep frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $C0, $C1, $C2, $C3  ;death frame
@RCheep:
    .db $00, $00, $B4, $B5, $B6, $B7  ;cheep-cheep frame 1 (red)
    .db $00, $00, $B8, $B5, $B9, $B7  ;cheep-cheep frame 2 (red)
    .db $00, $00, $BA, $BB, $BC, $BD  ;frame 1 Hflip
    .db $00, $00, $BA, $BE, $BC, $BF  ;frame 2 Hflip

    .db $00, $00, $5A, $5B, $5C, $5D  ;death frame
@Goomba:
    .db $00, $00, $52, $53, $54, $55  ;goomba
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $52, $53, $56, $57  ;frame 1 Hflip

    .db $00, $00, $92, $93, $94, $95  ;death frame (USD)
@GKoopaUSD:
    .db $00, $00, $98, $99, $9A, $9B  ;koopa shell frame 1 (upside-down)
    .db $00, $00, $9C, $9D, $9A, $9B  ;            frame 2
    .db $00, $00, $98, $99, $9A, $9B  ;frame 1 Hflip
    .db $00, $00, $9C, $9D, $9A, $9B  ;frame 2 Hflip

    .db $00, $00, $98, $99, $9A, $9B  ;death frame
@GKoopaRSU:
    .db $00, $00, $92, $93, $94, $95  ;shell frame 1 (upside-down)
    .db $00, $00, $92, $93, $96, $97  ;      frame 2
    .db $00, $00, $92, $93, $94, $95  ;frame 1 Hflip
    .db $00, $00, $92, $93, $96, $97  ;frame 2 Hflip

    .db $00, $00, $72, $73, $74, $75  ;death frame
@BeetleRSU:
    .db $00, $00, $6E, $6F, $70, $71  ;buzzy beetle shell frame 1 (rightsideup)
    .db $00, $00, $6E, $6F, $70, $71  ;                   frame 2
    .db $00, $00, $6E, $6F, $70, $71  ;frame 1 Hflip
    .db $00, $00, $6E, $6F, $70, $71  ;frame 2 Hflip

    .db $00, $00, $6E, $6F, $70, $71  ;death frame
@BeetleUSD:
    .db $00, $00, $72, $73, $74, $75  ;buzzy beetle shell frame 1 (upside-down)
    .db $00, $00, $72, $73, $74, $75  ;                   frame 2
    .db $00, $00, $72, $73, $74, $75  ;frame 1 Hflip
    .db $00, $00, $72, $73, $74, $75  ;frame 2 Hflip

@GoombaDefeat:
    .db $00, $00, $00, $00, $58, $59  ;defeated goomba
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $00, $00, $58, $59  ;frame 1 Hflip

    .db $E8, $E9, $EA, $EB, $EC, $ED  ;death frame
@Lakitu:
    .db $C4, $C5, $C6, $C7, $C8, $C9  ;lakitu frame 1
@LakituAlt:
    .db $00, $00, $CA, $CB, $C8, $C9  ;       frame 2
    .db $DC, $DD, $DE, $DF, $C8, $C9  ;frame 1 Hflip
    .db $00, $00, $CA, $CB, $C8, $C9  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@HammerBro:
    .db $00, $00, $00, $00, $00, $00  ;hammer bro frame 1
    .db $00, $00, $00, $00, $00, $00  ;           frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@HammerBro_Alt:
    .db $00, $00, $00, $00, $00, $00  ;           frame 3
    .db $00, $00, $00, $00, $00, $00  ;           frame 4
    .db $00, $00, $00, $00, $00, $00  ;frame 3 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 4 Hflip

@Piranha:
    .db $9E, $9F, $A0, $A1, $A2, $A3  ;piranha plant frame 1
    .db $A4, $A5, $A6, $A7, $A2, $A3  ;              frame 2
    .db $9E, $9F, $A0, $A1, $A2, $A3  ;frame 1 Hflip
    .db $A4, $A5, $A6, $A7, $A2, $A3  ;frame 2 Hflip

@RKoopa:
    .db $00, $00, $00, $00, $00, $00  ;koopa troopa frame 1 (red)
    .db $00, $00, $00, $00, $00, $00  ;             frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@RPKoopa:
    .db $00, $00, $00, $00, $00, $00  ;koopa paratroopa frame 1 (red)
    .db $00, $00, $00, $00, $00, $00  ;                 frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

@Bullet:
    .db $00, $00, $A8, $A9, $AA, $AB  ;bullet bill
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $AC, $AD, $AE, $AF  ;frame 1 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame (USD)
@RKoopaUSD:
    .db $00, $00, $00, $00, $00, $00  ;shell frame 1 (upside-down) (red)
    .db $00, $00, $00, $00, $00, $00  ;      frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame (RSU)
@RKoopaRSU:
    .db $00, $00, $00, $00, $00, $00  ;shell frame 1 (rightsideup) (red)
    .db $00, $00, $00, $00, $00, $00  ;      frame 2 (red)
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip
.ENDS

;-------------------------------------------------------------------------------------

.SECTION "EnemyGraphicsTable_03" BANK BANK_ENEMYTBL SLOT 2 FORCE ORG $0C00
;tiles arranged in top left, right, middle left, right, bottom left, right order
EnemyGraphicsTable_Arr3:
@Beetle:
    .db $00, $00, $5E, $5F, $60, $61  ;buzzy beetle frame 1
    .db $00, $00, $62, $63, $64, $65  ;             frame 2
    .db $00, $00, $66, $67, $68, $69  ;frame 1 Hflip
    .db $00, $00, $6A, $6B, $6C, $6D  ;frame 2 Hflip

@GKoopa:
    .db $00, $76, $77, $78, $79, $7A  ;koopa troopa frame 1
    .db $00, $7B, $7C, $7D, $7E, $7F  ;             frame 2
    .db $84, $00, $85, $86, $87, $88  ;frame 1 Hflip
    .db $89, $00, $8A, $8B, $8C, $8D  ;frame 2 Hflip

@GPKoopa:
    .db $80, $76, $81, $78, $79, $7A  ;koopa paratroopa frame 1
    .db $82, $7B, $83, $7D, $7E, $7F  ;                 frame 2
    .db $84, $8E, $85, $8F, $87, $88  ;frame 1 Hflip
    .db $89, $90, $8A, $91, $8C, $8D  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;spiny death frame
@Spiny:
    .db $00, $00, $00, $00, $00, $00  ;spiny frame 1
    .db $00, $00, $00, $00, $00, $00  ;      frame 2
    .db $00, $00, $00, $00, $00, $00  ;spiny frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;spiny frame 2 Hflip

@SpinyEgg:
    .db $00, $00, $00, $00, $00, $00  ;spiny egg frame 1
    .db $00, $00, $00, $00, $00, $00  ;          frame 2
    .db $00, $00, $00, $00, $00, $00  ;egg frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;egg frame 2 Hflip

    .db $00, $00, $F8, $F9, $FA, $FB  ;death frame
@Blooper:
    .db $00, $00, $F0, $F1, $F2, $F3  ;blooper frame 1
    .db $F0, $F1, $F4, $F5, $F6, $F7  ;        frame 2
    .db $00, $00, $F0, $F1, $F2, $F3  ;frame 1 Hflip
    .db $F0, $F1, $F4, $F5, $F6, $F7  ;frame 2 Hflip

    .db $00, $00, $EC, $ED, $EE, $EF  ;death frame
@GCheep:
    .db $00, $00, $E0, $E1, $E2, $E3  ;cheep-cheep frame 1 (green)
    .db $00, $00, $E4, $E1, $E5, $E3  ;cheep-cheep frame 2 (green)
    .db $00, $00, $E6, $E7, $E8, $E9  ;frame 1 Hflip
    .db $00, $00, $E6, $EA, $E8, $EB  ;frame 2 Hflip

    .db $00, $00, $DC, $DD, $DE, $DF  ;death frame
@RCheep:
    .db $00, $00, $D0, $D1, $D2, $D3  ;cheep-cheep frame 1 (red)
    .db $00, $00, $D4, $D1, $D5, $D3  ;cheep-cheep frame 2 (red)
    .db $00, $00, $D6, $D7, $D8, $D9  ;frame 1 Hflip
    .db $00, $00, $D6, $DA, $D8, $DB  ;frame 2 Hflip

    .db $00, $00, $5A, $5B, $5C, $5D  ;death frame
@Goomba:
    .db $00, $00, $52, $53, $54, $55  ;goomba
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $52, $53, $56, $57  ;frame 1 Hflip

    .db $00, $00, $92, $93, $94, $95  ;death frame (USD)
@GKoopaUSD:
    .db $00, $00, $98, $99, $9A, $9B  ;shell frame 1 (upside-down)
    .db $00, $00, $9C, $9D, $9A, $9B  ;      frame 2
    .db $00, $00, $98, $99, $9A, $9B  ;frame 1 Hflip
    .db $00, $00, $9C, $9D, $9A, $9B  ;frame 2 Hflip

    .db $00, $00, $98, $99, $9A, $9B  ;death frame (RSU)
@GKoopaRSU:
    .db $00, $00, $92, $93, $94, $95  ;shell frame 1 (rightsideup)
    .db $00, $00, $92, $93, $96, $97  ;      frame 2
    .db $00, $00, $92, $93, $94, $95  ;frame 1 Hflip
    .db $00, $00, $92, $93, $96, $97  ;frame 2 Hflip

    .db $00, $00, $72, $73, $74, $75  ;death frame
@BeetleRSU:
    .db $00, $00, $6E, $6F, $70, $71  ;buzzy beetle shell frame 1 (rightsideup)
    .db $00, $00, $6E, $6F, $70, $71  ;                   frame 2
    .db $00, $00, $6E, $6F, $70, $71  ;frame 1 Hflip
    .db $00, $00, $6E, $6F, $70, $71  ;frame 2 Hflip

    .db $00, $00, $6E, $6F, $70, $71  ;death frame
@BeetleUSD:
    .db $00, $00, $72, $73, $74, $75  ;buzzy beetle shell frame 1 (upside-down)
    .db $00, $00, $72, $73, $74, $75  ;                   frame 2
    .db $00, $00, $72, $73, $74, $75  ;frame 1 Hflip
    .db $00, $00, $72, $73, $74, $75  ;frame 2 Hflip

@GoombaDefeat:
    .db $00, $00, $00, $00, $58, $59  ;defeated goomba
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $00, $00, $58, $59  ;frame 1 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@Lakitu:
    .db $00, $00, $00, $00, $00, $00  ;lakitu frame 1
@LakituAlt:
    .db $00, $00, $00, $00, $00, $00  ;       frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@HammerBro:
    .db $00, $00, $00, $00, $00, $00  ;hammer bro frame 1
    .db $00, $00, $00, $00, $00, $00  ;           frame 2
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 2 Hflip

    .db $00, $00, $00, $00, $00, $00  ;death frame
@HammerBro_Alt:
    .db $00, $00, $00, $00, $00, $00  ;           frame 3
    .db $00, $00, $00, $00, $00, $00  ;           frame 4
    .db $00, $00, $00, $00, $00, $00  ;frame 3 Hflip
    .db $00, $00, $00, $00, $00, $00  ;frame 4 Hflip

@Piranha:
    .db $9E, $9F, $A0, $A1, $A2, $A3  ;piranha plant frame 1
    .db $A4, $A5, $A6, $A7, $A2, $A3  ;              frame 2
    .db $9E, $9F, $A0, $A1, $A2, $A3  ;frame 1 Hflip
    .db $A4, $A5, $A6, $A7, $A2, $A3  ;frame 2 Hflip

@RKoopa:
    .db $00, $A8, $A9, $AA, $AB, $AC  ;koopa troopa frame 1 (red)
    .db $00, $AD, $AE, $AF, $B0, $B1  ;             frame 2 (red)
    .db $B6, $00, $B7, $B8, $B9, $BA  ;frame 1 Hflip
    .db $BB, $00, $BC, $BD, $BE, $BF  ;frame 2 Hflip

@RPKoopa:
    .db $B2, $A8, $B3, $AA, $AB, $AC  ;koopa paratroopa frame 1 (red)
    .db $B4, $AD, $B5, $AF, $B0, $B1  ;                 frame 2 (red)
    .db $B6, $C0, $B7, $C1, $B9, $BA  ;frame 1 Hflip
    .db $BB, $C2, $BC, $C3, $BE, $BF  ;frame 2 Hflip

@Bullet:
    .db $00, $00, $00, $00, $00, $00  ;bullet bill
    .db $00, $00, $00, $00, $00, $00  ;padding
    .db $00, $00, $00, $00, $00, $00  ;frame 1 Hflip

    .db $00, $00, $C4, $C5, $C6, $C7  ;death frame (USD)
@RKoopaUSD:
    .db $00, $00, $CA, $CB, $CC, $CD  ;shell frame 1 (upside-down) (red)
    .db $00, $00, $CE, $CF, $CC, $CD  ;      frame 2 (red)
    .db $00, $00, $CA, $CB, $CC, $CD  ;frame 1 Hflip
    .db $00, $00, $CE, $CF, $CC, $CD  ;frame 2 Hflip

    .db $00, $00, $CA, $CB, $CC, $CD  ;death frame (RSU)
@RKoopaRSU:
    .db $00, $00, $C4, $C5, $C6, $C7  ;shell frame 1 (rightsideup) (red)
    .db $00, $00, $C4, $C5, $C8, $C9  ;      frame 2 (red)
    .db $00, $00, $C4, $C5, $C6, $C7  ;frame 1 Hflip
    .db $00, $00, $C4, $C5, $C8, $C9  ;frame 2 Hflip
.ENDS