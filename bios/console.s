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
; CONSOLE BIOS FUNCTIONS
;===============================================================================

.include "gw816.inc"
.include "bios.inc"
.include "console.inc"
.include "serial.inc"

d_escape        = $1b;
d_command       = '[';
d_separator     = ';';
d_set_position  = 'H';

.zeropage
console_decimal_b:          .byte 0
console_decimal_c:          .byte 0
console_decimal_idx:        .byte 0

.segment "BIOSBSS"
console_command_buffer:     .res 17


.segment "BIOSDATA"
console_decimal_table:      .byte 128, 160, 200


.macro appendCharToCommandBuffer char
    lda #char
    sta console_command_buffer, x
    inx
.endmacro

.macro resetCommandBuffer
    ldx #$02
.endmacro

.segment "BIOS"
ConsoleInit:
    ldx #0
    appendCharToCommandBuffer d_escape
    appendCharToCommandBuffer d_command
    rts

ConsoleClearScreen:
    SET_MX_8BIT
    resetCommandBuffer
    appendCharToCommandBuffer '2'
    appendCharToCommandBuffer 'J'
    bra ConsoleSendCommand

ConsoleSetCursorPos:
    SET_MX_8BIT
    resetCommandBuffer
    lda bios_frame_reg_x, s
    jsr ConsoleCommandAppendDecimal
    appendCharToCommandBuffer d_separator
    lda bios_frame_reg_y, s
    jsr ConsoleCommandAppendDecimal
    appendCharToCommandBuffer d_set_position
    bra ConsoleSendCommand

ConsoleSetAttributes:
    SET_MX_8BIT
    resetCommandBuffer
    jmp ConsoleSendCommand

ConsolePutChar:
    SET_MX_8BIT
    lda bios_frame_reg_a, s
    jsr SerialConsolePutChar
    jmp BiosReturn

ConsolePutString:
    lda bios_frame_reg_x, s
    tax
    SET_M_8BIT
    lda bios_frame_reg_a, s
    jsr SerialConsolePrintString
    jmp BiosReturn

ConsoleGetChar:
    rts

ConsoleReadLine:
    rts

ConsoleSendCommand:
    EXP_MX_8BIT
    stz console_command_buffer, x
    SET_X_16BIT
    lda #^console_command_buffer
    ldx #console_command_buffer
    jsr SerialConsolePrintString
    jmp BiosReturn

;
; Stole this routine from http://6502org.wikidot.com/software-output-decimal
; TODO: Comb through and see if it can be updated for 65C816
ConsoleCommandAppendDecimal:
    EXP_MX_8BIT
    stx console_decimal_idx

    ldx #1
    stx console_decimal_c
    inx
    ldy #$40
@a: sty console_decimal_b
    lsr
@b: rol
    bcs @c
    cmp console_decimal_table, x
    bcc @d
@c: sbc console_decimal_table, x
    sec
@d: rol console_decimal_b
    bcc @b
    tay
    cpx console_decimal_c
    lda console_decimal_b
    bcc @e
    beq @f
    stx console_decimal_c
@e: eor #$30

    phx
    ldx console_decimal_idx
    sta console_command_buffer, x
    inx
    stx console_decimal_idx
    plx

@f: tya
    ldy #$10
    dex
    bpl @a

    ldx console_decimal_idx
    rts
