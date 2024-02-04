//
// Copyright 2023 Craig Courtney
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// 1. Redistributions of source code must retain the above copyright notice,
//    this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright notice,
//    this list of conditions and the following disclaimer in the documentation
//    and/or other materials provided with the distribution.
//
// 3. Neither the name of the copyright holder nor the names of its contributors
//    may be used to endorse or promote products derived from this software
//    without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS “AS IS”
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

`timescale 1 ps / 1 ps

module irq_controller (
	input  wire			clk,			// System Clock
	input  wire			cs_n,			// Chip Select for IRQ Controller

	input  wire  [4:0]	bus_cycle,		// Bus Clock
	input  wire  		address,		// Address
	input  wire 		read_write,		// Read (High) / Write (Low) Select
	input  wire			reset_n,		// Bus Resest
	input  wire  [7:0]	data_in,		// Peripheral Data Bus In
	output reg   [7:0]	data_out,		// Peripheral Data Bus Out


	input  wire  [7:0]	irq_sources_n,	// Input IRQ Sources
	output reg			irq_out_n		// IRQ Output
);

	// Register to enable interrupt propigating to CPU
	reg [7:0] irq_enable_register;

	always @(posedge clk) begin

		if (reset_n) begin

			irq_enable_register <= 8'b00000000;

		end else begin

			if (!cs_n && read_write) begin
				data_out <= address ? irq_enable_register : ~irq_sources_n;
			end else begin 
				data_out <= 8'h00;
			end

			if (!cs_n && !read_write && address && bus_cycle == 8'h10) begin
				irq_enable_register <= data_in;
			end

		end

		irq_out_n <= !((~irq_sources_n & irq_enable_register) > 8'h0);

	end

endmodule
