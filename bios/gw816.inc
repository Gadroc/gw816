;
; Copyright 2023 Craig Courtney
;
; Redistribution and use in source and binary forms, with or without
; modification, are permitted provided that the following conditions are met:
;
; 1. Redistributions of source code must retain the above copyright notice,
;    this list of conditions and the following disclaimer.
;
; 2. Redistributions in binary form must reproduce the above copyright notice,
;    this list of conditions and the following disclaimer in the documentation
;    and/or other materials provided with the distribution.
;
; 3. Neither the name of the copyright holder nor the names of its contributors
;    may be used to endorse or promote products derived from this software
;    without specific prior written permission.
;
; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
; AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
; ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
; LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
; CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
; SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
; CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
; ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
; POSSIBILITY OF SUCH DAMAGE.
;

;
; Clio Regsiter Map
;
REG_SCR = $FF80 ; System Control Register
REG_RTA = $FF81 ; ROM Target Address
REG_RBA = $FF83 ; ROM Bank Address
REG_RDR = $FF84 ; Rom Data Regiseter
REG_ISR = $FF85 ; Interrupt Status Register
REG_ICR = $FF86 ; Interrupt Control Register
REG_CDR = $FF87 ; Console Data Register
REG_SDR = $FF88 ; Serial Data Register
REG_SPC = $FF89 ; SPI Control Register
REG_SPD = $FF8A ; SPI Data Register

;
; SCR Flags
;
SCR_CPU_FMASK   = %00000111
SCR_CPU_SMASK   = %11111000
SCR_CPU_10KHZ   = %00000000
SCR_CPU_1000KHZ = %00000001
SCR_CPU_500KHZ  = %00000010
SCR_CPU_1MHZ    = %00000011
SCR_CPU_2MHZ    = %00000100
SCR_CPU_4MHZ    = %00000101
SCR_CPU_6MHZ    = %00000110
SCR_CPU_8MHZ    = %00000111
SCR_LED_FMASK   = %00011000
SCR_LED_SMASK   = %11100111
SCR_LED_OFF     = %00000000
SCR_LED_ON      = %00001000
SCR_LED_SLOW    = %00010000
SCR_LED_FAST    = %00011000
SCR_ROM_RESET   = %00100000
SCR_ROM_READY   = %01000000
SCR_ROM_COMPLETE= %10000000

;
; ISR Flags
;
ISR_CONSOLE_TX_RDY  = %00000001
ISR_CONSOLE_RX_RDY  = %00000010
ISR_SERIAL_TX_RDY   = %00000100
ISR_SERIAL_RX_RDY   = %00001000
ISR_SPI_TX_COMPLETE = %00010000
ISR_SPI_BUSY        = %00100000

;
; Macro set a register value
;
.macro  SET_REGISTER register, mask, value
        .a8
        lda             register
        and             #mask
        ora             #value
        sta             register
.endmacro

;
; CPU Mode Macros
;
; Switch CPU to Native Mode
.macro SET_NATIVE_MODE
        clc
        xce
.endmacro

; Siwtch CPU to Emulation Mode
.macro SET_EMU_MODE
        sec
        xce
        .a8
        .i8
.endmacro

; Switch Memory and Index registers to 16 bit mode
.macro SET_MX_16BIT
        rep #%00110000
        .a16
        .i16
.endmacro

; Expect Memory and Index registers to be in 16 bit mode
.macro EXP_MX_16BIT
        .a16
        .i16
.endmacro

; Switch Memory and Index registers to 8 bit mode
.macro SET_MX_8BIT
        sep #%00110000
        .a8
        .i8
.endmacro

; Expect Memory and Index registers to be in 8 bit mode
.macro EXP_MX_8BIT
        .a8
        .i8
.endmacro

; Switch Memory registers to 16 bit mode
.macro SET_M_16BIT
        rep #%00100000
        .a16
.endmacro

; Expect Memory registers to be in 16 bit mode
.macro EXP_M_16BIT
        .a16
.endmacro

; Switch Memory registers to 8 bit mode
.macro SET_M_8BIT
        sep #%00100000
        .a8
.endmacro

; Expect Memory registers to be in 16 bit mode
.macro EXP_M_8BIT
        .a8
.endmacro

; Set Index registers to 16 bit mode
.macro SET_X_16BIT
        rep #%00010000
        .i16
.endmacro

; Expect Index registers to 16 bit mode
.macro EXP_X_16BIT
        .i16
.endmacro

; Set Index registers to 8 bit mode
.macro SET_X_8BIT
        sep #%00010000
        .i8
.endmacro

; Set Index registers to 8 bit mode
.macro EXP_X_8BIT
        .i8
.endmacro
