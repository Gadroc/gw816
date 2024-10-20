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
; SMC (Clio)
;===============================================================================
; Register Addresses
;-------------------------------------------------------------------------------
SMC_SCR  = $00FFC0 ; System Control Register
SMC_RDR  = $00FFC1 ; Rom Data Regiseter
SMC_ISR  = $00FFC2 ; Interrupt Status Register
SMC_ICR  = $00FFC3 ; Interrupt Control Register
SMC_CDR  = $00FFC4 ; Console Data Register
SMC_KDR  = $00FFC5 ; Keyboard Data Register
SMC_MDR  = $00FFC6 ; Mouse Data Register
SMC_TCR  = $00FFC7 ; Timer Control Register
SMC_TMC  = $00FFC8 ; Timer Counter
SMC_TMCL = $00FFC8 ; Timer Counter Low Register
SMC_TMCH = $00FFC9 ; Timer Coutner High Register
SMC_MCR  = $00FFCA ; Millisecond Clock Register (32-bit ms since reset)
;-------------------------------------------------------------------------------
; SCR Flags
;-------------------------------------------------------------------------------
SCR_ROM_RESET       = %01000000
SCR_ROM_COMPLETE    = %10000000
SCR_LED_MASK        = %00000011
SCR_LED_SMASK       = %11111100
SCR_LED_OFF         = %00000000
SCR_LED_ON          = %00000001
SCR_LED_SLOW        = %00000010
SCR_LED_FAST        = %00000011
;-------------------------------------------------------------------------------
; ISR Flags
;-------------------------------------------------------------------------------
ISR_CONSOLE_TX_RDY  = %00000001
ISR_CONSOLE_RX_RDY  = %00000010
ISR_KEYBOARD_TX_RDY = %00000100
ISR_KEYBOARD_RX_RDY = %00001000
ISR_MOUSE_RX_RDY    = %00010000

;===============================================================================
; MMU (Atlas) Registers
;===============================================================================
; Register Addresses
;-------------------------------------------------------------------------------
MMU_AASID       = $00FFA8   ; Current Active Address Space ID (ASID)
MMU_MMC         = $00FFA9   ; Memory Mapping Control Register
MMU_S0_OFFSET   = $00FFAA   ; Segment Zero Offset
MMU_S0_OFFSET_L = $00FFAA   ; Page Zero Offset Low Byte
MMU_S0_OFFSET_H = $00FFAB   ; Page Zero Offset High Byte
MMU_ACL_SEG     = $00FFAC   ; ACL Segment
MMU_ACL_SEG_L   = $00FFAC   ; ACL Segment Low Byte
MMU_ACL_SEG_H   = $00FFAD   ; ACL Segment High Byte
MMU_ACL         = $00FFAE   ; ACL
MMU_ACL_ASID    = $00FFAE   ; ACL - ASID
MMU_ACL_FLAGS   = $00FFAF   ; ACL - Flags
;-------------------------------------------------------------------------------
; MMC Flags
;-------------------------------------------------------------------------------
MMC_VRAM_DISABLE    = %10000000   ; VRAM Disable Bit
MMC_USER_MOD_EN     = %01000000   ; User Mode Enabled Bit
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
