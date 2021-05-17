*------------------------------------------------------------
* Title			MDFmon 
* Written by 	Mark Flitter
* Date			March 2021
* Description:	68000 monitor program
*-----------------------------------------------------------

	ORG  $0

DEBUG				EQU 0

; constants
NULL				EQU 0
TAB					EQU 9
CR					EQU 13
LF					EQU 10

ROM					EQU $0
RAM					EQU $200000
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
	IFEQ DEBUG
		MOVE.B DUART_SRA,\2							; read status register
		BTST #2,\2									; check for space to send
		BEQ WAIT_FOR_READY\@						; no space, check again
		MOVE.B \1,DUART_TXA							; send the next character
	ENDC

	IFNE DEBUG
		MOVE.B \1,D1
		MOVE.L #6,D0   
		TRAP #15									; write to terminal in simulator
	ENDC

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
	IFEQ DEBUG
		MOVE.B DUART_SRA,\2							; read status register
		BTST #0,\2						  			; check for character
		BEQ WAIT_FOR_READY\@			 			; nothing, check again
	ENDC

	READ_CHAR \1

	IFEQ DEBUG
		PRINT_CHAR \1,\2							; echo it back
	ENDC
	ENDM

; read a char from the serial port - assumes that there is one!
; \ 1= data register for read char
; will stamp on D0 and D1 in debug mode
READ_CHAR MACRO
	IFEQ DEBUG
		MOVE.B DUART_RXA,\1							; got a character, read it
	ENDC
	IFNE DEBUG
		MOVE.L #5,D0	
		TRAP #15									; read from keyboard in simulator
		MOVE.L D1,\1
	ENDC

	CMP.B #$1B,\1									; check for escape and go to start
	BEQ START
	ENDM


; read data from the download serial port
; \ 1= data register for read char
DOWNLOAD MACRO
WAIT_FOR_READY\@									; wait until the there is space to send

	MOVE.B DUART_SRA,\1								; check for command
	BTST #0,\1										; check for character
	BEQ CONTINUE\@									; nothing, continue

	READ_CHAR \1									; we're not going to do anything with it, just check for escape
CONTINUE\@
	MOVE.B DUART_SRB,\1								; read download status register
	BTST #0,\1										; check for character
	BEQ WAIT_FOR_READY\@							; nothing, check again
	
	MOVE.B DUART_RXB,\1								; got a character, read it
	MOVE.B \1,DISPLAY								; echo to the display

	ENDM

; unprotect the EEPROM
UNPROTECT MACRO
	MOVE.W #$AAAA,$2AAA								; remove write protect
	NOP
	MOVE.W #$5555,$1554
	NOP
	MOVE.W #$8080,$2AAA
	NOP
	MOVE.W #$AAAA,$2AAA
	NOP
	MOVE.W #$5555,$1554
	NOP
	MOVE.W #$2020,$2AAA
	ENDM
	
; protect the EEPROM
PROTECT MACRO
	MOVE.W #$AAAA,$2AAA								; and write protect
	MOVE.W #$5555,$1554
	MOVE.W #$A0A0,$2AAA
	ENDM


; read two hex digits from the download serial port and convert to a byte
; \1 result register, \2 = data register for read char, \3 = register to use for status poll, \4 = working data register, \5 = checksum register, \6 = working address register
DOWNLOAD_BYTE MACRO
	MOVE.B #2,\4
	WHILE.B \4 <GT> 0 DO
		LSL.L #4,\1									; it's OK to do this first, because we are either starting from 0, 
		DOWNLOAD \2									; or we are reading the next byte along, so need to shift up the previous one
		PRINT_CHAR \2,\3
		HEX2BIN \2,\2,\6
		OR.B \2,\1
		SUB.B #1,\4
	ENDW

	MOVE.L #0,\2									; rextract latest byte of address and add into checksum
	MOVE.B \1,\2
	ADD.L \1,\5

	ENDM

; write word to EEPROM
; \1 word to write, \2 = target address, \3 = working data register
PROGRAM MACRO
  MOVE.W \1,\2										; write the data

WAIT_FOR_COMPLETE\@
		MOVE.W \2,\3

		IF.W \3 <NE> \1 THEN
			BRA WAIT_FOR_COMPLETE\@
		ENDI
		ENDM
		
; program vector to EEPROM
; \1 handler address, \2 = target address, \3 = working data register
PROGRAM_VECTOR MACRO
	ADD.L #2,\2
	PROGRAM \1, (\2), \3							; write it
	LSR.L #8,\1
	LSR.L #8,\1
	SUB.L #2,\2
	PROGRAM \1, (\2), \3
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
VECS	DC.L BUS_ERROR_HANDLER					; BUS ERROR
		DC.L BUS_ERROR_HANDLER					; ADDRESS ERROR
		DC.L ILLEGAL_HANDLER					; ILLEGAL INSTRUCTION
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
		DC.L SPURIOUS_HANDLER
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
USER	DC.L TICK_HANDLER
	; start of program  
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
	
	PRINT_CRLF D1,A0
	LEA VERSION(PC),A0
	PRINT_STR A0,D3

	LEA END,A0
	MOVE.L A0,D0
	PRINT_REG D0,D1,D2,D3,A0
	PRINT_CRLF D1,A0

	LEA HELPPROMPT(PC),A0
	PRINT_STR A0,D3

	PRINT_CRLF D3,A0

	MOVE.L #0,D7									; address accumulator

	MOVE.B #2,DISPLAY
	
	MOVE.B #$0, MC68230_GENERAL_CONTROL				; set up the MC68230
	MOVE.B #$40, MC68230_PORT_A_CONTROL
	MOVE.B #$40, MC68230_PORT_B_CONTROL
	MOVE.B #MC68230_PORT_DIRECTION_WRITE, MC68230_PORT_C_DIRECTION
	
	MOVE.B #3,DISPLAY
	
	
MAIN_LOOP
	LEA PROMPT(PC),A0
	PRINT_STR A0,D3

GET_INPUT
	WAIT_CHAR D2,D3									; fetch character from serial port -> D2

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

	CMP.B #'p',D2
	BEQ P

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

	CMP.B #'x',D2
	BEQ X

	CMP.B #'i',D2
	BEQ I

	CMP.B #'o',D2
	BEQ O

	CMP.B #'#',D2
	BEQ HASH

	CMP.B #'b',D2
	BEQ B

	LEA HUH(PC),A0
	PRINT_STR A0,D3

	BRA MAIN_LOOP

; commands
H
	LEA HELP(PC),A0
	BRA PRINTIT

V
	LEA VERSION(PC),A0
PRINTIT
	PRINT_STR A0,D3	   
	BRA MAIN_LOOP

R
	MOVE.L D7,A0									; address accumulator -> address register
	MOVE.L #0,D7									;clear the now used address accumulator
	MOVE.L (A0),D2									; read the memory and print it
	PRINT_REG D2,D3,D4,D5,A0
	
	PRINT_CHAR #32,D3

	ROL.L #8,D2
	PRINT_CHAR D2,D3
	ROL.L #8,D2
	PRINT_CHAR D2,D3
	ROL.L #8,D2
	PRINT_CHAR D2,D3
	ROL.L #8,D2
	PRINT_CHAR D2,D3

	PRINT_CRLF D3,A0
	
	BRA MAIN_LOOP

W
	FOR D6 = #0 TO #7 DO								; read 4 bytes
		LSL.L #4,D5										; make what we have so far more significant
		WAIT_CHAR D2,D3									; next character -> D2
		HEX2BIN D2,D2,A0								; convert to binary -> D2
		OR.B D2,D5
	ENDF

	PRINT_CRLF D3,A0

	MOVE.L D7,A0									; address accumulator -> address register
	MOVE.L #0,D7									; clear the now used address accumulator

	MOVE.L D5,(A0)									; write the data

	BRA MAIN_LOOP

; register map for S
; A0 - start address
; A1 - offset
; A2 - next address to write
; A3 - next location (jmp)
; A4 - Working Address Register
; D0 - record count
; D1 - 'S', record type, data byte, done flag (0x00000000 = continue, 0xFFFFFFFF = done)
; D2 - checksum
; D3 - data byte count
; D4 - read address, moved into A2
; D5 - temp
; D6 - temp
; D7 - temp
S
	MOVE.L 0,A0										; start address -> A0
	MOVE.L D7,A1									; grab the address accumulator (offset) into A1
	
	MOVE.L #0,D0									; count of records read -> D0
		
WAIT_FOR_SRECORD									; wait for the start of a record, indicated by 'S'
	DOWNLOAD D1
	CMP.B #'S',D1									; found S?
	BNE WAIT_FOR_SRECORD							; nope, keep waiting
	
	PRINT_CHAR #'S',D5								; print the S
	ADD.L #1,D0										; read another S record, increment count
	
	DOWNLOAD D1										; read the record identifier and echo it back
	PRINT_CHAR D1,D5

	MOVE.L #0,D2									; clear the checksum

	DOWNLOAD_BYTE D3,D5,D6,D7,D2,A4

	IF.B D1 <EQ> #'0' THEN.L						; header, just ignore it
		PRINT_CRLF D5,A4
		BRA WAIT_FOR_SRECORD
	ELSE
		IF.B D1 <EQ> #'1' OR.B D1 <EQ> #'2' THEN.L	; 16 or 24 bit address data record
			SUB.L #3,D3								; subtract three bytes for 16 bit address and 1 byte checksum

			MOVE.L #0,D4							; read two bytes of address
			DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4			; first byte									
			DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4			; second one

			IF.B D1 <EQ> #'2'  THEN.L				; 24 bit address data record, read another byte
				SUB.L #1,D3							; subtract an extra bytes for 24 bit address	
				DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4		; 3rd byte
			ENDI

			MOVE.L D4,A2							; put the address in an address register
			ADD.L A1,A2								; add in the offset

			WHILE.B D3 <GT> #0 DO					; read the data bytes
				DOWNLOAD_BYTE D1,D5,D6,D7,D2,A4		; read it
 
				MOVE.B D1,(A2)+						; store it!

				SUB.B #1,D3							; 1 less byte to go
			ENDW

			MOVE.L #0,D1							; not done yet
		ELSE
			IF.B D1 <EQ> #'8' THEN.L				; termination record, exit
				MOVE.L #0,D4						; read the 24 bit start address
				DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4		; top byte
				DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4		; middle byte
				DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4		; bottom byte

				MOVE.L D4,A0						; start address -> A0
				ADD.L A1,A0							; add in the offset

				MOVE.L #$FFFFFFFF,D1				; done
			ELSE
				PRINT_CRLF D5,A4

				LEA UNREC(PC),A4					; warn for unrecognised type
				PRINT_STR A4,D5
				PRINT_CHAR D1,D5
				PRINT_CRLF D5,A4

				BRA WAIT_FOR_SRECORD				; ignore any other type	
			ENDI
		ENDI
	ENDI

	DOWNLOAD_BYTE D4,D5,D6,D7,D2,A4
	PRINT_CRLF D5,A4

	IF.B D2 <NE> #$FF THEN.L
		LEA CS_FAILURE(PC),A4						; warn for mismatched checksum
		PRINT_STR A4,D5
		PRINT_REG D0,D5,D3,D6,A4
		PRINT_CRLF D5,A4
		
		BRA MAIN_LOOP
	ENDI

	IF D1 <EQ> #0 THEN
	  BRA WAIT_FOR_SRECORD
	ENDI
DOWNLOAD_DONE
	PRINT_REG D0,D5,D6,D2,A1						; print out number of Srecords read
	LEA READ(PC),A1
	PRINT_STR A1,D5
	MOVE.L A0,D7									; set address accumulator to start address
	PRINT_REG D7,D5,D6,D2,A1						; print out start address
	PRINT_CRLF D5,A4

	BRA MAIN_LOOP

G
	MOVE.L D7,A0									; grab the address accumulator and then clear it
	MOVE.L #0,D7

	JMP (A0)
		
Z
	MOVE.L #RAM,A0									; address of RAM
	ADD.L #$100000,A0

	FOR.L D0 = #0 TO #$FFFFC BY #4 DO				; write
		MOVE.L D0,D1								; progress update
		LSR.L #8,D1 
		LSR.L #8,D1
		MOVE.B D1,DISPLAY
		
		MOVE.L A0,-(A0)
	ENDF

	MOVE.L #RAM,A0				 					; address of RAM
	ADD.L #$100000,A0

	FOR.L D0 = #0 TO #$FFFFC BY #4 DO				; read back and check 
		MOVE.L D0,D1				 				; progress update
		LSR.L #8,D1
		LSR.L #8,D1
		MOVE.B D1,DISPLAY

		MOVE.L A0,D2
		MOVE.L -(A0),D1

		IF.L D2 <NE> D1 THEN
			LEA RAM_ERROR(PC),A1
			PRINT_STR A1,D1
			MOVE.L A0,D1
			SUB.L #4,D1
			PRINT_REG D1,D3,D2,D6,A1				; print out failure address
			PRINT_CRLF D3,A1
		ENDI 
	ENDF

	BRA MAIN_LOOP

L
	MOVE.L #0,D0									; D0 will be the length to write			   
	MOVE.L #0,D1									; D1 will be the address to write 

	FOR D2 = #0 TO #7 DO							; read 4 bytes, we'll split into 2 byte address (MS) and 2 byte length (LS)
		LSL.L #4,D1									; make what we have so far more significant
		WAIT_CHAR D3,D4								; next character -> D2
		HEX2BIN D3,D3,A0							; convert to binary -> D2
		OR.B D3,D1
	ENDF

	MOVE.W D1,D0									; extract the LSword for the length	
	SUB.L #START,D0									; remove the vector table from the length
	LSR.L #8,D1										; extract the MSword for the address
	LSR.L #8,D1

	PRINT_CRLF D2,A1

	MOVE.L D1,A0									; target address
	MOVE.L D1,A3									; keep a copy for later

	MOVE.L D7,A1									; address accumulator -> address register
	ADD.L #START,A1									; skip the vectors
	MOVE.L D7,A4									; keep a clean copy for later
	MOVE.L #0,D7									; clear the now used address accumulator

	UNPROTECT										; important to only unprotect when we are fully committed (ie, can't escape)
					
	FOR D7 = #$0 TO #$FFFFFFFF DO					; dead timing loop to wait for unprotect
		NOP
	ENDF
				
	LEA LOADING(PC),A2
	PRINT_STR A2,D2
	LEA LOADING(PC),A2
	PRINT_STR A2,D2
		
	MOVE.L A1,D2
	PRINT_REG D2,D3,D4,D5,A2

	LEA TO(PC),A2
	PRINT_STR A2,D3

	MOVE.L A0,D2
	PRINT_REG D2,D3,D4,D5,A2

	LEA FOR(PC),A2
	PRINT_STR A2,D3
	PRINT_REG D0,D3,D4,D5,A2

	PRINT_CRLF D3,A2

	WHILE D0 <GT> #0 DO
		SUB.L #2,D0

		MOVE.B (A1),DISPLAY
		PROGRAM (A1),(A0),D2
				
		ADD.L #2,A0
		ADD.L #2,A1
	ENDW
	
	LEA STACK,A0
	ADD.L A4,A0
	MOVE.L (A0),D0
	
	MOVE.L #0,A0
	PROGRAM_VECTOR D0,A0,D2
	
	FOR A0 = #RESET TO #START-4 BY #4 DO

		MOVE.L A0,A1
		ADD.L A4,A1
			
		MOVE.L (A1),D0	
		ADD.L D1,D0
		SUB.L #START,D0

		MOVE.L A0,D2
		
		MOVE.L A0,D2
		MOVE.B D2,DISPLAY
		PROGRAM_VECTOR D0,A0,D2
	ENDF
										
	PROTECT

	BRA MAIN_LOOP
	
P
	MOVE.L #0,D0									; D0 will be the data to write

	FOR D1 = #0 TO #3 DO							; read 2 bytes
		LSL.L #4,D0									; make what we have so far more significant
		WAIT_CHAR D2,D3								; next character -> D2
		HEX2BIN D2,D2,A0							; convert to binary -> D2
		OR.B D2,D0
	ENDF

	PRINT_CRLF D2,A1

	MOVE.L D7,A0									; address accumulator -> target address register
	MOVE.L #0,D7									; clear the now used address accumulator

	UNPROTECT										; important to only unprotect when we are fully committed (ie, can't escape)
							
	FOR D7 = #$0 TO #$FFFFFFFF DO					; dead timing loop to wait for unprotect
		NOP
	ENDF
			 
	LEA LOADING(PC),A2								; the prints seem to be important for timing to unprotect the EEPROM
	PRINT_STR A2,D2

	PRINT_REG D0,D3,D4,D5,A2

	LEA TO(PC),A2
	PRINT_STR A2,D3

	MOVE.L A0,D2
	PRINT_REG D2,D3,D4,D5,A2

	PRINT_CRLF D3,A2

	PROGRAM D0,(A0),D2

	PROTECT

	BRA MAIN_LOOP
	
X
	LEA STATUS_REGISTER(PC),A2
	PRINT_STR A2,D3

	MOVE SR,D0
	PRINT_REG D0,D3,D4,D5,A2
	PRINT_CRLF D3,A2

	LEA STACK_POINTER(PC),A2
	PRINT_STR A2,D3

	MOVE.L SP,D0
	PRINT_REG D0,D3,D4,D5,A2
	PRINT_CRLF D3,A2

	BRA MAIN_LOOP
		
I
	MOVE.B #8,DUART_IMR
	AND.W #$F8FF,SR
	BRA MAIN_LOOP
	
O
	MOVE.B #0,DUART_IMR
	OR.W #$0700,SR
	BRA MAIN_LOOP
		
HASH
	PROTECT
	BRA MAIN_LOOP
	
B
	MOVE.B #(MC68230_PORT_C_READ | MC68230_PORT_C_WRITE | MC68230_PORT_C_CS), MC68230_PORT_C_DATA
	
	WRITE_8 #IDE_DRIVESEL_MASTER, #IDE_DRIVESEL_REGISTER, D0
	WAIT_DRIVE_READY D0, D1
	
	READ_8 #IDE_DRIVESEL_REGISTER, D0, D1
	
	MOVE.L #513,D3

	SEND_READ_COMMAND_AND_WAIT D3, D0, D1, D2		

	READ_32 #IDE_DATA_REGISTER, D4, D1		; start -> D4
	PRINT_REG D4,D0,D1,D6,A2
	PRINT_CRLF D6,A2

	READ_32 #IDE_DATA_REGISTER, D5, D1		; end -> D5
	PRINT_REG D5,D0,D1,D6,A2
	PRINT_CRLF D6,A2

	READ_32 #IDE_DATA_REGISTER, D7, D1		; read entry point into address accumulator
	PRINT_REG D7,D0,D1,D6,A2
	PRINT_CRLF D6,A2

	PRINT_CHAR #'*',D0
	MOVE.L D4, A0
	FOR D6 = #6 TO #255 DO
		READ_16 #IDE_DATA_REGISTER, D0, D1
		MOVE.W D0,(A0)+
	ENDF
	MOVE.L A0,D4
	ADD.L #1,D3
	
	WHILE D4 <LT> D5 DO
		SEND_READ_COMMAND_AND_WAIT D3, D0, D1, D2

		PRINT_CHAR #'*', D1
		MOVE.L D4, A0
		FOR D6 = #$0 TO #255 DO
			READ_16 #IDE_DATA_REGISTER, D0,D1
			MOVE.W D0,(A0)+
		ENDF
		MOVE.L A0, D4		
		ADD.L #1,D3
	ENDW

	PRINT_CRLF D3,A3
	
	BRA MAIN_LOOP

HEX_DIGIT
	LSL.L #4,D7											; add the next digit in the next 4 bits
	HEX2BIN D2,D2,A0
	OR.B D2,D7  
	BRA GET_INPUT

; exceptions	
BUS_ERROR_HANDLER

	LEA BUS_ERROR(PC),A0
	PRINT_STR A0,D1

	MOVE.L #0,D0
	MOVE.W (SP),D0

	BTST #4,D0
	BEQ WRITE
	
	LEA READING(PC),A0
	PRINT_STR A0,D1

	BRA CONTINUE	
WRITE
	LEA WRITING(PC),A0
	PRINT_STR A0,D1

CONTINUE
	MOVE.L 2(SP),D1
	PRINT_REG D1,D2,D3,D4,A0

	LEA FROM(PC),A0
	PRINT_STR A0,D0

	MOVE.L 10(SP),D1
	PRINT_REG D1,D2,D3,D4,A0
	PRINT_CRLF D0,A0
	
	MOVE.L #4,A0
	JMP (A0)
		
ILLEGAL_HANDLER
	MOVE.B #7,DISPLAY	
	
	MOVE.L #4,A0
	JMP (A0)
		
UNHANDLED_HANDLER
	LEA UNHANDLED(PC),A0
	JMP PRINTIT_RTE
	
UNINITIALISED_HANDLER
	LEA UNINITIALISED(PC),A0
	JMP PRINTIT_RTE

TICK_HANDLER
	MOVE.B DUART_RESET_OPR,D0
	LEA TICK(PC),A0
	JMP PRINTIT_RTE

SPURIOUS_HANDLER
	LEA SPURIOUS(PC),A0
PRINTIT_RTE
	PRINT_STR A0,D1
	RTE	
	
	SIMHALT												; halt simulator

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
		DC.B '[i]',TAB,TAB,TAB,'enable interrupts',CR,LF
		DC.B '[o]',TAB,TAB,TAB,'disable interrupts',CR,LF
		DC.B '[b]',TAB,TAB,TAB,'boot from disk',CR,LF,NULL
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
TICK DC.B 'tick',CR,LF,NULL
BUS_ERROR DC.B '* Bus/address error ',NULL
READING DC.B 'reading ',NULL
WRITING DC.B 'writing ',NULL
FROM DC.B ' from ',NULL
UNHANDLED DC.B '* Unhandled interrupt',NULL
UNINITIALISED DC.B '*  Unitialised interrupt vector',NULL
SPURIOUS DC.B '* Spurious interrupt',NULL
VERSION DC.B 'MDF-mon V1.135 (17/05/2021)',CR,LF,NULL	; this is the last line on purpose, so if it prints, we can be sure we got it all
END		DC.B 0
	END	START				    						; last line of source















*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
