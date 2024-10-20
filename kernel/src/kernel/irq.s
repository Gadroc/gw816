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
.include "ascii.inc"

.rodata
;-------------------------------------------------------------------------------
str_emu_irq:
                VT_FORE_RED
                .byte "** Emulatoin Mode Interrupt Encounterd **"
                ASC_CRLF
                VT_RESET
                .byte 0
str_abort_irq:
                VT_FORE_RED
                .byte "** CPU Abort Encountered **"
                ASC_CRLF
                VT_RESET
                .byte 0
str_nmi_irq:
                VT_FORE_YELLOW
                .byte "** NMI Encountered **"
                ASC_CRLF
                VT_RESET
                .byte 0
str_brk_irq:
                VT_FORE_YELLOW
                .byte "** BRK Encountered **"
                ASC_CRLF
                VT_RESET
                .byte 0

.code
;-------------------------------------------------------------------------------
IRQ_DEVICE_HANDLER:
.scope
                rti
.endscope

IRQ_EMU_HANDLER:
.scope
                SET_NATIVE_MODE
                SET_MX_16BIT
                lda #str_emu_irq
                jsr DEBUG_SPRINT
                stp
.endscope

IRQ_NMI_HANDLER:
.scope
                SET_MX_16BIT
                lda #str_nmi_irq
                jsr DEBUG_SPRINT
                ; TODO Start monitor
                stp
.endscope

IRQ_BRK_HANDLER:
.scope
                phb
                phd

                SET_MX_16BIT
                pha
                phx
                phy

                lda #str_brk_irq
                jsr DEBUG_SPRINT

                jmp [KRNL_VEC_BREAK]
.endscope

IRQ_ABORT_HANDLER:
.scope
                lda #str_abort_irq
                jsr DEBUG_SPRINT
                ; TODO Start monitor
                stp
.endscope
