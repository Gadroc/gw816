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
; Kernal Initialization and API Dispatcher
;===============================================================================

.include "gw816.inc"
.include "kernel.inc"
.include "kernel-api.inc"

.import __ZEROPAGE_SIZE__
.import MemoryManagementTests

.zeropage
kernel_api_call_count = 3

.segment "KERNEL_DATA"
kernel_api_vectors:
    .addr MemoryAlloc
    .addr MemoryFree
    .addr MemoryAvailable

.segment "KERNEL_CODE"
.proc KernelInit
    SET_MX_16BIT

    lda #KERNEL_DIRECT_PAGE       ; BIOS Direct Page at top of zero page
    tcd

    lda #KERNEL_DIRECT_PAGE-1     ; BIOS Stack at top of zero page
    tcs

    SET_M_8BIT

    ; Zero out ZeroPage variables
    ldx #$00
 :  stz $00, x
    inx
    cpx #__ZEROPAGE_SIZE__
    bne :-

    SET_REGISTER REG_SCR, SCR_LED_SMASK, SCR_LED_ON ; Turn on system led

    SET_M_16BIT

    cli

    jmp MemoryManagementTests

@loop:
    bra @loop
.endproc

KernelCallDispatcher:
    SET_MX_16BIT
    phd                             ; Save off registers
    phy
    phx
    pha

    asl a                           ; Multiply by 2 to get lookup index
    tax

    cli

    lda #KERNEL_DIRECT_PAGE       ; BIOS Direct Page at top of zero page
    tcd

    jmp (kernel_api_vectors, x)

@invalid_api_index:
    SET_REGISTER REG_SCR, SCR_LED_SMASK, SCR_LED_FAST
@endless:
    bra @endless

KerenelCallReturn:
    EXP_MX_16BIT

    SET_M_8BIT
    lda frame_kernel_reg_sr, s
    bcc @clear_carry
    ora #%00000001
    bra @update_sr
@clear_carry:
    and #%11111110
@update_sr:
    sta frame_kernel_reg_sr, s

    SET_M_16BIT
    pla
    plx
    ply
    pld

    rti
