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

#ifndef CLIO_BUS_MODULE_H
#define CLIO_BUS_MODULE_H

#include <pico/stdlib.h>
#include "config.h"

extern volatile uint8_t bus_data[BUS_DATA_SIZE];

/**
 * Initialize the address and data bus interface.
 */
void bus_init();

// Utility defines to check and retrieve data from bus_read PIO program.  Using these bypass overhead
// of SDK since we are very timing critical when using them.
#define BUS_READ_AVAILABLE          !(BUS_PIO->fstat & (1u << (PIO_FSTAT_RXEMPTY_LSB + BUS_READ_SM)))
#define NEXT_BUS_READ_ADDRESS       (BUS_PIO->rxf[BUS_READ_SM] & 0x3FFF)

#define REG_EVENT_AVAILABLE       !(BUS_PIO->fstat & (1u << (PIO_FSTAT_RXEMPTY_LSB + REG_EVENTS_SM)))
#define NEXT_REG_EVENT             BUS_PIO->rxf[REG_EVENTS_SM]

// Utility defines to deal with BUS_CONTROL_EVENT addresses.  These addresses include a RW bit as bit zero
// of the address.
#define REG_EVENT_IS_READ(request) (request & (1<<31))
#define REG_EVENT_ADDR(request) ((request >> 9) & 0x3FFF)
#define REG_EVENT_DATA(request) ((request >> (9+ADDRESS_PIN_COUNT)) & 0xFF)

#endif //CLIO_BUS_MODULE_H
