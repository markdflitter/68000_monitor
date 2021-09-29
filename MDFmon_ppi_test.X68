*------------------------------------------------------------
* Title			MDFmon 
* Written by 	Mark Flitter
* Date			March 2021
* Description:	68000 monitor 

*-----------------------------------------------------------

; constants
NULL				EQU 0
TAB					EQU 9
CR					EQU 13
LF					EQU 10

ROM					EQU $0
STACK_ADDRESS		EQU $2E0000

MC68230_BASE		EQU $A00000
MC68230_GENERAL_CONTROL_	EQU $0
MC68230_SERVICE_REQUEST_ 	EQU $1
MC68230_PORT_A_DIRECTION_ 	EQU $2
MC68230_PORT_B_DIRECTION_ 	EQU $3
MC68230_PORT_C_DIRECTION_ 	EQU $4
MC68230_INTERRUPT_VECTOR_ 	EQU $5
MC68230_PORT_A_CONTROL_ 	EQU $6
MC68230_PORT_B_CONTROL_ 	EQU $7
MC68230_PORT_A_DATA_		EQU $8
MC68230_PORT_B_DATA_		EQU $9
MC68230_PORT_A_ALTERNATE_ 	EQU $A
MC68230_PORT_B_ALTERNATE_ 	EQU $B
MC68230_PORT_C_DATA_ 		EQU $C
MC68230_STATUS_				EQU $D

MC68230_GENERAL_CONTROL		EQU MC68230_BASE+2*MC68230_GENERAL_CONTROL_+1
MC68230_SERVICE_REQUEST		EQU MC68230_BASE+2*MC68230_SERVICE_REQUEST_+1
MC68230_PORT_A_DIRECTION 	EQU MC68230_BASE+2*MC68230_PORT_A_DIRECTION_+1
MC68230_PORT_B_DIRECTION 	EQU MC68230_BASE+2*MC68230_PORT_B_DIRECTION_+1
MC68230_PORT_C_DIRECTION 	EQU MC68230_BASE+2*MC68230_PORT_C_DIRECTION_+1
MC68230_PORT_DIRECTION_READ	EQU 0
MC68230_PORT_DIRECTION_WRITE EQU $FF

MC68230_INTERRUPT_VECTOR 	EQU MC68230_BASE+2*MC68230_INTERRUPT_VECTOR_+1
MC68230_PORT_A_CONTROL 		EQU MC68230_BASE+2*MC68230_PORT_A_CONTROL_+1
MC68230_PORT_B_CONTROL 		EQU MC68230_BASE+2*MC68230_PORT_B_CONTROL_+1
MC68230_PORT_A_DATA			EQU MC68230_BASE+2*MC68230_PORT_A_DATA_+1
MC68230_PORT_B_DATA			EQU MC68230_BASE+2*MC68230_PORT_B_DATA_+1
MC68230_PORT_A_ALTERNATE 	EQU MC68230_BASE+2*MC68230_PORT_A_ALTERNATE_+1
MC68230_PORT_B_ALTERNATE 	EQU MC68230_BASE+2*MC68230_PORT_B_ALTERNATE_+1
MC68230_PORT_C_DATA 		EQU MC68230_BASE+2*MC68230_PORT_C_DATA_+1
MC68230_PORT_C_READ      	EQU $20
MC68230_PORT_C_WRITE		EQU $10
MC68230_PORT_C_CS			EQU $08
MC68230_STATUS 				EQU MC68230_BASE+2*MC68230_STATUS_+1

MC68230_PORT_C_READ			EQU $20
MC68230_PORT_C_WRITE 		EQU $10
MC68230_PORT_C_CS			EQU $08

IDE_DATA_REGISTER			EQU 0
IDE_SECTOR_COUNT_REGISTER	EQU 2
IDE_LBA_0_7_REGISTER		EQU 3
IDE_LBA_8_15_REGISTER		EQU 4
IDE_LBA_16_23_REGISTER		EQU 5
IDE_DRIVESEL_REGISTER		EQU 6
IDE_DRIVESEL_MASTER			EQU $E0

IDE_COMMAND_REGISTER		EQU 7
IDE_COMMAND_READ_WITH_RETRY			EQU $20

IDE_STATUS_REGISTER			EQU 7
IDE_STATUS_BUSY				EQU 7
IDE_STATUS_READY			EQU 6
IDE_STATUS_DRQ				EQU 3

DUART_BASE			EQU $C00000
DUART_MRA_			EQU $0
DUART_CSRA_			EQU $1
DUART_SRA_			EQU $1
DUART_CRA_			EQU $2
DUART_TXA_			EQU $3
DUART_RXA_			EQU $3
DUART_ACR_			EQU $4
DUART_IMR_			EQU $5
DUART_CTUR_			EQU $6
DUART_CTLR_			EQU $7
DUART_MRB_			EQU $8
DUART_CSRB_			EQU $9
DUART_SRB_			EQU $9
DUART_CRB_			EQU $A
DUART_TXB_			EQU $B
DUART_RXB_			EQU $B
DUART_IVR_			EQU $C
DUART_OPCR_			EQU $D
DUART_SET_OPR_		EQU $E
DUART_RESET_OPR_	EQU $F

DUART_MRA			EQU DUART_BASE+2*DUART_MRA_+1
DUART_SRA			EQU DUART_BASE+2*DUART_SRA_+1
DUART_CSRA			EQU DUART_BASE+2*DUART_CSRA_+1
DUART_CRA			EQU DUART_BASE+2*DUART_CRA_+1
DUART_TXA			EQU DUART_BASE+2*DUART_TXA_+1
DUART_RXA			EQU DUART_BASE+2*DUART_RXA_+1

DUART_MRB			EQU DUART_BASE+2*DUART_MRB_+1
DUART_SRB			EQU DUART_BASE+2*DUART_SRB_+1
DUART_CSRB			EQU DUART_BASE+2*DUART_CSRB_+1
DUART_CRB			EQU DUART_BASE+2*DUART_CRB_+1
DUART_TXB			EQU DUART_BASE+2*DUART_TXB_+1
DUART_RXB			EQU DUART_BASE+2*DUART_RXB_+1

DUART_ACR			EQU DUART_BASE+2*DUART_ACR_+1
DUART_IMR			EQU DUART_BASE+2*DUART_IMR_+1
DUART_CTUR			EQU DUART_BASE+2*DUART_CTUR_+1
DUART_CTLR			EQU DUART_BASE+2*DUART_CTLR_+1
DUART_IVR			EQU DUART_BASE+2*DUART_IVR_+1
DUART_OPCR			EQU DUART_BASE+2*DUART_OPCR_+1
DUART_SET_OPR		EQU DUART_BASE+2*DUART_SET_OPR_+1
DUART_RESET_OPR		EQU DUART_BASE+2*DUART_RESET_OPR_+1

DISPLAY_BASE		EQU $E00000
DISPLAY_			EQU $0
DISPLAY				EQU DISPLAY_BASE+2*DISPLAY_+1

; macros
; convert top 4 bits of input register from binary to a single hex digit
; the input register is changed during the process
; \1 input data register containing binary number, \2 data register for return value, \3 working address register
BIN2HEX MACRO
	LEA BIN2HEX_LUT(PC),\3							; load the lookup table
	ROL.L #4,\1										; shift the top 4 bits down to bottom of the register the and mask off everything else
	MOVE.B \1,\2
	ANDI.L #$F,\2
	MOVE.B 0(\3,\2),\2								; use that as an index into the LUT
	ENDM

; convert single hex digit to 4 bit binary number in LSbits
; the input register is changed during the process
; \1 data register containing hex character, \2 data register for return value, \3 working address register
HEX2BIN MACRO
	LEA HEX2BIN_LUT(PC),\3							; load the lookup table
	SUB.B #'0',\1									; work out offset and mask off anything rogue
	AND.L #$FF,\1									; ignore the top 3 bytes
	MOVE.B 0(\3,\1),\2								; use that as an index into the LUT	  
	ENDM

; send a single char to the serial port
; \1 = char to send, \2 = data register to use for status poll
; will stamp on D0 and D1 in debug mode
PRINT_CHAR MACRO
WAIT_FOR_READY\@									; wait until the there is space to send
	MOVE.B DUART_SRA,\2							; read status register
	BTST #2,\2									; check for space to send
	BEQ WAIT_FOR_READY\@						; no space, check again
	MOVE.B \1,DUART_TXA							; send the next character

	ENDM

; send CR,LF to the serial port
; \1 = data register to use for status poll, /2 = working address register
PRINT_CRLF MACRO
	LEA CRLF(PC),\2
	PRINT_STR \2,\1
	ENDM

; send C-style, zero terminated string to the serial port
; \1 = address register containing address of zero terminated string, \2 = data register to use for status poll, 
PRINT_STR MACRO
LOOP\@
	CMP.B #NULL,(\1)								; 0 -> done
	BEQ EXIT\@
	PRINT_CHAR (\1)+,\2
	BRA LOOP\@
EXIT\@
	ENDM
  
; send the contents of a data register to the serial port as a 1 digit hex number
; \1 = data register containing binary number, \2 = data register to use for status poll, \3 working data register, \4 working address register
PRINT_REG_4BIT MACRO
	LEA BIN2HEX_LUT(PC),\4							; load the lookup table
	MOVE.B \1,\3
	ANDI.L #$F,\3
	MOVE.B 0(\4,\3),\3								; use that as an index into the LUT
	PRINT_CHAR \3,\2
	ENDM

; send the contents of a data register to the serial port as a 8 digit hex number
; \1 = data register containing binary number, \2 = data register to use for status poll, \3 working data register, \4 counter register, \5 working address register
PRINT_REG MACRO
	LEA ox(PC),\5
	PRINT_STR \5,\2
	MOVE.L #7,\4			 						; loop round all 8 hex characters of 4 bits each
LOOP\@
	BIN2HEX \1,\3,\5
	PRINT_CHAR \3,\2
	DBEQ \4,LOOP\@
	ENDM

; wait for a char from the serial port
; \ 1= data register for read char, \2 = register to use for status poll
; will stamp on D0 and D1 in debug mode
WAIT_CHAR MACRO
WAIT_FOR_READY\@									; wait until the there is space to send
	MOVE.B DUART_SRA,\2							; read status register
	BTST #0,\2						  			; check for character
	BEQ WAIT_FOR_READY\@			 			; nothing, check again

	READ_CHAR \1

	PRINT_CHAR \1,\2							; echo it back
	ENDM

; read a char from the serial port - assumes that there is one!
; \ 1= data register for read char
; will stamp on D0 and D1 in debug mode
READ_CHAR MACRO
	MOVE.B DUART_RXA,\1							; got a character, read it

	CMP.B #$1B,\1									; check for escape and go to start
	BEQ START
	ENDM


; read data from the download serial port
; \ 1= data register for read char
DOWNLOAD MACRO
WAIT_FOR_READY\@									; wait until the there is space to send

	MOVE.B DUART_SRA,\1								; read download status register
	BTST #0,\1										; check for character
	BEQ WAIT_FOR_READY\@							; nothing, check again
	
	MOVE.B DUART_RXA,\1								; got a character, read it
	
	CMP.B #$1B,\1									; check for escape and go to start
	BEQ START

	MOVE.B \1,DISPLAY								; echo to the display

	ENDM

; read an ide register
; \1 = register to read, \2 = data register for result, \3 = working data register 
READ_8 MACRO
	MOVE.B #MC68230_PORT_DIRECTION_READ, MC68230_PORT_B_DIRECTION
	MOVE.B #(MC68230_PORT_C_READ | MC68230_PORT_C_WRITE), \3
	ORI.B \1, \3
	MOVE.B \3, MC68230_PORT_C_DATA
	ANDI.B #~MC68230_PORT_C_READ, \3
	MOVE.B \3, MC68230_PORT_C_DATA
	MOVE.B MC68230_PORT_B_DATA, \2
	ORI.B #MC68230_PORT_C_READ, \3
	MOVE.B \3, MC68230_PORT_C_DATA
	MOVE.B #(MC68230_PORT_C_READ | MC68230_PORT_C_WRITE | MC68230_PORT_C_CS), MC68230_PORT_C_DATA
	ENDM
	
; write an ide register
; \1 = value to write, \2 = register to write, \3 = working data register 
WRITE_8 MACRO
	MOVE.B #MC68230_PORT_DIRECTION_WRITE, MC68230_PORT_B_DIRECTION
	MOVE.B #(MC68230_PORT_C_READ | MC68230_PORT_C_WRITE), \3
	ORI.B \2, \3
	MOVE.B \3, MC68230_PORT_C_DATA
	ANDI.B #~MC68230_PORT_C_WRITE, \3
	MOVE.B \1, MC68230_PORT_B_DATA
	MOVE.B \3, MC68230_PORT_C_DATA
	ORI.B #MC68230_PORT_C_WRITE, \3
	MOVE.B \3, MC68230_PORT_C_DATA
	MOVE.B #(MC68230_PORT_C_READ | MC68230_PORT_C_WRITE | MC68230_PORT_C_CS), MC68230_PORT_C_DATA
	ENDM

; read ide data
; \1 = register to read, \2 = data register for result, \3 = working data register 
READ_16 MACRO
	MOVE.B #MC68230_PORT_DIRECTION_READ, MC68230_PORT_B_DIRECTION
	MOVE.B #MC68230_PORT_DIRECTION_READ, MC68230_PORT_A_DIRECTION
	
	MOVE.B #(MC68230_PORT_C_READ | MC68230_PORT_C_WRITE), \3	
	ORI.B \1, \3
	MOVE.B \3, MC68230_PORT_C_DATA
	ANDI.B #~MC68230_PORT_C_READ, \3
	MOVE.B \3, MC68230_PORT_C_DATA
	MOVE.B MC68230_PORT_A_DATA, \2
	LSL.W #8, \2
	MOVE.B MC68230_PORT_B_DATA, \2
	ORI.B #MC68230_PORT_C_READ, \3
	MOVE.B \3, MC68230_PORT_C_DATA
	MOVE.B #(MC68230_PORT_C_READ | MC68230_PORT_C_WRITE | MC68230_PORT_C_CS), MC68230_PORT_C_DATA
	ENDM
	
; read ide data
; \1 = register to read, \2 = data register for result, \3 = working data register 
READ_32 MACRO
	READ_16 \1, \2, \3
	LSL.L #8, \2
	LSL.L #8, \2
	READ_16 \1, \2, \3
	ENDM
		
; read ide status
;\1 = data register for result, \2 = working data register 
READ_IDE_STATUS MACRO	
	READ_8 #IDE_STATUS_REGISTER, \1, \2
	ENDM
	
; wait for ide drive to be ready
;\1 = working data register 1, \2 = working data register 2
WAIT_DRIVE_READY MACRO
LOOP\@
	READ_IDE_STATUS \1, \2
	BTST #IDE_STATUS_READY, \1
	BEQ LOOP\@
	ENDM
	
; wait for ide drive to be not busy
;\1 = working data register 1, \2 = working data register 2
WAIT_DRIVE_NOT_BUSY MACRO
LOOP\@
	READ_IDE_STATUS \1, \2
	BTST #IDE_STATUS_BUSY, \1
	BNE LOOP\@
	ENDM
	
; wait for ide drive to have data for us
;\1 = working data register 1, \2 = working data register 2
WAIT_DRIVE_DRQ MACRO
LOOP\@
	READ_IDE_STATUS \1, \2
	BTST #IDE_STATUS_DRQ, \1
	BEQ LOOP\@
	ENDM
	
; prepare to send a read command
; \1 = block number, \2 = working data register 1, /3 = working data register 2, /4 = working data register 3
SET_READ_ADDRESS MACRO
	WRITE_8 #1, #IDE_SECTOR_COUNT_REGISTER, \2
	MOVE.L \1,\3
	WRITE_8 \3, #IDE_LBA_0_7_REGISTER, \2
	LSR.L #8, \3
	WRITE_8 \3, #IDE_LBA_8_15_REGISTER, \2
	LSR.L #8, \3								
	WRITE_8 \3, #IDE_LBA_16_23_REGISTER, \2
	LSR.L #8, \3
	READ_8 #IDE_DRIVESEL_REGISTER, \4, \2
	ANDI.B #$0F,\3
	OR.B \3,\4
	WRITE_8 \4, #IDE_DRIVESEL_REGISTER, \2
	ENDM

; send command
; \1 = command, \2 = working data register 1,
SEND_COMMAND MACRO
	WRITE_8 \1, #IDE_COMMAND_REGISTER, \2
	ENDM
	
; send read command and wait
; \1 = block to read, \2 = working data register 1, \2 = working data register 2, \2 = working data register 3
SEND_READ_COMMAND_AND_WAIT MACRO
	WAIT_DRIVE_NOT_BUSY \2, \3
	SET_READ_ADDRESS \1, \2, \3, \4
	SEND_COMMAND #IDE_COMMAND_READ_WITH_RETRY, \2
	WAIT_DRIVE_NOT_BUSY \2, \3
	WAIT_DRIVE_DRQ \2, \3
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
STACK	DC.L STACK_ADDRESS						; STACK
RESET	DC.L START								; RESET
VECS	DC.L UNHANDLED_HANDLER					; BUS ERROR
		DC.L UNHANDLED_HANDLER					; ADDRESS ERROR
		DC.L UNHANDLED_HANDLER					; ILLEGAL INSTRUCTION
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER 
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER 
		DC.L UNHANDLED_HANDLER 
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER 
		DC.L UNHANDLED_HANDLER 
		DC.L UNHANDLED_HANDLER 
		DC.L UNHANDLED_HANDLER
		DC.L UNHANDLED_HANDLER
; start of program
UNHANDLED_HANDLER	  
START
	MOVE.L #STACK_ADDRESS,A7
	MOVE.B #0,DISPLAY

	MOVE.L #0,D0
	MOVE.B DUART_IVR,D0								; warm start?

; reset the UART in case of warm start
	MOVE.B #$A,DUART_CRA							; disable rx & tx
	MOVE.B #$A,DUART_CRB							; disable rx & tx
	
	FOR D1 = #$50 DOWNTO #$10 BY #$10 DO
		MOVE.B D1,DUART_CRA							; reset everyting
		NOP
	ENDF

	FOR D1 = #$50 DOWNTO #$10 BY #$10 DO
		MOVE.B D1,DUART_CRB							; reset everyting
		NOP
	ENDF
	
;initialise UART
	MOVE.B #$0,DUART_IMR							; no interrupts, please
	MOVE.B #$FF,DUART_CTUR
	MOVE.B #$FF,DUART_CTLR
	MOVE.B #$70,DUART_ACR
	MOVE.B #$4,DUART_OPCR							; enable counter

; channel A
	MOVE.B #$13,DUART_MRA							; no flow control, no parity, 8 data bits
	MOVE.B #$07,DUART_MRA							; 1 stop bit
	MOVE.B #$66,DUART_CSRA							; 115K  baud
	MOVE.B #$5,DUART_CRA							; enable rx & tx

; channel B
	MOVE.B #$13,DUART_MRB			 				; no flow control, no parity, 8 data bits
	MOVE.B #$07,DUART_MRB							; 1 stop bit
	MOVE.B #$66,DUART_CSRB							; 115K baud
	MOVE.B #$5,DUART_CRB							; enable rx & tx
	MOVE.B #64,DUART_IVR

	PRINT_CHAR #0,D1								; some non-printing char to flush out the serial port
	PRINT_CHAR #0,D1
	PRINT_CHAR #0,D1
	
	IF D0 <EQ> #$0F THEN
		MOVE.B DUART_CRA,D0							; BRG test mode
	ENDI

	MOVE.B #1,DISPLAY

	MOVE.B #2,DISPLAY
	
	MOVE.B #$0, MC68230_GENERAL_CONTROL				; set up the MC68230
	MOVE.B #$40, MC68230_PORT_A_CONTROL
	MOVE.B #$40, MC68230_PORT_B_CONTROL
	MOVE.B #MC68230_PORT_DIRECTION_WRITE, MC68230_PORT_A_DIRECTION
	MOVE.B #MC68230_PORT_DIRECTION_WRITE, MC68230_PORT_B_DIRECTION
	MOVE.B #MC68230_PORT_DIRECTION_WRITE, MC68230_PORT_C_DIRECTION
	
	MOVE.B #3,DISPLAY
	
MAIN_LOOP
	FOR.L D0 = #0 TO #$FF DO
		PRINT_REG D0,D2,D3,D4,A0
		PRINT_CRLF D2,A0

		MOVE.B D0,DISPLAY

		MOVE.B D0, MC68230_PORT_A_DATA
		MOVE.B D0, MC68230_PORT_B_DATA
		MOVE.B D0, MC68230_PORT_C_DATA

		FOR.L D1 = #0 TO #$FFFF DO
			MOVE.L #0,D2
			MOVE.L #0,D2
			MOVE.L #0,D2
			MOVE.L #0,D2
		ENDF

	ENDF
	
	JMP START(PC)
; strings
HELPPROMPT DC.B 'Press ? for help',CR,LF,NULL
HELP	DC.B '[?]',TAB,TAB,TAB,'help',CR,LF
		DC.B '[v]',TAB,TAB,TAB,'version',CR,LF
		DC.B 'xxxxxxxx[r]',TAB,TAB,'read long',CR,LF
		DC.B 'xxxxxxxx[w]xxxxxxxx',TAB,'write long',CR,LF
		DC.B 'xxxxxxxx[s]',TAB,TAB,'download S records',CR,LF
		DC.B 'xxxxxxxx[g]',TAB,TAB,'go',CR,LF
		DC.B '[z]',TAB,TAB,TAB,'zap memory',CR,LF
		DC.B 'xxxxxxxx[l]xxxxxxxx',TAB,'load to EEPROM',CR,LF
		DC.B 'xxxxxxxx[p]xxxxxxxx',TAB,'patch EEPROM',CR,LF
		DC.B '#',TAB,TAB,TAB,'write protect EEPROM',CR,LF
		DC.B '[x]',TAB,TAB,TAB,'print registers',CR,LF
		DC.B '[I]',TAB,TAB,TAB,'enable interrupts',CR,LF
		DC.B '[o]',TAB,TAB,TAB,'disable interrupts',CR,LF
		DC.B '[i]',TAB,TAB,TAB,'index the disk',CR,LF
		DC.B 'xxxxxxxx[b]',TAB,TAB,'boot from disk',CR,LF,NULL
HUH	 DC.B 'Huh?',CR,LF,NULL
READ	DC.B ' S records read, start address = ',NULL
UNREC	DC.B 'W: Unknown Srec type: ',NULL
CS_FAILURE	DC.B '! CS failure at ',NULL
RAM_ERROR	DC.B '! RAM error at: ',NULL
BIN2HEX_LUT	DC.B '0123456789ABCDEF'
HEX2BIN_LUT	DC.B 0,1,2,3,4,5,6,7,8,9,0,0,0,0,0,0,0,$A,$B,$C,$D,$E,$F
LOADING	DC.B 'Loading EEPROM...',CR,LF,NULL
CRLF	DC.B CR,LF,NULL
PROMPT	DC.B '> ',NULL
ox		DC.B '0x',NULL
to		DC.B ' -> ',NULL
for		DC.B ' for ',NULL
STACK_POINTER DC.B 'SP: ',NULL
STATUS_REGISTER DC.B 'SR: ',NULL
INDEX_SEP DC.B ' : ',NULL
BOOT DC.B 'Booting',NULL
NOT_FOUND DC.B 'Not found',CR,LF,NULL
TICK DC.B 'tick',CR,LF,NULL
BUS_ERROR DC.B '* Bus/address error ',NULL
READING DC.B 'reading ',NULL
WRITING DC.B 'writing ',NULL
FROM DC.B ' from ',NULL
UNHANDLED DC.B '* Unhandled interrupt',NULL
UNINITIALISED DC.B '* Unitialised interrupt vector',NULL
SPURIOUS DC.B '* Spurious interrupt',NULL
VERSION DC.B 'MDF-mon V1.149 (01/06/2021)',CR,LF,NULL	; this is the last line on purpose, so if it prints, we can be sure we got it all
END		DC.B 0
	END	START				    						; last line of source


*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
