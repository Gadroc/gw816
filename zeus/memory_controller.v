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

// 65xx SDRAM Controller
//
// Configuration Calculations
//
// INHIBIT_CYCLES:    {inhibit time in ns} / {clk period in ns}
// REFRESH_INTERVAL:  (({refresh time in ns} / {number of refreshes}) / {clk period in ns})
// 
// REF_TO_ACTIVE: 
// 
module memory_controller 
#(
	INHIBIT_CYCLES    = 16'd33333,	// Number of clk cycles for SDRAM inhibit during initialization
	INIT_REFRESHES    = 16'd8,		// Number of SDRAM auto refresh commands before init complete
	REFRESH_CYCLES    = 16'd9,		// Min number of clk cycles between SDRAM auto refresh (tRC)
	MODESET_CYCLES    = 16'd2,		// Number of clk cycles after SDRAM mode set (tRSC)
	PRECHARGE_CYCLES  = 16'd3,  	// Number of clk cycles after SDRAM precharge till command (tRP)
	CAS_LATENCY       = 16'd2,		// Number of clk cycles before latching SDRAM read output
	CAS_LATENCY_MODE  = 3'b010		// A6-A4 of mode select for cas latency

	ACTIVE_CYCLES     = 16'd7,		// Number of clk cycles after SDRAM active command to precharge (tRAS)
	WRITE_CYCLES      = 16'd5,		// Number of clk cycles after SDRAM write command (tWR)
	REFRESH_INTERVAL  = 16'd1122,  	// Number of phi2 cycles between SDRAM auto refreshes
	
) (
	input  wire 		clk,

	// Bus Interface
	input  wire  [23:0]	address,			// Address
	input  wire  [7:0]	data_in,			// Peripheral Data Bus In
	output wire  [7:0]	data_out,			// Peripheral Data Bus Out
	input  wire  [4:0]	bus_cycle,			// Phi2 Cycle Count
	input  wire 		read_write,			// Read (High) / Write (Low) Select
	input  wire			reset_n,			// Bus Resest
	input  wire			cs_n,				// Chip Select for Memory Controller
	
	output reg			ram_ready,			// Signals when RAM initialization is complete

	// SDRAM Interface
	output wire			sdram_clk,			// SDRAM Clock
	output reg  [12:0]	sdram_addr,			// SDRAM Address Bus
	output reg  [1:0]	sdram_bs,			// SDRAM Bank Select
	inout  wire [15:0]	sdram_data,			// SDRAM Data Bus
	output wire 		sdram_cs,			// SDRAM Chip Select
	output wire 		sdram_ras,			// SDRAM Row Address Strobe
	output wire 		sdram_cas,			// SDRAM Col Address Strobe
	output wire 		sdram_we,			// SDRAM Write Enable
	output reg  [1:0]	sdram_dqm,			// SDRAM Data Mask
	output reg	 		sdram_cke			// SDRAM Clock Enable
);
	// State Machine
	localparam INIT				= 4'h0;
	localparam INIT_PRECHARGE	= 4'h1;
	localparam INIT_MODE		= 4'h2;
	localparam INIT_REFRESH		= 4'h3;
	localparam SYNC				= 4'h4;
	localparam REFRESH  		= 4'h5;
	localparam ACTIVE   		= 4'h6;
	localparam OPERATION		= 4'h7;
	localparam DELAY   			= 4'h8;

	reg [3:0] state = INIT;			// Current state
	reg [3:0] delay_state = INIT;	// State to move to after delay is complete

	reg [15:0] delay_counter   = 16'h0000;	// Count down timer for cycles till next state
	reg [15:0] refresh_counter = 16'h0000;	// Number of clock cycles since last refresh (or during init count of refreshes done)

	// SDRAM Command control
	localparam COMMAND_NOP			= 4'b0111;
	localparam COMMAND_ACTIVE		= 4'b0011;
	localparam COMMAND_READ			= 4'b0101;
	localparam COMMAND_WRITE		= 4'b0100;
	localparam COMMAND_PRECHARGE	= 4'b0010;
	localparam COMMAND_REFRESH		= 4'b0001;
	localparam COMMAND_SET_MODE		= 4'b0000;
	
	// SDRAM Mode
	localparam WRITE_MODE = 1'b1;
	localparam ADDRESSING_MODE = 1'b0;
	localparam BURST_LENGTH = 3'b000;

	reg [3:0] sdram_command = COMMAND_NOP;
	assign {sdram_cs, sdram_ras, sdram_cas, sdram_we} = sdram_command;

	assign sdram_clk = clk;

	// Output Enable for data pins from controller to SDRAM
	reg sdram_data_oe = 1'b0;
	assign data_out = sdram_data_oe ? 8'h00 : sdram_data[7:0];
	assign sdram_data[15:8] = sdram_data_oe ? 8'h00 : 8'hZZ;
	assign sdram_data[7:0]  = sdram_data_oe ? data_in : 8'hZZ;
	
	initial ram_ready = 1'b0;

	always @(posedge clk) begin

		begin

			case (state)

				INIT: begin
				
					sdram_command	<= COMMAND_NOP;
					sdram_data_oe	<= 1'b0;
					sdram_cke       <= 1'b1;
					sdram_dqm 		<= 2'b11;
					
					delay_counter	<= INHIBIT_CYCLES;
					delay_state		<= INIT_PRECHARGE;
					state			<= DELAY;
					
				end
				
				INIT_PRECHARGE: begin
				
					sdram_command	<= COMMAND_NOP;
					sdram_addr[10]	<= 1'b1;
					sdram_command	<= COMMAND_PRECHARGE;
					
					delay_counter	<= PRECHARGE_CYCLES;
					delay_state		<= INIT_MODE;
					state			<= DELAY;
					
				end
				
				INIT_MODE: begin
				
					sdram_command	<= COMMAND_SET_MODE;
					sdram_bs		<= 2'b00;
					sdram_addr		<= { 3'b000, WRITE_MODE, 2'b00, CAS_LATENCY_MODE, ADDRESSING_MODE, BURST_LENGTH };				
					
					delay_counter	<= MODESET_CYCLES;
					delay_state		<= INIT_REFRESH;
					state			<= DELAY;
					
				end
				
				INIT_REFRESH: begin
				
					sdram_command   <= COMMAND_REFRESH;
					refresh_counter <= refresh_counter + 16'h1;					
					
					delay_counter	<= REFRESH_CYCLES;
					delay_state		<= (refresh_counter == INIT_REFRESHES) ? SYNC : INIT_REFRESH;
					state			<= DELAY;
					
				end
				
				SYNC: begin
				
					sdram_command   <= COMMAND_NOP;

					refresh_counter	<= 16'h1;
					sdram_dqm		<= 2'b00;

					if (bus_cycle == 5'h14) begin

						ram_ready <= 1'b1;
						state <= REFRESH;

					end
					
				end
				
				REFRESH: begin
				
					if (refresh_counter >= REFRESH_INTERVAL) begin
				
						sdram_command	<= COMMAND_REFRESH;
						refresh_counter	<= 0;
													
					end else begin 

						sdram_command   <= COMMAND_NOP;
						refresh_counter <= refresh_counter + 16'h1;

					end
				
					delay_counter	<= REFRESH_CYCLES - 16'h1;
					delay_state		<= ACTIVE;
					state 			<= DELAY;
					
				end
					
				ACTIVE: begin

					sdram_bs		<= address[23:22];
					sdram_addr		<= address[21:9];			

					if (!cs_n) begin
					
						sdram_command	<= COMMAND_ACTIVE;
						sdram_data_oe	<= ~read_write;

						delay_counter	<= ACTIVE_CYCLES - (read_write ? 16'd3 : 16'd2);
						delay_state		<= OPERATION;
						
					end else begin
					
						sdram_command   <= COMMAND_NOP;
						sdram_data_oe	<= 1'b0;

						delay_counter	<= 16'd10;	// TODO Do right math
						delay_state		<= REFRESH;
					
					end

					state <= DELAY;
					
				end
				
				
				OPERATION: begin
					
					sdram_command	<= (read_write) ? COMMAND_READ : COMMAND_WRITE;
					sdram_bs		<= 2'b00;
					sdram_addr		<= {4'b0010, address[8:0]};
					
					delay_counter	<= read_write ? 16'd4 : 16'd3;  // TODO Do right math
					delay_state		<= REFRESH;
					state			<= DELAY;
					
				end

				DELAY: begin
				
					sdram_command <= COMMAND_NOP;
					
					if (delay_counter > 0) begin

						delay_counter <= delay_counter - 16'h1;

					end else begin

						state <= delay_state;

					end
					
				end			

			endcase

		end

	end

endmodule