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

#ifndef CLIO_REG_MODULE_H
#define CLIO_REG_MODULE_H

#include <pico/stdlib.h>

#define REG_ADDR_SCR    0x00
#define REG_ADDR_RCR    0x01
#define REG_ADDR_RBA    0x02
#define REG_ADDR_RA_LO  0x03
#define REG_ADDR_RA_HI  0x04
#define REG_ADDR_RDR    0x05
#define REG_ADDR_SSR    0x06
#define REG_ADDR_SIC    0x07
#define REG_ADDR_CDR    0x08
#define REG_ADDR_SDR    0x09
#define REG_ADDR_BOOTLOADER 0x10
#define REG_ADDR_VECTORS    0x60

extern volatile uint8_t register_data[0x80];

void registers_init();

#define REGISTER(address)                   register_data[address]
#define REGISTER_SET_FLAG(address, flag)    register_data[address] |= flag
#define REGISTER_CLEAR_FLAG(address, flag)  register_data[address] &= ~flag
#define REGISTER_SET_MASKED(address, value, mask) register_data[address] = (register_data[address] & ~mask) | (value & mask)

#define REGISTER_IS_SET(address, flag)      ((register_data[address] & flag) == flag)
#define REGISTER_NOT_SET(address, flag)     ((register_data[address] & flag) == 0)

#endif //CLIO_REG_MODULE_H
