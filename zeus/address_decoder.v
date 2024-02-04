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

module address_decoder (
	input  wire			clk,			// System Clock
	input  wire [4:0]	bus_cycle,		// CPU Clock Signal
	input  wire 		reset_n,		// CPU Reset Signal
	input  wire 		vda,			// CPU Valid Data Address Signal
	input  wire 		vpa,			// CPU Valid Program Address Signal
	inout  wire [7:0]	cpu_data_bus,	// CPU Data / Bank Address Bus
	input  wire [15:0]	address,		// Address Bus
	output reg  [7:0]	bank,			// Peipheral Bus Latched Bank
	output reg  [7:0]	device_select_n	// IO Select Lines
);

	// Device Select Values
	localparam exp_sel    = 0;		// Expansion Slot
	localparam audio_sel  = 1;		// Audio Controller
	localparam smc_sel    = 2;		// System Management Controller
	localparam video_sel  = 3;		// Video Controller
	localparam spi_sel    = 4;		// SPI Controller (RTC & SDCARD)
	localparam irq_sel    = 5;		// IRQ Controller
	localparam ram_sel    = 6;		// Memory Controller
	localparam vidram_sel = 7;		// VRAM Controller

	// Indicates that the CPU has a valid address
	wire valid_address = reset_n && (vda || vpa) && (bus_cycle == 5'h5);
	wire address_reset = (bus_cycle == 5'h1);

	// Latch in bank address during phi1
	always @(posedge clk) begin
	
		if (address_reset) begin

			// Reset counter on phi1 edge and clear out latched in banks and device selects
			// this triggers approx 9ns (1 sys cycle in and sys is 90 off phase of phi2).
			device_select_n = 8'hFF;
			bank <= 8'h00;

		end else begin

			// Only latch in the defice select Bank and Device Select 33ns into phi1 cycle
			// prevent transients from pulling CS lines low, and makes sure the peripheral
			// bus has accurate bank and device select for full phi2 cycle.
			if (valid_address) begin

				bank <= cpu_data_bus;

				device_select_n[exp_sel]    <= (cpu_data_bus <= 8'h02 && address >= 16'hFF00 && address <= 16'hFF1F) ? 1'b0 : 1'b1;
				device_select_n[audio_sel]  <= (cpu_data_bus <= 8'h02 && address >= 16'hFF20 && address <= 16'hFF3F) ? 1'b0 : 1'b1;
				device_select_n[video_sel]  <= (cpu_data_bus <= 8'h02 && address >= 16'hFF40 && address <= 16'hFF5F) ? 1'b0 : 1'b1;
				device_select_n[spi_sel]    <= (cpu_data_bus <= 8'h02 && address >= 16'hFF60 && address <= 16'hFF6f) ? 1'b0 : 1'b1;
				device_select_n[irq_sel]    <= (cpu_data_bus <= 8'h02 && address >= 16'hFF70 && address <= 16'hFF7f) ? 1'b0 : 1'b1;
				device_select_n[smc_sel]    <= (cpu_data_bus <= 8'h02 && address >= 16'hFF80 && address <= 16'hFFFF) ? 1'b0 : 1'b1;
				device_select_n[vidram_sel] <= (cpu_data_bus >= 8'hf3) ? 1'b0 : 1'b1;
				device_select_n[ram_sel]    <= ((cpu_data_bus <= 8'h20 && address <= 16'hFEFF) || (cpu_data_bus >= 8'h03 && cpu_data_bus <= 8'hf2)) ? 1'b0 : 1'b1;

			end

		end
		
	end
	
endmodule
