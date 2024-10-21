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
; Test Cases For Memory Management System
;===============================================================================
.include "gw816.inc"
.include "kernel.inc"
.include "kernel-api.inc"
.include "kernel-memory.inc"
.include "monitor-display.inc"

.export MemoryManagementTests

.zeropage
block_iterator:     .word $0000, $0000
block_size:         .word $0000, $0000
block_next:         .word $0000, $0000
block_count:        .word $0000
free_mem:           .word $0000, $0000

.segment "KERNEL_BSS"
mem_pointer_1:      .word $0000, $0000
mem_pointer_2:      .word $0000, $0000
mem_pointer_3:      .word $0000, $0000
mem_pointer_4:      .word $0000, $0000
mem_pointer_5:      .word $0000, $0000
mem_pointer_6:      .word $0000, $0000
mem_pointer_7:      .word $0000, $0000
mem_pointer_8:      .word $0000, $0000

.segment "KERNEL_DATA"
str_fail_1:         .byte " ** Failed ", 0
str_fail_2:         .byte " (Expected: ", 0
str_fail_3:         .byte " Acutal: ", 0
str_fail_4:         .byte ") ", 10, 13, 0

str_block_count:    .byte "Block Count", 0
str_free_mem:       .byte "Free Memory", 0
str_return:         .byte "Return", 0

str_adding_memory:  .byte "Adding Memory                      : ", 0

str_cmd_end:        .byte "): ", 0
str_endline:        .byte 10, 13, 0

str_block_start:    .byte " # Free Block Start: $", 0
str_block_size:     .byte " - Size: $", 0
str_block_flags:    .byte " - Flags: $", 0

str_alloc_1:        .byte "Allocating (Flags:", 0
str_alloc_2:        .byte " Size:", 0

str_free_1:         .byte "Freeing           (Addr: $", 0

str_success:        .byte "Success", 10, 13, 0
str_error:          .byte "Error", 10, 13, 0

.macro assert_success
    bcs :+
    pea str_error
    jsr MonitorPrintString
    bra :++
:   pea str_success
    jsr MonitorPrintString
:   nop
.endmacro

.macro assert_failure
    bcc :+
    pea str_error
    jsr MonitorPrintString
    bra :++
:   pea str_success
    jsr MonitorPrintString
:   nop
.endmacro

.macro assert_ptr_equal actual, expected
    lda actual
    cmp #expected & $ffff
    bne :+
    lda actual + 2
    cmp #expected >> 16
    bne :+
    bra :++

:   pea str_fail_1
    jsr MonitorPrintString

    pea str_return
    jsr MonitorPrintString

    pea str_fail_2
    jsr MonitorPrintString

    lda #expected >> 16
    jsr MonitorPrintHexWord
    lda #expected & $ffff
    jsr MonitorPrintHexWord

    pea str_fail_3
    jsr MonitorPrintString

    lda actual + 2
    jsr MonitorPrintHexWord
    lda actual
    jsr MonitorPrintHexWord

    pea str_fail_4
    jsr MonitorPrintString
: nop
.endmacro

.macro assert_free_mem blocks, total_free
    jsr CaluclateFreeMemory

    ldx #$00

    lda block_count
    cmp #blocks
    beq :+

    ldx #$01

    pea str_fail_1
    jsr MonitorPrintString

    pea str_block_count
    jsr MonitorPrintString

    pea str_fail_2
    jsr MonitorPrintString

    lda #blocks
    jsr MonitorPrintHexByte

    pea str_fail_3
    jsr MonitorPrintString

    lda block_count
    jsr MonitorPrintHexByte

    pea str_fail_4
    jsr MonitorPrintString

:   lda free_mem
    cmp #total_free & $ffff
    bne :+
    lda free_mem + 2
    cmp #total_free >> 16
    bne :+
    bra :++

:   pea str_fail_1
    jsr MonitorPrintString

    ldx #$01

    pea str_free_mem
    jsr MonitorPrintString

    pea str_fail_2
    jsr MonitorPrintString

    lda #total_free >> 16
    jsr MonitorPrintHexWord
    lda #total_free & $ffff
    jsr MonitorPrintHexWord

    pea str_fail_3
    jsr MonitorPrintString

    lda free_mem + 2
    jsr MonitorPrintHexWord
    lda free_mem
    jsr MonitorPrintHexWord

    pea str_fail_4
    jsr MonitorPrintString

:   cpx #$00
    beq :+

    jsr DumpMemoryBlocks

:   nop
.endmacro

.macro free ptr

    pea str_free_1
    jsr MonitorPrintString

    lda ptr + 2
    jsr MonitorPrintHexWord
    lda ptr
    jsr MonitorPrintHexWord

    pea str_cmd_end
    jsr MonitorPrintString

    lda ptr + 2
    pha
    lda ptr
    pha

    lda #$0001
    cop $01

    pla
    pla

.endmacro

.macro malloc flags, alloc_size, ptr
    pea str_alloc_1
    jsr MonitorPrintString

    lda #flags
    jsr MonitorPrintHexByte

    pea str_alloc_2
    jsr MonitorPrintString

    lda #alloc_size >> 16
    jsr MonitorPrintHexWord
    lda #alloc_size & $ffff
    jsr MonitorPrintHexWord

    pea str_cmd_end
    jsr MonitorPrintString

    ; Flags
    pea flags
    ; Size
    pea alloc_size >> 16
    pea alloc_size & $ffff
    ; Return Location
    pea $0000
    pea $0000

    lda #$0000
    cop $00

    pla
    sta ptr
    pla
    sta ptr + 2

    .repeat 3
    pla
    .endrepeat

.endmacro

.segment "KERNEL_CODE"
EXP_MX_16BIT
MemoryManagementTests:

    pea str_adding_memory
    jsr MonitorPrintString

    ; Flags
    pea MEM_ALOC_IO
    ; Start of memory
    pea $0001
    pea $0000
    ; Size of memory
    pea $0002
    pea $0000

    jsr MemoryAdd

    assert_success
    assert_free_mem 1, $00020000

    pea str_adding_memory
    jsr MonitorPrintString

    ; Flags
    pea $0000
    ; Start of memory
    pea $0003
    pea $0000
    ; Size of memory
    pea $0003
    pea $0000

    jsr MemoryAdd

    assert_success
    assert_free_mem 2, $00050000

    malloc $0000, $00000C00, mem_pointer_1
    assert_success
    assert_ptr_equal  mem_pointer_1, $0003000A
    assert_free_mem 2, $0004F3F6

    malloc MEM_ALLOC_CLEAR, $00000C00, mem_pointer_2
    assert_success
    assert_ptr_equal  mem_pointer_2, $00030C14
    assert_free_mem 2, $0004E7EC

    malloc $0000, $00000C00, mem_pointer_3
    assert_success
    assert_ptr_equal mem_pointer_3, $0003181E
    assert_free_mem 2, $0004DBE2

    free mem_pointer_2
    assert_success
    assert_free_mem 3, $0004E7EC

    malloc $0000, $000003FF, mem_pointer_2
    assert_success
    assert_ptr_equal  mem_pointer_2, $00030C14
    assert_free_mem 3, $0004E3E2

    malloc $0000, $000007F2, mem_pointer_4
    assert_success
    assert_ptr_equal  mem_pointer_4, $0003101E
    assert_free_mem 2, $0004DBE2

    malloc $0000, $0000DBDA, mem_pointer_5
    assert_success
    assert_ptr_equal  mem_pointer_5, $00032428
    assert_free_mem 2, $0003FFFE

    malloc MEM_ALLOC_EXEC, $00008000, mem_pointer_6
    assert_success
    assert_ptr_equal  mem_pointer_6, $0004000C
    assert_free_mem 2, $00037FF4

    malloc MEM_ALLOC_EXEC, $00008000, mem_pointer_7
    assert_success
    assert_ptr_equal  mem_pointer_7, $0005000A
    assert_free_mem 3, $0002FFEA

    malloc MEM_ALLOC_EXEC, $00010000, mem_pointer_8
    assert_failure
    assert_free_mem 3, $0002FFEA

    free mem_pointer_6
    assert_success
    assert_free_mem 3, $00037FF4

    free mem_pointer_4
    assert_success
    assert_free_mem 4, $000387F4

    free mem_pointer_5
    assert_success
    assert_free_mem 4, $000463D8

    free mem_pointer_7
    assert_success
    assert_free_mem 3, $0004E3E2

    free mem_pointer_3
    assert_success
    assert_free_mem 2, $0004EFEC

    free mem_pointer_2
    assert_success
    assert_free_mem 2, $0004F3F6

    free mem_pointer_1
    assert_success
    assert_free_mem 2, $00050000

@alloc2:
    bra @alloc2

;-------------------------------------------------------------------------------
; CaluclateFreeMemory: Iterate over free memory blocks and calculate block
;                      count and total free memory
;-------------------------------------------------------------------------------
CaluclateFreeMemory:
    cp32 memory_first_block, block_iterator
    stz block_count
    z32 free_mem

@loop:
    lda block_iterator + 2
    beq @exit

    inc block_count

    clc
    lda free_mem
    ldy #memory_block_free::size
    adc [block_iterator], y
    sta free_mem
    lda free_mem + 2
    ldy #memory_block_free::size + 2
    adc [block_iterator], y
    sta free_mem + 2

    cp32si block_iterator, memory_block_free::next, block_next
    cp32 block_next, block_iterator
    bra @loop

@done:
    rts

;-------------------------------------------------------------------------------
; DumpMemoryBlocks: Iterate over free memory blocks and display them
;-------------------------------------------------------------------------------
DumpMemoryBlocks:
    cp32 memory_first_block, block_iterator

@loop:
    lda block_iterator + 2
    beq @exit

    pea str_block_start
    jsr MonitorPrintString

    lda block_iterator + 2
    jsr MonitorPrintHexWord
    lda block_iterator
    jsr MonitorPrintHexWord

    pea str_block_size
    jsr MonitorPrintString

    cp32si block_iterator, memory_block_free::size, block_size

    lda block_size + 2
    jsr MonitorPrintHexWord
    lda block_size
    jsr MonitorPrintHexWord

    pea str_block_flags
    jsr MonitorPrintString

    ldy #memory_block_free::flags
    lda [block_iterator], y
    jsr MonitorPrintHexWord

    pea str_endline
    jsr MonitorPrintString

    cp32si block_iterator, memory_block_free::next, block_next
    cp32 block_next, block_iterator

    bra @loop

@done:
    rts
