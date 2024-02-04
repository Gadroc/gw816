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

// SPI Master controller which connects an SDRAm chip to a 65xxx bus.
//
// Memory speed must be sufficiently higher than the 65xxx bus to allow for
// * Single read to fit with in phi2 high cycle
// * SDRAM tRC period fits within one phi2 full cycle
//
// Addr 
// 00 = SPI Mode Register
// 01 = SPI Device Select / Status Register
// 10 = SPI Rx/Tx Data (Read = Received data from last transfer, Write = Transfer out byte)
// 11 = Reserved
//
module spi_controller (
	input  wire			clk,			// System Clock
	input  wire			cs_n,			// Chip Select for IRQ Controller
	input  wire			reset_n,		// Bus Resest

	input  wire  [4:0]	bus_cycle,		// Bus Clock
	input  wire  [1:0]	address,		// Address
	input  wire 		read_write,		// Read (High) / Write (Low) Select
	input  wire  [7:0]	data_in,		// Peripheral Data Bus In
	output reg   [7:0]	data_out,		// Peripheral Data Bus Out
	
	output wire			irq_n,			// IRQ Signal
	
	input  wire			clk_shift,		// Clock used to drive shift
	
	input  wire			miso,			// SPI Master In Slave Out
	output reg			mosi,			// SPI Master Out Slave In
	output reg			sclk,			// SPI Shift Clock
	output reg   [3:0]  ss_n			// SPI Slave Select lines
);

	// ---------------------------------------------------------------------------------------------
	// Control Registers
	// ---------------------------------------------------------------------------------------------
	reg cpol = 1'b0;				// Clock idle polarity (0 = low, 1 = high)
	reg cpha = 1'b0;				// Clock phase sample on (0 = leading, 1 = trailing)
	reg [2:0] shift_divider = 3'h0;	// Number of clk_spi pulses * 2 per half cycle of sclk
	reg [1:0] device_select = 1'b0;	// Slave device selected
	reg auto_read_mode = 1'b0;		// When set a read for the data register writes $ff

	// ---------------------------------------------------------------------------------------------
	// Shift State Model
	// ---------------------------------------------------------------------------------------------
	localparam IDLE				= 3'h0;
	localparam TFR_START		= 3'h1;
	localparam LEADING_EDGE  	= 3'h2;
	localparam TRAILING_EDGE	= 3'h3;
	localparam TFR_COMPLETE     = 3'h4;

	reg [2:0] shift_state = IDLE;	// State of the shift clock
	reg [2:0] shift_counter = 3'h0;	// Counts the bits we have shifted of the data byte
	reg [2:0] clock_counter = 3'h0;	// Count down to next SCLK polairty change

	reg [7:0] rx_data = 8'h00;
	reg [7:0] tx_data = 8'h00;
	reg [7:0] shift_data = 8'h00;

	reg tx_ready = 1'b0;
	reg tx_complete = 1'b0;
	reg rx_read = 1'b0;

	assign irq_n = tx_complete && !rx_read;

	// ---------------------------------------------------------------------------------------------
	// Bus Interface
	// ---------------------------------------------------------------------------------------------
	always @(posedge clk) begin

		if (reset_n) begin
			cpol			<= 1'b0;
			cpha			<= 1'b0;
			shift_divider	<= 3'b000;
			device_select	<= 2'b00;
			auto_read_mode	<= 1'b0;
			ss_n			<= 2'b11;

		end else begin

			if (tx_ready && tx_complete) begin
				tx_ready <= 1'b0;
			end

			if (!cs_n) begin

				if (read_write) begin
					
					case (address)

						2'b00 : data_out <= { cpol, cpha, shift_divider, device_select, auto_read_mode };

						2'b01 : data_out <= { 6'h0 , tx_complete, shift_state != IDLE };

						2'b10 : begin
							data_out	<= rx_data;
							rx_read		<= 1'b1;

							if (auto_read_mode) begin

								tx_data		<= 8'hff;
								tx_ready	<= 1'b1;

							end

						end

						default: data_out <= 8'h00;

					endcase

				end else begin

					data_out <= 8'h00;

					if (bus_cycle == 8'h10) begin

						case (address)

							2'b00 : begin
								cpol			<= data_in[7];
								cpha			<= data_in[6];
								shift_divider	<= data_in[5:3];
								device_select	<= data_in[2:1];
								auto_read_mode	<= data_in[0];

								ss_n[0] <= !(data_in[7:6] == 2'h1);
								ss_n[1] <= !(data_in[7:6] == 2'h2);
								ss_n[2] <= !(data_in[7:6] == 2'h3);

							end

							2'b11 : begin
								if (!tx_ready) begin

									tx_data		<= data_in;
									tx_ready	<= 1'b1;
									rx_read		<= 1'b0;

								end
							end

						endcase

					end

				end

			end
		end

	end

	// ---------------------------------------------------------------------------------------------
	// SPI Shift Logic
	// ---------------------------------------------------------------------------------------------
	always @(posedge clk_shift) begin

		if (clock_counter > 0) begin

			clock_counter <= clock_counter - 1'b1;

		end else begin

			case (shift_state)

				IDLE: begin

					sclk = (cpol) ? 1'b1 : 1'b0;

					if (tx_ready) begin
						tx_complete <= 1'b0;

						// Shift out first byte on CPHA 0
						if (!cpha) begin
							mosi	<= tx_data[7];
							shift_data <= { tx_data[6:0], 1'b0 };
						end else begin
							shift_data <= tx_data;
						end

						shift_counter	<= 3'h0;
						clock_counter	<= shift_divider;
						shift_state		<= LEADING_EDGE;

					end

				end

				LEADING_EDGE: begin

					shift_counter <= shift_counter + 1'b1;

					if (cpha) begin
						mosi <= tx_data[7];
						shift_data <= { shift_data[6:0], 1'b0 };
					end else begin
						rx_data <= { rx_data[6:0], miso };
					end

					sclk = (cpol) ? 1'b0 : 1'b1;
					clock_counter	<= shift_divider;
					shift_state		<= TRAILING_EDGE;

				end

				TRAILING_EDGE: begin

					clock_counter <= shift_divider;

					if (cpha) begin
						rx_data <= { rx_data[6:0], miso };
					end else begin
						mosi	<= tx_data[7];
						shift_data <= { shift_data[6:0], 1'b0 };
					end

					sclk = (cpol) ? 1'b1 : 1'b0;			
					clock_counter	<= shift_divider;
					shift_state		<= (shift_counter == 3'h0) ? TFR_COMPLETE : LEADING_EDGE;

				end

				TFR_COMPLETE: begin

					if (cpha) begin
						rx_data <= { rx_data[6:0], miso };
					end

					tx_complete		<= 1'b1;			// Mark transfer complete					
					clock_counter	<= shift_divider;	// Make sure CS is off for appropriate time
					shift_state		<= IDLE;			// and then go back to waiting for transfer

				end

			endcase

		end

	end
	
endmodule