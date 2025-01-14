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

.global __ZEROPAGE_LOAD__, __ZEROPAGE_SIZE__
.global __STACK_START__, __STACK_SIZE__
.global __RODATA_LOAD__
.global __DATA_LOAD__, __DATA_RUN__, __DATA_SIZE__
.global __BSS_LOAD__, __BSS_SIZE__
.global __DIRECT_START__
.global __PCODE_START__

.include "gw816.inc"
.include "kernel.inc"

.include "debug.inc"
.include "ascii.inc"
.include "monitor.inc"

.zeropage
;-------------------------------------------------------------------------------
MAX_SEGMENT:    .word $0000

.rodata
;-------------------------------------------------------------------------------
str_welcome_start:
    ASC_CRLF
    VT_FORE_GREEN
    VT_BRIGHT
    .byte "GW816"
    VT_DIM
    .byte " Debug Console (", 0

str_welcome_end:
    .byte "KB)"
    VT_RESET
    ASC_CRLF
    .byte 0

.bss
;-------------------------------------------------------------------------------
KRNL_VEC_BREAK:
                .word $0000
                .word $0000

.code
;-------------------------------------------------------------------------------
KERNEL_START:
.scope
                SET_NATIVE_MODE
                SET_REGISTER SMC_SCR, SCR_LED_SMASK, SCR_LED_FAST
                SET_MX_16BIT

                lda #__DIRECT_START__
                tcd

                lda #__STACK_START__ + __STACK_SIZE__ - 1
                tcs

clear_zeropage: SET_M_8BIT
                ldx #$0000
:               stz $00, x
                inx
                cpx #$0100
                bne :-

clear_bss:      ldx #$0000
:               cpx #__BSS_SIZE__
                beq init_data
                stz __BSS_LOAD__, x
                inx
                bra :-

init_data:      ldx #$0000
:               cpx #__DATA_SIZE__
                beq init_mmu
                lda __DATA_LOAD__, x
                sta __DATA_RUN__, x
                inx
                bra :-

init_mmu:       SET_M_16BIT

    ; Seg $000 is global access (relocated to process specific seg)
                ldx #$0000
                stx MMU_ACL_SEG
                lda #ACL_MODE_GLOB
                sta MMU_ACL

    ; Seg $001-$0CF contains ROM executable code
                inx
                lda #ACL_READ_ONLY
                MMU_FILL_ACL(__RODATA_LOAD__ >> 12)

    ; Seg $0D0-$DF contains read-only data that has no code
    ; X set to $0D0 from previous fill
                lda #ACL_READ_ONLY|ACL_NO_EXEC
                MMU_FILL_ACL(__DATA_RUN__ >> 12)

    ; Seg $00E0-$0FF contains read-write data and IO but no code
    ; X set to $0E0 from previous fill
                lda #ACL_NO_EXEC
                MMU_FILL_ACL(__PCODE_START__ >> 12)

init_monitor:   lda #MONITOR_BREAK
                sta KRNL_VEC_BREAK
                stz KRNL_VEC_BREAK  + 2

find_max_seg:                       ; Disable VRAM so we can find all RAM
                SET_M_8BIT
                lda #MMC_VRAM_DISABLE
                tsb MMU_MMC
                SET_M_16BIT

    ;  Reset MR0 to $00000000
                stz MR0L
                stz MR0H
                stz MAX_SEGMENT

    ; Set index to the first segment to test kernel / romstrap
    ; require the first bank of RAM to exist/work so we just start
    ; testing at bank one.
                ldx #$0100

@loop:          stx MR0L+1          ; Replace the upper 12bits of MR0 address
                lda #$5115
                sta [MR0]
                cmp [MR0]
                bne @done           ; If readback does we are outside working RAM
                stx MAX_SEGMENT
                inx
                cpx #$1000          ; We only support 16MB of RAM
                bne @loop

    ; Reenable VRAM so we can find all RAM
 @done:         SET_M_8BIT
                lda #MMC_VRAM_DISABLE
                trb MMU_MMC

                SET_REGISTER SMC_SCR, SCR_LED_SMASK, SCR_LED_ON

    ; Print Welcome
                SET_M_16BIT
                lda #str_welcome_start
                jsr DEBUG_SPRINT

                lda MAX_SEGMENT
                inc
                asl
                asl
                jsr DEBUG_HEX_WORD

                lda #str_welcome_end
                jsr DEBUG_SPRINT

                cli

                brk
.endscope
