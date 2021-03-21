*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $0
START:   
SP DC.L $FFFFFFFF          ; Stack pointer
PC DC.L $00000400          ; Program counter
   ORG $400
* Put program code here
   NOP
   MOVE.B #0,D0            ; first instruction
INC:
   NOP
   ADD.B D0,1
   NOP
   JMP INC
    
    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
