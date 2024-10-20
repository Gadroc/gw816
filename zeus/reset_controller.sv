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

module reset_controller
# (
	RESET_PHI2_CYCLES = 10
) (
	input  wire				clk,
	input  wire				phi2,
	input  wire  [11:0]	phi2_cycle,
	
	output logic			reset_n,
	
	input  wire				clk_locked,
	input  wire				modules_ready,
	input  wire				reset_req
);

	initial reset_n = 0;
	logic [$bits(RESET_PHI2_CYCLES)-1:0]	reset_cycle_count;
	
	always @(posedge clk) begin
		
		if (!reset_req || !clk_locked || !modules_ready) begin
		
			reset_n <= 0;
			reset_cycle_count <= 0;
		
		end else if (!reset_n) begin
		
			if (reset_cycle_count == RESET_PHI2_CYCLES) begin
				
				if (!phi2 && phi2_cycle == 2) begin
					reset_n <= 1;
				end
			
			end else begin
			
				reset_n <= 0;
				reset_cycle_count <= reset_cycle_count + 1;
			
			end
		
		end

	end

endmodule