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

module ps2_controller (
	input  logic			wb_clk_i,				// Wishbone Bus Clock
	input  logic  [7:0]	wb_data_i,				// Wishbone Bus Data In
	output logic  [7:0]	wb_data_o,				// Wishbone Bus Data Out
	input  logic			wb_reset_i,				// Wishbone Bus Reset
	
	output logic 			wb_ack_o,				// Wishbone Bus Ack
	input  logic   [4:0]	wb_addr_i,				// Wishbone Bus Address
	output logic			wb_stall_o,				// Wishbone Stall
	input  logic			wb_strobe_i,			// Wishbone Strobe / Transaction Valid
	input  logic			wb_write_i,				// Wishbone Write Enable

	output wire				kbd_clk,			// Keyboard PS2 Clock Line
	inout  wire				kbd_dat,			// Keyboard PS2 Data Line
	output wire				mse_clk,			// Mouse PS2 Clock Line
	inout  wire				mse_dat			// Mouse PS2 Data Line
);

	assign kbd_clk = 1'b0;
	assign kbd_dat = 1'bz;
	assign mse_clk = 1'b0;
	assign mse_dat = 1'bz;

	// ---------------------------------------------------------------------------------------------
	// Register Access
	// ---------------------------------------------------------------------------------------------
	assign wb_stall_o = '0;

	wire wb_trx_accepted = wb_strobe_i;
	
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i) begin
		end
		
		else begin
		
			if (wb_trx_accepted) begin
				if (wb_write_i)				
					case(wb_addr_i)
						default: begin end
					endcase
				else
					case(wb_addr_i)
						default: wb_data_o <= '0;
					endcase
			end
			
		end
	
	end
	
	always_ff @(posedge wb_clk_i) begin
		wb_ack_o <= wb_strobe_i;
	end	
	
endmodule