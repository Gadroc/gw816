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
; Machine Language Monitor Display Functions
;===============================================================================

;===============================================================================
; MonitorPutChar: Displays a character to the console
;===============================================================================
; Register Inputs
; ----------------------------------------
; .A: Character to be displayed
.global MonitorPutChar

;===============================================================================
; MonitorPrintString: Printes a null terminated string to console
;===============================================================================
; Stack Inputs
; ----------------------------------------
; string_ptr : 16-bit pointer to null terminated string
.global MonitorPrintString

;===============================================================================
; MonitorPrintHexWord: Prints out a word in hex to the console
;===============================================================================
; Register Inputs
; ----------------------------------------
; .A: Word to be displayed
.global MonitorPrintHexWord

;===============================================================================
; MonitorPrintHexByte: Prints out a byte in hex to the console
;===============================================================================
; Register Inputs
; ----------------------------------------
; .A: Byte to be displayed (low byte if in 16-bit)
.global MonitorPrintHexByte