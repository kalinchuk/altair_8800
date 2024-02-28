; This program listens for data coming in over serial
; and then outputs any data that comes in back over serial.

CONS    EQU     10H             ;SERIAL STATUS PORT
COND    EQU     11H             ;SERIAL DATA PORT
TBE     EQU     2               ;TRANSMIT BUFFER ENTRY FLAG
RDA     EQU     1               ;RECEIVE DATA AVAILABLE FLAG

ORG 0H

; INITIALISE

        MVI     A,3             ;RESET 6850 UART
        OUT     CONS
        MVI     A,11H           ;8N2   
        OUT     CONS  

; BOOT PROMPT

BOOT    IN      CONS            ;WAIT FOR OK TO TRANSMIT
        ANI     TBE
        JZ      BOOT
        MVI     A,'>'           ;PRINT >
        OUT     COND            ;AND PRINT IT

; INPUT ROUTINE

CNTLC   IN      CONS            ;ANYTHING TYPED?
        ANI     RDA
        JZ      CNTLC           ;NO, LOOP WITH ZERO TRUE
 
        IN	COND		;GET TYPED CHARACTER
        MOV     B,A             ;SAVE DATA IN B

; OUTPUT ROUTINE

PTLOP   IN      CONS            ;WAIT FOR OK TO TRANSMIT
        ANI     TBE
        JZ      PTLOP
        MOV     A,B             ;RECOVER A
        OUT     COND            ;AND PRINT IT
	JMP     CNTLC
