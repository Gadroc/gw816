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
; ML Monitor
;===============================================================================
.include "gw816.inc"
.include "monitor.inc"

.segment "MONITORDATA"
mm_hello: .byte "hello", 0
mm_world: .byte "world", 0

.segment "MONITOR"
MonitorInit:
    rts

MonitorStart:
    cop COP_CONSOLE_CLEARSCREEN

    ldx #00
    ldy #00
    cop COP_CONSOLE_SETCURSORPOS

    lda #^mm_hello
    SET_X_16BIT
    ldx #mm_hello & $ffff
    cop COP_CONSOLE_PUTSTRING
    SET_X_8BIT

    ldx #02
    ldy #02
    cop COP_CONSOLE_SETCURSORPOS

    lda #^mm_world
    SET_X_16BIT
    ldx #mm_world & $ffff
    cop COP_CONSOLE_PUTSTRING
    SET_X_8BIT

@end:
    bra @end
