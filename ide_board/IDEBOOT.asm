BELL    EQU     07H
CR      EQU     0DH
LF      EQU     0AH

;-------------- Serial Board Port Assignments (88-2SIOJP)

BCTL            EQU     10H            ;SERIAL BOARD STATUS PORT       
BDTA            EQU     11H            ;SERIAL BOARD DATA PORT

;-------------- S100Computers IDE HARD DISK CONTROLLER COMMANDS ETC. 

BOOTADDRESS     EQU     0H              ;COPY DATA FROM DISK TO THIS LOCATION
SECCOUNT        EQU     12              ;10 - 512 byte sectors

IDEAport        EQU     030H            ;lower 8 bits of IDE interface
IDEBport        EQU     031H            ;upper 8 bits of IDE interface
IDECport        EQU     032H            ;control lines for IDE interface
IDECtrl         EQU     033H            ;8255 configuration port
IDEDrivePort    EQU     034H            ;To select the 1st or 2nd CF card/drive (Not used with this monitor)

IDEreset        EQU     80H             ;inverter between 8255 and IDE interface
IDEResetDelay   EQU     020H            ;Time delay for reset/initilization (~60 uS, with 10MHz Z80, 2 I/O wait states)
RDcfg8255       EQU     10010010B       ;Set 8255 IDECport out, IDEAport/B input
WRcfg8255       EQU     10000000B       ;Set all three 8255 ports output

IDEa0line       EQU     01H             ;direct from 8255 to IDE interface
IDEa1line       EQU     02H             ;direct from 8255 to IDE interface
IDEa2line       EQU     04H             ;direct from 8255 to IDE interface
IDEcs0line      EQU     08H             ;inverter between 8255 and IDE interface
IDEcs1line      EQU     10H             ;inverter between 8255 and IDE interface
IDEwrline       EQU     20H             ;inverter between 8255 and IDE interface
IDErdline       EQU     40H             ;inverter between 8255 and IDE interface

;
;Symbolic constants for the IDE Drive registers, which makes the
;code more readable than always specifying the address pins
;
REGdata         EQU     08H             ;IDEcs0line
REGerr          EQU     09H             ;IDEcs0line + IDEa0line
REGcnt          EQU     0AH             ;IDEcs0line + IDEa1line
REGsector       EQU     0BH             ;IDEcs0line + IDEa1line + IDEa0line
REGcyLSB        EQU     0CH             ;IDEcs0line + IDEa2line
REGcyMSB        EQU     0DH             ;IDEcs0line + IDEa2line + IDEa0line
REGshd          EQU     0EH             ;IDEcs0line + IDEa2line + IDEa1line             ;(0EH)
REGCMD          EQU     0FH             ;IDEcs0line + IDEa2line + IDEa1line + IDEa0line ;(0FH)
REGstatus       EQU     0FH             ;IDEcs0line + IDEa2line + IDEa1line + IDEa0line

;

DIAGLEDS       EQU     5               ;OUT (Will use this port initially for diagnostic LED display)

;IDE CMD Constants.  These shouMOV never change.
CMDrecal        EQU     10H
CMDread         EQU     20H
CMDwrite        EQU     30H
CMDinit         EQU     91H
CMDid           EQU     0ECH
CMDdownspin     EQU     0E0H
CMDupspin       EQU     0E1H

;BOOT UP THE 8255/IDE Board HARD DISK/Flash Memory Card

; Assume that this bootloader will be stored at memory location F000H
; Data is copied to 0H
; The SP (stack pointer) starts at location 7FF0H (and goes downwards)
; If the data to be copied is larger than ~7FF0H, increase
; The SP to a higher address (if possible). Keep in mind that
; this assumes a 64K RAM.
ORG 0F000H

INITIALIZE:
        LXI     SP, 7FF0H
        MVI     A,3             ;RESET 6850 UART
        OUT     BCTL
        MVI     A,11H           ;8N2   
        OUT     BCTL

; display option to select drive to boot

MENU:
        POP     H
        LXI     H,SPEAKMENU
        CALL    SPEAK
	
	CALL	GETCMD		;Character Input
	CPI     'A'
	JZ      SELECTDRIVE0
        CPI     'B'
	JZ      SELECTDRIVE1
        JMP     MENU

GETCMD:	IN	BCTL		;Get Character in [A]
	ANI	01H
	JZ	GETCMD
	IN	BDTA
	RET

SELECTDRIVE0:
	MVI    	A,0
	OUT	IDEDrivePort
	JMP	HBOOT

SELECTDRIVE1:
	MVI    	A,1
	OUT	IDEDrivePort
	JMP	HBOOT

HBOOT:
        POP     H                       ;CLEAN UP STACK
        LXI     H,LOADINGDRIVEMSG       ;Announce on speaker
        CALL    SPEAK
        
        CALL    INITILIZEIDEBOARD       ;Initilze the 8255 and drive (again just in case)
        JC      ERRNR                   ;Carry set to indicate an error, Drive not ready

        MVI     D,11100000B             ;Data for IDE SDH reg (512bytes, LBA mode,single drive)
        MVI     E,REGshd                ;00001110,(0EH) CS0,A2,A1,  
        CALL    IDEwr8D                 ;Write byte to select the MASTER device

        MVI     B,0FFH                  ;Delay time to allow a Hard Disk to get up to speed
WaitInit:       
        MVI     E,REGstatus             ;Get status after initilization
        CALL    IDErd8D                 ;Check Status (info in [D])
        MOV     A,D                     ;Z80 = BIT 7,D (A is not needed)
        ANI     80H
        JZ      SECREAD                 ;Zero, so all is OK to write to drive
                                        ;Delay to allow drive to get up to speed
        PUSH    B
        LXI     B,0FFFFH        
DXLAY2: MVI     D,2                     ;May need to adjust delay time to allow coMOV drive to
DXLAY1: DCR     D                       ;to speed
        JNZ     DXLAY1
        DCX     B
        MOV     A,C
        ORA     B
        JNZ     DXLAY2
        POP     B
        DCR     B
        JNZ     WaitInit                ;If after 0FFH, 0FEH, 0FDH... 0, then drive initilization problem
IDError:
        LXI     H,DRIVENRERR          ;Drive not ready
        JMP     ABORTERRMSG

SECREAD:                             
        MVI     A,11111111B             ;FLAG PROGRESS VISUALLY FOR DIAGNOSTIC
        OUT     DIAGLEDS

        CALL    IDEwaitnotbusy          ;Make sure drive is ready
        JC      IDError                 ;NC if ready

        MVI     D,0                     ;Load track 0,sec 0, head 0 ; CPM starts at sec 1
        MVI     E,REGsector             ;Send info to drive
        CALL    IDEwr8D

        MVI     D,0                     ;Send Low TRK#
        MVI     E,REGcyLSB
        CALL    IDEwr8D

        MVI     D,0                     ;Send High TRK#
        MVI     E,REGcyMSB
        CALL    IDEwr8D

        MVI     D,SECCOUNT              ;Count of sectors we wish to read
        MVI     E,REGcnt
        CALL    IDEwr8D

        MVI     D,CMDread               ;Send read CMD
        MVI     E,REGCMD
        CALL    IDEwr8D                 ;Send sec read CMD to drive.
        CALL    IDEwdrq                 ;Wait until it's got the data  

        LXI     H,BOOTADDRESS           ;DMA address where the copied data resides in RAM
        MVI     B,0                     ;256X2 bytes
        MVI     C,SECCOUNT              ;Count of sectors X 512
MoreRD16:
        MVI     A,REGdata               ;REG register address
        OUT     IDECport        

        ORI     IDErdline               ;08H+40H, Pulse RD line
        OUT     IDECport
        
        IN      IDEAport                ;read the LOWER byte
        MOV     M,A
        INX     H

        IN      IDEBport                ;read the UPPER byte
        MOV     M,A
        INX     H

        MVI     A,REGdata               ;Deassert RD line
        OUT     IDECport

        DCR     B
        JNZ     MoreRD16
        DCR     C
        JNZ     MoreRD16

        MVI     E,REGstatus             ;Check the R/W status when done
        CALL    IDErd8D
        MOV     A,D                     ;Z80 = Bit 0,D  (A is unused)
        ANI     01H
        JNZ     IDEerr1                 ;Z if no errors 
        JMP     BOOTADDRESS             ; Jump to boot address

IDEerr1:
        LXI     H,IDERWERROR            ;Drive R/W Error
        JMP     ABORTERRMSG


;      ----- SUPPORT ROUTINES --------------

INITILIZEIDEBOARD:                      ;Drive Select in [A]. Note leaves selected drive as [A]
        MVI     A,RDcfg8255             ;Config 8255 chip (10010010B), read mode on return
        OUT     IDECtrl                 ;Config 8255 chip, READ mode
                                
                                        ;Hard reset the disk drive 
                                        ;For some reason some CF cards need to the RESET line 
                                        ;pulsed very carefully. You may need to play around   
        MVI     A,IDEreset              ;with the pulse length. Symptoms are: incorrect data coming
        OUT     IDECport                ;back from a sector read (often due to the wrong sector being read)
                                        ;I have a (negative)pulse of 60 uSec. (10Mz Z80, two IO wait states).

        MVI     C,IDEResetDelay         ;~60 uS seems to work for the 5 different CF cards I have
ResetDelay:
        DCR     C
        JNZ     ResetDelay              ;Delay (reset pulse width)
        XRA     A
        OUT     IDECport                ;No IDE control lines asserted (just bit 7 of port C)
        
        CALL    DELAY15                 ;Need to delay a little before checking busy status

IDEwaitnotbusy:                         ;Drive READY if 01000000
        MVI     B,0FFH
        MVI     C,0FFH                  ;Delay, must be above 80H for 4MHz Z80. Leave longer for slower drives
MoreWait:
        MVI     E,REGstatus             ;Wait for RDY bit to be set
        CALL    IDErd8D
        MOV     A,D
        ANI     11000000B
        XRI     01000000B
        JZ      DoneNotbusy
        DCR     B       
        JNZ     MoreWait
        DCR     C
        JNZ     MoreWait
        STC                             ;Set carry to indicate an error
        RET
DoneNotBusy:
        ORA     A                       ;Clear carry it indicate no error
        RET      
                                        
                                        ;Wait for the drive to be ready to transfer data.
IDEwdrq:                                ;Returns the drive's status in Acc
        MVI     B,0FFH
        MVI     C,0FFH                  ;Delay, must be above 80H for 4MHz Z80. Leave longer for slower drives
MoreDRQ:
        MVI     E,REGstatus             ;wait for DRQ bit to be set
        CALL    IDErd8D
        MOV     A,D
        ANI     10001000B
        CPI     00001000B
        JZ      DoneDRQ
        DCR     B
        JNZ     MoreDRQ
        DCR     C
        JNZ     MoreDRQ
        STC                             ;Set carry to indicate error
        RET
DoneDRQ:
        ORA     A                       ;Clear carry
        RET
;
;------------------------------------------------------------------
; Low Level 8 bit R/W to the drive controller.  These are the routines that talk
; directly to the drive controller registers, via the 8255 chip.  
; Note the 16 bit I/O to the drive (which is only for SEC Read here) is done directly 
; in the routine MoreRD16 for speed reasons.

IDErd8D:                                ;READ 8 bits from IDE register in [E], return info in [D]
        MOV     A,E
        OUT     IDECport                ;drive address onto control lines

        ORI     IDErdline               ;RD pulse pin (40H)
        OUT     IDECport                ;assert read pin

        IN      IDEAport
        MOV     D,A                     ;return with data in [D]

        MOV     A,E                     ;Ken Robbins suggestion
        OUT     IDECport                ;Deassert RD pin

        XRA     A
        OUT     IDECport                ;Zero all port C lines
        RET


IDEwr8D:                                ;WRITE Data in [D] to IDE register in [E]
        MVI     A,WRcfg8255             ;Set 8255 to write mode
        OUT     IDECtrl

        MOV     A,D                     ;Get data put it in 8255 A port
        OUT     IDEAport

        MOV     A,E                     ;select IDE register
        OUT     IDECport

        ORI     IDEwrline               ;lower WR line
        OUT     IDECport

        MOV     A,E                     ;Kens Robbins suggestion, raise WR line
        OUT     IDECport

        XRA     A                       ;Deselect all lines including WR line
        OUT     IDECport

        MVI     A,RDcfg8255             ;Config 8255 chip, read mode on return
        OUT     IDECtrl
        RET
SPEAKOUT:
        XRA     A                       ;Will try 256 times, then timeout
SPXXX:  PUSH    PSW
        IN      BCTL                    ;(A0), Is SCC TX Buffer empty
        ANI     2
        JNZ     SENDS                   ;NZ if ready to recieve character
        POP     PSW
        DCR     A
        JNZ     SPXXX
        RET
SENDS:  POP     PSW
        MOV     A,C
        OUT     BDTA                    ;(A2), Send it
        RET

;SPEAKTOMM THIS IS A ROUTINE TO SEND A STRING TO TALKER [HL] AT STRING
SPEAK:  MOV     A,M
        CPI     '$'
        JZ      SPEAK1
        MOV     C,A
        CALL    SPEAKOUT
        INX     H
        JMP     SPEAK
SPEAK1: MVI     C,0DH                   ;MUST END WITH A CR
        JMP     SPEAKOUT
DELAY:  DCR     A                       ;GENERAL COUNT DOWN TIME DELAY
        RZ                              ;LENGTH SET IN [A]
        PUSH    PSW
        MVI     A,05H
MORE:   DCR     A
        PUSH    PSW
        XRA     A
MORE2:  DCR     A
        JNZ     MORE2
        POP     PSW
        JNZ     MORE
        POP     PSW
        JMP     DELAY

DELAY15:                                ;DELAY ~15 MS 
        MVI     A,40                    
DELAY1: MVI     B,0
M0:     DCR     B
        JNZ     M0
        DCR     A
        JNZ     DELAY1  
        RET
ERRNR:  LXI     H,DRIVENRERR            ;"DRIVE NOT READY
        JMP     ABORTERRMSG
ERRLD1:
        LXI     H,BOOTLD1ERR            ;"DATA ERROR IN BOOT SECTOR"
ABORTERRMSG:  
        CALL    SPEAK
        JMP     MENU                    ;BACK TO START 

SPEAKMENU:    	DB      'SELECT DRIVE (A or B):',CR,LF,'$'
LOADINGDRIVEMSG DB	'LOADING DRIVE...',CR,LF,LF,'$'
DRIVENRERR:     DB      BELL,CR,LF
                DB      'Drive not Ready.',CR,LF,LF,'$'
BOOTLD1ERR:     DB      BELL,CR,LF
                DB      'BOOT error.',CR,LF,LF,'$'
IDERWERROR:     DB      CR,LF
                DB      'IDE Drive R/W Error'
                DB      CR,LF,'$'