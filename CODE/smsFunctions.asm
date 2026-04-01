/*
------------------------------------------
            SMS FUNCTIONS
------------------------------------------
*/



/*
    INFO: WAITS FOR VBLANK
    INPUTS: NONE
    OUTPUTS: NONE
    AFFECTS: A
*/
waitForVblank:
;   CLEAR VBLANK STATUS
    IN A, (VDPCON_PORT)
;   WAIT UNTIL NEXT VBLANK
-:
    IN A, (VDPCON_PORT)
    OR A
    JP P, -
    RET


/*
    INFO: FUNCTIONS TO TURN THE DISPLAY ON OR OFF
    INPUTS: NONE
    OUTPUTS: NONE
    AFFECTS: A
*/
turnOffScreenVBlank:
;   TURN OFF SCREEN (KEEP VDP INTS)
    LD A, $A0
    JR +
turnOffVblankInts:
;   TURN OFF VBLANK INTERRUPTS (SCREEN ON)
    LD A, $C0   ; BIT 7 SET
    JR +
turnOffScreen:
;   TURN OFF SCREEN (AND DISABLE VDP INTS)
    LD A, $80   ; BIT 7 SET (OFFICAL DOCS SAY TO DO SO...)
    JR +
turnOnScreen:
;   TURN ON SCREEN (AND VDP INTS)
    LD A, $E0   ; BIT 7 SET (OFFICAL DOCS SAY TO DO SO...)
+:
    OUT (VDPCON_PORT), A
    LD A, $81
    OUT (VDPCON_PORT), A

    RET



/*
    INFO: FUNCTIONS TO TURN LINE INTERRUPTS ON OR OFF (OFF ALSO CLEARS V COUNTER)
    INPUTS: NONE
    OUTPUTS: NONE
    AFFECTS: A
*/
turnOffLineInts:
;   CLEAR V COUNTER
    LD A, $FF
    OUT (VDPCON_PORT), A
    LD A, $8A
    OUT (VDPCON_PORT), A
;   LINE INTS OFF
    LD A, $24
    JR +
turnOnLineInts:
;   LINE INTS ON
    LD A, $34
+:
    OUT (VDPCON_PORT), A
    LD A, $80
    OUT (VDPCON_PORT), A
    RET



/*
    INFO: Copies data to the VDP
    INPUT: hl = data address, bc = data length
    OUTPUT: NONE
    USES: AF, HL, BC
*/
copyToVDP:
    LD A, (HL)      ; WRITE BYTE TO VDP
    OUT (VDPDATA_PORT), A
    CPI     ; POINT TO NEXT BYTE AND DECREMENT COUNTER
    JP PE, copyToVDP    ; KEEP LOOPING UNTIL BC IS 0
    RET





/*
    INFO: Reads data from the VDP
    INPUT: hl = data address, bc = data length
    OUTPUT: NONE
    USES: AF, HL, BC
*/
copyFromVDP:
    IN A, (VDPDATA_PORT)    ; COPY BYTE FROM VDP TO DATA
    LD (HL), A
    CPI     ; POINT TO NEXT BYTE AND DECREMENT COUNTER
    JP PE, copyFromVDP    ; KEEP LOOPING UNTIL BC IS 0
	RET