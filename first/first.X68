    ORG    $0
    DC.L $00000000
    DC.L $00000000 
START:                  ; first instruction of program
    MOVE.L #$FFFFFF,A0
    MOVE.L #9,D1
    MOVE.L #$0,D2
LOOP:
    MOVE.B D2,(A0)
    ADD.B #1,D2
    MOVE.L #$FFFFFFFF,D0
WAIT:
    NOP
    NOP
    NOP
    NOP
    NOP
    DBEQ D0,WAIT
    DBEQ D1,LOOP
    JMP START
    END    START        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
