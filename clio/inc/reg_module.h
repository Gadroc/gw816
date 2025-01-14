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
#include "bus_module.h"

#define REG_BASE_ADDR   0x3FC0

#define REG_ADDR_SCR    0x3FC0
#define REG_ADDR_RDR    0x3FC1
#define REG_ADDR_ISR    0x3FC2
#define REG_ADDR_ICR    0x3FC3
#define REG_ADDR_CDR    0x3FC4
#define REG_ADDR_KDR    0x3FC5
#define REG_ADDR_MDR    0x3FC6
#define REG_ADDR_TCR    0x3FC7
#define REG_ADDR_TCL    0x3FC8
#define REG_ADDR_TCH    0x3FC9
#define REG_ADDR_MCR    0x3FCA

#define REG_ADDR_VECTORS    0x3FE0

#define REGISTER(address)                   bus_data[address]
#define REGISTER_SET_FLAG(address, flag)    bus_data[address] |= flag
#define REGISTER_CLEAR_FLAG(address, flag)  bus_data[address] &= ~flag
#define REGISTER_SET_MASKED(address, value, mask) bus_data[address] = (bus_data[address] & ~mask) | (value & mask)

#define REGISTER_IS_SET(address, flag)      ((bus_data[address] & flag) == flag)
#define REGISTER_NOT_SET(address, flag)     ((bus_data[address] & flag) == 0)

#endif //CLIO_REG_MODULE_H
