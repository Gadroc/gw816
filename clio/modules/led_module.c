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

#include <hardware/gpio.h>
#include <pico/printf.h>
#include "config.h"
#include "led_module.h"
#include "reg_module.h"

#define LED_STATE_OFF  0x0
#define LED_STATE_ON   0x1
#define LED_STATE_SLOW 0x2
#define LED_STATE_FAST 0x3

#define LED_INTERVAL_FAST_MS 100
#define LED_INTERVAL_SLOW_MS 500

#define LED_MASK ((1<<SIA_LED_PIN) | (1<<SYS_LED_PIN))

volatile uint8_t led_state = LED_STATE_OFF;
volatile bool led_dirty = false;

static bool            led_on;
static absolute_time_t next_toggle;
static uint64_t        toggle_interval;

void led_init() {
    gpio_init(SIA_LED_PIN);
    gpio_init(SYS_LED_PIN);
    gpio_set_dir(SIA_LED_PIN, true);
    gpio_set_dir(SYS_LED_PIN, true);
    gpio_put(SIA_LED_PIN, false);
    gpio_put(SYS_LED_PIN, false);
}

void led_tasks() {
    if (led_dirty) {
        led_dirty = false;
        switch (led_state) {
            case LED_STATE_OFF:
                gpio_clr_mask(LED_MASK);
                break;

            case LED_STATE_ON:
                gpio_set_mask(LED_MASK);
                break;

            case LED_STATE_SLOW:
                gpio_set_mask(LED_MASK);
                toggle_interval = LED_INTERVAL_SLOW_MS;
                next_toggle = make_timeout_time_ms(toggle_interval);
                led_on = true;
                break;

            case LED_STATE_FAST:
                gpio_set_mask(LED_MASK);
                toggle_interval = LED_INTERVAL_FAST_MS;
                next_toggle = make_timeout_time_ms(toggle_interval);
                led_on = true;
                break;

            default:
                break;
        }
        REGISTER_SET_MASKED(REG_ADDR_SCR, (led_state << 3), SCR_SIA_LED);
    }

    if (led_state > LED_STATE_ON) {
        if (absolute_time_diff_us(get_absolute_time(), next_toggle) <= 0) {
            led_on = !led_on;
            if (led_on) {
                gpio_set_mask(LED_MASK);
            } else {
                gpio_clr_mask(LED_MASK);
            }
            next_toggle = make_timeout_time_ms(toggle_interval);
        }
    }
}