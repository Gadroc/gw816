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

module video_compositor (
	input  logic			clk_i,
	input  logic			next_frame_i,
	input	 logic 			next_line_i,
	input  logic			next_pixel_i,
	
	output logic  [9:0]	buff_addr_o,
	input  logic  [7:0]	l0_buff_data_i,	
	input  logic  [7:0]	l1_buff_data_i,

	input  logic			l0_enable_i,
	input  logic			l1_enable_i,

	input  logic  [7:0]  pal_base_i,
	
	output logic [14:0]  vram_addr_o,
	output logic 			vram_strobe_o,
	input  logic			vram_ack_i,
   input  logic [31:0]  vram_data_i,
	
	output logic [15:0]	color_data_o
);

	logic  [9:0] current_col_r;
	logic [15:0] pal_addr_r;
	logic [15:0] color_data_r;
	
	assign buff_addr_o = current_col_r;
	assign vram_addr_o = { pal_base_i, pal_addr_r[7:1] };

	enum int unsigned {
		IDLE		= 0,		// Waiting for next frame or line.
		OUTPUT	= 2		// Output Color Data
	} state = IDLE;
	
	always_ff @(posedge clk_i) begin
	
		if (next_frame_i || next_line_i) begin
			current_col_r <= '0;
			state <= IDLE;
		end
		
		else case(state)
		
			IDLE: begin
				if (next_pixel_i) begin
					if (l1_enable_i && l1_buff_data_i > 8'h00)
						pal_addr_r <= l1_buff_data_i;
						
					else if (l0_enable_i && l0_buff_data_i > 8'h00)
						pal_addr_r <= l0_buff_data_i;
						
					else 
						pal_addr_r <= 8'h00;

					vram_strobe_o <= '1;
					
					state <= OUTPUT;				
				end
			end
			
			OUTPUT: begin								
				if (vram_ack_i) begin
					vram_strobe_o <= '0;

					color_data_o <= pal_addr_r[0] ? vram_data_i[31:16] : vram_data_i[15:0];
					
					current_col_r <= current_col_r + 10'h1;
					state <= IDLE;
				end
			end
		
		endcase
		
	end

endmodule