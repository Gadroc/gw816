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
.include "print.inc"

.import serial_put

;===============================================================================
; Device Print Routines
;===============================================================================

print_string:
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
                sta MR0L                    ; Store address in string to print

                SET_M_8BIT
                SET_X_16BIT
                ldy #$0000                  ; Reset Y to index through string
@loop:          lda (MR0L), y               ; Load next byte of string
                beq @done                   ; If it's zero exit out
                jsr serial_put              ; Send character to UART
                iny                         ; Increment index and check for next
                bne @loop                   ;  byte

@done:          plp
                ply
                rts
.endscope

print_hex_word:
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
                jsr print_hex_byte

                pla
                jsr print_hex_byte

                plp
                rts
.endscope

print_hex_byte:
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
                and #%00001111                  ; Remove high-nibble
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
                adc #$06                        ; Offset to skip punctuation for A-F
:               adc #$30                        ; Offset to ASCII Zero
                jmp serial_put
.endscope
