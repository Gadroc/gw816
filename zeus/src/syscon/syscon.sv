//
// Copyright 2025 Craig Courtney
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

module syscon(
	input  wire				clk50_i,			// Reference 50Mhz clock
	
	input  wire				reset_req_i,	// Request Request Signal
	
	output wire				ext_phi2_o,		// Phi2 2 Clock Output (7.5758Mhz / 132ns)
	
	output wire				wb_clk_o,		// Wishbone Bus Clock
	output logic			wb_reset_o		// Wishbone Bus Reset
);

	initial wb_reset_o = 1'b1;

	// ---------------------------------------------------------------------------------------------
	// Local signals
	// ---------------------------------------------------------------------------------------------
	wire       		ext_phi2_locked;			// External Phi2 clock is locked 
	wire 				wb_clk_locked;				// Wishbone Bus clock is locked
	wire				reset_req_triggered;		// Reset request has triggered
	logic  [1:0]   reset_counter = 2'h0;	// Counts wb_clk cycles for rest
	
	// ---------------------------------------------------------------------------------------------
	// PLL Clock Generation
	// ---------------------------------------------------------------------------------------------
	pll_phi2 phi2(
		.inclk0		(clk50_i),
		.c0			(ext_phi2_o),
		.locked		(ext_phi2_locked)
	);
	
	pll_sys sysclk (
		.inclk0		(clk50_i),
		.c0			(wb_clk_o),
		.locked		(wb_clk_locked)
	);
	
	
	// ---------------------------------------------------------------------------------------------
	// Reset Request Debounce
	// ---------------------------------------------------------------------------------------------
	// Debounhce incomming reset requests in case they come from noisy or switches.
	// ---------------------------------------------------------------------------------------------
	logic 			reset_req_last = 1'b0;
	wire  [23:0]	reset_req_counter;
	
	assign reset_req_triggered = reset_req_i && (reset_req_counter == 24'hFFFFFF);
	
	always @(posedge wb_clk_o) begin
	
		if (reset_req_last != reset_req_i)
			reset_req_counter <= 24'h000000;
		else if (reset_req_i && reset_req_counter < 24'hFFFFFF)
			reset_req_counter <= reset_req_counter + 24'h000001;
		
		reset_req_last <= reset_req_i;
	
	end
	

	// ---------------------------------------------------------------------------------------------
	// Reset Control
	// ---------------------------------------------------------------------------------------------
	// Make sure reset signal lasts for at least one clock signal and it is asserted before rising
	// edge of clock.
	// ---------------------------------------------------------------------------------------------
	always @(negedge wb_clk_o) begin
	
		if (reset_req_triggered) begin
			wb_reset_o <= 1'b1;
			reset_counter <= 2'h0;
		end
		
		else if (wb_reset_o) begin
			if (reset_counter == 2'h2)
				wb_reset_o <= 1'b0;
			else
				reset_counter <= reset_counter + 2'h1;
		end
				
	end
	
endmodule