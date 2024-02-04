# GW816
The GW816 is my hobby project to explore hardware and os design.  This is targeted at an era of nostalgic era for me as my first experience in software development was learning basic then assembly on my Commodore 64.  The GW816 is a what if alternative to the Commodore 128 as a successor to the Commodore 64.  It's aiming at similar goals from the 64 that the Apple IIgs was to the Apple II.  The GW816 is not seeking to be backwards compatible with the 64.

## Design Goals
Target goals for hardware and software running the GW816.

### Hardware
* 65C816 Processor Based System
* 8Mhz Target Clock Speed
* At least 1MB of RAM
* 2 Serial Ports (1 for serial console, 1 for data)
* SD Card for storage
* Real Time Clock
* NVRAM/Battery Backed RAM for system config
* PS/2 Keyboard & Mouse Support
* Video
  * 640x480 Native VGA Output
  * 80x25 Tex [VT-100 Font](https://en.wikipedia.org/wiki/VT100_encoding) (ISO-8859-1 and Code Page 1090)
  * Min 320x240 16 color full graphics mode
  * Redefinable Tile/Text character capability
  * Sprite Support (size & qty tbd)
* Sound
  * TBD

### Operating System
* Pre-emptive task system
  * Memory allocation (no MMU so honor system)
  * Shared memory blocks
  * Message based IPC
* ML Monitor
* FAT32 File System
* VT-100/ANSI Local/Remote console fullscreen editor
  * ANSI Color Escape Codes Supported
  * DEC Special Graphics
  * Merges PS/2 Keyboard and Serial Console port
* Relocatable Code Loader ([O65 Format](http://www.6502.org/users/andre/o65/fileformat.html))

## Hardware Implementation Notes

### Glue Logic / Custom Chips
The GW816 uses [Cyclone IV Development Board](https://www.aliexpress.us/item/2251832762966437.html) (Aether III) as a development platform for most of it's implementation.  Based on GW816 goals most of what is done in the FPGA would be done using custom ASICs like the VIC-II and SID, which the FPGA board is a substitue for.  I also want to learn VHDL and digital/synchronous circuit design.

This choice also radically reduces cost and complexity as many of the custom ASICs will fit in this FPGA.  The choosen board had appropraite connectors to just plug into a mainboard so finished product should be hand solderable.  Lastly the dev board has enough RAM to fully max out the 65816 RAM capacity.

This choice leans towards using 3.3v for the processor which will limit speeds, but 8Mhz is the fatest several other components work anyways.  An 8Mhz 65816 should be on par with the speed of contemporary era PCs, Macs and Amigas.

### Form Factor
Final form factor is currently undecided.  Two options:
* C64c Case using C64 keyboard to PS/2 controller (Need to have internal header for ps/2 keyboard and jumpers to disable external port).
* Mini ITX

### Power
Target standard 12v wall wart power supply with onboard regulation to 5v and 3.3v power. (Possibly pico atx power supply although the system does not use 12v).

### Serial Port
Data serial port has two options:
* Full external RS232 - TIA port used to drive external RS232 based Wifi Modem
* Bake Wifi board onto motherboard

### Expansion Slot
Board will have one expansion slot for development of future peripherals.

## Hardware Blocks

### Clock Generator (FPGA)

### Reset Controll (FPGA)

### Bus Controller (FPGA)
* Address Decoding
* Bus Mediation
  * Address Latching
  * Peripheral cross connects

### Memory Controller (FPGA)
* 65xxx BUS to SDRAM address translation
* SDRAM initialization and refresh
* Dev board SDRAM part can achieve 8Mhz 65xxx bus by overclocking to 2CL at 133Mhz (Spec says 3CL for 133Mhz)

#### IO Address Map
The IO MAP is repeated bank 00-02.  This allows for direct hardware access for tasks located in the first three banks of memory. 

TODO Update table with latest IO addresss map from hardware design.

| Start |  End | Description                   |
|------:|-----:|-------------------------------|
|  FF00 | FF1F | Expansion slot                |
|  FF20 | FF3F | Apollo                        |
|  FF40 | FF4F | System VIA (SNES Controllers) |
|  FF50 | FF5F | User Port VIA                 |
|  FF60 | FF7F | Aether                        |
|  FF80 | FF9F | Clio                          |
|  FFA0 | FFFF | Bootstrap & Vectors           |

### System Interface Adapter / Boot ROM -- Clio (Pico)
For at least the first revisions I will be using a Raspberry Pico (RP2040) as a bootstrap ROM, CDC based UARTs(VID 0x1209 PID: 0xD0DB), and PS2 Keyboard & Mouse Controller.  The Pico is only capable of direct 65xxx bus access up to 8Mhz, and in doing so it must start access during low phase of PHI2 meaning interleaving of the RAM bus is not supported with out a separate peripherial BUS.

Clio will present a bootstrap program and copy kernal into RAM before handing control over to the kernel.

Special thanks to [Rumblethumps](https://www.youtube.com/@rumbledethumps) as his [picocomputer](https://github.com/picocomputer) inspired me.  Although my design has taken a different path, and I've implemented as little os software as possible in the pico, instead favoring using the pico software to emulate hardware.  Without his work on PIO interface with the 6502 most of this design would not be possible.

### Interrupt Controller (FPGA)

### SPI Controller (FPGA)

### Video (FPGA)

### Sound (Pico)
Likely use the Pico to emulate an contemporary audio chip but with a direct 65xxx bus connection.  Board will have a Pico socket per wired for I2S audio and have on board audio amp for line out connections.

### RTC (...)
