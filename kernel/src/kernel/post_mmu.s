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

;===============================================================================
; POST Tests for MMU
;===============================================================================
.include "gw816.inc"
.include "kernel.inc"
.include "kernel-post.inc"
.include "monitor-display.inc"

.rodata
str_max_segement_start:         .byte "Memory segments: 0000", 0
str_next_segment:               .byte 8, 8, 8, 8, 0
str_newline:                    .byte 10, 13, 0
str_seg0_relocation_start:      .byte "Segemnt Zero Relocation:", 0
str_passed:                     .byte " Passed", 10, 13, 0
str_failed:                     .byte " Failed", 10, 13, 0

.code
.proc PostMmuTest
    jsr FindMaxSegment;
    jsr TestSeg0Relocation;
    jsr TestVramDisable;
    rts;
.endproc

.proc FindMaxSegment
    ; Disable VRAM during this test
    SET_M_8BIT
    lda #PCR_VRAM_DISABLE
    tsb MMU_MMC
    SET_M_16BIT

    pea str_max_segement_start;
    jsr MonitorPrintString

    stz <MR0L
    stz <MR0H

    ; X Contains Segment Address which is the upper 12 bits
    ; of the address.
    ldx #$0100

loop:
    stx <(MR0L+1)
    lda #$5115
    sta [<MR0]
    cmp [<MR0]
    bne exit
    stx <memory_max_segment

    pea str_next_segment
    jsr MonitorPrintString
    lda <memory_max_segment
    jsr MonitorPrintHexWord

    ldx z:<memory_max_segment
    inx
    cpx #$1000
    beq exit
    bra loop

exit:
    pea str_newline
    jsr MonitorPrintString

    ; Re-enable VRAM
    SET_M_8BIT
    lda #PCR_VRAM_DISABLE
    trb MMU_MMC
    SET_M_16BIT

    rts
.endproc

.proc TestPassed
    pea str_passed
    jsr MonitorPrintString
    rts
.endproc

.proc TestFailed
    ; Reset MMU since we may have exited tests early
    stz MMU_S0_OFFSET

    pea str_failed
    jsr MonitorPrintString
    rts
.endproc

; Note: This test must force abs addressing to segment 0 since it may
; get interprested as direct page and which may not be in segment 0.
.proc TestSeg0Relocation

    pea str_seg0_relocation_start
    jsr MonitorPrintString

    ; Setup MR0A to have location where we expect relocation to put data.
    stz <MR0L
    lda #$0001
    sta <MR0H

    ; Clear out data in both zero segment and the redirected segment
    lda #$0000
    sta a:$0000
    sta [<MR0]

    ; Setup up redirection and validate the change happend in the register
    lda #$0010
    sta MMU_S0_OFFSET
    cmp MMU_S0_OFFSET
    bne TestFailed

    ; Save data direct into segment 0 and validate it was put at the expected
    ; location in RAM
    lda #$5115
    sta a:$0000
    cmp [<MR0]
    bne TestFailed

    ; Now remove offset and verify that real segment 0 was not modified
    stz MMU_S0_OFFSET
    cmp a:$0000
    beq TestFailed

    bra TestPassed
.endproc

.proc TestVramDisable

.endproc
