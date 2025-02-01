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

module uart_controller (
	input  logic			wb_clk_i,				// Wishbone Bus Clock
	input  logic  [7:0]	wb_data_i,				// Wishbone Bus Data In
	output logic  [7:0]	wb_data_o,				// Wishbone Bus Data Out
	input  logic			wb_reset_i,				// Wishbone Bus Reset
	
	output logic 			wb_ack_o,				// Wishbone Bus Ack
	input  logic   [4:0]	wb_addr_i,				// Wishbone Bus Address
	output logic			wb_stall_o,				// Wishbone Stall
	input  logic			wb_strobe_i,			// Wishbone Strobe / Transaction Valid
	input  logic			wb_write_i,				// Wishbone Write Enable
	
	output logic			int_req_o,				// CPU Interrupt Request
	
	output logic			uart_tx,
	output logic			uart_rts,
	input  logic			uart_rx,
	input  logic			uart_cts
);

	localparam RBR_ADDR = 0;
	localparam THR_ADDR = 0;
	localparam IER_ADDR = 1;
	localparam FCR_ADDR = 2;
	localparam LCR_ADDR = 3;
	localparam LSR_ADDR = 4;
	localparam MCSR_ADDR = 5;
	localparam DIVL_ADDR = 6;
	localparam DIVH_ADDR = 7;
	
	logic [15:0] clock_divisor;
	logic  [7:0] transmit_buffer;
	logic  [7:0] scratch_buffer;
	logic  [7:0] receive_buffer;
	logic tx_buf_empty_r, rx_buf_full_r, rx_overrun_r, rx_frame_err_r;
	logic rx_err_int_en, tx_buf_int_en, rx_buf_int_en;
	logic qq_cts, q_cts;
	
	// Synchronize RTS to wishbone clock domain
	always_ff @(posedge wb_clk_i) begin
		{ qq_cts, q_cts } <= { q_cts, uart_cts };
	end
	
	// ---------------------------------------------------------------------------------------------
	// Register Access
	// ---------------------------------------------------------------------------------------------
	assign wb_stall_o = '0;

	wire wb_trx_accepted = wb_strobe_i;
	
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i) begin
			clock_divisor  	<= 16'd3332; // Default to 2400 baud??
			receive_buffer 	<= '0;
			rx_err_int_en  	<= '0;
			tx_buf_int_en  	<= '0;
			rx_buf_int_en  	<= '0;
			rx_buf_full_r		<= '0;
			rx_overrun_r		<= '0;
			rx_frame_err_r		<= '0;
			tx_buf_empty_r		<= '1;
			wb_data_o			<= '0;
			tx_start				<= '0;
			uart_rts       	<= '1;
		end
				
		else begin
		
			if (tx_complete)
				tx_buf_empty_r <= '1;
				
			if (rx_complete) begin
				receive_buffer <= rx_data;
				rx_frame_err_r <= rx_frame_err;
				rx_overrun_r	<= rx_buf_full_r;
				rx_buf_full_r	<= '1;
			end
		
			if (wb_trx_accepted) begin
			
				if (wb_write_i)				
					case(wb_addr_i)
						5'h0: begin
							transmit_buffer <= wb_data_i;
							tx_buf_empty_r <= '0;
							tx_start <= '1;
						end
						5'h1: scratch_buffer <= wb_data_i;
						5'h4: clock_divisor[7:0] <= wb_data_i;
						5'h5: clock_divisor[15:8] <= wb_data_i;
						5'h6: { rx_err_int_en, tx_buf_int_en, rx_buf_int_en, uart_rts } <= { wb_data_i[6:4], wb_data_i[0] };
						default: begin end
					endcase
				else
					case(wb_addr_i)
						5'h1: wb_data_o <= scratch_buffer;
						5'h2: begin
							wb_data_o <= { rx_frame_err_r, rx_overrun_r, tx_buf_empty_r, rx_buf_full_r, 3'h0, qq_cts };
						end
						5'h3: begin
							wb_data_o		<= receive_buffer;
							rx_buf_full_r	<= '0;
							rx_overrun_r	<= '0;
							rx_frame_err_r	<= '0;							
						end					
						5'h4: wb_data_o <= clock_divisor[7:0];
						5'h5: wb_data_o <= clock_divisor[15:8];
						5'h6: wb_data_o <= { 1'b0, rx_err_int_en, tx_buf_int_en, rx_buf_int_en, 3'h0, uart_rts };
						default: wb_data_o <= 8'h0;
					endcase		
			end 
			
			else begin
				tx_start <= '0;
			end
			
		end
	
	end
	
	always_ff @(posedge wb_clk_i) begin
		wb_ack_o <= wb_strobe_i;
	end

	// ---------------------------------------------------------------------------------------------
	// Interrupt Signals
	// ---------------------------------------------------------------------------------------------
	assign int_req_o = (rx_frame_err_r && (rx_overrun_r || rx_frame_err_r))
						 || (tx_buf_int_en && tx_buf_empty_r)
						 || (rx_buf_int_en && rx_buf_full_r);
	
	// ---------------------------------------------------------------------------------------------
	// Transmitter UART
	// ---------------------------------------------------------------------------------------------
	logic	tx_start, tx_active, tx_complete;
	
	uart_transmitter transmitter (
		.clock_i			(wb_clk_i),
		.reset_i			(wb_reset_i),
		
		.shift_div_i	(clock_divisor),
		
		.tx_start_i		(tx_start),
		.tx_data_i		(transmit_buffer),
		
		.tx_active_o	(tx_active),
		.tx_complete_o (tx_complete),
		
		.tx_o				(uart_tx)
	);
	
	// ---------------------------------------------------------------------------------------------
	// Receiver UART
	// ---------------------------------------------------------------------------------------------
	logic	rx_active, rx_complete, rx_frame_err;
	logic [7:0] rx_data;
	
	uart_receiver receiver (
		.clock_i				(wb_clk_i),
		.reset_i				(wb_reset_i),
		
		.shift_div_i		(clock_divisor),
		
		.rx_data_o			(rx_data),
		.rx_active_o		(rx_active),
		.rx_complete_o		(rx_complete),
		.rx_frame_err_o	(rx_frame_err),
		
		.rx_i					(uart_rx)
	);
	
endmodule