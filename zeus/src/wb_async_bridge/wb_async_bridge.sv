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

// Bridges asynchronous clients to a wishbone bus.
//
// Async clients must should assert ACK when they have
// completed the transaction and deassert ACK when request line goes low.
//
module wb_async_client_bridge #(
	ADDR_BITS = 5,
	DATA_BITS = 8
) (
	input  logic						wb_clk_i,				// Wishbone Bus Clock
	input  logic  [DATA_BITS-1:0]	wb_data_i,				// Wishbone Bus Data In
	output logic  [DATA_BITS-1:0]	wb_data_o,				// Wishbone Bus Data Out
	input  logic						wb_reset_i,				// Wishbone Bus Reset
	
	output logic 					   wb_ack_o,				// Wishbone Bus Ack
	input  logic  [ADDR_BITS-1:0]	wb_addr_i,				// Wishbone Bus Address
	output logic 						wb_stall_o,				// Wishbone Stall
	input  logic						wb_strobe_i,			// Wishbone Strobe / Transaction Valid
	input  logic						wb_write_i,				// Wishbone Write Enable
	
	input  logic						read_only_i,			// NOP Ack Writes when in read only mode
	
	output logic						ab_write_req_o,		// Async Bus Write Request
	output logic						ab_read_req_o,			// Async Bus Read Request
	input  logic 						ab_ack_i,				// Async Bus Acknowledge
	output logic [ADDR_BITS-1:0]  ab_addr_o, 				// Async Bus Address lines
	inout  logic [DATA_BITS-1:0]  ab_data_io				// Async Bus Data lines
);
	logic [DATA_BITS-1:0] trx_data;
	logic trx_write;
	logic	q_ack, qq_ack;
	
	
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i)
			{ qq_ack, q_ack } <= 2'b00;
		else
			{ qq_ack, q_ack } <= { q_ack, ab_ack_i };
	
	end
	
	// New transaction starts any time we are not stalled and strobe is high.
	wire wb_trx_accepted = (!wb_stall_o && wb_strobe_i);
	
	// Async bus can only process one request at a time, and can not 
	// accept new request till client device deasserts ACK.
	assign wb_stall_o = ab_write_req_o || ab_read_req_o || qq_ack;
	
	// Put write data on the bus during write otherwise keep bus at hi-z
	assign ab_data_io = ab_write_req_o ? trx_data : 'z;
	
	wire ab_req_complete = qq_ack || (ab_write_req_o && read_only_i);
	
	enum int unsigned { IDLE = 1, BUSY = 2 } state;
		
	always_ff @(posedge wb_clk_i) begin
		
		// Remove any external signals on the async bus at reset
		// or ack from request
		if (wb_reset_i) begin
			state 			<= IDLE;
			wb_ack_o			<= '0;
			ab_addr_o		<= '0;
			trx_data			<= '0;
			trx_write		<= '0;
		end
		
		else case (state)
			
			IDLE: begin
				wb_ack_o <= '0;
				ab_write_req_o <= '0;
				ab_read_req_o <= '0;

				if (wb_trx_accepted) begin
					state				<= BUSY;
					ab_addr_o		<= wb_addr_i;
					trx_data			<= wb_data_i;
				end
				
			end
			
			BUSY: begin
				ab_write_req_o <= (trx_write && ~read_only_i);
				ab_read_req_o  <= (~trx_write);
			
				if (ab_req_complete) begin
					wb_ack_o	<= '1;
					wb_data_o <= ab_data_io;
					state <= IDLE;
				end
				
			end
		
		endcase
		
	end
	
endmodule