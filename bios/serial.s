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

;===============================================================================
; LOW-LEVEL SERIAL PORT ROUTINES
;===============================================================================

.include "gw816.inc"
.include "serial.inc"

.zeropage
serial_string_address: .res 3

.macro SerialPortPut data_register, tx_ready_bit
    xba
    lda #tx_ready_bit
:   bit REG_ISR
    beq :-
    xba
    sta data_register
.endmacro

.macro SerialPortGet data_register, rx_ready_bit
    lda #rx_ready_bit
    bit REG_ISR
    bne @load
    sec
    rts
@load:
    lda data_register
    clc
.endmacro

.segment "BIOS"
SerialConsolePutChar:
    EXP_MX_8BIT
    SerialPortPut REG_CDR, ISR_CONSOLE_TX_RDY
    rts

SerialConsolePrintString:
    EXP_M_8BIT
    EXP_X_16BIT
    stx serial_string_address
    sta serial_string_address + 2
    ldy #$00
@loop:
    lda [serial_string_address],y
    beq @done
    SerialPortPut REG_CDR, ISR_CONSOLE_TX_RDY
    iny
    bra @loop
@done:
    rts


SerialConsoleGetChar:
    EXP_MX_8BIT
    SerialPortGet REG_CDR, ISR_CONSOLE_RX_RDY
    rts

SerialDataPutChar:
    EXP_MX_8BIT
    SerialPortPut REG_SDR, ISR_SERIAL_TX_RDY
    rts

SerialDataGetChar:
    EXP_MX_8BIT
    SerialPortGet REG_SDR, ISR_SERIAL_RX_RDY
    rts

SerialDataPrintString:
    rts
