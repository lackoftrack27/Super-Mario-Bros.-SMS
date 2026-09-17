; ------------------------------------------
;             SMS FUNCTIONS
; ------------------------------------------

;   INFO: WAITS FOR VBLANK
;   INPUTS: NONE
;   OUTPUTS: NONE
;   AFFECTS: A
waitForVblank:
;   CLEAR VBLANK STATUS
    IN A, (VDPCON_PORT)
;   WAIT UNTIL NEXT VBLANK
-:
    IN A, (VDPCON_PORT)
    RLCA
    JR NC, -
    RET


;   INFO: FUNCTIONS TO TURN THE DISPLAY OFF
;   INPUTS: NONE
;   OUTPUTS: NONE
;   AFFECTS: A
turnOffScreen:
;   TURN OFF SCREEN (AND DISABLE VDP INTS)
    LD A, $80 | MODE_CTRL2   ; BIT 7 SET (OFFICAL DOCS SAY TO DO SO...)
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A
    RET


;   INFO: Copies data to the VDP
;   INPUT: hl = data address, bc = data length
;   OUTPUT: NONE
;   USES: AF, HL, BC
copyToVDP:
    LD A, (HL)              ; WRITE BYTE TO VDP
    OUT (VDPDATA_PORT), A
    CPI                     ; POINT TO NEXT BYTE AND DECREMENT COUNTER
    JP PE, copyToVDP        ; KEEP LOOPING UNTIL BC IS 0
    RET


;   INFO: Reads data from the VDP
;   INPUT: hl = data address, bc = data length
;   OUTPUT: NONE
;   USES: AF, HL, BC
copyFromVDP:
    IN A, (VDPDATA_PORT)    ; COPY BYTE FROM VDP TO DATA
    LD (HL), A
    CPI                     ; POINT TO NEXT BYTE AND DECREMENT COUNTER
    JP PE, copyFromVDP      ; KEEP LOOPING UNTIL BC IS 0
	RET


;   INFO: Sets VRAM to a given value
;   INPUT: A - value, B - length (8 bit)
;   OUTPUT: NONE
;   USES: AF, B
MemsetVRAM8:
    OUT (VDPDATA_PORT), A
    DJNZ MemsetVRAM8
    RET


;   INFO: Sets VRAM to a given value
;   INPUT: A - value, BC - length (16 bit)
;   OUTPUT: NONE
;   USES: AF, BC
MemsetVRAM16:
    OUT (VDPDATA_PORT), A
    DJNZ MemsetVRAM16
    DEC C
    JP NZ, MemsetVRAM16
    RET