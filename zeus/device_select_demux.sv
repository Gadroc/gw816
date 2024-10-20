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

module device_sel_demux
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
	input  wire				clk,
	input  wire  [3:0]	device_select,
	
	
	output reg				io_exp_n,				// Expansion Bus Select
	output reg				io_audio_n,				// Audio Controller Select
	output reg				io_via_n,				// VIA Select
	output reg				io_smc_n					// SMC Select
);

	always_comb begin
		io_exp_n		<= device_select != IO_EXP_SEL;
		io_audio_n	<= device_select != IO_AUDIO_SEL;
		io_via_n		<= device_select != IO_VIA_SEL;
		io_smc_n		<= device_select != IO_SMC_SEL;
	end

endmodule