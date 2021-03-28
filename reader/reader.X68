; constants
DISPLAY_BASE        EQU $E00000
DISPLAY_            EQU $0
DISPLAY             EQU DISPLAY_BASE+2*DISPLAY_

DUART_BASE          EQU $D00000
DUART_MRA_          EQU $0
DUART_CSRA_         EQU $1
DUART_SRA_          EQU $1
DUART_CRA_          EQU $2
DUART_TXA_          EQU $3
DUART_RXA_          EQU $3
DUART_ACR_          EQU $4
DUART_IMR_          EQU $5
DUART_MRB_          EQU $8
DUART_CSRB_         EQU $9
DUART_SRB_          EQU $9
DUART_CRB_          EQU $A
DUART_TXB_          EQU $B
DUART_RXB_          EQU $B
DUART_IVR_          EQU $C
DUART_OPCR_         EQU $D
DUART_SET_OPR_      EQU $E
DUART_RESET_OPR_    EQU $F

DUART_MRA           EQU DUART_BASE+2*DUART_MRA_
DUART_SRA           EQU DUART_BASE+2*DUART_SRA_
DUART_CSRA          EQU DUART_BASE+2*DUART_CSRA_
DUART_CRA           EQU DUART_BASE+2*DUART_CRA_
DUART_TXA           EQU DUART_BASE+2*DUART_TXA_
DUART_RXA           EQU DUART_BASE+2*DUART_RXA_

DUART_MRB           EQU DUART_BASE+2*DUART_MRB_
DUART_SRB           EQU DUART_BASE+2*DUART_SRB_
DUART_CSRB          EQU DUART_BASE+2*DUART_CSRB_
DUART_CRB           EQU DUART_BASE+2*DUART_CRB_
DUART_TXB           EQU DUART_BASE+2*DUART_TXB_
DUART_RXB           EQU DUART_BASE+2*DUART_RXB_

DUART_ACR           EQU DUART_BASE+2*DUART_ACR_
DUART_IMR           EQU DUART_BASE+2*DUART_IMR_
DUART_IVR           EQU DUART_BASE+2*DUART_IVR_
DUART_OPCR          EQU DUART_BASE+2*DUART_OPCR_
DUART_SET_OPR       EQU DUART_BASE+2*DUART_SET_OPR_
DUART_RESET_OPR     EQU DUART_BASE+2*DUART_RESET_OPR_

; start vector
    ORG    $0
    DC.L $00000000
    DC.L $00000000 
; first instruction of program  
INITIALISE:
    MOVE.B #$03,DUART_MRA           ; no flow control, no parity, 8 data bits
    MOVE.B #$07,DUART_MRA           ; auto echo and 1 stop bit
    MOVE.B #$BB,DUART_CSRA          ; 9600 baud
    MOVE.B #$5,DUART_CRA            ; enable rx & tx

    MOVE.B #$03,DUART_MRB           ; no flow control, no parity, 8 data bits
    MOVE.B #$47,DUART_MRB           ; auto echo and 1 stop bit
    MOVE.B #$BB,DUART_CSRB          ; 9600 baud
    MOVE.B #$5,DUART_CRB            ; enable rx & tx

    MOVE.B #$0,DUART_ACR            
    MOVE.B #$0,DUART_IMR            ; no interrupts, please            
    MOVE.B #$0,DUART_OPCR           ; enable all outputs

    MOVE.B #$F6,DUART_IVR           
START:
    MOVE.L #7,D1                    ; loop counter
    MOVE.L #$0,D2                   ; output value
LOOP:
    MOVE.B #$FF,DUART_RESET_OPR     ; clear UART output register
    MOVE.B D2,DUART_SET_OPR         ; set UART output register
    ADD.B #1,D2                     ; next number
    MOVE.L #$FFFFFFFF,D0            ; wait for a bit...
    ;MOVE.W DUART_IVR,D3   
    ;ANDI #$0F,D3        
    ;MOVE.B D3,DISPLAY               ; write to the display
    ;ADD.B #48,D3                    ; ...back to a number
    ;MOVE.B D3,DUART_TXA               
    ;SUB.B #48,D3                    ; ...back to a number
    MOVE.W DUART_SRA,D3
    BTST #$0,D3
    BEQ CONTINUE
    MOVE.W DUART_RXA,D3
    MOVE.B D3,DUART_TXA    
    ANDI #$0F,D3        
    MOVE.B D3,DISPLAY               ; write to the display
    ;ADD.B #48,D3                    ; ...back to a number
    ;MOVE.B D3,DUART_TXA               

CONTINUE:
    ;MOVE.W DUART_RXA,D3
    ;MOVE.B D3,DUART_TXA               
WAIT:
    NOP
    NOP
    NOP
    NOP
    ;MOVE.W DUART_SRA,D3
    NOP
    NOP
    NOP
    NOP    
    ;MOVE.B D3,DISPLAY              ; write to the display
    ;BTST #$0,D3
    ;BEQ CONTINUE
    NOP
    NOP
    NOP
    NOP
    ;MOVE.W DUART_RXA,D3
    ;MOVE.B D3,DUART_TXA               
    ;MOVE.B D3,DUART_TXA               
           
    ;SUB.B #48,D3                    ; ...back to a number
    ;MOVE.B D3,DISPLAY               ; write to the display
    ANDI #$FB,CCR                   ; clear the Z bit if set
    DBEQ D0,WAIT                    ; end of wait loop
    DBEQ D1,LOOP                    ; next number
    JMP START                       ; ...and from the top
    END    START                    ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
