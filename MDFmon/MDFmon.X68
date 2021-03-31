*-----------------------------------------------------------
* Title      : MDFmon 
* Written by : Mark Flitter
* Date       : March 2021
* Description: 68000 monitor program
*-----------------------------------------------------------
; to do

DEBUG               EQU 0

; constants
DISPLAY_BASE        EQU $E00000
DISPLAY_            EQU $0
DISPLAY             EQU DISPLAY_BASE+2*DISPLAY_+1

DUART_BASE          EQU $D30000
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
RRRR
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

; macros
; convert top 4 bits of input register from binary to a single hex digit
; the input register is changed during the process
; \1 input data register containing binary number,  \2 data register for return value, \3 working address register
BIN2HEX MACRO
  LEA BIN2HEX_LUT,\3                ; load the lookup table
  ROL.L #4,\1                       ; shift the top 4 bits down to bottom of the register the and mask off everything else
  MOVE.B \1,\2
  ANDI.L #$F,\2
  MOVE.B 0(\3,\2),\2                ; use that as an index into the LUT
  ENDM

; convert single hex digit to 4 bit binary number in LSbits
; the input register is changed during the process
; \1 data register containing hex character, \2 data register for return value, \3 working address register
HEX2BIN MACRO
  LEA HEX2BIN_LUT,\3                  ; load the lookup table
  SUB.B #'0',\1                       ; work out offset and mask off anything rogue
  AND.L #$FF,\1                       ; ignore the top 3 bytes
  MOVE.B 0(\3,\1),\2                  ; use that as an index into the LUT      
  ENDM

; send a single char to the serial port
; \1 = char to send, \2 = data register to use for status poll
; will stamp on D0 and D1 in debug mode
PRINT_CHAR MACRO
WAIT_FOR_READY\@                  ; wait until the there is space to send
    IFEQ DEBUG
      MOVE.B DUART_SRA,\2           ; read status register
      BTST #2,\2                    ; check for space to send
      BEQ WAIT_FOR_READY\@          ; no space, check again
      MOVE.B \1,DUART_TXA           ; send the next character
    ENDC
    
    IFNE DEBUG
      MOVE.B \1,D1
      MOVE.L #6,D0   
      TRAP #15                      ; write to terminal in simulator
    ENDC

    ENDM

; send CR,LF to the serial port
; \1 = data register to use for status poll
PRINT_CRLF MACRO                  
    PRINT_CHAR #13,\1             ; CR
    PRINT_CHAR #10,\1             ; LF
    ENDM

; send C-style, zero terminated string to the serial port
; \1 = address register containing address of zero terminated string, \2 = data register to use for status poll, 
PRINT_STR MACRO
LOOP\@
    CMP.B #0,(\1)                 ; 0 -> done
    BEQ EXIT\@
    PRINT_CHAR (\1)+,\2
    JMP LOOP\@
EXIT\@
    ENDM
  
; send the contents of a data register to the serial port as a 8 digit hex number
; \1 = data register containing binary number, \2 = data register to use for status poll, \3 working data register, \4 counter register, \5 working address register, 
PRINT_REG MACRO
    MOVE.L #7,\4                ; loop round all 8 hex characters of 4 bits each
LOOP\@
    BIN2HEX \1,\3,\5
    PRINT_CHAR \3,\2
    DBEQ \4,LOOP\@
    ENDM
  
; read a char from the serial port
; \ 1= data register for read char, \2 = register to use for status poll
; will stamp on D0 and D1 in debug mode
READ_CHAR MACRO
WAIT_FOR_READY\@                  ; wait until the there is space to send

    IFEQ DEBUG
      MOVE.B DUART_SRA,\2         ; read status register
      BTST #0,\2                    ; check for character
      BEQ WAIT_FOR_READY\@          ; nothing, check again
    ENDC

    IFEQ DEBUG
      MOVE.B DUART_RXA,\1         ; got a character, read it
    ENDC
    IFNE DEBUG
      MOVE.L #5,D0    
      TRAP #15                    ; read from keyboard in simulator
      MOVE.L D1,\1
    ENDC
     
    CMP.B #$1B,\1                 ; check for escape and go to start
    BEQ START

    IFEQ DEBUG
      PRINT_CHAR \1,\2            ; echo it back
    ENDC
    ENDM

; register catalogue
; D0 - used for simulator I/O
; D1 - used for simulator I/O
; D3 - serial port status poll / task for TRAP in simulator
; D4 - read character
; D5 - data to write / data read
; D6 - working register used in R/W
; D7 - address accumulator
; A0 - address of string to print / address for R or W

; start vector
    ORG  $0
    DC.L $00000000              ; PC
    DC.L $00000000              ; SP
    
; start of program  
START
    MOVE.B #0,DISPLAY

; reset the UART in case of warm start
    MOVE.B #$A,DUART_CRA            ; disable rx & tx
    MOVE.B #$50,DUART_CRA           ; reset everyting
    NOP
    MOVE.B #$40,DUART_CRA           
    NOP
    MOVE.B #$30,DUART_CRA
    NOP
    MOVE.B #$20,DUART_CRA
    NOP
    MOVE.B #$10,DUART_CRA   

    MOVE.B #$A,DUART_CRB            ; disable rx & tx
    MOVE.B #$50,DUART_CRB           ; reset everyting
    NOP
    MOVE.B #$40,DUART_CRB           
    NOP
    MOVE.B #$30,DUART_CRB
    NOP
    MOVE.B #$20,DUART_CRB
    NOP
    MOVE.B #$10,DUART_CRB   

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

    PRINT_CHAR '.',D3               ; give the serial port chance to settle after reset

    MOVE.B #1,DISPLAY
       
    PRINT_CRLF D3

    LEA VERSION,A0
    PRINT_STR A0,D3
    PRINT_CRLF D3
    PRINT_CHAR #7,D3

    MOVE.L #0,D7                    ; address accumulator

    MOVE.B #2,DISPLAY
MAIN_LOOP
    PRINT_CHAR #'>',D3               ; prompt
    PRINT_CHAR #32,D3                ; space
    
GET_INPUT
    READ_CHAR D4,D3                  ; fetch character from serial port -> D4
    
    CMP.B #'0',D4
    BEQ HEX_DIGIT
    CMP.B #'1',D4
    BEQ HEX_DIGIT
    CMP.B #'2',D4
    BEQ HEX_DIGIT
    CMP.B #'3',D4
    BEQ HEX_DIGIT
    CMP.B #'4',D4
    BEQ HEX_DIGIT
    CMP.B #'5',D4
    BEQ HEX_DIGIT
    CMP.B #'6',D4
    BEQ HEX_DIGIT
    CMP.B #'7',D4
    BEQ HEX_DIGIT
    CMP.B #'8',D4
    BEQ HEX_DIGIT
    CMP.B #'9',D4
    BEQ HEX_DIGIT
    CMP.B #'A',D4
    BEQ HEX_DIGIT
    CMP.B #'B',D4
    BEQ HEX_DIGIT
    CMP.B #'C',D4
    BEQ HEX_DIGIT
    CMP.B #'D',D4
    BEQ HEX_DIGIT
    CMP.B #'E',D4
    BEQ HEX_DIGIT
    CMP.B #'F',D4
    BEQ HEX_DIGIT
    
    CMP.B #'W',D4
    BEQ W

    PRINT_CRLF D3
 
    CMP.B #'?',D4
    BEQ H

    CMP.B #'V',D4
    BEQ V
    
    CMP.B #'R',D4
    BEQ R

    CMP.B #'S',D4
    BEQ S

    CMP.B #'G',D4
    BEQ G   

    LEA HUH,A0
    PRINT_STR A0,D3
                       
    JMP MAIN_LOOP
    
; commands
H   LEA HELP,A0
    PRINT_STR A0,D3
    JMP MAIN_LOOP

V   LEA VERSION,A0
    PRINT_STR A0,D3       
    JMP MAIN_LOOP
    
R   
    MOVE.L D7,A0                    ; address accumulator -> address register
    MOVE.L (A0),D5                  ; read the memory and print it
    PRINT_REG D5,D3,D7,D6,A0
    PRINT_CRLF D3
    MOVE.L #0,D7                    ; clear the now used address accumulator
    JMP MAIN_LOOP

W   MOVE.L #0,D5                    ; D5 will be the value to write            

    READ_CHAR D4,D3                 ; read most significant character -> D4
    HEX2BIN D4,D4,A0                ; convert to binary -> D4
    MOVE.B D4,D5                    ; put at bottom of D5

    MOVE #6,D6                      ; 7 bytes left to read
    
READ_DATA
    LSL.L #4,D5                     ; make what we have so far more significant
    READ_CHAR D4,D3                 ; next character -> D4
    HEX2BIN D4,D4,A0                ; convert to binary -> D4
    OR.B D4,D5
    ANDI #$FB,CCR                   ; clear the Z bit if set (from the OR above)
    DBEQ D6,READ_DATA
    
    MOVE.L D7,A0                    ; address accumulator -> address register
    MOVE.L #0,D7                    ; clear the now used address accumulator
    
    MOVE.L D4,(A0)                  ; write the data

    PRINT_CRLF D3
    JMP MAIN_LOOP

S   READ_CHAR D4,D3                  ; fetch character from serial port -> D4
    JMP S

G   MOVE.L D7,A0                    ; address accumulator -> address register
    MOVE #0,D7                      ; clear the now used address accumulator
    JMP (A0)                        ; jump to it!
        
HEX_DIGIT
    LSL.L #4,D7                    ; add the next digit in the next 4 bits
    HEX2BIN D4,D4,A0
    OR.B D4,D7  
    JMP GET_INPUT

    SIMHALT                         ; halt simulator

; strings
VERSION DC.B 'MDF-mon V1.6 (31/03/2021)',13,10,0
HELP    DC.B '? Help',13,10,'V Version',13,10,'xxxxxxxxR Read long',13,10,'xxxxxxxxWxxxxxxxx Write long',13,10,'S download S records',13,10,'nnnnnnnnG Go',13,10,0
HUH     DC.B 'Huh?',13,10,0
UNIMP   DC.B 'Unimplemented',13,10,0
BIN2HEX_LUT DC.B '0123456789ABCDEF'
HEX2BIN_LUT DC.B 0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,$A,$B,$C,$D,$E,$F
    
    END    START                    ; last line of source








*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
