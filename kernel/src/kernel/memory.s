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
; Kernel Memory Management System
;===============================================================================
.include "gw816.inc"
.include "kernel.inc"
.include "kernel-api.inc"
.include "kernel-memory.inc"
.include "kernel-scratch.inc"

;*******************************************************************************
;**                                  DATA                                     **
;*******************************************************************************

.export alloc_block, prev_block, next_block, alloc_remaining, temp_block, adj_size, alloc_offset
.export free_mem, contiguous_mem

alloc_block := scratch+memory_alloc_scratch::alloc_block
prev_block := scratch+memory_alloc_scratch::prev_block
next_block := scratch+memory_alloc_scratch::next_block
alloc_remaining := scratch+memory_alloc_scratch::alloc_remaining
temp_block := scratch+memory_alloc_scratch::temp_block
adj_size := scratch+memory_alloc_scratch::adj_size
alloc_offset := scratch+memory_alloc_scratch::alloc_offset

free_mem := scratch+memory_calc_scratch::free_mem
contiguous_mem := scratch+memory_calc_scratch::contiguous_mem

.zeropage
memory_first_block:    .word $0000, $0000  ; Pointer to first memory block

.segment "KERNEL_CODE"
EXP_MX_16BIT

;*******************************************************************************
;**                       Kernel Internal Entry Points                        **
;*******************************************************************************

;===============================================================================
; MemoryAdd: Adds a region of memory. Should be called with interrupts off.
;===============================================================================
frame_memoryadd_size  = 3
frame_memoryadd_start = frame_memoryadd_size + 4
frame_memoryadd_flags = frame_memoryadd_start + 4
MemoryAdd:
    ; Setup pointer to free block
    fcp32 frame_memoryadd_start, temp_block

    ; Populate size into free block
    fcp32di frame_memoryadd_size, temp_block, memory_block_free::size

    ; Set flags for free block
    lda frame_memoryadd_flags, s
    ldy #memory_block_free::flags
    sta [temp_block], y

    ; Link free block into list
    jsr MemoryAddBlock

    sec
    rts


;*******************************************************************************
;**                        Kernel Trap Entry Points                           **
;*******************************************************************************

;===============================================================================
; MemoryAlloc: Allocate a block of memory
;===============================================================================
frame_memoryalloc_ptr   = frame_kernel_api_start
frame_memoryalloc_size  = frame_memoryalloc_ptr + 4
frame_memoryalloc_flags = frame_memoryalloc_size + 4
MemoryAlloc:
    ; If no free memory blocks clear carry and return
    lda memory_first_block + 2
    beq InvlaidRequest

    ; If requested size is zero clear carry and return
    lda frame_memoryalloc_size, s
    bne @begin_alloc
    lda frame_memoryalloc_size + 2, s
    bne @begin_alloc
    bra InvlaidRequest

@begin_alloc:
    ; Adjust request size to include size of structure overhead
    clc
    lda frame_memoryalloc_size, s
    adc #MEMORY_AMDIN_SPACE
    sta adj_size
    lda frame_memoryalloc_size + 2, s
    adc #$0000
    sta adj_size + 2

@round_up:
    ; Round to up to a multiple of two
    lda #1
    bit adj_size
    beq @apply_min_size             ; If bit zero is not set it's even
    clc
    inc adj_size                    ; If bit zero is set just add one
    bcc @apply_min_size
    inc adj_size + 2                ; and take care of any carryover

@apply_min_size:
    ; Check for minimum size
    lda adj_size + 2                ; If high word is greater than zero
    bne @validate_exec_size         ; we are larger than min size

    sec
    lda adj_size
    sbc #MEMORY_MIN_BLOCK_SIZE
    bcs @validate_exec_size

    lda #MEMORY_MIN_BLOCK_SIZE      ; Use minimumsize instead
    sta adj_size

@validate_exec_size:
    ; If EXEC flag is not set start finding blocks
    lda frame_memoryalloc_flags, s
    bit #MEM_ALLOC_EXEC
    beq MemoryFindBlock

    ; If it is make sure we are not requesting over 64k
    lda adj_size + 2
    beq MemoryFindBlock

InvlaidRequest:
    clc
    jmp KerenelCallReturn


;-------------------------------------------------------------------------------
; MemoryFindBlock: Finds first block that fits memory_alloc_size
;                  alloc_block will contain first matching block
;                  alloc_offset will contain offset into block to use
;                  alloc_remaining will contain the remaining space
;-------------------------------------------------------------------------------
MemoryFindBlock:
    ; Start with first block
    cp32 memory_first_block, alloc_block
    z32 prev_block

@check_loop:
    ; Check to see if the current pointer is null (high byte = zero)
    lda alloc_block + 2
    beq InvlaidRequest

    ; Pull in prev & next
    cp32si alloc_block, memory_block_free::next, next_block

    ; Clear offset
    stz alloc_offset

    ; Check if this IO flag matches free block
    lda frame_memoryalloc_flags, s
    ldy #memory_block_free::flags
    eor [alloc_block], y
    and #MEM_ALOC_IO
    bne @check_next_block 

    ; Subtract requested size from block size
    sec
    ldy #memory_block_free::size
    lda [alloc_block], y
    sbc adj_size
    sta alloc_remaining
    ldy #memory_block_free::size + 2
    lda [alloc_block], y
    sbc adj_size + 2
    sta alloc_remaining + 2
    ; if the result is negative we don't fit
    bcc @check_next_block

    ; It fits but we need to check for bank split if it's an exec request
    lda frame_memoryalloc_flags, s
    bit #MEM_ALLOC_EXEC
    beq MemorySplitBlock

    ;
    ; Bank request are only 16 bit (guraded against before we begin checking
    ; blocks)
    ;

    ; If low word is zero we have at least the whole bank so move forward
    lda alloc_block
    beq MemorySplitBlock

    ; Calculate remaining space in first bank of the target block
    lda #0000
    sec
    sbc alloc_block

    ; If request fits in remaining block space split it
    cmp adj_size
    bcs MemorySplitBlock

    ; Store block offset to next bank and subtract it from remaing
    sta alloc_offset

    sec
    lda alloc_remaining
    sbc alloc_offset
    sta alloc_remaining
    lda alloc_remaining + 2
    sbc #$0000
    sta alloc_remaining + 2
    ; If the resulting high word of the address is not negative it fits
    bcs MemorySplitBlock

@check_next_block:
    ; Check the next block
    cp32 alloc_block, prev_block
    cp32 next_block, alloc_block
    brl @check_loop

;-------------------------------------------------------------------------------
; MemorySplitBlock: Resizes the free block at alloc_block based on alloc_offset
;                   and creates a new free block containing the remaining space
;                   at the top of alloc_block.  This leave room free for the
;                   the new used memory block.
;-------------------------------------------------------------------------------
MemorySplitBlock:
    ; Check to see if there is an offset
    lda alloc_offset
    beq @check_remaining

    ; Check to see if offset larger than min block size if so just keep start
    cmp #MEMORY_MIN_BLOCK_SIZE
    bcs @resize_alloc_block_to_offset

    ; Since we don't have enough space to leave before this allocation we
    ; just add the offest to the size.
    clc
    lda adj_size
    adc alloc_offset
    sta adj_size
    bcc @check_remaining
    inc adj_size + 2
    bra @check_remaining

@resize_alloc_block_to_offset:

    ; Set existing block size to offset
    lda alloc_offset
    ldy #memory_block_free::size
    sta [alloc_block], y
    lda #$0000
    ldy #memory_block_free::size + 2
    sta [alloc_block], y

    ; Alloc block is now the previous block for a possible remainig space block
    cp32 alloc_block, prev_block

    ; Increment target block by offset
    clc
    lda alloc_block
    adc alloc_offset
    sta alloc_block
    lda alloc_block + 2
    adc #$0000
    sta alloc_block + 2

    ; Clear out offset as it was left in an existing block
    stz alloc_offset

@check_remaining:
    ; Check to see if remaining is larger than min block size if so just keep start
    sec
    lda alloc_remaining
    sbc #MEMORY_MIN_BLOCK_SIZE
    lda alloc_remaining + 2
    sbc #$0000
    bcs @splilt_remaining_space

    ; Since remaining is not big enough for a free memory block just add it
    ; to the adjusted size
    clc
    lda adj_size
    adc alloc_remaining
    sta adj_size
    lda adj_size + 2
    adc alloc_remaining + 2
    sta adj_size + 2

    cp32 alloc_block, temp_block
    jsr MemoryRemoveBlock
    bra MemorySetupUsedBlock

@splilt_remaining_space:
    ; Setup temp_block to point to location of remaining space
    clc
    lda alloc_block
    adc adj_size
    sta temp_block
    lda alloc_block + 2
    adc adj_size + 2
    sta temp_block + 2

    ; Size of new block is remaining
    cp32di alloc_remaining, temp_block, memory_block_free::size

    ; Copy flags to new block
    ldy #memory_block_free::flags
    lda [alloc_block], y
    sta [temp_block], y

    ; Insert new block between current prev / next
    jsr MemoryInsertBlock

;-------------------------------------------------------------------------------
; MemorySetupUsedBlock: Converts the current alloc_block to used memory block
;-------------------------------------------------------------------------------
MemorySetupUsedBlock:
    ; Used Record should start after the offset
    clc
    lda alloc_block
    adc alloc_offset
    sta temp_block
    lda alloc_block + 2
    adc #$0000
    sta temp_block + 2

    ; But start adddress for freeing the block up does not include offset
    ; offset was already added to the size earlier
    cp32di alloc_block, temp_block, memory_block_used::start

    ; Copy size into used_block
    cp32di adj_size, temp_block, memory_block_used::size

    ; Copy flags into used_block
    lda frame_memoryalloc_flags, s
    ldy #memory_block_used::flags
    sta [temp_block], y

    ; Setup return address
    clc
    lda temp_block
    adc #MEMORY_AMDIN_SPACE
    sta frame_memoryalloc_ptr, s
    lda temp_block + 2
    adc #$0000
    sta frame_memoryalloc_ptr + 2, s

    ; Check to see if we need to clear allocation contents
    lda frame_memoryalloc_flags, s
    bit #MEM_ALLOC_CLEAR
    beq @done

    ; Setup memory_alloc_temp_block to point to start of returned memory
    fcp32 frame_memoryalloc_ptr, temp_block

    ; Calculate end of clear
    clc
    lda temp_block
    adc frame_memoryalloc_size, s
    sta alloc_block
    lda temp_block + 2
    adc frame_memoryalloc_size + 2, s
    sta alloc_block + 2

@clear_loop:
    lda #$0000
    sta [temp_block]

    ; Increment clear pointer (by 2 as we are in 16-bit mode)
    clc
    lda temp_block
    adc #$02
    sta temp_block
    lda temp_block + 2
    adc #$00
    sta temp_block + 2

    ; Check to see if we've reached the end of clear
    cmp alloc_block + 2
    bne @clear_loop
    lda temp_block
    cmp alloc_block
    bne @clear_loop

@done:
    sec
    jmp KerenelCallReturn


;===============================================================================
; MemoryFree: Free a block of memory
;===============================================================================
MemoryFree:
frame_memoryfree_start  = frame_kernel_api_start

    ; Set alloc_return to used block
    sec
    lda frame_memoryfree_start, s
    sbc #MEMORY_AMDIN_SPACE
    sta alloc_block
    lda frame_memoryfree_start + 2, s
    sbc #$0000
    sta alloc_block + 2

    ; Copy out size so we don't overwrite bit
    cp32si alloc_block, memory_block_used::size, adj_size

    ; Copy flags into free block
    ldy #memory_block_used::flags
    lda [alloc_block], y
    and #MEM_ALOC_IO
    sta alloc_offset

    ; Set temp block to start address of used block
    cp32si alloc_block, memory_block_used::start, temp_block

    ; Copy size into free block
    cp32di adj_size, temp_block, memory_block_free::size

    ; Copy flags into free block
    lda alloc_offset
    ldy #memory_block_free::flags
    sta [temp_block], y

    jsr MemoryAddBlock

    sec
    jmp KerenelCallReturn


;-------------------------------------------------------------------------------
; MemoryAddBlock
;-------------------------------------------------------------------------------
; Inserts free memory defined by temp_block
;-------------------------------------------------------------------------------
MemoryAddBlock:

    ; Clear out prev_block
    z32 prev_block
    cp32 memory_first_block, next_block

@loop:
    lda next_block + 2
    beq MemoryInsertBlock

    ; Check to see if temp_block is after next_block
    sec
    lda next_block
    sbc temp_block
    lda next_block + 2
    sbc temp_block + 2
    bcs MemoryInsertBlock

    cp32 next_block, prev_block
    cp32si prev_block, memory_block_free::next, next_block

    bra @loop

;-------------------------------------------------------------------------------
; MemoryInsertBlock
;-------------------------------------------------------------------------------
; Inserts temp_block into free memory list after prev_block collapsing this
; block into it's neighbors if necessary.
;-------------------------------------------------------------------------------
MemoryInsertBlock:

    ; If previous block is empty then we are the first block
    lda prev_block + 2
    bne @collapse_prev

    cp32 temp_block, memory_first_block
    bra @check_last

@collapse_prev:

    ; Check if this IO flag matches free block
    ldy #memory_block_free::flags
    lda [temp_block], y
    eor [prev_block], y
    and #MEM_ALOC_IO
    bne @link_prev 

    ; Check to see if previous block is adjacent
    clc
    ldy #memory_block_free::size
    lda prev_block
    adc [prev_block], y
    tax
    ldy #memory_block_free::size+2
    lda prev_block+2
    adc [prev_block], y
    cpx temp_block
    bne @link_prev
    cmp temp_block + 2
    bne @link_prev

    ; Add new block size to prev block
    clc
    ldy #memory_block_free::size
    lda [prev_block], y
    adc [temp_block], y
    sta [prev_block], y
    ldy #memory_block_free::size + 2
    lda [prev_block], y
    adc [temp_block], y
    sta [prev_block], y

    cp32 prev_block, temp_block

    bra @check_last

@link_prev:
    cp32di temp_block, prev_block, memory_block_free::next

@check_last:
    ; If we are the last block we are done
    lda next_block + 2
    bne @collapse_next
    z32di temp_block, memory_block_free::next
    rts

@collapse_next:

    ; Check if this IO flag matches free block
    ldy #memory_block_free::flags
    lda [temp_block], y
    eor [next_block], y
    and #MEM_ALOC_IO
    bne @link_next 

    ; Check to see if next block is adjacent
    clc
    ldy #memory_block_free::size
    lda temp_block
    adc [temp_block], y
    tax
    ldy #memory_block_free::size+2
    lda temp_block+2
    adc [temp_block], y
    cpx next_block
    bne @link_next
    cmp next_block + 2
    bne @link_next

    clc
    ldy #memory_block_free::size
    lda [temp_block], y
    adc [next_block], y
    sta [temp_block], y
    ldy #memory_block_free::size + 2
    lda [temp_block], y
    adc [next_block], y
    sta [temp_block], y

    cp32sidi next_block, memory_block_free::next, temp_block, memory_block_free::next

    rts

@link_next:
    cp32di next_block, temp_block, memory_block_free::next
    rts

;-------------------------------------------------------------------------------
; MemoryRemoveBlock
;-------------------------------------------------------------------------------
; Removes temp_block from free memory list between prev_block and next_block
; collapsing this block those blocks if they are adjacent.
;-------------------------------------------------------------------------------
MemoryRemoveBlock:
    lda prev_block + 2
    bne @link_next

    cp32 next_block, memory_first_block
    rts

@link_next:
    cp32di next_block, prev_block, memory_block_free::next
    rts

;===============================================================================
; MemoryAvailable: Returns total amount of available memory
;===============================================================================
MemoryAvailable:
    ; Clear out prev_block
    cp32 memory_first_block, temp_block
    z32 prev_block
    z32 free_mem
    z32 contiguous_mem

@loop:
    lda temp_block + 2
    beq @done

    ; Add blocks size to total free meme
    clc
    lda free_mem
    ldy #memory_block_free::size
    adc [temp_block], y
    sta free_mem
    lda free_mem + 2
    ldy #memory_block_free::size + 2
    adc [temp_block], y
    sta free_mem + 2

    ; Check to see if this is largest block so far
    sec
    lda contiguous_mem
    ldy #memory_block_free::size
    sbc [temp_block], y
    lda contiguous_mem + 2
    ldy #memory_block_free::size + 2
    sbc [temp_block], y
    bcs @next_block

    ; It is so set largest contiguous memory
    lda [temp_block], y
    lda contiguous_mem + 2
    ldy #memory_block_free::size
    lda [temp_block], y
    lda contiguous_mem

@next_block:
    cp32 next_block, prev_block
    cp32si temp_block, memory_block_free::next, temp_block

    bra @loop

@done:
    ; set return values
    sec
    jmp KerenelCallReturn
