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
; BIOS
;
;===============================================================================

.include "gw816.inc"

.export BiosInit

.code
.proc BiosInit
    EXP_MX_8BIT
    SET_REGISTER REG_SCR, SCR_LED_SMASK, SCR_LED_ON

    SET_M_16BIT
    lda #$0fff
    tcs
    SET_M_8BIT

    lda #'h'
    jsr PutChar
    lda #'e'
    jsr PutChar
    lda #'l'
    jsr PutChar
    lda #'l'
    jsr PutChar
    lda #'o'
    jsr PutChar
    lda #' '
    jsr PutChar
    lda #'w'
    jsr PutChar
    lda #'o'
    jsr PutChar
    lda #'r'
    jsr PutChar
    lda #'l'
    jsr PutChar
    lda #'d'
    jsr PutChar


@loop:
    bra @loop
.endproc

.proc PutChar
    EXP_MX_8BIT
    xba
    lda #ISR_CONSOLE_TX_RDY
:   bit REG_ISR
    beq :-
    xba
    sta REG_CDR
    rts
.endproc
