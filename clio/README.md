# System Interface Adapter (Clio)
The system interface adapter ...

## Registers
| Address | Bit(s) | R/W | Description                                                                                                                                                 |
|--------:|-------:|:---:|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
|      00 |        |     | **System Control Register (SCR)**                                                                                                                           |
|         |    7:6 |     | Timer 2 Config                                                                                                                                              |
|         |    5:4 |  W  | Timer 1 Config                                                                                                                                              |
|         |        |     |                                                                                                                                                             |
|         |    2:0 | RW  | System Led<br/>00: Off<br/>01: Solid On</br>10: Slow Flash</br>11: Fast Flash                                                                               |
|      01 |        |     | **Interrupt Status Register (ISR)**                                                                                                                         |
|         |      7 |  R  | Timer 2 Interrupt                                                                                                                                           |
|         |      6 |  R  | Timer 1 Interrupt                                                                                                                                           |
|         |    5:2 |     | Reserved                                                                                                                                                    |
|         |      1 |  R  | Console Data Ready: Data is available to read from Console Data Register                                                                                    |
|         |      0 |  R  | Console Transmit Ready: Console transmit buffer has space available                                                                                         |
|      02 |        | R/W | **Interrupt Control Register (ICR)**<br/>High bits enable interrupts for the related status register bit, while low bit disables interrupts on that status. |
|      03 |        | R/W | **Console Data Register (CDR)**<br/>Read: Returns next byte from console receive buffer<br/>Write: Adds byte to console transmit buffer                     |
|      04 |        | R/W | **Timer 1 Counter Low (TLL)**<br/>Low byte of length in milliseconds for timer.                                                                             |
|      05 |        | R/W | **Timer 1 Counter High (TLH)**<br/>High byte of length in milliseconds for timer.                                                                           |
|      04 |        | R/W | **Timer 2 Counter Low (TLL)**<br/>Low byte of length in milliseconds for timer.                                                                             |
|      05 |        | R/W | **Timer 2 Counter High (TLH)**<br/>High byte of length in milliseconds for timer.                                                                           |
|   06-09 |        |  R  | **Millisecond Clock Register (MCR)**                                                                                                                        |
|   0A-1F |        |     | Reserved                                                                                                                                                    |
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
