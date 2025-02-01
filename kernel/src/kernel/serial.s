;
; Copyright 2025 Craig Courtney
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

.include "gw816.inc"
.include "ringbuffer.inc"

.export serial_init, serial_irq, serial_set_baud, serial_put, serial_get
.import serial_irq_ret

.zeropage
;-------------------------------------------------------------------------------
; Serial Buffers Indexes
;-------------------------------------------------------------------------------
rx_head:        .byte $00
rx_tail:        .byte $00
tx_head:        .byte $00
tx_tail:        .byte $00

.bss
;-------------------------------------------------------------------------------
; Serial Buffers
;-------------------------------------------------------------------------------
rx_buffer:   .res $ff
tx_buffer:   .res $ff

.rodata
;-------------------------------------------------------------------------------
; Baud Rate Divisors
;-------------------------------------------------------------------------------
BAUD_MAX = 7                ; Number of baud rates -1
baud_divisors:  .word 26665     ;   300 bps
                .word  6665     ;  1200 bps
                .word  3332     ;  2400 bps
                .word  1665     ;  4800 bps
                .word   832     ;  9600 bps
                .word   554     ; 14400 bps
                .word   415     ; 19200 bps
                .word   207     ; 38400 bps

.code
;-------------------------------------------------------------------------------
; Initialize Serial Bus
;-------------------------------------------------------------------------------
serial_init:
.scope
; Setup UART to fire IRQs and turn on RTS
                php
                SET_M_8BIT
                lda #UART_RX_FULL
                tsb UART_IER
                plp
                rts
.endscope

;-------------------------------------------------------------------------------
; Check for data transfers
; Supported Baud Rates:
; 0 -   300 bps
; 1 -  1200 bps
; 2 -  2400 bps
; 3 -  4800 bps
; 4 -  9600 bps
; 5 - 14400 bps
; 6 - 19200 bps
; 7 - 38400 bps
;-------------------------------------------------------------------------------
; Inputs: .C - Desired baud rate
; Outputs: c - Set if invalid baud rate is passed
;-------------------------------------------------------------------------------
serial_set_baud:
.scope
                php

; Check to see if # a is greater than BAUD_MAX
                SET_MX_8BIT
                cmp #BAUD_MAX
                bcc error
                lsr
                tax
                SET_M_16BIT
                lda baud_divisors, x
                sta UART_DIV
                clc
                plp
                rts

error:          sec
                plp
                rts
.endscope

;-------------------------------------------------------------------------------
; Check for data transfers
;-------------------------------------------------------------------------------
serial_irq:
.scope
; Check ISR to see if their is receive data
                SET_MX_8BIT
                lda UART_ISR
                bit #UART_RX_FULL
                bne serial_irq_rx
;                bit #UART_TX_EMPTY
;                bne serial_irq_tx
                jmp serial_irq_ret

 serial_irq_rx: lda UART_RBR
                RING_BUF_WRITE rx_buffer, rx_head, rx_tail
                jmp serial_irq_ret

;serial_irq_tx:  RING_BUF_READ tx_buffer, tx_head, tx_tail
;                bcs clear_tx_int        ; buffer empty so clear tx int enable
;
;                sta UART_THR
;
;                lda z:tx_tail           ; if there is still more data
;                cmp z:tx_head
;                bne done                ; leave tx int enabled
;
;clear_tx_int:   lda #UART_TX_EMPTY
;                trb UART_IER
;
;done:           jmp serial_irq_ret
.endscope

;-------------------------------------------------------------------------------
; Blocking send of a byte to the debug serial port.
;-------------------------------------------------------------------------------
; Preconditions: m 8-Bit
; Inputs: .A - Byte to send to the debug serial port
; Outputs: .A - Byte that was sent
; Modified: .A, .B
;-------------------------------------------------------------------------------
serial_put:
.scope
                EXP_M_8BIT

                xba

wait:           lda #UART_TX_EMPTY
                bit UART_ISR
                beq wait

                xba
                sta UART_THR

                rts
.endscope

;-------------------------------------------------------------------------------
; Non-blocking fetch of a byte from the debug serial port.
;-------------------------------------------------------------------------------
; Preconditions: m 8-Bit
; Inputs: None
; Outputs: .A - Byte fetched from debug serial port
;          c - Set if no data was available
; Modified: .A, .B, .Y
;-------------------------------------------------------------------------------
serial_get:
                EXP_MX_8BIT
                RING_BUF_READ rx_buffer, rx_head, rx_tail
                rts
