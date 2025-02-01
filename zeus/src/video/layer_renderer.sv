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

module layer_renderer (
	input  logic			clk_i,
	input  logic			next_frame_i,
	input  logic			next_line_i,
	
	input  logic			line_double_i,
	input  logic			pixel_double_i,
	input  logic  [1:0]	map_width_i,
	input  logic  [1:0]	map_height_i,
	input  logic  [1:0]	color_depth_i,
	input  logic			bitmap_mode_i,
	input  logic			tile_width_i,
	input  logic			tile_height_i,
	input  logic  [5:0]	map_base_i,
	input  logic  [5:0]  tile_base_i,
	
	output logic [14:0]  vram_addr_o,
	output logic 			vram_strobe_o,
	input  logic			vram_ack_i,
   input  logic [31:0]  vram_data_i,
	
	output logic  [9:0]	buff_addr_o,
	output logic 			buff_write_o,
	output logic  [7:0]	buff_data_o
);

	// Frame Position
	logic [9:0] frame_col_r, frame_row_r;
	logic			double_line_r;

	// Tile Map Data
	logic [14:0] map_data_addr_r;		// Address of data in map_data_r
	logic [31:0] map_data_r;			// Fetched Map Data

	// Tile or Bitmap Data
	logic [14:0] tile_data_addr_r;	// Address of tile data in tile_data_r
	logic [31:0] tile_data_r;			// Fetched tile data
	logic  [9:0] tile_pixel_r;			// Current pixel of the tile we are displaying	
	
	// Offset for the current bitmap line
	logic [16:0] bitmap_line_offset_r;
	
	// Determine line stride in 32bit reads
	logic [14:0] bitmap_stride;
	always_comb begin
		case (color_depth_i)
			2'b00: bitmap_stride = pixel_double_i ? 15'd320 : 15'd640;
			2'b01: bitmap_stride = pixel_double_i ? 15'd160 : 15'd320;
			2'b10: bitmap_stride = pixel_double_i ? 15'd80 : 15'd160;
			2'b11: bitmap_stride = pixel_double_i ? 15'd40 : 15'd80;
		endcase
	end
	
	// Line number of the current tile
	wire   [3:0] tile_line = tile_height_i ? frame_row_r[3:0] : { 1'b0, frame_row_r[2:0] };
	
	// Pixel offset in bytes for current pixel
	logic [9:0] pixel_offset;
	always_comb begin
		case (color_depth_i)
			2'b00: pixel_offset = tile_pixel_r;
			2'b01: pixel_offset = { 1'h0, tile_pixel_r[9:1] };
			2'b10: pixel_offset = { 2'h0, tile_pixel_r[9:2] };
			2'b11: pixel_offset = { 3'h0, tile_pixel_r[9:3] };
		endcase
	end
	
	wire [7:0] map_col;
	always_comb begin
		map_col = tile_width_i ? { 2'h0, frame_col_r[9:4] } : { 1'h0, frame_col_r[9:3] };
	end
	
	wire [7:0] map_row;
	always_comb begin
		map_row = tile_height_i ? { 2'h0, frame_row_r[9:4] } : { 1'h0, frame_row_r[9:3] };	
	end
		
	wire [16:0] map_row_offset;
	always_comb begin
		case (map_width_i)
			2'b00: map_row_offset = { map_row, 5'h0 };
			2'b01: map_row_offset = { map_row, 6'h0 };
			2'b10: map_row_offset = { map_row, 7'h0 };
			2'b11: map_row_offset = { map_row, 8'h0 };
		endcase
	end
		
	// Required map address to render current pixel
	logic [16:0] req_map_addr;
	always_comb begin
		req_map_addr = { map_base_i, 11'h0 } + map_row_offset + map_col;
	end
	
	// TODO: Calcuate tile index from map_data
	logic [7:0] tile_index;
	always_comb begin
		case (req_map_addr[1:0])
			2'b00: tile_index = map_data_r[31:24];
			2'b01: tile_index = map_data_r[23:16];
			2'b10: tile_index = map_data_r[15:8];
			2'b11: tile_index = map_data_r[7:0];
		endcase
	end

	logic [16:0] tile_offset;
	always_comb begin
			case ({ color_depth_i, tile_width_i, tile_height_i })
				4'b0011: 									tile_offset = { tile_index, 8'h0 }; // 256 Bytes Per Tile 
				4'b0001, 4'b0010, 4'b0111: 			tile_offset = { tile_index, 7'h0 }; // 128 Bytes Per Tile
				4'b0000, 4'b0101, 4'b0110, 4'b1011: tile_offset = { tile_index, 6'h0 };	//  64 Bytes Per Tile
				4'b0100, 4'b1001, 4'b1010, 4'b1111: tile_offset = { tile_index, 5'h0 };	//  32 Bytes Per Tile
				4'b1000, 4'b1101, 4'b1110:				tile_offset = { tile_index, 4'h0 };	//	 16 Bytes Per Tile
				4'b1100: 									tile_offset = { tile_index, 3'h0 };	//   8 Bytes Per Tile
			endcase
	end
	
	logic [7:0] line_offset;
	always_comb begin
		case ({ color_depth_i, tile_width_i })
			3'b001:				line_offset = { tile_line, 4'h0 };
		   3'b000, 3'b011:	line_offset = { 1'h0, tile_line, 3'h0 };
			3'b010, 3'b101:	line_offset = { 2'h0, tile_line, 2'h0 };
			3'b100, 3'b111:	line_offset = { 3'h0, tile_line, 1'h0 };
			3'b110:				line_offset =  8'h0;
		endcase
	end
	
	// Required tile address to render current pixel
	logic [16:0] req_tile_addr;
	always_comb begin
		if (bitmap_mode_i)
			req_tile_addr = { tile_base_i, 11'h0 } + bitmap_line_offset_r + pixel_offset;
		else
			req_tile_addr = { tile_base_i, 11'h0 } + tile_offset + line_offset + pixel_offset;
	end
	
	// Tile byte required for the current pixel
	logic [7:0] tile_byte;
	always_comb begin
		case (req_tile_addr[1:0])
			2'b00: tile_byte = tile_data_r[31:24];
			2'b01: tile_byte = tile_data_r[23:16];
			2'b10: tile_byte = tile_data_r[15:8];
			2'b11: tile_byte = tile_data_r[7:0];
		endcase
	end
	
	// Color index for the current pixel
	logic [7:0] pixel_pal_index;
	always_comb begin
		case (color_depth_i)
			2'b00: pixel_pal_index = tile_byte;
			
			2'b01: begin
				case (tile_pixel_r[0])
					1'b0: pixel_pal_index = { 4'b0, tile_byte[7:4] };
					1'b1: pixel_pal_index = { 4'b0, tile_byte[3:0] };
				endcase
			end
			
			2'b10: begin
				case (tile_pixel_r[1:0])
					2'b00: pixel_pal_index = { 6'b0, tile_byte[7:6] };
					2'b01: pixel_pal_index = { 6'b0, tile_byte[5:4] };
					2'b10: pixel_pal_index = { 6'b0, tile_byte[3:2] };
					2'b11: pixel_pal_index = { 6'b0, tile_byte[1:0] };
				endcase			
			end

			2'b11: begin
				case (tile_pixel_r[2:0])
					3'b000: pixel_pal_index = { 7'b0, tile_byte[7] };
					3'b001: pixel_pal_index = { 7'b0, tile_byte[6] };
					3'b010: pixel_pal_index = { 7'b0, tile_byte[5] };
					3'b011: pixel_pal_index = { 7'b0, tile_byte[4] };
					3'b100: pixel_pal_index = { 7'b0, tile_byte[3] };
					3'b101: pixel_pal_index = { 7'b0, tile_byte[2] };
					3'b110: pixel_pal_index = { 7'b0, tile_byte[1] };
					3'b111: pixel_pal_index = { 7'b0, tile_byte[0] };
				endcase			
			end
		endcase
	end
	
	wire end_of_tile = tile_pixel_r == (tile_width_i ? 10'hf : 10'h7);
	
	// Do we need to fetch a more map data.
	wire fetch_map  = !bitmap_mode_i && (req_map_addr[16:2] != map_data_addr_r);
	
	// Do we need to fetch a set of tile data.
	wire fetch_tile = req_tile_addr[16:2] != tile_data_addr_r;
	
	wire line_done = frame_col_r == (pixel_double_i ? 10'd320 : 10'd640);
	
	wire duplicate_line = line_double_i && double_line_r;
	
	enum int unsigned {
		IDLE			= 1,	// Waiting for line request
		MAP    		= 2,	// Fetch Map Data
		TILE			= 4,	// Fetch Tile Data
		PIXEL			= 8,	// Render Pixel
		DOUBLE		= 16,	// Render Duplicate Pixel
		NEXT			= 32	// Check for data fetch
	} state = IDLE;
	
	always_ff @(posedge clk_i) begin

		case (state)
			IDLE: begin
				frame_col_r <= '0;
			
				// Reset everything for new frame and start rendering line 0
				if (next_frame_i) begin
					frame_row_r <= '0;
					bitmap_line_offset_r <= '0;
					tile_pixel_r <= '0;
					double_line_r <= '1;
					state <= NEXT;
				end
				
				// Increment line and render it
				else if (next_line_i) begin
					
					double_line_r <= ~double_line_r;
					if (!duplicate_line) begin
						frame_row_r <= frame_row_r + 10'h1;
						bitmap_line_offset_r <= bitmap_line_offset_r + bitmap_stride;
						tile_pixel_r <= '0;				
						state <= NEXT;
					end
					
				end
			end
		
			MAP: begin
				vram_addr_o <= req_map_addr[16:2];
				map_data_addr_r <= req_map_addr[16:2];
				vram_strobe_o <= '1;
				if (vram_ack_i) begin
					map_data_r <= { vram_data_i[7:0], vram_data_i[15:8], vram_data_i[23:16], vram_data_i[31:24] };
					vram_strobe_o <= '0;
					state <= NEXT;
				end
			end
			
			TILE: begin
				vram_addr_o <= req_tile_addr[16:2];
				tile_data_addr_r <= req_tile_addr[16:2];
				vram_strobe_o <= '1;
				if (vram_ack_i) begin
					tile_data_r <= { vram_data_i[7:0], vram_data_i[15:8], vram_data_i[23:16], vram_data_i[31:24] };
					vram_strobe_o <= '0;
					state <= PIXEL;
				end				
			end
			
			PIXEL: begin
				buff_data_o <= pixel_pal_index;
				buff_write_o <= '1;
				
				if (end_of_tile && !bitmap_mode_i)
					tile_pixel_r <= '0;
				else
					tile_pixel_r <= tile_pixel_r + 10'h1;
				
				if (pixel_double_i) begin
					buff_addr_o <= { frame_col_r[8:0], 1'b0 };
					state <= DOUBLE;
				end
				else begin
					buff_addr_o <= frame_col_r;
					frame_col_r <= frame_col_r + 10'b1;
					state <= NEXT;
				end

			end
			
			DOUBLE: begin
				buff_addr_o <= { frame_col_r[8:0], 1'b1 };
				frame_col_r <= frame_col_r + 10'b1;
				state <= NEXT;
			end
			
			NEXT: begin
				buff_write_o <= '0;
				
				if (line_done)
					state <= IDLE;				
				else if (!bitmap_mode_i && fetch_map)
					state <= MAP;
				else if (fetch_tile)
					state <= TILE;
				else
					state <= PIXEL;						
			end
			
		endcase
	
	end
	
endmodule