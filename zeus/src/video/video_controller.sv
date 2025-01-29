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

module video_controller (
	input  logic			clk50_i,				// 50Mhz Refernce Clock
	
	input  logic			wb_clk_i,			// Wishbone Bus Clock
	input  logic  [7:0]	wb_data_i,			// Wishbone Bus Data In
	output logic  [7:0]	wb_data_o,			// Wishbone Bus Data Out
	input  logic			wb_reset_i,			// Wishbone Bus Reset
	
	output logic			wb_ack_o,			// Wishbone Bus Ack
	input  logic  [4:0]	wb_addr_i,			// Wishbone Bus Address
	output logic			wb_stall_o,			// Wishbone Stall
	input  logic			wb_strobe_i,		// Wishbone Strobe / Transaction Valid
	input  logic			wb_write_i,			// Wishbone Write Enable
	
	// VRAM Port
	output logic [14:0]	vram_addr_o,
	input  logic [31:0]	vram_data_i,
	
	// VGA Port
	output wire [4:0]		vga_red,					// VGA Red Signal Level
	output wire [5:0]		vga_green,				// VGA Green Signal Level
	output wire [4:0]		vga_blue,				// VGA Blue Signal Level
	output wire				vga_h_sync,				// VGA H-Sync Signal
	output wire				vga_v_sync				// VGA V-Sync Signal
);

	logic [7:0] pal_addr_r;
	
	logic [1:0] l0_map_width_r, l0_map_height_r, l0_color_depth_r;
	logic l0_bitmap_mode_r, l0_enable_r, l0_tile_width_r, l0_tile_height_r, l0_pixel_double_r, l0_line_double_r;
	logic [5:0] l0_map_addr_r, l0_tile_addr_r;

	logic [1:0] l1_map_width_r, l1_map_height_r, l1_color_depth_r;
	logic l1_bitmap_mode_r, l1_enable_r, l1_tile_width_r, l1_tile_height_r, l1_pixel_double_r, l1_line_double_r;
	logic [5:0] l1_map_addr_r, l1_tile_addr_r;
	
	// ---------------------------------------------------------------------------------------------
	// Register Access
	// ---------------------------------------------------------------------------------------------
	assign wb_stall_o = '0;
	wire wb_trx_accepted = wb_strobe_i;
	
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i) begin
			pal_addr_r <= 8'hff;
			l0_pixel_double_r <= '0;
			l0_line_double_r <= '0;
			l0_map_width_r <= '0;
			l0_map_height_r <= '0;
			l0_color_depth_r <= '0;
			l0_bitmap_mode_r <= '1;
			l0_enable_r <= '0;
			l0_tile_width_r <= '0;
			l0_tile_height_r <= '0;
			l0_map_addr_r <= '0;
			l0_tile_addr_r <= '0;
			l1_pixel_double_r <= '0;
			l1_line_double_r <= '0;
			l1_map_width_r <= '0;
			l1_map_height_r <= '0;
			l1_color_depth_r <= '0;
			l1_bitmap_mode_r <= '1;
			l1_enable_r <= '0;
			l1_tile_width_r <= '0;
			l1_tile_height_r <= '0;
			l1_map_addr_r <= '0;
			l1_tile_addr_r <= '0;
		end
		
		else begin
			
			if (wb_trx_accepted) begin
			
				if (wb_write_i)
					case(wb_addr_i)
						5'h0: pal_addr_r <= wb_data_i;
						5'h1: { l0_map_width_r, l0_map_height_r, l0_bitmap_mode_r, l0_enable_r, l0_color_depth_r } <= wb_data_i;
						5'h2: { l0_map_addr_r, l0_pixel_double_r, l0_line_double_r } <= wb_data_i;
						5'h3: { l0_tile_addr_r, l0_tile_width_r, l0_tile_height_r } <= wb_data_i;
						5'h4: { l1_map_width_r, l1_map_height_r, l1_bitmap_mode_r, l1_enable_r, l1_color_depth_r } <= wb_data_i;
						5'h5: { l1_map_addr_r, l1_pixel_double_r, l1_line_double_r } <= wb_data_i;
						5'h6: { l1_tile_addr_r, l1_tile_width_r, l1_tile_height_r } <= wb_data_i;
						default: begin end
					endcase
				else
					case(wb_addr_i)
						5'h0: wb_data_o <= pal_addr_r;
						5'h1: wb_data_o <= { l0_map_width_r, l0_map_height_r, l0_bitmap_mode_r, l0_enable_r, l0_color_depth_r };
						5'h2: wb_data_o <= { l0_map_addr_r, l0_pixel_double_r, l0_line_double_r };
						5'h3: wb_data_o <= { l0_tile_addr_r, l0_tile_width_r, l0_tile_height_r };
						5'h4: wb_data_o <= { l1_map_width_r, l1_map_height_r, l1_bitmap_mode_r, l1_enable_r, l1_color_depth_r };
						5'h5: wb_data_o <= { l1_map_addr_r, l1_pixel_double_r, l1_line_double_r };
						5'h6: wb_data_o <= { l1_tile_addr_r, l1_tile_width_r, l1_tile_height_r };
						default: wb_data_o <= 8'h0;
					endcase
			end
			
		end
	
	end
	
	always_ff @(posedge wb_clk_i) begin
		wb_ack_o <= wb_strobe_i;
	end
	
	// ---------------------------------------------------------------------------------------------
	// VRAM Arbiter
	// ---------------------------------------------------------------------------------------------
	logic [31:0] vram_data;
	vram_arbiter virtual_vram (
		.clk_i			(wb_clk_i),
		.vram_addr_o	(vram_addr_o),
		.vram_data_i	(vram_data_i),
		
		.vrf0_addr_i	(pal_vram_addr),
		.vrf0_strobe_i	(pal_vram_strobe),
		.vrf0_ack_o		(pal_vram_ack),

		.vrf1_addr_i	(l0_vram_addr),
		.vrf1_strobe_i	(l0_vram_strobe),
		.vrf1_ack_o		(l0_vram_ack),

		.vrf2_addr_i	(l1_vram_addr),
		.vrf2_strobe_i	(l1_vram_strobe),
		.vrf2_ack_o		(l1_vram_ack),
		
		.vrf3_strobe_i	('0),
				
		.vrf_data_o		(vram_data)
	);

	// ---------------------------------------------------------------------------------------------
	// VGA Signal Generation
	// ---------------------------------------------------------------------------------------------
	wire pixel_clk;
	pll_vga vga_clock (
		.inclk0	(clk50_i),
		.c0		(pixel_clk)
	);	
	
	wire [15:0] vga_color_data;
	wire vga_next_frame, vga_next_line, vga_next_pixel;
	vga_signal_generator vga (
		.pix_clk_i			(pixel_clk),
		.reset_i				(wb_reset_i),
		
		.vga_red				(vga_red),
		.vga_green			(vga_green),
		.vga_blue			(vga_blue),
		.vga_h_sync			(vga_h_sync),
		.vga_v_sync			(vga_v_sync),
		
		.next_frame_o		(vga_next_frame),
		.next_line_o		(vga_next_line),
		.next_pixel_o		(vga_next_pixel),
		
		.color_data_i		(vga_color_data)
	);
	
	logic qqq_next_line, qq_next_line, q_next_line;
	logic qqq_next_frame, qq_next_frame, q_next_frame;
	logic qqq_next_pixel, qq_next_pixel, q_next_pixel;
	
	always_ff @(posedge wb_clk_i) begin
		{ qqq_next_frame, qq_next_frame, q_next_frame } <= { qq_next_frame, q_next_frame, vga_next_frame };
		{ qqq_next_line, qq_next_line, q_next_line } <= { qq_next_line, q_next_line, vga_next_line };
		{ qqq_next_pixel, qq_next_pixel, q_next_pixel } <= { qq_next_pixel, q_next_pixel, vga_next_pixel && pixel_clk };
	end
	
	wire next_frame = qqq_next_frame && !qq_next_frame;
	wire next_line = qqq_next_line && !qq_next_line;
	wire next_pixel = qqq_next_pixel && !qq_next_pixel;
	
	// ---------------------------------------------------------------------------------------------
	// Pixel Line Buffers
	// ---------------------------------------------------------------------------------------------
	wire l0_buffer_write, l1_buffer_write;
	wire [9:0] buffer_read_addr, l0_buffer_write_addr, l1_buffer_write_addr;
	wire [7:0] l0_buffer_in, l0_buffer_out, l1_buffer_in, l1_buffer_out;
	
	line_buffer l0_buffer (
		.clk_i			(wb_clk_i),
		.read_addr_i	(buffer_read_addr),
		.read_data_o	(l0_buffer_out),		
		.write_i			(l0_buffer_write),
		.write_addr_i	(l0_buffer_write_addr),
		.write_data_i	(l0_buffer_in)
	);
	
	line_buffer l1_buffer (
		.clk_i			(wb_clk_i),
		.read_addr_i	(buffer_read_addr),
		.read_data_o	(l1_buffer_out),		
		.write_i			(l1_buffer_write),
		.write_addr_i	(l1_buffer_write_addr),
		.write_data_i	(l1_buffer_in)
	);	

	// ---------------------------------------------------------------------------------------------
	// Compositor
	// ---------------------------------------------------------------------------------------------
	// Compositor iterates through a scan line and will take care of layering of renderers and
	// looking up palette data.
	// ---------------------------------------------------------------------------------------------
	wire pal_vram_strobe, pal_vram_ack;
	wire [14:0] pal_vram_addr;
	
	video_compositor compositor (
		.clk_i				(wb_clk_i),
		.next_frame_i		(next_frame),
		.next_line_i		(next_line),		
		.next_pixel_i		(next_pixel),
		
		.buff_addr_o		(buffer_read_addr),

		.l0_buff_data_i	(l0_buffer_out),
		.l1_buff_data_i	(l1_buffer_out),
		
		.l0_enable_i		(l0_enable_r),
		.l1_enable_i		(l1_enable_r),
		
		.pal_base_i			(pal_addr_r),
		
		.vram_addr_o		(pal_vram_addr),
		.vram_strobe_o		(pal_vram_strobe),
		.vram_ack_i			(pal_vram_ack),
		.vram_data_i		(vram_data),
		
		.color_data_o		(vga_color_data)
	);
	
		
	// ---------------------------------------------------------------------------------------------
	// Layer Renderers
	// ---------------------------------------------------------------------------------------------
	wire l0_vram_strobe, l0_vram_ack;
	wire [14:0] l0_vram_addr;
	wire [7:0] l0_pal_index;
	
	layer_renderer l0_renderer (
		.clk_i				(wb_clk_i),
		.next_frame_i		(next_frame),
		.next_line_i		(next_line),
		
		.line_double_i		(l0_line_double_r),
		.pixel_double_i	(l0_pixel_double_r),
		.map_width_i		(l0_map_width_r),
		.map_height_i		(l0_map_height_r),
		.color_depth_i		(l0_color_depth_r),
		.bitmap_mode_i		(l0_bitmap_mode_r),
		.tile_width_i		(l0_tile_width_r),
		.tile_height_i		(l0_tile_height_r),
		.map_base_i			(l0_map_addr_r),
		.tile_base_i		(l0_tile_addr_r),
		
		.vram_addr_o		(l0_vram_addr),
		.vram_strobe_o		(l0_vram_strobe),
		.vram_ack_i			(l0_vram_ack),
		.vram_data_i		(vram_data),
		
		.buff_addr_o		(l0_buffer_write_addr),
		.buff_write_o		(l0_buffer_write),
		.buff_data_o		(l0_buffer_in)
	);

	wire l1_vram_strobe, l1_vram_ack;
	wire [14:0] l1_vram_addr;
	wire [7:0] l1_pal_index;
	
	layer_renderer l1_renderer (
		.clk_i				(wb_clk_i),
		.next_frame_i		(next_frame),
		.next_line_i		(next_line),
		
		.line_double_i		(l1_line_double_r),
		.pixel_double_i	(l1_pixel_double_r),
		.map_width_i		(l1_map_width_r),
		.map_height_i		(l1_map_height_r),
		.color_depth_i		(l1_color_depth_r),
		.bitmap_mode_i		(l1_bitmap_mode_r),
		.tile_width_i		(l1_tile_width_r),
		.tile_height_i		(l1_tile_height_r),
		.map_base_i			(l1_map_addr_r),
		.tile_base_i		(l1_tile_addr_r),
		
		.vram_addr_o		(l1_vram_addr),
		.vram_strobe_o		(l1_vram_strobe),
		.vram_ack_i			(l1_vram_ack),
		.vram_data_i		(vram_data),
		
		.buff_addr_o		(l1_buffer_write_addr),
		.buff_write_o		(l1_buffer_write),
		.buff_data_o		(l1_buffer_in)
	);
	
endmodule