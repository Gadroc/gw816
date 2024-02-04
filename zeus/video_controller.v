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

module video_controller (
	// Bus Interface
	input  wire  [18:0]	address,				// Address Bus
	input  wire  [7:0]	data_in,				// Data Bus
	output wire  [7:0]	data_out,			// Data Bus
	input	 wire				phi2,				   // Bus Clock
	input  wire 			read_write,			// Read (High) / Write (Low) Select
	input  wire				reset_n,				// Bus Resest
	input	 wire				reg_cs_n,			// Chip Select for Video Registers
	input  wire				vram_cs_n,			// Chip Select for VRAM access
	
	output wire				irq_n,				// IRQ Signal
	
	input  wire				pix_clk,				// Incodming pixel clock	
	
	output wire [4:0]		vga_red,				// VGA Red Signal Level
	output wire [4:0]		vga_green,			// VGA Green Signal Level
	output wire [4:0]		vga_blue,			// VGA Blue Signal Level
	output wire				vga_h_sync,			// VGA H-Sync Signal
	output wire          vga_v_sync,			// VGA V-Sync Signal
	
	output wire				vga_mem_oe_n,		// VGA Memory Output Enable
	output wire				vga_mem_we_n,		// VGA Memory Write Enable
	output wire [18:0]	vga_mem_addr,		// VGA Memory Address Bus
	inout  wire [7:0]		vga_mem_data		// VGA Memory Data Bus
);

	assign data_out = 8'h00;
	assign vga_red   = 5'b00000;
	assign vga_green = 5'b00000;
	assign vga_blue  = 5'b00000;
	assign vga_h_sync = pix_clk;
	assign vga_v_sync = 1'b0;
	assign vga_mem_oe_n = 1'b1;
	assign vga_mem_we_n = 1'b1;
	assign vga_mem_addr = 19'h000000;
	assign vga_mem_data = 8'hZZ;
	assign irq_n = 1'b1;

endmodule
