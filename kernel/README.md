# GW816 Firmware

## Memory Map
|  Start |    End | Description                               |
|-------:|-------:|-------------------------------------------|
| 000000 | 00EFFF | Direct Pages / Stacks (Managed by Kernel) |
| 00F000 | 00FEFF | Interrupt Controllers / Drivers           |
| 00FF00 | 00FFFF | I/O                                       |
| 010000 | 030000 | Kenerl / Drivers (I/O on all banks)       |
| 040000 | F7FFFF | Applications, Libraries, and Data         |
| F80000 | FFFFFF | Video Memory                              |

## Conductor
* Memory Allocation
  * Alloc Memory
  * Dealloc Memory
  * Free Memory

* Process Control
  * Create - Create a process
  * Exit
  * Sleep - Sleep till 
  * Wake - 
  * Wait - Wait for child process to exit
  * Scheduler

* IPC
  * Pipe

* Device
  * Clocks & Timers
  * Block Storage
  * Console
  * NVRAM
  * Serial
  * Keyboard
  * Mouse
  * Keyboard

ML Monitor (Sits on top of conductor)
* Register Dump

DOS
* Filesystem
* Dynamic Linker (Does this need to be in Conductor?)
  * Process o65 for stream\
  cla