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

module vram_arbiter (
	input  logic			clk_i,
	
	output logic [14:0]	vram_addr_o,
	input  logic [31:0]	vram_data_i,
	
	input  logic [14:0]  vrf0_addr_i,
	input  logic			vrf0_strobe_i,
	output logic			vrf0_ack_o,

	input  logic [14:0]  vrf1_addr_i,
	input  logic			vrf1_strobe_i,
	output logic			vrf1_ack_o,

	input  logic [14:0]  vrf2_addr_i,
	input  logic			vrf2_strobe_i,
	output logic			vrf2_ack_o,

	input  logic [14:0]  vrf3_addr_i,
	input  logic			vrf3_strobe_i,
	output logic			vrf3_ack_o,
	
	output logic [31:0]	vrf_data_o
);

	logic [14:0] vram_addr_r;
	logic	vrf0_ack_next;
	logic	vrf1_ack_next;
	logic vrf2_ack_next;
	logic vrf3_ack_next;	
	

	assign vram_addr_o = vram_addr_r;
	assign vrf_data_o = vram_data_i;
	
	always_comb
	begin
		vram_addr_r = 15'h0000;
		vrf0_ack_next = 1'b0;
		vrf1_ack_next = 1'b0;
		vrf2_ack_next = 1'b0;
		vrf3_ack_next = 1'b0;

		if (vrf0_strobe_i) begin
			vram_addr_r = vrf0_addr_i;
			vrf0_ack_next = 1'b1;

		end else if (vrf1_strobe_i) begin
			vram_addr_r = vrf1_addr_i;
			vrf1_ack_next = 1'b1;

		end else if (vrf2_strobe_i) begin
			vram_addr_r = vrf2_addr_i;
			vrf2_ack_next = 1'b1;

		end else if (vrf3_strobe_i) begin
			vram_addr_r = vrf3_addr_i;
			vrf3_ack_next = 1'b1;
		end
	end
	
	always@(posedge clk_i)
	begin
		vrf0_ack_o <= vrf0_ack_next;
		vrf1_ack_o <= vrf1_ack_next;
		vrf2_ack_o <= vrf2_ack_next;
		vrf3_ack_o <= vrf3_ack_next;
	end	
	

endmodule