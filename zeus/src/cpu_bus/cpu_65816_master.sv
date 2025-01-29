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

module cpu_65816_master (
	input  wire				wb_clk_i,				// Wishbone Bus Clock
	input  wire	  [7:0]	wb_data_i,				// Wishboe Bus Data In
	output logic  [7:0]	wb_data_o,				// Wishboe Bus Data In
	input  wire				wb_reset_i,				// Wishbone Bus Reset
	
	input  wire				wb_ack_i,				// Wishbone Bus Ack
	output logic [23:0]	wb_addr_o,				// Wishbone Bus Address 
	output logic			wb_cycle_o,				// Wishbone Cycle
	input  wire				wb_stall_i,				// Wishbone Stall
	output logic			wb_strobe_o,			// Wishbone Strobe / Transaction Valid
	output logic			wb_write_o,				// Wishbone Write Enable
	
	input  logic			access_violation_i,	// Access violaotion has been detected
	input  logic			supervisor_mode_i,	// Superivosr mode
	
	// 65C816 CPU Bus
	input  wire				phi2,						// CPU Clock
	input  wire				cpu_vda,					// CPU Valid Data Address Signal
	input  wire				cpu_vpa,					// CPU Valid Program Address Signal
	input  wire  [15:0]	cpu_addr_bus,			// CPU Address Bus
	inout  logic  [7:0]	cpu_data_bus,			// CPU Data / Bank Address Bus
	input  wire				cpu_read_write,		// CPU Read/Write Signal
	output wire				cpu_abort_n,			// CPU Abort Signal (Negative edge will abort current opcode)
	output logic			cpu_halt_n,				// CPU Halt Signal (low will pause CPU to allow slow bus activity)
	output wire				cpu_reset_n				// CPU Reset Signal	
);	

	localparam RESET_PHI2_CYCLES = 4'd10;
	
	localparam SEP = 8'hE2;
	localparam PLP = 8'h28;
	localparam STP = 8'hDB;
	localparam WAI = 8'hCB;
	localparam XCE = 8'hFB;
	localparam SEI = 8'h78;
	localparam RTI = 8'h40;
	
	// ---------------------------------------------------------------------------------------------
	// Phi2 Cycle Timing
	// ---------------------------------------------------------------------------------------------
	wire  [4:0]	cycle_counter;
	logic [2:0] phi2_synchronizer;

	always_ff @(posedge wb_clk_i) begin
	
		phi2_synchronizer <= { phi2_synchronizer[1], phi2_synchronizer[0], phi2 };
		
	end
	
	wire cycle_reset = phi2_synchronizer[2] && !phi2_synchronizer[1];
	
	always_ff @(posedge wb_clk_i) begin
		
		if (cycle_reset)
			cycle_counter <= 5'h03;
		else if (cycle_counter == 5'h0f)
			cycle_counter <= 5'h0;
		else
			cycle_counter <= cycle_counter + 5'h01;
		
	end

	// ---------------------------------------------------------------------------------------------
	// Access Violation Handling
	// ---------------------------------------------------------------------------------------------
	always_ff @(posedge wb_clk_i) begin
	
		if (cycle_counter >= 5'h2 && cycle_counter <= 5'h6)
			cpu_abort_n <= '1;
		else if (access_violation_i)
			cpu_abort_n <= '0;
	
	end
	
	// ---------------------------------------------------------------------------------------------
	// 65C816 Bus to Wishbone BUS Adapter
	// ---------------------------------------------------------------------------------------------
	enum int unsigned {
		RESET			= 0,		// Hold CPU in reset for min number of cycles
		IDLE			= 2,		// Wait for CPU to start a read/write
		STROBE		= 4,		// Initiate Wishbone transaction
		WAIT			= 8,		// Wait for Wishbone transaction
		RELEASE		= 16		// Releasing CPU from Wait State
	} state;
	
	
	logic [$bits(RESET_PHI2_CYCLES)-1:0]	reset_cycle_count;
	logic	[7:0] read_data;
	
	wire phi2_start		= (cycle_counter == 5'h08);
	wire reset_done		= (reset_cycle_count >= RESET_PHI2_CYCLES && cycle_counter == 5'h0c);
	wire address_ready	= (cpu_reset_n && ( cpu_vda || cpu_vpa ) && cycle_counter == 5'h04);
	wire read_ready		= address_ready && cpu_read_write;
	wire write_ready		= (cpu_reset_n && ( cpu_vda || cpu_vpa) && !cpu_read_write && cycle_counter == 5'h0b);
	wire halt_start		= (cycle_counter == 5'h0d);	
	wire halt_release    = (phi2 && (cycle_counter < 5'h0d));

	wire wb_trx_accepted		= (wb_cycle_o && wb_strobe_o && !wb_stall_i);
	wire wb_trx_complete		= (wb_cycle_o && wb_ack_i);

	logic inhibit_interrupt_disable_r;
	
	// Hold CPU Reset pin high when we are note in reset state.
	assign cpu_reset_n = state != RESET;
	
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i) begin
			state <= RESET;
			wb_cycle_o	<= '0;
			wb_strobe_o	<= '0;
			wb_write_o	<= '0;
			wb_addr_o	<= '0;
			wb_data_o	<= '0;
			cpu_halt_n	<= '1;
			reset_cycle_count <= '0;
			inhibit_interrupt_disable_r <= '0;
		end
		
		else case(state)
		
			RESET: begin
			
				if (reset_done) 
					state <= IDLE;
				else if (phi2_start)
					reset_cycle_count = reset_cycle_count + 1;
					
			end
			
			IDLE: begin
				
				if (address_ready)
					wb_addr_o <= { cpu_data_bus, cpu_addr_bus };					
				
				if (read_ready) begin
					wb_cycle_o <= '1;
					wb_write_o <= '0;
					wb_strobe_o <= '1;
					state <= STROBE;
				end
				
				if (write_ready && cpu_abort_n) begin
					wb_data_o <= cpu_data_bus;
					wb_cycle_o <= '1;
					wb_write_o <= '1;
					wb_strobe_o <= '1;
					state <= STROBE;
				end					
			
			end
			
			STROBE: begin
			
				if (halt_start)
					cpu_halt_n <= '0;

				if (wb_trx_accepted) begin
					wb_strobe_o <= '0;
					state <= WAIT;
				end
								
			end
			
			WAIT: begin
			
				if (wb_trx_complete) begin
				
					wb_cycle_o <= '0;

					if (!wb_write_o) begin
					
						// Usermode SEP/PLP needs to prevent interrutpts being disabled through SEP/PLP
						if (!supervisor_mode_i && cpu_vpa && cpu_vda && (wb_data_i == SEP || wb_data_i == PLP))
							inhibit_interrupt_disable_r <= 1'b1; 
					
					
						// Prevent STP / WAI with NOP they are unsupported opcodes for the computer
						if (cpu_vpa && cpu_vda && (wb_data_i == STP || wb_data_i == WAI))
							read_data <= 8'hEA;
							
						// Replace on XCE / SEI / RTI and trigger when in user mode	
						// TODO this should trigger an abort back to supervisor code
						else if (!supervisor_mode_i && (wb_data_i == XCE || wb_data_i == SEI || wb_data_i == RTI))
							read_data <= 8'hEA;
							
						// If the last fetch was for usermode SEP/PLP remove bit 2 to prevent IRQs from being disabled
						else if (inhibit_interrupt_disable_r) begin
							read_data <= { wb_data_i[7:3], 1'b0, wb_data_i[1:0] };
							inhibit_interrupt_disable_r <= 1'b0;
						end
							
						else
							read_data <= wb_data_i;
					
					end
					
					state	<= (cpu_halt_n) ? IDLE : RELEASE;
					
				end
				
				else if (!wb_write_o && halt_start)
					cpu_halt_n <= '0;
			
			end
			
			RELEASE: begin
				
				if (halt_release) begin
				
					cpu_halt_n <= '1;
					state <= IDLE;
				
				end
			end
		
		endcase
	
	end
	
	always_comb begin
		cpu_data_bus = (phi2 && cpu_read_write) ? read_data : 8'bz;
	end

endmodule