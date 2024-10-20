;
; Copyright 2024 Craig Courtney
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
.include "kernel.inc"
.include "debug.inc"

;===============================================================================
; Debug Serial Port
;===============================================================================

DEBUG_INIT:
                rts

DEBUG_PUT_CHAR:
;-------------------------------------------------------------------------------
; Blocking send of a byte to the debug serial port.
;-------------------------------------------------------------------------------
; Preconditions: m 8-Bit
; Inputs: .A - Byte to send to the debug serial port
; Outputs: .A - Byte that was sent
; Modified: .A, .B
;-------------------------------------------------------------------------------
.scope
                EXP_M_8BIT
                xba                     ; Save off byte to send in .B
                lda #ISR_CONSOLE_TX_RDY ; Wait till TX buffer has room
@wait:          bit SMC_ISR
                beq @wait
                xba                     ; Retrieve byte to send from .B
                sta SMC_CDR             ; Send it to UART
                rts
.endscope

DEBUG_GET_CHAR:
;-------------------------------------------------------------------------------
; Non-blocking fetch of a byte from the debug serial port.
;-------------------------------------------------------------------------------
; Preconditions: m 8-Bit
; Inputs: None
; Outputs: .A - Byte fetched from debug serial port
;          c - Set if no data was available
; Modified: .A
;-------------------------------------------------------------------------------
.scope
                EXP_M_8BIT
                sec                     ; Pre-load carry bit for no data
                lda #ISR_CONSOLE_RX_RDY ; Check to see if RX buffer has data
                bit SMC_ISR
                beq @nodata
                lda SMC_CDR             ; If so read data from UART and
                clc                     ; clear carry to indicated data
@nodata:        rts
.endscope

DEBUG_SPRINT:
;-------------------------------------------------------------------------------
; Prints a null terminated string to the debug serial port
;-------------------------------------------------------------------------------
; Preconditions: Pm- 16-Bit,  DBR- Set to bank where string is located.
; Inputs: .C - Address location of the string to print.
;-------------------------------------------------------------------------------
.scope
                phy
                php

                EXP_M_16BIT
                sta MR0L                ; Store address in string to print

                SET_M_8BIT
                SET_X_16BIT
                ldy #$0000              ; Reset Y to index through string
@loop:          lda (MR0L), y           ; Load next byte of string
                beq @done               ; If it's zero exit out
                jsr DEBUG_PUT_CHAR      ; Send character to UART
                iny                     ; Increment index and check for next
                bne @loop               ;  byte

@done:          plp
                ply
                rts
.endscope

DEBUG_HEX_WORD:
;-------------------------------------------------------------------------------
; Prints a word in HEX format to the debug console.
;-------------------------------------------------------------------------------
; Preconditions: None
; Inputs: .A - Word to print
; Outputs: None
; Changes: .A, .B
;-------------------------------------------------------------------------------
.scope
                php
                SET_M_8BIT

                pha
                xba
                jsr DEBUG_HEX_BYTE

                pla
                jsr DEBUG_HEX_BYTE

                plp
                rts
.endscope

DEBUG_HEX_BYTE:
;-------------------------------------------------------------------------------
; Prints a byte in HEX format to the debug console.
;-------------------------------------------------------------------------------
; Inputs: .A - Byte to print
; Outputs: None
; Changes: .A
;-------------------------------------------------------------------------------
.scope
                phx
                php
                SET_MX_8BIT

@split_byte:    pha                 ; Save off source for high-nibble
                and #%00001111      ; Remove high-nibble
                tax                 ; Store low-nibble in X
                pla                 ; Fetch source for high-nibble
                lsr                 ; Shift high-nibble down to bits 3:0
                lsr
                lsr
                lsr

                jsr @print_nibble
                txa
                jsr @print_nibble

                plp
                plx
                rts

@print_nibble:  clc
                cmp #$0A
                bcc :+
                adc #$06            ; Offset to skip punctuation for A-F
:               adc #$30            ; Offset to ASCII Zero
                jmp DEBUG_PUT_CHAR
.endscope
