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

#ifndef CLIO_SIA_CLOCK_MODULE_H
#define CLIO_SIA_CLOCK_MODULE_H

#include <stdint.h>
#include <hardware/gpio.h>

#include "config.h"

#define SCR_CPU_SPEED_MASK (0b00000111)

/**
 *
 * Initializes the CPU clock and puts the CPU in reset hold.
 *
 * @param freq_id 0 = 10Khz, 1 = 100Khz, 2 = 500KhZ, 3 = 1MhZ, 4 = 2Mhz, 5 = 4Mhz, 6 = 6Mhz, 7 = 8Mhz
 */
void cpu_init(uint8_t freq_id);

/**
 * Sets the PHI2 output pin to the specified frequency.
 *
 * @param freq_id 0 = 10Khz, 1 = 100Khz, 2 = 500KhZ, 3 = 1MhZ, 4 = 2Mhz, 5 = 4Mhz, 6 = 6Mhz, 7 = 8Mhz
 */
void cpu_set_freq(uint8_t freq_id);

/**
 * Gets the current PHI2 frequency
 *
 * @return 0 = 10Khz, 1 = 100Khz, 2 = 500KhZ, 3 = 1MhZ, 4 = 2Mhz, 5 = 4Mhz, 6 = 6Mhz, 7 = 8Mhz
 */
uint8_t cpu_get_freq();

#endif //CLIO_SIA_CLOCK_MODULE_H
