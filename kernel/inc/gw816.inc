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
;    this list of conditions and the following disclaimer in the documentfation
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
; CPU Mode Macros
;===============================================================================
; Switch CPU to Native Mode
.macro SET_NATIVE_MODE
        clc
        xce
.endmacro

; Siwtch CPU to Emulation Mode
.macro SET_EMU_MODE
        sec
        xce
        .a8
        .i8
.endmacro

; Switch Memory and Index registers to 16 bit mode
.macro SET_MX_16BIT
        rep #%00110000
        .a16
        .i16
.endmacro

; Expect Memory and Index registers to be in 16 bit mode
.macro EXP_MX_16BIT
        .a16
        .i16
.endmacro

; Switch Memory and Index registers to 8 bit mode
.macro SET_MX_8BIT
        sep #%00110000
        .a8
        .i8
.endmacro

; Expect Memory and Index registers to be in 8 bit mode
.macro EXP_MX_8BIT
        .a8
        .i8
.endmacro

; Switch Memory registers to 16 bit mode
.macro SET_M_16BIT
        rep #%00100000
        .a16
.endmacro

; Expect Memory registers to be in 16 bit mode
.macro EXP_M_16BIT
        .a16
.endmacro

; Switch Memory registers to 8 bit mode
.macro SET_M_8BIT
        sep #%00100000
        .a8
.endmacro

; Expect Memory registers to be in 16 bit mode
.macro EXP_M_8BIT
        .a8
.endmacro

; Set Index registers to 16 bit mode
.macro SET_X_16BIT
        rep #%00010000
        .i16
.endmacro

; Expect Index registers to 16 bit mode
.macro EXP_X_16BIT
        .i16
.endmacro

; Set Index registers to 8 bit mode
.macro SET_X_8BIT
        sep #%00010000
        .i8
.endmacro

; Set Index registers to 8 bit mode
.macro EXP_X_8BIT
        .i8
.endmacro

;===============================================================================
; Register Manipulation Macros
;===============================================================================
.macro  SET_REGISTER register, mask, value
.if .asize = 16
        SET_M_8BIT
        lda             register
        and             #mask
        ora             #value
        sta             register
        SET_M_16BIT
.else
        lda             register
        and             #mask
        ora             #value
        sta             register
.endif
.endmacro

;===============================================================================
; 65C816 Interrupt Vector Addresses
;===============================================================================
VEC_COP             = $00FFE4
VEC_BRK             = $00FFE6
VEC_ABORTB          = $00FFE8
VEC_NMIB            = $00FFEA
VEC_IRQB            = $00FFEE
VEC_EMU_COP         = $00FFF4
VEC_EMU_ABORTB      = $00FFF8
VEC_EMU_NMIB        = $00FFFA
VEC_EMU_RESETB      = $00FFFC
VEC_EMU_IRQB_BRK    = $00FFFE

;===============================================================================
; UART Registers
;===============================================================================
; Register Addresses
;-------------------------------------------------------------------------------
UART_THR        = $00BFA0   ; Transmit Data Hold Register
UART_SCR        = $00BFA1   ; Scratch Register
UART_ISR        = $00BFA2   ; Interrupt Status Register
UART_RBR        = $00BFA3   ; Receive Buffer Register
UART_DIV        = $00BFA4   ; Baudrate Divisor
UART_DIVL       = $00BFA4   ; Baudrate Divisor Low Register
UART_DIVH       = $00BFA5   ; Baudrate Divisor High Register
UART_IER        = $00BFA6   ; Interrupt Enable Register
;-------------------------------------------------------------------------------
; UART Flags
;-------------------------------------------------------------------------------
UART_RX_FRAME_ERR  = %10000000   ; Frame Error Bit
UART_RX_OVRRUN_ERR = %01000000   ; Overrun Error Bit
UART_TX_EMPTY      = %00100000   ; Transmit Data Hold Register Emtpy Bit
UART_RX_FULL       = %00010000   ; Receive Buffer Full Bit


;===============================================================================
; MMU (Atlas) Registers
;===============================================================================
; Register Addresses
;-------------------------------------------------------------------------------
MMU_AASID       = $00BFE0   ; Current Active Address Space ID (ASID)
MMU_MMC         = $00BFE1   ; Memory Mapping Control Register
MMU_S0_OFFSET   = $00BFE2   ; Segment Zero Offset
MMU_S0_OFFSET_L = $00BFE3   ; Page Zero Offset Low Byte
MMU_S0_OFFSET_H = $00BFE4   ; Page Zero Offset High Byte
MMU_ACL_SEG     = $00BFE5   ; ACL Segment
MMU_ACL_SEG_L   = $00BFE6   ; ACL Segment Low Byte
MMU_ACL_SEG_H   = $00BFE7   ; ACL Segment High Byte
MMU_ACL         = $00BFE8   ; ACL
MMU_ACL_ASID    = $00BFE9   ; ACL - ASID
MMU_ACL_FLAGS   = $00BFEA   ; ACL - Flags
;-------------------------------------------------------------------------------
; MMC Flags
;-------------------------------------------------------------------------------
MMC_VRAM_DISABLE    = %10000000   ; VRAM Disable Bit
MMC_ROM_DISABLE     = %01000000   ; ROM Disable Bit
MMC_ABORT_CODE_MASK = %00000111   ; Abort Code Mask
;-------------------------------------------------------------------------------
; ACL 16-Bit Access Flags
;-------------------------------------------------------------------------------
ACL_SYS_MASK   = %1111000000000000  ; System Flag Mask
ACL_ALLOCATED  = %1000000000000000  ; System Flag Allocated Bit
ACL_MODE_MASK  = %0000110000000000  ; Access Mode Read Mask
ACL_MODE_SMASK = %1111001111111111  ; Access Mode Set Mask
ACL_MODE_SUP   = %0000000000000000  ; Access Mode Supervisor Only
ACL_MODE_USER  = %0000010000000000  ; Access Mode User Mode ASID
ACL_MODE_GLOB  = %0000100000000000  ; Access Mode Global All ASIDs
ACL_NO_EXEC    = %0000001000000000  ; No Execute Bit
ACL_READ_ONLY  = %0000000100000000  ; Read Only Bit
ACL_ASID_MASK  = %0000000011111111  ; ASID Read Mask
ACL_ASID_SMASK = %1111111100000000  ; ASID Set Mask
;-------------------------------------------------------------------------------
; ACL 8-Bit Access Flags
;-------------------------------------------------------------------------------
ACL_FLAGS_SYS_MASK   = %11110000    ; System Flag Mask
ACL_FLAGS_ALLOCATED  = %10000000    ; System Flag Allocated Bit
ACL_FLAGS_MODE_MASK  = %00001100    ; Access Mode Mask
ACL_FLAGS_MODE_SMASK = %11110011    ; Access Mode Set Mask
ACL_FLAGS_MODE_SUP   = %00000000    ; Access Mode Supervisor Only
ACL_FLAGS_MODE_USER  = %00000100    ; Access Mode User Mode ASID
ACL_FLAGS_MODE_GLOB  = %00001000    ; Access Mode Global All ASIDs
ACL_FLAGS_NO_EXEC    = %00000010    ; No Execute Bit
ACL_FLAGS_READ_ONLY  = %00000001    ; Read Only Bit
;-------------------------------------------------------------------------------
; MMU Macos
;-------------------------------------------------------------------------------
; Fills a region of ACLs with the same ASID
; Expects: Pm - 16-Bit, Px - 16-Bit
; Inputs : C - ACL Register Continats (ASID+Flags), X - Start Segment
; Params : length - Number of segments to fill
.macro MMU_FILL_ACL length
:       stx MMU_ACL_SEG
        sta MMU_ACL
        inx
        cpx #length
        bne :-
.endmacro