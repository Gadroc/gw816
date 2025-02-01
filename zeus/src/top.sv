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

module zeus (
	// FPGA Core Board
	input  wire				clk_50,					// FPGA Core Module 50Mhz Clock
	output wire				led1,						// FPGA Core Module Led (middle)
	output wire				led2,						// FPGA Core Module Led (outer next to U4)
	input  wire				sw1,						// FPGA Core Module Button 1 (middle)
	input  wire				sw2,						// FPGA Core Module Button 2 (inner)
	
	// Common Signals
	output wire				phi2,						// External Bus Clock
	output wire				reset_n,					// CPU Reset Signal
	input  wire				reset_req_n,			// External Reset Request
	input  wire				nmi_req_n,				// External NMI Request
	
	// 65C816 CPU Bus
	input  wire				cpu_vda,					// CPU Valid Data Address Signal
	input  wire				cpu_vpa,					// CPU Valid Program Address Signal
	input  wire				cpu_vp_n,				// CPU Vector Pull
	input  wire  [15:0]	cpu_addr_bus,			// CPU Address Bus
	inout  wire   [7:0]	cpu_data_bus,			// CPU Data / Bank Address Bus
	input  wire				cpu_read_write,		// CPU Read/Write Signal
	output wire				cpu_irq_n,				// CPU IRQ Signal
	output wire				cpu_abort_n,			// CPU Abort Signal (Negative edge will abort current opcode)
	output wire				cpu_halt_n,				// CPU Halt Signal (low will pause CPU to allow slow bus activity)
	
	// External Asynchronous Peripheral Bus
	output wire				io_reset_n,				// External Reset
	output wire  [15:0]	io_addr_bus,			// External Address Bus
	inout  wire   [7:0]	io_data_bus,			// External Data Bus
	output wire				io_read_req_n,			// External Bus Read Request
	output wire				io_write_req_n,		// External Bus Write Request
	input  wire				io_ack_n,				// External Bus Device Acknowledge
	output wire				io_exp1_n,				// Expansion IO Select
	output wire				io_exp2_n,				// Expansion IO Select
	output wire				io_audio_n,				// Audio Controller Select
	output wire				io_rom_n,				// ROM Select

	// SPI Peripheral Bus
	input  wire				spi_miso,				// SPI Master In / Slave Out 
	output wire				spi_mosi,				// SPI Master Out / Slave In
	output wire				spi_clk,					// SPI Clock
	output wire				spi_sdcard_cs,			// SPI SDCARD Select
	output wire				spi_rtc_cs,				// SPI RTC Chip Select
	
	// UART Port
	input  wire				uart_rx,					// UART Transmit
	output wire				uart_tx,					// UART Receive
	output wire				uart_rts,				// UART Request to Send
	input  wire				uart_cts,				// UART Clear to Send
	
	// PS2 Ports
	output wire				ps2_kbd_clk,			// PS2 Keyboard Clock
	inout  wire				ps2_kbd_dat,			// PS2 Keyboard Data
	output wire				ps2_mse_clk,			// PS2 Mouse Clock
	inout  wire				ps2_mse_dat,			// PS2 Mouse Data

	// VGA Port
	output wire [4:0]		vga_red,					// VGA Red Signal Level
	output wire [5:0]		vga_green,				// VGA Green Signal Level
	output wire [4:0]		vga_blue,				// VGA Blue Signal Level
	output wire				vga_h_sync,				// VGA H-Sync Signal
	output wire				vga_v_sync,				// VGA V-Sync Signal

	// SDRAM Chip (W9825G6KH-6)
	output wire [12:0]	sdram_addr,				// SDRAM Address Bus
	output wire [1:0]		sdram_bs,				// SDRAM Bank Select
	inout  wire [15:0]	sdram_data,				// SDRAM Data Bus
	output wire				sdram_cs_n,				// SDRAM Chip Select
	output wire				sdram_ras_n,			// SDRAM Row Address Strobe
	output wire				sdram_cas_n,			// SDRAM Col Address Strobe
	output wire				sdram_we_n,				// SDRAM Write Enable
	output wire [1:0]		sdram_dqm,				// SDRAM Data Mask
	output wire				sdram_clk,				// SDRAM Clock
	output wire 			sdram_cke				// SDRAM Clock Enable
);

	// ---------------------------------------------------------------------------------------------
	// FPGA Carrier Interface
	// ---------------------------------------------------------------------------------------------
	wire reset_req = !sw1 || !reset_req_n;
	wire nmi_req = !sw2;// || !nmi_req_n;
	
	assign led1 = reset_n;
	assign led2 = cpu_halt_n;

	
	// ---------------------------------------------------------------------------------------------
	// Wishbone Signals
	// ---------------------------------------------------------------------------------------------	
		
	// Shared Bus Signals
	wire			wb_clk;
	wire			wb_reset;
	wire [23:0] wb_addr;
	wire			wb_cycle;
	wire			wb_write;
	
	// Muxed Signals
	wire  [7:0] wbm_data_out;
	wire  [7:0] wbm_data_in;
	wire			wbm_strobe;
	wire			wbm_ack;
	wire			wbm_stall;

	
	// ---------------------------------------------------------------------------------------------
	// Wishbone SYSCON
	// ---------------------------------------------------------------------------------------------
	syscon janus (
		.clk50_i			(clk_50),
		.reset_req_i	(reset_req),
		.ext_phi2_o		(phi2),
		.wb_clk_o		(wb_clk),
		.wb_reset_o		(wb_reset)		
	);

	// ---------------------------------------------------------------------------------------------
	// Wishbone INTERCON
	// ---------------------------------------------------------------------------------------------
	
	// Address Decoding
	always_comb begin
		wbd_io_exp1_sel	= 1'b0;
		wbd_io_exp2_sel	= 1'b0;
		wbd_io_audio_sel	= 1'b0;
		wbd_video_sel		= 1'b0;
		wbd_ps2_sel			= 1'b0;
		wbd_uart_sel		= 1'b0;
		wbd_spi_sel			= 1'b0;
		wbd_io_rom_sel		= 1'b0;
		wbd_mmu_sel			= 1'b0;
		wbd_vram_sel		= 1'b0;
		wbd_ram_sel			= 1'b0;
		
	
		if      (wb_addr >= 24'h00BF00 && wb_addr <= 24'h00BF1F)								wbd_io_exp1_sel	= 1'b1;
		else if (wb_addr >= 24'h00BF20 && wb_addr <= 24'h00BF3F)								wbd_io_exp2_sel	= 1'b1;
		else if (wb_addr >= 24'h00BF40 && wb_addr <= 24'h00BF5F)								wbd_io_audio_sel	= 1'b1;	
		else if (wb_addr >= 24'h00BF60 && wb_addr <= 24'h00BF7F)								wbd_video_sel		= 1'b1;		
		else if (wb_addr >= 24'h00BF80 && wb_addr <= 24'h00BF9F)								wbd_ps2_sel			= 1'b1;
		else if (wb_addr >= 24'h00BFA0 && wb_addr <= 24'h00BFBF)								wbd_uart_sel		= 1'b1;
		else if (wb_addr >= 24'h00BFC0 && wb_addr <= 24'h00BFDF)								wbd_spi_sel			= 1'b1;
		else if (wb_addr >= 24'h00BFE0 && wb_addr <= 24'h00BFFF)								wbd_mmu_sel			= 1'b1;
		else if (!rom_disabled && !wb_write
		         && wb_addr >= 24'h00C000 && wb_addr <= 24'h01BFFF)							wbd_io_rom_sel		= 1'b1;
		else if (!vram_disabled && wb_addr >= 24'hfe0000 && wb_addr <= 24'hffffff)		wbd_vram_sel		= 1'b1;
		else 																									wbd_ram_sel			= 1'b1;
		
	end
	
	always_comb begin
		wbm_stall	= '0;
		wbm_ack		= '0;
		wbm_data_in	= '0;

		wbd_io_strobe		= '0;
		wbd_io_data_in		= '0;
		wbd_video_strobe	= '0;
		wbd_video_data_in	= '0;		
		wbd_ps2_strobe		= '0;
		wbd_ps2_data_in	= '0;
		wbd_uart_strobe	= '0;
		wbd_uart_data_in	= '0;
		wbd_spi_strobe		= '0;
		wbd_spi_data_in	= '0;
		wbd_mmu_strobe		= '0;
		wbd_mmu_data_in	= '0;
		wbd_vram_strobe	= '0;
		wbd_vram_data_in	= '0;
		wbd_ram_strobe		= '0;
		wbd_ram_data_in	= '0;
			
		if (wbd_io_exp1_sel || wbd_io_exp2_sel || wbd_io_audio_sel || wbd_io_rom_sel) begin
			wbm_stall = wbd_io_stall;
			wbm_ack = wbd_io_ack;
			wbm_data_in = wbd_io_data_out;
			
			wbd_io_strobe = wbm_strobe;
			wbd_io_data_in = wbm_data_out;
		end
		
		else if (wbd_video_sel) begin
			wbm_stall = wbd_video_stall;
			wbm_ack = wbd_video_ack;
			wbm_data_in = wbd_video_data_out;
			
			wbd_video_strobe = wbm_strobe;
			wbd_video_data_in = wbm_data_out;		
		end
				
		else if (wbd_ps2_sel) begin
			wbm_stall = wbd_ps2_stall;
			wbm_ack = wbd_ps2_ack;
			wbm_data_in = wbd_ps2_data_out;
			
			wbd_ps2_strobe = wbm_strobe;
			wbd_ps2_data_in = wbm_data_out;				
		end

		else if (wbd_uart_sel) begin
			wbm_stall = wbd_uart_stall;
			wbm_ack = wbd_uart_ack;
			wbm_data_in = wbd_uart_data_out;
			
			wbd_uart_strobe = wbm_strobe;
			wbd_uart_data_in = wbm_data_out;		
		end

		else if (wbd_spi_sel) begin
			wbm_stall = wbd_spi_stall;
			wbm_ack = wbd_spi_ack;
			wbm_data_in = wbd_spi_data_out;
			
			wbd_spi_strobe = wbm_strobe;
			wbd_spi_data_in = wbm_data_out;			
		end
		
		else if (wbd_mmu_sel) begin
			wbm_stall = wbd_mmu_stall;
			wbm_ack = wbd_mmu_ack;
			wbm_data_in = wbd_mmu_data_out;
			
			wbd_mmu_strobe = wbm_strobe;
			wbd_mmu_data_in = wbm_data_out;			
		end

		else if (wbd_vram_sel) begin
			wbm_stall = wbd_vram_stall;
			wbm_ack = wbd_vram_ack;
			wbm_data_in = wbd_vram_data_out;
			
			wbd_vram_strobe = wbm_strobe;
			wbd_vram_data_in = wbm_data_out;			
		end

		else if (wbd_ram_sel) begin
			wbm_stall = wbd_ram_stall;
			wbm_ack = wbd_ram_ack;
			wbm_data_in = wbd_ram_data_out;
			
			wbd_ram_strobe = wbm_strobe;
			wbd_ram_data_in = wbm_data_out;			
		end
		
	end
		
	// ---------------------------------------------------------------------------------------------
	// CPU Bus
	// ---------------------------------------------------------------------------------------------

	cpu_65816_master cpu_bus_master (
		.wb_clk_i				(wb_clk),
		.wb_data_i				(wbm_data_in),
		.wb_data_o				(wbm_data_out),
		.wb_reset_i				(wb_reset),
		
		.wb_ack_i				(wbm_ack),
		.wb_addr_o				(wb_addr),
		.wb_cycle_o				(wb_cycle),
		.wb_stall_i				(wbm_stall),
		.wb_strobe_o			(wbm_strobe),
		.wb_write_o				(wb_write),
		
		.supervisor_mode_i	(supervisor_mode),
		.access_violation_i	(access_violation),
		
		.phi2						(phi2),
		.cpu_vda					(cpu_vda),
		.cpu_vpa					(cpu_vpa),
		.cpu_addr_bus			(cpu_addr_bus),
		.cpu_data_bus			(cpu_data_bus),
		.cpu_read_write		(cpu_read_write),
		.cpu_abort_n			(cpu_abort_n),
		.cpu_halt_n				(cpu_halt_n),
		.cpu_reset_n			(reset_n)
	);
	
	assign cpu_irq_n = ~wbd_uart_irq;
	
	
	// ---------------------------------------------------------------------------------------------
	// Memory Management Unit
	// ---------------------------------------------------------------------------------------------	
	wire			wbd_mmu_sel;
	wire			wbd_mmu_strobe;
	wire			wbd_mmu_ack;
	wire			wbd_mmu_stall;
	wire [7:0]	wbd_mmu_data_in;
	wire [7:0]	wbd_mmu_data_out;	
	wire rom_disabled, vram_disabled;
	wire access_violation, supervisor_mode;
	
	memory_management_unit mmu (
		.wb_clk_i				(wb_clk),
		.wb_data_i				(wbd_mmu_data_in),
		.wb_data_o				(wbd_mmu_data_out),
		.wb_reset_i				(wb_reset),
		
		.wb_ack_o				(wbd_mmu_ack),
		.wb_addr_i				(wb_addr),
		.wb_stall_o				(wbd_mmu_stall),
		.wb_strobe_i			(wbd_mmu_strobe),
		.wb_write_i				(wb_write),

		.cpu_vp_i				(~cpu_vp_n),
		.cpu_vpa_i				(cpu_vpa),
		.cpu_vda_i				(cpu_vda),
		
		.supervisor_mode_o	(supervisor_mode),
		.access_violation_o	(access_violation),
		
		.ram_addr_o				(ram_addr),
		
		.rom_disabled_o		(rom_disabled),
		.vram_disabled_o		(vram_disabled)
	);
	
	// ---------------------------------------------------------------------------------------------
	// External IO Bus Controller
	// ---------------------------------------------------------------------------------------------
	wire			wbd_io_rom_sel;
	wire			wbd_io_audio_sel;
	wire			wbd_io_exp1_sel;
	wire			wbd_io_exp2_sel;
	
	wire			wbd_io_strobe;
	wire			wbd_io_ack;
	wire			wbd_io_stall;
	wire	[7:0]	wbd_io_data_in;
	wire  [7:0]	wbd_io_data_out;
	
	wire [15:0] rom_addr;
	wire			io_write_req;
	wire			io_read_req;
	
	wb_async_client_bridge #( .ADDR_BITS (5) ) io_bus (
		.wb_clk_i				(wb_clk),
		.wb_data_i				(wbd_io_data_in),
		.wb_data_o				(wbd_io_data_out),
		.wb_reset_i				(wb_reset),
		
		.wb_ack_o				(wbd_io_ack),
		.wb_addr_i				(wb_addr[4:0]),
		.wb_stall_o				(wbd_io_stall),
		.wb_strobe_i			(wbd_io_strobe),
		.wb_write_i				(wb_write),
		
		.read_only_i			(wbd_io_rom_sel),
		
		.ab_addr_o				(io_addr_bus[4:0]),
		.ab_data_io				(io_data_bus),
		.ab_write_req_o		(io_write_req),
		.ab_read_req_o			(io_read_req),
		.ab_ack_i				(~io_ack_n)
	);
	
	// Map right ROM addr into 00C000 - 01BFFF
	// Bits above 16 are already filtered 
	// ---------------------------------------
	//  Inputs Bits   Desired    Calculations
	//  -----------   -------    ------------
	//  16 15 14       15 14     15^14 ~14
	//   0  1  1        0  0       0     0
	//   1  0  0        0  1       0     1
	//   1  0  1        1  0       1     0
	//   1  1  0        1  1       1     1
	// ---------------------------------------
	assign io_addr_bus[15:5]	= wbd_io_rom_sel ? { wb_addr[15]^wb_addr[14], ~wb_addr[14], wb_addr[13:5] } : '0;

	assign io_write_req_n	= ~io_write_req;
	assign io_read_req_n		= ~io_read_req;
	assign io_exp1_n			= ~wbd_io_exp1_sel;
	assign io_exp2_n			= ~wbd_io_exp2_sel;
	assign io_audio_n			= ~wbd_io_audio_sel;
	assign io_rom_n			= ~wbd_io_rom_sel;
	assign io_reset_n			= ~wb_reset;
	
	// ---------------------------------------------------------------------------------------------
	// SDRAM Memory Controller
	// ---------------------------------------------------------------------------------------------
	wire			wbd_ram_sel;
	wire			wbd_ram_strobe;
	wire			wbd_ram_ack;
	wire			wbd_ram_stall;
	wire	[7:0]	wbd_ram_data_in;
	wire  [7:0]	wbd_ram_data_out;
	wire [24:0] ram_addr;

	sdram_controller mnemosyne (
		.wb_clk_i		(wb_clk),
		.wb_data_i		(wbd_ram_data_in),
		.wb_data_o		(wbd_ram_data_out),
		.wb_reset_i		(wb_reset),
		
		.wb_ack_o		(wbd_ram_ack),
		.wb_addr_i		(ram_addr),
		.wb_stall_o		(wbd_ram_stall),
		.wb_strobe_i	(wbd_ram_strobe),
		.wb_write_i		(wb_write),		
		
		.sdram_addr		(sdram_addr),
		.sdram_bs		(sdram_bs),
		.sdram_data		(sdram_data),
		.sdram_cs_n		(sdram_cs_n),
		.sdram_ras_n	(sdram_ras_n),
		.sdram_cas_n	(sdram_cas_n),
		.sdram_we_n		(sdram_we_n),
		.sdram_dqm		(sdram_dqm),
		.sdram_clk		(sdram_clk),
		.sdram_cke		(sdram_cke)
	);
	
	
	// ---------------------------------------------------------------------------------------------
	// Video Display Contoller
	// ---------------------------------------------------------------------------------------------
	wire			wbd_vram_sel;
	wire			wbd_vram_strobe;
	wire			wbd_vram_ack;
	wire			wbd_vram_stall;
	wire	[7:0]	wbd_vram_data_in;
	wire  [7:0]	wbd_vram_data_out;
	
	wire [14:0] vid_vram_addr;
	wire [31:0] vid_vram_out;
	
	vram_controller vram (
		.wb_clk_i		(wb_clk),
		.wb_data_i		(wbd_vram_data_in),
		.wb_data_o		(wbd_vram_data_out),
		.wb_reset_i		(wb_reset),
		
		.wb_ack_o		(wbd_vram_ack),
		.wb_addr_i		(wb_addr[16:0]),
		.wb_stall_o		(wbd_vram_stall),
		.wb_strobe_i	(wbd_vram_strobe),
		.wb_write_i		(wb_write),
		
		.vram_addr_i	(vid_vram_addr),
		.vram_data_o	(vid_vram_out)
		
	);
	
	wire			wbd_video_sel;
	wire			wbd_video_strobe;
	wire			wbd_video_ack;
	wire			wbd_video_stall;
	wire	[7:0]	wbd_video_data_in;
	wire  [7:0]	wbd_video_data_out;			
	
	video_controller apollo (
		.clk50_i			(clk_50),
		
		.wb_clk_i		(wb_clk),
		.wb_data_i		(wbd_video_data_in),
		.wb_data_o		(wbd_video_data_out),
		.wb_reset_i		(wb_reset),
		
		.wb_ack_o		(wbd_video_ack),
		.wb_addr_i		(ram_addr[4:0]),
		.wb_stall_o		(wbd_video_stall),
		.wb_strobe_i	(wbd_video_strobe),
		.wb_write_i		(wb_write),
		
		.vram_addr_o	(vid_vram_addr),
		.vram_data_i	(vid_vram_out),

		.vga_red			(vga_red),
		.vga_green		(vga_green),
		.vga_blue		(vga_blue),
		.vga_h_sync		(vga_h_sync),
		.vga_v_sync		(vga_v_sync)
	);

	
	// ---------------------------------------------------------------------------------------------
	// Keyboard/Mouse Controller
	// ---------------------------------------------------------------------------------------------
	wire			wbd_ps2_sel;
	wire			wbd_ps2_strobe;
	wire			wbd_ps2_ack;
	wire			wbd_ps2_stall;	
	wire	[7:0]	wbd_ps2_data_in;
	wire  [7:0]	wbd_ps2_data_out;
	
	ps2_controller keyboard (
		.wb_clk_i		(wb_clk),
		.wb_data_i		(wbd_ps2_data_in),
		.wb_data_o		(wbd_ps2_data_out),
		.wb_reset_i		(wb_reset),
		
		.wb_ack_o		(wbd_ps2_ack),
		.wb_addr_i		(wb_addr[4:0]),
		.wb_stall_o		(wbd_ps2_stall),
		.wb_strobe_i	(wbd_ps2_strobe),
		.wb_write_i		(wb_write),	

		.kbd_clk			(ps2_kbd_clk),
		.kbd_dat			(ps2_kbd_dat),
		.mse_clk			(ps2_mse_clk),
		.mse_dat			(ps2_mse_dat)
	);
	
	
	// ---------------------------------------------------------------------------------------------
	// Serial UART Controller
	// ---------------------------------------------------------------------------------------------
	wire			wbd_uart_sel;
	wire			wbd_uart_strobe;
	wire			wbd_uart_ack;
	wire			wbd_uart_stall;	
	wire	[7:0]	wbd_uart_data_in;
	wire  [7:0]	wbd_uart_data_out;
	wire			wbd_uart_irq;
	
	uart_controller uart (
		.wb_clk_i		(wb_clk),
		.wb_data_i		(wbd_uart_data_in),
		.wb_data_o		(wbd_uart_data_out),
		.wb_reset_i		(wb_reset),
		
		.wb_ack_o		(wbd_uart_ack),
		.wb_addr_i		(wb_addr[4:0]),
		.wb_stall_o		(wbd_uart_stall),
		.wb_strobe_i	(wbd_uart_strobe),
		.wb_write_i		(wb_write),
		
		.int_req_o		(wbd_uart_irq),
		
		.uart_tx			(uart_tx),
		.uart_rx			(uart_rx),
		.uart_rts		(uart_rts),
		.uart_cts		(uart_cts)
	);
	
	
	// ---------------------------------------------------------------------------------------------
	// SPI Controller
	// ---------------------------------------------------------------------------------------------
	wire			wbd_spi_sel;
	wire			wbd_spi_strobe;
	wire			wbd_spi_ack;
	wire			wbd_spi_stall;	
	wire	[7:0]	wbd_spi_data_in;
	wire  [7:0]	wbd_spi_data_out;
	
	spi_controller cadmus (
		.wb_clk_i			(wb_clk),
		.wb_data_i			(wbd_spi_data_in),
		.wb_data_o			(wbd_spi_data_out),
		.wb_reset_i			(wb_reset),
		
		.wb_ack_o			(wbd_spi_ack),
		.wb_addr_i			(wb_addr[4:0]),
		.wb_stall_o			(wbd_spi_stall),
		.wb_strobe_i		(wbd_spi_strobe),
		.wb_write_i			(wb_write),		
		
		.spi_miso			(spi_miso),
		.spi_mosi			(spi_mosi),
		.spi_clk				(spi_clk),
		.spi_sdcard_cs		(spi_sdcard_cs),
		.spi_rtc_cs			(spi_rtc_cs)
	);
	
endmodule