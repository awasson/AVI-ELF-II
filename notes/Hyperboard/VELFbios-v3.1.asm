; V-ELF Bios, version 3.1 - Aug 28, 2012
;
;Revsions:
; 1.0 - Original draft - Aug 2003
; 2.0 - Released version - Aug 2003
; 3.0 - Added operation notes as comments to the file - Aug 25, 2010
; 3.1 - Added this Revision listing and dates - Aug 28, 2012
; 3.1 - Added Tape IN/OUT circuit to hardware - Aug 28, 2012
; 3.1 - Created write up, schematic and board layout files - Aug 28, 2012
;
;Decription:	The BIOS/ROM chip that runs the V-ELF.
;
; The V-ELF is a combination of the COSMAC VIP and COSMAC ELF systems (many thanks to Joseph Weisbecker).
;
; With the flip of a switch, the V-ELF behaves like either the COSMAC ELF or VIP.
;
; In ELF mode:
;  32K of RAM is mapped to 0x0000 to 0x7FFF
;  32K of ROM is mapped to 0x8000 to 0xFFFF
;
; The system doesn't do much on it's own and requires you to enter a
; program via the input switches or execute what ever program has
; been put/left in RAM from the VIP Monitor or VELF Bios ROM.
;
; In VIP mode:
;  32K of RAM is mapped out until A15 goes high (a Long Branch to 0x8200 does this)
;  32K of ROM is mapped to both 0x0000 to 0x7FFF AND 0x8000 to 0xFFFF
;
; Here, execution starts in the ROM which upon reset (ie RUN=0) get's mapped to 0x0000.
; The first instruction is a Long Branch to the ROM using the upper 32K address.
; With A15 high during a Memory Read cycle, the RS flipflop clears the remapping of ROM
; and allows the RAM to be accessed in the lower 32K region.  This clever technique was used by
; the COSMAC VIP and it fits the demand here to allow the COSMAC ELF and it's programs to
; use the RAM in the lower 32K region.
;
; Execution goes directly to the VElf Bios at 0x8200 where the VElf starts the talking through
; RS232 (Q for TXD, EF2 for RXD) by sending it's Menu at 9600,N,8,1
;
;  VELF MENU:	"COSMAC ELF says Hello (v3.1)"
;   		" [D] Dump, [E] Enter, [R] Run ? "
;
; Here, you may talk to your ELF via your terminal program.
; D-Dumps Memory 1 page at a time, Enter an address, <Enter> dumps next page, <Esc> to quit.
; E-Enters Data into the RAM, Enter an address, Enter Data, <Enter> to next byte, <Esc> to quit.
; R-Runs at what ever address you select, Enter an address.
; Or pressing the "IN" button will cause the VElf to execute the VIP monitor or Load a program into RAM from ROM.
;
; What's not shown on this menu is the ability to upload a .hex file!  Just go ahead and do a text
; upload of your .hex file.  The ":" character will trigger the interpretation of the .hex line.
;
;  Here's a typical hex file line:
;   :1000000090B1B2B3B4F82DA3F83FA2F811A1D37206
;   iCCAddrRT----------DATA------------------CS
;
; The : triggers the interpretation of the line.
; The next two digits (10=16 bytes) give the count of bytes in that line
; The next four digits (0000) sets the start address of the data bytes to come
; The next two digits is the record type, 00 for data, 01 for end of file (no other types are interpreted)
; The next 32 digits are the 16 data bytes in hex format
; The last two digits are the checksum, which is tested for errors.  Any errors are counted.
;
; After every line, the page counter is displayed on the HEX Display
; Upon the 01 record type, the ERRORS counter is displayed and the monitor returns to the menu.
;
; Pressing the IN button at any time (checked during the RS232 RXCHAR routine) will cause
; execution to go to the VIP monitor or preload a program from ROM into RAM.
; If the dipswitches are all off, then the VIP monitor program is loaded.
; Otherwise, the program number selected by the dipswitches is loaded into RAM from the BIOS ROM.
; See "pgmtable" for a list of loadable programs contained within this ROM.
;
; pgmtable
; 0x01 = Starship (as listed in part 4 of the COSMAC ELF - Popular Electronics Jully 1977 issue)
; 0x02 = SumFun (as listed in the VIP Games Manual)
; 0x03 = PinBall (as listed in the VIP Games Manual)
; 0x04 to 0xFF are not defined in this version.
;
; If the IN button is pressed with dipswitches all off, then VIP Monitor is started.
; The VIP Monitor requires you to hold down the "C" key to enter the Monitor program. Hold "C" while pressing IN button.
; If you do not hold down the C key, execution of code at 0000 will occur.
; Once the monitor program is entered, it tests to see how many pages of RAM are available, starting at 4K
; it then clears the last 80 bytes of ram in the last page of ram (0x0F00 in the VElf) for a Video Display.
; After you release the "C" button, you must enter a 4 digit starting address:  XXXX
; Then select what to do as follows:
; "0" to begin entering data into RAM, keep entering 2 digit hex values for consecutive RAM addresses
; "A" to view memory, any key displays the next byte
; "B" to read data from TAPE Drive (via EF2 line), enter the number of pages to READ
; "F" to write data to TAPE Drive (via Q line), enter the number of pages to WRITE
;
; My version of VElf does not use TAPE, you'll have to add the hardware required to interface your tape deck.
; New for version 3.1.  Tape IN/OUT circuit has been added so I can try loading/saving to TAPE now!
;
;
; Version 1, Beta version, never released.
; Version 2, Got everything running, so I think.
; Version 3, added the above notes to understand the system.
;
;

; RCA COSMAC VIP CDP18S711 Monitor ROM Listing
; disassembled by Lee A. Hart <leeahart@earthlink.net>
; Modified comments & added RS232 Routines 9600,N,8,1
; by Josh Bensadon
;
; Push input (EF4) at any time to enter original VIP ROM
;
;       The ROM is partially decoded to occupy all memory
;       from 8000-FFFFh. Execution normally begins after
;       Reset with P=0, X=0, R(0)=0000, and the address
;       inhibit latch set so the monitor ROM is also at
;       0000-7FFFh instead of RAM. Thus the 1802 begins
;       executing the monitor ROM code.
;
; register usage
;
;       R0 = 1861 video DMA pointer
;       R1 = 1861 interrupt handler PC
;       R2 = stack pointer
;       R3 = main PC
;       R4 = dismem subroutine PC
;       R5 = display subroutine PC
;       R6 = address pointer to read/write memory
;       R7 = getbyte subroutine PC
;       R8 = beeper timer (decremented by interrupt handler)
;       RA = bitmap table pointer
;       RC = key subroutine PC

	.MSFIRST	;when using .dw, save Most significant byte first (Big Endian)

        .org  8000h

	LBR ELFSTART

;	The following original code done in "rxchar" routine exit, if "IN" (EF4) is pressed, by call to "RomLoad"
;
;        ldi here1/256  ;set R2=8008     ;this code is found at XVipRom
;        phi r2
;        ldi here1%256
;        plo r2
;        sex r2
;        sep r2          ;make R2 the program counter

        .org  8003h	;VIP MONITOR PROGRAM
here1:
        sex r2
	ldi 0		;new code added to clear R0
	phi r0
	plo r0
        out 4           ;reset address inhibit latch (map RAM to 0000 area)
        .db  0
        out 2           ;set keyboard latch to monitor "C" Key
        .db  0Ch
        ldi 0FFh        ;test for high end of RAM
        plo r1
        ldi 0Fh
        phi r1          ;set R1=0FFF (4k; max RAM on VIP)
notram:
        ldi 0AAh        ;store AA
        str r1
        ldn r1          ;load it
        xri 0AAh        ;if it worked,
        bz  isram       ;  then R1 points to top of RAM
        ghi r1
        smi 4           ;else R1=R1-0400 (try 1k lower)
        bnf isram       ;if underflow, no RAM, continue anyway
        phi r1
        br  notram      ;if not 4k of RAM, then try 1k lower
isram:
        b3  monitor
			;if "C" key is not pressed,
        ghi r0          ;  set R0=0000
        plo r0
        sex r0          ;  set X=0, P=0,
        sep r0          ;  and go execute program at 0
        		;  R1=Last byte of RAM available (0FFF,0CFF,08FF or 04FF) (0FFF on VElf)
monitor:
        sex r1
clear10:                ;clear RAM from top=0xFF to 0xB0 of last page of ram (0FFF to 0FB0 on VElf)
        ldi 0           ;  clear a byte
        stxd            ;  decrement pointer
        glo r1
        xri 0AFh        ;  until address=0xAF
        bnz clear10

                        ;create RAM program to save registers
        ldi 0D2h        ;  push SEP R2 @rrAF
        stxd
        ldi 9Fh         ;  push GHI RF @rrAE
        str r1
        glo r1          ;point R0 to RAM program
        plo r0
        ghi r1
        phi r0
        ldi 0CFh	;R1=rrCF
        plo r1

        		;M(rrCF) = RF.1
        		;M(rrCE) = RE.1
        		;M(rrCD) = RD.1
        		;M(rrCC) = RC.1
        		;M(rrCB) = RB.1
        		;M(rrCA) = RA.1
        		;M(rrC9) = R9.1
        		;M(rrC8) = R8.1
        		;M(rrC7) = R7.1
        		;M(rrC6) = R6.1
        		;M(rrC5) = R5.1
        		;M(rrC4) = R4.1
        		;M(rrC3) = R3.1

savereg:
        sep r0          ;call the RAM program
        stxd            ;push register contents it returns and dec X
        dec r0
        dec r0          ;point R0 to RAM program again
        lda r0          ;decrement GHI Rx instruction
        smi 1
        dec r0          ;point R0 to RAM program again
        str r0
        xri 82h         ;if not down to GHI R2,
        bnz savereg     ;  then repeat

        ghi r2          ;change PC to R3 (R2 was PC)
        phi r3
        ldi here2%256
        plo r3
        sep r3
here2:
        ghi r0
        phi r2		;R2.1 = rr (top page of ram) (0F on VElf)
        phi rb		;RB.1 = rr (top page of ram) Page to load R0 with in video refresh
        phi rd		;RD.1 = rr (top page of ram)
        ldi 81h		;Set page of subroutines
        phi r1		;R1=81xx
        phi r4		;R4=81xx
        phi r5		;R5=81xx
        phi r7		;R7=81xx
        phi ra          ;RA=81xx
        phi rc		;RC=81xx
        ldi int%256
        plo r1          ;R1=8146 (1861 interrupt handler)
        ldi 0AFh
        plo r2          ;R2=rrAF
        ldi dismem%256
        plo r4          ;R4=81DD (display memory subroutine)
        ldi display%256
        plo r5          ;R5=81C6 (display hex char subroutine)
        ldi getbyte%256
        plo r7          ;R7=81BA (get hex byte subroutine)
        ldi keyfound%256
        plo rc          ;RC=81A1 (get key subroutine, Start at "KeyFound" since
        		;the C key was pressed to get to this point)

getaddr:
        sex r2
        inp 1           ;turn on 1861 TV display
        sep rc          ;wait until C key released
        sep r7          ;  get 1st key
        sep r7          ;  go back to get byte to shift and get 2nd key
        sep r7          ;  go back to get byte to OR the hex digits
        phi r6          ;save in R6.1
        sep r7          ;  get 1st key
        sep r7          ;  go back to get byte to shift and get 2nd key
        sep r7          ;  go back to get byte to OR the hex digits
        plo r6          ;save in R6.0
        sep r4          ;display address R6, and M(R6)
        sep rc          ;get a key
        phi re          ;  save it
        bz  mwrite      ;if "0", go to Memory Write command
        xri 10
        bz  mread       ;if "A", go to Memory Read command
        sep rc          ;get a key (count of pages to write/read to tape)
        plo re          ;  save it
        dec r2
        out 1           ;turn off TV
        ghi re          ;get saved key
        xri 0Bh
        bz  tread       ;if "B", go to Tape Read command
        ghi re          ;get saved key
        xri 0Fh         ;if anything but "F",
        bnz $           ;  loop forever
;
; twrite -- tape write command
;
        ldi beep%256    ;change RC to point to Beep subroutine
        plo rc
        ldi 40h		;write lead in 0x40xx bits (~16,000 bits)
        phi r9

twrite:			;write lead in loop
        ghi r3		;r3 = PC = 0x8098
        shr		;aka Clear DF flag
        sep rc          ;call Beep to write 0 bit
        dec r9
        ghi r9
        bnz twrite	;Loop ~16,000 times
twrite1:
        ldi 10h		;Reset Parity Counter (Counts 1's sent)
        plo r7
        ldi 8
        plo r9
        lda r6		;Get byte to write to Tape
        phi r7		;Hold Byte in R7.1
        ghi r3
        shl
        sep rc          ;call Beep to write a 1 bit             -SEND START BIT (1)  Inc R7
        glo r6		;Check for page boundary
        bnz twrite2
        dec re		;count down pages writen on every page boundary
twrite2:
        ghi r7		;Fetch Byte to write
        shr		;Shift out bit
        phi r7
        sep rc          ;call Beep to write a data bit          -SEND 8 DATA BITS    Inc R7 if DF=1
        dec r9		;decrement bit counter
        glo r9
        bnz twrite2	;loop back to write 8 bits
        inc r7		;Calculate ODD Parity  Counting start bit, Parity = 0 if count of 1's is ODD.
        glo r7
        shr
        sep rc          ;call Beep to write parity bit          -SEND PARITY BIT     
        glo re
        bnz twrite1	;loop back to write next byte until all pages are written
        sep rc          ;call Beep to write FINAL bit
tread6:
        inp 1           ;turn on TV display
        dec r6
        sep r4          ;display last byte written
        br  $           ;end; loop forever
;
; tread -- tape read command
;
tread:
        ldi tapein%256  ;change RC to point to tapein
        plo rc          ;  subroutine to read 1 bit
tread1:			;Lead In Loop
        ldi 10
        phi r9
tread2:
        sep rc          ;call TapeIn to read 1 bit

        bdf tread1	;Loop back while 1 (Lead IN)
        dec r9
        ghi r9
        bnz tread2
tread5:
        sep rc          ;call TapeIn to read 1 bit
        bnf tread5	;Loop back until we get START BIT (1)
        ldi 9
        plo 9		;Set Bit Counter
        plo 7		;Set Parity Counter
tread3:
        ghi r7		;Get Byte to assemble
        shrc		;Shift in READ bit
        phi r7		;Save Byte
        dec r9		;Count bits
        sep rc          ;call TapeIn to read Data & Parity bits
        glo r9
        bnz tread3	;Loop back to read 9 bits (Shifts start bit out)
        glo r7
        shr
        bdf tread4	;Jump if NO parity error
        seq		;else, SET Q to indicate ERROR
tread4:
        ghi r7		;Save BYTE
        str r6
        inc r6
        glo r6
        bnz tread5	;Test for Page boundary
        dec re		;Count down pages to read
        glo re
        bnz tread5	;Jump back until all pages are read.
        br  tread6      ;end; loop forever
;
; mread -- memory read command
;
mread:
        sep rc          ;get a key
        inc r6          ;increment address in R6
        sep r4          ;display address R6 and M(R6)
        br  mread       ;repeat forever
;
; mwrite -- memory write command
;
mwrite:
        sep r7          ;get keys, assemble into byte
        sep r7
        sep r7
        str r6
        sep r4          ;display address R6 and M(R6)
                        ;  (i.e. new contents of memory)
        inc r6          ;increment memory pointer

        br  mwrite      ;repeat forever

        .db  0,0,0,0     ;unused?
;
; index table -- converts hex digit into address in bitmap
;       table where that digit's bitmap begins.

        .org 8100h
index:
        .db  30h         ;"0" digit bitmap starting addr
        .db  39h         ;"1"
        .db  22h         ;"2"
        .db  2Ah         ;"3"
        .db  3Eh         ;"4"
        .db  20h         ;"5"
        .db  24h         ;"6"
        .db  34h         ;"7"
        .db  26h         ;"8"
        .db  28h         ;"9"
        .db  2Eh         ;"A"
        .db  18h         ;"B"
        .db  14h         ;"C"
        .db  1Ch         ;"D"
        .db  10h         ;"E"
        .db  12h         ;"F"
;
; bitmap table -- bit patterns to put on the screen to
;       display hex characters 0-F in a 5-high by 8-wide
;       format. Each pattern uses 5 consecutive bytes.
;       1's are bright, 0's are dark pixels. The patterns
;       overlap to save memory.
bitmap:
        .db  11110000b   ;top of "E"
        .db  10000000b
        .db  11110000b   ;top of "F"
        .db  10000000b
        .db  11110000b   ;top of "C"
        .db  10000000b
        .db  10000000b
        .db  10000000b
        .db  11110000b   ;top of "B"
        .db  01010000b
        .db  01110000b
        .db  01010000b
        .db  11110000b   ;top of "D"
        .db  01010000b
        .db  01010000b
        .db  01010000b
        .db  11110000b   ;top of "5"
        .db  10000000b
        .db  11110000b   ;top of "2"
        .db  00010000b
        .db  11110000b   ;top of "6"
        .db  10000000b
        .db  11110000b   ;top of "8"
        .db  10010000b
        .db  11110000b   ;top of "9"
        .db  10010000b
        .db  11110000b   ;top of "3"
        .db  00010000b
        .db  11110000b
        .db  00010000b
        .db  11110000b   ;top of "A"
        .db  10010000b
        .db  11110000b   ;top of "0"
        .db  10010000b
        .db  10010000b
        .db  10010000b
        .db  11110000b   ;top of "7"
        .db  00010000b
        .db  00010000b
        .db  00010000b
        .db  00010000b
        .db  01100000b   ;top of "1"
        .db  00100000b
        .db  00100000b
        .db  00100000b
        .db  01110000b
        .db  10100000b   ;top of "4"
        .db  10100000b
        .db  11110000b
        .db  00100000b
        .db  00100000b
;
; interrupt routine for 64x32 format (1 page display memory)
;
intret0:
        req             ;return with Q off
intret1:
        lda r2
        ret             ;<-return with interrupts enabled
int:                    ;->entry with P=R1
        dec r2          ;point to free location on stack
        sav             ;  push T
        dec r2
        str r2          ;  save D
        nop             ;3 cycles of NOP for sync
        inc r9
        ldi 0           ;reset DMA pointer to start of
        plo r0          ;  display RAM
        ghi rb
        phi r0
        sex r2          ;NOPs for timing
        sex r2          ;set D=line start address (6 cycles)
disp:
        glo r0
                        ;1861 displays a line (8 cycles)
        sex r2
        sex r2          ;reset line start address (6 cycles)
        dec r0
                        ;1861 displays line a 2nd time (8 cycles)
        plo r0
        sex r2          ;reset line start address (6 cycles)
        dec r0
                        ;1861 displays line a 3rd time (8 cycles)
        plo r0
        sex r2          ;reset line start address (6 cycles)
        dec r0
                        ;1861 displays line a 4th time (8 cycles)
        plo r0          ;set R0.0=line start address
        bn1 disp        ;loop 32 times

        ghi r8		;r8.1 is TIMER,  Counts down when set>0
        bz  disp1       ;if Zero, skip decrementing
        plo rb		;(Using rb.0, to avoid altering DF)
        dec rb          ;  else decrement beeper time remaining
        glo rb          ;    ...high byte
        phi r8
disp1:
        glo r8          ;    ...low byte
        bz  intret0     ;if beep time is zero, then return with Q off
        seq             ;  else return with Q on
        dec r8
        br  intret1

; beep -- output a 1-cycle square wave on Q
;       at 2 KHz if DF=0, or 0.8 KHz if DF=1.
;       Also increments R7.
;
beepx:
        sep r3          ;<-return
beep:
        ldi 10          ;2 KHz if DF=0
        bnf setq
        ldi 32          ;0.8 KHz if DF=1
        inc r7		;Parity Bit count the 1's
setq:
        seq             ;set Q    16 cycles
        phi rf          ;save delay length 16 cycles
beepl:
        smi 1           ;delay 16 clock cycles  @3.579/2 = 1.79Mhz = 0.558uSec
        bnz beepl	;      16 clock cycles, =(32*10+48)*0.558uSec=205uSec=(1/2 cycle of 2.44Khz) 
        		;                       =(32*32+48)*0.558uSec=598uSec=(1/2 cycle of 836hz)
        		;			@3.52/2 = 1.76Mhz = 0.568uSec
        		;      16 clock cycles, =(32*10+48)*0.568uSec=209uSec=(1/2 cycle of 2.39Khz) 
        		;                       =(32*32+48)*0.568uSec=609uSec=(1/2 cycle of 821hz)
        		
        bnq beepx       ;exit after low half cycle 16 cycles
        req             ;reset Q
        ghi rf		;fetch delay length
        br  beepl       ;delay again
;
; tapein -- cassette tape audio input; read one cycle.
;       If low frequency, returns DF=1 and increments R7.
;       If high frequency, returns DF=0.

tapeinx:
        sep r3          ;<-return
tapein:
        ldi 16          ;set timer
        bn2 $           ;wait for EF2=1 (EF2 pin low)
                        ;  (i.e. wait for rising edge)
tapein1:
        bn2 tapein2     ;wait 4 x 16 cycles and test EF2
        smi 1
        bnz tapein1     ;if it times out, is low frequency
        inc r7          ;  increment R7 Parity Counter
        ghi rc          ;  and set D=81h (to set DF)
tapein2:
        shl             ;shift high bit of D into DF
                        ;  if DF=1, is low freq
                        ;  if DF=0, is high freq
        b2  $           ;wait for EF2=0 (EF2 pin high)
                        ;  (i.e. low half of this cycle)
        br  tapeinx     ;  and exit
;
; get a key -- scans keypad, and returns when a key is found.
;       'Beeps' while key is down. Returns key (0-F) in D and
;       on the stack. Uses RC as its dedicated program counter.
key:
        sep r3          ;<-return
GETKEY:
        sex r2          ;->entry: scan keypad, return when found
        ghi rc
        plo rf          ;for n = 10h to 0:
keyn:
        dec rf          ;  decrement n
        dec r2
        glo rf          ;  set keypad latch to n
        str r2
        out 2           ;  is key = n?
        sex r2
        sex r2
        bn3 keyn        ;  until key found
keyfound:
        ldi 4           ;->enter with P=RC
        plo r8          ;set beep duration to 4/60 sec
        glo r8
        bnz $-1         ;wait for it to end
        ldi 4
        plo r8          ;keep beeping until key released
        b3  $-3         ;  (i.e. EF3 pin returns high)
        glo r8
        bq  $-3
        glo rf
        ani 0Fh         ;mask key to 0-F
        str r2          ;  and return it on the stack
        br  key

        .db  0,0,0,0     ;(unused)

; getbyte -- get 2 keys from the keypad, and assemble them
;       into a byte. Return the byte in D. Uses R7 as its
;       dedicated program counter.

        sep r3          ;<-return
getbyte:
        sep rc          ;->enter; get 1st key
        shl
        shl             ;shift it into high nibble
        shl
        shl
        plo re          ;save it
        sep rc          ;get 2nd key
        glo re
        or              ;combine them and return in D
        br  getbyte-1
;
; display -- display hex digit & advance pointer. On entry:
;       D = display table base addr + hex digit.
;       RD pointer to video RAM addr of top line of char.
;       Uses R5 as its dedicated program counter.

        sep r4          ;<-return
display:                ;->entry
        plo ra          ;point RA to display table + digit
        ldn ra          ;get starting addr of char gen.
        plo ra          ;point RA to top line bit pattern
        ldi 5           ;characters are 5 lines high
        plo rf          ;  RF.0=line counter
display1:
        lda ra          ;  get display pattern
        str rd          ;  put in video RAM
        glo rd          ;  add 8 to video RAM address
        adi 8           ;    to point to next line of char
        plo rd
        dec rf          ;  decrement line counter
        glo rf          ;  get line counter
        bnz display1    ;  loop unti last line done
        glo rd
        adi 0D9h        ;set RD back to original video RAM
        plo rd          ;  address +1 (points to next char)
        br  display-1   ;and return
;
; dismem -- display memory address and data in hex. On entry,
;       R2 (stack pointer) points to an occupied byte
;       R6 = address, and is pointing to data byte to display
;       Uses R4 as its dedicated program counter.

dismemx:
        sep r3          ;<-return
dismem:
        dec r2          ;->entry
        ldn r6          ;push data byte to display onto stack
        stxd
        glo r6          ;push low byte of address onto stack
        stxd
        ghi r6          ;store high byte of address on stack
        str r2
        ldi 6           ;display 6 hex digits
        plo re
        ldi 0D8h        ;RD=position in video RAM
        plo rd
dismem1:
        ldn r2          ;get hex byte from stack
        shr
        shr             ;shift out low nibble
        shr
        shr
        sep r5          ;display high nibble
        lda r2          ;pop hex byte from stack
        ani 0Fh         ;mask out high nibble
        sep r5          ;display low nibble
        glo re
        shr
        plo re
        bz  dismemx     ;if RE.0=0, exit
        bnf dismem1     ;if DF=0, repeat for another byte
                        ;(i.e. is address, which takes 2 bytes)
        inc rd          ;else move right 2 positions in video RAM
        inc rd          ;  to put space between address and data
        br  dismem1     ;  and go display 2 more digits (data byte)
        .db  1           ;checksum?

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
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************

; register usage
;
;       R1 = scratch used by TXMsg
;       R2 = stack pointer @7FFF
;       R3 = main PC
;       R4 = call subroutine PC
;       R5 = return subroutine PC
;       R6 = return address
;       R7 = Transmit Byte PC routine
;       R8 = Receive Byte PC routine
;       R9 = Receive Ascii Byte (2 ascii chars)
;	RC = Input control allowed
;	RD = Entered address
;       RE = scratch
;       RF = scratch

	.define call	sep r4	\	.dw
	.define retn	sep r5
	.define	tx_char	sep r7
	.define	rx_char	sep r8
	.define	rx_byte	sep r9
	.define	print	sep r4	\	.dw txmsg

	.org  8200h
ELFSTART:
	seq		;tx line high

	sex r2		;Set Stack Pointer
	ldi 7fh		;to 7f7f
	phi r2
	plo r2

        ldi callr/256
        phi r4
        phi r5
        phi r7
        phi r8
        phi r9

        ldi callr%256
        plo r4

        ldi retnr%256
        plo r5

        ldi txchar%256
        plo r7

        ldi rxchar%256
        plo r8

	ldi rxqbyte%256
	plo r9

	ldi mainloop/256
	phi r3
	ldi mainloop%256
	plo r3
	sep r3


;**********************************************************************
;Call Subroutine
;call with R2 pointing to free stack byte
;Pushes R6 to Stack
;Sets R6 to Return Address (2 bytes after Sep R4 call)
;Returns execution to R3
;----------------------------------------------------------------------
	sep r3	;go to called program
callr:	phi rf	;Save D
	sex r2	;X=Stack
	glo r6	;Push r6 to Stack, big endian
	stxd
	ghi r6
	stxd
	glo r3	;Fetch Unmodified Return Address
	plo r6
	ghi r3
	phi r6
	lda r6	;get subroutine address AND modify return address
	phi r3	;to skip inline data
	lda r6	;save call to address to R3
	plo r3
	ghi rf	;restore D
	br callr-1	;jump for SEP R4 re-entery


;**********************************************************************
;Return Subroutine
;Call with R2 pointing to free stack byte below return address
;Restores Return Address in R6 to R3
;Pops R6 from stack
;Returns execution to R3
;----------------------------------------------------------------------
	sep r3	;go to calling program
retnr:	phi rf	;Save D
	ghi r6	;Fetch Return Address
	phi r3	;back to R3
	glo r6
	plo r3
	inc r2	;Pop previous r6 from stack
	lda r2
	phi r6	;
	sex r2	;X=Stack
	ldx
	plo r6	;
	ghi rf	;restore D
	br retnr-1

;**********************************************************************
;Transmit Byte via Q connected to RS232 driver
;call with R3 being the previous PC
;Byte to send in D
;Returns with D unaffected
;re.1 = D
;Destroys re.0
;----------------------------------------------------------------------
        sep r3		;10.5
txchar:	phi re
	ldi 9		;9 bits to transmit (1 start + 8 data)
	plo re
	ghi re
	shl		;set start bit
	rshr		;DF=0

txcloop:
	bdf $+5		;10.5   jump to seq to send a 1 bit
	req		;11.5   send a 0 bit
	br $+5		;1      jump +5 to next shift
	seq		;11.5   send a 1 bit
	br $+2		;1      jump +2 to next shift (NOP for timing)
	rshr		;2      shift next bit to DF flag
	phi re		;3      save D in re.1
	DEC re		;4      dec bit count
	glo re		;5      get bit count
	bz txcret	;6      if 0 then all 9 bits (start and data) sent
	ghi re		;7      restore D
	NOP		;8.5    pause 1/2 time
	br txcloop	;9.5    loop back to send next bit
txcret:	ghi re		;7
	ghi re		;8
	ghi re		;9
	NOP		;10.5
	seq		;11.5 stop bit
	NOP		;1
	NOP		;2.5
	NOP		;4
	NOP		;5.5
	NOP		;7
	NOP		;8.5
	br txchar-1	;9.5

;**********************************************************************
;rx_char
;Receive Byte via EF2 connected to RS232 receiver
;Recieves 8 bits
;call with R3 being the previous PC
;Returns with Byte received in D and re.1
;Destroys re.0
;Starts original VIP ROM if EF4 input switch pressed
;----------------------------------------------------------------------
	sep r3
rxchar:	ldi 8		;start bit +7 bits from loop, last bit on returning
	plo re
	ldi 0
rxcw:			;wait for start bit
	bn4 $+4		;loop while high
	br  RomLoad
	bn2 rxcw	;each instr takes 9us, we need 104us = 11.5
			;delay 1/2 bit time to center samples
	NOP		;     Don't test for correct start bit
	NOP		;     it will work, if there's too much
	NOP		;     noise on the line, shorten the cable!
rxcloop:
	NOP		;10.5
	b2 $+6		;11.5 sample rx input bit
	ori 80h		;1
	br $+4		;2
	phi re		;1
	phi re		;2
	shr		;3
	phi re		;4
	DEC re		;5
	glo re		;6
	bz rxcret	;7
	ghi re		;8
	br  rxcloop	;9
rxcret:	ghi re		;8
	ghi re		;9
	NOP		;10.5
	b2 $+4		;11.5 sample last rx input bit
	ori 80h		;1
	phi re
	br rxchar-1



;**********************************************************************
;rx_byte
;Get Quick Byte  (call 3 times, because this routine sub-calls rxchar twice)
;call with R3 being the previous PC
;Recieves 2 characters and converts from ascii to hex
;----------------------------------------------------------------------
	sep r3	;return
rxqbyte: rx_char	;get 1st char
	ani 04Fh	;mask low nibble and alpha flag (40h)
	shl
	shl
	bnf rxq2
        adi 36		;9 shifted left twice

rxq2	shl
	shl
	str r2		;save to temp X location m(R(x))
	rx_char		;get 2nd char
	ani 04Fh	;mask low nibble and alpha flag (40h)
	shl
	shl
	bnf alphan
	adi 36		;9 shifted left twice
alphan	shr
	shr
	or		;or in 1st digit
	str r2		;save byte on stack to add
	ghi rb		;add into check sum
	add
	phi rb
	ldn r2		;restore byte
	br rxqbyte-1


;**********************************************************************
;Transmit Hex Byte in D
;----------------------------------------------------------------------
txbyte:	stxd
	shr
	shr
	shr
	shr
	call txhex
	irx
	LDX
	ani 0fh
;	call txhex
;	retn

;**********************************************************************
;Transmit Hex nibble in D
;----------------------------------------------------------------------
txhex:	smi 10		;d=n-10
	bm  txnumb
	adi 41h		;else if alpha
	tx_char
	retn

txnumb:	adi 10
	ori 30h
	tx_char
	retn

RomLoad	inp 4
	bz  XVipRom	;execute VIP ROM
	shl		;x2 for address words
	shl		;x2 for 2 address words
	plo rd		;Table must start at xx04
	ldi pgmtable/256 ;rD points to table
	phi rd

	ldi RLoop%256	;set up subroutine call
	plo r7		;in r7, routine copies 1 page

                ;set starting write address
	ldi 0	;Write to 0000
	plo rE
	phi rE	;rE points to destination

	lda rd	;get address of first 2 pages
	phi rc
	lda rd
	plo rc	;rC points to source

                ;call routine that writes 1 page twice
	sep r7	;Write 2 pages from first address
	sep r7

	lda rd	;get address of remaining memory
	phi rc
	lda rd
	plo rc	;rC points to source
RLoop1	sep r7
	ghi rE	;Test for end of RAM
	shl
	bnf RLoop1
	;Quiting TIME!


XVipRom: req 		;clear tx line
	b4 XVipRom	;loop while in button down,
			;so program starts with button up
	ldi here1/256  ;set R2=8003 as per Original VIP ROM
        phi r2
        ldi here1%256
        plo r2
        sep r2          ;make R2 the program counter

                ;Write 1 page
	sep r8	;Return control to previous PC
RLoop	lda rc	;read a source byte (and advance)
	str rE	;write a destination byte
	INC rE	;(and advance)
	glo rE	;check if page written yet
	bnz RLoop
	lbr RLoop-1 ;exit, leaving r7 ready for next call


;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
	.org 8303h
mainloop:

	print
	.text "\r\nVELF says \042Hello\042 (v3.1)\r\n"
	.text " [D] Dump, [E] Enter, [R] Run ? \000"

	ldi 0		;do not return control chars
	plo rc		;from inputbyte routine

	rx_char
        xri ':'
        bz  gethexfile
	ghi re
	ori 20h		;to lower case
	phi re
	xri 'e'
	bz  enter
	ghi re
	xri 'r'
	bz  lbr_execute
	ghi re
	xri 'd'
	bz  Dump
	br  mainloop

lbr_execute	lbr execute

;--------------------------------------- Dump
Dump
	print
	.text "Dump\000"

	call	inputaddress

dnextpage:
	call newline
	ldi 16		;16 rows
	plo rc
dnextline:
	ldi 16		;16 columns
	plo rb

	ghi rd		;display address     xxxx:
	call txbyte
	glo rd
	call txbyte
	ldi ':'
	tx_char

dnextchar:
	ldi ' '		;put space then byte
	tx_char
	lda rd
	call txbyte
	DEC rb
	glo rb
	bnz dnextchar

	call newline

	DEC rc
	glo rc
	bnz dnextline

	print
	.db "Enter or Esc\000"

redon:	rx_char
	xri 13
	bz  dnextpage
	ghi re
	xri 27
	bz mainloop
	ldi 7
	tx_char
	br redon

;--------------------------------------- Enter

enter	print
	.text "Enter\000"

	call inputaddress

enterloop1
	call newline
	ghi rd
	call txbyte
	glo rd
	call txbyte
	ldi 3
	call spaces

enterloop2
	ldn rd		;get byte and display
	call txbyte

	ldi ':'
	tx_char


	ldi 2
	plo rc		;allow control chars from inputbyte routine
	call uscore

	call inputbyte
	bdf  e_ctrl	;jump if control or bad char entered

	str rd
	INC rd
	glo rd
	ani 7
	bz enterloop1

	ldi 4
	call spaces
	br enterloop2

e_ctrl	xri 27
	bz mainloop
	call newline
	br enterloop1

;**********************************************************************
;**********************************************************************
;**********************************************************************
	.org 8400H-3
gethexfile
	ldi 0
	plo rb		;zero errors counter
	br ghdoline	;we already got the colon

			;wait for colon
ghwait:	rx_char
	xri ':'
	bnz ghwait

ghdoline:
	ldi 0
	phi rb		;zero check sum
	rx_byte		;call rx_byte 3 times, 1 to get 1st rx_char
	rx_byte		;2 to get 2nd rx_char
	rx_byte		;3 to compose them into 1 byte
	plo rc		;rc is byte counter

;	call txbyte

	rx_byte		;get high digits of address
	rx_byte
	rx_byte
	phi rd

;	call txbyte
			;get low digits of address
	rx_byte		;get high digits of address
	rx_byte
	rx_byte
	plo rd

;	call txbyte

	rx_byte		;get record type
	rx_byte
	rx_byte
	xri 1
	bz ghend	;if record type is 01 then end

;	xri 1
;	call txbyte


ghloop:			;get data
        rx_byte
	rx_byte
	rx_byte
	str rd		;save data

;	call txbyte

	INC rd		;advance
	DEC rc		;count down bytes in this line
	glo rc
	bnz ghloop

	ghi rd		;Display current page on HEX Display
	str r2
	out 4
	DEC r2

        rx_byte		;get check sum
	rx_byte
	rx_byte
	ghi rb
	bz ghwait
	INC rb
	glo rb
	bnz ghwait	;freeze errors at 255
	DEC rb
	br ghwait	;wait for next colon

ghend
	print
	.text " Errors=\000"
	glo rb
	call txbyte

	lbr mainloop

;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************
;**********************************************************************



;**********************************************************************
;----------------------------------------------------------------------
inputaddress
	print
	.text "\r\nAddress:\000"

	ldi 4		;do 4 underscores
	call uscore

	call inputbyte
	phi rd
	call inputbyte
	plo rd
	print
	.text "\r\n\000"
	retn

;**********************************************************************
;----------------------------------------------------------------------
inputbyte
	call inputhex
	bdf  inputbret	;jump if control char entered
	shl
	shl
	shl
	shl
	stxd		;save to temp X location m(R(x))
	call inputhex
	irx
	bdf  inputbret	;jump if control char entered
	or		;or in 1st digit
inputbret
	retn

;**********************************************************************
;----------------------------------------------------------------------
inputhex:			;get hex digit
        rx_char		;get rs232 byte
        phi rc
	call ishex
	tx_char
	glo rf
	shr		;Move valid hex to DF
	bdf  ih_ctrl_char
	retn

ih_ctrl_char
	glo rc
	bz  inputhex	;get another char if control not allowed
	ghi rc		;else, return control char
	retn

;**********************************************************************
;----------------------------------------------------------------------
uscore	plo rf
usloop1	print
	.text "_\000"
	smi 1
	bnz usloop1
	glo rf
usloop2	print
	.text "\033[D\000"
	smi 1
	bnz usloop2
	retn

;**********************************************************************
;----------------------------------------------------------------------
spaces	print
	.text " \000"
	smi 1
	bnz spaces
	retn

;**********************************************************************
;----------------------------------------------------------------------
hexout	str r2		;save to temp X location m(R(x))
	out 4
	DEC r2
	retn

;**********************************************************************
;----------------------------------------------------------------------
hexinp	inp 4
	call hexout
	retn


;**********************************************************************
;Execute RD
;----------------------------------------------------------------------
execute	print
	.text " Run\000"
	call	inputaddress
	ghi rd
	phi r0
	glo rd
	plo r0
	req
        ldi 0FFh        ;test for high end of RAM
        plo r1
        ldi 0Fh
        phi r1          ;set R1=0FFF (4k; max RAM on VIP)
	ldi 0
	plo r8		;disable tone
	sex r0
	sep r0

;**********************************************************************
;Transmit inline text message
;returns to instruction after last End-Of-String byte \000
;----------------------------------------------------------------------
txmsg:	phi rf	;Save D
txmlp	lda r6
	bz txmsgret
	tx_char
	br txmlp
txmsgret:
	ghi rf	;Restore D
	retn

;**********************************************************************
;New Line
;----------------------------------------------------------------------
newline	print		;newline
	.db "\r\n\000"
	retn


;**********************************************************************
;Is Hex?
;Call using DoSub
;D is byte to evaluate (n)
;re.1 is same byte (from rx_char), not affected for displaying ascii char
;Returns with D as orignal ascii char (or bell if bad hex char)
;rf.1 = Hex code shifted left 1 place.  if lsb is set means bad char
;----------------------------------------------------------------------
ishex:	smi 30h		;d=n-48
        bm  badhex	;jump if < 30h
        smi 10		;d=n-58
        bm  goodnumb	;jump if n is between 30h and 39h
        smi 7		;d=n-65
        bm  badhex	;jump if n is between 3Ah and 40h
        smi 6		;d=n-71
;	bm  goodalpha	;jump if n is between 41h and 46h
;	br  badhex
        bpz badhex	;jump if n is >46h

goodalpha
	adi 16
	br  good
goodnumb
	adi 10
good:	shl		;lsb=0
	plo rf		;save hex digit
	ghi re		;return orignal char
	retn

badhex	ldi 7		;return sound bell
	plo rf		;flag bad hex char (lsb=1)
	retn

	.org	$8504
pgmtable
	.dw	Starship	;starship not a chip 8 program,
	.dw	Starship	;just load it twice, does not matter
	.dw	Chip8
	.dw	SumFun
	.dw	Chip8
	.dw	PinBall

Starship
	.dw	$90B1
	.dw	$B2B3
	.dw	$B4F8
	.dw	$2DA3
	.dw	$F83F
	.dw	$A2F8
	.dw	$11A1
	.dw	$D372
	.dw	$7022
	.dw	$7822
	.dw	$52C4
	.dw	$C4C4
	.dw	$F800
	.dw	$B0F8
	.dw	$00A0
	.dw	$80E2
	.dw	$E220
	.dw	$A0E2
	.dw	$20A0
	.dw	$E220
	.dw	$A03C
	.dw	$1E30
	.dw	$0FE2
	.dw	$693F
	.dw	$2F6C
	.dw	$A437
	.dw	$333F
	.dw	$356C
	.dw	$5414
	.dw	$3033
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$7BDE
	.dw	$DBDE
	.dw	$0000
	.dw	$0000
	.dw	$4A50
	.dw	$DA52
	.dw	$0000
	.dw	$0000
	.dw	$425E
	.dw	$ABD0
	.dw	$0000
	.dw	$0000
	.dw	$4A42
	.dw	$8A52
	.dw	$0000
	.dw	$0000
	.dw	$7BDE
	.dw	$8A5E
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$0000
	.dw	$07E0
	.dw	$0000
	.dw	$0000
	.dw	$FFFF
	.dw	$FFFF
	.dw	$0006
	.dw	$0001
	.dw	$0000
	.dw	$0001
	.dw	$007F
	.dw	$E001
	.dw	$0000
	.dw	$0002
	.dw	$7FC0
	.dw	$3FE0
	.dw	$FCFF
	.dw	$FFFE
	.dw	$400F
	.dw	$0010
	.dw	$0480
	.dw	$0000
	.dw	$7FC0
	.dw	$3FE0
	.dw	$0480
	.dw	$0000
	.dw	$003F
	.dw	$D040
	.dw	$0480
	.dw	$0000
	.dw	$000F
	.dw	$0820
	.dw	$0480
	.dw	$7A1E
	.dw	$0000
	.dw	$0790
	.dw	$0480
	.dw	$4210
	.dw	$0000
	.dw	$187F
	.dw	$FCF0
	.dw	$721C
	.dw	$0000
	.dw	$3000
	.dw	$0010
	.dw	$4210
	.dw	$0000
	.dw	$73FC
	.dw	$0010
	.dw	$7BD0
	.dw	$0000
	.dw	$3000
	.dw	$3FF0
	.dw	$0000
	.dw	$0000
	.dw	$180F
	.dw	$C000
	.dw	$0000
	.dw	$0000
	.dw	$07F0
	.dw	$0000
	.dw	$0000

Chip8
	.dw	$91BB	;
	.dw	$FF01	;
	.dw	$B2B6	;
	.dw	$F8CF	;
	.dw	$A2F8	;
	.dw	$81B1	;
	.dw	$F846	;
	.dw	$A190	;
	.dw	$B4F8	;
	.dw	$1BA4	;
	.dw	$F801	;
	.dw	$B5F8	;
	.dw	$FCA5	;
	.dw	$D496	;
	.dw	$B7E2	;
	.dw	$94BC	;
	.dw	$45AF	;
	.dw	$F6F6	;
	.dw	$F6F6	;
	.dw	$3244	;
	.dw	$F950	;
	.dw	$AC8F	;
	.dw	$FA0F	;
	.dw	$F9F0	;
	.dw	$A605	;
	.dw	$F6F6	;
	.dw	$F6F6	;
	.dw	$F9F0	;
	.dw	$A74C	;
	.dw	$B38C	;
	.dw	$FC0F	;
	.dw	$AC0C	;
	.dw	$A3D3	;
	.dw	$301B	;
	.dw	$8FFA	;
	.dw	$0FB3	;
	.dw	$4530	;
	.dw	$4022	;
	.dw	$6912	;
	.dw	$D400	;
	.dw	$0001	;
	.dw	$0101	;
	.dw	$0101	;
	.dw	$0101	;
	.dw	$0101	;
	.dw	$0101	;
	.dw	$0100	;
	.dw	$0101	;
	.dw	$007C	;
	.dw	$7583	;
	.dw	$8B95	;
	.dw	$B4B7	;
	.dw	$BC91	;
	.dw	$EBA4	;
	.dw	$D970	;
	.dw	$9905	;
	.dw	$06FA	;
	.dw	$07BE	;
	.dw	$06FA	;
	.dw	$3FF6	;
	.dw	$F6F6	;
	.dw	$2252	;
	.dw	$07FA	;
	.dw	$1FFE	;
	.dw	$FEFE	;
	.dw	$F1AC	;
	.dw	$9BBC	;
	.dw	$45FA	;
	.dw	$0FAD	;
	.dw	$A7F8	;
	.dw	$D0A6	;
	.dw	$93AF	;
	.dw	$8732	;
	.dw	$F327	;
	.dw	$4ABD	;
	.dw	$9EAE	;
	.dw	$8E32	;
	.dw	$A49D	;
	.dw	$F6BD	;
	.dw	$8F76	;
	.dw	$AF2E	;
	.dw	$3098	;
	.dw	$9D56	;
	.dw	$168F	;
	.dw	$5616	;
	.dw	$308E	;
	.dw	$00EC	;
	.dw	$F8D0	;
	.dw	$A693	;
	.dw	$A78D	;
	.dw	$32D9	;
	.dw	$06F2	;
	.dw	$2D32	;
	.dw	$BEF8	;
	.dw	$01A7	;
	.dw	$46F3	;
	.dw	$5C02	;
	.dw	$FB07	;
	.dw	$32D2	;
	.dw	$1C06	;
	.dw	$F232	;
	.dw	$CEF8	;
	.dw	$01A7	;
	.dw	$06F3	;
	.dw	$5C2C	;
	.dw	$168C	;
	.dw	$FC08	;
	.dw	$AC3B	;
	.dw	$B3F8	;
	.dw	$FFA6	;
	.dw	$8756	;
	.dw	$12D4	;
	.dw	$9BBF	;
	.dw	$F8FF	;
	.dw	$AF93	;
	.dw	$5F8F	;
	.dw	$32DF	;
	.dw	$2F30	;
	.dw	$E500	;
	.dw	$42B5	;
	.dw	$42A5	;
	.dw	$D48D	;
	.dw	$A787	;
	.dw	$32AC	;
	.dw	$2A27	;
	.dw	$30F5	;
	.dw	$0000	;
	.dw	$0000	;
	.dw	$0000	;
	.dw	$0000	;
	.dw	$0045	;
	.dw	$A398	;
	.dw	$56D4	;
	.dw	$F881	;
	.dw	$BCF8	;
	.dw	$95AC	;
	.dw	$22DC	;
	.dw	$1256	;
	.dw	$D406	;
	.dw	$B8D4	;
	.dw	$06A8	;
	.dw	$D464	;
	.dw	$0A01	;
	.dw	$E68A	;
	.dw	$F4AA	;
	.dw	$3B28	;
	.dw	$9AFC	;
	.dw	$01BA	;
	.dw	$D4F8	;
	.dw	$81BA	;
	.dw	$06FA	;
	.dw	$0FAA	;
	.dw	$0AAA	;
	.dw	$D4E6	;
	.dw	$06BF	;
	.dw	$93BE	;
	.dw	$F81B	;
	.dw	$AE2A	;
	.dw	$1AF8	;
	.dw	$005A	;
	.dw	$0EF5	;
	.dw	$3B4B	;
	.dw	$560A	;
	.dw	$FC01	;
	.dw	$5A30	;
	.dw	$404E	;
	.dw	$F63B	;
	.dw	$3C9F	;
	.dw	$562A	;
	.dw	$2AD4	;
	.dw	$0022	;
	.dw	$8652	;
	.dw	$F8F0	;
	.dw	$A707	;
	.dw	$5A87	;
	.dw	$F317	;
	.dw	$1A3A	;
	.dw	$5B12	;
	.dw	$D422	;
	.dw	$8652	;
	.dw	$F8F0	;
	.dw	$A70A	;
	.dw	$5787	;
	.dw	$F317	;
	.dw	$1A3A	;
	.dw	$6B12	;
	.dw	$D415	;
	.dw	$8522	;
	.dw	$7395	;
	.dw	$5225	;
	.dw	$45A5	;
	.dw	$86FA	;
	.dw	$0FB5	;
	.dw	$D445	;
	.dw	$E6F3	;
	.dw	$3A82	;
	.dw	$1515	;
	.dw	$D445	;
	.dw	$E6F3	;
	.dw	$3A88	;
	.dw	$D445	;
	.dw	$0730	;
	.dw	$8C45	;
	.dw	$0730	;
	.dw	$84E6	;
	.dw	$6226	;
	.dw	$45A3	;
	.dw	$3688	;
	.dw	$D43E	;
	.dw	$88D4	;
	.dw	$F8F0	;
	.dw	$A7E7	;
	.dw	$45F4	;
	.dw	$A586	;
	.dw	$FA0F	;
	.dw	$3BB2	;
	.dw	$FC01	;
	.dw	$B5D4	;
	.dw	$4556	;
	.dw	$D445	;
	.dw	$E6F4	;
	.dw	$56D4	;
	.dw	$45FA	;
	.dw	$0F3A	;
	.dw	$C407	;
	.dw	$56D4	;
	.dw	$AF22	;
	.dw	$F8D3	;
	.dw	$738F	;
	.dw	$F9F0	;
	.dw	$52E6	;
	.dw	$07D2	;
	.dw	$56F8	;
	.dw	$FFA6	;
	.dw	$F800	;
	.dw	$7E56	;
	.dw	$D419	;
	.dw	$89AE	;
	.dw	$93BE	;
	.dw	$99EE	;
	.dw	$F456	;
	.dw	$76E6	;
	.dw	$F4B9	;
	.dw	$5645	;
	.dw	$F256	;
	.dw	$D445	;
	.dw	$AA86	;
	.dw	$FA0F	;
	.dw	$BAD4	;
	.dw	$0000	;
	.dw	$0000	;
	.dw	$0000	;
	.dw	$0000	;
	.dw	$0000	;
	.dw	$00E0	;
	.dw	$004B	;

SumFun
	.dw	$00E0	;
	.dw	$6A00	;
	.dw	$2262	;
	.dw	$6380	;
	.dw	$228A	;
	.dw	$6514	;
	.dw	$C003	;
	.dw	$C103	;
	.dw	$C203	;
	.dw	$6400	;
	.dw	$8404	;
	.dw	$8414	;
	.dw	$8424	;
	.dw	$225A	;
	.dw	$12A4	;
	.dw	$6390	;
	.dw	$2282	;
	.dw	$E4A1	;
	.dw	$122C	;
	.dw	$3600	;
	.dw	$76FF	;
	.dw	$121E	;
	.dw	$2294	;
	.dw	$6310	;
	.dw	$2282	;
	.dw	$229A	;
	.dw	$6380	;
	.dw	$228A	;
	.dw	$00E0	;
	.dw	$8A64	;
	.dw	$2262	;
	.dw	$75FF	;
	.dw	$4500	;
	.dw	$124A	;
	.dw	$6360	;
	.dw	$228A	;
	.dw	$120C	;
	.dw	$6412	;
	.dw	$F418	;
	.dw	$631A	;
	.dw	$228A	;
	.dw	$74FE	;
	.dw	$3400	;
	.dw	$124C	;
	.dw	$1258	;
	.dw	$6810	;
	.dw	$6913	;
	.dw	$2270	;
	.dw	$00EE	;
	.dw	$6830	;
	.dw	$6900	;
	.dw	$A2B0	;
	.dw	$FA33	;
	.dw	$F265	;
	.dw	$2270	;
	.dw	$00EE	;
	.dw	$F029	;
	.dw	$D895	;
	.dw	$7806	;
	.dw	$F129	;
	.dw	$D895	;
	.dw	$7806	;
	.dw	$F229	;
	.dw	$D895	;
	.dw	$00EE	;
	.dw	$73FF	;
	.dw	$3300	;
	.dw	$1282	;
	.dw	$00EE	;
	.dw	$F315	;
	.dw	$F307	;
	.dw	$3300	;
	.dw	$128C	;
	.dw	$00EE	;
	.dw	$6302	;
	.dw	$F318	;
	.dw	$00EE	;
	.dw	$6816	;
	.dw	$690A	;
	.dw	$F429	;
	.dw	$D895	;
	.dw	$00EE	;
	.dw	$660A	;
	.dw	$6380	;
	.dw	$2282	;
	.dw	$E4A1	;
	.dw	$122C	;
	.dw	$121E	;

PinBall
	.dw	$6E01	; vE=01
	.dw	$EEA1	; SKIP;vE NE KEY
	.dw	$120E	; GO m20E
	.dw	$6E02	; vE=02
	.dw	$EEA1	; SKIP;vE NE KEY
	.dw	$1212	; GO m212
	.dw	$1200	; GO m200
	.dw	$6800	; v8=00
	.dw	$1214	; GO m214
	.dw	$6801	; v8=01
	.dw	$6501	; v5=01
	.dw	$66E8	; v6=E8
	.dw	$A67F	; I=067F
	.dw	$0634	; MLS@0634
	.dw	$FC01	;
	.dw	$4C00	; SKIP;vC NE 00
	.dw	$1234	; GO m234
	.dw	$0634	; MLS@0634
	.dw	$F001	;
	.dw	$0603	; MLS@0603
	.dw	$122A	; GO m22A
	.dw	$05E3	; MLS@05E3
	.dw	$70FF	; v0+FF
	.dw	$3000	; SKIP;v0 EQ 00
	.dw	$1226	; GO m226
	.dw	$121A	; GO m21A
	.dw	$A68A	; I=068A
	.dw	$0642	; MLS@0642
	.dw	$A69A	; I=069A
	.dw	$0628	; MLS@0628
	.dw	$0501	; MLS@0501
	.dw	$4800	; SKIP;v8 NE 00
	.dw	$1246	; GO m246
	.dw	$0628	; MLS@0628
	.dw	$0501	; MLS@0501
	.dw	$A690	; I=0690
	.dw	$063A	; MLS@063A
	.dw	$F801	;
	.dw	$C107	; v1=RND
	.dw	$7103	; v1+03
	.dw	$063A	; MLS@063A
	.dw	$F101	;
	.dw	$063A	; MLS@063A
	.dw	$F101	;
	.dw	$4800	; SKIP;v8 NE 00
	.dw	$1262	; GO m262
	.dw	$6A01	; vA=01
	.dw	$252E	; DO m52E
	.dw	$2550	; DO m550
	.dw	$6A00	; vA=00
	.dw	$252E	; DO m52E
	.dw	$2550	; DO m550
	.dw	$6116	; v1=16
	.dw	$600A	; v0=0A
	.dw	$A67C	; I=067C
	.dw	$D013	; SHOW 3MI@v0v1
	.dw	$6019	; v0=19
	.dw	$D013	; SHOW 3MI@v0v1
	.dw	$6024	; v0=24
	.dw	$D013	; SHOW 3MI@v0v1
	.dw	$6033	; v0=33
	.dw	$D013	; SHOW 3MI@v0v1
	.dw	$6104	; v1=04
	.dw	$247C	; DO m47C
	.dw	$71FF	; v1+FF
	.dw	$3100	; SKIP;v1 EQ 00
	.dw	$127E	; GO m27E
	.dw	$2578	; DO m578
	.dw	$2592	; DO m592
	.dw	$6A00	; vA=00
	.dw	$6400	; v4=00
	.dw	$6E01	; vE=01
	.dw	$EEA1	; SKIP;vE NE KEY
	.dw	$12A8	; GO m2A8
	.dw	$24B4	; DO m4B4
	.dw	$FF07	; vF=TIME
	.dw	$3F00	; SKIP;vF EQ 00
	.dw	$128E	; GO m28E
	.dw	$2550	; DO m550
	.dw	$6F04	; vF=04
	.dw	$FF15	; TIME=vF
	.dw	$6101	; v1=01
	.dw	$8413	;
	.dw	$128E	; GO m28E
	.dw	$4400	; SKIP;v4 NE 00
	.dw	$2550	; DO m550
	.dw	$A69A	; I=069A
	.dw	$FA1E	; I=I+vA
	.dw	$F065	; v0:v0=MI
	.dw	$70FF	; v0+FF
	.dw	$0640	; MLS@0640
	.dw	$F055	; MI=V0:v0
	.dw	$2550	; DO m550
	.dw	$A693	; I=0693
	.dw	$0628	; MLS@0628
	.dw	$0301	; MLS@0301
	.dw	$6502	; v5=02
	.dw	$663F	; v6=3F
	.dw	$0603	; MLS@0603
	.dw	$12C8	; GO m2C8
	.dw	$6404	; v4=04
	.dw	$C707	; v7=RND
	.dw	$2572	; DO m572
	.dw	$A693	; I=0693
	.dw	$F065	; v0:v0=MI
	.dw	$F015	; TIME=v0
	.dw	$24B4	; DO m4B4
	.dw	$FF07	; vF=TIME
	.dw	$3F00	; SKIP;vF EQ 00
	.dw	$12D6	; GO m2D6
	.dw	$0603	; MLS@0603
	.dw	$12EA	; GO m2EA
	.dw	$12DC	; GO m2DC
	.dw	$A64D	; I=064D
	.dw	$F41E	; I=I+v4
	.dw	$F065	; v0:v0=MI
	.dw	$8400	; v4=v0
	.dw	$8C40	; vC=v4
	.dw	$05E3	; MLS@05E3
	.dw	$61EF	; v1=EF
	.dw	$8165	; v1=v1-v6
	.dw	$4F00	; SKIP;vF NE 00
	.dw	$1334	; GO m334
	.dw	$0608	; MLS@0608
	.dw	$13AA	; GO m3AA
	.dw	$A693	; I=0693
	.dw	$0634	; MLS@0634
	.dw	$F100	;
	.dw	$3103	; SKIP;v1 EQ 03
	.dw	$130A	; GO m30A
	.dw	$6E00	; vE=00
	.dw	$EEA1	; SKIP;vE NE KEY
	.dw	$135A	; GO m35A
	.dw	$78FF	; v8+FF
	.dw	$3800	; SKIP;v8 EQ 00
	.dw	$132E	; GO m32E
	.dw	$A69D	; I=069D
	.dw	$0634	; MLS@0634
	.dw	$FE00	;
	.dw	$4E00	; SKIP;vE NE 00
	.dw	$1326	; GO m326
	.dw	$7EFF	; vE+FF
	.dw	$063A	; MLS@063A
	.dw	$FE00	;
	.dw	$8870	; v8=v7
	.dw	$6C08	; vC=08
	.dw	$12EC	; GO m2EC
	.dw	$A693	; I=0693
	.dw	$0628	; MLS@0628
	.dw	$0301	; MLS@0301
	.dw	$1320	; GO m320
	.dw	$0603	; MLS@0603
	.dw	$132E	; GO m32E
	.dw	$12CE	; GO m2CE
	.dw	$6F2D	; vF=2D
	.dw	$FF18	; TONE=vF
	.dw	$FF15	; TIME=vF
	.dw	$24B4	; DO m4B4
	.dw	$FF07	; vF=TIME
	.dw	$3F00	; SKIP;vF EQ 00
	.dw	$133A	; GO m33A
	.dw	$A690	; I=0690
	.dw	$0634	; MLS@0634
	.dw	$F800	;
	.dw	$8A83	;
	.dw	$A69A	; I=069A
	.dw	$FA1E	; I=I+vA
	.dw	$F065	; v0:v0=MI
	.dw	$4000	; SKIP;v0 NE 00
	.dw	$1358	; GO m358
	.dw	$128C	; GO m28C
	.dw	$2486	; DO m486
	.dw	$1358	; GO m358
	.dw	$A691	; I=0691
	.dw	$FA1E	; I=I+vA
	.dw	$F065	; v0:v0=MI
	.dw	$4000	; SKIP;v0 NE 00
	.dw	$137C	; GO m37C
	.dw	$0640	; MLS@0640
	.dw	$70FF	; v0+FF
	.dw	$F055	; MI=V0:v0
	.dw	$A69D	; I=069D
	.dw	$0628	; MLS@0628
	.dw	$1800	;
	.dw	$A693	; I=0693
	.dw	$0628	; MLS@0628
	.dw	$0101	;
	.dw	$2568	; DO m568
	.dw	$2570	; DO m570
	.dw	$12EA	; GO m2EA
	.dw	$246E	; DO m46E
	.dw	$24A4	; DO m4A4
	.dw	$A690	; I=0690
	.dw	$0634	; MLS@0634
	.dw	$F800	;
	.dw	$A69A	; I=069A
	.dw	$FA1E	; I=I+vA
	.dw	$6000	; v0=00
	.dw	$F055	; MI=V0:v0
	.dw	$8A83	;
	.dw	$78FF	; v8+FF
	.dw	$A690	; I=0690
	.dw	$063A	; MLS@063A
	.dw	$F800	;
	.dw	$3800	; SKIP;v8 EQ 00
	.dw	$1358	; GO m358
	.dw	$6E01	; vE=01
	.dw	$EEA1	; SKIP;vE NE KEY
	.dw	$13A4	; GO m3A4
	.dw	$139C	; GO m39C
	.dw	$24A4	; DO m4A4
	.dw	$246E	; DO m46E
	.dw	$1342	; GO m342
	.dw	$6D02	; vD=02
	.dw	$FD18	; TONE=vD
	.dw	$2570	; DO m570
	.dw	$A67A	; I=067A
	.dw	$8160	; v1=v6
	.dw	$0634	; MLS@0634
	.dw	$F201	;
	.dw	$8125	; v1=v1-v2
	.dw	$4F00	; SKIP;vF NE 00
	.dw	$141E	; GO m41E
	.dw	$8160	; v1=v6
	.dw	$0634	; MLS@0634
	.dw	$F201	;
	.dw	$8215	; v2=v2-v1
	.dw	$4F00	; SKIP;vF NE 00
	.dw	$141E	; GO m41E
	.dw	$6107	; v1=07
	.dw	$8162	; v1=v1&v6
	.dw	$A65F	; I=065F
	.dw	$F11E	; I=I+v1
	.dw	$F065	; v0:v0=MI
	.dw	$8100	; v1=v0
	.dw	$4100	; SKIP;v1 NE 00
	.dw	$141E	; GO m41E
	.dw	$2486	; DO m486
	.dw	$252E	; DO m52E
	.dw	$24B4	; DO m4B4
	.dw	$A689	; I=0689
	.dw	$F11E	; I=I+v1
	.dw	$F065	; v0:v0=MI
	.dw	$8F00	; vF=v0
	.dw	$A697	; I=0697
	.dw	$4A01	; SKIP;vA NE 01
	.dw	$A69A	; I=069A
	.dw	$6903	; v9=03
	.dw	$0640	; MLS@0640
	.dw	$F065	; v0:v0=MI
	.dw	$0640	; MLS@0640
	.dw	$80F4	; v0=v0+vF
	.dw	$6C0A	; vC=0A
	.dw	$80C5	; v0=v0-vC
	.dw	$3F00	; SKIP;vF EQ 00
	.dw	$1402	; GO m402
	.dw	$700A	; v0+0A
	.dw	$F055	; MI=V0:v0
	.dw	$0640	; MLS@0640
	.dw	$79FF	; v9+FF
	.dw	$3900	; SKIP;v9 EQ 00
	.dw	$13F0	; GO m3F0
	.dw	$3F00	; SKIP;vF EQ 00
	.dw	$1356	; GO m356
	.dw	$C201	; v2=RND
	.dw	$3200	; SKIP;v2 EQ 00
	.dw	$141A	; GO m41A
	.dw	$247C	; DO m47C
	.dw	$141C	; GO m41C
	.dw	$2486	; DO m486
	.dw	$252E	; DO m52E
	.dw	$24B4	; DO m4B4
	.dw	$46E8	; SKIP;v6 NE E8
	.dw	$1466	; GO m466
	.dw	$46EF	; SKIP;v6 NE EF
	.dw	$1466	; GO m466
	.dw	$6100	; v1=00
	.dw	$6C02	; vC=02
	.dw	$05E3	; MLS@05E3
	.dw	$0608	; MLS@0608
	.dw	$7101	; v1+01
	.dw	$6C07	; vC=07
	.dw	$05E3	; MLS@05E3
	.dw	$0608	; MLS@0608
	.dw	$7102	; v1+02
	.dw	$6C09	; vC=09
	.dw	$05E3	; MLS@05E3
	.dw	$0608	; MLS@0608
	.dw	$7104	; v1+04
	.dw	$6C03	; vC=03
	.dw	$05E3	; MLS@05E3
	.dw	$0608	; MLS@0608
	.dw	$7108	; v1+08
	.dw	$6C04	; vC=04
	.dw	$05E3	; MLS@05E3
	.dw	$4105	; SKIP;v1 NE 05
	.dw	$12E2	; GO m2E2
	.dw	$4107	; SKIP;v1 NE 07
	.dw	$12E2	; GO m2E2
	.dw	$410D	; SKIP;v1 NE 0D
	.dw	$12E2	; GO m2E2
	.dw	$4101	; SKIP;v1 NE 01
	.dw	$12E2	; GO m2E2
	.dw	$410A	; SKIP;v1 NE 0A
	.dw	$146A	; GO m46A
	.dw	$410B	; SKIP;v1 NE 0B
	.dw	$146A	; GO m46A
	.dw	$2568	; DO m568
	.dw	$12EA	; GO m2EA
	.dw	$A655	; I=0655
	.dw	$12E4	; GO m2E4
	.dw	$88A0	; v8=vA
	.dw	$6A01	; vA=01
	.dw	$2550	; DO m550
	.dw	$6A00	; vA=00
	.dw	$2550	; DO m550
	.dw	$8A80	; vA=v8
	.dw	$00EE	; RET
	.dw	$A689	; I=0689
	.dw	$C007	; v0=RND
	.dw	$7002	; v0+02
	.dw	$F11E	; I=I+v1
	.dw	$F055	; MI=V0:v0
	.dw	$690B	; v9=0B
	.dw	$A675	; I=0675
	.dw	$F11E	; I=I+v1
	.dw	$F065	; v0:v0=MI
	.dw	$8200	; v2=v0
	.dw	$A667	; I=0667
	.dw	$D297	; SHOW 7MI@v2v9
	.dw	$7901	; v9+01
	.dw	$7201	; v2+01
	.dw	$A689	; I=0689
	.dw	$F11E	; I=I+v1
	.dw	$F065	; v0:v0=MI
	.dw	$F029	; I=v0(LSDP)
	.dw	$D295	; SHOW 5MI@v2v9
	.dw	$00EE	; RET
	.dw	$A66E	; I=066E
	.dw	$6018	; v0=18
	.dw	$6100	; v1=00
	.dw	$D014	; SHOW 4MI@v0v1
	.dw	$6020	; v0=20
	.dw	$A672	; I=0672
	.dw	$D014	; SHOW 4MI@v0v1
	.dw	$00EE	; RET
	.dw	$A68E	; I=068E
	.dw	$F065	; v0:v0=MI
	.dw	$0640	; MLS@0640
	.dw	$3000	; SKIP;v0 EQ 00
	.dw	$14D6	; GO m4D6
	.dw	$6E04	; vE=04
	.dw	$EEA1	; SKIP;vE NE KEY
	.dw	$14EE	; GO m4EE
	.dw	$A69C	; I=069C
	.dw	$F065	; v0:v0=MI
	.dw	$0640	; MLS@0640
	.dw	$3000	; SKIP;v0 EQ 00
	.dw	$14E2	; GO m4E2
	.dw	$6E06	; vE=06
	.dw	$EEA1	; SKIP;vE NE KEY
	.dw	$14F8	; GO m4F8
	.dw	$00EE	; RET
	.dw	$70FF	; v0+FF
	.dw	$A68E	; I=068E
	.dw	$F055	; MI=V0:v0
	.dw	$4004	; SKIP;v0 NE 04
	.dw	$2578	; DO m578
	.dw	$14C4	; GO m4C4
	.dw	$70FF	; v0+FF
	.dw	$A69C	; I=069C
	.dw	$F055	; MI=V0:v0
	.dw	$4004	; SKIP;v0 NE 04
	.dw	$2592	; DO m592
	.dw	$00EE	; RET
	.dw	$2502	; DO m502
	.dw	$6009	; v0=09
	.dw	$6D02	; vD=02
	.dw	$FD18	; TONE=vD
	.dw	$14D8	; GO m4D8
	.dw	$2514	; DO m514
	.dw	$6009	; v0=09
	.dw	$6D02	; vD=02
	.dw	$FD18	; TONE=vD
	.dw	$14E4	; GO m4E4
	.dw	$A0E9	; I=00E9
	.dw	$0625	; MLS@0625
	.dw	$0628	; MLS@0628
	.dw	$0F01	;
	.dw	$0628	; MLS@0628
	.dw	$FF01	;
	.dw	$0628	; MLS@0628
	.dw	$F806	;
	.dw	$1524	; GO m524
	.dw	$A0EC	; I=00EC
	.dw	$0625	; MLS@0625
	.dw	$0628	; MLS@0628
	.dw	$1F01	;
	.dw	$0628	; MLS@0628
	.dw	$FF01	;
	.dw	$0628	; MLS@0628
	.dw	$F008	;
	.dw	$0628	; MLS@0628
	.dw	$0008	;
	.dw	$0628	; MLS@0628
	.dw	$0000	;
	.dw	$00EE	; RET
	.dw	$6200	; v2=00
	.dw	$6B30	; vB=30
	.dw	$4A01	; SKIP;vA NE 01
	.dw	$6B00	; vB=00
	.dw	$6900	; v9=00
	.dw	$A694	; I=0694
	.dw	$4A01	; SKIP;vA NE 01
	.dw	$A697	; I=0697
	.dw	$F91E	; I=I+v9
	.dw	$F065	; v0:v0=MI
	.dw	$F029	; I=v0(LSDP)
	.dw	$DB25	; SHOW 5MI@vBv2
	.dw	$7B06	; vB+06
	.dw	$7901	; v9+01
	.dw	$3903	; SKIP;v9 EQ 03
	.dw	$1538	; GO m538
	.dw	$00EE	; RET
	.dw	$A69A	; I=069A
	.dw	$FA1E	; I=I+vA
	.dw	$F065	; v0:v0=MI
	.dw	$4000	; SKIP;v0 NE 00
	.dw	$156E	; GO m56E
	.dw	$F029	; I=v0(LSDP)
	.dw	$6200	; v2=00
	.dw	$6126	; v1=26
	.dw	$4A01	; SKIP;vA NE 01
	.dw	$6116	; v1=16
	.dw	$D125	; SHOW 5MI@v1v2
	.dw	$00EE	; RET
	.dw	$610A	; v1=0A
	.dw	$8145	; v1=v1-v4
	.dw	$8410	; v4=v1
	.dw	$00EE	; RET
	.dw	$C703	; v7=RND
	.dw	$7703	; v7+03
	.dw	$8870	; v8=v7
	.dw	$00EE	; RET
	.dw	$A0E9	; I=00E9
	.dw	$0625	; MLS@0625
	.dw	$0628	; MLS@0628
	.dw	$0801	;
	.dw	$0628	; MLS@0628
	.dw	$0001	;
	.dw	$0628	; MLS@0628
	.dw	$0006	;
	.dw	$0628	; MLS@0628
	.dw	$0808	;
	.dw	$0628	; MLS@0628
	.dw	$0800	;
	.dw	$00EE	; RET
	.dw	$A0EC	; I=00EC
	.dw	$0625	; MLS@0625
	.dw	$0628	; MLS@0628
	.dw	$0001	;
	.dw	$0628	; MLS@0628
	.dw	$0001	;
	.dw	$0628	; MLS@0628
	.dw	$1008	;
	.dw	$0628	; MLS@0628
	.dw	$1008	;
	.dw	$0628	; MLS@0628
	.dw	$1000	;
	.dw	$00EE	; RET
	.dw	$01D6	;
	.dw	$D6C6	; SHOW 6MI@v6vC
	.dw	$D7C6	; SHOW 6MI@v7vC
	.dw	$D6C6	; SHOW 6MI@v6vC
	.dw	$CBD7	; vB=RND
	.dw	$D6D6	; SHOW 6MI@v6vD
	.dw	$D6CB	; SHOW BMI@v6vC
	.dw	$D6C1	; SHOW 1MI@v6vC
	.dw	$D7C1	; SHOW 1MI@v7vC
	.dw	$D6C1	; SHOW 1MI@v6vC
	.dw	$CBF8	; vB=RND
	.dw	$08F4	;
	.dw	$56D3	;
	.dw	$F808	;
	.dw	$F556	;
	.dw	$D38E	; SHOW EMI@v3v8
	.dw	$F63B	;
	.dw	$D5F8	; SHOW 8MI@v5vF
	.dw	$01F4	;
	.dw	$56F8	;
	.dw	$80AE	;
	.dw	$D38E	; SHOW EMI@v3v8
	.dw	$FE3B	;
	.dw	$D5F8	; SHOW 8MI@v5vF
	.dw	$01F5	;
	.dw	$56F8	;
	.dw	$0130	;
	.dw	$D5F8	; SHOW 8MI@v5vF
	.dw	$FCA7	;
	.dw	$96B7	;
	.dw	$E7F8	;
	.dw	$05BD	; MLS@05BD
	.dw	$F8AD	;
	.dw	$F4F4	;
	.dw	$ADF8	; I=0DF8
	.dw	$F5A6	;
	.dw	$E672	;
	.dw	$AE93	; I=0E93
	.dw	$BC4D	; SET v4 COLOR @vCXD       ????????
	.dw	$ACDC	; I=0CDC
	.dw	$4DAC	; SKIP;vD NE AC
	.dw	$DC8E	; SHOW EMI@vCv8
	.dw	$2656	; DO m656
	.dw	$D4F8	; SHOW 8MI@v4vF
	.dw	$00BC	;
	.dw	$300B	; SKIP;v0 EQ 0B
	.dw	$F801	;
	.dw	$BCF8	; SET vF COLOR @vCX8       ????????
	.dw	$F5A6	;
	.dw	$E672	;
	.dw	$AE9B	; I=0E9B
	.dw	$BFF0	; SET vF COLOR @vF       ????????
	.dw	$AFEF	; I=0FEF
	.dw	$8EF3	;
	.dw	$BE8E	; SET v8 COLOR @vEXE       ????????
	.dw	$F23A	;
	.dw	$1F15	;
	.dw	$159C	; GO m59C
	.dw	$3A24	; SKIP;vA EQ 24
	.dw	$9E5F	;
	.dw	$D49B	; SHOW BMI@v4v9
	.dw	$BAD4	; SET vD COLOR @vAX4       ????????
	.dw	$455A	; SKIP;v5 NE 5A
	.dw	$E58A	;
	.dw	$F4AA	;
	.dw	$159A	; GO m59A
	.dw	$7C00	; vC+00
	.dw	$BAD4	; SET vD COLOR @vAX4       ????????
	.dw	$45A6	; SKIP;v5 NE A6
	.dw	$0A56	;
	.dw	$302A	; SKIP;v0 EQ 2A
	.dw	$45A6	; SKIP;v5 NE A6
	.dw	$065A	; MLS@065A
	.dw	$302A	; SKIP;v0 EQ 2A
	.dw	$2AD4	;
	.dw	$F814	;
	.dw	$AFF8	; I=0FF8
	.dw	$005A	;
	.dw	$1A2F	;
	.dw	$8F3A	;
	.dw	$45D4	; SKIP;v5 NE D4
	.dw	$0309	; MLS@0309
	.dw	$0103	;
	.dw	$0001	;
	.dw	$0902	;
	.dw	$0708	; MLS@0708
	.dw	$0901	;
	.dw	$0003	;
	.dw	$0102	;
	.dw	$0300	;
	.dw	$0102	;
	.dw	$0203	; MLS@0203
	.dw	$0304	; MLS@0304
	.dw	$00FC	;
	.dw	$FCFC	;
	.dw	$FCFC	;
	.dw	$FCFC	;
	.dw	$7222	; v2+22
	.dw	$2222	; DO m222
	.dw	$4742	; SKIP;v7 NE 42
	.dw	$4272	; SKIP;v2 NE 72
	.dw	$0815	;
	.dw	$2532	; DO m532
	.dw	$598E	;
	.dw	$E0A0	;
	.dw	$E004	;
	.dw	$0702	; MLS@0702
	.dw	$1706	; GO m706
	.dw	$3F08	; SKIP;vF EQ 08
	.dw	$1704	; GO m704
	.dw	$0800	;

        .END

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
