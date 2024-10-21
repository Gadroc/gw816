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

.include "gw816.inc"
.include "kernel.inc"
.include "monitor.inc"
.include "ascii.inc"
.include "debug.inc"

.import __KDIRECT_START__

input_buffer_size = 64

.zeropage
;-------------------------------------------------------------------------------
mon_reg_pbx:    .word $0000                         ; PB Shadow (Program Bank)
mon_reg_pcx:    .word $0000                         ; PC Shadow (Program Counter)
mon_reg_srx:    .byte $00                           ; SR Shadow (Status Register)
mon_reg_cx:     .word $0000                         ; .C Shadow (C Register)
mon_reg_xx:     .word $0000                         ; .X Shadow (X Register)
mon_reg_yx:     .word $0000                         ; .Y Shadow (Y Register)
mon_reg_spx:    .word $0000                         ; SP Shadow (Stack Pointer)
mon_reg_dpx:    .word $0000                         ; DP Shadow (Direct Page)
mon_reg_dbx:    .byte $00                           ; DB Shadow (Data Bank)

input_buffer_idx:   .byte $00                           ; Current Input Buffer Offset
digit_max:          .byte $00
bits_per_digit:     .byte $00

;-------------------------------------------------------------------------------
; Kernel Register Usage
;-------------------------------------------------------------------------------
; MR0 - Console Print String
; MR7 - Console Read Line
;
; MR5 - Current end address
; MR6 - Current start address
;

.bss
;-------------------------------------------------------------------------------
input_buffer:
                .res input_buffer_size+1

.rodata
;-------------------------------------------------------------------------------
str_mon_reg:
                ASC_CRLF
                .byte "  PB  PC   nvmxdizc  .C   .X   .Y   SP   DP  DB"
                ASC_CRLF
                .byte "; ", 0

str_prompt:
                ASC_CRLF
                VT_RESET
                .byte ".", 0

str_error:
                ASC_CRLF
                .byte "** ERROR", 0

str_memline_start:
                ASC_CRLF
                .byte ">", 0

str_memline_ascii:
                .byte ":"
                VT_HIDDEN
                .byte 0

str_memline_end:
                VT_RESET
                .byte 0

str_cursor_on:
                VT_CURSOR_ON
                .byte 0

str_cursor_off:
                VT_CURSOR_OFF
                .byte 0

cmd_table:
                .byte   'R'
                .byte   'M'
                .byte   '>'
                .byte   ';'
                .byte   'F'
                .byte   'C'
                .byte   'H'
                .byte   'T'

cmd_vectors:
                .word display_registers
                .word dump_memory
                .word edit_memory
                .word edit_registers
                .word fill_memory
                .word compare_memory
                .word search_memory
                .word copy_memory

cmd_count = cmd_vectors - cmd_table

;-------------------------------------------------------------------------------
; Macro to parse argument to specific register
;-------------------------------------------------------------------------------
.macro parse_argument_to_reg    reg, err_lbl
                jsr parse_argument
                SET_M_16BIT
                bcs err_lbl
                lda MR1L
                sta z:reg
                lda MR1H
                sta z:reg+2
.endmacro

.macro check_reg_addr_order   start_reg, end_reg, is_after
;-------------------------------------------------------------------------------
; Validates that the end address is after the start address
;-------------------------------------------------------------------------------
; Preconditions: m 16-Bit
; Inputs: MR6 - End address
;         MR7 - Start Address
; Changes: .A
; Outputs: Carry Set if invalid, Carry Cleared if valid
;-------------------------------------------------------------------------------
.scope
                lda z:start_reg+2
                cmp z:end_reg+2
                bcc is_before       ; start high word is before end high word
                bne is_after        ; end high word is before start high word
                lda z:start_reg
                cmp z:end_reg
                beq is_before
                bcs is_after        ; start low word is after end low word
is_before:
.endscope
.endmacro


.code
;-------------------------------------------------------------------------------

MONITOR_BREAK:
;-------------------------------------------------------------------------------
; Monitor entry point when break is encountered.
;-------------------------------------------------------------------------------
; Preconditions: Pm 16-Bit, Px 16-Bit
;                TODO Stack Layout
; Inputs: None
; Outputs: None
; Changes: Everything
;-------------------------------------------------------------------------------
.scope
                EXP_MX_16BIT

                pea __KDIRECT_START__           ; Setup Kernel DP
                pld

                ply                     ; Recover registers
                plx
                pla

                sta mon_reg_cx                  ;.C
                stx mon_reg_xx                  ;.X
                sty mon_reg_yx                  ;.Y

                SET_X_8BIT              ; Use X to pull 8bit data

                pla                     ; DP
                sta mon_reg_dpx

                plx                     ; DB
                stx mon_reg_dbx

                plx                     ; SR
                stx mon_reg_srx

                pla                     ; PC
                sta mon_reg_pcx

                plx                     ; PB
                stx mon_reg_pbx

                SET_MX_16BIT
                tsc
                sta mon_reg_spx

                cli

    ; Falltrhough to register display
.endscope

display_registers:
;-------------------------------------------------------------------------------
; Prints the contents of the shadow registers.
;-------------------------------------------------------------------------------
; Preconditions: m 16-Bit
; Inputs: None
; Outputs: None
; Changes: .A
;-------------------------------------------------------------------------------
.scope
                SET_MX_16BIT
    ; Display Register Labels
                lda #str_mon_reg
                jsr DEBUG_SPRINT

    ; Program Bank
                SET_M_8BIT
                lda mon_reg_pbx
                jsr DEBUG_HEX_BYTE

                jsr print_space

    ; Program Counter
                SET_M_16BIT
                lda mon_reg_pcx
                jsr DEBUG_HEX_WORD

                jsr print_space
                jsr print_space

                SET_MX_8BIT
                ldx mon_reg_srx
                ldy #8
 sr_bit_loop:   txa
                asl
                tax
                lda #'0'
                adc #0
                jsr DEBUG_PUT_CHAR
                dey
                bne sr_bit_loop

                SET_MX_16BIT
                ldx #$0000

register_loop:  jsr print_space
                lda mon_reg_cx,x
                jsr DEBUG_HEX_WORD
                inx
                inx
                cpx #mon_reg_dbx-mon_reg_cx
                bcc register_loop

                SET_M_8BIT
                jsr print_space
                lda mon_reg_dbx
                jsr DEBUG_HEX_BYTE

    ; Fall Through to Command Input
.endscope

monitor_command_clear:
                SET_M_8BIT
                EXP_X_16BIT
                stz input_buffer_idx
monitor_command:
.scope
                SET_M_16BIT
                lda #str_prompt
                jsr DEBUG_SPRINT

                ; Read in command line
                jsr read_line

                ; Extract Command Character from input buffer
                SET_MX_8BIT
                stz input_buffer_idx        ; Reset index to read buffer
                jsr skip_white_space        ; Skip to first character
                bcs monitor_default_error   ; If no char found error
                lda input_buffer, x         ; Load in command character
                cmp #$61
                bcc @cmdcheck
                sbc #$20

                ldx #$00
@cmdcheck:      cmp cmd_table, x
                bne @next

                inc input_buffer_idx        ; Advance index for param parsing
                txa
                clc
                rol
                tax
                jmp (cmd_vectors,x)

@next:          inx
                cpx #cmd_count
                bcs monitor_default_error
                bra @cmdcheck
.endscope


monitor_default_error:
                SET_MX_16BIT
                lda #str_error
monitor_error:
;-------------------------------------------------------------------------------
; Display error and return to command input
;-------------------------------------------------------------------------------
;
;-------------------------------------------------------------------------------
.scope
                jsr DEBUG_SPRINT
                jmp monitor_command_clear
.endscope


dump_memory:
;-------------------------------------------------------------------------------
; Dumps range of memory to the screen, both in HEX and ASCII.  If start address
; is supplied current memory location will be displayed.  If no end address is
; supplied 256 bytes are displayed.
;
; M [start_address] [end_address]
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
.scope
                SET_MX_16BIT

                ; Parse First Param as Start Address
                ; If not present use default size from last value of start
                parse_argument_to_reg MR6, default_end

                ; Parse Second Param as End Address
                ; If not present use default size
                parse_argument_to_reg MR5, default_end

                ; Validate start comes before end
                check_reg_addr_order MR6, MR5, monitor_default_error
                bra dump

                ; Default to sixteen bytes
default_end:    SET_M_16BIT
                lda MR6H
                sta MR5H
                lda MR6L
                adc #$FF
                sta MR5L
                bcc dump
                inc MR5H

dump:           ; Dump current line of data
                jsr print_memory

                ; Increment current address
                lda MR6L
                clc
                adc #$10
                sta MR6L
                bcc next_line
                inc MR6H

                ; Check to see if we are at end address.  If not loop
next_line:      lda MR6H
                cmp MR5H
                bcc dump
                bne done
                lda MR6L
                cmp MR5L
                bcc dump

done:           jmp monitor_command_clear
.endscope


copy_memory:
;-------------------------------------------------------------------------------
; Copies a block of memory to a second location
;
; T start_address end_address dest_address
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
.scope
                EXP_MX_16BIT

                ; Parse First Param as Start Address
                parse_argument_to_reg MR6, error

                ; Parse Second Param as End Address
                parse_argument_to_reg MR5, error

                ; Parse Third Param as destination
                parse_argument_to_reg MR4, error

                ; Validate end is not before start
                check_reg_addr_order MR6, MR5, error
                jmp do_copy

error:          jmp monitor_default_error

do_copy:        ; Check copy direction
                check_reg_addr_order MR6, MR4, forward_copy
                jmp reverse_copy

forward_copy:   ; When dest is before start iterate forwards

@fwd_loop:      ; Copy byte end to dest
                SET_M_8BIT
                lda [MR6]
                sta [MR4]
                SET_M_16BIT

                ; Check if done
                lda MR5H
                cmp MR6H
                bne @increment
                lda MR5L
                cmp MR6L
                bne @increment
                jmp monitor_command_clear

@increment:     ; Increment start and dest and loop to copy byte
                clc
                lda MR6L
                adc #$0001
                sta MR6L
                lda MR6H
                adc #$0000
                sta MR6H

                clc
                lda MR4L
                adc #$0001
                sta MR4L
                lda MR4H
                adc #$0000
                sta MR4H

                bra @fwd_loop

reverse_copy:   ; When dest is after start iterated backwards

                ; Increment dest by size
                lda MR5L
                sbc MR6L
                sta MR1L
                lda MR6H
                sbc MR6H
                sta MR1H

                lda MR4L
                adc MR1L
                sta MR4L
                lda MR4H
                adc MR1H
                sta MR4H

@rev_loop:      ; Copy byte end to dest
                SET_M_8BIT
                lda [MR5]
                sta [MR4]
                SET_M_16BIT

                ; Check if done
                lda MR5H
                cmp MR6H
                bne @decrement
                lda MR5L
                cmp MR6L
                bne @decrement
                jmp monitor_command_clear

@decrement:     ; Decrement end and dest and loop to copy byte
                sec
                lda MR5L
                sbc #$0001
                sta MR5L
                lda MR5H
                sbc #$0000
                sta MR5H

                sec
                lda MR4L
                sbc #$0001
                sta MR4L
                lda MR4H
                sbc #$0000
                sta MR4H

                bra @rev_loop
.endscope


search_memory:
;-------------------------------------------------------------------------------
; Searches through a range of memory for a sequence of bytes.
;
; H start_address end_address seq
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
.scope
@done:          jmp monitor_command_clear
.endscope


edit_memory:
;-------------------------------------------------------------------------------
; Sets memory begining at a start address with a data sequence.
;
; > start_address seq
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
.scope
@done:          jmp monitor_command_clear
.endscope


edit_registers:
;-------------------------------------------------------------------------------
; Updates the shadow values of the registers which will be used when returning
; from break or jumping into code.  Note
;
; ; [[PB] [PC] [SR] [C] [X] [Y] [SP] [DP] [DB]
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
.scope
@done:          jmp monitor_command_clear
.endscope


fill_memory:
;-------------------------------------------------------------------------------
; Fills an address range with a byte of data.
;
; F start_address end_address data
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
.scope
                ; Parse First Param as Start Address
                parse_argument_to_reg MR6, error

                ; Parse Second Param as End Address
                parse_argument_to_reg MR5, error

                ; Validate start is before end
                check_reg_addr_order MR6, MR5, error

                ; Parse Data
                SET_M_8BIT
                jsr parse_argument
                bcs error
                lda MR1L

                SET_X_16BIT
loop:           sta [MR6]

                ldx MR6L
                inx
                stx MR6L
                bne check
                ldx MR6H
                inx
                stx MR6H

check:          ldx MR6H
                cpx MR5H
                bne loop
                ldx MR6L
                cpx MR5L
                bcc loop
                beq loop

                SET_M_16BIT
                jmp monitor_command_clear

error:          jmp monitor_default_error
.endscope


compare_memory:
;-------------------------------------------------------------------------------
; Compares two regions of memory.
;
; C reg1_start reg1_end reg2_start
;-------------------------------------------------------------------------------
;-------------------------------------------------------------------------------
.scope
@done:          jmp monitor_command
.endscope


print_start_address:
;-------------------------------------------------------------------------------
; Prints the current start address
;-------------------------------------------------------------------------------
;
;-------------------------------------------------------------------------------
.scope
                SET_M_8BIT
                lda MR6H
                jsr DEBUG_HEX_BYTE
                SET_M_16BIT
                lda MR6L
                jmp DEBUG_HEX_WORD
.endscope

print_memory:
;-------------------------------------------------------------------------------
; Displays a line of 16 bytes of memory
;-------------------------------------------------------------------------------
; Inputs: MR0 - 24 Bit Address of memory to display
;-------------------------------------------------------------------------------
.scope
                phb
                phy
                php

                SET_M_16BIT
                lda #str_memline_start
                jsr DEBUG_SPRINT

    ; Display Address
                jsr print_start_address

    ; Display Hex Values
                SET_MX_8BIT
                ldy #$00
hex_loop:       jsr print_space
                lda [MR6],y
                jsr DEBUG_HEX_BYTE
                iny
                cpy #$10
                bcc hex_loop

                SET_M_16BIT
                lda #str_memline_ascii
                jsr DEBUG_SPRINT

                SET_M_8BIT
                ldy #$00
ascii_loop:     lda [MR6],y

                cmp #ASC_SPACE
                bcc nonprintable
                cmp #ASC_DEL
                bcc print
nonprintable:   lda #'.'

print:          jsr DEBUG_PUT_CHAR
                iny
                cpy #$10
                bcc ascii_loop

retrun:         SET_M_16BIT
                lda #str_memline_end
                jsr DEBUG_SPRINT

                plp
                ply
                plb
                rts
.endscope


skip_white_space:
;-------------------------------------------------------------------------------
; Advances the input buffer index to the next non-white space character.
;-------------------------------------------------------------------------------
; Precodnitions: Pm 8-Bit, Px 16-Bit
;                input_buffer_idx set to start of scan
; Output: .X, input_buffer_idx: Offset from begining of input buffer to character
;         Pc - Set if no non-white space found, clear if found
;-------------------------------------------------------------------------------
.scope
                php

                SET_MX_8BIT
                ldx input_buffer_idx
next:           lda input_buffer,x
                beq nodata
                cmp #ASC_SPACE
                bne done
                inx
                cpx #input_buffer_size
                beq nodata
                stx input_buffer_idx
                bra next
done:           plp
                clc
                rts

nodata:         plp
                sec
                rts
.endscope


parse_argument:
;-------------------------------------------------------------------------------
; Parses the next argument from tne input buffer.  Argument are supported in
; decimal, hex, or binary representations.  Default is decimals, hexadecimals
; should be prefaced with $ and binary with %.
;-------------------------------------------------------------------------------
; Precodnitions: Pm 8-Bit, Px 16-Bit
;                input_buffer_idx set to start of scan for parameter
; Ouptuts: MR1 - 32 bit parsed value of parameter
; Changes: .A .X
;-------------------------------------------------------------------------------
.scope
                php

                SET_M_16BIT
                stz MR1L
                stz MR1H

                jsr skip_white_space
                bcs failure                     ; No parameter found

    ; Check to see if binary prefix
                SET_MX_8BIT
                lda #$10
                sta digit_max
                lda #$04
                sta bits_per_digit
                lda input_buffer, x
                cmp #'%'
                bne parse_digit
                lda #$02
                sta digit_max
                lda #$01
                sta bits_per_digit

next:           inx
parse_digit:    cpx #input_buffer_size
                beq success

                lda input_buffer, x
                beq success
                cmp #ASC_SPACE
                beq success

                SET_M_16BIT
                ldy bits_per_digit
shift:          clc
                rol MR1L
                rol MR1H
                dey
                bne shift

digit_to_bin:   SET_M_8BIT
                cmp #$61
                bcc sub_zero
                sbc #$20

    ; Subtract out ASCII zero
sub_zero:       sec
                sbc #'0'
                bcc failure

    ; Check to see if we are 0-9 if so we are done
                cmp #10
                bcc check_max

    ; Remove punctuation, and error if value is less than a
                sbc #$07
                bcc failure

    ; Validate value is within range
check_max:      cmp digit_max
                bcs failure

                ora MR1L
                sta MR1L
                bra next

success:        stx input_buffer_idx
                plp
                clc
                rts

failure:        plp
                sec
                rts
.endscope


read_line:
;-------------------------------------------------------------------------------
; Reads a line of data into a buffer
;-------------------------------------------------------------------------------
; Precondition
;-------------------------------------------------------------------------------
.scope
                php

    ; Make sure zero terminated
                SET_MX_8BIT
                ldx input_buffer_idx
                stz input_buffer, x

    ; Print out current content of the buffer
                SET_M_16BIT
                lda #input_buffer
                jsr DEBUG_SPRINT

    ; Turn on the cursor
                lda #str_cursor_on
                jsr DEBUG_SPRINT

                SET_M_8BIT
input_loop:     nop
                jsr DEBUG_GET_CHAR
                bcs input_loop

    ; Check to see if return has been received
                cmp #ASC_CR
                beq return

    ; Check for backspace
                cmp #ASC_BS
                beq backspace

    ; Check for delete
                cmp #ASC_DEL
                beq backspace

    ; Now check to see if we are in ascii range
                cmp #ASC_SPACE
                bcc alert
                cmp #ASC_DEL
                bcs alert

                cpx #input_buffer_size
                bcs alert
                sta input_buffer,x
                inx
                jsr DEBUG_PUT_CHAR
                bra input_loop

alert:          lda #ASC_BELL
                jsr DEBUG_PUT_CHAR
                bra input_loop

backspace:      txa
                beq alert
                dex
                lda #ASC_BS
                jsr DEBUG_PUT_CHAR
                lda #ASC_SPACE
                jsr DEBUG_PUT_CHAR
                lda #ASC_BS
                jsr DEBUG_PUT_CHAR
                bra input_loop

return:         lda #$00
                sta input_buffer,x
                stx input_buffer_idx

                SET_M_16BIT
                lda #str_cursor_off
                jsr DEBUG_SPRINT

                plp
                rts
.endscope


print_space:
;-------------------------------------------------------------------------------
; Prints a space to the debug console
;-------------------------------------------------------------------------------
; Chagnes: .A
;-------------------------------------------------------------------------------
.scope
                php
                SET_MX_8BIT
                lda #ASC_SPACE
                jsr DEBUG_PUT_CHAR
                plp
                rts
.endscope
