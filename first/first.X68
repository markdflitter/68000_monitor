; constants
DISPLAY_BASE        EQU $E00000
DISPLAY_            EQU $0
DISPLAY             EQU DISPLAY_BASE+2*DISPLAY_

DUART_BASE          EQU $D00000
DUART_MR_           EQU $0
DUART_OPCR_         EQU $D
DUART_SET_OPR_      EQU $E
DUART_RESET_OPR_    EQU $F
DUART_MR            EQU DUART_BASE+2*DUART_MR_
DUART_OPCR          EQU DUART_BASE+2*DUART_OPCR_
DUART_SET_OPR       EQU DUART_BASE+2*DUART_SET_OPR_
DUART_RESET_OPR     EQU DUART_BASE+2*DUART_RESET_OPR_

; start vector
    ORG    $0
    DC.L $00000000
    DC.L $00000000 
; first instruction of program  
:INITIALISE
    MOVE.B #$0,DUART_MR
    MOVE.B #$0,DUART_OPCR
START:
    MOVE.L #7,D1                    ; loop counter
    MOVE.L #$0,D2                   ; output value
LOOP:
    MOVE.B #$FF,DUART_RESET_OPR     ; clear UART output register
    MOVE.B D2,DUART_SET_OPR         ; set UART outpout register
    MOVE.B D2,DISPLAY               ; write to the display
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
