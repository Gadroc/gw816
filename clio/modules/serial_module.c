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

#include <stdio.h>

#include "serial_module.h"
#include "reg_module.h"

struct ring_buffer console_uart_rx_buffer;
struct ring_buffer console_uart_tx_buffer;

void serial_init() {
    stdio_uart_init_full(uart0, 115200, UART_TX, UART_RX);
    serial_reset();
}

void serial_tasks()
{
    if (!ring_buffer_is_empty(&console_uart_tx_buffer))
    {
        putchar(ring_buffer_get_byte(&console_uart_tx_buffer));
    }
    if (!ring_buffer_is_full(&console_uart_tx_buffer))
    {
        REGISTER_SET_FLAG(REG_ADDR_ISR, ISR_CONSOLE_TX_READY);
    }

    int usb_c = getchar_timeout_us(0);
    if (usb_c != PICO_ERROR_TIMEOUT && !ring_buffer_is_full(&console_uart_rx_buffer))
    {
        ring_buffer_put_byte(&console_uart_rx_buffer, usb_c);
    }

    if (!ring_buffer_is_empty(&console_uart_rx_buffer) && REGISTER_NOT_SET(REG_ADDR_ISR, ISR_CONSOLE_RX_READY))
    {
        REGISTER(REG_ADDR_CDR) = ring_buffer_get_byte(&console_uart_rx_buffer);
        REGISTER_SET_FLAG(REG_ADDR_ISR, ISR_CONSOLE_RX_READY);
    }
}
