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

extern const uint8_t rom_kernel_bin[];
extern unsigned int rom_kernel_bin_len;

extern const uint8_t rom_bootstrap_bin[];
extern unsigned int rom_bootstrap_bin_len;

extern const uint8_t rom_dos_bin[];
extern unsigned int rom_dos_bin_len;

volatile enum rom_register_states rom_state = rom_state_unknown;

static const uint32_t kernel_addr = 0xe000;
static const uint32_t dos_addr = 0x10000;

static bool kernel_complete;

static const uint8_t *rom_data;
static uint32_t rom_start;
static uint32_t rom_size;
static uint32_t rom_index;

void rom_init() {
    for (uint32_t i = 0; i < rom_bootstrap_bin_len; i++) {
        REGISTER(REG_ADDR_BOOTLOADER + i) = rom_bootstrap_bin[i];
    }
    rom_reset();
}

void rom_set_byte() {
    REGISTER(REG_ADDR_RA_LO) = (rom_start + rom_index) & 0xff;
    REGISTER(REG_ADDR_RA_HI) = ((rom_start + rom_index) >> 8) & 0xff;
    REGISTER(REG_ADDR_RA_BA) = ((rom_start + rom_index) >> 16) & 0xff;
    REGISTER(REG_ADDR_RDR)   = rom_data[rom_index];
    REGISTER_SET_FLAG(REG_ADDR_SCR, SCR_ROM_DATA_READY);
    rom_state = rom_state_ready;
}

void rom_tasks() {
    switch (rom_state) {
        case rom_state_reset:;
            REGISTER_CLEAR_FLAG(REG_ADDR_SCR, SCR_ROM_COMPLETE);

            kernel_complete = false;
            rom_data = rom_kernel_bin;
            rom_start = kernel_addr;
            rom_size = rom_kernel_bin_len;
            rom_index = 0;
            rom_set_byte();

            break;

        case rom_state_next:
            rom_index++;
            if (rom_index == rom_size) {
                if (kernel_complete || rom_dos_bin_len == 0) {
                    REGISTER_SET_FLAG(REG_ADDR_SCR, SCR_ROM_COMPLETE);
                    REGISTER_SET_FLAG(REG_ADDR_SCR, SCR_ROM_DATA_READY);
                    rom_state = rom_state_unknown;
                } else {
                    kernel_complete = true;
                    rom_data = rom_dos_bin;
                    rom_start = dos_addr;
                    rom_size = rom_dos_bin_len;
                    rom_index = 0;
                    rom_set_byte();
                }
            } else {
                rom_set_byte();
            }
            break;

        default:
            break;
    }
}