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

#define LED_INTERVAL_FAST_MS 100
#define LED_INTERVAL_SLOW_MS 500

#define LED_MASK (1<<LED_PIN)

volatile uint8_t led_state = LED_STATE_OFF;
volatile bool led_dirty = false;

static bool            led_on;
static absolute_time_t next_toggle;
static uint64_t        toggle_interval;

void led_init() {
    gpio_init(LED_PIN);
    gpio_set_dir(LED_PIN, true);
    led_reset();
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
        REGISTER_SET_MASKED(REG_ADDR_SCR, (led_state << 3), SCR_LED_MASK);
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