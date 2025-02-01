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
#include "config.h"
#include "reg_module.h"
#include "bus_module.h"
#include "rom_module.h"

static bool _reset = true;

#ifdef DISPLAY_ACTIONS
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
            uint16_t address = raw & 0xFFFF;
            pio_sm_put(BUS_PIO, BUS_READ_SM, bus_data[address]);
            if (display_count < DISPLAY_MAX) {
                printf("BUS R A:%04x D:%02x RAW:%08lx\n", address, bus_data[address], raw);
                display_count++;
            }
        }
#endif

    }
}

/**
 * Background loop to process peripheral interactions, and manage and background tasks to execute bus loop
 * requests.
 */
_Noreturn void peripheral_loop() {
    while (true) {
    }
}

int main() {

    sleep_ms(150);

    // We need to "overclock" the RP2040 in order to keep up over 5Mhz or so
    // target system is 8Mhz
    set_sys_clock_khz(256000,true);

    stdio_usb_init();

    // Setup RESET_REQ sense pin
    gpio_init(BUS_RESET_REQ_PIN);
    gpio_set_dir(BUS_RESET_REQ_PIN, true);
    gpio_clr_mask(1 << BUS_RESET_REQ_PIN);

    // Initialize the address and data bus programs
    bus_init();

    // Initialize rom
    rom_init();

    // Start the bus processing loop
    multicore_launch_core1(bus_loop);

    gpio_set_mask(1 << BUS_RESET_REQ_PIN);

    // Start the peripheral loop
    peripheral_loop();
}
