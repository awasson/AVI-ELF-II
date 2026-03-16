	.define	PRINT	 sep r4	\	.dw PRINT_SUB
	.define	PRINTB	 sep r4	\	.dw PRINTB_SUB
	.define	PUT_CHAR sep r4	\	.dw PUT_CHAR_SUB
	.define	PUT_BYTE sep r4	\	.dw PUT_BYTE_SUB
	.define	PUT32_RA sep r4	\	.dw PUT32_RA_SUB
	.define	LDI_RA   sep r4	\	.dw LDI_RA_SUB	\	.dw 
	.define	LDI_RB   sep r4	\	.dw LDI_RB_SUB	\	.dw 
	.define	LDI_RC   sep r4	\	.dw LDI_RC_SUB	\	.dw 
	.define	LDI_RD   sep r4	\	.dw LDI_RD_SUB	\	.dw 
	.define	LDI_RE   sep r4	\	.dw LDI_RE_SUB	\	.dw 
	.define	LD_RA    sep r4	\	.dw LD_RA_SUB	\	.dw 
	.define	LD_RB    sep r4	\	.dw LD_RB_SUB	\	.dw 
	.define	LD_RC    sep r4	\	.dw LD_RC_SUB	\	.dw 
	.define	LD_RD    sep r4	\	.dw LD_RD_SUB	\	.dw 
	.define	ST_RA    sep r4	\	.dw ST_RA_SUB	\	.dw 
	.define	ST_RB    sep r4	\	.dw ST_RB_SUB	\	.dw 
	.define	ST_RC    sep r4	\	.dw ST_RC_SUB	\	.dw 
	.define	ST_RD    sep r4	\	.dw ST_RD_SUB	\	.dw 
	.define	CLR32_RA sep r4	\	.dw CLR32_RA_SUB
	.define	CLR32_RB sep r4	\	.dw CLR32_RB_SUB
	.define	CLR32_RE sep r4	\	.dw CLR32_RE_SUB
	.define	LDI32_RA sep r4	\	.dw LDI32_RA_SUB \	.dw 
	.define	LDI32_RB sep r4	\	.dw LDI32_RB_SUB \	.dw 
	.define STD	 sep r4 \	.dw STD_SUB	 \	.dw 
	.define LDD	 sep r4 \	.dw LDD_SUB	 \	.dw 
	.define ADD_RA_RB sep r4 \	.dw ADD_RA_RB_SUB
	.define	RX_CHAR	sep r4	\	.dw RXCHAR_SUB


;AVI ELF II, VIP Personality ROM, SD Card Reader
;Josh Bensadon
;Jan 9, 2024
;
;The AVI ELF II is Ed Keefe's reproduction of the Netronics ELF II computer.
;It looks very similar to the orginal, but offers 32K of RAM and elevated 
;Keyboard & Display boards.
;
;This ROM can make use of a VIP Keypad Personality module to run the ELF II
;as a RCA VIP.
;
;The SD Card Reader will map this ROM at 0000 after RESET for boot.  
;
;During Boot:
;0000-7FFF 32K ROM
;8000-BFFF 16K MAIN RAM WINDOW (Bank switched for 64K)
;C000-FFFE 16K BOOT RAM
;FFFF-FFFF SD Card memory mapped

;RAM (Main board RAM)
;8000-BFFF 16K of 64K BIG_RAM on SD Card Reader, four banks of 16K
;
;ROM will either load a file from the SD Card to the 64K BIG_RAM or
;load the BIG_RAM with VIP system at 8000 (optionally with CHIP-8).
;
;When MAIN_RAM is loaded, the BOOT process will end with the remap the MAIN_RAM
;to the full 64K space and execute at a selected location.
;
;This ROM code will first send a serial message through Q to say "Hi"
;Next it will test if the VIP Keypad is present.
;If Keypad is present, a check if "C" is pressed, if so, VIP software will
;be loaded and ran (this emulates a VIP)
;
;ROM will serve as a serial monitor and will display files from the SD Card
;Files will be displayed on screen through the Pixie chip.
;The VIP Keypad will be used as input to select SD Card files.
;If the VIP keypad is not available, then it will use the ELF II keypad.
;To make ELF II keypad work on single key strokes (like the VIP Keypad), the
;data available line from the 74C923 will be monitored by EF3.
;
;
;Command prompt:
;DIR - Directory
;I - Initialize FAT, read root directory
;B - Select BOOT RAM
;M - Select MAIN RAM
;S - Sector Read.  S [####]  Use 4 digit hex number for Sector to read.
;    Sector is loaded into RAM Buffer at C000.  Each sector is 512 bytes
;    If you ommit number, the next sector will be read.
;D - Dumps RAM in binary format.  D [####] [/S]
;    Reads which ever RAM is selected (BOOT or MAIN)
;    When reading BOOT, the /S will read the Shadow RAM in place of ROM (lower 32K)
;E - Edit / Write to RAM.  E [####].  Writes to selected BOOT or MAIN ram.
;    Any writes to BOOT under 32K will go to the Shadow RAM.
;X - Execute program in MAIN, BOOT or SHADOW RAM.  X [####] [/R/S]
;    It will default to the start address of a HEX file or allow a manually entered address.
;    Switch /R will select BOOT RAM space.  /R/S will select the SHADOW RAM (lower 32K)
;CD- Change Directory.  CD [dirname]
;    Use CD .. to go to parrent directoy
;    Use CD \  for root directory
;V - View File on the SD Card.  V filename [/A | /H | /B]
;    File is understood to be ASCII if the extension is .TXT, Intel HEX if .HEX or just
;    Binary if .BIN or alternately B## where ## is a valid 2 digit hex page.
;    /A will override the extension and force an ASCII dump
;    /H will override with HEX (just the same as ASCII)
;    /B will override with Binary
;L - Load File on the SD Card.  L filename [####] [/A | /H | /B] [/R]
;    /A, /H, /B will override the file type
;    ASCII or BINARY files will load at ####.
;    Binary files with the extension B## will load at page ##
;    eg. L pattern.b2a will load at page 2A00
;    /R will save the file to BOOT RAM space
;    HEX files will always load at the addresses given in the file
;
;
;
;VIP Keypad will pull /EF3 line low when addressing a key down.  
;0-F must be scanned by OUT 2
;
;ELF II Keypad will pull /EF3 line high when a key is down.
;Key can be read as low nibble from INP 4
;
;CONTROL BYTE - OUT 5
;High nibble selects the bit, low bit selects set/reset
;
;3 bits select EF4 connections
;
;30 - SD Write LED ON
;31 - SD Write LED OFF
;
;
;This code is for the 4051 production board
;
;
;20/10/00 = 000 - not connected 
;20/10/01 = 001 - EF4 x45 VIP KP Detect
;20/11/00 = 010 - EF4 x47 ELF Keypad
;20/11/01 = 011 - EF4 x47 ELF Keypad
;21/10/00 = 100 - not connected
;21/10/01 = 101 - EF4 Card Write Protect Sense Switch
;21/11/00 = 110 - EF4 Card Detect
;21/11/01 = 111 - EF4 Card Detect
;
;
;Test VIP Keypad present - Bus Pin x45 VIP KP Detect connected to /EF4
;BN4 Branches if NOT present
;
;
;Test ELF Keypad present - Bus Pin x47 74C923 Strobe connected to /EF4
;     /Q Pulls line for open test.
;     Test with Q LOW (/Q=HIGH)
;       -/EF3 low, B3 branches, ELF Keyboard present (strobe is holding low)
;       -/EF3 high, Either no Keyboard or a Key is pressed, need to test with Q low
;       Test with Q HIGH
;         -/EF4 low, B3 branches, = no 74C923 chip (line is floating)
;	  -/EF4 high, 74C923 strobe is high, means a key is pressed.
;
;     Continue control connection to x47 if ELF Keyboard is to be used, single keys are detected by /EF4
;
;
;30 - DSR OFF
;31 - DSR ON
;
;40 - \/ MAIN RAM Bank 0
;50 - /\
;
;41 - \/ MAIN RAM Bank 1
;50 - /\
;
;40 - \/ MAIN RAM Bank 2
;51 - /\
;
;41 - \/ MAIN RAM Bank 3
;51 - /\
;
;60 - ROM Selected (in bottom 32K)
;61 - BOOT RAM selected (in bottom 32K)
;
;70 - SD Card Deselect
;71 - SD Card Select
;
;
;Logic of ROM code:
;Start:
; Say "Hi" to Serial output
; IF VIP Keypad present THEN
;    IF VIP Keypad C pressed THEN 
;       Say "Running VIP"
;       Load VIP to 8000 and RUN it
;    END IF
; END IF
; Test Pixie Present
; Start Pixie if present
; TEST 8K RAM & Say results
; IF VIP Keypad present THEN
;    Say VIP Keypad present
;    Select RX routine that scans VIP Keypad
; ELSEIF ELF Keypad present THEN
;    Say ELF Keypad present
;    Select RX routine that scan ELF Keypad
; ELSE
;    Say no Keypad detected
; ENDIF
; 
;
; If Keypad and PIXIE is present, then the option to run from Keypad or Serial is available.
; Otherwise, user can only work through the Serial.
; 
;
;
;This source file is assembled using TASM
;
;	Examples of coding pseudo ops
;
;	These Defines set pseudo op codes
;

	.define CALL	sep r4	\	.dw
	.define RETN	sep r5


;LDI_RA:	RA=M(PC), PC=PC+2
;


DIRFLAG	.EQU	'('

	.define NEWPAGE	.org	(($ + 00FFH) & 0FF00H)	;(($-1)/256+1)*256
	.define ENDOFPAGE .org	($ | 00FFH)		;($/256)*256+255


;            #include "equates"
;
;	CALL	NEWLINE		;This gets replaced with two lines:
;				SEP R4
;				.dw NEWLINE
;
;	PRINT                   ;Print is just a call to "PRINT_SUB"
;	.text "Hello\000"
;
;        ldi callr/256          ;Get High and Low Bytes of memory labels
;        phi r4
;        ldi callr%256
;        plo r4
;
;
;            [<label>] .TEXT   "<string>"
;
;            Escape
;            Sequence        Description
;            ------------------------------
;            \n              Line Feed
;            \r              Carriage return
;            \b              Backspace
;            \t              Tab
;            \f              Formfeed
;            \\              Backslash
;            \"              Quote
;            \000            Octal value of character
;
;
;
;
;
;
;	RAM
;7E00	Video Display Page
;7F7F	Stack
;
;
; register usage
;
;	R0 = 1861 video DMA pointer
;	R1 = 1861 interrupt handler PC
;	R2 = stack pointer
;	R3 = main PC
;	R4 = call subroutine PC   (SCRT)
;	R5 = return subroutine PC (SCRT)
;	R6 = return address       (SCRT)
;	R7 = 
;	R8 = 
;	R9 = High is system STATUS, Low is PC_POS
;	RA = scratch
;	RB = scratch
;	RC = Cursor position (Line/Pixel Position)
;	RD = scratch, Display pointer during Screen PRINT
;	RE = scratch
;	RF = scratch, HIGH saves D during CALL/RET (SCRT)
;
;
;	R9.1 = STATUS
;	bit0 	PIXIE PRESENT (Cleared if Serial Interface selected)
;	bit1	Cursor Enable
;	bit2	Set if RAM good
;	bit3	not used
;	bit4	SD Card Inserted
;	bit5	Set to use FILE BLOCK MODE (process entire sector vs byte)
;	bit6	Set if ELF Keyboard detected, 
;		used for boot up display and Menu Type Selection
;	bit7	Set if VIP Keyboard detected
;		used for boot up display and Menu Type Selection
;		and used in RXChar to selecttype of Keyboard to read



	.MSFIRST	;when using .dw, save Most significant byte first (Big Endian)
	.NOPAGE
	
	.ORG	0000h

		GHI	R0	;Set page of subroutines
		PHI	R1	;
		PHI	R4
		PHI	R5
		PHI	R9	;Clear system status
		LDI	ISR%256
		PLO	R1		;R1 = 1861 interrupt handler

		LDI	0FEh	;R2 = FEFEh STACK
		PHI	R2
		PLO	R2

		LDI	CALLR%256
		PLO	R4
		LDI	RETNR%256
		PLO	R5

		LDI	MAINRUN/256
		PHI	R3
		LDI	MAINRUN%256
		PLO	R3
		SEP	R3		;New PC

;**********************************************************************
;**********************************************************************
;**               SCRT Subroutines and ISR                           **
;** Interrupt:  X,P->T, 2->X, 1->P, 0->IE                            **
;**********************************************************************
;**********************************************************************

; interrupt routine for 64x32 format (1 page display memory)
;
INTRET:		LDA R2
		RET		;<-return with interrupts enabled
ISR:                    ;->entry with P=R1
		DEC R2		;point to free location on stack
		SAV		;  push T
		DEC R2
		STR R2		;  save D
		NOP		;3 cycles of NOP for sync

		LDI	0	;reset DMA pointer to start of
		PLO	R0	;  display RAM
		LDI	VIDEO_PAGE/256
		PHI	R0
		LDA	R0	;Cannot use LDN R0, that is IDLE command
		PHI	R0
		DEC	R0

				;set D=line start address (6 cycles)
ISRDISP:                                           
		GLO R0
				;1861 displays a line (8 cycles)
		SEX R2
		SEX R2		;reset line start address (6 cycles)
		DEC R0
				;1861 displays line a 2nd time (8 cycles)
		PLO R0
		SEX R2		;reset line start address (6 cycles)
		DEC R0
				;1861 displays line a 3rd time (8 cycles)
		PLO R0
		SEX R2		;reset line start address (6 cycles)
		DEC R0
				;1861 displays line a 4th time (8 cycles)
		PLO R0		;set R0.0=line start address
		BN1 ISRDISP	;loop 32 times
        	BR  INTRET



;**********************************************************************
;Call Subroutine SCRT
;call with R2 pointing to free stack byte
;Pushes R6 to Stack
;Sets R6 to Return Address (2 bytes after Sep R4 call)
;Returns execution to R3
;----------------------------------------------------------------------
	SEP R3	;go to called program
CALLR:	PHI RF	;Save D
	SEX R2	;X=Stack
	DEC R2  ;Point to free byte on stack
	GLO R6	;Push r6 to Stack, big endian
	STXD
	GHI R6
	STXD
	GLO R3	;Fetch Unmodified Return Address
	PLO R6
	GHI R3
	PHI R6
	LDA R6	;get subroutine address AND modify return address
	PHI R3	;to skip inline data
	LDA R6	;save call to address to R3
	PLO R3
	GHI RF	;restore D
	BR  CALLR-1	;jump for SEP R4 re-entery


;**********************************************************************
;Return Subroutine SCRT
;Call with R2 pointing to free stack byte below return address
;Restores Return Address in R6 to R3
;Pops R6 from stack
;Returns execution to R3
;----------------------------------------------------------------------
	SEP R3	;go to calling program
RETNR:	PHI RF	;Save D
	GHI R6	;Fetch Return Address
	PHI R3	;back to R3
	GLO R6
	PLO R3
	INC R2	;Pop previous R6 from stack
	LDA R2
	PHI R6	;
	SEX R2	;X=Stack
	LDA R2
	PLO R6	;
	GHI RF	;restore D
	BR  RETNR-1


;*********************************************************************************

MAINRUN		SEX	R3
		OUT	5
		.DB	70h	;SD Card not selected
		OUT	5
		.DB	31h	;DSR ON
		SEX	R3
		SEX	R3


;-------------------------------------------------------------------- KEYPAD TESTING
				; IF VIP Keypad present THEN
				;    IF VIP Keypad C pressed THEN 
				;       Say "Running VIP"
				;       Load VIP to 8000 and RUN it
				;    END IF
				; END IF
		SEX	R3
		OUT	2	;Select a key that isn't likely to be pressed
		.DB	07h	;Test key 7 (Not Key C)
		OUT	5
		.DB	20h	;001 = Enable x45 sensing
		OUT	5
		.DB	10h	;
		OUT	5
		.DB	01h	;

		BN4	TVK_END	;Jump no VIP Keyboard
				
		OUT	5	;CONTROL BYTE = No Test, EF4=free
		.DB	00h	;000 = Disable x45 sensing

		B3	TVK_END	;Jump if EF3 low

		OUT	2	;
		.DB	0Ch	;Test for key C
		LDI	80h	;STATUS = VIP KEYPAD PRESENT
		PHI	R9
		BN3	TK_END	;C not pressed

		LBR	GOVIP	;Copy VIP to ROM @ 8000, Jump!
		
TVK_END		OUT	5	;CONTROL BYTE = No Test, EF3=free
		.DB	11h	;010 = Map 74C923 to /EF4
				;Test for ELF Keyboard (74C923) Present
				;
		REQ		;Pull line high (Q is inverted)
		B4	TEK_OK	;Jump if line is LOW (doesn't pull high, C923 holds it low)
		SEQ		;Pull line low to test if C923 holds it high (key pressed)
		B4	TK_END

TEK_OK		LDI	40h	;STATUS = ELF KEYPAD PRESENT
		PHI	R9
TK_END		REQ
		
		OUT	5
		.DB	21h	;111 = Enable Card Detect sensing
		OUT	5
		.DB	11h	;
		OUT	5
		.DB	01h	;


;#########################################  PAGE 1 ENDS HERE

		CALL	SELECT_SERIAL
		CALL	MSG_WELCOME

		#INCLUDE "AEVIP-TR.ASM"	;TEST RAM
		
;************************************  RAM TEST COMPLETE
;************************************
;************************************  Start normal operation, Turn on PIXIE
; INITIALIZE RAM ROUTINES
;
		CALL	SELECT_SERIAL

		CALL	STORE_STRING
		  .DW	READ_SHADOW_RAM	;Save routines
		  .DB	7		;7 BYTES
		  SEX R3		
		  OUT	5
		  .DB	61h
		  LDN	RD
		  OUT	5
		  .DB	60h				
		  RETN			;RETN


;-------------------------------------------------------------- VIDEO TESTING
		LDI 	VIDEO_PAGE1/256	;RD.1 = FBh TOP PAGE OF RAM FOR VIDEO DISPLAY
		STD	VIDEO_PAGE
		INC	RE
		STR	RE	;Store PRINT PAGE too
		LDI	0
		PHI	R0
				;TEST FOR PIXIE
		INP	1	;turn on 1861 TV display
		CALL	CLS_PRINT_PAGE	;Clear Screen, Serves as a DELAY to let PIXIE
				;cause interrupt and change R0.1
		GHI	R0
		BZ	NOPIXIE
		 GHI	R9
		 ORI	1	;STATUS 
		 PHI	R9
		 CALL	SELECT_BOTH
NOPIXIE		CALL	MSG_PIXIE
;MSG_PIXIE	PRINT
;		.text "PIXIE-\000"
		GHI	R9
		ANI	01h
		BNZ	PNOTSKIP
		 PRINT
		 .text "NOT \000"		
PNOTSKIP	CALL	MSG_PRESENT2RAM	;Save a little ram here to fit on page
;-------------------------------------------------------------- DISPLAY RAM TEST RESULTS		

		
		GHI	R9
		ANI	04h
		BNZ	RTR_GOOD
		 PRINT
		 .text "BAD\r\n\000"		
		 BR	RTR_END
RTR_GOOD	PRINT
		.text "GOOD\r\n\000"
RTR_END
		GHI	R9
		SHL
		BNF	NO_VIPKP
		 PRINT	
		 .text "VIP\000"
		 BR	KP_END
NO_VIPKP	 SHL
		 BNF	NO_ELFKP
		 PRINT	
		 .text "ELF\000"
		 BR	KP_END
NO_ELFKP	 PRINT	
		 .text "NO\000"		
KP_END		PRINT
		.text " KEYPAD\r\n\000"

;#########################################  PAGE 2 ENDS HERE

		CALL	SELECT_PIXIE	;Message for PIXIE only
		GHI	R9	;Get STATUS
		SHR
		BNF	MNOPIXIE
		 ANI	060h	;Check keypad present
		 BZ	MNOKEY
		 PRINT
		 .text "CONTINUE?\000"
		 CALL	MK_PRINT_YES_NO

		 BR	MNOPIXIE
MNOKEY		  PRINT
		 .text "USE SERIAL ONLY\000"	;PIXIE BUT NO KEYPAD
MNOPIXIE 	
		CALL	SELECT_SERIAL	;Message for SERIAL only

		BN4	MNO_NOCARD	;SD_CARD_OUT
		 GHI	R9		;SD_CARD_IN
		 ORI	10h
		 PHI	R9
		 BR	MNO_CARD_EX		
MNO_NOCARD	 PRINT
		 .text "No Card\r\n\000"
MNO_CARD_EX

		CALL	MSG_SERIAL

		;SELECT THE TYPE OF MENU INTERFACE, KEYPAD OR SERIAL
MSEL_LP		RX_CHAR
		BZ	MSERIAL	;0=NO=SERIAL MENU
		SMI	1
		BNZ	MSEL_1	;1=YES=PIXIE MENU
		CALL	MKEY
MSEL_1		SMI	25	;<Esc>=SERIAL MENU
		BM	MSEL_LP

;****************************************  SERIAL MENU
;****************************************
;****************************************
MSERIAL		OUT 1	;Turn OFF PIXIE
		GHI	R9	;Get STATUS
		ANI	0FEh	;Turn off PIXIE from status
		PHI	R9	
		CALL	SELECT_SERIAL
		CALL	DEFAULT_SERIAL
		LDI	' '
		STD	DISPLAY_FORMAT

		CALL	INIT_FAT
		CALL	LOAD_DIR	
		CALL	NEWLINE

		CALL	SELECT_MAIN_RAM	
		;CALL	SELECT_BOOT_RAM
		
ENTERCOMMAND	PRINT
		.text "\r\nEnter Command\000"
		

;******     ******   ***********   ****     ****    ****    ****
;*******   *******   ***********   *****    ****    ****    ****
;******** ********   ****          ******   ****    ****    ****
;*****************   ****          *******  ****    ****    ****
;*****************   ***********   ******** ****    ****    ****
;****  *****  ****   ***********   **** ********    ****    ****
;****   ***   ****   ****          ****  *******    ****    ****
;****    *    ****   ****          ****   ******    ****    ****
;****         ****   ***********   ****    *****     **********
;****         ****   ***********   ****     ****       ******
		
		
		;INP	1
MAIN_MENU	;CALL	SELECT_BOTH
	
	
MENU_LOOP	CALL	MENU
		BR	MENU_LOOP

MENU		CALL	MSGET_COMMAND
		CALL	NEWLINE				
		CALL	INIT_PTRA	;Init command buffer, RA = 7FF1
		.DW	COMMAND_LINE ;A null will start the string at 7FF0
		CALL	FINDNEXT ;Find start of next word on line, Return 1st Char
		CALL	TOUPPER	
		STD	COMMAND

		CALL	INSTR
		.TEXT	"EXMBISDLVCH\031\025\000"
		STR	R2	;Multiply by 3
		SHL
		ADD
		ADI	MENU_DISPATCH%256
		PLO	R3		;N-WAY BRANCH

MENU_DISPATCH	LBR	MENU_HELP	;00 - Not found
		LBR	SM_ENTER	;E
		LBR	SS_EXECUTE	;X
		LBR	SELECT_MAIN_RAM	;M
		LBR	SELECT_BOOT_RAM	;B
		LBR	SS_INIT_FAT	;I
		LBR	SM_SEC_READ	;S
		LBR	SS_DCMD		;D DIR OR DUMP
		LBR	SM_LOAD		;L
		LBR	SM_LOAD		;V
		LBR	SM_CD		;C
		LBR	SM_HEX
		LBR	SS_CARD_IN	;19h SD_CARD_IN
		LBR	SS_CARD_OUT	;15h SD_CARD_OUT

SS_DCMD		INC	RA
		LDN	RA
		CALL	TOUPPER	
		XRI	'I'
		LBZ	SM_DIR
		LBR	SM_DUMP

SS_INIT_FAT	CALL	INIT_FAT
		CALL	LOAD_DIR
		RETN

		;NEWPAGE
		
		;Routine to call reading/writing of BIG RAM with Dump/Edit commands
		;Routines in RAM to select either BIG_RAM or ELF_RAM for Dump/Edit.
SELECT_MAIN_RAM	CALL	SELECT_MAINRAM
		CALL	PRINT_MAIN_RAM
		RETN
		

SELECT_BOOT_RAM	CALL	SELECT_BOOTRAM
		CALL	PRINT_BOOT_RAM
		RETN
		

PRINT_MAIN_RAM	PRINT		
		.TEXT	"MAIN-RAM\000"
		RETN
		
;---------------------------------------------------------
SM_SEC_READ	CALL	GET32_CMDLINE	;CMD_PARAM = HEX32 from COMMANDLINE
		BNZ	SSR_0		;Branch HEX entered

		LDI_RA	SEC_READ_PTR
		CALL	INC32_RA	;SEC ++
		BR	SSR_2

SSR_0		CALL	READ_SWITCHES
		LDD	LINE_SWITCHES	;/C = 10
		ANI	10h
		BZ	SSR_1		;BRANCH NO /C SWITCH
		
		LD_RA	CMD_PARAM
		ST_RA	CCLUS		;SAVE CURRENT CLUSTER
		CALL	CALC_SEC_IDX	;Converts CCLUS to SEC_IDX
		LDI_RA	SEC_IDX
		LBR	SSR_3

SSR_1		LDI_RB	CMD_PARAM	;READ CMD_PARAM Sector
		LDI_RA	SEC_READ_PTR
		CALL	CPY32_RB2RA	;LET SEC_READ_PTR = The entered Sector	

SSR_2		LDI_RB	SEC_READ_PTR	;SEC_PTR = DIR_SECTOR
		LDI_RA	SEC_IDX
		CALL	CPY32_RB2RA	;LET A = B Save Sector in SEC_IDX
		
SSR_3		PRINT
		.text "\r\nSEC:\000"
		PUT32_RA
		CALL	SD_READ_SEC	;Read Sector at SEC_IDX
		LDI_RD	SD_RAM_BUFFER
		CALL	SELECT_BOOTRAM
		LBR	SM_DUMP_RD


		NEWPAGE
;----------------------------------------------------------------------------
;Change Directory Serial Command
SM_CD		LDI_RA	COMMAND_LINE+1	;Read command line from begining
		CALL	FINDNEXT	;Find the "CD"
		INC	RA		;Move past the CD and look for CD.. or CD\
		INC	RA
		CALL	FINDNEXT	;Advance to next non space 
		BZ	SM_PRINT_FULL	;NO Parameter, print FULL PATH

		CALL	PARSE_FILENAME	;Fetch File name to variable "FNAME"
		BZ	SMCD_INVALID	;Error parsing file name (not 8.3)
		
		CALL	CHDIR		;Change directory to name at RA (if valid)
					;Accepts .. for parent
SM_PRINT_FULL	LDI	13
		PUT_CHAR
		CALL	PRINT_FULLPATH
		PRINT
		.TEXT	"\033[K\000"
		RETN

;----------------------------------------------------------------------------
;Change Directory.  RA points to a string with the Directory Name.  
CHDIR		LDI_RA	FNAME		;Check Fname
		CALL	CMPSTR		;
		.TEXT	"\\\000"	;\ Char Check for Backslash
		BZ	SM_ROOT

		CALL	SEARCH_FILENAME	;Find Entry in directory
		BZ	SMCD_INVALID	;Entry not found
		LDD	FATTRIB		;Test if Directory Entry
		ANI	10h		;
		BZ	SMCD_INVALID	;Not Directory

		LDI_RA	FNAME
		CALL	CMPSTR
		.TEXT	"..\000"	;.. Parent
		BZ	CD_REMOVEPATH
					;Check if room for name
		CALL	FULLPATH_EOS	;RD = FULLPATH_EOS
		BZ	SMCD_FULL
		ADI	12		;Look for 12 free bytes
		BDF	SMCD_FULL
		CALL	SELECT_RD	;"Prints" FILE name into FULLPATH
		LDI_RA	FNAME		;
		CALL	PRINT_FILENAME	;
		CALL	SELECT_DEFAULT	;
		LDI	05Ch		;Add BACK SLASH
		STR	RD		;
		INC	RD		;
		LDI	0h		;And <EOS>
		STR	RD
		BR	CD_GG

CD_REMOVEPATH	CALL	FULLPATH_EOS	;RD = END OF STRING (NUL), D=RD.0
		SMI	1		;Check if at BYTE 1 (ROOT BACKSLASH) = OK
		BZ	CD_GG		;eg.  \BIN\FUN\<EOS>  D=9
		DEC	RD		;     012345678  9
		DEC	RD		;Go back to last letter of current Sub directory
		
DC_SEEK_SLASH	LDN	RD
		SMI	05Ch
		BZ	CD_98
		DEC	RD
		GLO	RD
		BNZ	DC_SEEK_SLASH
CD_98		INC	RD	;Save 0 at next char
		STR	RD

CD_GG		LD_RB	FCLUS0		;Fetch new directory cluster
CD_GG2		ST_RB	DCLUS		;set and load
		CALL	LOAD_DIR
		RETN

SM_ROOT		LDI_RB	0000h		;Loading 0000 ROOT Directory
		BR	CD_GG2		;Clears FULLPATH

PRINT_FULLPATH	LDI_RA	FULLPATH
		CALL	PRINTZ_SUB
		RETN

SMCD_FULL	PRINT
		.TEXT	"FULL\000"
		BR	SMCD_INVALID1
SMCD_INVALID	PRINT
		.TEXT	"Invalid\000"
SMCD_INVALID1	PRINT
		.TEXT	" Directory\000"
		RETN



FULLPATH_EOS	LDI_RD	FULLPATH
FP_LP		LDN	RD
		BZ	FP_EOS
		INC	RD
		GLO	RD
		BNZ	FP_LP
FP_EOS		GLO	RD
		RETN

MSG_WELCOME	PRINT
		.text "ELF II SD CARD v0.2\r\n\000"
		RETN

MSG_SERIAL	PRINT
		.text "<Any> to cancel PIXIE and run Serial Interface only\r\n\000"
		RETN

		NEWPAGE
;**********************************************************************
; LOAD or VIEW FILE
;----------------------------------------------------------------------
SM_LOAD		CALL	FINDSPACE	;Get to first letter of next word on cmd line
		CALL	FINDNEXT	;Returns first char or NUL
		BZ	SML_USE		;If NUL, Filename is blank, send help

		CALL	PARSE_FILENAME	;fetch File name to variable "FNAME"
		BZ	SML_RET		;Error parsing file name
		
SML_1		CALL	SEARCH_FILENAME
		BZ	SML_RET
		
		LDI	0		;Init some flags
		STD	CONTINOUS
		STD	FILE_TYPE


		CALL	FCL_FILETYPE	;Fetch file type from file name
		CALL	FCL_ADDRESS	;Fetch address from command line OR from *.B## file extension (mark as Binary File)
		CALL	FCL_SWITCHES	;Fetch file type from override switches
		LDD	FILE_TYPE
		BNZ	SML_GO

		PRINT
		.text "GUESSING\000"
		LDD	DISPLAY_FORMAT	;SERIAL OR PIXIE (SPACE OR CR)
		PUT_CHAR
		CALL	GUESS_FILE_TYPE
		
		;LDD	FILE_TYPE	;Guessing always sets 1, 2, or 3
		;LBZ	SML_UNKNOWN_MSG

SML_GO		CALL	PRINT_FILE_TYPE

		PRINT
		.text ", \000"
		
		LDD	DISPLAY_FORMAT	;SERIAL OR PIXIE (SPACE OR CR)
		PUT_CHAR
		
		PRINT
		.text "FILE SIZE=\000"
		LDI_RA	FSIZE		;File Size (counts down as bytes read)
		CALL	PRINT_DEC
		
		CALL	NEWLINE

		CALL	SET_OUTPUT	;Check if doing LOAD or VIEW and point file output to
					;appropriate routine
					;RA is set here for BINARY LOAD

		CALL	SLICE32K	;RC = A size of file, up to 32K
		BZ	SML_EXIT	;Exit if zero
		
;Fetch Cluster, Count through Sectors, Count through Bytes, process output
SML_CLUSTER_LP	CALL	CALC_SEC_IDX	;Converts CCLUS to SEC_IDX

SML_LP1		CALL	SD_READ_SEC	;Read sector at SEC_IDX

		LDI_RD	SD_RAM_BUFFER

		GHI	R9		;Check output type, BLOCK or BYTE?
		ANI	20h
		BZ	SML_SEND512
		CALL	FILE_OUTPUT_SUB	;Send BLOCK OUTPUT to RAM.
					;RA and RB are free to init and use
					;
		BZ	SML_EXIT	;EXIT IF ESCAPE
		BR	SML_CHK_NEXT

SML_SEND512	GLO	RC		;EXIT IF BYTES REMAINING = 0
		BNZ	SML_SEND512_1	;
		GHI	RC		;
		BZ	SML_NEXT_SLICE	;
SML_SEND512_1				;
		DEC	RC		;
		LDN	RD		;
					;
		CALL	FILE_OUTPUT_SUB	;Send OUTPUT to screen or RAM.
					;RA and RB are free to init and use
					;
		BZ	SML_EXIT	;EXIT IF ESCAPE
		INC	RD		;
		GHI	RD		;Check for C200
		XRI	(SD_RAM_BUFFER+200h)/256
		BNZ	SML_SEND512	;
		
SML_CHK_NEXT	GLO	RC		;EXIT IF BYTES REMAINING = 0
		BNZ	SML_NEXT_SEC
		GHI	RC
		BNZ	SML_NEXT_SEC
		
SML_NEXT_SLICE	CALL	SLICE32K	;RC = A size of file, up to 32K
		BZ	SML_EXIT	;Exit if zero
				
SML_NEXT_SEC	LDI_RD	SEC_IDX		;Advance to next Sector (within Cluster)
		CALL	INC32_RD
		
		LDD	SECTORS_REMAIN	;count down sectors remaining in this cluster
		SMI	1
		STR	RE
		BNZ	SML_LP1
					;GO FETCH NEXT CLUSTER AND RECALCULATE SEC_IDX
		CALL	FAT_HOP		;CCLUS = FAT(CCLUS)
		BNZ	SML_CLUSTER_LP	;LOOP BACK IF NO error (or EOF)
		
SML_EXIT	CALL	FILE_EOF_SUB
		LDI	1
SML_RET		RETN


SML_USE		PRINT
		.text "\r\nUSE: CMD <FILENAME> [addr] [/a|/b|/h /R]\r\n\000"
		RETN

		;Get a Slice of file, up to 32K and put into RC
SLICE32K	LDI_RC	FSIZE		;Check if size = 0
		CALL	TSTZ32_RC	;
		BZ	SLICE32K_RET	;Exit if zero
					;
		LD_RC	FSIZE		;Check if there is >32768 bytes
		GHI	RC		;
		SHL			;
		BDF	SLICE32K_2	;Branch if 8xxx
		LD_RC	FSIZE+2
		GHI	RC
		BNZ	SLICE32K_1	;Branch if not 00xx xxxx
		GLO	RC
		BNZ	SLICE32K_1	;Branch if not   00 xxxx
		LD_RC	FSIZE		;Fetch the remainder of the file <32768

		LDI	FSIZE/256	;Zero FSIZE low word
		PHI	RF
		LDI	FSIZE%256
		PLO	RF
		LDI	0
		STR	RF
		INC	RF
		STR	RF
		BR	SLICE32K_4

SLICE32K_1	DEC	RC		;Borrow 1 from high word
		ST_RC	FSIZE+2		;
		LD_RC	FSIZE		;Mark low word with 8xxx
		GHI	RC		;
		ORI	80h		;
		BR	SLICE32K_3	;Save and process another 32768

SLICE32K_2	SHR			;If 8xxx, then subtract 32768 and process
SLICE32K_3	PHI	RC
		ST_RC	FSIZE
		LDI_RC	8000h
SLICE32K_4	LDI	1		;RETURN NOT ZERO
SLICE32K_RET	RETN


		NEWPAGE
		
					;Sample file
GUESS_FILE_TYPE	CALL	CALC_SEC_IDX	;Converts CCLUS to SEC_IDX
		CALL	SD_READ_SEC	;Read Sector at SEC_IDX
		LDI_RD	SD_RAM_BUFFER
;		LDI_RA	0	;Zero Character counters
		LDI_RB	0
		LDI_RC	0
		CALL	GFT_COUNT
		CALL	GFT_COUNT_0
		GLO	RB
		BNZ	GFT_BIN

		GLO	RC
		SMI	7
		LDI	1		;1=ASCII
		BM	GFT_EX
		LDI	2		;2=ASCII-HEX
		BR	GFT_EX
GFT_BIN		LDI	3		;3=BINARY
GFT_EX		STD	FILE_TYPE
		RETN		

GFT_COUNT_0	INC	RD
GFT_COUNT	LDA	RD
		SMI	9
		BM	CFTC_B		;< 9, TAB
		SMI	2
		BM	CFTC_A		;= 9 or 10 TAB or LF
		SMI	2
		BM	CFTC_B		;= 11 to 12
		BZ	CFTC_A		;= 13 CR
		SMI	32-13		
		BM	CFTC_B		;= 14 to 31
		SMI	03Ah-32
		BM	CFTC_A		;= SPACE TO '9'
		BZ	CFTC_C		;= ':'
		SMI	127-3Ah
		BM	CFTC_A		;= ';' TO '~'
CFTC_B		INC	RB		;Count Binary characters
		BR	CFT_EN
CFTC_C		INC	RC		;Count Colons (used in HEX FILES)
		BR	CFT_EN
CFTC_A		;INC	RA		;Count Ascii Characters
		;BR	CFT_EN
CFT_EN		GLO	RD
		BNZ	GFT_COUNT
		GLO	RB
		BZ	CFT_RET		
		DEC	RB		;SHIFT RIGHT FOR SINGLE BYTE SIGNIFICANCE
		GLO	RB
		SHR
		PLO	RB
CFT_RET		RETN
		

		

								;NEWPAGE
								
		;RC & RD Are in use M(RD) holds data
		;This routine is called for the first byte, allows variable
		;spaced printing 
PUT_BINARY1_SUB	LDI	10h		;PUT_BINARY1 happens just once to initialize things
		STD	PB1LEN
		CALL	STORE_STRING
		  .DW	FILE_OUTPUT_SUB
  		  .DB	4		;8 BYTES
		  SEP R4
		  .DW	 PUT_BINARY_SUB
		  RETN

		LD_RA	FILE_POS	;IF low nibble 0, print address
		GLO	RA		;Fetch low byte address
		ANI	0Fh
		BZ	PUT_BINARY_SUB
		SDI	10h
		STD	PB1LEN
		SDI	10h
		CALL	NEWLINE
		CALL	PUT_RA
		STR	R2
		SHL
		ADD
		PLO	RA
		INC	RA
		
PB1_LP		LDI	' '
		PUT_CHAR
		DEC	RA
		GLO	RA
		BNZ	PB1_LP
		
		

		;RC & RD Are in use M(RD) holds data
PUT_BINARY_SUB	LD_RA	FILE_POS	;IF low nibble 0, print address
		GLO	RA		;xxx0
		STR	R2		;Save for end of line testing xxxF
		ANI	0Fh
		BNZ	PB_NOLABEL	;Skip LABEL for not start xxx0
		CALL	NEWLINE		;Start a new line for LABEL
		;Test for high bytes
		LD_RB	FILE_POS+2	;If address hits above 64K, print extra bytes
		GHI	RB
		BZ	PB_1
		PUT_BYTE		;Print 2 extra address bytes (32 bit address)
		GLO	RB
		PUT_BYTE
		BR	PB_2
PB_1		GLO	RB		;Print just 1 extra address bytes (24 bit)
		BZ	PB_2
		PUT_BYTE
PB_2		CALL	PUT_RA		;Print lower 16 bits
		LDI	' '		;Space into first data byte
		PUT_CHAR
PB_NOLABEL	LDI_RA	FILE_POS	;Advance File Position
		CALL	INC32_RA
		LDI	' '
		PUT_CHAR
		CALL 	READ_RAM_SUB
		PUT_BYTE

		BN2	PB_3
		LDD	CONTINOUS
		BZ	PB_3
		LDI	0
		RETN
		
PB_3		LDN	R2
		ANI	0Fh
		XRI	0Fh		;Test for End of Line
		BNZ	PB_RET
		CALL	DUMP_ASC_LINE

		LDN	R2		;Check address for xxFF
		ADI	1
		BNZ	PB_RET
		CALL	ENTER_OR_ESC	;RETURN D=1 OR ESC D=0
PB_RET		RETN


MSG_PIXIE	PRINT
		.text "PIXIE-\000"
		RETN

		NEWPAGE
				;Returns DF=1 for Enter, 0 for Escape
ENTER_OR_ESC	LDD	CONTINOUS
		BNZ	EOE_T
		PRINT
		.DB "\r\nENTER, ESC, OR CONTINUOUS\000"

EOE_LP:		RX_CHAR
		CALL	TOUPPER
		XRI	0Dh
		BZ	EOE_1
		XRI	'C'^0Dh
		BZ	EOE_C
		XRI	1Bh^'C'
		BNZ	EOE_LP
EOE_0		LDI	0
		SHR
EOE_RET		RETN
EOE_C		LDI	1
		STD	CONTINOUS
EOE_T		B2	EOE_0
EOE_1		LDI	3
		SHR
		RETN		

;----------------------------------------------
DUMP_ASC_LINE	PRINT
		.text " | \000"

		LDD	PB1LEN	;Get length of line (only changes on the first line)
		PLO	RA	;can be 1 to F for first line, 10h for all other lines
		STR	R2
		
		GLO	RD	;Get address in memory
		SM		;Go back X number of bytes
		PLO	RD
		GHI	RD	;Borrow from High byte
		PHI	RA	;but first, save High byte for restore later
		SMBI	0
		PHI	RD
		INC	RD	;Increment because RD is already at last byte xxxF
				;A line length of 10h needs only go back 0Fh
		
		GLO	RA	;Calculate extra spaces needed by
		SDI	10h	;RA= 10h - Length
		BZ	DAL_1
		PLO	RA
DAL_LP1		LDI	' '
		PUT_CHAR
		DEC	RA
		GLO	RA
		BNZ	DAL_LP1

DAL_1		LDD	PB1LEN	;Get length of line (only changes on the first line)
		PLO	RA

DAL_LP2:	CALL 	READ_RAM_SUB
		SMI	20h
		BM	DAL_NP
		SMI	60h
		BPZ	DAL_NP
		ADI	80h
		BR	DAL_PC
		
DAL_NP		LDI ' '
DAL_PC		PUT_CHAR
		INC	RD
		DEC	RA
		GLO	RA
		BNZ	DAL_LP2
		DEC	RD
		GHI	RA
		PHI	RD
		LDI	10h
		STD	PB1LEN
		RETN

		;NEWPAGE



;-----------------------------------------------
FCL_ADDRESS	LDI_RA	FILE_POS
		CLR32_RA
		
		CALL	INIT_PTRA
		.DW	COMMAND_LINE ;A null will start the string at 7FF0
		
		CALL	FINDNEXT ;Find start of next word on line, Return 1st Char
		CALL	FINDSPACE
		CALL	FINDNEXT ;Find start of next word on line, Return 1st Char

		CALL	FETCHADDR	;RD=ADDRESS
		BZ	FCLA_FEXT	;IF no address on cmd line, check extension
		
		GHI	RD
		PHI	RA
		GLO	RD
		PLO	RA
		ST_RA	FILE_POS
		RETN
		
;-----------------------------------------------
FCLA_FEXT	LDI_RA	FNAME+8		;Check File name extension for Bxx where xx = Valid HEX number
		LDA	RA
		SMI	'B'		;Abort if not .Bxx
		BNZ	SB_EX
		LDA	RA		;get middle char
		CALL	TOHEX
		BNF	SB_EX		;Abort if not HEX
		SHL
		SHL
		SHL
		SHL
		STR	R2
		LDN	RA
		CALL	TOHEX
		BNF	SB_EX
		OR
		PHI	RA
		LDI	0
		PLO	RA
		ST_RA	FILE_POS
		ST_RA	GH_START_ADDR
		LDI	3
		STD	FILE_TYPE
SB_EX		RETN		


MSG_PRESENT2RAM	PRINT
		.text "PRESENT\r\n"
		.text "SYS RAM-\000"
		RETN

;-----------------------------------------------
FCL_FILETYPE	LDI_RA	FNAME+8		;Check File name extension for TXT, HEX, OR BIN
		CALL	CMPSTR
		.TEXT	"TXT\000"
		BNZ	FCLF_NOTTXT
		LDI	1
		BR	FCLR_EX
FCLF_NOTTXT	CALL	CMPSTR
		.TEXT	"HEX\000"
		BNZ	FCLF_NOTHEX
		LDI	2
		BR	FCLR_EX
FCLF_NOTHEX	CALL	CMPSTR
		.TEXT	"BIN\000"
		BNZ	FCLF_RET
		LDI	3
FCLR_EX		STD	FILE_TYPE
FCLF_RET	RETN		

READ_SWITCHES	LDI	0
		STD	LINE_SWITCHES
FCL_SWITCHES	CALL	INIT_PTRA
		.DW	COMMAND_LINE ;A null will start the string at 7FF0
		
FCLS_LP		LDA	RA	;Test for / switches
		BZ	FCLF_RET		
		SMI	'/'
		BNZ	FCLS_LP
		
		LDN	RA
		CALL	TOUPPER
		STR	R2
		CALL	INSTR
		.TEXT	"AHB\000" ;Any of these switches?
		BZ	FCLS_0
		STD	FILE_TYPE
		BR	FCLS_LP
FCLS_0		LDN	R2
		CALL	INSTR
		.TEXT	"RXSC   ?\000" ;Any of these switches?
		BZ	FCLS_LP
		PLO	RF
		DEC	RF
		LDI	ROWTABLE/256 	;Row starts msb = 0
		PHI	RF		;/R = 80
		LDN	RF		;/X = 40
		STR	R2		;/S = 20
		LDD	LINE_SWITCHES	;/C = 10
		OR			;/? = 01
		STR	RE
		BR	FCLS_LP

		NEWPAGE
;-----------------------------------------------
SET_OUTPUT	CALL	STORE_STRING	;Default EOF sub
		  .DW	FILE_EOF_SUB
		  .DB	4		;4 BYTES
  		  SEP R4		;DO_EOF_SUB
		  .DW	 EOF_SUB
		  RETN
		  
		LDD	COMMAND
		SMI	'V'
		BZ	SO_VIEW

		GHI	R9
		ORI	20h
		PHI	R9

		LDD	FILE_TYPE
		SMI	2
		BZ	SOL_HEX
		
SOL_BIN		CALL	STORE_STRING
		  .DW	FILE_OUTPUT_SUB
		  .DB	4		;4 BYTES
		  SEP R4		
		  .DW	 WRITE_BINARY
		  RETN

		PRINT
		.TEXT	"WRITE @\000"
		LD_RA	FILE_POS
		ST_RA	GH_ADDR	;Binary Writes use HEX Address counter for sharing routine
		CALL	PUT_RA
		CALL	MSG_IN	;PRINT " IN "
		LDD	DISPLAY_FORMAT	;SERIAL OR PIXIE (SPACE OR CR)
		PUT_CHAR
		LD_RA	GH_ADDR
		BR	SOL_SWITCHES
		
SOL_HEX		CALL	STORE_STRING
		  .DW	FILE_OUTPUT_SUB
		  .DB	8		;8 BYTES
		  SEP R4		
		  .DW	 WRITE_HEX
		  RETN
  		  SEP R4		;DO_EOF_SUB
		  .DW	 HEX_EOF_SUB
		  RETN

		CALL	HEX_INIT

		PRINT
		.TEXT	"HEX-WRITE \000"
		LDD	DISPLAY_FORMAT	;SERIAL OR PIXIE (SPACE OR CR)
		PUT_CHAR

SOL_SWITCHES	LDD	LINE_SWITCHES	;/R = 80, /X = 40, /S = 20
		ANI	80h
		BZ	SOL_MAIN
		CALL	SELECT_BOOT_RAM	
		RETN
SOL_MAIN	CALL	SELECT_MAIN_RAM		
		RETN
	
		
SO_VIEW		GHI	R9
		ANI	20h^0FFh
		PHI	R9

		LDD	FILE_TYPE
		SMI	3
		BZ	SOV_BIN

SOV_ASC		CALL	STORE_STRING
		  .DW	FILE_OUTPUT_SUB
		  .DB	4		;4 BYTES
		  SEP R4		
		  .DW	 PUT_CHAR_RNZ
		  RETN

		RETN
		
SOV_BIN		CALL	STORE_STRING
		  .DW	FILE_OUTPUT_SUB
		  .DB	4		;4 BYTES
		  SEP R4		
		  .DW	 PUT_BINARY1_SUB
		  RETN

		CALL	SELECT_BOOTRAM
		RETN

		
;---------------------------------------------------------------


WRITE_BINARY	
WB_LP		GLO	RC
		BNZ	WB_1
		GHI	RC
		BZ	WB_EX		;EXIT IF EOF
WB_1		DEC	RC

		LDN	RD
		CALL	WRITE_RAM_SUB
		INC	RA		;Advance File Position

		INC	RD		;
		GHI	RD		;Check for C200
		XRI	(SD_RAM_BUFFER+200h)/256
		BNZ	WB_LP		;
WB_EX		LDI	1
		RETN





SM_HEX		PRINT
		.TEXT	"SEND HEX, <ESC>-DONE\000"

		CALL	HEX_INIT
		
SMH_LP		LDI_RD	SD_RAM_BUFFER+1FFh
		RX_CHAR
		STR	RD
		XRI	27
		BZ	SMH_RET
		PLO	RC
		CALL	WRITE_HEX
		BR	SMH_LP		
SMH_RET		CALL	HEX_EOF_SUB
		RETN


;**********************************************************************
;
;    Intel Hex Object Format. This is the default format.  This format is
;    line  oriented  and  uses only printable ASCII characters except for
;    the carriage return/line feed at the end of each line.  Each line in
;    the file assumes the following format:
;
;    :NNAAAARRHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHCCTT
;
;    Where:
;
;    All fields marked 'hex' consist of two  or  four  ASCII  hexadecimal
;    digits  (0-9,  A-F).  A maximum of 24 data bytes will be represented
;    on each line.
;
;    :       = Record Start Character
;    NN      = Byte Count (hex)
;    AAAA    = Address of first byte (hex)
;    RR      = Record Type (hex, 00 except for last record which is 01)
;    HH      = Data Bytes (hex)
;    CC      = Check Sum (hex)
;    TT      = Line Terminator (carriage return, line feed)
;
;    The last line of the file will be a record conforming to  the  above
;    format with a byte count of zero (':00000001FF').
;
;    The checksum is defined as:
;
;            sum      =  byte_count + address_hi + address_lo +
;                            record_type + (sum of all data bytes)
;            checksum =  ((-sum) & ffh)
;
;	RR=05, Start Linear Address address aaaa in big endian
;		:040000050000aaaaCC
;
;Input byte @RD
;Uses registers R7, R8, RA, RB,
		NEWPAGE
WRITE_HEX	
WH_SEND512	GLO	RC
		BNZ	WH_1
		GHI	RC
		BZ	WH_EX		;EXIT IF EOF
WH_1		DEC	RC
					;
		GLO	R8
		PLO	R3	;Branch to step
					;
WH_NEXT		
		INC	RD		;
		GHI	RD		;Check for C200
		XRI	(SD_RAM_BUFFER+200h)/256
		BNZ	WH_SEND512	;
WH_EX		LDI	1
		RETN


WH_WAIT		LDN	RD
		XRI	':'
		BNZ	WH_NEXT

WH_INIT		LDI	WH_FETCH_HIGH%256
		PLO	R8
		LDI	0
		PLO	R7	;CHECKSUM
		LDI	WH_DO_COUNT%256
		PHI	R8
		BR	WH_NEXT
		
WH_FETCH_HIGH	LDN	RD
		ANI	4Fh
		ADI	0C9h	;ASCII TO HEX
		BDF	WHHA
		ADI	37h
WHHA		SHL
		SHL
		SHL
		SHL		
		PHI	RB	;RB Holds High Nibble
		LDI	WH_FETCH_LOW%256
		PLO	R8
		BR	WH_NEXT
		
WH_FETCH_LOW	LDN	RD
		ANI	4Fh
		ADI	0C9h	;ASCII TO HEX
		BDF	WHLA
		ADI	37h
WHLA		STR	R2
		GHI	RB
		OR
		STR	R2	
		PHI	RB	;RB Holds byte
		GLO	R7	;Update CHECKSUM
		ADD
		PLO	R7
		LDI	WH_FETCH_HIGH%256
		PLO	R8
		GHI	R8	;Branch to BYTE STEPS
		PLO	R3	

WH_DO_COUNT	GHI	RB
		PLO	RB	;Save count in LOW RB
		LDI	WH_DO_ADDR_HIGH%256
		PHI	R8
		BR	WH_NEXT

;    :NNAAAARRHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHCCTT
		
WH_DO_ADDR_HIGH	GHI	RB
		PHI	RA	;Save High Address
		LDI	WH_DO_ADDR_LOW%256
		PHI	R8
		BR	WH_NEXT
		
WH_DO_ADDR_LOW	GHI	RB
		PLO	RA	;Save Low Address
		LDD	GH_FLAGS
		ANI	4
		BNZ	WHDAL_EX
		LDN	RE
		ORI	4
		STR	RE
		ST_RA	GH_START_ADDR

WHDAL_EX	LDI	WH_DO_TYPE%256
		PHI	R8
		BR	WH_NEXT

;00 =DATA, 01=EOF, 04=START ADDRESS
WH_DO_TYPE	GHI	RB
		BZ	WHDT_EX
		SMI	1
		BNZ	WHDT_1
		LDD	GH_FLAGS
		ORI	1
		STR	RE
		BR	WHDT_EX
WHDT_1		SMI	4
		BNZ	WHDT_EX
		LDD	GH_FLAGS
		ORI	2
		STR	RE
		LDI	WH_DO_START%256
		PHI	R8
		RETN
WHDT_EX		LDI	WH_DO_DATA%256
		PHI	R8
		BR	WH_NEXT

;	RR=05, Start Linear Address address aaaa in big endian
;		:040000050000aaaaCC


WH_DO_START	GLO	RB	;BYTE COUNT
		BZ	WH_DO_CHECKSUM
		DEC	RB
		SMI	1
		BNZ	SHDS_1
		GHI	RB
		STD	GH_START_ADDR
SHDS_1		SMI	1
		BNZ	SHDS_EX
		GHI	RB
		STD	GH_START_ADDR+1
SHDS_EX		BR	WH_NEXT
		
		
WH_DO_DATA	GLO	RB	;BYTE COUNT
		BZ	WH_DO_CHECKSUM
		DEC	RB
		GHI	RB
		CALL	WRITE_RAM_SUB
		INC	RA
		BR	WH_NEXT

WH_DO_CHECKSUM	GLO	R7	
		BZ	WH_NO_ERROR
		LDD	GH_ERR_CNT
		ADI	1
		BZ	WH_NO_ERROR	;Prevent roll over
		STR	RE
WH_NO_ERROR	LDI	WH_WAIT%256
		PLO	R8
		BR	WH_NEXT


HEX_INIT	LDI	WH_WAIT%256
		PLO	R8
		LDI	0
		STD	GH_ERR_CNT
		INC	RE
		STR	RE	;STD	GH_FLAGS
		RETN

		
;    :NNAAAARRHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHHCCTT
		
		NEWPAGE
		
HEX_EOF_SUB	PRINT
		.TEXT "\r\nEOF - \000"
		LDD	GH_ERR_CNT
		BNZ	HES_ERRS
		PRINT
		.TEXT "NO\000"
		BR	HES_NERRS	
HES_ERRS	LDI_RA	TEMP32
		CLR32_RA
		STD	TEMP32
		CALL	PRINT_DEC
HES_NERRS	PRINT
		.TEXT " ERRORS \000"
		LDD	GH_FLAGS
		SHR
		BNF	HES_NOEOF
		PRINT
		.TEXT " *EOF* \000"
HES_NOEOF	SHR
		BNF	HES_NO_SAR
		PRINT
		.TEXT " START ADDR=\000"
		LD_RA	GH_START_ADDR
		CALL	PUT_RA
		RETN
		
HES_NO_SAR	SHR
		BNF	HES_RET
		PRINT
		.TEXT " FIRST ADDR=\000"
		LD_RA	GH_START_ADDR
		CALL	PUT_RA
		
HES_RET		RETN



PUT_CHAR_RNZ	PUT_CHAR
PCR_TST_ESC	B2	PCR_0
		LDI	1	;Then return non-zero to continue (ie, not escape)
		RETN
PCR_0		LDI	0
		RETN

;-----------------------------------------------------------------------------
;Fetch a file name from the command line
;Input: RA = Command Line
;Output: D=1 Good (FNAME loaded), D=0 fail


PARSE_FILENAME	LDI_RB	FNAME		;RB points to 11 byte "Filenameext"
		LDI	11
		CALL	BLANK		;Start with a blank look
		LDI_RB	FNAME
		
		CALL	CMPSTR
		.TEXT	"..\000"	;.. Parent
		BNZ	PF_NAME		;
		LDN	RA
		STR	RB
		INC	RB
		STR	RB
		BR	PF_EX
		

PF_NAME		LDI	8
		CALL	COPYFN
		BNZ	PF_HELP		;More than 8 chars before DOT
		BNF	PF_EX		;NO DOT, Ok

		LDI_RB	FNAME+8		;RB points to 3 byte "ext"
		LDI	3
		CALL	COPYFN
		BDF	PF_HELP
		BZ	PF_EX		;Branch if 3 or Less characters

PF_HELP		PRINT
		.text "\r\nBad filename\r\n\000"
		LDI	0
		RETN

PF_EX		LDI	1
		RETN

SF_NOT_FOUND	CALL	MSG_FILENOTFOUND
		RETN

					;LOOK FOR FILE IN CURRENT DIRECTORY	
SEARCH_FILENAME	CALL	DIR_INIT	;Init counters and load first Directory Sector
		BZ	SF_NOT_FOUND
SML_NEXT	CALL	DIR_FETCH
		BZ	SF_NOT_FOUND	;End of directory and FILE NOT FOUND
		LDI_RB	FNAME
		CALL	COMPARE_FNAME	;RB returns at end of FNAME (when found)
		BDF	SML_NEXT
		LDI_RB	FATTRIB
		GLO	RA	;Copy FClus0 and FSIZE to FCB
		ADI	0Bh	;offset to ATTRIB
		PLO	RA
		LDN	RA
		STR	RB
		INC	RB
		GLO	RA
		ADI	0Fh	;offset to AClus0 (0B + 0F = 1A)
		PLO	RA
		LDI	6	;6 Bytes to copy, Clus0 and Size
		CALL	COPY_RAM_RA2RB
		LD_RB	FCLUS0	
		ST_RB	CCLUS
		LDI	1
		RETN





;-----------------------------------------------
PRINT_FILE_TYPE	LDD	FILE_TYPE
		SMI	1
		BZ	PFT_ASC
		SMI	1
		BZ	PFT_HEX
		SMI	1
		BZ	PFT_BIN
PFT_UNK		PRINT
		.text "UNKNOWN\000"
		RETN	
PFT_BIN		PRINT
		.text "BINARY\000"
		RETN
PFT_ASC		PRINT
		.text "ASCII\000"
		RETN
PFT_HEX		PRINT
		.text "HEX\000"
		RETN



;****************************************
;****************************************
;****************************************
;****************************************
;****************************************
;=====================================================================================================

		
	;Attributes
	;01-READ ONLY
	;02-HIDDEN
	;04-SYSTEM
	;08-VOLUME LABEL
	;10-DIRECTORY
	;20-ARCHIVE
						
SM_DIR		PRINT
		.text "Volume: \000"
		LDI_RA	VOLUME_NAME
		CALL	PRINT_FILENAME
		CALL	NEWLINE
		LDI_RA	SD_DIR_LIST
		LDD	FILE_COUNT
		PLO	RC
		BZ	DD_RET
		
DD_NEXT		CALL	PRINT_FILENAME
		
		DEC	RC
		GLO	RC
		BZ	DD_RET

				;Do some Screen formating	
		GLO	R9	;PC_POS
		SMI	64
		BM	DD_SAMELINE
		CALL	NEWLINE
DD_SAMELINE	GLO	R9	;PC_POS	;TAB OUT 16 CHARS
		ANI	0Fh
		BZ	DD_NEXT
		LDI	' '
		PUT_CHAR
		BR	DD_SAMELINE

DD_RET		CALL	NEWLINE
		
		LDI_RA TEMP32	;32 BIT WORD FOR ACC
		LDI32_RA	0000h,0000h
		LDD	FILE_COUNT
		STR	RA
		CALL	PRINT_DEC
		PRINT
		.text " FILES\000"
		RETN


		
		
MENU_HELP	PRINT
		.text "???\r\n"
		.text "DIR-DIRECTORY\r\n"
		.text "CD-CHANGE DIRECTORY [\|..]\r\n"
		.text "X-EXECUTE MAIN RAM [/R] (BootRAM)\r\n"
		.text "S-SECTOR READ [/C] (Cluster)\r\n"
		.text "L-LOAD FILE [A|B|H] (Ascii|Binary|Hex) /R (BootRAM)\r\n"
		.text "V-VIEW FILE [A|B|H]\r\n"
		.text "E-EDIT RAM\r\n"
		.text "D-DUMP RAM [/S] (Shadow RAM)\r\n"
		.text "B-BOOT RAM\r\n"
		.text "M-MAIN RAM\r\n"
		.text "H-HEX UPLOAD\r\n"	
		.text "\000"
		RETN


		NEWPAGE
MSGET_COMMAND	PRINT
		.text "\r\n>\000"
				;Init command buffer, RA = 7FF0 (End of buffer=xxFF)
		CALL	INIT_PTRA
		.DW	COMMAND_LINE ;A null will start the string at 7FF0
		
MSGC_LP		RX_CHAR

MSGC_LPIN	SMI	20h
		BM	MSGC_CTRL	;Jump if < Space
		SMI	60h
		BPZ	MSGC_LP		;Jump if NOT Printable char

MSGC_PRINTABLE	ADI	80h
		CALL	TOUPPER
		PUT_CHAR
		STR	RA
		INC	RA
		GLO	RA		;Check for end of RAM/Buffer = xxFF
		BNZ	MSGC_LP
		DEC	RA		;Freeze
		BR	MSGC_LP

MSGC_CTRL	XRI	0EDh		;Control char less 20h
		BZ	MSGC_RET
		XRI	0E8h^0EDh
		BZ	MSGC_BS

		XRI	0F5h^0E8h
		BZ	MSGC_CARDOUT	;SD_CARD_OUT
		XRI	0F9h^0F5h
		BZ	MSGC_CARDIN	;SD_CARD_IN
		
		XRI	0E8h^0F9h
		BNZ	MSGC_LP		;Ingnore all other ctrl

MSGC_ESC	RX_CHAR
		SMI	'['
		BZ	MSGC_ESC_SEQ
		ADI	'['
		BR	MSGC_LPIN	;If not an escape sequence, process char


MSGC_ESC_SEQ	RX_CHAR
		SMI	'A'
		BM	MSGC_ESC_SEQ	;Burn through Escape Sequence
		BR	MSGC_LP
		
MSGC_RET	STR	RA		;Save 00 end of line
		GLO	RA
		SMI	80H
		BZ	MSGC_LP		;Do not return if buffer is null
		RETN
		
MSGC_BS		DEC	RA
		LDN	RA		;Check buffer contents
		INC	RA
		BZ	MSGC_LP		;Ignore BS if pointer at start
		DEC	RA
		LDI	8		;Print BS to terminal
		PUT_CHAR
		BR	MSGC_LP


MSGC_CARDIN	LDI	4		;SD_CARD_OUT 19
MSGC_CARDOUT	ADI	15h		;SD_CARD_IN  15
		STR	R2		;Put these control characters at front of command line and return
		CALL	INIT_PTRA
		.DW	COMMAND_LINE ;A null will start the string at 7FF0
		LDN	R2
		STR	RA
		RETN


RUNRAM		OUT 1	;Turn OFF PIXIE
		LDI 0	;Set R0 to start address of RAM program
		PHI R0	
		PLO R0
		INP 5	;Trigger RAM Mapping
		SEP R0	;RAM will be mapped after this instruction


	NEWPAGE

;--------------------------------------- Dump
SM_DUMP		CALL	FETCHADDR	;RD=ADDRESS

		CALL	PRINT_RAM_SUB

		CALL	READ_SWITCHES

SM_DUMP_RD	LDI_RA	FILE_POS
		CLR32_RA

		LDI	0
		STD	CONTINOUS

		GLO	RD
		PLO	RA
		GHI	RD
		PHI	RA
		ST_RA	FILE_POS
		CALL	PUT_BINARY1_SUB
		INC	RD
		BZ	DUMP_RET
		
DUMP_LP		CALL	PUT_BINARY_SUB
		INC	RD
		BNZ	DUMP_LP
DUMP_RET	RETN


READ_BOOT_RAM	LDD	LINE_SWITCHES
		ANI	20h	;S Shadow RAM
		BZ	RBR_1
		
		CALL	READ_SHADOW_RAM
		RETN
		
RBR_1		LDN	RD		;LDN	RD  (ELF_RAM)  7FE0
		RETN			;RETN


MSG_IN		PRINT
		.TEXT	" IN \000"
		RETN

MSG_FILENOTFOUND PRINT
		.text "\r\nFile not found\r\n\000"
		RETN

		;RB = Source (in LOW RAM)
		;RC = Count
		;RD = Destination in NEW RAM		
WRITE_RAM_BLOCK	GHI	RD
		;STXD		;Save RD.1
		SEX	R3
		SHL		;Check bank
		BDF	WRB1X	;Branch if Bank 1X
		SHL
		BDF	WRB01

		OUT	5	;Select BANK 00
		.DB	40h	;
		OUT	5
		.DB	50h

		GHI	RD	;Set pointer to High 32 memory
		ORI	80h
		PHI	RD
		BR	WRB_LOOP

WRB01		OUT	5	;Select BANK 01
		.DB	41h	;
		OUT	5
		.DB	50h
		GHI	RD	;Set pointer to High 32 memory
		XRI	0C0h
		PHI	RD
		BR	WRB_LOOP


WRB1X		SHL
		BDF	WRB11
		OUT	5	;Select BANK 10
		.DB	40h	;
		OUT	5
		.DB	51h

WRB_LOOP	GHI	RC
		BNZ	WRB_DO
		GLO	RC
		BNZ	WRB_DO
		RETN
		
WRB_DO		LDA	RB
		STR	RD
		INC	RD
		DEC	RC
		BR	WRB_LOOP

WRB11		OUT	5	;Select BANK 11
		.DB	41h	;
		OUT	5
		.DB	51h
		GHI	RD	;Set pointer to High 32 memory
		ANI	0B0h
		PHI	RD
		BR	WRB_LOOP




		;NEWPAGE
;--------------------------------------- Enter

SM_ENTER	CALL FETCHADDR

ENTERLOOP1	GHI RD
		PUT_BYTE
		GLO RD
		PUT_BYTE
		LDI 3
		CALL	SPACES

		CALL	READ_RAM_SUB	;get byte and display
		PUT_BYTE

		LDI	':'
		PUT_CHAR

		LDI	2
		CALL	USCORE

		CALL	INPUTBYTE
		BNF	E_CTRL	;jump if control or bad char entered

		ST_RD	TEMP32
		LD_RA	TEMP32
		CALL	WRITE_RAM_SUB

		LDI	':'
		PUT_CHAR
		CALL	READ_RAM_SUB	;get byte and display
		PUT_BYTE

		INC	RD
		CALL	NEWLINE
		BR	ENTERLOOP1

E_CTRL		GHI	RE	;Fetch last RX Char
		XRI	27
		BZ	ENTER_EXIT
		CALL	NEWLINE
		BR	ENTERLOOP1

ENTER_EXIT	RETN


;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************


	

;**********************************************************************
; Fetch address from Buffer at M(RA)
; Put in RD.  D=0 if no valid address found
;----------------------------------------------------------------------
FETCHADDR	CALL	GET32_CMDLINE	;Get 32 bit from Command Line
		LD_RD	CMD_PARAM	;Fetch 16 bit value from PARAM
		RETN

	NEWPAGE


;**********************************************************************
; HASH COMMAND LINE PARAMETER
; Fetch 32 BIT value from Buffer at M(RA)
; Put in CMD_PARAM
; RETURNS D=0 If no valid argument found
;----------------------------------------------------------------------
GET32_CMDLINE	CALL	WORDEND	;GET TO LAST CHAR OF FIRST PARAMETER (NEXT WORD)
		LDI_RB	CMD_PARAM
		CLR32_RB

		LDN	RA	;Fetch characters frome the end (low nibble)
		CALL	TOHEX
		LDI	0
		BNF	GET32CL_END	;Exit DF=0 (bad hex)
		
		LDI	4
GET32CL_LP	STR	R2
		LDN	RA	;Fetch first character (low nibble)
		CALL	TOHEX
		BNF	GET32CL_EXIT	;Exit DF=0 (bad hex)
		STR	RB
		DEC	RA	;RA=PREVIOUS CHARACTER
		LDN	RA	;Fetch next character (high nibble)
		CALL	TOHEX
		BNF	GET32CL_EXIT
		SHL
		SHL
		SHL
		SHL
		SEX	RB
		OR
		STR	RB
		INC	RB
		DEC	RA	;RA=PREVIOUS CHARACTER
		LDN	R2
		SMI	1
		BNZ	GET32CL_LP
GET32CL_EXIT	LDN	RA
		SMI	'/'	;Consider SWITCHES as unacceptable
		;LDI	1
GET32CL_END	RETN



MSG_EXECUTE	PRINT
		.TEXT "EXECUTE AT:\000"
		RETN
MSG_RUN		PRINT
		.TEXT "\r\nRun:\000"
		RETN		

EOF_SUB		PRINT
		.TEXT "\r\nEOF\000"
		RETN

PRINT_BOOT_RAM	PRINT
		.TEXT	"BOOT-RAM\000"
		RETN

;**********************************************************************
;Execute RD
;----------------------------------------------------------------------
		;EXECUTE
SS_EXECUTE	LDI	0
		STD	CONTINOUS
		CALL	FETCHADDR	;RD=ADDRESS
		BNZ	SSE_GO
MK_EXECUTE	CALL	MSG_EXECUTE	;PRINT "EXECUTE AT:"
		LDD	DISPLAY_FORMAT	;SERIAL OR PIXIE (SPACE OR CR)
		PUT_CHAR
		LD_RD	GH_START_ADDR
		CALL	PUT_RD
		PRINT
		.TEXT " ?\000"
		LDD	DISPLAY_FORMAT
		SMI	' '
		BZ	SSE_SERIAL
		CALL	MK_PRINT_YES_NO
		RX_CHAR
		SMI	1
		BZ	SSE_GO
		RETN

SSE_SERIAL	CALL	ENTER_OR_ESC
		BDF	SSE_GO
		RETN

SSE_GO		CALL	MSG_RUN		;PRINT "\r\nRUN"
		CALL	PUT_RD
		CALL	PUT_SPACE_BYTE

		GHI	RD
		PHI	R0
		GLO	RD
		PLO	R0
		CALL	READ_SWITCHES
		LDD	LINE_SWITCHES
		SHL
		BDF	SSE_BOOTRAM	;/R SWITCH USED
		CALL	PRINT_MAIN_RAM
	
		LDI	100
		CALL	LONG_DELAY

		OUT	1	;turn off 1861
		CALL	DELAY
		GHI	RD	;Load R0 after turning OFF Video (when called from MKEY)
		PHI	R0
		GLO	RD
		PLO	R0

		LDI	0FH	;Preload R1 with 0F to run VIP software
		PHI	R1
		SEX	R3
		INP 5		;Trigger RAM Mapping
		SEX R0
		SEP R0		;RAM will be mapped after this instruction

		
SSE_BOOTRAM	CALL	PRINT_BOOT_RAM
		SEX	R3
		OUT	5
		.DB	20h	;000 = Not connected
		OUT	5
		.DB	10h	;
		OUT	5
		.DB	00h	;
		ANI	40h		;40=20 after shift = /S switch
		BNZ	SSE_SHADOW_RAM
		SEX	R0
		SEP	R0
		
SSE_SHADOW_RAM	CALL	STORE_STRING	;Change READ to Execute Shadow RAM
		  .DW READ_SHADOW_RAM
		  .DB	5		;5 BYTES
		  SEX R3
		  OUT	5
		  .DB	061h		;ROM BANK 1
		  SEX R0
		  SEP R0		
		CALL	READ_SHADOW_RAM	;No comming back!



								NEWPAGE
;**********************************************************************
;**********************************************************************
;**                    KEYBOARD MENU SYSTEM                          **
;**********************************************************************
;**********************************************************************
								
MKEY		CALL	SELECT_PIXIE	;DROP SERIAL
		CALL	DEFAULT_PIXIE
		LDI	10		;10 SHOULD DO CR ALSO
		STD	DISPLAY_FORMAT

		CALL	MK_MENU
		BR	MKEY

;---------------------------------------------------- MK MENU
MK_MENU		CALL	CLS_PRINT_PAGE
		PRINT
		.text "C - RUN VIP\r\n"
		.text "D - DIRECTORY\r\n"
		.text "E/F - UP/DOWN\r\n"
		.text "1-5 - LOAD\r\n"
		.text "A - EXECUTE\000"

		
MKEY_LP		RX_CHAR
		CALL	INSTR
		.DB	0Ch,0Dh,0Ah,0
		
		SHL		;Multiply by 2
		ADI	MKEY_DISPATCH%256
		PLO	R3		;N-WAY BRANCH

MKEY_DISPATCH	BR	MKEY_LP	;00 - Not found
		BR	GOVIP	;C
		BR	MKD_DIR	;D
		BR	MKD_EXE
		
MKD_DIR		CALL	MK_DIR
		BZ	MK_MENU
		SMI	0Ah		;A key pressed to leave DIR
		BZ	MKD_EXE
		SMI	15h-0Ah		;Check for Card Out
		BNZ	MK_MENU
		
		CALL	CLS_PRINT_PAGE
		PRINT
		.text "NO CARD\000"
		RX_CHAR
		BR	MK_MENU
		
MKD_EXE		CALL	CLS_PRINT_PAGE
		CALL	MK_EXECUTE
		CALL	CLS_PRINT_PAGE
		PRINT	
		.text "ENTER ADDRESS?\000"
		CALL	MK_PRINT_YES_NO
		RX_CHAR
		SMI	1
		BNZ	MK_MENU

		GHI	R9	;Cursor ON
		ORI	2
		PHI	R9
		
		PRINT
		.TEXT	"\r\n>\000"
		CALL	MK_GETBYTE
		PHI	RD
		CALL	MK_GETBYTE
		PLO	RD
		ST_RD	GH_START_ADDR
		GHI	R9	;Cursor OFF
		ANI	2^0FFH
		PHI	R9
		BR	MKD_EXE

MK_GETBYTE	RX_CHAR
		PHI	RA
		CALL	PUT_HEX
		RX_CHAR
		PLO	RA
		CALL	PUT_HEX
		GHI	RA
		SHL
		SHL
		SHL
		SHL
		STR	R2
		GLO	RA
		OR
		RETN		
		
MK_PRINT_YES_NO	PRINT
		.text "\r\n1-YES, 0-NO\000"
		RETN

;--------------------------------------- RUN VIP Software
; RUN VIP Software
; Copy VIP ROM to 8000h and execute
;--------------------------------------- RUN VIP Software
GOVIP		SEX	R2
		OUT	1	;turn off 1861
		LDI	VIPROM/256	;RB = Source (VIP ROM)
		PHI	RB
		LDI	VIPROM%256
		PLO	RB
		
		LDI_RC	0200h	;RC = Count
		
		PLO	RD	;RD = Destination (in NEW RAM)
		PLO	R0	;R0 = RUN ADDRESS
		PHI	R0
		PLO	R1
		LDI	80h
		PHI	RD
		PHI	R1	;Execute VIP ROM at 8000 using R1
				;This will keep R0.1 = 00 for jumping to program
				;VIP ROM does not care, it will SEP R2 immediately
		
		CALL	WRITE_RAM_BLOCK
			
GO_BIGRAM	LDI	100
		CALL	LONG_DELAY
		
	;	LDI	0FH	;Preload R1 with 0F to run VIP software
	;	PHI	R1
	;	B3	GB_0800
	;	GLO	R0	;Execute AT 0000 IF key still not pressed
	;	PHI	R0
		
GB_0800		SEX	R3
		INP 5		;Trigger RAM Mapping
		SEX R0
		SEP R1		;RAM will be mapped after this instruction

		;NEWPAGE
		
;---------------------------------------------------- MK DIRECTORY
MK_DIR		GHI	R9		;IF NO SD CARD, EXIT D=0FF FAIL
		ANI	10h
		BNZ	MK_DIR_1
		LDI	0FFh
		RETN

MK_DIR_1	CALL	MK_DIR_INIT	;Init card, show type, etc
		BZ	MKD_TOP
		RETN			;Return if Fail

		
MKD_TOP		LDI_RA	SD_DIR_LIST	;RA POINTS TO START OF DIR LIST
		LDD	FILE_COUNT	;CHECK EACH PRINT IF END OF LIST
		PHI	RC		;Put File count into Register for speed
		LDI	0		
		PLO	RC
		
MKD_DOPAGE	CALL	CLS_PRINT_PAGE	;Print 1 page of files
					;
		LDI	1		;
		PLO	RB		;
					;
MKD_LP		GHI	RC		;
		STR	R2		;
		GLO	RC		;
		SM			;PTR - FILECOUNT
		BPZ	MKD_NUL		;
					;
		INC	RC		;Not EOL, print it
		GLO	RB		;
		CALL	PUT_HEX		;
		LDI	'-'		;
		PUT_CHAR		;
		CALL	PRINT_FILENAME	;
		BR	MKD_NEWLINE	;
					;
MKD_NUL		INC	RC		;
		GLO	RA		;KEEP RA ADVANCING
		ADI	12		;
		PLO	RA		;
		GHI	RA		;
		ADCI	0		;
		PHI	RA		;

					;
MKD_NEWLINE	CALL	NEWLINE		;
		INC	RB		;
		GLO	RB		;
		SMI	6		;
		BM	MKD_LP		;LOOP BACK TO DO 5 FILES per page

		
MKD_GETKEY	RX_CHAR			;GET KEYBOARD INPUT
		BZ	MKD_RET		;0 KEY, EXIT TO PREVIOUS MENU
		SMI	6		;
		BM	MKD_PICKOF5	;1-5, SELECT THAT FILE
		SMI	0Eh-6		;
		BZ	MKD_UP		;E KEY, DO LIST UP
		SMI	1		;
		BZ	MKD_DOWN	;F KEY, DO LIST DOWN
		ADI	0Fh		;Restore Key value
MKD_RET		RETN			;RETURN

MKD_DOWN	LDI	0
		STR	R2
		OUT	2		;Strobe next VIP key for autorepeat
		DEC	R2	
		GHI	RC		;DOWN RC.1 IS FILECOUNT
		STR	R2		;
		GLO	RC		;RC.0 IS PTR
		SM			;PTR - FILECOUNT
		BPZ	MKD_GETKEY	;
		BR	MKD_DOPAGE	;
		
MKD_UP		LDI	0
		STR	R2
		OUT	2		;Strobe next VIP key for autorepeat
		DEC	R2
		GLO	RC		;UP
		SMI	5		;
		BZ	MKD_GETKEY	;
		SMI	5		;
		PLO	RC		;
		GLO	RA		;
		SMI	12*10		;
		PLO	RA		;
		GHI	RA		;
		SMBI	0		;
		PHI	RA		;
		BR	MKD_DOPAGE	;

MKD_PICKOF5	PLO	RB
		CALL	CLS_PRINT_PAGE
		GLO	RB

MKDPICK_LP1	GLO	RA		;
		SMI	12		;
		PLO	RA		;
		GHI	RA		;
		SMBI	0		;
		PHI	RA		;
		INC	RB
		GLO	RB
		BNZ	MKDPICK_LP1
		LDN	RA
		SMI	DIRFLAG
		BZ	MKD_DIRNAME
		
		LDI_RB	FNAME
		LDI	11
		CALL	COPY_RAM_RA2RB
		
		CALL	SML_1		;LOAD THE FILE
		BZ	MKD_LOADFAIL	;Exit if error loading
		LDI	0Ah		;Ask to Execute?
MKD_LOADFAIL	CALL	RX_ANYKEY	;Get anykey for pause
		RETN

MKD_DIRNAME	INC	RA
		LDI_RB	FNAME
		LDI	11
		CALL	COPY_RAM_RA2RB
		CALL	CHDIR
		BR	MKD_TOP
		
RX_ANYKEY	STR	R2
		RX_CHAR
		LDN	R2	;RESTORE D FROM CALL
		RETN

								NEWPAGE
MK_DIR_INIT	LDI	VIDEO_PAGE2/256
		STD	PRINT_PAGE
		CALL	CLS_PRINT_PAGE
		PRINT
		.text "INIT SD CARD\r\n\000"
		CALL	SELECT_NONE
		CALL	INIT_FAT
		BNZ	MKDI_FAIL		
MKDI_SHOW	CALL	SELECT_PIXIE
		PRINT
		.text "SD TYPE: \000"
		LDD	SD_CARD_TYPE
		PUT_BYTE
		PRINT
		.text "\r\nPAR TYPE: \000"
		LDD	SD_PART_TYPE	;TYPE, 4, 6, or 86h
		PUT_BYTE
		PRINT
		.text "\r\nLOADING\r\n\000"
		
		CALL	LOAD_DIR

		PRINT
		.text "\r\nVol:\000"
		LDI_RA	VOLUME_NAME
		CALL	PRINT_FILENAME

		LDI	VIDEO_PAGE3/256
		STD	PRINT_PAGE

		LDI	STARSHIP/256
		PLO	RE
		LDI	VIDEO_PAGE3/256
		PHI	RE
		CALL	PRINT_PAGE_GET

		LDI	VIDEO_PAGE3/256
		STD	PRINT_PAGE
		CALL	DOPAGELEFT

		LDI	VIDEO_PAGE2/256
		STD	PRINT_PAGE
		CALL	DOPAGELEFT

		LDI	VIDEO_PAGE1/256
		STD	PRINT_PAGE
		
		RX_CHAR			;Wait for any key
		SMI	15h		
		BNZ	MKDI_EXIT	;Not card out
		BR	MKDI_FAIL1
MKDI_FAIL	CALL	SELECT_PIXIE
		RX_CHAR
MKDI_FAIL1	LDI	015h
		RETN
MKDI_EXIT	LDI	0		;SUCCESS
		RETN
		
MK_CURSOR	RETN


;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************

;**********************************************************************
;CLS
;CLEAR SCREEN
;Writes 00's to full page of D upon entry
;Call with Page to clear in D
;Uses RE Scratch Register
;----------------------------------------------------------------------
CLS_PRINT_PAGE	LDI	0	;Zero the cursor
		STD	PIXIE_ROW
		STD	PIXIE_COL
		LDD	PRINT_PAGE
CLS:		PHI	RE
		LDI	0
		PLO	RE
CLS_LOOP	LDI	0	;Handy loop subroutine to clear page RE
		STR	RE
		INC	RE
		GLO	RE
		BNZ	CLS_LOOP
		RETN



;PAGE RF TO PAGE RE
PRINT_PAGE_GET	GLO	RE
		PHI	RF
		LDI	0
		PLO	RF
		PLO	RE
		
PPG_LOOP	LDA	RF
		STR	RE
		INC	RE
		GLO	RE
		BNZ	PPG_LOOP
		RETN

	

;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************

	NEWPAGE
	
SELECT_MAINRAM	CALL	STORE_STRING	;Save routines at 7FE0h and 7FE4
		  .DW	READ_RAM_SUB
  		  .DB	12		;12 BYTES
		  SEP R4		;CALL READ_MAIN_RAM  7FE0
		  .DW	READ_MAIN_RAM
		  RETN			;RETN
		  	;WRITE_RAM_SUB
		  SEP R4		;CALL WRITE_RAM (BIG_RAM) 7FE4
		  .DW	WRITE_MAIN_RAM
		  RETN			;RETN
		  	;PRINT_RAM_SUB
		  SEP R4
		  .DW	PRINT_MAIN_RAM
		  RETN
		RETN


SELECT_BOOTRAM	CALL	STORE_STRING
		  .DW	READ_RAM_SUB
		  .DB	12		;12 BYTES
		  SEP R4		;CALL READ_MAIN_RAM  7FE0
		  .DW	READ_BOOT_RAM
		  RETN			;RETN
		  	;WRITE_RAM_SUB	  
		  STR	RA		;STR	RD  (ELF_RAM)  7FE4
		  RETN			;RETN
		  SEX	R2		;Filler 2 bytes
		  SEX	R2
		  	;PRINT_RAM_SUB
  		  SEP R4
		  .DW	PRINT_BOOT_RAM
		  RETN
		RETN




READ_MAIN_RAM	GHI	RD
		PLO	RF	;Save original RD.1
		SHL		;Check bank
		BDF	RMB1X	;Branch if HIGH bank
		SHL
		BDF	RMB01
		
		SEX	R3	;Select BANK 00
		OUT	5
		.DB	40h	;
		OUT	5
		.DB	50h
		
		GHI	RD	;Read from the High 32 memory
		ORI	80h	;Adust address to 16K Window between 8000-BFFF
		PHI	RD
		LDN	RD
		PHI	RF	;Save byte read
		GLO	RF	;Restore RD.1
		PHI	RD
		GHI	RF	;Restore byte read
		RETN

RMB01		SEX	R3	;Select BANK 01
		OUT	5
		.DB	41h	;
		OUT	5
		.DB	50h
		
		GHI	RD	;Read from the High 32 memory
		XRI	0C0h	;Adust address to 16K Window between 8000-BFFF
		PHI	RD
		LDN	RD
		PHI	RF	;Save byte read
		GLO	RF	;Restore RD.1
		PHI	RD
		GHI	RF	;Restore byte read
		RETN


RMB1X		SHL
		BDF	RMB11

		SEX	R3	;Select BANK 10
		OUT	5
		.DB	40h	;
		OUT	5
		.DB	51h
		LDN	RD	;Read the byte from HIGH RAM (in the high bank)
		RETN

RMB11		SEX	R3	;Select BANK 11
		OUT	5
		.DB	41h	;
		OUT	5
		.DB	51h
		
		GHI	RD	;Read from the High 32 memory
		ANI	0BFh	;Adust address to 16K Window between 8000-BFFF
		PHI	RD
		LDN	RD
		PHI	RF	;Save byte read
		GLO	RF	;Restore RD.1
		PHI	RD
		GHI	RF	;Restore byte read
		RETN


WRITE_MAIN_RAM	GHI	RA
		PLO	RF	;Save original RD.1
		SHL		;Check bank
		BDF	WMB1X	;Branch if Bank 1X
		SHL
		BDF	WMB01
		
		SEX	R3	;Select BANK 00
		OUT	5
		.DB	40h	;
		OUT	5
		.DB	50h
		
		GHI	RA	;Read from the High 32 memory
		ORI	80h	;Adust address to 16K Window between 8000-BFFF
		PHI	RA
		GHI	RF	;Fetch D from saved copy done during CALL
		STR	RA	;Write byte to RAM
		GLO	RF
		PHI	RA
		RETN

WMB01		SEX	R3	;Select BANK 01
		OUT	5
		.DB	41h	;
		OUT	5
		.DB	50h
		
		GHI	RA	;Read from the High 32 memory
		XRI	0C0h	;Adust address to 16K Window between 8000-BFFF
		PHI	RA
		GHI	RF	;Fetch D from saved copy done during CALL
		STR	RA	;Write byte to RAM
		GLO	RF
		PHI	RA
		RETN


WMB1X		SHL
		BDF	WMB11

		SEX	R3	;Select BANK 10
		OUT	5
		.DB	40h	;
		OUT	5
		.DB	51h
		GHI	RF	;Fetch D from saved copy done during CALL
		STR	RA	;Write byte to RAM
		RETN

WMB11		SEX	R3	;Select BANK 11
		OUT	5
		.DB	41h	;
		OUT	5
		.DB	51h
		
		GHI	RA	;Read from the High 32 memory
		ANI	0BFh	;Adust address to 16K Window between 8000-BFFF
		PHI	RA
		GHI	RF	;Fetch D from saved copy done during CALL
		STR	RA	;Write byte to RAM
		GLO	RF
		PHI	RA
		RETN




	

		#INCLUDE "AEVIP-SD.ASM"	;SD CARD ROUTINES
		#INCLUDE "AEVIP-UT.ASM"	;UTILITY ROUTINES
		#INCLUDE "AEVIP-PP.ASM"	;PIXIE PRINT ROUTINES
		
		.ORG	7E00h
		
		#INCLUDE "AEVIP-VR.ASM"	;VIP ROM ROUTINES
	





;00	IDL		IDLE
;0n	LDN	Rn	LOAD VIA N	D = M(R1)
;1n	INC	Rn	INCREMENT REG N	Rn = Rn + 1
;2n	DEC	Rn	DECREMENT REG N	R0 = R0 - 1
;30	BR	XX	SHORT BRANCH	RP.0 = M(RP)
;31	BQ	XX	SHORT BRANCH IF Q = 1
;32	BZ	XX	SHORT BRANCH IF D = 0
;33	BDF	XX	SHORT BRANCH IF DF = 1
;	BPZ	XX	SHORT BRANCH IF POSITIVE OR ZERO
;	BGE	XX	SHORT BRANCH IF EQUAL OR GREATER
;34	B1	XX	SHORT BRANCH IF EF1 = 1
;35	B2	XX	SHORT BRANCH IF EF2 = 1
;36	B3	XX	SHORT BRANCH IF EF3 = 1
;37	B4	XX	SHORT BRANCH IF EF4 = 1
;38	NBR		NO SHORT BRANCH RP = RP + 1
;	SKP		SHORT SKIP
;39	BNQ	XX	SHORT BRANCH IF Q = 0
;3A	BNZ	XX	SHORT BRANCH IF D NOT 0
;3B	BNF	XX	SHORT BRANCH IF DF = 0
;	BM		SHORT BRANCH IF MINUS
;	BL		SHORT BRANCH IF LESS
;3C	BN1	XX	SHORT BRANCH IF EF1 = 0
;3D	BN2	XX	SHORT BRANCH IF EF2 = 0
;3E	BN3	XX	SHORT BRANCH IF EF3 = 0
;3F	BN4	XX	SHORT BRANCH IF EF4 = 0
;4n	LDA	Rn	LOAD ADVANCE	D = M(Rn); Rn = Rn + 1
;5n	STR	Rn	STORE VIA N	M(Rn) = D
;60	IRX		INCREMENT REG X	RX = RX + 1
;6n	OUT	n	OUTPUT n	BUS = M(RX); RX = RX + 1
;68
;69	INP	n	INPUT n		M(RX) = BUS; D = BUS
;70	RET		RETURN		(X,P) = M(RX); RX = RX + 1; IE = 1
;71	DIS		DISABLE		(X,P) = M(RX); RX = RX + 1; IE = 0
;72	LDXA		LOAD VIA X AND ADVANCE		D = M(RX); RX = RX + 1
;73	STXD		STORE VIA X AND DECREMENT	M(RX) = D; RX = RX - 1
;74	ADC		ADD WITH CARRY		DF, D = M(RX) + D + DF
;75	SDB		SUBTRACT D WITH BORROW	DF, D = M(RX) - D - /DF
;76	SHRC		SHIFT RIGHT WITH CARRY
;	RSHR		RING SHIFT RIGHT
;77	SMB		SUBTRACT MEMORY WITH BORROW	DF,D = D - M(RX) - /DF
;78	SAV		SAVE M(RX) = T
;79	MARK		PUSH X, P TO STACK	T = X,P; M(R2) = T; X = P; R2 = R2 - 1
;7A	REQ		RESET Q		Q = 0
;7B	SEQ		SET Q		Q = 1
;7C	ADCI	XX	ADD WITH CARRY, IMMEDIATE	DF, D = M(RP) + D + DF; RP = RP + 1
;7D	SDBI	XX	SUBTRACT D WITH BORROW, IMMEDIATE DF, D = M(RP) - D - /DF; RP = RP + 1
;7E	SHLC		SHIFT LEFT WITH CARRY
;	RSHL		RING SHIFT LEFT
;7F	SMBI	XX	SUBTRACT MEMORY WITH BORROW, IMMEDIATE DF, D = D - M(RP) - /DF; RP = RP + 1
;8n	GLO	Rn	GET LOW REG N	D = Rn.0
;9n	GHI	Rn	GET HIGH REG N	D = Rn.1
;An	PLO	Rn	PUT LOW REG N	Rn.0 = D
;Bn	PHI	Rn	PUT HIGH REG N	Rn.1 = D
;C0	LBR	XX XX	LONG BRANCH	RP.1 = M(RP); RP.0 = M(RP + 1)
;C1	LBQ	XX XX	IF Q = 1 THEN RP.1 = M(RP); RP.0 = M(RP + 1)
;C2	LBZ	XX XX	IF D = 0 THEN RP.1 = M(RP); RP.0 = M(RP + 1)
;C3	LDF	XX XX	IF DF = 1 THEN RP.1 = M(RP); RP.0 = M(RP + 1)
;C4	NOP		No Operation
;C5	LSNQ		IF Q = 0 THEN RP = RP+2
;C6	LSNZ		IF D <> 0 THEN RP = RP+2
;C7	LSNF		IF DF = 0 THEN RP = RP+2
;C8	NLBR		RP = RP+2
;C8	LSKP		RP = RP+2
;C9	LBNQ	XX XX	IF Q = 0 THEN RP.1 = M(RP); RP.0 = M(RP + 1)
;CA	LBNZ	XX XX	IF D <> 0 THEN RP.1 = M(RP); RP.0 = M(RP + 1)
;CB	LDNF	XX XX	IF DF = 0 THEN RP.1 = M(RP); RP.0 = M(RP + 1)
;CC	LSIE		IF IE = 1 THEN RP = RP+2
;CD	LSQ		IF Q = 1 THEN RP = RP+2
;CE	LSZ		IF D = 0 THEN RP = RP+2
;CF	LSDF		IF DF = 1 THEN RP = RP+2
;Dn	SEP	n	SET P	P=n
;En	SEX	n	SET X	X=n
;F0	LDX		LOAD VIA X	D = M(RX)
;F1	OR		OR		D = M(RX) OR D
;F2	AND		AND		D = M(RX) AND D
;F3	XOR		EXCLUSIVE OR	D = M(RX) XOR D
;F4	ADD		ADD		DF, D = M(RX) + D
;F5	SD		SUBTRACT D	DF, D = M(RX) - D
;F6	SHR		SHIFT D RIGHT	DF = LSB(D); MSB(D) = 0
;F7	SM		SUBTRACT MEMORY	DF,D = D - M(RX)
;F8	LDI	XX	LOAD IMMEDIATE	D = M(RP); RP = RP + 1
;F9	ORI	XX	OR IMMEDIATE	D = M(RP) OR D; RP = RP + 1
;FA	ANI	XX	AND IMMEDIATE	D = M(RP) AND D; RP = RP + 1
;FB	XRI	XX	EXCLUSIVE OR IMMEDIATE	D = M(RP) XOR D; RP = RP + 1
;FC	ADI	XX	ADD IMMEDIATE		DF, D = M(RP) + D; RP = RP + 1
;FD	SDI	XX	SUBTRACT D IMMEDIATE	DF, D = M(RP) - D; RP = RP + 1
;FE	SHL		SHIFT D LEFT		DF = MSB(D); LSB(D) = 0
;FF	SMI	XX	SUBTRACT MEMORY IMMEDIATE	DF, D = D - M(RP); RP = RP + 1
;			DMA IN	M(R0) = BUS; R0 = R0 + 1
;			DMA OUT BUS = M(R0); R0 = R0 + 1
;			INTERRUPT T = X,P; IE = 0; P = 1; X = 2
;
;
;'Mnem. 'Op'F'Description                 'Notes                '
;'------+--+-+----------------------------+---------------------'
;'ADC   '74'*'Add with Carry              '{DF,D}=mx+D+DF       '
;'ADCI i'7C'*'Add with Carry Immediate    '{DF,D}=mp+D+DF,p=p+1 '
;'ADD   'F4'*'Add                         '{DF,D}=mx+D          '
;'ADI  i'FC'*'Add Immediate               '{DF,D}=mp+D,p=p+1    '
;'AND   'F2'*'Logical AND                 'D={mx}&D             '
;'ANI  i'FA'*'Logical AND Immediate       'D={mp}&D,p=p+1       '
;'B1   a'34'-'Branch if EF1               'If EF1=1 BR else NBR '
;'B2   a'35'-'Branch if EF2               'If EF2=1 BR else NBR '
;'B3   a'36'-'Branch if EF3               'If EF3=1 BR else NBR '
;'B4   a'37'-'Branch if EF4               'If EF4=1 BR else NBR '
;'BDF  a'33'-'Branch if DF                'If DF=1 BR else NBR  '
;'BGE  a'33'-'Branch if Greater or Equal  'See BDF              '
;'BL   a'38'-'Branch if Less              'See BNF BR else NBR  '
;'BM   a'38'-'Branch if Minus             'See BNF              '
;'BN1  a'3C'-'Branch if Not EF1           'If EF1=0 BR else NBR '
;'BN2  a'3D'-'Branch if Not EF2           'If EF2=0 BR else NBR '
;'BN3  a'3E'-'Branch if Not EF3           'If EF3=0 BR else NBR '
;'BN4  a'3F'-'Branch if Not EF4           'If EF4=0 BR else NBR '
;'BNF  a'38'-'Branch if Not DF            'If DF=0 BR else NBR  '
;'BNQ  a'39'-'Branch if Not Q             'If Q=0 BR else NBR   '
;'BNZ  a'3A'-'Branch if D Not Zero        'If D=1 BR else NBR   '
;'BPZ  a'33'-'Branch if Positive or Zero  'See BDF              '
;'BQ   a'31'-'Branch if Q                 'If Q=1 BR else NBR   '
;'BR   a'30'-'Branch                      'pl=mp                '
;'BZ   a'32'-'Branch if D Zero            'If D=0 BR else NBR   '
;'DEC  r'2N'-'Decrement register N        'n=n-1                '
;'DIS   '71'-'Disable                     '{X,P}=mx,x=x+1,IE=0  '
;'GHI  r'9N'-'Get High register N         'D=nh                 '
;'GLO  r'8N'-'Get Low register N          'D=nl                 '
;'IDL   '00'-'Idle (wait for DMA or int.) 'Bus=m0               '
;'INC  r'1N'-'Increment register N        'n=n+1                '
;'INP  d'6N'-'Input (N=d+8=9-F)           'mx=Bus,D=Bus,Nlines=d'
;'IRX   '60'-'Increment register X        'x=x+1                '
;'LBDF a'C3'-'Long Branch if DF           'If DF=1 LBR else LNBR'
;'LBNF a'C8'-'Long Branch if Not DF       'If DF=0 LBR else LNBR'
;'LBNQ a'C9'-'Long Branch if Not Q        'If Q=0 LBR else LNBR '
;'LBNZ a'CA'-'Long Branch if D Not Zero   'If D=1 LBR else LNBR '
;'LBQ  a'C1'-'Long Branch if Q            'If Q=1 LBR else LNBR '
;'LBR  a'C0'-'Long Branch                 'p=mp                 '
;'LBZ  a'C2'-'Long Branch if D Zero       'If D=0 LBR else LNBR '
;'LDA  r'4N'-'Load advance                'D=mn,n=n+1           '
;'LDI  i'F8'-'Load Immediate              'D=mp,p=p+1           '
;'LDN  r'0N'-'Load via N (except N=0)     'D=mn                 '
;'LDX   'F0'-'Load via X                  'D=mx                 '
;'LDXA  '72'-'Load via X and Advance      'D=mx,x=x+1           '
;'LSDF  'CF'-'Long Skip if DF             'If DF=1 LSKP else NOP'
;'LSIE  'CC'-'Long Skip if IE             'If IE=1 LSKP else NOP'
;'LSKP  'C8'-'Long Skip                   'See NLBR             '
;'LSNF  'C7'-'Long Skip if Not DF         'If DF=0 LSKP else NOP'
;'LSNQ  'C5'-'Long Skip if Not Q          'If Q=0 LSKP else NOP '
;'LSNZ  'C6'-'Long Skip if D Not Zero     'If D=1 LSKP else NOP '
;'LSQ   'CD'-'Long Skip if Q              'If Q=1 LSKP else NOP '
;'LSZ   'CE'-'Long Skip if D Zero         'If D=0 LSKP else NOP '
;'MARK  '79'-'Push X,P to stack  (T={X,P})'m2={X,P},X=P,r2=r2-1 '
;'NBR   '38'-'No short Branch (see SKP)   'p=p+1                '
;'NLBR a'C8'-'No Long Branch (see LSKP)   'p=p+2                '
;'NOP   'C4'-'No Operation                'Continue             '
;'OR    'F1'*'Logical OR                  'D={mx}vD             '
;'ORI  i'F9'*'Logical OR Immediate        'D={mp}vD,p=p+1       '
;'OUT  d'6N'-'Output (N=d=1-7)            'Bus=mx,x=x+1,Nlines=d'
;'PLO  r'AN'-'Put Low register N          'nl=D                 '
;'PHI  r'BN'-'Put High register N         'nh=D                 '
;'REQ   '7A'-'Reset Q                     'Q=0                  '
;'RET   '70'-'Return                      '{X,P}=mx,x=x+1,IE=1  '
;'RSHL  '7E'*'Ring Shift Left             'See SHLC             '
;'RSHR  '76'*'Ring Shift Right            'See SHRC             '
;'SAV   '78'-'Save                        'mx=T                 '
;'SDB   '75'*'Subtract D with Borrow      '{DF,D}=mx-D-DF       '
;'SDBI i'7D'*'Subtract D with Borrow Imm. '{DF,D}=mp-D-DF,p=p+1 '
;'SD    'F5'*'Subtract D                  '{DF,D}=mx-D          '
;'SDI  i'FD'*'Subtract D Immediate        '{DF,D}=mp-D,p=p+1    '
;'SEP  r'DN'-'Set P                       'P=N                  '
;'SEQ   '7B'-'Set Q                       'Q=1                  '
;'SEX  r'EN'-'Set X                       'X=N                  '
;'SHL   'FE'*'Shift Left                  '{DF,D}={DF,D,0}<-    '
;'SHLC  '7E'*'Shift Left with Carry       '{DF,D}={DF,D}<-      '
;----------------------------------------------------------------
;----------------------------------------------------------------
;'Mnem. 'Op'F'Description                 'Notes                '
;'------+--+-+----------------------------+---------------------'
;'SHR   'F6'*'Shift Right                 '{D,DF}=->{0,D,DF}    '
;'SHRC  '76'*'Shift Right with Carry      '{D,DF}=->{D,DF}      '
;'SKP   '38'-'Short Skip                  'See NBR              '
;'SMB   '77'*'Subtract Memory with Borrow '{DF,D}=D-mx-{~DF}    '
;'SMBI i'7F'*'Subtract Mem with Borrow Imm'{DF,D}=D-mp-~DF,p=p+1'
;'SM    'F7'*'Subtract Memory             '{DF,D}=D-mx          '
;'SMI  i'FF'*'Subtract Memory Immediate   '{DF,D}=D-mp,p=p+1    '
;'STR  r'5N'-'Store via N                 'mn=D                 '
;'STXD  '73'-'Store via X and Decrement   'mx=D,x=x-1           '
;'XOR   'F3'*'Logical Exclusive OR        'D={mx}.D             '
;'XRI  i'FB'*'Logical Exclusive OR Imm.   'D={mp}.D,p=p+1       '
;'      '  '-'Interrupt action            'T={X,P},P=1,X=2,IE=0 '
;'------+--+-+--------------------------------------------------'
;'      '??' '8-bit hexadecimal opcode                          '
;'      '?N' 'Opcode with register/device in low 4/3 bits       '
;'      '  '-'DF flag unaffected                                '
;'      '  '*'DF flag affected                                  '
;'-----------+--------------------------------------------------'
;' mn        'Register addressing                               '
;' mx        'Register-indirect addressing                      '
;' mp        'Immediate addressing                              '
;' R( )      'Stack addressing (implied addressing)             '
;'-----------+--------------------------------------------------'
;'DFB n(,n)  'Define Byte                                       '
;'DFS n      'Define Storage block                              '
;'DFW n(,n)  'Define Word                                       '
;'-----------+--------------------------------------------------'
;' D         'Data register (accumulator, 8-bit)                '
;' DF        'Data Flag (ALU carry, 1-bit)                      '
;' I         'High-order instruction digit (4-bit)              '
;' IE        'Interrupt Enable (1-bit)                          '
;' N         'Low-order instruction digit (4-bit)               '
;' P         'Designates Program Counter register (4-bit)       '
;' Q         'Output flip-flop (1-bit)                          '
;' R         '1 of 16 scratchpad Registers(16-bit)              '
;' T         'Holds old {X,P} after interrupt (X high, 8-bit)   '
;' X         'Designates Data Pointer register (4-bit)          '
;'-----------+--------------------------------------------------'
;' mn        'Memory byte addressed by R(N)                     '
;' mp        'Memory byte addressed by R(P)                     '
;' mx        'Memory byte addressed by R(X)                     '
;' m?        'Memory byte addressed by R(?)                     '
;' n         'Short form for R(N)                               '
;' nh        'High-order byte of R(N)                           '
;' nl        'Low-order byte of R(N)                            '
;' p         'Short form for R(P)                               '
;' pl        'Low-order byte of R(P)                            '
;' r?        'Short form for R(?)                               '
;' x         'Short form for R(X)                               '
;'-----------+--------------------------------------------------'
;' R(N)      'Register specified by N                           '
;' R(P)      'Current program counter                           '
;' R(X)      'Current data pointer                              '
;' R(?)      'Specific register                                 '
;'-----------+--------------------------------------------------'
;' a         'Address expression                                '
;' d         'Device number (1-7)                               '
;' i         'Immediate expression                              '
;' n         'Expression                                        '
;' r         'Register (hex digit or an R followed by hex digit)'
;'-----------+--------------------------------------------------'
;' +         'Arithmetic addition                               '
;' -         'Arithmetic subtraction                            '
;' *         'Arithmetic multiplication                         '
;' /         'Arithmetic division                               '
;' &         'Logical AND                                       '
;' ~         'Logical NOT                                       '
;' v         'Logical inclusive OR                              '
;' .         'Logical exclusive OR                              '
;' <-        'Rotate left                                       '
;' ->        'Rotate right                                      '
;' { }       'Combination of operands                           '
;' ?         'Hexadecimal digit (0-F)                           '
;' -->       'Input pin                                         '
;' <--       'Output pin                                        '
;' <-->      'Input/output pin                                  '
;----------------------------------------------------------------


;RAM ALLOCATION
	.ORG 0FFFFh
SD_CARD_REG

	.ORG 0C000h

SD_RAM_BUFFER	.DS	512	;SECTOR BUFFER  ;MUST start at xx00
SD_DIR_LIST	.DS	12*256	;Directory Listing for sorting

	
	.ORG 0FA00h
VIDEO_PAGE1	.DS	256
VIDEO_PAGE2	.DS	256
VIDEO_PAGE3	.DS	256

	.ORG 0FD00h
FULLPATH	.DS	256	;DIRECTORY NAME (GROWS WITH SUBDIRECTORIES)
;SPARE		.DS	128	;
;STACK		.DS	128

	.ORG 0FF00h
VIDEO_PAGE	.DS	1	;7F00 MUST bet at xx00h, low byte is used to clear R0
PRINT_PAGE	.DS	1
GH_ADDR		.DS	2	;HEX File, address of record
GH_ERR_CNT	.DS	1	;HEX File, Count of ERRORS
GH_FLAGS	.DS	1	;HEX File, Flag for EOF encountered (MUST FOLLOW GH_ERR_CNT)
GH_START_ADDR	.DS	2	;HEX File, Start address given in 05 record type


SD_PARAM_CMD	.DS	1	;Must be location before SD_PARAM
SD_PARAM	.DS	4	;This 32 bit value is in BIG Endian for Sending to SD Card
SDC_STATUS	.DS	1	;Must be location after SD_PARAM

SD_CARD_TYPE	.DS	1	;7F10

SD_PART_TYPE	.DS	1	;Partition type

				;8 BYTES FROM MBR
SD_PART_BASE	.DS	4	;SD PARTITION STARTING RECORD
SD_PART_SIZE	.DS	4	;SD PARTITION SIZE (Must follow SD_PART_BASE)

				;10 BYTES FROM PARTION RECORD
BYTE_P_SEC	.DS	2	;Bytes per Sector (Almost always 512)
SEC_PER_CLUS	.DS	1	;
RESERVED_SEC	.DS	2	;
FAT_COPIES	.DS	1	;
ROOTDIR_SIZE	.DS	2	;7F20
FILESYS_SEC	.DS	4	;2 BYTES CHECKED FOR 0, OR 4 BYTES FROM SEC+20

HIDDEN_SEC	.DS	4	;
SEC_PER_FAT	.DS	2	;7F2A
FAT1START	.DS	4	;7F2C Calculated Sector to FAT1
DIR_SECTOR	.DS	4	;7F30 Calculated Sector to Root Directory
DATASTART	.DS	4	;Calculated Sector to Data Area
SEC_PTR		.DS	4	;7F38 Sector Pointer, general use variable that holds the last sector read
SEC_IDX		.DS	4	;Incrementing Index for Sectors (DIR or FILES)
FILENAME	.DS	8	;7F40 File Name
FILEEXT		.DS	3	;File Extension
DIR_SECTORS	.DS	1	;Directory Entry Size (pre loads SECTORS_REMAIN)
TEMP32		.DS	4	;7F4C


;SDFCB:
FNAME		.DS	11	;7F50 File name 12 CHARS for multi use
FATTRIB		.DS	1	;File Attribute
FCLUS0		.DS	2	;7F5C First Cluster of File as given by the Directory Entry.
FSIZE		.DS	4	;7F62 File Size
CCLUS		.DS	2	;Current Cluster, set to FClus0, then updated with FAT
DCLUS		.DS	2	;Directory Cluster
FILE_COUNT	.DS	1	;

SECTORS_REMAIN	.DS	1	;7F72 Count down sectors read in each cluster

READ_RAM_SUB	.DS	4	;Subroutines in RAM for modification
WRITE_RAM_SUB	.DS	4	;MUST FOLLOW READ_RAM
PRINT_RAM_SUB	.DS	4	;MUST FOLLOW WRITE_RAM
DIVIDE_SUB	.DS	4
MOD_SUB		.DS	4	;
PUT_CHAR_SUB	.DS	4   	;
SELECT_DEFAULT	.DS	4
READ_SHADOW_RAM	.DS	8	;
FILE_OUTPUT_SUB	.DS	4
FILE_EOF_SUB	.DS	4	;
FILE_POS	.DS	4	;Count of location through the file
PB1LEN		.DS	1	;Length of first line (May be less than 10h)
FILE_TYPE	.DS	1	;ASC, HEX OR BINARY (1, 2, OR 3)
LINE_SWITCHES	.DS	1	;R=BOOT RAM (80)
COMMAND		.DS	1	;First letter of command

SPARE		.DS	1

VOLUME_NAME	.DS	11

CONTINOUS	.DS	1	;Flag to indicate continous display of file/memory
	
				;Cursor position (Line/Pixel Position)
PIXIE_ROW	.DS	1	;ROW = 0, 1, 2, 3, 4.  
PIXIE_COL	.DS	1	;POS = 0 to 63 (PIXEL POSITION)

MODMASK		.DS	1	;Mask for getting remainder when using Shift Divide.
DF_SHIFTCNT	.DS	1	;Count of shifts needed for divide

CMD_PARAM	.DS	4	;Parameter entered in Command Line
SEC_READ_PTR	.DS	4	;7FA3 Parameter entered in Command Line
DEC_STR		.DS	10
DIR_BUFF_PTR	.DS	2
DISPLAY_FORMAT	.DS	1	;
CURSOR		.DS	1

COMMAND_LINE	.DS	1	;Must be at end, code checks roll-over to xx00 for EOL
		.IF (0FFFFh-$) < 20h  
		!!!COMMAND-LINE-BUFFER-TOO-SMALL
		.ENDIF	  		  

        .END
	