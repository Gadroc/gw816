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

module data_bus_mux (
	input  wire					read_write,

	output wire  [7:0]		output_bus,
	
	input  wire					io_video_n,					// Video Controller Select
	input  wire					io_irq_n,					// IRQ Controller Select
	input  wire					io_spi_n,					// SPI Controller Select
	input  wire					io_mmu_n,					// MMU Select
	input  wire					ram_cs_n,					// RAM Select
	input  wire					vram_cs_n,					// VRAM Select
	
	input  wire  [7:0]		cpu_data_bus,
	input  wire  [7:0]		per_data_bus,
	input  wire  [7:0]		irq_data_out,
	input  wire  [7:0]		spi_data_out,
	input  wire  [7:0]		video_data_out,
	input  wire  [7:0]		ram_data_out,
	input  wire  [7:0]		mmu_data_out
);

	always_comb begin
		if (!read_write) begin
			output_bus <= cpu_data_bus;
		end else begin
			case ({io_video_n, io_irq_n, io_spi_n, io_mmu_n, ram_cs_n, vram_cs_n})
				6'b011111		: output_bus <= video_data_out;
				6'b101111		: output_bus <= irq_data_out;
				6'b110111		: output_bus <= spi_data_out;
				6'b111011		: output_bus <= mmu_data_out;
				6'b111101		: output_bus <= ram_data_out;
				6'b111110		: output_bus <= video_data_out;
				default			: output_bus <= per_data_bus;
			endcase
		end
	end	

endmodule