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

module acl_config_ram #(
	DATA_WIDTH = 8,
	ADDR_WIDTH = 12
) (
	input  clk_i,
	input  reg_write_i,
	input  [(DATA_WIDTH-1):0] reg_data_i,
	input  [(ADDR_WIDTH-1):0] reg_addr_i, active_addr_i,
	output [(DATA_WIDTH-1):0] reg_data_o, active_data_o
);

	logic [DATA_WIDTH-1:0] ram[2**ADDR_WIDTH-1:0];
	
	always @(posedge clk_i) begin
	
		if (reg_write_i) begin
			ram[reg_addr_i] <= reg_data_i;
			reg_data_o <= reg_data_i;
		end
		
		else begin
			reg_data_o <= ram[reg_addr_i];
		end
		
	end
	
	always @(posedge clk_i) begin
	
		active_data_o <= ram[active_addr_i];
	
	end

endmodule