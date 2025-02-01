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

module memory_management_unit (
	input  logic			wb_clk_i,				// Wishbone Bus Clock
	input  logic  [7:0]	wb_data_i,				// Wishbone Bus Data In
	output logic  [7:0]	wb_data_o,				// Wishbone Bus Data Out
	input  logic			wb_reset_i,				// Wishbone Bus Reset
	
	output logic 			wb_ack_o,				// Wishbone Bus Ack
	input  logic [23:0]	wb_addr_i,				// Wishbone Bus Address
	output logic			wb_stall_o,				// Wishbone Stall
	input  logic			wb_strobe_i,			// Wishbone Strobe / Transaction Valid
	input  logic			wb_write_i,				// Wishbone Write Enable
	
	input  logic			cpu_vp_i,
	input  logic			cpu_vpa_i,
	input  logic			cpu_vda_i,
	
	output logic			supervisor_mode_o,
	output logic			access_violation_o,
	
	output logic [24:0]  ram_addr_o,
	
	output logic			rom_disabled_o,		// Should ROM be disabled in favor of RAM
	output logic			vram_disabled_o		// Should VRAM be disabled in favor of RAM	
);

	logic [11:0] segzero_offset_r;
	logic [11:0] acl_segment_r;
	logic [7:0] active_asid_r;
	logic [2:0] abort_code_r;
	logic rom_disabled_r, vram_disabled_r, usermode_enable_r;

	logic [7:0] segment_acl_asid_r;
	logic [7:0] segment_acl_flags_r;
	
	logic [7:0] active_seg_asid_r;
	logic [7:0] active_seg_flags_r;

	wire [1:0] active_seg_access_mode = active_seg_flags_r[3:2];
	wire active_seg_no_exec = active_seg_flags_r[1];
	wire acitve_seg_write_protect = active_seg_flags_r[0];
	
	logic supervisor_mode_r, access_violation_r;

	assign rom_disabled_o		= rom_disabled_r;
	assign vram_disabled_o		= vram_disabled_r;
	assign access_violation_o  = access_violation_r;
	assign supervisor_mode_o	= supervisor_mode_r;
	
	assign ram_addr_o = (wb_addr_i[23:12] == 12'h000) ? { 1'b0, segzero_offset_r, wb_addr_i[11:0]} : { 1'b0, wb_addr_i };
	
	
	// ---------------------------------------------------------------------------------------------
	// Register Access
	// ---------------------------------------------------------------------------------------------
	assign wb_stall_o = '0;
	wire wb_trx_accepted = wb_strobe_i;
	
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i) begin
			segzero_offset_r = '0;
			active_asid_r = '0;
			rom_disabled_r = '0;
			usermode_enable_r = '0;
			vram_disabled_r = '0;
			acl_segment_r = '0;
		end
		
		else begin
			
			if (wb_trx_accepted) begin
			
				if (wb_write_i)
					case(wb_addr_i[3:0])
						4'h0: active_asid_r <= wb_data_i;
						4'h1: { vram_disabled_r, rom_disabled_r } <= { wb_data_i[7:6] };
						4'h2: segzero_offset_r[7:0] <= wb_data_i;
						4'h3: segzero_offset_r[11:8] <= wb_data_i[3:0];
						4'h4: acl_segment_r[7:0] <= wb_data_i;
						4'h5: acl_segment_r[11:8] <= wb_data_i[3:0];
						4'h8: usermode_enable_r <= wb_data_i[7];
						default: begin end
					endcase
				else
					case(wb_addr_i[3:0])
						4'h0: wb_data_o <= active_asid_r;
						4'h1: wb_data_o <= { vram_disabled_r, rom_disabled_r, 6'h0 };
						4'h2: wb_data_o <= segzero_offset_r[7:0];
						4'h3: wb_data_o <= { 4'h0, segzero_offset_r[11:8] };
						4'h4: wb_data_o <= acl_segment_r[7:0];
						4'h5: wb_data_o <= { 4'h0, acl_segment_r[11:8] };
						4'h6: wb_data_o <= segment_acl_asid_r;
						4'h7: wb_data_o <= segment_acl_flags_r;
						4'h8: wb_data_o <= { usermode_enable_r, 4'h0, abort_code_r };
						default: wb_data_o <= 8'h0;
					endcase
			end
			
		end
	
	end
	
	always_ff @(posedge wb_clk_i) begin
		wb_ack_o <= wb_strobe_i;
	end

	// ---------------------------------------------------------------------------------------------
	// ACL Config Ram
	// ---------------------------------------------------------------------------------------------
	
	// TODO Fix active seg so takes into account seg_zero remap		

	
	wire acl_asid_write = (wb_trx_accepted && wb_write_i && wb_addr_i[3:0] == 4'h6);
	acl_config_ram acl_asids (
		.clk_i			(wb_clk_i),
		.reg_write_i	(acl_asid_write),
		.reg_data_i		(wb_data_i),
		.reg_addr_i		(acl_segment_r),
		.reg_data_o		(segment_acl_asid_r),
		.active_addr_i	(wb_addr_i[23:12]),
		.active_data_o	(active_seg_asid_r)
	);
	
	wire acl_flags_write = (wb_trx_accepted && wb_write_i && wb_addr_i[3:0] == 4'h7);
	acl_config_ram acl_flags (
		.clk_i			(wb_clk_i),
		.reg_write_i	(acl_flags_write),
		.reg_data_i		(wb_data_i),
		.reg_addr_i		(acl_segment_r),
		.reg_data_o		(segment_acl_flags_r),
		.active_addr_i	(wb_addr_i[23:12]),
		.active_data_o	(active_seg_flags_r)
	);
	

	// ---------------------------------------------------------------------------------------------
	// Supervisor Tracking
	// ---------------------------------------------------------------------------------------------
	always_ff @(posedge wb_clk_i) begin
	
		// Anytime we reset or a vector is pulled then we should switch to supervisor mode
		if (wb_reset_i || cpu_vp_i)
			supervisor_mode_r <= '1;
		
		// If we fetch an opcode from non-supervisor mode segment, switch to user mode
		if (usermode_enable_r && cpu_vpa_i && cpu_vda_i && active_seg_access_mode != 2'h0)
			supervisor_mode_r <= '0;
		
	end
	
	// ---------------------------------------------------------------------------------------------
	// Memory Protection
	// ---------------------------------------------------------------------------------------------
	always_ff @(posedge wb_clk_i) begin
	
		if (wb_reset_i) begin
			abort_code_r = '0;
			access_violation_r <= 1'b0;
		end
		
		else if ((cpu_vpa_i || cpu_vda_i) && supervisor_mode_r == '0) begin
			
			// Segment Access Violation
			// Segment Access Mode = 0x00, Supervisor Mode Off
			// Segment Access Mode = 0x01, Active ASID != Segmetn ASID, Supervisor Off
			if  (active_seg_access_mode != 2'h0 
			 || (active_seg_access_mode != 2'h1 && (active_asid_r != active_seg_asid_r))) begin
				abort_code_r <= 3'h1;
				access_violation_r <= 1'b1;
			end
		
			// Segment Write Violation
			// Segment Write Protect On, wb_write_i, Supervisor Off
			else if (acitve_seg_write_protect &&  wb_write_i) begin
				abort_code_r <= 3'h2;
				access_violation_r <= 1'b1;
			end
			
			// Segment NoExec Violation
			// Segment Access Mode = 0x01, Active ASID != Segmetn ASID, Supervisor Off
			else if (active_seg_no_exec && cpu_vpa_i) begin
				abort_code_r <= 3'h3;
				access_violation_r <= 1'b1;
			end
			
		end
		
		else
			access_violation_r <= 1'b0;

	end
	
	
endmodule