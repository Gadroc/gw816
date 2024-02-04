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
; Kernel
;===============================================================================
.global KernelInit

;-------------------------------------------------------------------------------
; KerenelCallReturn: Returns from kernel api call
;-------------------------------------------------------------------------------
.global KernelCallDispatcher, KerenelCallReturn

.global ExecutePost

KERNEL_DIRECT_PAGE = $DF00
START_OF_HEAP = $00030000

;-------------------------------------------------------------------------------
; 32-Bit Data Macros
;-------------------------------------------------------------------------------

;
; z32: Zeros out a 32 bit value at desination with option index
;
.macro z32  destination, index

.ifblank index
        stz destination
        stz destination+2
.else
        stz destination, index
        stz destination+2, index
.endif

.endmacro

;
; z32di: Zeros out a 32 bit value at Direct Indirect Long Indexed destination
;
.macro z32di  destination, destination_offset
        lda #$0000
.ifnblank destination_offset
        ldy #destination_offset
        sta [destination], Y
        ldy #destination_offset+2
.else
        sta [destinoation]
        ldy #$02
.endif
        sta [destination], y
.endmacro

;
; cp32: Copies a 32 bit value from source to destination
;
.macro cp32  source, destination
        lda source
        sta destination
        lda source + 2
        sta destination + 2
.endmacro

;
; cp32di: Copies a 32 bit value from source to Direct Indirect Long Indexed
;         destination
;
.macro cp32di  source, destination, destination_offset

        lda source

.ifnblank destination_offset
        ldy #destination_offset
.else
        ldy #$0000
.endif

        sta [destination], y
        lda source + 2

.ifnblank destination_offset
        ldy #destination_offset + 2
.else
        ldy #$0002
.endif

        sta [destination], y
.endmacro

;
; cp32si: Copies a 32 bit value from Direct Indirect Long Indexed source
;         to a Direct Indirect Long Indexed destiation
.macro cp32si  source, source_offset, destination
        ldy #source_offset
        lda [source], y
        sta destination
        ldy #source_offset + 2
        lda [source], y
        sta destination + 2
.endmacro

;
; cp32sidi: Copies a 32 bit value from Direct Indirect Long Indexed source
;           to a Direct Indirect Long Indexed destiation
.macro cp32sidi  source, source_offset, destination, destination_offset
        ldy #source_offset
        lda [source], y
        ldy #destination_offset
        sta [destination], y
        ldy #source_offset + 2
        lda [source], y
        ldy #destination_offset + 2
        sta [destination], y
.endmacro


; fcp32: Copy a 32-bit value from stack frame
.macro fcp32  frame_offset, destination

        lda frame_offset, s
        sta destination
        lda frame_offset + 2, s
        sta destination + 2

.endmacro

; fcpy32id: Copy a 32-bit value from stack frame to Direct Indirect Long
;           Indexed destination
.macro fcp32di  frame_offset, destination, destination_offset

.ifblank destination_offset
        ldy #$0000
.else
        ldy #destination_offset
.endif

        lda frame_offset, s
        sta [destination], y

.ifblank destination_offset
        ldy #$0002
.else
        ldy #destination_offset + 2
.endif
        lda frame_offset + 2, s
        sta [destination], y

.endmacro
