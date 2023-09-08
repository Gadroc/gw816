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
.include "bios.inc"
.include "console.inc"
.include "serial.inc"
.include "monitor.inc"

max_api = 7

.segment "ZEROPAGE"
bios_call_cop_address: .res 3

.segment "BIOSDATA"
bios_api_vectors:
    .addr   ConsoleClearScreen
    .addr   ConsoleSetCursorPos
    .addr   ConsoleSetAttributes
    .addr   ConsolePutChar
    .addr   ConsolePutString
    .addr   ConsoleGetChar
    .addr   ConsoleReadLine

.segment "BIOS"
BiosInit:
    EXP_X_8BIT
    SET_M_16BIT
    lda #$cf00                  ; BIOS Direct Page at $cf00
    tcd

    lda #$0fff                  ; BIOS 4k Stack starting at $0fff
    tcs
    SET_M_8BIT

    lda #00                     ; Setup Data bank
    pha
    plb

    SET_REGISTER REG_SCR, SCR_LED_SMASK, SCR_LED_ON

    ;
    ; Initialize BIOS Sub-systems
    ;
    jsr ConsoleInit

    ;
    ; Check for bootloader
    ;

    ;
    ; No boot loader so jmp into monitor
    ;
    jml MonitorStart

@loop:
    bra @loop

BiosDispatch:
    SET_MX_16BIT
    phy                             ; Save off registers
    phx
    pha

    lda bios_frame_reg_pc, s      ; Extract address of COP signature
    dec a
    sta bios_call_cop_address

    SET_M_8BIT                      ; Extract bank of COP signature
    lda bios_frame_reg_pb, s
    sta bios_call_cop_address + 2

    lda [bios_call_cop_address]     ; Fetch COP signature
    SET_M_16BIT
    and #$00ff

    cmp #max_api                    ; Mack sure the API call is not to high
    bcs @invalid_api_index

    asl a                           ; Double our index for address lookup
    tax
    jmp (bios_api_vectors,x)

@invalid_api_index:
    SET_REGISTER REG_SCR, SCR_LED_SMASK, SCR_LED_FAST
@endless:
    bra @endless

BiosReturn:
    SET_MX_16BIT                    ; Restore registers
    pla
    plx
    ply
    rti
