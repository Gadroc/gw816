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

#include <pico/stdlib.h>
#include <pico/multicore.h>

#include <stdio.h>
#include "reg_module.h"
#include "bus_module.h"
#include "rom_module.h"
#include "serial_module.h"
#include "led_module.h"

static union BUS_CONTROL_EVENT request;

static uint16_t divider_int;
static bool _reset = true;

#ifdef DISPLAY_REQUEST
uint16_t display_count = 0;
#endif

/**
 * Processing loop to manage all register read/write notifications.  Each bus request only has approximately
 * 80 clock cycles before a possible next request, so code should defer as much as possible to peripheral loop.
 *
 * Note: Read requests are actually fulfilled by DMA requests to the register memory. Read requests processed
 *       in this loop are after read actions (auto increments, etc...).
 */
_Noreturn static __attribute__((optimize("O1")))  void bus_loop() {
    while (true) {

#ifndef USE_DMA
        if (BUS_READ_AVAILABLE) {
            uint32_t raw = BUS_PIO->rxf[BUS_READ_SM];
            uint8_t address = raw & 0x3F;
            pio_sm_put(BUS_PIO, BUS_READ_SM, REGISTER(address));
            if (display_count < DISPLAY_MAX) {
                printf("R A:%04x D:%02x %08lx %08x\n", address + 0xFFC0, REGISTER(address), raw, (uintptr_t)register_data);
                display_count++;
            }
        }
#endif

        if (BUS_REQUEST_AVAILABLE) {
            request.raw = NEXT_BUS_REQUEST;

#ifdef DISPLAY_REQUEST
            if (display_count < DISPLAY_MAX) {
                 printf("%1s A:%04x D:%02x RAW:%08lx\n", BUS_EVENT_IS_READ(request) ? "R" : "W", BUS_EVENT_ADDR(request) + 0xFFC0,
                       BUS_EVENT_IS_READ(request) ? REGISTER(BUS_EVENT_ADDR(request)) : request.data, request.raw);
                display_count++;
            }
#endif

            switch (request.address) {
                case BUS_EVENT_WRITE(REG_ADDR_SCR):
                    led_set(request.data & SCR_LED_MASK);
                    break;

                case BUS_EVENT_READ(REG_ADDR_RDR):
                    rom_next_byte();
                    break;

                case BUS_EVENT_WRITE(REG_ADDR_CDR):
                    SERIAL_TX_BYTE(console_uart_tx_buffer, ISR_CONSOLE_TX_READY, request.data)
                    break;

                case BUS_EVENT_READ(REG_ADDR_CDR):
                    SERIAL_NEXT_BYTE(console_uart_rx_buffer, ISR_CONSOLE_RX_READY)
                    break;
            }

            if (!BUS_EVENT_IS_READ(request) &&  BUS_EVENT_ADDR(request) >= REG_ADDR_VECTORS) {
                REGISTER(BUS_EVENT_ADDR(request)) = request.data;
            }
        }
    }
}

/**
 * Background loop to process peripheral interactions, and manage and background tasks to execute bus loop
 * requests.
 */
_Noreturn void peripheral_loop() {
    while (true) {
        if (gpio_get(BUS_RESET_PIN)) {
            _reset = false;

            // Check UART Buffers
            serial_tasks();

            // Manage leds
            led_tasks();

        } else {
            if (!_reset) {
#ifdef DISPLAY_REQUEST
                display_count = 0;
                printf("\n** RESET **\n");
#endif

                rom_reset();
                serial_reset();
                led_reset();

                _reset = true;
            }
        }
    }
}

int main() {

    sleep_ms(150);

    // We need to "overclock" the RP2040 in order to keep up over 5Mhz or so
    // target system is 8Mhz
    set_sys_clock_khz(256000,true);

    // Pull down reset request during startup
    gpio_init(RESET_REQ);
    gpio_set_dir(RESET_REQ, true);
    gpio_set_mask(1<<RESET_REQ);

    // Setup RESET sense pin
    gpio_init(BUS_RESET_PIN);
    gpio_set_dir(BUS_RESET_PIN, false);

    // Initialize serial ports
    serial_init();

    // Initialize registers
    registers_init();

    // Initialize the address and data bus programs
    bus_init();

    // Initialize rom
    rom_init();

    // Initialize led control
    led_init();

    // Release reset so CPU can start
    gpio_clr_mask(1<<RESET_REQ);

    // Start the bus processing loop
    multicore_launch_core1(bus_loop);

    // Start the peripheral loop
    peripheral_loop();
}
