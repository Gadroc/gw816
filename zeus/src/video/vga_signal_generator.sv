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

module vga_signal_generator
# (

	HORIZ_VIS	= 10'd639,	// Maximum Value for visible data
	HORIZ_FP		= 10'd016,	// Count of Front Porch
	HORIZ_SP		= 10'd096,	// Count of Sync Pulse
	HORIZ_BP		= 10'd048,	// Count of Back Porch

	VERT_VIS		= 10'd399,	// Maximum Value for visible data
	VERT_FP		= 10'd012,	// Count of Front Porch
	VERT_SP		= 10'd002,	// Count of Sync Pulse
	VERT_BP		= 10'd035	// Count of Back Porch
	
) (

	input  logic 			pix_clk_i,			// Pixel Display Clock
	input  logic			reset_i,			// System Reset Signal
	
	// VGA Interface
	output logic  [4:0]	vga_red,			// VGA Red Signal Level
	output logic  [5:0]	vga_green,		// VGA Green Signal Level
	output logic  [4:0]	vga_blue,		// VGA Blue Signal Level
	output logic			vga_h_sync,		// VGA H-Sync Signal
	output logic			vga_v_sync,		// VGA V-Sync Signal
	
	// Compositor Interface
	output logic			next_frame_o,		// Trigger start of next frame and fill first line buffer
	output logic			next_line_o,		// Trigger fill of line buffer
	output logic  			next_pixel_o,		// Trigger next pixel output
	
	input  logic [15:0]	color_data_i		// RGB Data for current pixel
);
	localparam HSYNC_START	= (HORIZ_VIS + HORIZ_FP);
	localparam HSYNC_END		= (HSYNC_START + HORIZ_SP);
	localparam HORIZ_MAX		= (HORIZ_VIS + HORIZ_FP + HORIZ_SP + HORIZ_BP);

	localparam VSYNC_START	= (VERT_VIS + VERT_FP);
	localparam VSYNC_END		= (VSYNC_START + VERT_SP);
	localparam VERT_MAX		= (VERT_VIS + VERT_FP + VERT_SP + VERT_BP);
	
	logic  [9:0]	horiz_counter;			// Current Horizontal Position
	logic  [9:0]	vert_counter;			// Current Vertical Position
	logic				q_h_sync, q_v_sync;	// Delay for sync signals to match delay in color data
	logic				visible_r, q_visible;

	// Horizontal Sync Signal Generation
	wire h_sync		= ~((horiz_counter > HSYNC_START) & (horiz_counter <= HSYNC_END));
	
	// Vertical Sync Signal Generation
	wire v_sync		= ~((vert_counter > VSYNC_START) & (vert_counter <= VSYNC_END));

	// Are we in the visible region
	wire visible = (horiz_counter <= HORIZ_VIS) && (vert_counter <= VERT_VIS);
	
	// Trigger next frame at end of visible region
	wire next_frame = (horiz_counter == HORIZ_VIS + 10'h001) && (vert_counter == VERT_MAX);
	
	// Trigger next line at end of visisible space 1 scan line before
	wire next_line = (horiz_counter == HORIZ_VIS + 10'h001) && (vert_counter < VERT_VIS);
	
	// Trigger pixel changes on clock during visilbe area
	wire next_pixel = (horiz_counter == HORIZ_MAX && (vert_counter == VERT_MAX || vert_counter < VERT_VIS )) ||
							(horiz_counter < HORIZ_VIS && vert_counter <= VERT_VIS);
	
	// Display Counters
	always @(posedge pix_clk_i) begin

		if (reset_i) begin

			horiz_counter	<= 10'd000;
			vert_counter 	<= VERT_VIS + 10'h001;
			
		end else begin
		
			{ vga_h_sync, q_h_sync } <= { q_h_sync, h_sync };
			{ vga_v_sync, q_v_sync } <= { q_v_sync, v_sync };
			{ visible_r, q_visible } <= { q_visible, visible };
			
			vga_red		<= (visible_r) ? color_data_i[15:11] : 5'h00;
			vga_green	<= (visible_r) ? color_data_i[10:5] : 5'h00;
			vga_blue		<= (visible_r) ? color_data_i[4:0] : 5'h00;
			
			next_frame_o <= next_frame;
			next_line_o <= next_line;
			next_pixel_o <= next_pixel;
			
			if (horiz_counter == HORIZ_MAX) begin

				horiz_counter	<= 10'd000;
				vert_counter	<= (vert_counter == VERT_MAX) ? 10'd000 : vert_counter + 10'd001;

			end else begin	

				horiz_counter 	<= horiz_counter + 10'd001;

			end

		end

	end
		
endmodule