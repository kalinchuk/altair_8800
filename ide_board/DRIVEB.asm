; This program displays a line of text on load.

BCTL    EQU     10H             ;SERIAL STATUS PORT
BDTA    EQU     11H             ;SERIAL DATA PORT

CR      EQU     0DH
LF      EQU     0AH

ORG 0H

INITIALIZE:
        MVI     A,3             ;RESET 6850 UART
        OUT     BCTL
        MVI     A,11H           ;8N2   
        OUT     BCTL
DISPLAY:
        LXI     H,OUTPUT
        CALL    SPEAK
	HLT

SPEAKOUT:
        XRA     A
SPXXX:  
	IN      BCTL
        ANI     2
        JNZ     SENDS
        DCR     A
        JNZ     SPXXX
        RET
SENDS:  
	MOV     A,C
        OUT     BDTA
        RET
SPEAK:  
	MOV     A,M
        CPI     '$'
        JZ      SPEAK1
        MOV     C,A
        CALL    SPEAKOUT
        INX     H
        JMP     SPEAK
SPEAK1: 
	MVI     C,0DH
        JMP     SPEAKOUT


OUTPUT:    	DB      'Loaded Drive B Data.',CR,LF,'$'