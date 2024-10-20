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

module clock_generator
# (
	PHI2_PULSE_CYCLE_COUNT	= 12'd11			// Number of system cycles in each phi2 pulse
) (
	input  wire				clk_50,				// FPGA Core Module 50Mhz Clock
	
	output logic			clk,					// FPGA System Clock 166.67 Mhz
	output wire				clk_phi2,			// Bus Clock for CPU and Peripherals
	output logic [11:0]	phi2_cycle,			// System Clock Cycle Count for current phi2 phase
	output wire				clk_shift,			// 20Mhz Shift Clock for SPI
	output wire				clk_shift_slow,	// 2Mhz Shift Clock for SPI
	output wire				clk_vga,				// Pixel Clock for VGA Controller
	output wire				clk_locked			// Indicator that the PLL is locked
);

	initial clk_phi2		= 1'b0;
	initial phi2_cycle 	= 12'd0;

	sys_pll sys (
		.inclk0	(clk_50),
		.c0		(clk),
		.c1		(clk_shift),
		.c2		(clk_shift_slow),
		.locked	(clk_locked)
	);
	
	vga_pll vga (
		.inclk0	(clk_50),
		.c0		(clk_vga)
	);
	
	always @(posedge clk) begin

		if (phi2_cycle == PHI2_PULSE_CYCLE_COUNT) begin
			phi2_cycle <= 12'h000;
			clk_phi2 <= !clk_phi2;
		end else begin
			phi2_cycle <= phi2_cycle + 12'h01;
		end

	end

endmodule