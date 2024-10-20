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

#ifndef CLIO_ROM_MODULE_H
#define CLIO_ROM_MODULE_H

#include "reg_module.h"
#include <memory.h>

#define SCR_ROM_COMPLETE    (0b10000000)

extern const uint8_t romstrap_bin[];
extern unsigned int romstrap_bin_len;

extern const uint8_t kernel_bin[];
extern unsigned int kernel_bin_len;
extern uint32_t rom_index;

void rom_init();

static inline void rom_next_byte() {
    REGISTER(REG_ADDR_RDR) = kernel_bin[rom_index++];
    if (rom_index == kernel_bin_len) {
        REGISTER_SET_FLAG(REG_ADDR_SCR, SCR_ROM_COMPLETE);
    }
}

static inline void rom_reset() {
    memcpy(&REGISTER(REG_ADDR_BOOTLOADER), &romstrap_bin, romstrap_bin_len);
    REGISTER_CLEAR_FLAG(REG_ADDR_SCR, SCR_ROM_COMPLETE);
    rom_index = 0;
    rom_next_byte();
}

#endif //CLIO_ROM_MODULE_H
