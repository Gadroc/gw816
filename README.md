# GW816
The GW816 is my hobby project to explore hardware and os design.  This is targeted at an era
of nostalgic era for me as my first experience in software development was learning basic then assembly
on my Commodore 64.  The GW816 represents what would have been my dream next computer in 1985 as the Amiga
was far outside the range of my wallet as a teenager.

## Design Goals
Create a 16-bit computer based on at 65C816 which would fit into the commodore line as an alternate to
the Commodore 128.  It would sit in between the C64 and amiga but with much better Graphics and Sound
capabilities than the 128.

* When possible use hardware which can be easily sourced today
* Physical hardware does not need to be period accurate, but interface to software development does
* Storage should be removable and easily read/written from current computers
* CDC Serial over USB (RS-232 serial ports are not common enough anymore and USB dongle are a pain)
* 3.3V based to ease component selection

For at least the first revisions I will be emulating new chipsets using Raspberry Pi Picos.  While this will 
limit me to roughly 8Mhz I think that is actually a reasonable speed for the time period.  This will enable
me to rapidly prototype these chips using existing software libraries for the Pico.

Special thanks to [Rumblethumps](https://www.youtube.com/@rumbledethumps) as his 
[picocomputer](https://github.com/picocomputer) inspired me.  Although my design has taken a different path, 
and I've implemented as little os software as possible in the pico, instead favoring using the pico software
to emulate hardware.  Without his pioneering of PIO interface with the 6502 most of this design would not be
possible.

## Hardware Features
* 65C816 Processor at 8Mhz
* 1MB of RAM (Supports up to 16MB via memory expansion slot)
* 2 CDC Serial Ports
  * Console (working)
  * Data (future)
* SD Card (via SPI)
* RTC (via SPI)
  * 64 Bytes Battery Backed RAM
* PS/2 Keyboard / Mouse Interface
* Sound 
  * (... stats here ...)
* Video
  * 128K Video RAM
  * 15-Bit color palette
  * 640x480 VGA Native Output
* Expansion port for add in cards (full buss access, no DMA support)

## BIOS Features (In Progress)
* SDCard IO
* FAT32 File System
* RTC Functions
* Bootloader - Find's possible kernels and allows user to select one
* ML Monitor
* PS/2 Keyboard & Mouse
* VT-100 Local/Remote console fullscreen editor
  * ANSI Color Escape Codes Supported
  * DEC Special Graphics
  * Merges PS/2 Keyboard and Serial Console port

## Basic Kernel (Future)
* Loads as OS and implements a Commodore like full-screen editor and basic single tasking machine

## GW/OS Kernel (Future)
* GUI Based Operating System
* Relocatable code & co-operative multi-tasking
* GUI application tool library

## GW/OS Memory Map
|  Start |    End | Description                               |
|-------:|-------:|-------------------------------------------|
| 000000 | 00CEFF | Direct Pages / Stacks (Managed by Kernel) |
| 00CF00 | 00CFFF | BIO Direct Page                           |
| 00D000 | 00FEFF | BIOS / Bootloader / Monitor               |
| 00FF00 | 00FF8F | I/O Registers                             |
| 00FF90 | 00FFFF | BIOSCopy / Interrupt Vectors              |
| 010100 | 01FFFF | BIOS                                      |
| 020000 | 0FFFFF | Kernel / OS / Application & Data          |

## Chipset Overview

### System Interface Adapter (Clio - In Progress)
USB: VID 0x1209 PID: 0xD0DB
Clio is the primary chipset orchestrating the GW816.  It is responsible for the following:
* Clock Generation (Working)
* CPU Reset Control (Working)
* BIOS / Interrupt Vectors (Working)
* SPI Controller for SD and RTC (Future)
* Timers (Future)

The GW816 does not have ROM chips, instead the Clio will copy the BIOS into RAM and transfer
control to it.

### Bus Interface Adapter (Hermes - In Progress)
The BIA takes care of address decoding and PS/2 bus communications.

### Graphics Controller (Aether - Future)
* Pico w/ HDMI (https://github.com/Wren6991/PicoDVI)
* [VT-100 Font](https://en.wikipedia.org/wiki/VT100_encoding) (ISO-8859-1 and Code Page 1090)

### Audio Controller (Apollo - Future)
* Pico w/ I2S Audio channel
* Running various sound chip emulation routines (TBD)
