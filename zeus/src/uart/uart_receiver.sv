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

module uart_receiver (
	input  logic			clock_i,
	input  logic			reset_i,
	
	input  logic [15:0]	shift_div_i,			// Shift Clock Divider

	output logic  [7:0]	rx_data_o,				// Data to Transmist
	
	output logic			rx_active_o,			// We are activley transmitting
	output logic			rx_complete_o,			// Complete Indicator
	output logic			rx_frame_err_o,

	input  logic			rx_i						// Output Serial
);

	logic [15:0] clock_count_r;
	logic  [2:0] bit_count_r;
	logic qq_rx, q_rx;
	
	// Synchronize serial input signal to clock domain
	always_ff @(posedge clock_i) begin
		{ qq_rx, q_rx } <= { q_rx, rx_i };
	end
	
	enum int unsigned { IDLE = 1, START = 2, DATA = 4, STOP = 8, COMPLETE = 16 } state;
	
	
	always_ff @(posedge clock_i) begin
	
		if (reset_i) begin
			rx_active_o		<= '0;
			rx_complete_o	<= '0;
			rx_data_o		<= '0;
			state 			<= IDLE;
		end
		
		else case(state)
		
			IDLE: begin
				rx_complete_o	<= '0;
				clock_count_r	<= '0;
				bit_count_r		<= '0;
				
				if (qq_rx == 1'b0)
					state <= START;
			end
			
			START: begin
			
				if (clock_count_r == { 1'b0, shift_div_i[15:1] }) begin
					if (qq_rx == 1'b0) begin
						clock_count_r	<= '0;
						rx_active_o		<= '1;
						state <= DATA;
					end
					else
						state <= IDLE;
				end
				else
					clock_count_r <= clock_count_r + 1;
			
			end
			
			DATA: begin
				
				if (clock_count_r < shift_div_i)
					clock_count_r	<= clock_count_r + 1;
				else begin
				
					clock_count_r <= '0;
					rx_data_o <= { qq_rx, rx_data_o[7:1] };
					if (bit_count_r == 3'h7)
						state <= STOP;
					else
						bit_count_r <= bit_count_r + 1;
				
				end
				
			end
			
			STOP: begin
			
				if (clock_count_r < shift_div_i)
					clock_count_r	<= clock_count_r + 1;
				else begin
					rx_active_o		<= '0;
					rx_complete_o	<= '1;
					
					if (qq_rx == 1'b0)
						rx_frame_err_o <= '1;						
					
					state <= COMPLETE;
				end
			
			end
			
			COMPLETE: begin
				rx_complete_o	<= '0;
				rx_frame_err_o	<= '0;
				state <= IDLE;
			end
		
		endcase
	
	end

endmodule