PORT0S    EQU     10H                   ;SERIAL 0 STATUS PORT
PORT0D    EQU     11H                   ;SERIAL 0 DATA PORT
PORT1S    EQU     12H                   ;SERIAL 1 STATUS PORT
PORT1D    EQU     13H                   ;SERIAL 1 DATA PORT
TBE       EQU     02H                   ;TRANSMIT BUFFER ENTRY FLAG
RDA       EQU     01H                   ;RECEIVE DATA AVAILABLE FLAG
TILDE     EQU     7EH                   ;USED TO DESIGNATE END OF RESPONSE
CR        EQU     0DH                   ;CARRIAGE RETURN
LF        EQU     0AH                   ;LINE FEED
BACKSPACE EQU     08H                   ;BACKSPACE KEY
SPACE     EQU     20H                   ;SPACE KEY

ORG 0H

INITIALIZE:
        MVI     A,3                     ;RESET 6850 UART
        OUT     PORT0S
        OUT     PORT1S
        MVI     A,11H                   ;8N2   
        OUT     PORT0S
        OUT     PORT1S

START:
        POP     H
        LXI     H,WELCOME
        CALL    SPEAK

BOOT:   POP     H
        LXI     H,PROMPT
        CALL    SPEAK

CNTLC:  IN      PORT0S
        ANI     RDA
        JZ      CNTLC
 
        IN      PORT0D
        MOV     B,A

PTLOP0: IN      PORT0S                  ;OUTPUT BACK TO PORT 0
        ANI     TBE
        JZ      PTLOP0
        MOV     A,B
        OUT     PORT0D

        CPI     BACKSPACE               ; CHECK IF CHARACTER IS BACKSPACE
        JNZ     PTLOP1

HANDLE_BACKSPACE0:
        IN      PORT0S
        ANI     TBE
        JZ      HANDLE_BACKSPACE0
        MVI     A, SPACE
        OUT     PORT0D

HANDLE_BACKSPACE1:
        IN      PORT0S
        ANI     TBE
        JZ      HANDLE_BACKSPACE1
        MVI     A, BACKSPACE
        OUT     PORT0D

PTLOP1: IN      PORT1S                  ;OUTPUT TO PORT 1
        ANI     TBE
        JZ      PTLOP1
        MOV     A,B
        OUT     PORT1D

        CPI     CR                      ;IF NOT SUBMITTED, LISTEN FOR MORE USER INPUT
        JNZ     CNTLC

LFSND:  IN      PORT1S                  ;SUBMITTED, PRINT SOME LF and CR
        ANI     TBE
        JZ      LFSND
        MVI     A, LF
        OUT     PORT1D

LFPRNT: IN      PORT0S
        ANI     TBE
        JZ      LFPRNT
        MVI     A, LF
        OUT     PORT0D

CRPRNT: IN      PORT0S
        ANI     TBE
        JZ      CRPRNT
        MVI     A, CR
        OUT     PORT0D

RESP:   IN      PORT1S                  ;LISTEN FOR RESPONSE
        ANI     RDA
        JZ      RESP

        IN      PORT1D
        CPI     TILDE                   ;IF TILDE (END), GO BACK TO PROMPT
        JZ      BOOT
        MOV     B,A

RESPREL: 
        IN      PORT0S                  ;IF NOT END, PRINT RESPONSE
        ANI     TBE
        JZ      RESPREL
        MOV     A,B
        OUT     PORT0D
        JMP     RESP

SPXXX:  PUSH    PSW
        IN      PORT0S
        ANI     2
        JNZ     SENDS
        POP     PSW
        DCR     A
        JNZ     SPXXX
        RET
SENDS:  POP     PSW
        MOV     A,C
        OUT     PORT0D
        RET

SPEAK:  MOV     A,M
        CPI     '$'
        JZ      ENDSPEAK
        MOV     C,A
        CALL    SPXXX
        INX     H
        JMP     SPEAK
ENDSPEAK:
        RET

WELCOME:     DB      CR,LF,'ChatGPT Assistant. Ask away!',CR,LF,LF,'$'
PROMPT:      DB      CR,LF,'>','$'
