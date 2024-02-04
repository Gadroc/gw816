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
; Power On Self Test
;===============================================================================
.include "gw816.inc"
.include "kernel.inc"

.segment "KERNEL_CODE"
EXP_MX_16BIT

;-------------------------------------------------------------------------------
; PuaseMs: Pauses for given number of milliseconds.
;-------------------------------------------------------------------------------
;
; NOTE: This routine is cycle count accurate and only approximates milliseconds.
;
; Technically this should not be a subroutine during ram verification, since
; stack RAM may not be present, Due to the nature of Clio requiring the first
; 512k of RAM present and working before we can get to execution of POST we
; don't have to deal with that.
;
; Inputs
; ----------------------------------------
; .A:
; .B:
; .X: Number of milliseconds to pause
; .Y:
; .SR: NVmxDIZC
;      ||||||||
;      |||||||+--->
;      ||||+++---->
;      |||+-------> 0
;      ||+--------> 1
;      ++--------->
PuaseMs:
    EXP_X_16BIT
    phy

@len_loop:
    ldy #8000

@ms_loop:
    dey
    cpy #0
    bne @ms_loop

    dex
    cpy #0
    bne @len_loop

    ply
    rts

ExecutePost:
    ; TODO Detect Available Memory
    ; TODO Memory Test
    ; TODO Check for RTC presence
    ; TODO Check for disk presence
    ; TODO Check for keyboard & mouse
    rts


