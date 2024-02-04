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
; Kernel API Calls
;===============================================================================

;
; Stack Frame relative addresses for kernel trap calls
;
frame_kernel_reg_c      = 1
frame_kernel_reg_x      = frame_kernel_reg_c + 2
frame_kernel_reg_y      = frame_kernel_reg_x + 2
frame_kernel_reg_d      = frame_kernel_reg_y + 2
frame_kernel_reg_sr     = frame_kernel_reg_d + 2
frame_kernel_reg_pc     = frame_kernel_reg_sr + 1
frame_kernel_reg_pb     = frame_kernel_reg_pc + 2
frame_kernel_api_start  = frame_kernel_reg_pb + 1

;===============================================================================
; MemoryAlloc: Allocate a block of memory
;===============================================================================
; Stack Inputs
; ----------------------------------------
; flags  : 16-bit collection of MEM_ALLOC_* flags
; size   : 32-bit size of requested block
;
; Stack Outputs
; ----------------------------------------
; address : 32-bit address of allocated memory

MEM_ALLOC_CLEAR  = %0000000000000001 ; Clear memory to zeros during allocation
MEM_ALLOC_EXEC   = %0000000000000010 ; Allocation for executable code:
                                     ; * allocation will not cross bank boundry
                                     ; * allocation may be write protected
MEM_ALOC_IO      = %0000000000000100 ; Allocation for code in pages where IO
                                     ; is available
.global MemoryAlloc

;===============================================================================
; MemoryFree: Releases a block of memory
;===============================================================================
; Stack Inputs
; ----------------------------------------
; pointer : 32-bit pointer to memory to free
.global MemoryFree

;===============================================================================
; MemoryAvailable: Returns total amount of available memory
;===============================================================================
.global MemoryAvailable
