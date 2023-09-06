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
; BOOTSTRAP
; Since Clio does not have enough address lines to fully emulate ROM, we have
; a small section of bootstrap ROM which will sequentially read BIOS code
; via SCR, RTA, and RDR registers and copy it into RAM.  It will then tranfser
; control to the BIOS Init Vector.
;===============================================================================

.include "gw816.inc"

.export BootstrapStart
.import VEC_BIOS_INIT

.segment "BOOTSTRAP"
BootstrapStart:
        SET_NATIVE_MODE
        EXP_M_8BIT
        SET_X_16BIT

        ; Reset ROM and set LED to slow blink
        ;SET_REGISETER REG_SCR, #%11000111, %00110000
        SET_REGISTER REG_SCR, SCR_LED_SMASK^SCR_ROM_RESET, SCR_LED_SLOW|SCR_ROM_RESET

@rom_copy_loop:
        lda REG_SCR             ; Wait for ROM Ready bit to be set
        bit #SCR_ROM_READY
        beq @rom_copy_loop
        bit #SCR_ROM_COMPLETE
        beq @copy_byte
        SET_X_8BIT
        jmp (VEC_BIOS_INIT)

@copy_byte:
        lda REG_RBA             ; Set data bank for byte copy
        pha
        plb

        ldx REG_RTA
        lda REG_RDR             ; Load current ROM byte
        sta a:$0000,x           ; Save to destination location
        cmp a:$0000,x           ; Now verify it's written
        beq @rom_copy_loop

@rom_fail:
        SET_REGISTER REG_SCR, SCR_LED_SMASK, SCR_LED_FAST
@rom_fail_loop:
        bra @rom_fail_loop


