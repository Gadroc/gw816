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
; Machine Language Monitor Display Functions
;===============================================================================
.include "gw816.inc"
.include "kernel.inc"
.include "monitor-display.inc"

;===============================================================================
; Macros
;===============================================================================
.macro putchar
    xba
    lda #ISR_CONSOLE_TX_RDY

 @wait_for_ready:
    bit REG_ISR
    beq @wait_for_ready

    xba
    sta REG_CDR
.endmacro


.segment "KERNEL_CODE"
EXP_MX_16BIT

;===============================================================================
; MonitorPutChar: Displays a character to the console
;===============================================================================
MonitorPutChar:
    php
    SET_M_8BIT

    putchar

    plp
    rts

;===============================================================================
; MonitorPrintString: Printes a null terminated string to console
;===============================================================================
MonitorPrintString:
    clc
    php
    SET_M_8BIT

    ldy #$0000

@loop:
    lda (4, s), y ; Read string address after 1 byte SR, 2 byte return address
    beq @done
    putchar
    iny
    bpl @loop

    ; Set carry bit for return status
    lda 1, s
    ora #%00000001
    sta 1, s

@done:
    plp ; Restore our stack register
    plx ; Pull the return address
    ply ; Pull string address
    phx ; Push back the return address

    rts

;===============================================================================
; MonitorPrintHexWord: Prints out a word in hex to the console
;===============================================================================
MonitorPrintHexWord:
    php
    SET_M_8BIT

    pha
    xba
    jsr MonitorPrintHexByte
    pla
    jsr MonitorPrintHexByte

    plp
    rts

;===============================================================================
; MonitorPrintHexByte: Prints out a byte in hex to the console
;===============================================================================
MonitorPrintHexByte:
    php
    SET_M_8BIT

    jsr SplitByteToNyble
    jsr PrintHexNyble
    txa
    jsr PrintHexNyble

    plp
    rts


;-------------------------------------------------------------------------------
; PrintHexNyble
;-------------------------------------------------------------------------------
;
; Requirements
; ----------------------------------------
; M - 8 Bit mode
;
; Register Inputs
; ----------------------------------------
; .A: Nybble to print
PrintHexNyble:
    ; If this nybble value is 10 or over add 8 to skip over punctuation
    clc
    cmp #$0A
    bcc :+
    adc #$06    ;  Add offset to skip punctuation (carry flag adds one as well)
:   adc #$30    ;  Offset to zero
    putchar
    rts


;-------------------------------------------------------------------------------
; SplitByteToNyble
;-------------------------------------------------------------------------------
; Splits the target block as necessary memory_alloc_target_block will point to
; used block.
;
; Requirements
; ----------------------------------------
; M - 8 Bit mode
;
; Register Inputs
; ----------------------------------------
; .A: Byte to be split
;
; Register Outputs
; ----------------------------------------
; .A: High Nybble
; .X: Low Nybble
;-------------------------------------------------------------------------------
SplitByteToNyble:
    EXP_M_8BIT
    pha
    and #%00001111
    tax
    pla
    .repeat 4
    lsr
    .endrepeat
    rts
