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

#ifndef CLIO_CONSOLE_MODULE_H
#define CLIO_CONSOLE_MODULE_H

#include <pico/stdlib.h>
#include "ring_buffer.h"
#include "reg_module.h"

#define SSR_CONSOLE_TX_READY (0b00000001)
#define SSR_CONSOLE_RX_READY (0b00000010)
#define SSR_DATA_TX_READY    (0b00000100)
#define SSR_DATA_RX_READY    (0b00001000)


extern struct ring_buffer console_uart_rx_buffer;
extern struct ring_buffer console_uart_tx_buffer;

extern struct ring_buffer data_uart_rx_buffer;
extern struct ring_buffer data_uart_tx_buffer;

void serial_init();

void serial_tasks();

static inline void serial_reset() {
    ring_buffer_init(&console_uart_rx_buffer);
    ring_buffer_init(&console_uart_tx_buffer);
    ring_buffer_init(&data_uart_rx_buffer);
    ring_buffer_init(&data_uart_tx_buffer);

    REGISTER_SET_FLAG(REG_ADDR_ISR, SSR_CONSOLE_TX_READY);
    REGISTER_CLEAR_FLAG(REG_ADDR_ISR, SSR_CONSOLE_RX_READY);
    REGISTER_SET_FLAG(REG_ADDR_ISR, SSR_DATA_TX_READY);
    REGISTER_CLEAR_FLAG(REG_ADDR_ISR, SSR_DATA_RX_READY);
}

#define SERIAL_TX_BYTE(buffer, tx_bit, data)  { \
    if (!ring_buffer_is_full(&buffer)) {        \
        ring_buffer_put_byte(&buffer, data);    \
        if (ring_buffer_is_full(&buffer)) {     \
            REGISTER_CLEAR_FLAG(REG_ADDR_ISR, tx_bit); \
        }                                       \
    }                                           \
}

#define SERIAL_NEXT_BYTE(buffer, rx_bit, data_reg_addr) { \
    if (ring_buffer_is_empty(&buffer)) {                            \
        REGISTER(data_reg_addr) = 0x00;                             \
        REGISTER_CLEAR_FLAG(REG_ADDR_ISR, rx_bit);                  \
    } else {                                                        \
        REGISTER(data_reg_addr) = ring_buffer_get_byte(&buffer);    \
        REGISTER_SET_FLAG(REG_ADDR_ISR, rx_bit);                    \
    }                                                               \
}

static inline void serial_update_flags() {
    if (!ring_buffer_is_full(&console_uart_tx_buffer)) {
        REGISTER_SET_FLAG(REG_ADDR_ISR, SSR_CONSOLE_TX_READY);
    }
    if (!ring_buffer_is_empty(&console_uart_rx_buffer)) {
        REGISTER_SET_FLAG(REG_ADDR_ISR, SSR_CONSOLE_RX_READY);
    }
}

#endif //CLIO_CONSOLE_MODULE_H
