*-----------------------------------------------------------
* Title      : MDFmon 
* Written by : Mark Flitter
* Date       : March 2021
* Description: 68000 monitor program
*-----------------------------------------------------------
; to do
; Review for any other savings
; burn EEPROM to alternative location ($1000) and update the start vector as the very last operation
; if the EEPROM programming getas stuck, print out value read back and retry write eventually? 
; make the monitor relocatable, so it can run in RAM and ROM


; keep track of highest address hit during srec download
; implement backspace
; check for escape during Z and L?  Not sure if W is a good idea either
; fix being able to enter random chars when W'ing
; ram check at startup?  Not sure if this is a good idea!

    ORG  $0
    ;ORG  $200000

DEBUG               EQU 0

; constants
NULL                EQU 0
TAB                 EQU 9
CR                  EQU 13
LF                  EQU 10

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
    LEA HEX2BIN_LUT,\3                  		    ; load the lookup table
    SUB.B #'0',\1                       		    ; work out offset and mask off anything rogue
    AND.L #$FF,\1                       		    ; ignore the top 3 bytes
    MOVE.B 0(\3,\1),\2                  		    ; use that as an index into the LUT      
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
; \1 = data register to use for status poll, /2 = working address register
PRINT_CRLF MACRO
    LEA CRLF,\2
    PRINT_STR \2,\1
    ENDM

; send C-style, zero terminated string to the serial port
; \1 = address register containing address of zero terminated string, \2 = data register to use for status poll, 
PRINT_STR MACRO
LOOP\@
    CMP.B #NULL,(\1)                 			; 0 -> done
    BEQ EXIT\@
    PRINT_CHAR (\1)+,\2
    BRA LOOP\@
EXIT\@
    ENDM
  
; send the contents of a data register to the serial port as a 8 digit hex number
; \1 = data register containing binary number, \2 = data register to use for status poll, \3 working data register, \4 counter register, \5 working address register
PRINT_REG MACRO
    PRINT_CHAR #'0',\2          				    ;0x header
    PRINT_CHAR #'x',\2
    MOVE.L #7,\4                				    ; loop round all 8 hex characters of 4 bits each
LOOP\@
    BIN2HEX \1,\3,\5
    PRINT_CHAR \3,\2
    DBEQ \4,LOOP\@
    ENDM
    
; wait for a char from the serial port
; \ 1= data register for read char, \2 = register to use for status poll
; will stamp on D0 and D1 in debug mode
WAIT_CHAR MACRO
WAIT_FOR_READY\@                  			    ; wait until the there is space to send
    IFEQ DEBUG
        MOVE.B DUART_SRA,\2         			    ; read status register
        BTST #0,\2                    		    ; check for character
        BEQ WAIT_FOR_READY\@          		    ; nothing, check again
    ENDC
    
    READ_CHAR \1

    IFEQ DEBUG
        PRINT_CHAR \1,\2            			    ; echo it back
    ENDC
    ENDM
    
; read a char from the serial port - assumes that there is one!
; \ 1= data register for read char
; will stamp on D0 and D1 in debug mode
READ_CHAR MACRO
    IFEQ DEBUG
        MOVE.B DUART_RXA,\1         			    ; got a character, read it
    ENDC
    IFNE DEBUG
        MOVE.L #5,D0    
        TRAP #15                    			    ; read from keyboard in simulator
        MOVE.L D1,\1
    ENDC
     
    CMP.B #$1B,\1                 			    ; check for escape and go to start
    BEQ START
    ENDM
    
    
; read data from the download serial port
; \ 1= data register for read char
DOWNLOAD MACRO
WAIT_FOR_READY\@                  				; wait until the there is space to send

    MOVE.B DUART_SRA,\1           				; check for command
    BTST #0,\1                    				; check for character
    BEQ CONTINUE\@                				; nothing, continue
 
    READ_CHAR \1                                ; we're not going to do anything with it, just check for escape
CONTINUE\@
    MOVE.B DUART_SRB,\1         				    ; read download status register
    BTST #0,\1                  				    ; check for character
    BEQ WAIT_FOR_READY\@        				    ; nothing, check again
    
    MOVE.B DUART_RXB,\1         				    ; got a character, read it
    MOVE.B \1,DISPLAY           				    ; echo to the display
    
    ENDM
    
; read two hex digits from the download serial port and convert to a byte
; \1 result register, \2 = data register for read char, \3 = register to use for status poll, \4 = working data register, \5 = checksum register, \6 = working address register
DOWNLOAD_BYTE MACRO
    MOVE.B #2,\4
    WHILE.B \4 <GT> 0 DO
        LSL.L #4,\1                             ; it's OK to do this first, because we are either starting from 0, 
        DOWNLOAD \2                             ; or we are reading the next byte along, so need to shift up the previous one
        PRINT_CHAR \2,\3
        HEX2BIN \2,\2,\6
        OR.B \2,\1
        SUB.B #1,\4
    ENDW
    
    MOVE.L #0,\2                		            ; rextract latest byte of address and add into checksum
    MOVE.B \1,\2
    ADD.L \1,\5

    ENDM
    

; register catalogue
; D0 - used for simulator I/O
; D1 - used for simulator I/O
; D2 - read character
; D3 - serial port status poll / task for TRAP in simulator
; D6 - working register used in R/W
; D7 - address accumulator, reset by download
; A0 - address of string to print 

; start vector
STACK    DC.L $00000000              			; STACK
RESET    DC.L START                  			; RESET
    
; start of program  
START
    MOVE.B #0,DISPLAY

; reset the UART in case of warm start
    MOVE.B #$A,DUART_CRA            			    ; disable rx & tx
    MOVE.B #$50,DUART_CRA           			    ; reset everyting
    NOP
    MOVE.B #$40,DUART_CRA           
    NOP
    MOVE.B #$30,DUART_CRA
    NOP
    MOVE.B #$20,DUART_CRA
    NOP
    MOVE.B #$10,DUART_CRA   

    MOVE.B #$A,DUART_CRB            			    ; disable rx & tx
    MOVE.B #$50,DUART_CRB           			    ; reset everyting
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
    MOVE.B #$0,DUART_IMR            			    ; no interrupts, please            
    MOVE.B #$0,DUART_OPCR           			    ; enable all outputs

; channel A
    MOVE.B #$13,DUART_MRA           			    ; no flow control, no parity, 8 data bits
    MOVE.B #$07,DUART_MRA           			    ; 1 stop bit
    MOVE.B #$CC,DUART_CSRA          			    ; 9600 baud
    MOVE.B #$5,DUART_CRA            			    ; enable rx & tx

; channel B
    MOVE.B #$13,DUART_MRB           			    ; no flow control, no parity, 8 data bits
    MOVE.B #$07,DUART_MRB           			    ; 1 stop bit
    MOVE.B #$CC,DUART_CSRB          			    ; 9600 baud
    MOVE.B #$5,DUART_CRB            			    ; enable rx & tx

    PRINT_CHAR '.',D3               			    ; give the serial port chance to settle after reset

    MOVE.B #1,DISPLAY
       
    PRINT_CRLF D3,A0

    LEA VERSION,A0
    PRINT_STR A0,D3
    PRINT_CRLF D3,A0

    MOVE.L #0,D7                    			    ; address accumulator

    MOVE.B #2,DISPLAY
MAIN_LOOP
    PRINT_CHAR #'>',D3               		    ; prompt
    PRINT_CHAR #32,D3                		    ; space
    
GET_INPUT
    WAIT_CHAR D2,D3                  		    ; fetch character from serial port -> D2
    
    IF.B D2 <GE> #'0' AND.B D2 <LE> #'9' THEN
        BRA HEX_DIGIT
    ENDI
    IF.B D2 <GE> #'A' AND.B D2 <LE> #'F' THEN
        BRA HEX_DIGIT
    ENDI
        
    CMP.B #'w',D2
    BEQ W
    
    CMP.B #'l',D2
    BEQ L 

    PRINT_CRLF D3,A0
 
    CMP.B #'?',D2
    BEQ H

    CMP.B #'v',D2
    BEQ V
    
    CMP.B #'r',D2
    BEQ R

    CMP.B #'s',D2
    BEQ S

    CMP.B #'g',D2
    BEQ G   

    CMP.B #'z',D2
    BEQ Z   

    LEA HUH,A0
    PRINT_STR A0,D3
                       
    BRA MAIN_LOOP
    
; commands
H   
    LEA HELP,A0
    BRA PRINTSTR

V   
    LEA VERSION,A0
PRINTSTR
    PRINT_STR A0,D3       
    BRA MAIN_LOOP
    
R   
    MOVE.L D7,A0                    			    ; address accumulator -> address register
    MOVE.L (A0),D5                  			    ; read the memory and print it
    PRINT_REG D5,D3,D7,D6,A0
    PRINT_CRLF D3,A0
    MOVE.L #0,D7                    			    ; clear the now used address accumulator
    BRA MAIN_LOOP

W
    MOVE.L #0,D5                    			    ; D5 will be the value to write            

    MOVE #7,D6                      			    ; 7 bytes left to read
    
READ_DATA_TO_POKE
    LSL.L #4,D5                     			    ; make what we have so far more significant
    WAIT_CHAR D2,D3                 			    ; next character -> D2
    HEX2BIN D2,D2,A0                			    ; convert to binary -> D2
    OR.B D2,D5
    ANDI #$FB,CCR                   			    ; clear the Z bit if set (from the OR above)
    DBEQ D6,READ_DATA_TO_POKE
    
    MOVE.L D7,A0                    			    ; address accumulator -> address register
    MOVE.L #0,D7                    			    ; clear the now used address accumulator
    
    MOVE.L D5,(A0)                  			    ; write the data

    PRINT_CRLF D3,A0
    BRA MAIN_LOOP

; register map for S
; A0 - start address
; A1 - offset
; A2 - next address to write
; A3 - next location (jmp)
; A4 - Working Address Register
; D0 - record count
; D1 - 'S', record type, data byte
; D2 - checksum
; D3 - data byte count
; D4 - read address, moved into A2
; D5 - temp
; D6 - temp
; D7 - temp
S
    MOVE.L 0,A0                     			    ; start address -> A0
    MOVE.L D7,A1                    			    ; grab the address accumulator (offset) into A1
    
    MOVE.L #0,D0                    			    ; count of records read -> D0
        
WAIT_FOR_SRECORD                    			    ; wait for the start of a record, indicated by 'S'
    DOWNLOAD D1                 
    CMP.B #'S',D1                   			    ; found S?    
    BNE WAIT_FOR_SRECORD            			    ; nope, keep waiting
    
    PRINT_CHAR #'S',D5                          ; print the S
    ADD.L #1,D0                     			    ; read another S record, increment count
    
    DOWNLOAD D1                      			; read the record identifier and echo it back
    PRINT_CHAR D1,D5

    MOVE.L #0,D2                    			    ; clear the checksum

    MOVE.L #0,D3                    			    ; read the 2 digit byte count -> D3
    DOWNLOAD_BYTE D3,D5,D6,D7,D2,A4                                        

    IF.B D1 <EQ> #'0' THEN.L        			    ; header, just ignore it
        PRINT_CRLF D5,A4
        BRA WAIT_FOR_SRECORD
    ELSE
        IF.B D1 <EQ> #'1' OR.B D1 <EQ> #'2' THEN.L ; 16 or 24 bit address data record
            SUB.L #3,D3                 		    ; subtract three bytes for 16 bit address and 1 byte checksum
    
            MOVE.L #0,D4                		    ; read two bytes of address
            DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4     ; first byte                           
            DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4     ; second one
            
            IF.B D1 <EQ> #'2'  THEN.L           ; 24 bit address data record, read another byte
                SUB.L #1,D3                 	    ; subtract an extra bytes for 24 bit address    
                DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4 ; 3rd byte       
            ENDI
            
        	    MOVE.L D4,A2            	            ; put the address in an address register
			ADD.L A1,A2             		        ; add in the offset

            WHILE.L D3 <GT> #0 DO       		    ; read the data bytes                
                MOVE.L #0,D1            		    ; D1 holds the byte
                DOWNLOAD_BYTE D1,D5,D6,D7,D2,A4 ; read it                               
                        
                MOVE.B D1,(A2)+         		    ; store it!

                SUB.L #1,D3                     ; 1 less byte to go
            ENDW
        
            LEA WAIT_FOR_SRECORD,A3     	        ; next place to go
		ELSE
	        IF.B D1 <EQ> #'8' THEN.L    	        ; termination record, exit
				MOVE.L #0,D4              	    ; read the 24 bit start address
	            DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4 ; top byte	
			    DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4 ; middle byte	  
			    DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4 ; bottom byte
				  
				MOVE.L D4,A0              	    ; start address -> A0
				
				LEA DOWNLOAD_DONE,A3      	    ; next place to go
			ELSE
				PRINT_CRLF D5,A4
			
				LEA UNREC,A4              	    ; warn for unrecognised type
				PRINT_STR A4,D5
				PRINT_CHAR D1,D5
				PRINT_CRLF D5,A4
			
				BRA WAIT_FOR_SRECORD      	    ; ignore any other type    
			ENDI
		ENDI
	ENDI
    
    MOVE.L #0,D4                    			    ; read the checksum from the data stream add to our checksum: should make it FF
    DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4							
    PRINT_CRLF D5,A4
		
    IF.B D2 <NE> #$FF THEN.L
		LEA CS_FAILURE,A4             			; warn for mismatched checksum
		PRINT_STR A4,D5
		PRINT_REG D0,D5,D2,D6,A4
		PRINT_CRLF D5,A4
		BRA MAIN_LOOP
	ENDI
    
    JMP (A3)
DOWNLOAD_DONE
    PRINT_REG D0,D5,D6,D2,A1        			    ; print out number of Srecords read
    LEA READ,A1
    PRINT_STR A1,D5
    MOVE.L A0,D7                    			    ; set address accumulator to start address
    PRINT_REG D7,D5,D6,D2,A1        			    ; print out start address
    PRINT_CRLF D5,A4     
        
    BRA MAIN_LOOP
    
G
    MOVE.L D7,A0                    			    ; address accumulator -> address register
    MOVE #0,D7                      			    ; clear the now used address accumulator
    JMP (A0)                        			    ; jump to it!
    
Z
    MOVE.L #RAM,A0                  			    ; address of RAM
    
    FOR.L D0 = #0 TO #$40000 BY #4 DO             ; write
        	MOVE.L D0,D1                              ; progress update
		LSR.L #8,D1 
		LSR.L #8,D1
		MOVE.B D1,DISPLAY

		MOVE.L D0,(A0)+
    ENDF
 
    MOVE.L #RAM,A0              				      ; address of RAM
   
    FOR.L D0 = #0 TO #$40000 BY #4 DO               ; read back and check 
		MOVE.L D0,D1              				  ; progress update
		LSR.L #8,D1
		LSR.L #8,D1
		MOVE.B D1,DISPLAY

		MOVE.L (A0)+,D1
		  
		IF.L D0 <NE> D1 THEN	  
		    LEA RAM_ERROR,A1
		    PRINT_STR A1,D1
		    MOVE.L A0,D1
		    SUB.L #4,D1
		    PRINT_REG D1,D3,D2,D6,A1       			; print out failure address
		    PRINT_CRLF D3,A1
		ENDI 
    ENDF
    
    BRA MAIN_LOOP
  
L
    MOVE.L #0,D5                    			    ; D5 will be the length  to write            

    FOR D6 = #0 TO #3 DO                          ; read the length to write
        LSL.L #4,D5                     			; make what we have so far more significant
        WAIT_CHAR D2,D3                 			; next character -> D2
        HEX2BIN D2,D2,A0                			; convert to binary -> D2
        OR.B D2,D5
    ENDF
		  
    PRINT_CRLF D3,A0

    MOVE.L #ROM,A0                  			    ; start of ROM
    
    MOVE.L D7,A1                    			    ; address accumulator -> address register
    MOVE.L #0,D7                    			    ; clear the now used address accumulator
    
    MOVE.W #$AAAA,$2AAA
    MOVE.W #$5555,$1554
    MOVE.W #$8080,$2AAA
    MOVE.W #$AAAA,$2AAA
    MOVE.W #$5555,$1554
    MOVE.W #$2020,$2AAA
    
    LEA LOADING,A2                				; important for timing
    PRINT_STR A2,D3
    
    WHILE D5 <GT> #0 DO
		SUB.L #2,D5
		  
		MOVE.B (A1),DISPLAY
		MOVE.W (A1),(A0)            			    ; write the data
	  
WAIT_FOR_COMPLETE
		MOVE.W (A0),D2

		IF D2 <NE> (A1) THEN
			BRA WAIT_FOR_COMPLETE
		ENDI
      
		ADD.L #2,A0
		ADD.L #2,A1
	 ENDW    
    
    MOVE.W #$AAAA,$2AAA
    MOVE.W #$5555,$1554
    MOVE.W #$A0A0,$2AAA
            
    BRA MAIN_LOOP
        
HEX_DIGIT
    LSL.L #4,D7                    				; add the next digit in the next 4 bits
    HEX2BIN D2,D2,A0
    OR.B D2,D7  
    BRA GET_INPUT

    SIMHALT                         			    ; halt simulator

; strings
VERSION DC.B 'MDF-mon V1.52 (10/04/2021)',CR,LF,NULL
HELP    DC.B '?',TAB,TAB,TAB,'help',CR,LF
        DC.B '[v]',TAB,TAB,TAB,'version',CR,LF
        DC.B 'xxxxxxxx[r]',TAB,TAB,'read long',CR,LF
        DC.B 'xxxxxxxx[w]xxxxxxxx',TAB,'write long',CR,LF
        DC.B '[s]',TAB,TAB,TAB,'download S records',CR,LF
        DC.B 'xxxxxxxx[g]',TAB,TAB,'go',CR,LF
        DC.B '[z]',TAB,TAB,TAB,'zap memory',CR,LF
        DC.B 'xxxxxxxx[l]xxxx',TAB,TAB,'load to EEPROM',CR,LF,NULL
HUH     DC.B 'Huh?',CR,LF,NULL
READ    DC.B ' S records read, start address = ',NULL
UNREC   DC.B 'W: Unknown Srec type: ',NULL
CS_FAILURE   DC.B 'W: CS failure at ',NULL
RAM_ERROR DC.B 'W: RAM error at: ',NULL
BIN2HEX_LUT DC.B '0123456789ABCDEF'
HEX2BIN_LUT DC.B 0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,$A,$B,$C,$D,$E,$F
LOADING DC.B 'Loading EEPROM...',CR,LF,NULL
CRLF    DC.B CR,LF,NULL
    
    END    START                                ; last line of source







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
