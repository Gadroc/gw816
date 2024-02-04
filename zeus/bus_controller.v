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

module bus_controller (
	input  wire			clk,				// System Clock
	input  wire 		phi2,				// CPU Clock Signal
	input  wire 		read_write,			// CPU RW Signal (High - Read, Low - Write)
	input  wire [7:0]	device_select_n,	// IO Select Lines
	
	// External data buses
	inout  wire [7:0]	cpu_data_bus,		// CPU Data / Bank Address Bus
	inout  wire [7:0]	ext_data_bus,		// External Peripheral Data Bus
	output reg [7:0]	data_bus,			// Output data bus	
	
	// Internal data sources
	input  wire [7:0]	ram_data_out,		// Data comming from the memory controller
	input  wire [7:0]	spi_data_out,		// Data comming from the spi controller
	input  wire [7:0]	video_data_out,		// Data comming from the video controller
	input  wire [7:0]	irqcon_data_out		// Data comming from the IRQ controller
);

	// Device Select Values
	localparam exp_sel    = 8'b11111110;	// Expansion Slot
	localparam audio_sel  = 8'b11111101;	// Audio Controller
	localparam smc_sel    = 8'b11111011;	// System Management Controller
	localparam video_sel  = 8'b11110111;	// Video Controller
	localparam spi_sel    = 8'b11101111;	// SPI Controller (RTC & SDCARD)
	localparam irqcon_sel = 8'b11011111;	// IRQ Controller
	localparam ram_sel    = 8'b10111111;	// Memory Controller
	localparam vidram_sel = 8'b01111111;	// VRAM Controller
	
   // Assert data lines when appropriate
	assign cpu_data_bus = (phi2 && read_write)  ? data_bus : 8'bZ;
	assign ext_data_bus = (phi2 && !read_write) ? data_bus : 8'bZ;
		
	// Select which data should be presented on the bus
	always @(posedge clk) begin
	
		if (!read_write) begin

			data_bus <= cpu_data_bus;

		end else begin

			case (device_select_n)
				video_sel :	data_bus <= video_data_out;
				spi_sel   :	data_bus <= spi_data_out;
				irqcon_sel:	data_bus <= irqcon_data_out;
				ram_sel   :	data_bus <= ram_data_out;
				vidram_sel:	data_bus <= video_data_out;
				default   :	data_bus <= ext_data_bus;
			endcase

		end

	end

endmodule
