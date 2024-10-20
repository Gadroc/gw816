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

#ifndef CLIO_RING_BUFFER_H
#define CLIO_RING_BUFFER_H

#include <stdint.h>
#include <pico/sync.h>

#define RING_BUFFER_SIZE 32

struct ring_buffer {
    volatile uint8_t data[RING_BUFFER_SIZE];
    volatile uint8_t start;
    volatile uint8_t end;
};

static inline void ring_buffer_init(struct ring_buffer* buffer) {
    buffer->start = 0;
    buffer->end = 0;
}

/**
 * Checks to see if the buffer is empty
 *
 * @param buffer Buffer to check for data.
 * @return true if buffer contains data
 */
static inline bool ring_buffer_is_empty(volatile struct ring_buffer* buffer) {
    return buffer->start == buffer->end;
}

/**
 * Checks to see if the buffer is full.
 *
 * @param buffer Buffer to check for space.
 * @return ture if buffer is full
 */
static inline bool ring_buffer_is_full(volatile struct ring_buffer* buffer) {
    return (buffer->end + 1) % RING_BUFFER_SIZE == buffer->start;
}

/**
 * Gets the next byte form the buffer and increments start. WARNING must check ot see if buffer has data
 * before calling!
 *
 * @param buffer Buffer to get data from.
 * @return Value from buffer
 */
static inline uint8_t ring_buffer_get_byte(volatile struct ring_buffer *buffer) {
    uint8_t value = buffer->data[buffer->start];
    buffer->start = (buffer->start + 1) % RING_BUFFER_SIZE;
    return value;
}

/**
 * Puts a byte into the ring buffer.  WARNING must check to see if buffer is full!
 *
 * @param buffer
 * @return ture if buffer is full
 */
static inline bool ring_buffer_put_byte(volatile struct ring_buffer* buffer, uint8_t value) {
    buffer->data[buffer->end] = value;
    buffer->end = (buffer->end + 1) % RING_BUFFER_SIZE;
    return ring_buffer_is_full(buffer);
}

#endif //CLIO_RING_BUFFER_H
