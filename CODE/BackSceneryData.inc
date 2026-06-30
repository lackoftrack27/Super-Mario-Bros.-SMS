.SECTION "BackSceneryColumnPtrs" BANK BANK_SLOT2 SLOT 2 FREE RETURNORG
BackSceneryColumnPtrs:
;   CLOUDS
    .dw BGColumn01
    .dw BGColumn02
    .dw BGColumn03
    .dw BGColumn04
    .dw BGColumn05
    .dw BGColumn06
    .dw BGColumn07
    .dw BGColumn08
    .dw BGColumn09
    .dw BGColumn0A
    .dw BGColumn0B
    .dw BGColumn0C
    .dw BGColumn0D
    .dw BGColumn0E
    .dw BGColumn0F
;   MOUNTAINS/GRASS
    .dw BGColumn10
    .dw BGColumn11
    .dw BGColumn12
    .dw BGColumn13
    .dw BGColumn14
    .dw BGColumn15
    .dw BGColumn16
    .dw BGColumn17
    .dw BGColumn18
;   TREES/FENCE
    .dw BGColumn19
    .dw BGColumn1A
    .dw BGColumn1B
;   CLOUDS (NIGHT)
    .dw BGColumn1C
    .dw BGColumn1D
    .dw BGColumn1E
    .dw BGColumn1F
    .dw BGColumn20
    .dw BGColumn21
    .dw BGColumn22
    .dw BGColumn23
    .dw BGColumn24
    .dw BGColumn25
    .dw BGColumn26
    .dw BGColumn27
    .dw BGColumn28
    .dw BGColumn29
    .dw BGColumn2A
    .dw BGColumn2B
    .dw BGColumn2C
    .dw BGColumn2D
    .dw BGColumn2E
    .dw BGColumn2F
    .dw BGColumn30
    .dw BGColumn31
    .dw BGColumn32
    .dw BGColumn33
    .dw BGColumn34
    .dw BGColumn35
    .dw BGColumn36
    .dw BGColumn37
    .dw BGColumn38
    .dw BGColumn39
    .dw BGColumn3A
;   MOUNTAINS (NIGHT)
    .dw BGColumn3B
    .dw BGColumn3C
    .dw BGColumn3D
    .dw BGColumn3E
    .dw BGColumn3F
    .dw BGColumn40
    .dw BGColumn41
    .dw BGColumn42
    .dw BGColumn43
    .dw BGColumn44
    .dw BGColumn45
    .dw BGColumn46
    .dw BGColumn47
    .dw BGColumn48
    .dw BGColumn49
    .dw BGColumn4A
    .dw BGColumn4B
    .dw BGColumn4C
    .dw BGColumn4D
    .dw BGColumn4E
    .dw BGColumn4F
    .dw BGColumn50
    .dw BGColumn51
    .dw BGColumn52
    .dw BGColumn53
;   TREES/FENCE (NIGHT)
    .dw BGColumn54
    .dw BGColumn55
    .dw BGColumn56
    .dw BGColumn57
    .dw BGColumn58
    .dw BGColumn59
    .dw BGColumn5A
    .dw BGColumn5B
    .dw BGColumn5C
    .dw BGColumn5D
    .dw BGColumn5E
    .dw BGColumn5F
    .dw BGColumn60
    .dw BGColumn61
    .dw BGColumn62
    .dw BGColumn63
    .dw BGColumn64
    .dw BGColumn65
    .dw BGColumn66
    .dw BGColumn67
    .dw BGColumn68
    .dw BGColumn69
;   WATER
    .dw BGColumn6A
    .dw BGColumn6B
    .dw BGColumn6C
    .dw BGColumn6D
    .dw BGColumn6E
    .dw BGColumn6F
    .dw BGColumn70
    .dw BGColumn71
    .dw BGColumn72
    .dw BGColumn73
    .dw BGColumn74
    .dw BGColumn75
    .dw BGColumn76
    .dw BGColumn77
    .dw BGColumn78
;   WATER CASTLE
    .dw BGColumn79
    .dw BGColumn7A
    .dw BGColumn7B
    .dw BGColumn7C
    .dw BGColumn7D
    .dw BGColumn7E
    .dw BGColumn7F
    .dw BGColumn80
    .dw BGColumn81
    .dw BGColumn82
    .dw BGColumn83
    .dw BGColumn84
    .dw BGColumn85
    .dw BGColumn86
    .dw BGColumn87
    .dw BGColumn88
    .dw BGColumn89
    .dw BGColumn8A
    .dw BGColumn8B
    .dw BGColumn8C
    .dw BGColumn8D
;   LATERNS
    .dw BGColumn8E
    .dw BGColumn8F
    .dw BGColumn90
    .dw BGColumn91
.ENDS

.SECTION "BG Scenery Column Data" BANK BANK_SLOT2 SLOT 2 FREE RETURNORG
BGColumn01: ; CLOUD [R] @ 09
    .db $09, MT_CLOUD_RIGHT
    .db $8A, MT_CLOUD_RIGHTBOT

BGColumn02: ; CLOUD [L] @ 01
    .db $01, MT_CLOUD_LEFT
    .db $82, MT_CLOUD_LEFTBOT

BGColumn03: ; CLOUD [M] @ 01
    .db $01, MT_CLOUD_MID
    .db $82, MT_CLOUD_MIDBOT

BGColumn04: ; CLOUD [R] @ 01
    .db $01, MT_CLOUD_RIGHT
    .db $82, MT_CLOUD_RIGHTBOT

BGColumn05: ; CLOUD [L] @ 05
    .db $05, MT_CLOUD_LEFT
    .db $86, MT_CLOUD_LEFTBOT

BGColumn06: ; CLOUD [M] @ 05
    .db $05, MT_CLOUD_MID
    .db $86, MT_CLOUD_MIDBOT

BGColumn07: ; CLOUD [R] @ 05
    .db $05, MT_CLOUD_RIGHT
    .db $86, MT_CLOUD_RIGHTBOT

BGColumn08: ; CLOUD [L] @ 00
    .db $00, MT_CLOUD_LEFT
    .db $81, MT_CLOUD_LEFTBOT

BGColumn09: ; CLOUD [M] @ 00
    .db $00, MT_CLOUD_MID
    .db $81, MT_CLOUD_MIDBOT

BGColumn0A: ; CLOUD [R] @ 00
    .db $00, MT_CLOUD_RIGHT
    .db $81, MT_CLOUD_RIGHTBOT

BGColumn0B: ; CLOUD [L] @ 09
    .db $09, MT_CLOUD_LEFT
    .db $8A, MT_CLOUD_LEFTBOT

BGColumn0C: ; CLOUD [M] @ 09
    .db $09, MT_CLOUD_MID
    .db $8A, MT_CLOUD_MIDBOT

BGColumn0D: ; CLOUD [L] @ 04
    .db $04, MT_CLOUD_LEFT
    .db $85, MT_CLOUD_LEFTBOT

BGColumn0E: ; CLOUD [M] @ 04
    .db $04, MT_CLOUD_MID
    .db $85, MT_CLOUD_MIDBOT

BGColumn0F: ; CLOUD [R] @ 04
    .db $04, MT_CLOUD_RIGHT
    .db $85, MT_CLOUD_RIGHTBOT

;   ---

BGColumn10:
    .db $0A, MT_MOUNT_LEFT
    .db $8B, MT_MOUNT_LEFTBOT

BGColumn11:
    .db $09, MT_MOUNT_LEFT
    .db $8A, MT_MOUNT_LEFTBOT

BGColumn12:
    .db $08, MT_MOUNT_MIDTOP
    .db $09, $01
    .db $8A, MT_MOUNT_MIDBOT

BGColumn13:
    .db $09, MT_MOUNT_RIGHT
    .db $8A, MT_MOUNT_RIGHTBOT

BGColumn14:
    .db $0A, MT_MOUNT_RIGHT
    .db $8B, MT_MOUNT_RIGHTBOT

BGColumn15:
    .db $8A, MT_BUSH_LEFT

BGColumn16:
    .db $8A, MT_BUSH_MID

BGColumn17:
    .db $8A, MT_BUSH_RIGHT

BGColumn18:
    .db $09, MT_MOUNT_MIDTOP
    .db $0A, $01
    .db $8B, MT_MOUNT_MIDBOT

;   ---

BGColumn19:
    .db $09, MT_SMALLTREE_TOP
    .db $0A, MT_TREE_TRUNK
    .db $8B, MT_TREE_TRUNK

BGColumn1A:
    .db $08, MT_TALLTREE_TOP
    .db $09, MT_TALLTREE_BOT
    .db $8A, MT_TREE_TRUNK

BGColumn1B:
    .db $8A, MT_FENCE

;   ---

BGColumn1C:
    .db $06, MT_STAR_00
    .db $08, MT_STAR_01
    .db $09, MT_CLOUD_RIGHT
    .db $8A, MT_CLOUD_RIGHTBOT

BGColumn1D:
    .db $01, MT_STAR_02
    .db $88, MT_STAR_03

BGColumn1E:
    .db $02, MT_STAR_04
    .db $87, MT_STAR_05

BGColumn1F:
    .db $01, MT_CLOUD_MID
    .db $02, MT_CLOUD_MIDBOT
    .db $03, MT_STAR_03
    .db $86, MT_STAR_06

BGColumn20:
    .db $01, MT_CLOUD_RIGHT
    .db $02, MT_CLOUD_RIGHTBOT
    .db $84, MT_STAR_07

BGColumn21:
    .db $01, MT_STAR_05
    .db $87, MT_STAR_08

BGColumn22:
    .db $02, MT_STAR_07
    .db $88, MT_STAR_09

BGColumn23:
    .db $01, MT_STAR_03
    .db $05, MT_CLOUD_LEFT
    .db $86, MT_CLOUD_LEFTBOT

BGColumn24:
    .db $04, MT_STAR_0A
    .db $05, MT_CLOUD_MID
    .db $86, MT_CLOUD_MIDBOT

BGColumn25:
    .db $86, MT_STAR_07

BGColumn26:
    .db $85, MT_STAR_0B

BGColumn27:
    .db $80, MT_STAR_01

BGColumn28:
    .db $03, MT_STAR_0C
    .db $85, MT_STAR_0D

BGColumn29:
    .db $00, MT_CLOUD_LEFT
    .db $01, MT_CLOUD_LEFTBOT
    .db $87, MT_STAR_0E

BGColumn2A:
    .db $00, MT_CLOUD_MID
    .db $01, MT_CLOUD_MIDBOT
    .db $82, MT_STAR_04

BGColumn2B:
    .db $00, MT_CLOUD_RIGHT
    .db $01, MT_CLOUD_RIGHTBOT
    .db $88, MT_STAR_0F

BGColumn2C:
    .db $83, MT_STAR_0D

BGColumn2D:
    .db $86, MT_STAR_10

BGColumn2E:
    .db $03, MT_STAR_09
    .db $04, MT_STAR_04
    .db $88, MT_STAR_0A

BGColumn2F:
    .db $86, MT_STAR_09

BGColumn30:
    .db $06, MT_STAR_02
    .db $09, MT_CLOUD_LEFT
    .db $8A, MT_CLOUD_LEFTBOT

BGColumn31:
    .db $00, MT_STAR_01
    .db $03, MT_STAR_0C
    .db $04, MT_STAR_06
    .db $09, MT_CLOUD_MID
    .db $8A, MT_CLOUD_MIDBOT

BGColumn32:
    .db $84, MT_STAR_08

BGColumn33:
    .db $06, MT_STAR_00
    .db $88, MT_STAR_01

BGColumn34:
    .db $03, MT_STAR_03
    .db $05, MT_CLOUD_MID
    .db $86, MT_CLOUD_MIDBOT

BGColumn35:
    .db $01, MT_STAR_05
    .db $04, MT_CLOUD_MID
    .db $05, MT_CLOUD_MIDBOT
    .db $87, MT_STAR_08

BGColumn36:
    .db $02, MT_STAR_07
    .db $04, MT_CLOUD_RIGHT
    .db $05, MT_CLOUD_RIGHTBOT
    .db $88, MT_STAR_09

BGColumn37:
    .db $81, MT_STAR_03

BGColumn38:
    .db $84, MT_STAR_0A

BGColumn39:
    .db $05, MT_STAR_0B
    .db $09, MT_CLOUD_LEFT
    .db $8A, MT_CLOUD_LEFTBOT

BGColumn3A:
    .db $00, MT_STAR_01
    .db $09, MT_CLOUD_MID
    .db $8A, MT_CLOUD_MIDBOT

;   ---

BGColumn3B:
    .db $06, MT_STAR_00
    .db $08, MT_STAR_01
    .db $0A, MT_MOUNT_LEFT
    .db $8B, MT_MOUNT_LEFTBOT

BGColumn3C:
    .db $01, MT_STAR_02
    .db $08, MT_STAR_03
    .db $09, MT_MOUNT_LEFT
    .db $8A, MT_MOUNT_LEFTBOT

BGColumn3D:
    .db $02, MT_STAR_04
    .db $07, MT_STAR_05
    .db $08, MT_MOUNT_MIDTOP
    .db $09, $01
    .db $8A, MT_MOUNT_MIDBOT

BGColumn3E:
    .db $03, MT_STAR_03
    .db $06, MT_STAR_06
    .db $0A, MT_MOUNT_RIGHT
    .db $8B, MT_MOUNT_RIGHTBOT

BGColumn3F:
    .db $84, MT_STAR_07

BGColumn40:
    .db $01, MT_CLOUD_LEFT
    .db $02, MT_CLOUD_LEFTBOT
    .db $88, MT_STAR_09

BGColumn41:
    .db $01, MT_CLOUD_RIGHT
    .db $02, MT_CLOUD_RIGHTBOT
    .db $84, MT_STAR_0A

BGColumn42:
    .db $06, MT_STAR_07
    .db $8A, MT_BUSH_MID

BGColumn43:
    .db $05, MT_STAR_0B
    .db $8A, MT_BUSH_MID

BGColumn44:
    .db $00, MT_STAR_01
    .db $8A, MT_BUSH_RIGHT

BGColumn45:
    .db $03, MT_STAR_0C
    .db $05, MT_STAR_0D
    .db $09, MT_MOUNT_MIDTOP
    .db $0A, $01
    .db $8B, MT_MOUNT_MIDBOT

BGColumn46:
    .db $07, MT_STAR_0E
    .db $0A, MT_MOUNT_RIGHT
    .db $8B, MT_MOUNT_RIGHTBOT

BGColumn47:
    .db $00, MT_CLOUD_LEFT
    .db $01, MT_CLOUD_LEFTBOT
    .db $82, MT_STAR_04

BGColumn48:
    .db $06, MT_STAR_10
    .db $8A, MT_BUSH_LEFT

BGColumn49:
    .db $03, MT_STAR_09
    .db $04, MT_STAR_04
    .db $08, MT_STAR_0A
    .db $8A, MT_BUSH_MID

BGColumn4A:
    .db $01, MT_CLOUD_LEFT
    .db $02, MT_CLOUD_LEFTBOT
    .db $86, MT_STAR_09

BGColumn4B:
    .db $01, MT_CLOUD_MID
    .db $02, MT_CLOUD_MIDBOT
    .db $86, MT_STAR_02

BGColumn4C:
    .db $00, MT_STAR_01
    .db $01, MT_CLOUD_MID
    .db $02, MT_CLOUD_MIDBOT
    .db $03, MT_STAR_0C
    .db $04, MT_STAR_06
    .db $89, MT_STAR_01

BGColumn4D:
    .db $01, MT_CLOUD_RIGHT
    .db $02, MT_CLOUD_RIGHTBOT
    .db $84, MT_STAR_08

BGColumn4E:
    .db $00, MT_CLOUD_LEFT
    .db $01, MT_CLOUD_LEFTBOT
    .db $03, MT_STAR_03
    .db $86, MT_STAR_06

BGColumn4F:
    .db $00, MT_CLOUD_MID
    .db $01, MT_CLOUD_MIDBOT
    .db $84, MT_STAR_07

BGColumn50:
    .db $00, MT_CLOUD_RIGHT
    .db $01, MT_CLOUD_RIGHTBOT
    .db $87, MT_STAR_08

BGColumn51:
    .db $01, MT_STAR_03
    .db $8A, MT_BUSH_LEFT

BGColumn52:
    .db $04, MT_STAR_0A
    .db $8A, MT_BUSH_MID

BGColumn53:
    .db $06, MT_STAR_07
    .db $8A, MT_BUSH_RIGHT

;   ---

BGColumn54:
    .db $01, MT_CLOUD_LEFT
    .db $02, MT_CLOUD_LEFTBOT
    .db $06, MT_STAR_00
    .db $88, MT_STAR_01

BGColumn55:
    .db $01, MT_CLOUD_MID
    .db $02, MT_CLOUD_MIDBOT
    .db $88, MT_STAR_03

BGColumn56:
    .db $01, MT_CLOUD_MID
    .db $02, MT_CLOUD_MIDBOT
    .db $87, MT_STAR_05

BGColumn57:
    .db $03, MT_STAR_03
    .db $86, MT_STAR_06

BGColumn58:
    .db $05, MT_STAR_0B
    .db $8A, MT_FENCE

BGColumn59:
    .db $00, MT_STAR_01
    .db $8A, MT_FENCE

BGColumn5A:
    .db $03, MT_STAR_0C
    .db $05, MT_STAR_0D
    .db $8A, MT_FENCE

BGColumn5B:
    .db $01, MT_CLOUD_LEFT
    .db $02, MT_CLOUD_LEFTBOT
    .db $87, MT_STAR_0E

BGColumn5C:
    .db $06, MT_STAR_10
    .db $09, MT_SMALLTREE_TOP
    .db $0A, MT_TREE_TRUNK
    .db $8B, MT_TREE_TRUNK

BGColumn5D:
    .db $03, MT_STAR_09
    .db $04, MT_STAR_04
    .db $08, MT_STAR_0A
    .db $09, MT_SMALLTREE_TOP
    .db $0A, MT_TREE_TRUNK
    .db $8B, MT_TREE_TRUNK

BGColumn5E:
    .db $00, MT_CLOUD_LEFT
    .db $01, MT_CLOUD_LEFTBOT
    .db $86, MT_STAR_09

BGColumn5F:
    .db $00, MT_CLOUD_MID
    .db $01, MT_CLOUD_MIDBOT
    .db $86, MT_STAR_02

BGColumn60:
    .db $00, MT_CLOUD_RIGHT
    .db $01, MT_CLOUD_RIGHTBOT
    .db $03, MT_STAR_0C
    .db $04, MT_STAR_06
    .db $89, MT_STAR_01

BGColumn61:
    .db $01, MT_CLOUD_MID
    .db $02, MT_CLOUD_MIDBOT
    .db $84, MT_STAR_08

BGColumn62:
    .db $01, MT_CLOUD_MID
    .db $02, MT_CLOUD_MIDBOT
    .db $06, MT_STAR_00
    .db $88, MT_STAR_01

BGColumn63:
    .db $01, MT_CLOUD_RIGHT
    .db $02, MT_CLOUD_RIGHTBOT
    .db $88, MT_STAR_03

BGColumn64:
    .db $87, MT_STAR_05

BGColumn65:
    .db $04, MT_STAR_07
    .db $8A, MT_FENCE

BGColumn66:
    .db $01, MT_STAR_05
    .db $07, MT_STAR_08
    .db $8A, MT_FENCE

BGColumn67:
    .db $02, MT_STAR_07
    .db $08, MT_STAR_09
    .db $09, MT_SMALLTREE_TOP
    .db $0A, MT_TREE_TRUNK
    .db $8B, MT_TREE_TRUNK

BGColumn68:
    .db $01, MT_STAR_03
    .db $8A, MT_FENCE

BGColumn69:
    .db $00, MT_CLOUD_MID
    .db $01, MT_CLOUD_MIDBOT
    .db $85, MT_STAR_0B

;   ---

BGColumn6A:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATERBG_00
    .db $0A, MT_WATERBG_01
    .db $8B, MT_WATERBG_02

BGColumn6B:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATER
    .db $0A, MT_WATERBG_03
    .db $8B, MT_WATERBG_04

BGColumn6C:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATER
    .db $0A, MT_WATER
    .db $8B, MT_WATERBG_05

BGColumn6D:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATER
    .db $0A, MT_WATER
    .db $8B, MT_WATERBG_04

BGColumn6E:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATERBG_06
    .db $0A, MT_WATERBG_07
    .db $8B, MT_WATERBG_08

BGColumn6F:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATERBG_09
    .db $0A, MT_WATERBG_0A
    .db $8B, MT_WATERBG_0B

BGColumn70:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATERBG_0C
    .db $0A, MT_WATERBG_0D
    .db $8B, MT_WATERBG_08

BGColumn71:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATERBG_0E
    .db $0A, MT_WATERBG_0F
    .db $8B, MT_WATERBG_0B

BGColumn72:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATER
    .db $0A, MT_WATERBG_10
    .db $8B, MT_WATERBG_05

BGColumn73:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATERBG_11
    .db $0A, MT_WATERBG_12
    .db $8B, MT_WATERBG_13

BGColumn74:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATERBG_14
    .db $0A, MT_WATERBG_15
    .db $8B, MT_WATERBG_02

BGColumn75:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATERBG_04
    .db $0A, MT_WATERBG_16
    .db $8B, MT_WATERBG_13

BGColumn76:
    .db $07, MT_WATERBG_06
    .db $08, MT_WATERBG_07
    .db $09, MT_WATERBG_08
    .db $0A, MT_WATERBG_17
    .db $8B, MT_WATERBG_02

BGColumn77:
    .db $07, MT_WATERBG_0E
    .db $08, MT_WATERBG_0F
    .db $09, MT_WATERBG_0B
    .db $0A, MT_WATERBG_16
    .db $8B, MT_WATERBG_13

;   ---

BGColumn78:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATER
    .db $8A, MT_WCASTLE_00

BGColumn79:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WATER
    .db $8A, MT_WCASTLE_01

BGColumn7A:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WCASTLE_02
    .db $8A, MT_WCASTLE_03

BGColumn7B:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WCASTLE_04
    .db $8A, MT_WCASTLE_05

BGColumn7C:
    .db $07, MT_WATER
    .db $08, MT_WCASTLE_06
    .db $09, MT_WCASTLE_07
    .db $8A, MT_WCASTLE_03

BGColumn7D:
    .db $07, MT_WCASTLE_08
    .db $08, MT_WCASTLE_09
    .db $09, MT_WCASTLE_0A
    .db $8A, MT_WCASTLE_0B

BGColumn7E:
    .db $07, MT_WCASTLE_0C
    .db $08, MT_WCASTLE_0D
    .db $09, MT_WCASTLE_0E
    .db $8A, MT_WCASTLE_0F

BGColumn7F:
    .db $07, MT_WCASTLE_10
    .db $08, MT_WCASTLE_11
    .db $09, MT_WCASTLE_12
    .db $8A, MT_WCASTLE_13

BGColumn80:
    .db $07, MT_WCASTLE_14
    .db $08, MT_WCASTLE_15
    .db $09, MT_WCASTLE_16
    .db $8A, MT_WCASTLE_17

BGColumn81:
    .db $07, MT_WCASTLE_18
    .db $08, MT_WCASTLE_19
    .db $09, MT_WCASTLE_0A
    .db $8A, MT_WCASTLE_0B

BGColumn82:
    .db $07, MT_WCASTLE_1A
    .db $08, MT_WCASTLE_0D
    .db $09, MT_WCASTLE_0E
    .db $8A, MT_WCASTLE_0F

BGColumn83:
    .db $07, MT_WCASTLE_1B
    .db $08, MT_WCASTLE_11
    .db $09, MT_WCASTLE_12
    .db $8A, MT_WCASTLE_13

BGColumn84:
    .db $07, MT_WCASTLE_1C
    .db $08, MT_WCASTLE_1D
    .db $09, MT_WCASTLE_0E
    .db $8A, MT_WCASTLE_0F

BGColumn85:
    .db $07, MT_WCASTLE_1E
    .db $08, MT_WCASTLE_1F
    .db $09, MT_WCASTLE_12
    .db $8A, MT_WCASTLE_13

BGColumn86:
    .db $07, MT_WATER
    .db $08, MT_WATER
    .db $09, MT_WCASTLE_20
    .db $8A, MT_WCASTLE_17

BGColumn87:
    .db $07, MT_WCASTLE_18
    .db $08, MT_WCASTLE_19
    .db $09, MT_WCASTLE_0A
    .db $8A, MT_WCASTLE_21

BGColumn88:
    .db $07, MT_WCASTLE_0C
    .db $08, MT_WCASTLE_0D
    .db $09, MT_WCASTLE_0D
    .db $8A, MT_WCASTLE_22

BGColumn89:
    .db $07, MT_WCASTLE_10
    .db $08, MT_WCASTLE_11
    .db $09, MT_WCASTLE_12
    .db $8A, MT_WCASTLE_23

BGColumn8A:
    .db $07, MT_WCASTLE_14
    .db $08, MT_WCASTLE_15
    .db $09, MT_WCASTLE_24
    .db $8A, MT_WCASTLE_25

BGColumn8B:
    .db $07, MT_WCASTLE_18
    .db $08, MT_WCASTLE_19
    .db $09, MT_WCASTLE_19
    .db $8A, MT_WCASTLE_26

BGColumn8C:
    .db $07, MT_WCASTLE_1A
    .db $08, MT_WCASTLE_0D
    .db $09, MT_WCASTLE_0D
    .db $8A, MT_WCASTLE_22

BGColumn8D:
    .db $07, MT_WCASTLE_1B
    .db $08, MT_WCASTLE_11
    .db $09, MT_WCASTLE_12
    .db $8A, MT_WCASTLE_23

;   ---

BGColumn8E:
    .db $04, MT_LATERN_LT
    .db $85, MT_LATERN_LB

BGColumn8F:
    .db $04, MT_LATERN_RT
    .db $85, MT_LATERN_RB

BGColumn90:
    .db $01, MT_LATERN_LT
    .db $82, MT_LATERN_LB

BGColumn91:
    .db $01, MT_LATERN_RT
    .db $82, MT_LATERN_RB
.ENDS