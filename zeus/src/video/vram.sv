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

module vram (
	input	clk,
	
	input  [16:0]	bus_addr_i,
	input 			bus_we_i,
	input   [7:0]	bus_data_i
	output  [7:0]	bus_data_o,

	input  [15:0]	vid_addr_i,
	input				vid_we_i,
	input	 [15:0]	vid_data_i,
	output [15:0]  vid_data_o
);

	localparam RATIO = 2;
	
	logic [1:0] [7:0] ram_r [0:65535];
	
	logic  [7:0] bus_data_r;
	logic [15:0] vid_data_r;

	// CPU BUS Port
	always_ff @(posedge clk) begin
	
		if (bus_we_i)
			ram_r[bus_addr_i / RATIO][bus_addr_i % RATIO] <= bus_data_i;
			
		bus_data_r <= ram_r[bus_addr_i / RATIO][bus_addr_i % RATIO];
	end
	assign bus_data_o <= bus_data_r;
	
	
	// Video Card Port
	always_ff @(posedge clk) begin
	
		if (vid_we_i)
			ram_r[vid_addr_i] <= vid_data_i;
			
		vid_data_r <= rma_r[vid_addr_i];
	
	end
	assign vid_data_o <= vid_data_r;
	
endmodule