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
; ASCII Characters
;===============================================================================
ASC_BELL    = $07
ASC_BS      = $08
ASC_CR      = $0d
ASC_DEL     = $7f
ASC_ESC     = $1b
ASC_TAB     = $09
ASC_LF      = $0A
ASC_SPACE   = $20

.macro ASC_CRLF
    .byte ASC_CR, ASC_LF
.endmacro

;===============================================================================
; VT100/ANSI Escape Codes
;===============================================================================
.macro VT_RESET
    .byte ASC_ESC, "[0m"
.endmacro

.macro VT_BRIGHT
    .byte ASC_ESC, "[1m"
.endmacro

.macro VT_DIM
    .byte ASC_ESC, "[2m"
.endmacro

.macro VT_UNDERSCORE
    .byte ASC_ESC, "[4m"
.endmacro

.macro VT_BLINK
    .byte ASC_ESC, "[5m"
.endmacro

.macro VT_REVERSE
    .byte ASC_ESC, "[6m"
.endmacro

.macro VT_HIDDEN
    .byte ASC_ESC, "[7m"
.endmacro

.macro VT_FORE_BLACK
    .byte ASC_ESC, "[30m"
.endmacro

.macro VT_FORE_RED
    .byte ASC_ESC, "[31m"
.endmacro

.macro VT_FORE_GREEN
    .byte ASC_ESC, "[32m"
.endmacro

.macro VT_FORE_YELLOW
    .byte ASC_ESC, "[33m"
.endmacro

.macro VT_FORE_BLUE
    .byte ASC_ESC, "[34m"
.endmacro

.macro VT_FORE_MAGENTA
    .byte ASC_ESC, "[35m"
.endmacro

.macro VT_FORE_CYAN
    .byte ASC_ESC, "[36m"
.endmacro

.macro VT_FORE_WHITE
    .byte ASC_ESC, "[37m"
.endmacro

.macro VT_BACK_BLACK
    .byte ASC_ESC, "[40m"
.endmacro

.macro VT_BACK_RED
    .byte ASC_ESC, "[41m"
.endmacro

.macro VT_BACK_GREEN
    .byte ASC_ESC, "[42m"
.endmacro

.macro VT_BACK_YELLOW
    .byte ASC_ESC, "[43m"
.endmacro

.macro VT_BACK_BLUE
    .byte ASC_ESC, "[44m"
.endmacro

.macro VT_BACK_MAGENTA
    .byte ASC_ESC, "[45m"
.endmacro

.macro VT_BACK_CYAN
    .byte ASC_ESC, "[46m"
.endmacro

.macro VT_BACK_WHITE
    .byte ASC_ESC, "[47m"
.endmacro

.macro VT_CLEAR
    .byte ASC_ESC, "[2J"
.endmacro

.macro VT_CURSOR_ON
    .byte ASC_ESC, "[?5h"
.endmacro

.macro VT_CURSOR_OFF
    .byte ASC_ESC, "[?5l"
.endmacro
