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
module sdram_controller 
#(
	INHIBIT_CYCLES    	= 16'd33333,					// Number of clk cycles for SDRAM inhibit during initialization
	INIT_REFRESHES			= 16'd8,							// Number of cycles to do refreshes before init is finished
	
	CAS_LATENCY_MODE  	= 3'b011,						// A6-A4 of mode select for cas latency
	CAS_LATENCY				= 16'd3,							// CAS Latency Cycles
	
	MODESET_CYCLES    	= 16'd1,							// Number of clk cycles after SDRAM mode set (tRSC)
	PRECHARGE_CYCLES  	= 16'd2,  						// Number of clk cycles after SDRAM precharge till command (tRP)
	REFRESH_CYCLES    	= 16'd9,							// Number of clk cycles between SDRAM auto refresh (tRC)
	
	ACTIVATE_CYCLES     	= 16'd2,							// Number of clk cycles after SDRAM active command to precharge (tRAS)
	WRITE_DELAY_CYCLES   = 16'd3,							// Number of clk cycles to wait before data is ready for writing
	WRITE_CYCLES      	= 16'd4,							// Number of clk cycles after SDRAM auto-precharge write command before next active/refresh
	READ_CYCLES				= CAS_LATENCY+1,				// Number of clk cycles after SDRAM auto-precharge read command before next active/refresh;

	REFRESH_INTERVAL		= 10'd22							// Number of clk cycles between activates/refreshes
	
) (
	input  wire 			clk,					// Incomming 166.666 Mhz Clock

	// Bus Interface
	input  wire				phi2,					// Bus Cycle sync signal (sent when bus is stable for cycle)
	input  wire 			read_write,			// High when reading, low when writeing
	input  wire				cs_n,					// Low when this device is the target of the io request
	input  wire  [24:0]	address,				// Address of IO request
	input  wire  [7:0]	data_in,				// Peripheral Data Bus In
	output logic [7:0]	data_out,			// Peripheral Data Bus Out

	output logic			ram_ready,			// Signals when RAM initialization is complete

	output wire				sdram_clk,			// SDRAM Clock
	output wire  [12:0]	sdram_addr,			// SDRAM Address Bus
	output wire  [1:0]	sdram_bs,			// SDRAM Bank Select
	inout  wire  [15:0]	sdram_data,			// SDRAM Data Bus
	output wire				sdram_cs,			// SDRAM Chip Select
	output wire				sdram_ras,			// SDRAM Row Address Strobe
	output wire				sdram_cas,			// SDRAM Col Address Strobe
	output wire				sdram_we,			// SDRAM Write Enable
	output wire  [1:0]	sdram_dqm,			// SDRAM Data Mask
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

	enum bit [3:0] {INIT_NOP, INIT_CHARGE, SETMODE, INIT_REFRESH, IDLE, REFRESH, ACTIVATE, READ, WRITE} state, next_state = INIT_NOP;
	
	logic 			last_phi2;
	logic [9:0]		refresh_counter	= 10'h0;
	logic [15:0]	state_counter		= 16'h0000;

	wire  [3:0]		sdram_command;
	wire				sdram_data_oe;
	
	wire				init_delay_done;
	wire				init_refresh_done;
	wire				init_charge_done;
	wire				setmode_done;
	wire				refresh_done;
	wire				active_done;
	wire				read_done;
	wire				write_done;
	wire				idle_done;
	
	// Pass through clock to the SDRAM chip
	assign sdram_clk = clk;
	assign {sdram_cs, sdram_ras, sdram_cas, sdram_we} = sdram_command;

	// We never use power down SDRAM so clock is always enabled
	assign sdram_cke = 1'b1;
	
	// Setup our ram ready signal once we are out of initialization
	always_comb begin
		case (state)
			INIT_NOP:		ram_ready = 1'b0;
			INIT_CHARGE:	ram_ready = 1'b0;
			SETMODE:		 	ram_ready = 1'b0;
			INIT_REFRESH:	ram_ready = 1'b0;
			default:		 	ram_ready = 1'b1;
		endcase
	end
	
	assign init_delay_done		= (state_counter == INHIBIT_CYCLES);
	assign init_refresh_done	= (refresh_counter == INIT_REFRESHES && state_counter == REFRESH_CYCLES);
	assign init_charge_done		= (state_counter == PRECHARGE_CYCLES);
	assign setmode_done			= (state_counter == MODESET_CYCLES);
	assign refresh_done			= (state_counter == REFRESH_CYCLES);
	assign active_done			= (state_counter >= ACTIVATE_CYCLES + (read_write ? 16'd0 : WRITE_DELAY_CYCLES));
	assign read_done				= (state_counter == READ_CYCLES);
	assign write_done				= (state_counter == WRITE_CYCLES);
	assign idle_done				= (!last_phi2 && phi2);
	assign refresh_due		   = (refresh_counter >= REFRESH_INTERVAL);
		
	//
	// SDRAM State Machine
	//
	always_comb begin
	
		case (state)
	
			INIT_NOP: begin
			
				if (init_delay_done) begin
					next_state	= INIT_CHARGE;
				end else begin
					next_state	= INIT_NOP;
				end
				
			end
			
			INIT_CHARGE: begin
				
				if (init_charge_done) begin
					next_state	= SETMODE;
				end else begin
					next_state	= INIT_CHARGE;
				end
				
			end
			
			SETMODE : begin
			
				if (setmode_done) begin
					next_state	= INIT_REFRESH;
				end else begin
					next_state	= SETMODE;
				end
			
			end
			
			INIT_REFRESH : begin

				if (init_refresh_done) begin
					next_state	= IDLE;
				end else begin
					next_state  = INIT_REFRESH;
				end
			
			end
			
			IDLE : begin
			
				if (idle_done && !cs_n) begin
					next_state	= ACTIVATE;	
				end else if (idle_done && refresh_due) begin
					next_state = REFRESH;
				end else begin
					next_state	= IDLE;
				end
			
			end
			
			REFRESH : begin
				
				if (refresh_done) begin
					next_state	= IDLE;
				end else begin
					next_state	= REFRESH;
				end
				
			end
			
			ACTIVATE : begin
			
				if (active_done && !read_write) begin
						next_state = WRITE;
				end else if (active_done && read_write) begin
						next_state = READ;
				end else begin
					next_state = ACTIVATE;
				end				
			
			end
			
			READ : begin
			
				if (read_done) begin
					next_state = refresh_due ? REFRESH : IDLE;
				end else begin
					next_state = READ;
				end
				
			end

			WRITE : begin
			
				if (write_done) begin
					next_state = refresh_due ? REFRESH : IDLE;
				end else begin
					next_state = WRITE;
				end
				
			end
			
		endcase
	end

	always @(posedge clk) begin	
	
		state <= next_state;
		last_phi2 <= phi2;
		
	end
	
	always @(posedge clk) begin

		if (state != next_state) begin
			state_counter <= 16'h0000;
		end else if (state == INIT_REFRESH && state_counter == REFRESH_CYCLES) begin
			state_counter <= 16'h0000;
		end else begin
			state_counter <= state_counter + 16'h0001;
		end
		
	end
	
	always @(posedge clk) begin
		
		if ((state == REFRESH && state_counter == 16'h0000 ) | (state == INIT_NOP && next_state == INIT_REFRESH)) begin
			refresh_counter <= 10'h00;
		end else if (state == INIT_REFRESH && state_counter == 16'h0000 || ram_ready) begin
			refresh_counter <= refresh_counter + 10'h1;
		end
		
	end

	always @(posedge clk) begin		
	
		if (state == READ) begin
			data_out <= address[24] ? sdram_data[15:8] : sdram_data[7:0];
		end
		
	end

	always_comb begin
	
		if (state == INIT_NOP) begin
			sdram_dqm = 2'b11;
		end else begin
			sdram_dqm = address[24] ? 2'b01 : 2'b10;
		end
		
	end
	
	always_comb begin
		if (!cs_n && !read_write) begin
			// DQM will prevent saving of data to the wrong byte
			sdram_data[15:8] = data_in;
			sdram_data[7:0]  = data_in;
		end else begin
			sdram_data[15:0] = 16'hzzzz;
		end
		
	end
	
	always_comb begin
	
		if (state == INIT_NOP) begin
			sdram_command	= COMMAND_INHIBIT;
			sdram_bs			= 2'b00;
			sdram_addr		= 13'b0000000000000;

		end else if (state_counter == 16'h0000) begin
		
			case (state)
				
				INIT_CHARGE: begin
					sdram_command	= COMMAND_PRECHARGE;			
					sdram_bs			= 2'b00;
					sdram_addr		= 13'b0010000000000;
				end

				SETMODE: begin
					sdram_command	= COMMAND_SET_MODE;			
					sdram_bs			= 2'b00;
					sdram_addr		= { 3'b000, WRITE_MODE, 2'b00, CAS_LATENCY_MODE, ADDRESSING_MODE, BURST_LENGTH };
				end

				INIT_REFRESH: begin
					sdram_command	= COMMAND_REFRESH;
					sdram_bs			= 2'b00;
					sdram_addr		= 13'b0000000000000;
				end

				REFRESH: begin
					sdram_command	= COMMAND_REFRESH;
					sdram_bs			= 2'b00;
					sdram_addr		= 13'b0000000000000;
				end

				ACTIVATE: begin
					sdram_command	= COMMAND_ACTIVATE;
					sdram_bs			= address[23:22];
					sdram_addr		= address[21:9];
				end


				READ: begin
					sdram_command	= COMMAND_READ;
					sdram_bs			= address[23:22];
					sdram_addr		= {4'b0010, address[8:0]};
				end

				WRITE: begin
					sdram_command	= COMMAND_WRITE;
					sdram_bs			= address[23:22];
					sdram_addr		= {4'b0010, address[8:0]};
				end

				
				default: begin
					sdram_command	= COMMAND_NOP;				
					sdram_bs			= 2'b00;
					sdram_addr		= 13'b0000000000000;
				end
				
				
			endcase
			
		end else begin
			sdram_command	= COMMAND_NOP;
			sdram_bs			= 2'b00;
			sdram_addr		= 13'b0000000000000;		
		end
		
	end


endmodule