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
; Ring Buffer Macros
;===============================================================================
; All macros assume buffer size = 256 and that MX are in 8-bit mode.

;===============================================================================
; Ring Buffer Write Macro
;===============================================================================
; Stores contents of the accumulators into a ring buffer with head and tail
; pointers in zeropage.  Overruns will erase oldest byte from buffer.
;-------------------------------------------------------------------------------
.macro RING_BUF_WRITE buffer, head, tail
.scope
                xba                 ; save off write data
                lda z:tail          ; check to see if we have enough room
                sec
                sbc z:head
                beq write           ; buffer empty go ahead and write
                cmp #$02
                bcs write           ; there is enough room

                lda z:tail          ; not enought so move tail to make room
                inc
                sta z:tail

write:          xba                  ; pull back write data
                ldx z:head
                sta buffer, x
                inx
                stx z:head
.endscope
.endmacro

;===============================================================================
; Ring Buffer Write Wait
;===============================================================================
; Waits until there is enough space in the buffer to write a byte.
;-------------------------------------------------------------------------------
.macro RING_BUF_WRITE_WAIT head, tail
.scope
wait:           lda z:head          ; check to see if we have enough room
                sec
                sbc z:tail
                beq done            ; buffer empty go ahead and write
                cmp #$02
                bcs wait            ; there is enough room
done:
.endscope
.endmacro

;===============================================================================
; Ring Buffer Write Macro
;===============================================================================
; Reads data from a ring buffer into the accumulator.  Carry flag will be set
; if no data was in buffer.
;-------------------------------------------------------------------------------
.macro RING_BUF_READ buffer, head, tail
.scope
                ldy z:tail          ; check if buffer is empty
                cpy z:head
                beq done

                lda buffer, y       ; load data
                iny                 ; increment the tail
                sty z:tail
                clc
done:
.endscope
.endmacro
