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
#include "bus_module.pio.h"
#include "reg_module.h"
#include "cpu_module.h"

static uint clock_current_freq = 8;

//
// Dividers for system clock (240 MHz) to drive the bus_clock PIO program.
//
// 0 = 10Khz, 1 = 100 kHz, 2 = 500 kHZ, 3 = 1 MHz, 4 = 2 MHz, 5 = 4 MHz, 6 = 6 MHz, 7 = 8 MHz
static const uint16_t clock_div_int[] = {12000, 1200, 240, 120, 60, 30, 20, 15 };

void cpu_init(uint8_t freq_id) {
    gpio_init(BUS_RESET_PIN);
    gpio_set_dir(BUS_RESET_PIN, true);

    cpu_reset_hold();
    clock_current_freq = (freq_id <= 7) ? freq_id : 7;
    REGISTER_SET_MASKED(REG_ADDR_SCR, clock_current_freq, SCR_CPU_SPEED_MASK);

    uint offset = pio_add_program(BUS_PIO, &bus_clock_program);
    pio_sm_claim(BUS_PIO, BUS_CLOCK_SM);

    pio_sm_set_consecutive_pindirs(BUS_PIO, BUS_CLOCK_SM, BUS_CLOCK_PIN, 1, true);

    pio_sm_config config = bus_clock_program_get_default_config(offset);
    sm_config_set_sideset_pins(&config, BUS_CLOCK_PIN);
    sm_config_set_clkdiv_int_frac(&config, clock_div_int[clock_current_freq], 0);
    pio_sm_init(BUS_PIO, BUS_CLOCK_SM, offset, &config);

    pio_sm_set_enabled(BUS_PIO, BUS_CLOCK_SM, true);
}

void cpu_set_freq(uint8_t freq_id) {
    if (freq_id <= 7 && freq_id != clock_current_freq) {
        clock_current_freq = freq_id;
        pio_sm_set_clkdiv_int_frac(BUS_PIO, BUS_CLOCK_SM, clock_div_int[freq_id], 0);
        REGISTER_SET_MASKED(REG_ADDR_SCR, freq_id, SCR_CPU_SPEED_MASK);
    }
}

uint8_t cpu_get_freq() {
    return clock_current_freq;
}