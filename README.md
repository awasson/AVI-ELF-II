# AVI ELF II Rev D Variant

**The AVI ELF II Rev D Variant is a reproduction of the RCA  CDP1802-based computer kit by Netronics Research and Development Limited.**

![ELF II Rev D Variant](https://github.com/awasson/AVI-ELF-II/assets/2935397/c0068558-4cf3-4f1a-80ae-7bcad960d778)

The AVI ELF II Rev D Variant single board microcomputer was reimagined by the late Ed Keefe (1964-2022) to maintain the aesthetic of the original ELF II, with additional onboard RAM and daughter cards for flexibility of keypad encoders and display drivers.

This project is ongoing with the support of [Josh Bensadon](https://github.com/JoshBensadon), [Andrew Wasson](https://github.com/awasson), Walter Miraglia and Rizal Acob. Below you will find a stable version of the PCB gerber files, bill of materials. 

[The Assembly Manual](https://github.com/awasson/AVI-ELF-II/wiki/AVI-ELF-II-Basic-Assembly-Notes) is in progress in the Wiki.

**There are a number of differences between the AVI ELF II and the original:**

* Power on/off toggle switch with power status LED.
* Power is from a single 6 to 9 volt DC supply that supplies the board and expansion cards. Suitable for use with typical 9 volt adapter with barrel connector (center positive). If a V7805-2000R (DC DC CONVERTER 5V 10W) is used in place of the LM7805 voltage regulator, up to 2A of current is available for the board and expansion boards.
* Optional on-board DC-DC coverter for +8 volt / -8 volt supply for original Netronics Giant Board.
* 32KB on-board RAM with ability to adjust RAM size from 256 Bytes to 32KB.
* Optional onboard RAM battery backup.
* Keypad uses modern Cherry MX compatible keyswitches.
* Optional raised Keypad to approximate height of keypad on the original Netronics ELF II.
* Onboard Data Display options for original HP 5082-7740 7-Segment Displays or HP 5082-7340 Dot Matrix LED Display.
* Optional raised display boards for TIL 311 or Dot Matrix Address and Data Displays. 

### Build Notes
* [AVI ELF II Wiki](https://github.com/awasson/AVI-ELF-II/wiki/AVI-ELF-II-Basic-Assembly-Notes)

### Design Files:
* [Schematic](notes/ELF-II/AVIELF2v1-Sch.pdf)
* [Bill of Materials](notes/ELF-II/AVI%20ELF%20II%20Final%20BOM.xlsx)
* [FAB Files](gerbers/ELF-II/AVIELF2v1-Gerbers.zip)


## Expansion Boards
Several Expansion boards have been designed to enhance and extend the ELF II. These were designed primarily for use with the AVI ELF II but it is quite possible that they will work with an orginal Netronics ELF II. 
* **Hyperboard Expansion Card** With 32KB RAM / 32KB EPROM, CD1852 Byte-Wide Input/Output Ports, CD1854 UART, Cassette IN/OUT with proto area (in development/testing). The Hyperboard is a decendant of the Netronics ELF II Giant Board but the Hyperboard includes modern enhancements for additional RAM and EEPROM, input/output ports and serial connections.
* **ELF 2K Disk for ELF II Board** Uses Spare Time Gizmos ELF 2K Firmware to add a Compact Flash Card "Hard Disk" to use with the ELF/OS Disk Operating System. Provides 32KB RAM / 32KB EPROM, 16C450 UART, Serial Communications with FTDI connections, USB FT232RL device, IDE connection, CF Card socket and Real Time Clock chip (in development/testing).    
* **VIP Personality Board** to VIP an ELF (in development).
* **Protoboard** Full sized expansion card with 86 position edge connection for prototyping cicuitry. 
