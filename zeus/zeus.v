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

module zeus (

	// FPGA Core Board Features
	input  wire			clk_50,			// FPGA Module 50Mhz Clock
	output wire			led,			// FPGA Module Led
	input  wire [1:0]	key,			// FPGA Module Buttons

	// CPU
	output wire 		phi2,			// CPU Clock Signal
	output wire 		reset_n,		// CPU Reset Signal
	input  wire 		read_write,		// CPU RW Signal (High - Read, Low - Write)
	input  wire 		vda,			// CPU Valid Data Address Signal
	input  wire 		vpa,			// CPU Valid Program Address Signal
	input  wire			vp_n,			// CPU Vector Pull
	inout  wire [7:0]	cpu_data_bus,	// CPU Data / Bank Address Bus
	output wire 		irq_n,			// CPU IRQ Signal
	output wire			abort_n,		// CPU Abort Signal (Negative edge will abort current opcode)
	input  wire [15:0]	cpu_addr_bus,	// CPU Address Bus

	// External Peripheral Bus
	inout  wire [7:0]	ext_data_bus,	// Peripheral Data Bus	
	output wire 		io_exp_n,		// Expansion Slot Select
	output wire			io_audio_n,		// Audio Controller Select
	output wire 		io_smc_n,		// System Management Controller Select
	
	// IRQ Controller
	input  wire			irq_exp_n,		// IRQ Signal from Expansion Slot
	input  wire			irq_audio_n,	// IRQ Singal from Audio Controller
	input  wire			irq_rtc_n,		// IRQ Signal from RTC Chip
	input  wire			irq_uart_n,		// IRQ Signal from SMC Uart
	input  wire			irq_timer_n,	// IRQ Signal from SMC Timers
	input  wire			irq_kbms_n,		// IRQ Signal from SMC Keyboard/Mouse Controller
	
	// SPI Bus
	input  wire			miso,			// SPI Master In Slave Out
	output wire			mosi,			// SPI Master Out Slave In
	output wire 		sclk,			// SPI Shift Clock
	output wire			ss_rtc_n,		// SPI RTC Slave Select
	output wire			ss_sdcard_n,	// SPI SDCard Slave Select

	// VGA Controller
	output wire [4:0]	vga_red,		// VGA Red Signal Level
	output wire [4:0]	vga_green,		// VGA Green Signal Level
	output wire [4:0]	vga_blue,		// VGA Blue Signal Level
	output wire			vga_h_sync,		// VGA H-Sync Signal
	output wire			vga_v_sync,		// VGA V-Sync Signal
	
	// Video Memory
	output wire			vga_mem_oe_n,	// VGA Memory Output Enable
	output wire			vga_mem_we_n,	// VGA Memory Write Enable
	output wire [18:0]	vga_mem_addr,	// VGA Memory Address Bus
	inout  wire [7:0]	vga_mem_data,	// VGA Memory Data Bus
	
	// SDRAM Chip (W9825G6KH-6)
	output wire [12:0]	sdram_addr,		// SDRAM Address Bus
	output wire [1:0]	sdram_bs,		// SDRAM Bank Select
	inout  wire [15:0]	sdram_data,		// SDRAM Data Bus
	output wire 		sdram_cs,		// SDRAM Chip Select
	output wire 		sdram_ras,		// SDRAM Row Address Strobe
	output wire 		sdram_cas,		// SDRAM Col Address Strobe
	output wire 		sdram_we,		// SDRAM Write Enable
	output wire [1:0]	sdram_dqm,		// SDRAM Data Mask
	output wire			sdram_clk,		// SDRAM Clock
	output wire 		sdram_cke		// SDRAM Clock Enable	
);

	// Signals for future use if I want to do a full MMU.
	// For now leave them in normal operation mode
	assign abort_n = 1'b1;

	// Light LED when CPU is not in reset
	assign led = ~reset_n;

	// ---------------------------------------------------------------------------------------------
	// Clock Generation & Sync Singals
	// ---------------------------------------------------------------------------------------------
	wire clk_gen_locked;
	wire clk_sys;			// System Clock (Must be 22x phi2 Bus Clock)
	wire clk_phi2;			// PHI2 Bus Clock
	wire clk_spi;			// SPI Shift Clock Base
	wire clk_pixel;			// VGA Pixel Clock
	
	clock clock_generator (
		.inclk0				(clk_50),
		.c0					(clk_phi2),
		.c1					(clk_sys),
		.c2					(clk_pixel),
		.c3					(clk_spi),
		.locked				(clk_gen_locked)
	);
	assign phi2 = clk_phi2;

	reg [1:0] phi2_detect = 2'b00;	// Edge dectet signals for phi2
	reg [4:0] bus_cycle;			// Cycle counter from 0-21 starting from first sys clock after phi2 falls
	
	always @(posedge clk_sys) begin

		phi2_detect <= { phi2_detect[0], phi2 };

		// Reset counter on phi2 clock fall
		if (phi2_detect == 2'b10) begin
			bus_cycle <= 5'h02;
		end else if (bus_cycle == 5'h15) begin
			bus_cycle <= 5'h00;
		end else begin
			bus_cycle <= bus_cycle + 5'h01;
		end

	end

	// ---------------------------------------------------------------------------------------------
	// Reset Controller
	// ---------------------------------------------------------------------------------------------
	wire ram_ready;		// Signal indicating the SDRAM system has finished initialization

	reset_controller reset (
		.clk				(clk_sys),
		.phi2				(clk_phi2),
		.reset_n			(reset_n),
		.ram_ready			(ram_ready),
		.reset_req_n		(key[0])
	);

	// ---------------------------------------------------------------------------------------------
	// Address Decode and Bus Control
	// ---------------------------------------------------------------------------------------------
	wire [7:0]  data_bus;
	wire [7:0]  device_select_n;
	
	// Internal device data bus out signals
	wire [7:0]	ram_data_out;
	wire [7:0]	irqcon_data_out;
	wire [7:0]	spi_data_out;
	wire [7:0]	video_data_out;	

	// External device select lines
	assign io_exp_n		= device_select_n[0];
	assign io_audio_n	= device_select_n[1];
	assign io_smc_n		= device_select_n[2];

	// Bus Controller Signals
	wire [7:0] bank;
	
	address_decoder decoder (
		.clk				(clk_sys),
		.bus_cycle			(bus_cycle),
		.reset_n			(reset_n),
		.vda				(vda),
		.vpa				(vpa),
		.cpu_data_bus		(cpu_data_bus),
		.address			(cpu_addr_bus),
		.bank				(bank),
		.device_select_n	(device_select_n)
	);
	
	// MUXs appropriate device signals to the CPU, and extracts bank address from CPU during low phi2
	bus_controller bus (
		.clk				(clk_sys),
		.phi2				(clk_phi2),
		.read_write			(read_write),
		.device_select_n	(device_select_n),
		.data_bus			(data_bus),
		.cpu_data_bus		(cpu_data_bus),
		.ext_data_bus		(ext_data_bus),
		.ram_data_out		(ram_data_out),
		.spi_data_out		(spi_data_out),
		.video_data_out		(video_data_out),
		.irqcon_data_out	(irqcon_data_out)
	);

	// ---------------------------------------------------------------------------------------------
	// IRQ Controller
	// ---------------------------------------------------------------------------------------------
	wire [7:0]  irq_src;
	
	assign irq_src[0] = irq_kbms_n;
	assign irq_src[1] = irq_timer_n;
	assign irq_src[2] = irq_uart_n;
	assign irq_src[3] = irq_rtc_n;
	assign irq_src[4] = irq_audio_n;
	assign irq_src[5] = irq_exp_n;
	
	irq_controller irq (
		.clk				(clk_sys),
		.cs_n				(device_select_n[6]),

		.bus_cycle			(bus_cycle),
		.address			(cpu_addr_bus[0]),
		.read_write			(read_write),
		.reset_n			(reset_n),
		.data_in			(data_bus),
		.data_out			(irqcon_data_out),

		.irq_sources_n		(irq_src),
		.irq_out_n			(irq_n)
	);

	// ---------------------------------------------------------------------------------------------
	// Memory Controller
	// ---------------------------------------------------------------------------------------------
	memory_controller ram (
		.clk				(clk_sys),
		.address			({bank, cpu_addr_bus}),
		.data_in 			(data_bus),
		.data_out			(ram_data_out),
		.bus_cycle			(bus_cycle),
		.read_write			(read_write),
		.reset_n			(reset_n),
		.cs_n				(device_select_n[6]),
		.ram_ready  		(ram_ready),
		.sdram_addr			(sdram_addr),
		.sdram_bs			(sdram_bs),
		.sdram_data			(sdram_data),
		.sdram_cs			(sdram_cs),
		.sdram_ras			(sdram_ras),
		.sdram_cas			(sdram_cas),
		.sdram_we			(sdram_we),
		.sdram_dqm			(sdram_dqm),
		.sdram_clk			(sdram_clk),
		.sdram_cke			(sdram_cke)
	);

	// ---------------------------------------------------------------------------------------------
	// SPI Bus Controller
	// ---------------------------------------------------------------------------------------------
	wire ss_exp_n;

	spi_controller spi (
		.clk				(clk_sys),
		.cs_n				(device_select_n[4]),
		.reset_n			(reset_n),
		.bus_cycle			(bus_cycle),
		.address			(cpu_addr_bus[1:0]),
		.read_write 		(read_write),
		.data_in			(data_bus),
		.data_out			(spi_data_out),
		.irq_n				(irq_src[6]),
		.clk_shift			(clk_spi),
		.miso				(miso),
		.mosi				(mosi),
		.sclk				(sclk),
		.ss_n				({ ss_exp_n, ss_rtc_n, ss_sdcard_n })
	);

	// ---------------------------------------------------------------------------------------------
	// Video Controller
	// ---------------------------------------------------------------------------------------------
	video_controller gfx (
		.address			({bank[2:0], cpu_addr_bus}),
		.data_in			(data_bus),
		.data_out			(video_data_out),
		.phi2				(clk_phi2),
		.read_write 		(read_write),
		.reset_n			(reset_n),
		.reg_cs_n			(device_select_n[3]),
		.vram_cs_n			(device_select_n[7]),
		.irq_n				(irq_src[7]),
		.pix_clk			(clk_pixel),
		.vga_red			(vga_red),
		.vga_green			(vga_green),
		.vga_blue			(vga_blue),
		.vga_h_sync			(vga_h_sync),
		.vga_v_sync			(vga_v_sync),
		.vga_mem_oe_n		(vga_mem_oe_n),
		.vga_mem_we_n		(vga_mem_we_n),
		.vga_mem_addr		(vga_mem_addr),
		.vga_mem_data		(vga_mem_data)
	);
	
endmodule