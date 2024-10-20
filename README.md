# GW816
The GW816 is my hobby project to explore hardware and os design.  This is targeted at an nostalgic era for me as my first experience in software development was learning basic then assembly on my Commodore 64.  The GW816 is a what if alternative to the Commodore 128 as a successor to the Commodore 64.  It's aiming at similar goals from the 64 that the Apple IIgs was to the Apple II.  The GW816 is not seeking to be backwards compatible with the 64.

## Design Goals
Target goals for hardware and software running the GW816.

### Hardware
* 65C816 Processor Based System
* 8Mhz Target Clock Speed
* At least 1MB of RAM
* 2 Serial Ports (1 for debug console, 1 for data)
* SD Card for storage (SPI)
* Real Time Clock (SPI)
* NVRAM/Battery Backed RAM for system config (via RTC SPI)
* PS/2 Keyboard & Mouse Support
* Video
  * 640x480 Native VGA Output
  * 80x25 Tex [VT-100 Font](https://en.wikipedia.org/wiki/VT100_encoding) (ISO-8859-1 and Code Page 1090)
  * Min 320x240 16 color full graphics mode
  * Redefinable Tile/Text character capability
  * Sprite Support (size & qty TBD)
* Sound
  * PCM?

### Firmware
* Hardware Init
* ML Monitor
* Bootloader

### Operating System
* Pre-emptive task system
  * Memory allocation (no MMU so honor system)
  * Shared memory blocks
  * Message based IPC
* FAT16 File System
* Relocatable Code Loader ([O65 Format](http://www.6502.org/users/andre/o65/fileformat.html))

## Hardware Implementation Notes

### Glue Logic / Custom Chips
The GW816 uses [Cyclone IV Development Board](https://www.aliexpress.us/item/3256803879412530.html) as a development platform for most of it's implementation.  Based on GW816 goals most of what is done in the FPGA would be done using custom ASICs like the VIC-II and SID, which the FPGA board is a substitute for.  I also want to learn VHDL and digital/synchronous circuit design.

This choice also radically reduces cost and complexity as many of the custom ASICs will fit in this FPGA.  The chosen board has appropriate connectors to just plug into a mainboard so finished product should be hand solderable.  Lastly the dev board has enough RAM to fully max out the 65816 RAM capacity.

This choice leans towards using 3.3v for the processor which will limit speeds, but 8Mhz is the fastest several other components work anyway.  An 8Mhz 65816 should be on par with the speed of contemporary era PCs, Macs and Amigas.

### Form Factor
Final board layout will target an Mini ITX board layout to leverage modern existing SFF cases.

### Power
Target standard 12v wall wart power supply with onboard regulation to 5v and 3.3v power. (Possibly pico atx power supply although the system does not use 12v).

### Expansion Slot
Board will have one expansion slot for development of future peripherals.

## Hardware Blocks

### Clock Generator (FPGA)

### Reset Control (FPGA)
Accept reset requests from hardware buttons and other devices and make sure the CPU reset adheres to CPU specs.

### Bus Controller (FPGA)
* Address Decoding
* Bus Mediation
  * Address Latching
  * Peripheral cross connects

### Memory Controller (FPGA)
* 65xxx BUS to SDRAM address translation
* SDRAM initialization and refresh
* Dev board SDRAM part can achieve 8Mhz 65xxx bus by overclocking to 2CL at 133Mhz (Spec says 3CL for 133Mhz)

### System Interface Adapter / Boot ROM -- (RP2040)
For at least the first revisions I will be using a Raspberry Pico (RP2040) as a bootstrap ROM, Debug Serial Port, and PS2 Keyboard & Mouse Controller.  The Pico is only capable of direct 65xxx bus access up to 8Mhz, and in doing so it must start access during low phase of PHI2 meaning interleaving of the RAM bus is not supported with out a separate peripheral BUS.

Clio will present a bootstrap program and copy kernal into RAM before handing control over to the kernel.

Special thanks to [Rumblethumps](https://www.youtube.com/@rumbledethumps) as his [picocomputer](https://github.com/picocomputer) inspired me.  Although my design has taken a different path, and I've implemented as little os software as possible in the pico, instead favoring using the pico software to emulate hardware.  Without his work on PIO interface with the 6502 most of this design would not be possible.

### Interrupt Controller (FPGA)
Interrupt controller will allow quick identification and suppression of all interrupt sources.

### SPI Controller (FPGA)

### Video (FPGA)

### Sound (Pico)
Likely use the Pico to emulate an contemporary audio chip but with a direct 65xxx bus connection.  Board will have a Pico socket per wired for I2S audio and have on board audio amp for line out connections.

### RTC (...)
