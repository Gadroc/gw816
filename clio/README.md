# System Interface Adapter (Clio)
The system interface adapter ...

---
## TODO
* Move from standard IO to dual CDC serial ports
* If VBUS is present wait for CDC connect to release cpu
* If VBUS is present and CDC connection drops put CPU in reset
* If VBUS is present and CDC connection starts pull CPU out of reset
* HW Serial Flow Control??
* Implement Serial IRQs
* Implement SPI Registers
* Timers
* Watchdog
---

## Registers
| Address | Bit(s) | R/W | Description                                                                                                                                                 |
|--------:|-------:|:---:|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
|      00 |        |     | **System Control Register (SCR)**                                                                                                                           |
|         |      7 |  R  | ROM Complete: Set if RDR has already read the last byte of ROM data.                                                                                        |
|         |      6 |  R  | ROM Data Ready: RBA, RA, and RDR contain valid data.                                                                                                        |
|         |      5 |  W  | ROM Reset: Writing this bit resets RDR to point to begging of ROM data.                                                                                     |
|         |    3-4 | RW  | System Led<br/>00: Off<br/>01: Solid On</br>10: Slow Flash</br>11: Fast Flash                                                                               |
|         |    2-0 | RW  | CPU Speed<br/>000 : 10 kHz<br/>001 : 100 kHz<br/>010 : 500 kHz<br/>011 : 1 MHz<br/>100 : 2 MHz<br/>101 : 4 MHz<br/>110 : 6 Mhz<br/>111 : 8 MHz              |
|   01-02 |        |  R  | **ROM Target Address (RTA)**<br/>Contains the current target address of the RDR.                                                                            |
|      03 |        |  R  | **ROM Bank Address (RBA)**<br/>Contains the current target bank of the RDR.                                                                                 |
|      04 |        |  R  | **ROM Data Register (RDR)**<br/>Contains current byte in ROM buffer.  Read from this register will increment target address and fetch the next byte.        |
|      05 |        |     | **Interrupt Status Register (ISR)**                                                                                                                         |
|         |    7-6 |     | Reserved                                                                                                                                                    |
|         |      5 |  R  | SPI Busy: SPI busy is transmitting / receiving data (does not generate interrupt)                                                                           |
|         |      4 |  R  | SPI Transmit Complete: Flag set when data transfer is complete                                                                                              |
|         |      3 |  R  | Serial Data Ready: Data is available to read from Serial Data Register                                                                                      |
|         |      2 |  R  | Serial Transmit Ready: Serial transmit buffer has space available                                                                                           |
|         |      1 |  R  | Console Data Ready: Data is available to read from Console Data Register                                                                                    |
|         |      0 |  R  | Console Transmit Ready: Console transmit buffer has space available                                                                                         |
|      06 |        | R/W | **Interrupt Control Register (ICR)**<br/>High bits enable interrupts for the related status register bit, while low bit disables interrupts on that status. |
|      07 |        | R/W | **Console Data Register (CDR)**<br/>Read: Returns next byte from console receive buffer<br/>Write: Adds byte to console transmit buffer                     |
|      08 |        | R/W | **Serial Data Register (SDR)**<br/>Read: Returns next byte from serial receive buffer<br/>Write: Adds byte to serial transmit buffer                        |
|      09 |        |     | **SPI Control Register (SPC)**                                                                                                                              |
|         |    7-6 | R/W | Read Mode<br/>00: Write to Read<br/>01: Auto Read with last transmit value<br/>10: Auto Read with 0x00<br/>11: Auto Read with 0xFF                          |
|         |    5-4 | R/W | Shift Clock Speed<br/>00: 400Khz<br/>01: 4Mhz<br/>10: 20Mhz<br/>11: 25Mhz                                                                                   |
|         |      3 | R/W | Clock Phase (CPHA)<br/>0: Leading Edge<br/>1: Trailing Edge                                                                                                 |
|         |      2 | R/W | Clock Polarity (CPOL)<br/>0: Rising Edge<br/>1: Falling Edge                                                                                                |
|         |    1-0 | R/W | Device Select<br/>0x: No Device Selected<br/>10: SD Card<br/>11: RTC                                                                                        | 
|      0A |        | R/W | **SPI Data Register (SPD)**<br/>Read: Returns next byte from serial receive buffer<br/>Write: Sends byte over the SPI bus                                   |
|   0C-1F |        |     | Reserved                                                                                                                                                    |
|   20-5F |        |  R  | **Bootstrap Code**                                                                                                                                          |
|   60-61 |        |     | Reserved                                                                                                                                                    |
|   62-63 |        |     | Reserved                                                                                                                                                    |
|   64-65 |        |     | **Native COP Vector**                                                                                                                                       |
|   66-67 |        |     | **Native BRK Vector**                                                                                                                                       |
|   68-69 |        |     | **Native ABORT Vector**                                                                                                                                     |
|   6A-6B |        |     | **Native NMI Vector**                                                                                                                                       |
|   6C-6D |        |     | Reserved                                                                                                                                                    |
|   6E-6F |        |     | **Native IRQ Vector**                                                                                                                                       |
|   70-71 |        |     | Reserved                                                                                                                                                    |
|   72-73 |        |     | Reserved                                                                                                                                                    |
|   74-75 |        |     | **Emulation COP Vector**                                                                                                                                    |
|   76-77 |        |     | Reserved                                                                                                                                                    |
|   78-79 |        |     | **Emulation ABORT Vector**                                                                                                                                  |
|   7A-7B |        |     | **Emulation NMI Vector**                                                                                                                                    |
|   7C-7D |        |     | **Emulation RESET Vector**                                                                                                                                  |
|   7E-7F |        |     | **Emulation IRQ/BRK Vector**                                                                                                                                |
