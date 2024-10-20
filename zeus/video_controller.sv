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

// VGA Video Controller for GW816

module video_controller (
	input  wire 			clk,					// Clock Bus for Registers

	// Bus Interface
	input  wire  [16:0]	address,				// Register Address
	input  wire  [7:0]	data_in,				// Peripheral Data Bus In
	output logic [7:0]	data_out,			// Peripheral Data Bus Out

	input  wire				phi2,					// Bus Clock
	input  wire  [11:0]	phi2_cycle,			// Bus Cycle
	input  wire 			read_write,			// Read (High) / Write (Low) Select
	input  wire				reset_n,				// Bus Resest
	input  wire				cs_n,					// Chip Select for Video Controller
	input  wire				vram_cs_n,			// Chip Select for Reading Writing VRAM


	// Video Card Signals
	input  wire 			clk_pix,				// Pixel Display Clock

	output wire [4:0]		vga_red,				// VGA Red Signal Level
	output wire [5:0]		vga_green,			// VGA Green Signal Level
	output wire [4:0]		vga_blue,			// VGA Blue Signal Level
	output wire				vga_h_sync,			// VGA H-Sync Signal
	output wire				vga_v_sync			// VGA V-Sync Signal	
);

	localparam HORIZ_VIS		= 10'd639;	// Maximum Value for visible data
	localparam HORIZ_FP		= 10'd016;	// Count of Front Porch
	localparam HORIZ_SP		= 10'd096;	// Count of Sync Pulse
	localparam HORIZ_BP		= 10'd048;	// Count of Back Porch

	localparam HSYNC_START	= (HORIZ_VIS + HORIZ_FP);
	localparam HSYNC_END		= (HSYNC_START + HORIZ_SP);
	localparam HORIZ_MAX		= (HORIZ_VIS + HORIZ_FP + HORIZ_SP + HORIZ_BP);

	localparam VERT_VIS		= 10'd399;	// Maximum Value for visible data
	localparam VERT_FP		= 10'd012;	// Count of Front Porch
	localparam VERT_SP		= 10'd002;	// Count of Sync Pulse
	localparam VERT_BP		= 10'd035;	// Count of Back Porch

	localparam VSYNC_START	= (VERT_VIS + VERT_FP);
	localparam VSYNC_END		= (VSYNC_START + VERT_SP);
	localparam VERT_MAX		= (VERT_VIS + VERT_FP + VERT_SP + VERT_BP);

	// ---------------------------------------------------------------------------------------------
	// VRAM and Register Control
	// ---------------------------------------------------------------------------------------------
	logic [16:0]	vram_address = 16'h0000;
	wire  [7:0]		vram_a_data_out;
	wire  [7:0]		vram_b_data_out;
	
	
	dual_port_dual_clk_ram #(.DATA_WIDTH (8), .ADDR_WIDTH (17)) vram (
		.addr_a		(address),
		.addr_b		(vram_address),
		.clk_a			(clk),
		.clk_b			(clk_pix),
		.data_a			(data_in),
		.data_b			(8'h00),
		.we_a				(phi2 && !vram_cs_n),
		.we_b				(1'b0),
		.q_a				(vram_a_data_out),
		.q_b				(vram_b_data_out)
	);

	// Mux VRAM and Registers
	always @(posedge clk) begin

		if (!vram_cs_n && read_write) begin
			data_out <= vram_a_data_out;
		end else begin 
			data_out <= 8'h00;
		end

	end


	// ---------------------------------------------------------------------------------------------
	// Video Signals
	// ---------------------------------------------------------------------------------------------
	reg  [9:0]	horiz_pos;			// Current Horizontal Position
	reg  [9:0]  vert_pos;			// Current Vertical Position
	reg			visible_region;	// High when in vertical area of display


	// ---------------------------------------------------------------------------------------------
	// Sync Generation
	// ---------------------------------------------------------------------------------------------
	assign vga_h_sync			= ~((horiz_pos > HSYNC_START) && (horiz_pos <= HSYNC_END));
	assign vga_v_sync			= ~((vert_pos > VSYNC_START) && (vert_pos <= VSYNC_END));
	assign visible_region	= horiz_pos <= HORIZ_VIS && vert_pos <= VERT_VIS;

	always @(posedge clk_pix) begin

		if (!reset_n) begin

			// During reset setup up during vertical blank to start fetching data
			horiz_pos	<= 10'd000;
			vert_pos 	<= VERT_VIS + 10'h001;

		end else begin

			if (horiz_pos == HORIZ_MAX) begin

				horiz_pos	<= 10'd000;
				vert_pos		<= (vert_pos >= VERT_MAX) ? 10'd000 : vert_pos + 10'd001;

			end else begin	

				horiz_pos <= horiz_pos + 10'd001;

			end

		end

	end


	// ---------------------------------------------------------------------------------------------	
	// Color Pattern
	// ---------------------------------------------------------------------------------------------
	reg [3:0] color_count;
	reg [5:0] color;

	assign vga_red			= 5'b00000;
	assign vga_green		= visible_region ? color : 6'b000000;
	assign vga_blue		= 5'b00000;

	always @(posedge clk_pix) begin

		if (vert_pos == VERT_MAX) begin

			color       <= 5'h00;
			color_count <= 4'h0;

		end else begin

			if (horiz_pos == HORIZ_MAX) begin
				if (color_count == 4'd7) begin
					color_count <= 4'd00;
					color <= (color == 6'b111111) ? 5'd0 : color + 5'd1; 
				end else begin
					color_count <= color_count + 4'd01;
				end
			end
		end

	end

endmodule