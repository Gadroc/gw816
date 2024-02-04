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
#include "cpu_module.h"
#include "reg_module.h"
#include "bus_module.h"
#include "rom_module.h"
#include "serial_module.h"
#include "led_module.h"

static union BUS_CONTROL_EVENT request;

static uint16_t divider_int;

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
            uint8_t address = NEXT_BUS_READ_ADDRESS;
            pio_sm_put(BUS_PIO, BUS_READ_SM, REGISTER(address));
            if (display_count < DISPLAY_MAX) {
                printf("R A:%04x D:%02x\n", address + 0xFF80, REGISTER(address));
                display_count++;
            }
        }
#endif

        if (BUS_REQUEST_AVAILABLE) {
            request.raw = NEXT_BUS_REQUEST;

#ifdef DISPLAY_REQUEST
//            if (display_count < DISPLAY_MAX) {
                 printf("%1c A:%04x D:%02x RAW:%08lx\n", BUS_EVENT_IS_READ(request) ? 'R' : 'W', BUS_EVENT_ADDR(request) + 0xFF80,
                       BUS_EVENT_IS_READ(request) ? REGISTER(BUS_EVENT_ADDR(request)) : request.data, request.raw);
//                display_count++;
//            }
#endif

            switch (request.address) {
                case BUS_EVENT_WRITE(REG_ADDR_SCR):
                    led_set(request.data & SCR_SIA_LED_MASK);
                    //cpu_set_freq(request.data & SCR_CPU_SPEED_MASK);
                    if (request.data & SCR_ROM_RESET) {
                        rom_read_reset();
                    }
                    break;

                case BUS_EVENT_READ(REG_ADDR_RDR):
                    rom_next_byte();
                    break;

                case BUS_EVENT_WRITE(REG_ADDR_CDR):
                    SERIAL_TX_BYTE(console_uart_tx_buffer, SSR_CONSOLE_TX_READY, request.data)
                    break;

            case BUS_EVENT_READ(REG_ADDR_CDR):
                    SERIAL_NEXT_BYTE(console_uart_rx_buffer, SSR_CONSOLE_RX_READY, REG_ADDR_CDR)
                    break;

                case BUS_EVENT_READ(REG_ADDR_ISR):
                    serial_update_flags();
                    break;
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
            // Manage ROM Load
            rom_tasks();

            // Check UART Buffers
            serial_tasks();

            // Manage leds
            led_tasks();

        } else {
            rom_reset();
            serial_reset();
            led_reset();
        }
    }
}

int main() {

    // We need to "overclock" the RP2040 in order to keep up over 5Mhz or so
    // target system is 8Mhz
    set_sys_clock_khz(256000,true);

    // Setup Power Supply
    gpio_init(23);
    gpio_set_dir(23, true);
    gpio_put(23, true);

    // Setup RESET sense pin
    gpio_init(BUS_RESET_PIN);
    gpio_set_dir(BUS_RESET_PIN, false);

    // Initialize console uart
    // TODO If vbus is connected then we should wait for CDC serial on console prot before releasing cpu
    // TODO If vbus is connected and CDC console drops we should put cpu in reset
    serial_init();

    // Initialize registers
    registers_init();

    // Initialize the address and data bus programs
    bus_init(divider_int);

    // Initialize Reset and Hold CPU in reset
    //cpu_init(START_FREQ);

    // Initialize rom
    rom_init();

    // Initialize led control
    led_init();

    // Start the bus processing loop
    multicore_launch_core1(bus_loop);

    // Start the peripheral loop
    peripheral_loop();
}
