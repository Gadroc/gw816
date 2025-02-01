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

module uart_transmitter (
	input logic				clock_i,
	input logic				reset_i,
	
	input logic [15:0]	shift_div_i,			// Shift Clock Divider

	input logic				tx_start_i,				// New data ready to transmit
	input logic  [7:0]	tx_data_i,				// Data to Transmist
	
	output logic			tx_active_o,			// We are activley transmitting
	output logic			tx_complete_o,			// Complete Indicator

	output logic			tx_o						// Output Serial
);

	logic [15:0] clock_count_r;
	logic  [2:0] bit_count_r;
	logic	 [7:0] tx_data_r;

	enum int unsigned { IDLE = 1, START = 2, DATA = 4, STOP = 8, COMPLETE = 16 } state;
	
	always_ff @(posedge clock_i) begin
		if (reset_i) begin
			state 			<= IDLE;
			tx_active_o		<= '0;
			tx_complete_o	<= '0;
			tx_o				<= '1;
		end 
	
		else case(state)
		
			IDLE: begin				
				tx_o				<= '1;
				tx_complete_o	<= '0;
				clock_count_r	<= '0;
				bit_count_r		<= '0;
				
				if (tx_start_i) begin
					
					tx_active_o <= '1;
					tx_data_r	<= tx_data_i;
					state			<= START;
					
				end				
			end
			
			START: begin
				tx_o	<= '0;
				
				if (clock_count_r < shift_div_i)
					clock_count_r	<= clock_count_r + 1;
				else begin
					clock_count_r	<= '0;
					state				<= DATA;
				end
			end
					
			DATA: begin
				tx_o <= tx_data_r[0];
				
				if (clock_count_r < shift_div_i)
					clock_count_r	<= clock_count_r + 1;
				else begin
					clock_count_r	<= '0;
					
					if (bit_count_r < 7) begin
						bit_count_r <= bit_count_r + 1;
						tx_data_r = { 1'b0, tx_data_r[7:1] };
					end
					else begin
						bit_count_r <= '0;
						state <= STOP;
					end						
				end
			end
			
			STOP: begin
				tx_o	<= '1;
				
				if (clock_count_r < shift_div_i)
					clock_count_r	<= clock_count_r + 1;
				else begin
					clock_count_r	<= '0;
					tx_active_o		<= '0;
					tx_complete_o	<= '1;
					state				<= COMPLETE;
				end
			end
			
			COMPLETE: begin
				state <= IDLE;
			end			
			
		endcase
	
	end
	
endmodule	