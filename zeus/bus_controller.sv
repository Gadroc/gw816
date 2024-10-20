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

module bus_controller
# (
	IO_EXP_SEL			= 4'd1,
	IO_AUDIO_SEL		= 4'd2,
	IO_VIDEO_SEL		= 4'd3,
	IO_IRQ_SEL			= 4'd4,
	IO_SPI_SEL			= 4'd5,
	IO_VIA_SEL			= 4'd6,
	IO_SMC_SEL			= 4'd7,
	IO_RAM_SEL			= 4'd8,
	IO_VRAM_SEL			= 4'd9,
	IO_MMU_SEL			= 4'd10
	
) (
	input  wire				clk,							// System Clock (6ns period)
	input  wire				reset_n,						// System Reset
	
	input  wire				phi2,							// CPU Clock
	input  wire  [11:0]	phi2_cycle,					// CPU Clock Cycle Counter
	input  wire  [15:0]	cpu_addr_bus,				// CPU Address Bus
	inout  wire  [7:0]	cpu_data_bus,				// CPU Data Bus
	input  wire				read_write,					// CPU Read Write Signal (Read High)
	input  wire       	cpu_vda,						// CPU Valid Data Address
	input  wire				cpu_vpa,						// CPU Valid Program Address
	input  wire				cpu_vp_n,					// CPU Vector Pull
	output wire				cpu_abort_n,				// CPU Abort Input
	
	output logic			supervisor_mode,			// System Supervisor Mode

	output wire				io_exp_n,					// Expansion Bus Select
	output wire				io_audio_n,					// Audio Controller Select
	output wire				io_video_n,					// Video Controller Select
	output wire				io_irq_n,					// IRQ Controller Select
	output wire				io_spi_n,					// SPI Controller Select
	output wire				io_via_n,					// VIA Select
	output wire				io_smc_n,					// SMC Select
	output wire				io_mmu_n,					// MMU Select
	output wire				ram_cs_n,					// RAM Select
	output wire				vram_cs_n,					// VRAM Select
	
	output wire				bus_sync,					// Pulse when bus config is valid
	output wire				write_enable,				// Write Enable Signal (valid when data from CPU is valid)
	inout  wire  [7:0]	per_data_bus,				// Peripheral Data Bus
	output logic [23:0]	per_addr_bus,				// RAM Address Bus
	
	input  wire  [7:0]	data_in,
	output reg   [7:0]   data_out
);

	//
	//
	// Internal Elements
	//
	//
	
	logic  [3:0]	device_select_i;			// Selected Device
	wire   [7:0]	active_seg_flags_i;		// Flags for the active memory segment
	wire   [7:0]	active_seg_asid_i;		// ASID for the active memory segment

	//
	//
	// Configuration Registers
	//
	//	
	
	logic [7:0]		active_asid_r;				// Currently active ASID

	logic				vram_disabled_r;			// VRAM Disabled Signal
	logic				user_mode_enabled_r;		// Signal to allow exit of supervisor mode
	logic [2:0]		abort_code_r;				// Abort reason code
	
	logic [11:0]	seg_zero_offset_r;		// Segment Zero relocation offset
	

	logic [11:0]	acl_seg_r;					// ACL Segment
	wire  [7:0]		acl_flags_r;				// ACL Page flags
	wire  [7:0]		acl_asid_r;					// ACL Page ASID
	
	
	//
	//
	// Aliases for address parts
	//
	//
	wire  [7:0]		bank = cpu_data_bus;
	wire  [15:0]	address = cpu_addr_bus;	
	wire  [12:0]	segment = {bank, cpu_addr_bus[15:12]};
	wire  [11:0]	active_segment_addr = per_addr_bus[23:12];
	
	
	//
	//
	// Configuration Memory
	//
	//
	
	wire	acl_flags_we	= !io_mmu_n && write_enable && cpu_addr_bus[2:0] == 4'h7;
	wire	acl_asid_we	=!io_mmu_n && write_enable && cpu_addr_bus[2:0] == 4'h6;
	
	// Configuration memroy for page flags
	dual_port_ram #(.DATA_WIDTH (8), .ADDR_WIDTH (12)) segment_flags (
		.clk		(clk),
		
		// Port A: ACL Configuration Registers
		.addr_a	(acl_seg_r),
		.data_a	(data_in),
		.q_a		(acl_flags_r),
		.we_a		(acl_flags_we),

		// Port B: Active Segement Configuration
		.addr_b	(active_segment_addr),
		.data_b	(8'h00),
		.q_b		(active_seg_flags_i),
		.we_b		(1'b0)
	);

	// Configuration memroy for page asids
	dual_port_ram #(.DATA_WIDTH (8), .ADDR_WIDTH (12)) page_config_asids (
		.clk		(clk),
		
		// Port A: ACL Configuration Registers
		.addr_a	(acl_seg_r),
		.data_a	(data_in),
		.q_a		(acl_asid_r),
		.we_a		(acl_asid_we),
		
		// Port B: Active Segement Configuration
		.addr_b	(active_segment_addr),
		.data_b	(8'h00),
		.q_b		(active_seg_asid_i),
		.we_b		(1'b0)
	);
	
	//
	//
	// CPU Bus Arbitration
	//
	//	

	assign cpu_data_bus = (phi2 && read_write)  ? data_in : 8'bZ;
	assign per_data_bus = (phi2 && !read_write) ? data_in : 8'bZ;	
	
	//
	//
	// Supervisor Mode Tracking
	//
	//
	assign supervisor_mode = 1;
	assign cpu_abort_n = 1;

	//
	//
	// Address Latch & Decode
	//
	//
	
	// Data is only on and after the 8th cycle count since of the phi2 clock (tMDS)
	assign write_enable = !read_write && phi2 && phi2_cycle >= 12'h8;

	// Latch address 5 cycles (approx 33ns) after falling edge of clock to account for tADS
	wire latch_address = reset_n && (cpu_vda || cpu_vpa) && (!phi2 && phi2_cycle == 4);
	
	assign bus_sync = (!phi2 && phi2_cycle == 5);

	// Reset address 1 cycle (approx 9ns) after falling edge of bus clock to account for tDHR/tDHW
	wire address_reset = !reset_n || (!phi2 && phi2_cycle == 1);
	
	
	always @(posedge clk) begin

		if (address_reset) begin
		
			per_addr_bus		<= 24'h000000;
			device_select_i	<= 0;

		end else begin

			if (latch_address) begin
				
				// Latch in ram address bus
				if (segment == 12'h000) begin
					per_addr_bus <= { seg_zero_offset_r, address[11:0] };
				end else begin
					per_addr_bus <= { bank, address };
				end
			
				// Decode device selection based on cpu data and addr busses.  Can not
				// use latched per_addr_bus as it will not be availble till next clock.
				// Device decode is also latched to enable wait states if we want later.
				if (bank == 8'h00) begin
					
					if (address >= 16'hFF00 && address <= 16'hFF1F) begin
					
						device_select_i <= IO_EXP_SEL;
						
					end else if (address >= 16'hFF60 && address <= 16'hFF7F) begin
						
						device_select_i <= IO_AUDIO_SEL;
					
					end else if (address >= 16'hFF80 && address <= 16'hFF9F) begin
					
						device_select_i <= IO_VIDEO_SEL;
					
					end else if (address >= 16'hFFA0 && address <= 16'hFFA3) begin
					
						device_select_i <= IO_IRQ_SEL;

					end else if (address >= 16'hFFA4 && address <= 16'hFFA7) begin
					
						device_select_i <= IO_SPI_SEL;
					
					end else if (address >= 16'hFFA8 && address <= 16'hFFAF) begin
					
						device_select_i <= IO_MMU_SEL;
					
					end else if (address >= 16'hFFB0 && address <= 16'hFFBF) begin
					
						device_select_i <= IO_VIA_SEL;
					
					end else if (address >= 16'hFFC0 && address <= 16'hFFFF) begin
					
						device_select_i <= IO_SMC_SEL;
					
					end else begin
					
						device_select_i <= IO_RAM_SEL;
					
					end
				
				end else if (!vram_disabled_r && bank >= 8'hfe) begin
					
					device_select_i <= IO_VRAM_SEL;
				
				end else begin
				
					device_select_i <= IO_RAM_SEL;
					
				end
				
			end
			
		end
		
	end
			
	always_comb begin
		io_exp_n		<= device_select_i != IO_EXP_SEL;
		io_audio_n	<= device_select_i != IO_AUDIO_SEL;
		io_video_n	<= device_select_i != IO_VIDEO_SEL;
		io_irq_n		<= device_select_i != IO_IRQ_SEL;
		io_spi_n		<= device_select_i != IO_SPI_SEL;
		io_via_n		<= device_select_i != IO_VIA_SEL;
		io_smc_n		<= device_select_i != IO_SMC_SEL;
		io_mmu_n		<= device_select_i != IO_MMU_SEL;
		ram_cs_n		<= device_select_i != IO_RAM_SEL;
		vram_cs_n	<= device_select_i != IO_VRAM_SEL;
	end

	// MMU Config Registers
	always @(posedge clk) begin

		if (!reset_n) begin

			active_asid_r			<= 8'h00;
			
			vram_disabled_r		<= 1'b0;
			user_mode_enabled_r	<= 1'b0;
			abort_code_r			<= 2'h0;
			
			seg_zero_offset_r		<= 12'h000;
			
			acl_seg_r				<= 12'h000;

		end else begin
	
			if (io_mmu_n && write_enable) begin
				
				case (cpu_addr_bus[2:0])
					4'h0 :	active_asid_r 				<= data_in;
					4'h1 :	begin
									vram_disabled_r		<= data_in[7];
									user_mode_enabled_r	<= data_in[6];
									abort_code_r			<= data_in[2:0];
								end
					4'h2 :	seg_zero_offset_r[7:0]	<= data_in;
					4'h3 :	seg_zero_offset_r[11:8]	<= data_in[3:0];
					4'h4 :   acl_seg_r[7:0]				<= data_in;
					4'h5 :	acl_seg_r[11:8] 			<= data_in[3:0];
				endcase
				
			end
				
		end
		
	end
	
	// MMU Config Register Output Mux
	always_comb begin
		case (cpu_addr_bus[2:0])
			4'h0 : data_out <= active_asid_r;
			4'h1 : data_out <= { vram_disabled_r, user_mode_enabled_r, 2'b00, abort_code_r };
			4'h2 : data_out <= seg_zero_offset_r[7:0];
			4'h3 : data_out <= { 4'h0, seg_zero_offset_r[11:8] };
			4'h4 : data_out <= acl_seg_r[7:0];
			4'h5 : data_out <= { 4'h0, acl_seg_r[11:8] };
			4'h6 : data_out <= acl_asid_r;
			4'h7 : data_out <= acl_flags_r;
		endcase
	end
	
endmodule