.MEMORYMAP
    DEFAULTSLOT 0
    SLOTSIZE    $7FF0
    SLOT 0  $0000       ; ROM (NOT PAGED)
    SLOTSIZE    $0010
    SLOT 1  $7FF0       ; SMS HEADER
    SLOTSIZE    $4000
    SLOT 2  $8000       ; ROM (PAGED)
    ; ---
    SLOTSIZE    $0100
    SLOT 03  $C000       ; RAM PAGE 00
    SLOT 04  $C100       ; RAM PAGE 01
    SLOT 05  $C200       ; RAM PAGE 02
    SLOT 06  $C300       ; RAM PAGE 03
    SLOT 07  $C400       ; RAM PAGE 04
    SLOT 08  $C500       ; RAM PAGE 05
    SLOT 09  $C600       ; RAM PAGE 06
    SLOT 10  $C700       ; RAM PAGE 07

    SLOT 11  $C800       ; RAM PAGE 08
    SLOT 12  $C900       ; RAM PAGE 09
    SLOT 13  $CA00       ; RAM PAGE 0A
    SLOT 14  $CB00       ; RAM PAGE 0B
    SLOT 15  $CC00       ; RAM PAGE 0C
    SLOT 16  $CD00       ; RAM PAGE 0D
    SLOT 17  $CE00       ; RAM PAGE 0E
    SLOT 18  $CF00       ; RAM PAGE 0F

    SLOT 19  $D000       ; RAM PAGE 10
    SLOT 20  $D100       ; RAM PAGE 11
    SLOT 21  $D200       ; RAM PAGE 12
    SLOT 22  $D300       ; RAM PAGE 13
    SLOT 23  $D400       ; RAM PAGE 14
    SLOT 24  $D500       ; RAM PAGE 15
    SLOT 25  $D600       ; RAM PAGE 16
    SLOT 26  $D700       ; RAM PAGE 17

    SLOT 27  $D800       ; RAM PAGE 18
    SLOT 28  $D900       ; RAM PAGE 19
    SLOT 29  $DA00       ; RAM PAGE 1A
    SLOT 30  $DB00       ; RAM PAGE 1B
    SLOT 31  $DC00       ; RAM PAGE 1C
    SLOT 32  $DD00       ; RAM PAGE 1D
    SLOT 33  $DE00       ; RAM PAGE 1E
    SLOT 34  $DF00       ; RAM PAGE 1F
    
.ENDME

;   256KB IN TOTAL
.ROMBANKMAP
    BANKSTOTAL  16
    BANKSIZE    $7FF0   ; ROM (NOT PAGED)
    BANKS   1
    BANKSIZE    $0010   ; SMS HEADER
    BANKS   1
    BANKSIZE    $4000   ; ROM (PAGED)
    BANKS   14
.ENDRO