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

#include "rom_module.h"
#include <stdio.h>

extern const uint8_t bios_bin[];
extern unsigned int bios_bin_len;
extern const uint8_t bios_bootstrap_bin[];
extern unsigned int bios_bootstrap_bin_len;

volatile enum rom_states rom_state = rom_state_unknown;

static const uint32_t bios_addr = 0xd000;
static size_t bios_index;

void rom_init() {
    for (uint32_t i = 0; i < bios_bootstrap_bin_len; i++) {
        REGISTER(REG_ADDR_BOOTLOADER+i) = bios_bootstrap_bin[i];
    }
    bios_index = 0x00;
}

void rom_tasks() {
    switch (rom_state) {
        case rom_state_reset:;
            REGISTER(REG_ADDR_RA_LO) = bios_addr & 0xff;
            REGISTER(REG_ADDR_RA_HI) = (bios_addr >> 8) & 0xff;
            REGISTER(REG_ADDR_RA_BA) = (bios_addr >> 16) & 0xff;
            REGISTER(REG_ADDR_RDR)   = bios_bin[bios_index];
            bios_index = 0;
            REGISTER_CLEAR_FLAG(REG_ADDR_SCR, SCR_ROM_COMPLETE);
            REGISTER_SET_FLAG(REG_ADDR_SCR, SCR_ROM_DATA_READY);
            rom_state = rom_state_ready;
            break;

        case rom_state_next:
            bios_index++;
            if (bios_index == bios_bin_len) {
                REGISTER_SET_FLAG(REG_ADDR_SCR, SCR_ROM_COMPLETE);
                REGISTER_SET_FLAG(REG_ADDR_SCR, SCR_ROM_DATA_READY);
                rom_state = rom_state_unknown;
            } else {
                REGISTER(REG_ADDR_RA_LO) = (bios_addr + bios_index) & 0xFF;
                REGISTER(REG_ADDR_RA_HI) = ((bios_addr + bios_index)  >> 8) & 0xff;
                REGISTER(REG_ADDR_RA_BA) = ((bios_addr + bios_index)  >> 16) & 0xff;
                REGISTER(REG_ADDR_RDR)   = bios_bin[bios_index];
                REGISTER_SET_FLAG(REG_ADDR_SCR, SCR_ROM_DATA_READY);
                rom_state = rom_state_ready;
            }
            break;

        default:
            break;
    }
}