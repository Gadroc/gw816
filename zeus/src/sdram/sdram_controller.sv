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

module sdram_controller #(
	INHIBIT_CYCLES    	= 16'd20001,		// Number of clk cycles for SDRAM inhibit during initialization
	INIT_REFRESHES			= 16'd8,				// Number of cycles to do refreshes before init is finished
	
	CAS_LATENCY_MODE  	= 3'b010,			// A6-A4 of mode select for cas latency
	CAS_LATENCY				= 16'd2,				// CAS Latency Cycles
	
	SETMODE_CYCLES    	= 16'd2,				// Number of clk cycles after SDRAM mode set (tRSC)
	PRECHARGE_CYCLES  	= 16'd3,  			// Number of clk cycles after SDRAM precharge till command (tRP)
	REFRESH_CYCLES    	= 16'd9,				// Number of clk cycles between SDRAM auto refresh (tRC)
	
	ACTIVATE_CYCLES     	= 16'd0,				// Number of clk cycles after SDRAM active command to precharge (tRAS)
	WRITE_CYCLES      	= 16'd2,				// Number of clk cycles after SDRAM auto-precharge write command before next active/refresh
	READ_CYCLES				= CAS_LATENCY-1,	// Number of clk cycles after SDRAM auto-precharge read command before next active/refresh;

	REFRESH_INTERVAL		= 16'd2000			// Number of clk cycles between activates/refreshes	
) (
	input  wire				wb_clk_i,			// Wishbone Bus Clock
	input  logic  [7:0]	wb_data_i,			// Wishbone Bus Data In
	output logic  [7:0]	wb_data_o,			// Wishbone Bus Data Out
	input  wire				wb_reset_i,			// Wishbone Bus Reset
	
	output wire				wb_ack_o,			// Wishbone Bus Ack
	input  wire  [24:0]	wb_addr_i,			// Wishbone Bus Address
	output wire				wb_stall_o,			// Wishbone Stall
	input  wire				wb_strobe_i,		// Wishbone Strobe / Transaction Valid
	input  wire				wb_write_i,			// Wishbone Write Enable
	
	output wire [12:0]	sdram_addr,			// SDRAM Address Bus
	output wire [1:0]		sdram_bs,			// SDRAM Bank Select
	inout  wire [15:0]	sdram_data,			// SDRAM Data Bus
	output wire				sdram_cs_n,			// SDRAM Chip Select
	output wire				sdram_ras_n,		// SDRAM Row Address Strobe
	output wire				sdram_cas_n,		// SDRAM Col Address Strobe
	output wire				sdram_we_n,			// SDRAM Write Enable
	output wire [1:0]		sdram_dqm,			// SDRAM Data Mask
	output wire				sdram_clk,			// SDRAM Clock
	output wire 			sdram_cke			// SDRAM Clock Enable
);

	// SDRAM Command control
	localparam COMMAND_NOP			= 4'b0111;
	localparam COMMAND_ACTIVATE	= 4'b0011;
	localparam COMMAND_READ			= 4'b0101;
	localparam COMMAND_WRITE		= 4'b0100;
	localparam COMMAND_PRECHARGE	= 4'b0010;
	localparam COMMAND_REFRESH		= 4'b0001;
	localparam COMMAND_SET_MODE	= 4'b0000;
	localparam COMMAND_INHIBIT    = 4'b1111;

	// SDRAM Mode
	localparam WRITE_MODE 			= 1'b1;
	localparam ADDRESSING_MODE 	= 1'b0;
	localparam BURST_LENGTH 		= 3'b000;

	wire [3:0] sdram_command;
	assign {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = sdram_command;
	
	assign sdram_clk = wb_clk_i;
	assign sdram_cke = 1'b1;	

	enum logic [10:0] { 
		INHIBIT = 11'd0, PRECHARGE = 11'd2, SETMODE = 11'd4, IDLE = 11'd8,
		REFRESH = 11'd16, ACTIVATE = 11'd32, READ = 11'd64, LATCH = 11'd128,
		WRITE = 11'd256, DELAY = 11'd512, ACK = 11'd1024	
	} state, next_state, delay_state;

	// Counters for SDRAM state machine
	logic  [4:0] init_refresh_counter = 5'h0;
	logic [15:0] refresh_counter = 16'h0;
	logic [15:0] state_counter = 16'h0;
	logic [16:0] delay_count = 16'h0;
	
	// Latch Transaction from Wishbone Bus
	logic [24:0] trx_addr;
	logic  [7:0] trx_data;
	logic 		 trx_write;
	
	// We can only handle one transaction at t
	assign wb_stall_o = (state != IDLE);
	assign wb_ack_o = (state == WRITE || state == ACK);
	
	// State transition conditions
	wire	inhibit_done		= (state_counter >= INHIBIT_CYCLES);
	wire 	init_done			= (init_refresh_counter == INIT_REFRESHES);
	wire	delay_done			= (state_counter == delay_count);
	wire	refresh_due			= (refresh_counter >= REFRESH_INTERVAL);
	wire	wb_trx_accepted	= (~wb_stall_o && wb_strobe_i);
		
	always_comb begin
	
		case (state)
	
			INHIBIT:		next_state = (inhibit_done) ? PRECHARGE : INHIBIT;
			PRECHARGE:	next_state = DELAY;
			SETMODE:		next_state = DELAY;
			REFRESH:		next_state = DELAY;
			IDLE: begin
				if (wb_trx_accepted)
					next_state = ACTIVATE;
				else if (refresh_due)
					next_state = REFRESH;
				else
					next_state = IDLE;
			end
			ACTIVATE:	next_state = DELAY;
			READ:			next_state = DELAY;
			LATCH:		next_state = ACK;
			WRITE:		next_state = DELAY;
			DELAY:		next_state = (delay_done) ? delay_state : DELAY;
			ACK:			next_state = IDLE;
			
		endcase
	end
	
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i) begin
			state <= INHIBIT;
		end
		
		else begin
			state <= next_state;
		end
			
			
	end
	
	always_ff @(posedge wb_clk_i) begin

		if (state != next_state || wb_reset_i)
			state_counter <= 16'h0000;
		else
			state_counter <= state_counter + 16'h0001;
		
	end
	
	always_ff @(posedge wb_clk_i) begin
	
		case (state)
		
			IDLE: begin
				if (wb_trx_accepted) begin
					trx_addr  <= wb_addr_i;
					trx_data  <= wb_data_i;
					trx_write <= wb_write_i;
				end
			end

			PRECHARGE: begin
				delay_state <= SETMODE;
				delay_count <= PRECHARGE_CYCLES;
			end
			
			SETMODE: begin
				delay_state <= REFRESH;
				delay_count <= SETMODE_CYCLES;
			end
			
			REFRESH: begin
				delay_state <= (init_done) ? IDLE : REFRESH;
				delay_count <= REFRESH_CYCLES;
			end

			ACTIVATE: begin
				delay_state <= (trx_write) ? WRITE : READ;
				delay_count <= ACTIVATE_CYCLES;
			end
			
			READ: begin
				delay_state	<= LATCH;
				delay_count <= READ_CYCLES;
			end
			
			LATCH: begin
				wb_data_o <= trx_addr[0] ? sdram_data[15:8] : sdram_data[7:0];
			end
		
			WRITE: begin
				delay_state	<= IDLE;
				delay_count	<= WRITE_CYCLES;
			end
			
		endcase	
	end
	
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i)
			init_refresh_counter <= '0;
			
		else if (state == REFRESH) begin
			refresh_counter <= '0;
			if (init_refresh_counter < INIT_REFRESHES)
				init_refresh_counter <= init_refresh_counter + 5'h1;
		end
		
		else
			refresh_counter <= refresh_counter + 16'h1;
	
	end

	always_comb begin
	
		if (state != IDLE && trx_write) begin
			sdram_data[15:8] =  trx_addr[0] ? trx_data : 8'h00 ;
			sdram_data[7:0]  =  trx_addr[0] ? 8'h00 : trx_data;
		end else
			sdram_data[15:0] = 16'hzzzz;
		
		
		case (state)
		
			INHIBIT: begin
				sdram_command	= COMMAND_INHIBIT;
				sdram_bs			= 2'b00;
				sdram_addr		= 13'b0000000000000;
				sdram_dqm 		= 2'b11;
			end
			
			PRECHARGE: begin
				sdram_command	= COMMAND_PRECHARGE;			
				sdram_bs			= 2'b00;
				sdram_addr		= 13'b0010000000000;
				sdram_dqm 		= 2'b00;
			end

			SETMODE: begin
				sdram_command	= COMMAND_SET_MODE;			
				sdram_bs			= 2'b00;
				sdram_addr		= { 3'b000, WRITE_MODE, 2'b00, CAS_LATENCY_MODE, ADDRESSING_MODE, BURST_LENGTH };
				sdram_dqm 		= 2'b00;
			end

			REFRESH: begin
				sdram_command	= COMMAND_REFRESH;
				sdram_bs			= 2'b00;
				sdram_addr		= 13'b0000000000000;
				sdram_dqm 		= 2'b00;			
			end

			ACTIVATE: begin
				sdram_command	= COMMAND_ACTIVATE;
				sdram_bs			= trx_addr[24:23];
				sdram_addr		= trx_addr[22:10];
				sdram_dqm 		= 2'b00;
			end


			READ: begin
				sdram_command	= COMMAND_READ;
				sdram_bs			= trx_addr[24:23];
				sdram_addr		= {4'b0010, trx_addr[9:1]};
				sdram_dqm 		= 2'b00;
			end

			WRITE: begin
				sdram_command	= COMMAND_WRITE;
				sdram_bs			= trx_addr[24:23];
				sdram_addr		= {4'b0010, trx_addr[9:1]};
				sdram_dqm = trx_addr[0] ? 2'b01 : 2'b10;
			end

			
			default: begin
				sdram_command	= COMMAND_NOP;				
				sdram_bs			= 2'b00;
				sdram_addr		= 13'b0000000000000;
				sdram_dqm 		= 2'b00;
			end
			
		endcase
		
	end
	
	
endmodule