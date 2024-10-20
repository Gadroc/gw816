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
	// FPGA Core Board
	input  wire				clk_50,				// FPGA Core Module 50Mhz Clock
	output wire				led1,					// FPGA Core Module Led
	output wire				led2,					// FPGA Core Module Led
	input  wire				sw1,					// FPGA Core Module Button 1 (next to RAM chip)
	input  wire				sw2,					// FPGA Core Module Button 2 (Next to U8)

	// BUS Control Signals
	output wire 			phi2,					// System Clock Signal
	output wire 			reset_n,				// System Reset Signal
	input  wire				read_write,			// Bus RW Signal (High - Read, Low - Write)
	
	// CPU Interface
	input  wire				cpu_vda,				// CPU Valid Data Address Signal
	input  wire				cpu_vpa,				// CPU Valid Program Address Signal
	input  wire				cpu_vp_n,			// CPU Vector Pull
	input  wire [15:0]	cpu_addr_bus,		// CPU Address Bus
	inout  wire [7:0]		cpu_data_bus,		// CPU Data / Bank Address Bus
	output wire				cpu_irq_n,			// CPU IRQ Signal
	output wire				cpu_abort_n,		// CPU Abort Signal (Negative edge will abort current opcode)

	// Peripheral Bus
	output wire				per_phi2,			// Peripheral Bus Clock (Dev Board Only)
	output wire				per_reset_n,		// Peripheral Bus Reset Signal (Dev Board Only)
	output wire				per_read_write,	// Peripheral RW Signal (High - Read, Low - Write)
	inout  wire [7:0]		per_data_bus,		// Peripheral Data Bus
	output wire [5:0]		ext_per_addr_bus,	// Peripheral Address Bus (Dev Board Only)

	// Peripherial Bus Device Selection
	output wire				io_exp_n,			// Expansion Slot Select
	output wire				io_audio_n,			// Audio Controller Select
	output wire				io_smc_n,			// System Management Controller Select
	output wire				io_via_n,			// VIA Select (Note VIA is on CPU Bus not peripheral bus)

	// IRQ Signals
	input  wire				irq_exp_n,			// IRQ Signal from Expansion Slot
	input  wire				irq_audio_n,		// IRQ Singal from Audio Controller
	input  wire				irq_rtc_n,			// IRQ Signal from RTC Chip
	input  wire				irq_via_n,			// IRQ Signal from VIA Chip
	input  wire				irq_smc_uart1_n,	// IRQ Signal from SMC UART (Serail & Data Ports)
	input  wire				irq_smc_timer_n,	// IRQ Signal from SMC Timers
	input  wire				irq_smc_kbms_n,	// IRQ Signal from SMC Keyboard/Mouse Controller
	
	// Reset Request Line
	input  wire				reset_req_n,		// IRQ Signal from SMC UART (Serail & Data Ports)
	
	// Dev Board High Z Inputs
	input  wire				ps2_mse_clk,
	input  wire				ps2_mse_dat,

	// SD Card
	inout  wire				sd_dat0,				// SDCARD DAT0
	inout  wire				sd_dat1,				// SDCARD DAT1
	inout  wire				sd_dat2,				// SDCARD DAT2
	inout  wire				sd_dat3,				// SDCARD DAT3
	output wire				sd_clk,				// SDCARD Clock
	output wire				sd_cmd,				// SDCARD Command

	// VGA
	output wire [4:0]		vga_red,				// VGA Red Signal Level
	output wire [5:0]		vga_green,			// VGA Green Signal Level
	output wire [4:0]		vga_blue,			// VGA Blue Signal Level
	output wire				vga_h_sync,			// VGA H-Sync Signal
	output wire				vga_v_sync,			// VGA V-Sync Signal

	// SDRAM Chip (W9825G6KH-6)
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

	localparam IO_EXP_SEL		= 4'd1;
	localparam IO_AUDIO_SEL		= 4'd2;
	localparam IO_VIDEO_SEL		= 4'd3;
	localparam IO_IRQ_SEL		= 4'd4;
	localparam IO_SPI_SEL		= 4'd5;
	localparam IO_VIA_SEL		= 4'd6;
	localparam IO_SMC_SEL		= 4'd7;
	localparam IO_RAM_SEL		= 4'd8;
	localparam IO_VRAM_SEL		= 4'd9;
	localparam IO_MMU_SEL		= 4'd10;


	// ---------------------------------------------------------------------------------------------
	// Clock signals
	// ---------------------------------------------------------------------------------------------
	wire 				clk_locked;					// System PLL is locked and ready
	wire				clk;							// System Clock (166.67Mhz)
	wire				clk_shift;					// Fast shift clock for SPI (20Mhz)
	wire				clk_shift_slow;			// Slow shift clock for SPI (2Mhz)
	wire				clk_vga;						// VGA Pixel Clock (25.175Mhz)
	
	// We count 6ns cycles per phi2 phase.  This is resete to 0 on each phase change on phi2.
	// Used for timing of synchronus logic for settle time for phi2 based read/write operations.
	wire [11:0]		phi2_cycle;


	clock_generator cronous (
		.clk_50				(clk_50),
		.clk					(clk),
		.clk_phi2			(phi2),
		.phi2_cycle			(phi2_cycle),
		.clk_shift			(clk_shift),
		.clk_shift_slow	(clk_shift_slow),
		.clk_vga				(clk_vga),
		.clk_locked			(clk_locked)
	);


	// ---------------------------------------------------------------------------------------------
	// Data Bus Mux
	// ---------------------------------------------------------------------------------------------
	wire [7:0]		mmu_data_out;
	wire [7:0]		mmu_acl_data_out;
	wire [7:0]		irq_data_out;
	wire [7:0]		ram_data_out;
	wire [7:0]		video_data_out;
	wire [7:0]		spi_data_out;

	wire				io_video_n;
	wire				io_irq_n;
	wire				io_spi_n;
	wire				io_mmu_n;
	wire				ram_cs_n;
	wire				vram_cs_n;
	
	wire [7:0]		data_bus;

	data_bus_mux bus_mux (
		.read_write			(read_write),

		.output_bus			(data_bus),
		
		.io_video_n			(io_video_n),
		.io_irq_n			(io_irq_n),
		.io_spi_n			(io_spi_n),
		.io_mmu_n			(io_mmu_n),
		.ram_cs_n			(ram_cs_n),
		.vram_cs_n			(vram_cs_n),
		
		
		.cpu_data_bus		(cpu_data_bus),
		.per_data_bus		(per_data_bus),
		.irq_data_out		(irq_data_out),
		.spi_data_out		(spi_data_out),
		.video_data_out	(video_data_out),
		.ram_data_out		(ram_data_out),
		.mmu_data_out		(mmu_data_out)
	);


	// ---------------------------------------------------------------------------------------------
	// SDRAM Controller
	// ---------------------------------------------------------------------------------------------
	wire 			ram_ready;
	wire			bus_sync;
	
	sdram_controller memory_controller (
		.clk				(clk),
		.address			({ 1'b0, per_addr_bus }),
		.data_in 		(data_bus),
		.data_out		(ram_data_out),
		.read_write		(read_write),
		.cs_n				(ram_cs_n),
		.phi2				(phi2),
		.ram_ready  	(ram_ready),
		.sdram_addr		(sdram_addr),
		.sdram_bs		(sdram_bs),
		.sdram_data		(sdram_data),
		.sdram_cs		(sdram_cs_n),
		.sdram_ras		(sdram_ras_n),
		.sdram_cas		(sdram_cas_n),
		.sdram_we		(sdram_we_n),
		.sdram_dqm		(sdram_dqm),
		.sdram_clk		(sdram_clk),
		.sdram_cke		(sdram_cke)
	);
	


	// ---------------------------------------------------------------------------------------------
	// Bus Controller
	// ---------------------------------------------------------------------------------------------
	wire  [23:0]	per_addr_bus;
	wire				supervisor_mode;
	wire				write_enable;
	
	assign ext_per_addr_bus = per_addr_bus[5:0];
	
	bus_controller atlas (
		.clk					(clk),
		.reset_n				(reset_n),
	
		.phi2					(phi2),
		.phi2_cycle			(phi2_cycle),
		.bus_sync		   (bus_sync),
		.cpu_addr_bus		(cpu_addr_bus),
		.cpu_data_bus		(cpu_data_bus),
		.read_write			(read_write),
		.cpu_vda				(cpu_vda),
		.cpu_vpa				(cpu_vpa),
		.cpu_vp_n			(cpu_vp_n),
		.cpu_abort_n		(cpu_abort_n),
	
		.supervisor_mode	(supervisor_mode),

		.io_exp_n			(io_exp_n),
		.io_audio_n			(io_audio_n),
		.io_video_n			(io_video_n),
		.io_irq_n			(io_irq_n),
		.io_spi_n			(io_spi_n),
		.io_via_n			(io_via_n),
		.io_smc_n			(io_smc_n),
		.io_mmu_n			(io_mmu_n),		
		.ram_cs_n			(ram_cs_n),
		.vram_cs_n			(vram_cs_n),
		
	   .write_enable		(write_enable),
		.per_data_bus		(per_data_bus),
		.per_addr_bus		(per_addr_bus),
	
		.data_in				(data_bus),
		.data_out			(mmu_data_out)
	);
	

	// ---------------------------------------------------------------------------------------------
	// Interrupt Controller
	// ---------------------------------------------------------------------------------------------
	wire [7:0]  irq_src;
	
	assign irq_src[0] = irq_smc_kbms_n;
	assign irq_src[1] = irq_smc_timer_n;
	assign irq_src[2] = irq_smc_uart1_n;
	assign irq_src[3] = 1'b0;
	assign irq_src[4] = irq_rtc_n;
	assign irq_src[5] = irq_audio_n;
	assign irq_src[6] = irq_exp_n;
	assign irq_src[7] = irq_via_n;
	
	interrupt_controller irq (
		.clk					(clk),
		.reset_n				(reset_n),
		.cs_n					(io_irq_n),

		.phi2					(phi2),
		.write_enable		(write_enable),
		.address				(per_addr_bus[0]),
		
		.data_in				(data_bus),
		.data_out			(irq_data_out),

		.irq_sources_n		(irq_src),
		.irq_out_n			(cpu_irq_n)
	);


	// ---------------------------------------------------------------------------------------------
	// SPI Signals
	// ---------------------------------------------------------------------------------------------
	wire				spi_rtc_cs;
	wire				spi_sdcard_cs;
	wire				spi_clk;
	wire				spi_mosi;
	wire				spi_miso;


	// ---------------------------------------------------------------------------------------------
	// Reset Controller
	// ---------------------------------------------------------------------------------------------
	reset_controller janus (
		.clk				(clk),
		.phi2				(phi2),
		.phi2_cycle		(phi2_cycle),
		.reset_n			(reset_n),
		.clk_locked		(clk_locked),
		.modules_ready	(ram_ready),
		.reset_req  	(reset_req)
	);


	// ---------------------------------------------------------------------------------------------
	// Video Controller
	// ---------------------------------------------------------------------------------------------
	video_controller apollo (
	
		.clk				(clk),
		.clk_pix			(clk_vga),

		.address			(per_addr_bus[15:0]),
		.data_in			(data_bus),
		.data_out		(video_data_out),
	
		.phi2				(phi2),
		.phi2_cycle		(phi2_cycle),
		.read_write		(read_write),
		.reset_n			(reset_n),
		.cs_n				(io_video_n),
		.vram_cs_n		(vram_cs_n),
	
		.vga_red			(vga_red),
		.vga_green		(vga_green),
		.vga_blue		(vga_blue),
		.vga_h_sync		(vga_h_sync),
		.vga_v_sync		(vga_v_sync)
	);

	
	// ---------------------------------------------------------------------------------------------
	// Hardware Specific Config
	// 
	// Custom motherboard will have a single clock line going to all devices, freeing up 1 pin
	// Custom motherboard will have a single reset line going to all devices, freeing up 1 pin
	// Custom motherboard will have a single read write line going to all devices, freeing up 1 pin
	//
	// Dev Board does not have
	//  audio controller
	// ---------------------------------------------------------------------------------------------

	// Reset Request
	assign reset_req = !sw1 || !reset_req_n;

	
	// Peripheral Bus
	assign per_phi2 			= phi2;
	assign per_reset_n		= reset_n;
	assign per_read_write	= read_write;


	// SD Card
	assign sd_dat0	= spi_miso;
	assign sd_dat1	= 1'bZ;
	assign sd_dat2	= 1'bZ;
	assign sd_dat3	= spi_sdcard_cs;
	assign sd_clk	= spi_clk;
	assign sd_cmd	= spi_mosi;
	
	assign led1 = reset_n;
	assign led2 = ~supervisor_mode;
	
endmodule