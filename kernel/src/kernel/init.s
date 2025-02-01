;
; Copyright 2025 Craig Courtney
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

.import __STACK_START__, __STACK_SIZE__
.import __RODATA_LOAD__
.import __DATA_LOAD__, __DATA_RUN__, __DATA_SIZE__
.import __BSS_LOAD__, __BSS_SIZE__
.import __DIRECT_START__

.import serial_init, serial_put

.include "gw816.inc"
.include "kernel.inc"

.include "print.inc"
.include "ascii.inc"
.include "ringbuffer.inc"

.zeropage
;-------------------------------------------------------------------------------
MAX_SEGMENT:    .word $0000
test_head: .byte $00
test_tail: .byte $00

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
test_buffer: .res 256
.code
;-------------------------------------------------------------------------------
KERNEL_START:
.scope
                SET_NATIVE_MODE
                SET_MX_16BIT

                lda #__DIRECT_START__
                tcd

                lda #__STACK_START__ + __STACK_SIZE__ - 1
                tcs

                SET_M_8BIT

; Zero out ZP data
                ldx #$0000
:               stz $00, x
                inx
                cpx #$0100
                bne :-

; Zero non-initialized data segment RAM
                ldx #$0000
:               cpx #__BSS_SIZE__
                beq init_data
                stz __BSS_LOAD__, x
                inx
                bra :-

; Copy initialized data segment to RAM
init_data:
                SET_M_16BIT

                lda #__DATA_SIZE__
                beq shadow_copy
                dec
                ldx #(__DATA_LOAD__ & $ffff)
                ldy #(__DATA_RUN__ & $ffff)
                mvn #^__DATA_LOAD__,#^__DATA_RUN__

; Shadow Copy Kernel CODE into RAM to run faster
shadow_copy:
                lda #$3FFF
                ldx #$C000
                ldy #$C000
                mvn #$00,#$00

; We can now turn off ROM
                SET_M_8BIT
                lda MMU_MMC
                ora #MMC_ROM_DISABLE
                sta MMU_MMC
                SET_M_16BIT

                jsr serial_init
;find_max_seg:                       ; Disable VRAM so we can find all RAM
;                SET_M_8BIT
;                lda #MMC_VRAM_DISABLE
;                tsb MMU_MMC
;                SET_M_16BIT
;
;    ;  Reset MR0 to $00000000
;                stz MR0L
;                stz MR0H
;                stz MAX_SEGMENT
;
;    ; Set index to the first segment to test kernel / romstrap
;    ; require the first bank of RAM to exist/work so we just start
;    ; testing at bank one.
;                ldx #$0100
;
;@loop:          stx MR0L+1          ; Replace the upper 12bits of MR0 address
;                lda #$5115
;                sta [MR0]
;                cmp [MR0]
;                bne @done           ; If readback does we are outside working RAM
;                stx MAX_SEGMENT
;                inx
;                cpx #$1000          ; We only support 16MB of RAM
;                bne @loop
;
;    ; Reenable VRAM so we can find all RAM
; @done:         SET_M_8BIT
;                lda #MMC_VRAM_DISABLE
;                trb MMU_MMC
;
;                SET_REGISTER SMC_SCR, SCR_LED_SMASK, SCR_LED_ON
;
    ; Print Welcome
                SET_M_16BIT

                cli

                lda #str_welcome_start
                jsr print_string

                lda MAX_SEGMENT
                inc
                asl
                asl
                jsr print_hex_word

                lda #str_welcome_end
                jsr print_string

                SET_MX_8BIT

                lda z:test_head
                jsr print_hex_byte
                lda z:test_tail
                jsr print_hex_byte
                lda #' '
                jsr serial_put

                lda #$01
                RING_BUF_WRITE test_buffer, test_head, test_tail

                lda z:test_head
                jsr print_hex_byte
                lda z:test_tail
                jsr print_hex_byte
                lda #' '
                jsr serial_put

                lda z:test_tail        ; check to see if we have enough room
                sec
                sbc z:test_head
                jsr print_hex_byte
                lda #' '
                jsr serial_put

                lda #$02
                RING_BUF_WRITE test_buffer, test_head, test_tail
                lda #$03
                RING_BUF_WRITE test_buffer, test_head, test_tail
                lda #$04
                RING_BUF_WRITE test_buffer, test_head, test_tail
                lda #$05
                RING_BUF_WRITE test_buffer, test_head, test_tail
                lda #$06
                RING_BUF_WRITE test_buffer, test_head, test_tail

                lda z:test_head
                jsr print_hex_byte
                lda z:test_tail
                jsr print_hex_byte
                lda #' '
                jsr serial_put

                RING_BUF_READ test_buffer, test_head, test_tail
                lda z:test_head
                jsr print_hex_byte
                lda z:test_tail
                jsr print_hex_byte

                brk
.endscope
