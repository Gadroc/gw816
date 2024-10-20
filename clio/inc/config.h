/*
 * Copyright 2023 Craig Courtney
 *
 * Redistribution and use in source and binary forms, with or without modification, are permitted provided that the
 * following conditions are met:
 *
 * 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following
 *    disclaimer.
 *
 * 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the
 *    following disclaimer in the documentation and/or other materials provided with the distribution.
 *
 * 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote
 *    products derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS” AND ANY EXPRESS OR IMPLIED WARRANTIES,
 * INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE
 * USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */
#ifndef CLIO_PINS_H
#define CLIO_PINS_H

#include <hardware/pio.h>

//#define DISPLAY_REQUEST
#define DISPLAY_MAX 60
#define USE_DMA

#define BUS_PIN_BASE        0
#define BUS_RW_PIN          (BUS_PIN_BASE)
#define BUS_ADDR_BASE_PIN   (BUS_PIN_BASE + 1)
#define BUS_DATA_PIN_BASE   (BUS_PIN_BASE + 7)
#define BUS_RESET_PIN       27
#define BUS_CS_PIN          28
#define BUS_CLOCK_PIN       29

#define LED_PIN             25
#define SW_PIN              24

#define IRQ_PIN_PS2         22
#define IRQ_PIN_TIMER       23
#define IRQ_PIN_UART        15

#define RESET_REQ           26

#define UART_TX             16
#define UART_RX             17

#define PS2_KBD_CLK         18
#define PS2_KBD_DAT         19
#define PS2_MSE_CLK         20
#define PS2_MSE_DAT         21

#define BUS_PIO             pio0
#define BUS_CONTROL_SM      0
#define BUS_READ_SM         1

#endif //CLIO_PINS_H
