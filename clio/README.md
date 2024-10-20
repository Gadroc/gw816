# System Interface Adapter (Clio)
The system interface adapter ...

## Registers
| Address | Bit(s) | R/W | Description                                                                                                                                                 |
|--------:|-------:|:---:|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
|      00 |        |     | **System Control Register (SCR)**                                                                                                                           |
|         |      7 |  R  | ROM Complete: Set if RDR has already read the last byte of ROM data.                                                                                        |
|         |      6 |  W  | ROM Ready: Writing this bit resets RDR to point to begging of ROM data.                                                                                     |
|         |    5:3 |     | Reserved                                                                                                                                                    |
|         |    2:0 | RW  | System Led<br/>00: Off<br/>01: Solid On</br>10: Slow Flash</br>11: Fast Flash                                                                               |
|      01 |        |  R  | **ROM Data Register (RDR)**<br/>Contains current byte in ROM buffer.  Read from this register will increment target address and fetch the next byte.        |
|      02 |        |     | **Interrupt Status Register (ISR)**                                                                                                                         |
|         |    7:5 |     | Reserved                                                                                                                                                    |
|         |      4 |  R  | Mouse Data Ready: Mouse Data is available to read from Mouse Data Register                                                                                  |
|         |      3 |  R  | Keyboard Transmit Ready: Keyboard transmit buffer has space available                                                                                       |
|         |      2 |  R  | Keyboard Data Ready: Keyboard Data is available to read from Keyboard Data Register                                                                         |
|         |      1 |  R  | Console Data Ready: Data is available to read from Console Data Register                                                                                    |
|         |      0 |  R  | Console Transmit Ready: Console transmit buffer has space available                                                                                         |
|      03 |        | R/W | **Interrupt Control Register (ICR)**<br/>High bits enable interrupts for the related status register bit, while low bit disables interrupts on that status. |
|      04 |        | R/W | **Console Data Register (CDR)**<br/>Read: Returns next byte from console receive buffer<br/>Write: Adds byte to console transmit buffer                     |
|      05 |        | R/W | **Keyboard Data Register (KDR)**<br/>Read: Returns next byte from keyboard receive buffer<br/>Write: Adds byte to keyboard transmit buffer                  |
|      06 |        | R/W | **Mouse Data Register (MDR)**<br/>Read: Returns next byte from mouse receive buffer<br/>Write: Adds byte to mouse transmit buffer                           |
|      07 |        | R/W | **Timer Control Register (TCR)**                                                                                                                            |
|         |      7 | R/W | Timer Interrupt: High when timer has fired, writing a one to this bit clears the timer                                                                      |
|         |      6 |  W  | Timer Start: Writing a one to this bit starts the timer                                                                                                     |
|         |    5-0 |     | Reserved                                                                                                                                                    |
|      08 |        | R/W | **Timer Counter Low (TLL)**<br/>Low byte of length in milliseconds for timer.                                                                               |
|      09 |        | R/W | **Timer Counter High (TLH)**<br/>High byte of length in milliseconds for timer.                                                                             |
|   0A-0D |        |  R  | **Millisecond Clock Register (MCR)**                                                                                                                        |
|   0E-1F |        |     | Reserved                                                                                                                                                    |
|   20-21 |        |     | Reserved                                                                                                                                                    |
|   22-23 |        |     | Reserved                                                                                                                                                    |
|   24-25 |        |     | **Native COP Vector**                                                                                                                                       |
|   26-27 |        |     | **Native BRK Vector**                                                                                                                                       |
|   28-29 |        |     | **Native ABORT Vector**                                                                                                                                     |
|   2A-2B |        |     | **Native NMI Vector**                                                                                                                                       |
|   2C-2D |        |     | Reserved                                                                                                                                                    |
|   2E-2F |        |     | **Native IRQ Vector**                                                                                                                                       |
|   30-31 |        |     | Reserved                                                                                                                                                    |
|   32-33 |        |     | Reserved                                                                                                                                                    |
|   34-35 |        |     | **Emulation COP Vector**                                                                                                                                    |
|   36-37 |        |     | Reserved                                                                                                                                                    |
|   38-39 |        |     | **Emulation ABORT Vector**                                                                                                                                  |
|   3A-3B |        |     | **Emulation NMI Vector**                                                                                                                                    |
|   3C-3D |        |     | **Emulation RESET Vector**                                                                                                                                  |
|   3E-3F |        |     | **Emulation IRQ/BRK Vector**                                                                                                                                |
