*-----------------------------------------------------------
* Title      : MDFmon 
* Written by : Mark Flitter
* Date       : March 2021
* Description: 68000 monitor program
*-----------------------------------------------------------
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

DUART_MRA           EQU DUART_BASE+2*DUART_MRA_+1
DUART_SRA           EQU DUART_BASE+2*DUART_SRA_+1
DUART_CSRA          EQU DUART_BASE+2*DUART_CSRA_+1
DUART_CRA           EQU DUART_BASE+2*DUART_CRA_+1
DUART_TXA           EQU DUART_BASE+2*DUART_TXA_+1
DUART_RXA           EQU DUART_BASE+2*DUART_RXA_+1

DUART_MRB           EQU DUART_BASE+2*DUART_MRB_+1
DUART_SRB           EQU DUART_BASE+2*DUART_SRB_+1
DUART_CSRB          EQU DUART_BASE+2*DUART_CSRB_+1
DUART_CRB           EQU DUART_BASE+2*DUART_CRB_+1
DUART_TXB           EQU DUART_BASE+2*DUART_TXB_+1
DUART_RXB           EQU DUART_BASE+2*DUART_RXB_+1

DUART_ACR           EQU DUART_BASE+2*DUART_ACR_+1
DUART_IMR           EQU DUART_BASE+2*DUART_IMR_+1
DUART_IVR           EQU DUART_BASE+2*DUART_IVR_+1
DUART_OPCR          EQU DUART_BASE+2*DUART_OPCR_+1
DUART_SET_OPR       EQU DUART_BASE+2*DUART_SET_OPR_+1
DUART_RESET_OPR     EQU DUART_BASE+2*DUART_RESET_OPR_+1

;MACROs
PRINT_CHAR MACRO                  ; \1 = register to use for status poll, \2 = char to send
WAIT_FOR_READY\@                  ; wait until the there is space to send
  MOVE.B DUART_SRA,\1             ; read status register
  BTST #2,\1                      ; check for space to send
  BEQ WAIT_FOR_READY\@            ; no space, check again
  MOVE.B \2,DUART_TXA             ; send the next character
  ENDM

PRINT_STR MACRO                   ; \1 = register to use for status poll, \2 = register containing address of zero terminated string
LOOP\@
  CMP.B #0,(\2)                   ; 0 -> done
  BEQ EXIT\@
  PRINT_CHAR \1,(\2)+
  JMP LOOP\@
EXIT\@
  ENDM

; start vector
    ORG  $0
    DC.L $00000000
    DC.L $00000000 
    
; start of program  
START
    MOVE.B #0,DISPLAY

;initialise UART
    MOVE.B #$0,DUART_ACR            
    MOVE.B #$0,DUART_IMR            ; no interrupts, please            
    MOVE.B #$0,DUART_OPCR           ; enable all outputs

; channel A
    MOVE.B #$03,DUART_MRA           ; no flow control, no parity, 8 data bits
    MOVE.B #$07,DUART_MRA           ; auto echo and 1 stop bit
    MOVE.B #$BB,DUART_CSRA          ; 9600 baud
    MOVE.B #$5,DUART_CRA            ; enable rx & tx

; channel B
    MOVE.B #$03,DUART_MRB           ; no flow control, no parity, 8 data bits
    MOVE.B #$47,DUART_MRB           ; auto echo and 1 stop bit
    MOVE.B #$BB,DUART_CSRB          ; 9600 baud
    MOVE.B #$5,DUART_CRB            ; enable rx & tx

    MOVE.B #1,DISPLAY
    
    
    LEA VERSION,A0
    PRINT_STR D0,A0                       
    PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF

    MOVE.B #2,DISPLAY
MAIN_LOOP
    MOVE.B #3,DISPLAY

    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space

WAIT_FOR_INPUT
    MOVE.B #4,DISPLAY

    MOVE.B DUART_SRA,D0             ; read status register
    BTST #0,D0                      ; check for character
    BEQ WAIT_FOR_INPUT              ; nothing, check again

    MOVE.B DUART_RXA,D1             ; got a character, read it
    PRINT_CHAR D0,D1                ; echo it back
    PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF
    
    CMP.B #'V',D1
    BEQ V

    CMP.B #'H',D1
    BEQ H
    
    LEA HUH,A0
    PRINT_STR D0,A0                       

    JMP MAIN_LOOP

V   LEA VERSION,A0
    PRINT_STR D0,A0       
    JMP MAIN_LOOP
    
H   LEA HELP,A0
    PRINT_STR D0,A0       
    JMP MAIN_LOOP
    
    SIMHALT                         ; halt simulator

; strings
VERSION DC.B 'MDFmon V1.1',13,10,0
HELP    DC.B 'H(elp)',13,10,'V(ersion)',13,10,0
HUH     DC.B 'Huh?',13,10,0
    
    END    START                    ; last line of source



*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
