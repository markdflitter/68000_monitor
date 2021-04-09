*-----------------------------------------------------------
* Title      : MDFmon 
* Written by : Mark Flitter
* Date       : March 2021
* Description: 68000 monitor program
*-----------------------------------------------------------
; to do
; remove the odd byte handling in the downloads
; implement DOWNLOAD_BYTE to remove repeated code and shorten the gap between S1 and S2
; stop using two registers in download
; lots of repeated code in download between the two S record types (S1 and S2)
; add simpler .W and .B variants of PRINT_REG, will reduce code a bit
; burn EEPROM to alternative location ($1000) and update the start vector as the very last operation
; if the EEPROM programming getas stuck, print out value read back and retry write eventually? 

; make the monitor relocatable, so it can run in RAM and ROM
; keep track of highest address hit during srec download
; fix the reset vector so that it jumps to the start
; Replace JMP -> BRA
; implement backspace
; check for escape during Z and L?  Not sure if W is a good idea either
; fix being able to enter random chars when W'ing
; ram check at startup?  Not sure if this is a good idea!

    ORG  $0
    ;ORG  $200000

DEBUG               EQU 0

; constants
ROM                 EQU $0
RAM                 EQU $200000
   
DUART_BASE          EQU $C00000
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

DISPLAY_BASE        EQU $E00000
DISPLAY_            EQU $0
DISPLAY             EQU DISPLAY_BASE+2*DISPLAY_+1

; macros
; convert top 4 bits of input register from binary to a single hex digit
; the input register is changed during the process
; \1 input data register containing binary number,  \2 data register for return value, \3 working address register
BIN2HEX MACRO
    LEA BIN2HEX_LUT,\3							; load the lookup table
    ROL.L #4,\1                       			; shift the top 4 bits down to bottom of the register the and mask off everything else
    MOVE.B \1,\2
    ANDI.L #$F,\2
    MOVE.B 0(\3,\2),\2                			; use that as an index into the LUT
    ENDM

; convert single hex digit to 4 bit binary number in LSbits
; the input register is changed during the process
; \1 data register containing hex character, \2 data register for return value, \3 working address register
HEX2BIN MACRO
    LEA HEX2BIN_LUT,\3                  		; load the lookup table
    SUB.B #'0',\1                       		; work out offset and mask off anything rogue
    AND.L #$FF,\1                       		; ignore the top 3 bytes
    MOVE.B 0(\3,\1),\2                  		; use that as an index into the LUT      
    ENDM

; send a single char to the serial port
; \1 = char to send, \2 = data register to use for status poll
; will stamp on D0 and D1 in debug mode
PRINT_CHAR MACRO
WAIT_FOR_READY\@                  				; wait until the there is space to send
    IFEQ DEBUG
        MOVE.B DUART_SRA,\2           			; read status register
        BTST #2,\2                    			; check for space to send
        BEQ WAIT_FOR_READY\@          			; no space, check again
        MOVE.B \1,DUART_TXA           			; send the next character
    ENDC
    
    IFNE DEBUG
        MOVE.B \1,D1
        MOVE.L #6,D0   
        TRAP #15                      			; write to terminal in simulator
    ENDC

    ENDM

; send CR,LF to the serial port
; \1 = data register to use for status poll
PRINT_CRLF MACRO
    PRINT_CHAR #13,\1             				; CR
    PRINT_CHAR #10,\1             				; LF
    ENDM

; send C-style, zero terminated string to the serial port
; \1 = address register containing address of zero terminated string, \2 = data register to use for status poll, 
PRINT_STR MACRO
LOOP\@
    CMP.B #0,(\1)                 				; 0 -> done
    BEQ EXIT\@
    PRINT_CHAR (\1)+,\2
    JMP LOOP\@
EXIT\@
    ENDM
  
; send the contents of a data register to the serial port as a 8 digit hex number
; \1 = data register containing binary number, \2 = data register to use for status poll, \3 working data register, \4 counter register, \5 working address register, 
PRINT_REG MACRO
    PRINT_CHAR #'0',\2          				;0x header
    PRINT_CHAR #'x',\2
    MOVE.L #7,\4                				; loop round all 8 hex characters of 4 bits each
LOOP\@
    BIN2HEX \1,\3,\5
    PRINT_CHAR \3,\2
    DBEQ \4,LOOP\@
    ENDM
  
; wait for a char from the serial port
; \ 1= data register for read char, \2 = register to use for status poll
; will stamp on D0 and D1 in debug mode
WAIT_CHAR MACRO
WAIT_FOR_READY\@                  				; wait until the there is space to send

    IFEQ DEBUG
        MOVE.B DUART_SRA,\2         			; read status register
        BTST #0,\2                    			; check for character
        BEQ WAIT_FOR_READY\@          			; nothing, check again
    ENDC
    
    READ_CHAR \1

    IFEQ DEBUG
        PRINT_CHAR \1,\2            			; echo it back
    ENDC
    ENDM
    
; read a char from the serial port - assumes that there is one!
; \ 1= data register for read char
; will stamp on D0 and D1 in debug mode
READ_CHAR MACRO
    IFEQ DEBUG
        MOVE.B DUART_RXA,\1         			; got a character, read it
    ENDC
    IFNE DEBUG
        MOVE.L #5,D0    
        TRAP #15                    			; read from keyboard in simulator
        MOVE.L D1,\1
    ENDC
     
    CMP.B #$1B,\1                 				; check for escape and go to start
    BEQ START
    ENDM
    
    
; read data from the download serial port
; \ 1= data register for read char, \2 = register to use for status poll
DOWNLOAD MACRO
WAIT_FOR_READY\@                  				; wait until the there is space to send

    MOVE.B DUART_SRA,\2           				; check for command
    BTST #0,\2                    				; check for character
    BEQ CONTINUE\@                				; nothing, continue
 
    READ_CHAR \1
CONTINUE\@
    MOVE.B DUART_SRB,\2         				; read status register
    BTST #0,\2                  				; check for character
    BEQ WAIT_FOR_READY\@        				; nothing, check again
    
    MOVE.B DUART_RXB,\1         				; got a character, read it
    MOVE.B \1,DISPLAY           				; echo to the display
    
    ENDM

; register catalogue
; D0 - used for simulator I/O
; D1 - used for simulator I/O
; D2 - read character
; D3 - serial port status poll / task for TRAP in simulator
; D4 - count of S records read
; D5 - data to write / data read / byte count for S record load
; D6 - working register used in R/W and download
; D7 - address accumulator / reset by download
; A0 - address of string to print 

; start vector
STACK    DC.L $00000000              			; STACK
RESET    DC.L START                  			; RESET
    
; start of program  
START
    MOVE.B #0,DISPLAY

; reset the UART in case of warm start
    MOVE.B #$A,DUART_CRA            			; disable rx & tx
    MOVE.B #$50,DUART_CRA           			; reset everyting
    NOP
    MOVE.B #$40,DUART_CRA           
    NOP
    MOVE.B #$30,DUART_CRA
    NOP
    MOVE.B #$20,DUART_CRA
    NOP
    MOVE.B #$10,DUART_CRA   

    MOVE.B #$A,DUART_CRB            			; disable rx & tx
    MOVE.B #$50,DUART_CRB           			; reset everyting
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
    MOVE.B #$0,DUART_IMR            			; no interrupts, please            
    MOVE.B #$0,DUART_OPCR           			; enable all outputs

; channel A
    MOVE.B #$13,DUART_MRA           			; no flow control, no parity, 8 data bits
    MOVE.B #$07,DUART_MRA           			; 1 stop bit
    MOVE.B #$CC,DUART_CSRA          			; 9600 baud
    MOVE.B #$5,DUART_CRA            			; enable rx & tx

; channel B
    MOVE.B #$13,DUART_MRB           			; no flow control, no parity, 8 data bits
    MOVE.B #$07,DUART_MRB           			; 1 stop bit
    MOVE.B #$CC,DUART_CSRB          			; 9600 baud
    MOVE.B #$5,DUART_CRB            			; enable rx & tx

    PRINT_CHAR '.',D3               			; give the serial port chance to settle after reset

    MOVE.B #1,DISPLAY
       
    PRINT_CRLF D3

    LEA VERSION,A0
    PRINT_STR A0,D3
    PRINT_CRLF D3
    PRINT_CHAR #7,D3

    MOVE.L #0,D7                    			; address accumulator

    MOVE.B #2,DISPLAY
MAIN_LOOP
    PRINT_CHAR #'>',D3               			; prompt
    PRINT_CHAR #32,D3                			; space
    
GET_INPUT
    WAIT_CHAR D2,D3                  			; fetch character from serial port -> D2
    
    CMP.B #'0',D2
    BEQ HEX_DIGIT
    CMP.B #'1',D2
    BEQ HEX_DIGIT
    CMP.B #'2',D2
    BEQ HEX_DIGIT
    CMP.B #'3',D2
    BEQ HEX_DIGIT
    CMP.B #'4',D2
    BEQ HEX_DIGIT
    CMP.B #'5',D2
    BEQ HEX_DIGIT
    CMP.B #'6',D2
    BEQ HEX_DIGIT
    CMP.B #'7',D2
    BEQ HEX_DIGIT
    CMP.B #'8',D2
    BEQ HEX_DIGIT
    CMP.B #'9',D2
    BEQ HEX_DIGIT
    CMP.B #'A',D2
    BEQ HEX_DIGIT
    CMP.B #'B',D2
    BEQ HEX_DIGIT
    CMP.B #'C',D2
    BEQ HEX_DIGIT
    CMP.B #'D',D2
    BEQ HEX_DIGIT
    CMP.B #'E',D2
    BEQ HEX_DIGIT
    CMP.B #'F',D2
    BEQ HEX_DIGIT
    
    CMP.B #'W',D2
    BEQ W
    
    CMP.B #'L',D2
    BEQ L 

    PRINT_CRLF D3
 
    CMP.B #'?',D2
    BEQ H

    CMP.B #'V',D2
    BEQ V
    
    CMP.B #'R',D2
    BEQ R

    CMP.B #'S',D2
    BEQ S

    CMP.B #'G',D2
    BEQ G   

    CMP.B #'Z',D2
    BEQ Z   

    LEA HUH,A0
    PRINT_STR A0,D3
                       
    JMP MAIN_LOOP
    
; commands
H   
    LEA HELP,A0
    PRINT_STR A0,D3
    JMP MAIN_LOOP

V   
    LEA VERSION,A0
    PRINT_STR A0,D3       
    JMP MAIN_LOOP
    
R   
    MOVE.L D7,A0                    			; address accumulator -> address register
    MOVE.L (A0),D5                  			; read the memory and print it
    PRINT_REG D5,D3,D7,D6,A0
    PRINT_CRLF D3
    MOVE.L #0,D7                    			; clear the now used address accumulator
    JMP MAIN_LOOP

W
    MOVE.L #0,D5                    			; D5 will be the value to write            

    WAIT_CHAR D2,D3                 			; read most significant character -> D2
    HEX2BIN D2,D2,A0                			; convert to binary -> D2
    MOVE.B D2,D5                    			; put at bottom of D5

    MOVE #6,D6                      			; 7 bytes left to read
    
READ_DATA_TO_POKE
    LSL.L #4,D5                     			; make what we have so far more significant
    WAIT_CHAR D2,D3                 			; next character -> D2
    HEX2BIN D2,D2,A0                			; convert to binary -> D2
    OR.B D2,D5
    ANDI #$FB,CCR                   			; clear the Z bit if set (from the OR above)
    DBEQ D6,READ_DATA_TO_POKE
    
    MOVE.L D7,A0                    			; address accumulator -> address register
    MOVE.L #0,D7                    			; clear the now used address accumulator
    
    MOVE.L D5,(A0)                  			; write the data

    PRINT_CRLF D3
    JMP MAIN_LOOP

        
S
    MOVE.L D7,A3                    			; grab the address accumulator
    MOVE.L #0,D4                    			; count of records read -> D4
    MOVE.L 0,A2                     			; start address -> A2
    
WAIT_FOR_SRECORD                    			; wait for the start of a record, indicated by 'S'
    DOWNLOAD D2,D3                  
    CMP.B #'S',D2                   			; found S?    
    BNE WAIT_FOR_SRECORD            			; nope, keep waiting
    
    ADD.L #1,D4                     			; read another S record, increment count
    
    DOWNLOAD D7,D3                  			; read the record digit

    MOVE.L #0,D6                    			; checksum

    MOVE.L #0,D5                    			; read the 2 digit byte count -> D5
    DOWNLOAD D2,D3              
    HEX2BIN D2,D2,A0
    OR.L D2,D5
    LSL.L #4,D5    
    DOWNLOAD D2,D3
    HEX2BIN D2,D2,A0  
    OR.L D2,D5
                
    ADD.L D5,D6                     			; add byte count into checksum

    IF.B D7 <EQ> #'0' THEN.L        			; header, just ignore it
        BRA WAIT_FOR_SRECORD
    ELSE
        IF.B D7 <EQ> #'1' THEN.L       		 	; 16 bit address data record
            MOVE.L #0,D7                		; read the 16 bit address, we'll stomp on D7 for this since it's sort of like the address accumulator
            DOWNLOAD D2,D3              		; top byte
            PRINT_CHAR D2,D3
            HEX2BIN D2,D2,A0
            OR.L D2,D7
            LSL.L #4,D7
            DOWNLOAD D2,D3         
            PRINT_CHAR D2,D3
            HEX2BIN D2,D2,A0
            OR.L D2,D7
        
            ADD.L D7,D6                 		; add top byte of address into checksum

            LSL.L #4,D7                 		; bottom byte
            DOWNLOAD D2,D3
            PRINT_CHAR D2,D3
            HEX2BIN D2,D2,A0
            OR.L D2,D7
            LSL.L #4,D7        
            DOWNLOAD D2,D3
            PRINT_CHAR D2,D3
            HEX2BIN D2,D2,A0
            OR.L D2,D7
        
            MOVE.L #0,D2                		; rextract bottom byte of address and add into checksum
            MOVE.B D7,D2
            ADD.L D2,D6
        
            ADD.L A3,D7                			; add in the offset
        
            SUB.L #3,D5                 		; subtract three bytes for 16 bit address and 1 byte checksum
        
            BTST #0,D7                  		; deal with odd addresses

            MOVE.L D7,A1                		; put the address in an address register, and we can now re-use D7
            BEQ EVEN
                
            SUB.L #1,D5
            SUB.L #1,A1
        
            MOVE.L #0,D7
            DOWNLOAD D2,D3            			; MS 4 bits
            PRINT_CHAR D2,D3
            HEX2BIN D2,D2,A0
            OR.L D2,D7
            LSL.L #4,D7
             
            DOWNLOAD D2,D3            			; LS 4 bits    
            PRINT_CHAR D2,D3
            HEX2BIN D2,D2,A0
            OR.L D2,D7
                        
            ADD.L D7,D6               			; add into checksum
                      
            MOVE.W (A1),D3            			; get the current data and replace the bottom byte
        
            ANDI.W #$FF00,D3
            OR.W D7,D3
        
            MOVE.W D3,(A1)           			; store it!
            ADD.L #2,A1
EVEN        
            WHILE.L D5 <GE> #2 DO       		; read the data bytes
                SUB.L #2,D5
                MOVE.L #0,D7            		; D7 holds the word
            
                DOWNLOAD D2,D3          		; MS 4 bits
                PRINT_CHAR D2,D3
                HEX2BIN D2,D2,A0
                OR.L D2,D7
                LSL.L #4,D7
             
                DOWNLOAD D2,D3          		; LS 4 bits    
                PRINT_CHAR D2,D3
                HEX2BIN D2,D2,A0
                OR.L D2,D7
                        
                ADD.L D7,D6             		; add into checksum
            
                LSL.L #4,D7
                DOWNLOAD D2,D3          		; MS 4 bits
                PRINT_CHAR D2,D3
                HEX2BIN D2,D2,A0
                OR.L D2,D7
             
                LSL.L #4,D7
                DOWNLOAD D2,D3          		; LS 4 bits    
                PRINT_CHAR D2,D3
                HEX2BIN D2,D2,A0
                OR.L D2,D7
            
                MOVE.L #0,D2            		; rextract bottom byte of address and add into checksum
                MOVE.B D7,D2
                ADD.L D2,D6
            
                MOVE.W D7,(A1)+         		; store it!
            ENDW
        
            IF D5 <EQ> #1 THEN
                MOVE.L #0,D7            		; D7 holds the word
                    
                DOWNLOAD D2,D3          		; MS 4 bits
                PRINT_CHAR D2,D3
                HEX2BIN D2,D2,A0
                OR.L D2,D7
            LSL.L #4,D7
             
            DOWNLOAD D2,D3            			; LS 4 bits    
            PRINT_CHAR D2,D3
            HEX2BIN D2,D2,A0
            OR.L D2,D7
                        
            ADD.L D7,D6               			; add into checksum
            
            MOVE.W (A1),D3            			; get the current data and replace the top byte
            LSL.L #8,D7
            AND.L #$00FF,D3
            OR.L D7,D3

            MOVE.W D3,(A1)+          			; store it!
        ENDI
  
        PRINT_CRLF D3
        LEA WAIT_FOR_SRECORD,A1     			; next place to go
      ELSE
			IF.B D7 <EQ> #'2' THEN.L    		; 24 bit address data record
				MOVE.L #0,D7            		; read the 24 bit address, we'll stomp on D7 for this since it's sort of like the address accumulator
				DOWNLOAD D2,D3          		; top byte
				PRINT_CHAR D2,D3
				HEX2BIN D2,D2,A0
				OR.L D2,D7
				LSL.L #4,D7
				DOWNLOAD D2,D3         
				PRINT_CHAR D2,D3
				HEX2BIN D2,D2,A0
				OR.L D2,D7
				
				ADD.L D7,D6             		; add top byte of address into checksum

				LSL.L #4,D7             		; middle byte
				DOWNLOAD D2,D3
				PRINT_CHAR D2,D3
				HEX2BIN D2,D2,A0
				OR.L D2,D7
				LSL.L #4,D7        
				DOWNLOAD D2,D3
				PRINT_CHAR D2,D3
				HEX2BIN D2,D2,A0
				OR.L D2,D7
				
				MOVE.L #0,D2            		; rextract middle byte of address and add into checksum
				MOVE.B D7,D2
				ADD.L D2,D6
          
				LSL.L #4,D7             		; bottom byte
				DOWNLOAD D2,D3
				PRINT_CHAR D2,D3
				HEX2BIN D2,D2,A0
				OR.L D2,D7
				LSL.L #4,D7        
				DOWNLOAD D2,D3
				PRINT_CHAR D2,D3
				HEX2BIN D2,D2,A0
				OR.L D2,D7
        
				MOVE.L #0,D2            		; rextract bottom byte of address and add into checksum
				MOVE.B D7,D2
				ADD.L D2,D6
				
				MOVE.L D7,A1            		; put the address in an address register, and we can now re-use D7
				ADD.L A3,A1             		; add in the offset
				  
				BTST #0,D7              		; deal with odd addresses

				MOVE.L D7,A1            		; put the address in an address register, and we can now re-use D7
				BEQ EVEN2
						
				SUB.L #1,D5
				SUB.L #1,A1
				
				MOVE.L #0,D7
				DOWNLOAD D2,D3          		; MS 4 bits
				PRINT_CHAR D2,D3
				HEX2BIN D2,D2,A0
				OR.L D2,D7
				LSL.L #4,D7
					 
				DOWNLOAD D2,D3          		; LS 4 bits    
				PRINT_CHAR D2,D3
				HEX2BIN D2,D2,A0
				OR.L D2,D7
                        
				ADD.L D7,D6             		; add into checksum
							  
				MOVE.W (A1),D3          		; get the current data and replace the bottom byte
				
				ANDI.W #$FF00,D3
				OR.W D7,D3
				
				MOVE.W D3,(A1)          		; store it!
				ADD.L #2,A1
EVEN2
				SUB.L #4,D5             		; subtract four bytes for 24 bit address and 1 byte checksum
				WHILE.L D5 <GE> #2 DO   		; read the data bytes
					SUB.L #2,D5
					
					MOVE.L #0,D7        		; D7 holds the word
					
					DOWNLOAD D2,D3      		; MS 4 bits
					PRINT_CHAR D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
					LSL.L #4,D7
					 
					DOWNLOAD D2,D3      		; LS 4 bits    
					PRINT_CHAR D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
                        
					ADD.L D7,D6        		 	; add into checksum
					
					LSL.L #4,D7
					DOWNLOAD D2,D3      		; MS 4 bits
					PRINT_CHAR D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
					 
					LSL.L #4,D7
					DOWNLOAD D2,D3      		; LS 4 bits    
					PRINT_CHAR D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
					
					MOVE.L #0,D2        		; rextract bottom byte of address and add into checksum
					MOVE.B D7,D2
					ADD.L D2,D6
					
					MOVE.W D7,(A1)+     		; store it!
            
				ENDW
            
				IF D5 <EQ> #1 THEN
					MOVE.L #0,D7        		; D7 holds the word
							
					DOWNLOAD D2,D3      		; MS 4 bits
					PRINT_CHAR D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
					LSL.L #4,D7
					 
					DOWNLOAD D2,D3      		; LS 4 bits    
					PRINT_CHAR D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
								
					ADD.L D7,D6         		; add into checksum
					
					MOVE.W (A1),D3      		; get the current data and replace the top byte
					LSL.L #8,D7
					AND.L #$00FF,D3
					OR.L D7,D3

					MOVE.W D3,(A1)+     		; store it!
				ENDI
				PRINT_CRLF D3
				LEA WAIT_FOR_SRECORD,A1 		; next place to go
			ELSE
				IF.B D7 <EQ> #'8' THEN.L    	; termination record, exit
					MOVE.L #0,D7              	; read the 24 bit address, we'll stomp on D7 for this since it's sort of like the address accumulator
					DOWNLOAD D2,D3            	; top byte
					HEX2BIN D2,D2,A0
					OR.L D2,D7
					LSL.L #4,D7
					DOWNLOAD D2,D3         
					HEX2BIN D2,D2,A0
					OR.L D2,D7
				
					ADD.L D7,D6               	; add top byte of address into checksum

					LSL.L #4,D7               	; middle byte
					DOWNLOAD D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
					LSL.L #4,D7        
					DOWNLOAD D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
        
					MOVE.L #0,D2              	; rextract middle byte of address and add into checksum
					MOVE.B D7,D2
					ADD.L D2,D6
				  
					LSL.L #4,D7               	; bottom byte
					DOWNLOAD D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
					LSL.L #4,D7        
					DOWNLOAD D2,D3
					HEX2BIN D2,D2,A0
					OR.L D2,D7
				
					MOVE.L #0,D2              	; rextract bottom byte of address and add into checksum
					MOVE.B D7,D2
					ADD.L D2,D6
				  
					MOVE.L D7,A2              	; start address -> A2
				
					LEA DOWNLOAD_DONE,A1      	; next place to go
				ELSE
					LEA UNREC,A0              	; warn for unrecognised type
					PRINT_STR A0,D3
					PRINT_CHAR D7,D3
					PRINT_CRLF D3
			
					JMP WAIT_FOR_SRECORD      	; ignore any other type    
				ENDI
			ENDI
		ENDI
    ENDI
    
    NOT.L D6                        			; ones complement the checksum
    ANDI.L #$FF,D6                  			; and take the LSByte
        
    MOVE.L #0,D7                    			; read the checksum from the data stream
    DOWNLOAD D2,D3                  			; top byte
    HEX2BIN D2,D2,A0
    OR.L D2,D7
    LSL.L #4,D7
    DOWNLOAD D2,D3                  			; bottom byte
    HEX2BIN D2,D2,A0
    OR.L D2,D7
                
    IF.B D7 <NE> D6 THEN.L
		LEA CS_FAILURE,A0             			; warn for mismatched checksum
		PRINT_STR A0,D3
		PRINT_REG D4,D3,D6,D7,A0
		PRINT_CRLF D3
		JMP MAIN_LOOP
	ENDI
    
    JMP (A1)
DOWNLOAD_DONE
    PRINT_REG D4,D3,D7,D6,A0        			; print out number of Srecords read
    LEA READ,A0
    PRINT_STR A0,D3
    MOVE.L A2,D7                    			; set address accumulator to start address
    PRINT_REG D7,D3,D2,D6,A0        			; print out start address
    PRINT_CRLF D3     
        
    JMP MAIN_LOOP
    
G
    MOVE.L D7,A0                    			; address accumulator -> address register
    MOVE #0,D7                      			; clear the now used address accumulator
    JMP (A0)                        			; jump to it!
    
Z
    MOVE.L #RAM,A0                  			; address of RAM
    MOVE.L #0,D0                    			; number of bytes
   
    WHILE.L D0 <LE> #$40000 DO      			; read the data bytes
       
		MOVE.L D0,D1                  			; progress update
		LSR.L #8,D1 
		LSR.L #8,D1
		ANDI.L #$F,D1
		MOVE.B D1,DISPLAY

		MOVE.L D0,(A0)+ 
		ADD.L #4,D0
    ENDW
 
    MOVE.L #RAM,A0              				; address of RAM
    MOVE.L #0,D0                				; number of bytes
   
    WHILE.L D0 <LE> #$40000 DO 					; read the data bytes

		MOVE.L D0,D1              				; progress update
		LSR.L #8,D1
		LSR.L #8,D1
		ANDI.L #$F,D1
		MOVE.B D1,DISPLAY

		MOVE.L (A0)+,D1
		  
		IF.L D0 <EQ> D1 THEN
			BRA OK
		ENDI 
		  
		LEA RAM_ERROR,A1
		PRINT_STR A1,D1
		MOVE.L A0,D1
		SUB.L #4,D1
		PRINT_REG D1,D3,D2,D6,A1       			; print out failure address
		PRINT_CRLF D3
OK    
		ADD.L #4,D0
    ENDW
    
    JMP MAIN_LOOP
  
L
    MOVE.L #0,D5                    			; D5 will be the length  to write            

    WAIT_CHAR D2,D3                				; read most significant character -> D2
    HEX2BIN D2,D2,A0                			; convert to binary -> D2
    MOVE.B D2,D5                    			; put at bottom of D5

    MOVE #2,D6                      			; 3 bytes left to read
    
READ_LENGTH
    LSL.L #4,D5                     			; make what we have so far more significant
    WAIT_CHAR D2,D3                 			; next character -> D2
    HEX2BIN D2,D2,A0                			; convert to binary -> D2
    OR.B D2,D5
    ANDI #$FB,CCR                   			; clear the Z bit if set (from the OR above)
    DBEQ D6,READ_LENGTH
        
    PRINT_CRLF D3

    MOVE.L #ROM,A0                  			; start of ROM
    
    MOVE.L D7,A1                    			; address accumulator -> address register
    MOVE.L #0,D7                    			; clear the now used address accumulator
    
    MOVE.L #$2AAA,A3
    MOVE.W #$AAAA,(A3)
    MOVE.L #$1554,A3
    MOVE.W #$5555,(A3)
    MOVE.L #$2AAA,A3
    MOVE.W #$8080,(A3)
    MOVE.L #$2AAA,A3
    MOVE.W #$AAAA,(A3)
    MOVE.L #$1554,A3
    MOVE.W #$5555,(A3)
    MOVE.L #$2AAA,A3
    MOVE.W #$2020,(A3)
    
    LEA LOADING,A2                				; important for timing
    PRINT_STR A2,D3

    ANDI #$FB,CCR                   			; clear the Z bit if set (from the OR above)
    
    WHILE D5 <GT> #0 DO
		SUB.L #2,D5
		  
		MOVE.B (A1),DISPLAY
		MOVE.W (A1),(A0)            			; write the data
	  
WAIT_FOR_COMPLETE
		MOVE.W (A0),D2

		IF D2 <NE> (A1) THEN
			JMP WAIT_FOR_COMPLETE
		ENDI
      
		ADD.L #2,A0
		ADD.L #2,A1
    ENDW  
    
    MOVE.L #$2AAA,A3
    MOVE.W #$AAAA,(A3)
    MOVE.L #$1554,A3
    MOVE.W #$5555,(A3)
    MOVE.L #$2AAA,A3
    MOVE.W #$A0A0,(A3)
            
    JMP MAIN_LOOP
        
HEX_DIGIT
    LSL.L #4,D7                    				; add the next digit in the next 4 bits
    HEX2BIN D2,D2,A0
    OR.B D2,D7  
    JMP GET_INPUT

    SIMHALT                         			; halt simulator

; strings
VERSION DC.B 'MDF-mon V1.36 (08/04/2021)',13,10,0
HELP    DC.B '? Help',13,10,'V Version',13,10,'xxxxxxxxR Read long',13,10,'xxxxxxxxWxxxxxxxx Write long',13,10,'S download S records',13,10,'xxxxxxxxG Go',13,10,'Z Zap memory',10,13,'xxxxxxxxLxxxx Load to EEPROM',10,13,0
HUH     DC.B 'Huh?',13,10,0
READ    DC.B ' S records read, start address = ',0
UNREC   DC.B 'W: Unknown Srec type: ',0
CS_FAILURE   DC.B 'W: CS failure at ',0
RAM_ERROR DC.B 'W: RAM error at: ',0
BIN2HEX_LUT DC.B '0123456789ABCDEF'
HEX2BIN_LUT DC.B 0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,$A,$B,$C,$D,$E,$F
LOADING  DC.B 'Loading EEPROM...',13,11,0
    
    END    START                    ; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
