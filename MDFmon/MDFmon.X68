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
  
PRINT_REG MACRO                ; \1 = register to use for status poll, \2 = register containing binary number - will be destroyed!, \3 = working data register, \4 working address register
  LEA LUT,\4

  MOVE.L \2,\3
  LSR.L #8,\3
  LSR.L #8,\3
  LSR.L #8,\3
  LSR.L #4,\3
  ANDI #$F,\3
  
  MOVE.B 0(\4,\3),\3
  PRINT_CHAR \1,\3

  MOVE.L \2,\3
  LSR.L #8,\3
  LSR.L #8,\3
  LSR.L #8,\3
  ANDI #$F,\3
  
  MOVE.B 0(\4,\3),\3
  PRINT_CHAR \1,\3
  
  MOVE.L \2,\3
  LSR.L #8,\3
  LSR.L #8,\3
  LSR.L #4,\3
  ANDI #$F,\3
  
  MOVE.B 0(\4,\3),\3
  PRINT_CHAR \1,\3
  
  MOVE.L \2,\3
  LSR.L #8,\3
  LSR.L #8,\3
  ANDI #$F,\3
  
  MOVE.B 0(\4,\3),\3
  PRINT_CHAR \1,\3

  MOVE.L \2,\3
  LSR.L #8,\3
  LSR.L #4,\3
  ANDI #$F,\3
  
  MOVE.B 0(\4,\3),\3
  PRINT_CHAR \1,\3

  MOVE.L \2,\3
  LSR.L #8,\3
  ANDI #$F,\3
  
  MOVE.B 0(\4,\3),\3
  PRINT_CHAR \1,\3

  MOVE.L \2,\3
  LSR.L #4,\3
  ANDI #$F,\3
  
  MOVE.B 0(\4,\3),\3
  PRINT_CHAR \1,\3

  MOVE.L \2,\3
  ANDI #$F,\3
  
  MOVE.B 0(\4,\3),\3
  PRINT_CHAR \1,\3

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
    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space
    
    MOVE #0,D2                      ; address accumuulator

    MOVE.B #2,DISPLAY
MAIN_LOOP
    MOVE.B #3,DISPLAY

WAIT_FOR_INPUT
    MOVE.B #4,DISPLAY

    MOVE.B DUART_SRA,D0             ; read status register
    BTST #0,D0                      ; check for character
    BEQ WAIT_FOR_INPUT              ; nothing, check again

    MOVE.B DUART_RXA,D1             ; got a character, read it
    PRINT_CHAR D0,D1                ; echo it back

    CMP.B #'H',D1
    BEQ H

    CMP.B #'V',D1
    BEQ V
    
    CMP.B #'R',D1
    BEQ R

    CMP.B #'W',D1
    BEQ W

    CMP.B #'S',D1
    BEQ S

    CMP.B #'G',D1
    BEQ G

    CMP.B #'0',D1
    BEQ DIGIT
    CMP.B #'1',D1
    BEQ DIGIT
    CMP.B #'2',D1
    BEQ DIGIT
    CMP.B #'3',D1
    BEQ DIGIT
    CMP.B #'4',D1
    BEQ DIGIT
    CMP.B #'5',D1
    BEQ DIGIT
    CMP.B #'6',D1
    BEQ DIGIT
    CMP.B #'7',D1
    BEQ DIGIT
    CMP.B #'8',D1
    BEQ DIGIT
    CMP.B #'9',D1
    BEQ DIGIT
    
    CMP.B #'A',D1
    BEQ HEX_DIGIT
    CMP.B #'B',D1
    BEQ HEX_DIGIT
    CMP.B #'C',D1
    BEQ HEX_DIGIT
    CMP.B #'D',D1
    BEQ HEX_DIGIT
    CMP.B #'E',D1
    BEQ HEX_DIGIT
    CMP.B #'F',D1
    BEQ HEX_DIGIT

    PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF
    LEA HUH,A0
    PRINT_STR D0,A0
    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space
                       
    JMP MAIN_LOOP

; commands
H   PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF       
    LEA HELP,A0
    PRINT_STR D0,A0
    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space
    JMP MAIN_LOOP

V   PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF
    LEA VERSION,A0
    PRINT_STR D0,A0       
    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space
    JMP MAIN_LOOP
    
R   PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF
    MOVE.L D2,A0
    MOVE.L (A0),D1
    PRINT_REG D0,D1,D2,A0
    MOVE #0,A0
    MOVE #0,D2
    PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF
    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space
    
    JMP MAIN_LOOP

W   PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF
    MOVE.L #0,D3                
READ_DIGIT1
    MOVE.B DUART_SRA,D0             ; read status register
    BTST #0,D0                      ; check for character
    BEQ READ_DIGIT1                 ; nothing, check again

    MOVE.B DUART_RXA,D1             ; got a character, read it
    PRINT_CHAR D0,D1                ; echo it back
    SUB.B #'0',D1
    ANDI #$F,D1
    OR.B D1,D3
READ_DIGIT2
    MOVE.B DUART_SRA,D0             ; read status register
    BTST #0,D0                      ; check for character
    BEQ READ_DIGIT2                 ; nothing, check again

    MOVE.B DUART_RXA,D1             ; got a character, read it
    PRINT_CHAR D0,D1                ; echo it back
    LSL.L #4,D2                     ; add the next digit in the next 4 bits
    SUB.B #'0',D1
    ANDI #$F,D1
    OR.B D1,D3

    MOVE.L D0,A0
    MOVE (A0),D0
    MOVE #0,A0
    MOVE #0,D0

    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space
    JMP MAIN_LOOP

S   PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF
    LEA UNIMP,A0
    PRINT_STR D0,A0       
    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space
    JMP MAIN_LOOP

G   PRINT_CHAR D0,#13               ; CR
    PRINT_CHAR D0,#10               ; LF
    LEA UNIMP,A0
    PRINT_STR D0,A0
    PRINT_CHAR D0,#62               ; prompt
    PRINT_CHAR D0,#32               ; space
    JMP MAIN_LOOP
    
DIGIT
    LSL.L #4,D2             ; add the next digit in the next 4 bits
    SUB.B #'0',D1
    ANDI #$F,D1
    OR.B D1,D2
    JMP MAIN_LOOP
    
HEX_DIGIT
    LSL.L #4,D2
    SUB.B #'A',D1
    ADD.B #10,D1
    ANDI #$F,D1
    OR.B D1,D2
    JMP MAIN_LOOP

    SIMHALT                         ; halt simulator

; strings
VERSION DC.B 'MDF-mon V1.2 (29/03/2021)',13,10,0
HELP    DC.B 'H(elp)',13,10,'V(ersion)',13,10,'nnnnnnnnR(ead)',13,10,'nnnnnnnnW(rite)nn',13,10,'S(records)',13,10,'nnnnnnnnG(o)',13,10,0
HUH     DC.B 'Huh?',13,10,0
UNIMP   DC.B 'Unimplemented',13,10,0
LUT     DC.B '0123456789ABCDEF'
    
    END    START                    ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
