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

#include <hardware/dma.h>
#include <hardware/structs/bus_ctrl.h>

#include "bus_module.h"
#include "bus_module.pio.h"
#include "config.h"
#include "reg_module.h"

/**
 * Initialize the PIO routines for bus read requests.
 *
 * @param divider_int Initial clock divider integer portion
 * @param divider_frac  Initial clock divider fraction portion
 */
void bus_read_init(uint16_t divider_int, uint8_t divider_frac) {
    uint offset = pio_add_program(BUS_PIO, &bus_read_program);
    pio_sm_claim(BUS_PIO, BUS_READ_SM);

    pio_sm_set_consecutive_pindirs(BUS_PIO, BUS_READ_SM, BUS_ADDR_BASE_PIN, 6, false);
    pio_sm_set_consecutive_pindirs(BUS_PIO, BUS_READ_SM, BUS_DATA_PIN_BASE, 8, false);

    pio_sm_config config = bus_read_program_get_default_config(offset);
    sm_config_set_out_pins(&config, BUS_DATA_PIN_BASE, 8);
    sm_config_set_out_shift(&config, true, false, 8);
    sm_config_set_in_pins(&config, BUS_ADDR_BASE_PIN);
    sm_config_set_in_shift(&config, false, true, 6);
    sm_config_set_clkdiv_int_frac(&config, divider_int, divider_frac);
    pio_sm_init(BUS_PIO, BUS_READ_SM, offset, &config);

    // Pre-load the base address of the register data for DMA reads
    pio_sm_put(BUS_PIO, BUS_READ_SM, (uintptr_t)register_data >> 6);
    pio_sm_exec_wait_blocking(BUS_PIO, BUS_READ_SM, pio_encode_pull(false, true));
    pio_sm_exec_wait_blocking(BUS_PIO, BUS_READ_SM, pio_encode_mov(pio_y, pio_osr));
    pio_sm_exec_wait_blocking(BUS_PIO, BUS_READ_SM, pio_encode_mov(pio_isr, pio_y));
    pio_sm_set_enabled(BUS_PIO, BUS_READ_SM, true);

#ifdef USE_DMA
    int addr_chan = dma_claim_unused_channel(true);
    int data_chan = dma_claim_unused_channel(true);

    // DMA move the requested memory data to PIO for output
    dma_channel_config data_dma = dma_channel_get_default_config(data_chan);
    channel_config_set_high_priority(&data_dma, true);
    channel_config_set_dreq(&data_dma, pio_get_dreq(BUS_PIO, BUS_READ_SM, true));
    channel_config_set_transfer_data_size(&data_dma, DMA_SIZE_8);
    channel_config_set_chain_to(&data_dma, addr_chan);
    dma_channel_configure(
            data_chan,
            &data_dma,
            &BUS_PIO->txf[BUS_READ_SM], // dst
            register_data,                  // src
            1,
            false);

    // DMA move address from PIO into the data DMA config
    dma_channel_config addr_dma = dma_channel_get_default_config(addr_chan);
    channel_config_set_high_priority(&addr_dma, true);
    channel_config_set_dreq(&addr_dma, pio_get_dreq(BUS_PIO, BUS_READ_SM, false));
    channel_config_set_read_increment(&addr_dma, false);
    channel_config_set_chain_to(&addr_dma, data_chan);
    dma_channel_configure(
            addr_chan,
            &addr_dma,
            &dma_channel_hw_addr(data_chan)->read_addr, // dst
            &BUS_PIO->rxf[BUS_READ_SM],                     // src
            1,
            true);
#endif
}

/**
 * Initializes the PIO Routines for bus decoding
 *
 * @param divider_int Initial clock divider integer portion
 * @param divider_frac  Initial clock divider fraction portion
 */
void bus_control_init(uint16_t divider_int, uint8_t divider_frac) {
    uint offset = pio_add_program(BUS_PIO, &bus_control_program);
    pio_sm_claim(BUS_PIO, BUS_CONTROL_SM);

    pio_sm_set_consecutive_pindirs(BUS_PIO, BUS_CONTROL_SM, BUS_RW_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(BUS_PIO, BUS_CONTROL_SM, BUS_CS_PIN, 1, false);
    pio_sm_set_consecutive_pindirs(BUS_PIO, BUS_CONTROL_SM, BUS_DATA_PIN_BASE, 8, false);

    pio_sm_config config = bus_control_program_get_default_config(offset);
    sm_config_set_out_pins(&config, BUS_DATA_PIN_BASE, 8);
    sm_config_set_in_pins(&config, BUS_RW_PIN);
    sm_config_set_jmp_pin(&config, BUS_CS_PIN);
    sm_config_set_fifo_join(&config, PIO_FIFO_JOIN_RX );
    sm_config_set_clkdiv_int_frac(&config, divider_int, divider_frac);
    pio_sm_init(BUS_PIO, BUS_CONTROL_SM, offset, &config);

    pio_sm_set_enabled(BUS_PIO, BUS_CONTROL_SM, true);
}

void bus_setup_gpio_pin(uint gpio) {
    gpio_set_pulls(gpio, true, true);
    gpio_set_input_hysteresis_enabled(gpio, false);
    hw_set_bits(&pio0->input_sync_bypass, 1u << gpio);
    hw_set_bits(&pio1->input_sync_bypass, 1u << gpio);
}


void bus_init() {

    // Adjustments for GPIO performance. Important!
    for (int i = BUS_PIN_BASE; i < BUS_PIN_BASE + 15; i++)
    {
        bus_setup_gpio_pin(i);
    }
    bus_setup_gpio_pin(BUS_CS_PIN);

    // Raise DMA above CPU on crossbar
    bus_ctrl_hw->priority |=
            BUSCTRL_BUS_PRIORITY_DMA_R_BITS |
            BUSCTRL_BUS_PRIORITY_DMA_W_BITS;

    // Capture function of all the pins we drive with the SIA bus pio routines
    pio_gpio_init(BUS_PIO, BUS_RW_PIN);
    pio_gpio_init(BUS_PIO, BUS_CS_PIN);
    pio_gpio_init(BUS_PIO, BUS_CLOCK_PIN);
    for (int i=0; i<8; i++) {
        pio_gpio_init(BUS_PIO, BUS_DATA_PIN_BASE + i);
    }

    bus_read_init(1, 0);
    bus_control_init(1, 0);
}