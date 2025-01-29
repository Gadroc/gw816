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

module vram_controller (
	input  logic			wb_clk_i,			// Wishbone Bus Clock
	input  logic  [7:0]	wb_data_i,			// Wishbone Bus Data In
	output logic  [7:0]	wb_data_o,			// Wishbone Bus Data Out
	input  logic			wb_reset_i,			// Wishbone Bus Reset
	
	output logic			wb_ack_o,			// Wishbone Bus Ack
	input  logic [16:0]	wb_addr_i,			// Wishbone Bus Address
	output logic			wb_stall_o,			// Wishbone Stall
	input  logic			wb_strobe_i,		// Wishbone Strobe / Transaction Valid
	input  logic			wb_write_i,			// Wishbone Write Enable
	
	input  logic [14:0]	vram_addr_i,
	output logic [31:0]	vram_data_o
);

	logic [3:0] [7:0] ram_r [32767:0];

	// ---------------------------------------------------------------------------------------------
	// Wishbone Device Signals
	// ---------------------------------------------------------------------------------------------
	assign wb_stall_o = '0;

	always_ff @(posedge wb_clk_i) begin
		wb_ack_o <= wb_strobe_i;
	end
	
	wire wb_trx_accepted = wb_strobe_i;

	// ---------------------------------------------------------------------------------------------
	// Wishbone Bus Port
	// ---------------------------------------------------------------------------------------------
	logic [7:0] wb_data_r;
	
	always_ff @(posedge wb_clk_i) begin

		if (wb_trx_accepted && wb_write_i)
			ram_r[wb_addr_i / 4][wb_addr_i % 4] <= wb_data_i;
		
		wb_data_r <= ram_r[wb_addr_i / 4][wb_addr_i % 4];
		
	end
	assign wb_data_o = wb_data_r;
	
	
	// ---------------------------------------------------------------------------------------------
	// Video Controller Ram Port
	// ---------------------------------------------------------------------------------------------
	logic [31:0] vram_data_r;
	
	always_ff @(posedge wb_clk_i) begin
			
		vram_data_r <= ram_r[vram_addr_i];
	
	end
	assign vram_data_o = vram_data_r;


endmodule