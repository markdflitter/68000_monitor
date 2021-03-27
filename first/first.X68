; constants
DISPLAY_BASE        EQU $E00000
DISPLAY_            EQU $0
DISPLAY             EQU DISPLAY_BASE+2*DISPLAY_

DUART_BASE          EQU $D00000
DUART_MRA_          EQU $0
DUART_CSRA_         EQU $1
DUART_CRA_          EQU $2
DUART_TXA_          EQU $3
DUART_ACR_          EQU $4
DUART_IMR_          EQU $5
DUART_OPCR_         EQU $D
DUART_SET_OPR_      EQU $E
DUART_RESET_OPR_    EQU $F
DUART_MRA           EQU DUART_BASE+2*DUART_MRA_
DUART_CSRA          EQU DUART_BASE+2*DUART_CSRA_
DUART_CRA           EQU DUART_BASE+2*DUART_CRA_
DUART_TXA           EQU DUART_BASE+2*DUART_TXA_
DUART_ACR           EQU DUART_BASE+2*DUART_ACR_
DUART_IMR           EQU DUART_BASE+2*DUART_IMR_
DUART_OPCR          EQU DUART_BASE+2*DUART_OPCR_
DUART_SET_OPR       EQU DUART_BASE+2*DUART_SET_OPR_
DUART_RESET_OPR     EQU DUART_BASE+2*DUART_RESET_OPR_

; start vector
    ORG    $0
    DC.L $00000000
    DC.L $00000000 
; first instruction of program  
INITIALISE:
    MOVE.B #$03,DUART_MRA           ; MR1A
    MOVE.B #$07,DUART_MRA           ; MR2A
    MOVE.B #$BB,DUART_CSRA          ; 9600 baud
    MOVE.B #$4,DUART_CRA            ; enable tx
    MOVE.B #$0,DUART_ACR            
    MOVE.B #$0,DUART_IMR            ; no interrupts, please            
    MOVE.B #$0,DUART_OPCR
START:
    MOVE.L #7,D1                    ; loop counter
    MOVE.L #$0,D2                   ; output value
LOOP:
    MOVE.B #$FF,DUART_RESET_OPR     ; clear UART output register
    MOVE.B D2,DUART_SET_OPR         ; set UART output register
    MOVE.B D2,DISPLAY               ; write to the display
    MOVE.B D2,D3                    ; convert to ASCII in D3...
    ADD.B #48,D3                    ; ... by adding 48
    MOVE.B D3,DUART_TXA             ; to the serial port!!
    ADD.B #1,D2                     ; next number
    MOVE.L #$FFFFFFFF,D0            ; wait for a bit...
WAIT:
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    NOP
    DBEQ D0,WAIT                    ; end of wait loop
    DBEQ D1,LOOP                    ; next number
    JMP START                       ; ...and from the top
    END    START                    ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
