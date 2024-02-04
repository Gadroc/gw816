`timescale 1ns/1ps 

module hermes(
	input  wire phi2,						// CPU Clock Signal
	input  wire reset_n,					// CPU Reset Signal
	input  wire read_write,				// CPU RW Signal (High - Read, Low - Write)
	input  wire vda,						// CPU Valid Data Address Signal
	input  wire vpa,						// CPU Valid Program Address Signal
	
	output reg  [7:0]  bank_address, // Bank Address Latchg
	input  wire [15:0] address,		// Address Bus
	inout  wire [7:0]  dba,				// CPU Data / Bank Address Bus
	inout  wire [7:0]  d,				// Peripheral Data Bus
	
	output wire read_n,					// Bus Read Operation
	output wire write_n,					// Bus Write Operation
	
	output wire [3:0] ram_n,		   // RAM Chip Selects

	output wire io_exp_n,				// Expansion Slot Select
	output wire io_aia_n,            // AIA Sound Chip Select
	output wire io_via1_n,           // VIA 1 Chip Select
	output wire io_via2_n,           // VIA 2 Chip Select
	output wire io_xia_n,            // XIA Video Chip Select
	output wire io_sia_n,            // SIA Interface Chip Select
	
	input  wire irq_exp_n,				// IRQ Signal from Expansion Slot
	input  wire irq_aia_n,           // IRQ Signal from AIA Sound Chip
	input  wire irq_via1_n,          // IRQ Signal from VIA 1 Chip
	input  wire irq_via2_n,          // IRQ Signal from VIA 2 Chip
	input  wire irq_xia_n,           // IRQ Signal from XIA Video Chip
	input  wire irq_sia_n,           // IRQ Signal from SIA Interface Chip
	
	output wire irq_n						// IRQ Signal to CPU
);
 
	wire   valid_address = reset_n && (vda || vpa);
	assign read_n        = ~(phi2 && read_write);
	assign write_n       = ~(phi2 && ~read_write);

	
	// Decode address to select appropriate bus device
	address_decoder decoder (
	   .phi2           (phi2),
		.read_write     (read_write),
		.bank           (bank_address),
		.address        (address),
		.valid_address  (valid_address),
		.ram_n          (ram_n),
		.io_exp_n       (io_exp_n),
		.io_aia_n       (io_aia_n),
		.io_via1_n      (io_via1_n),
		.io_via2_n      (io_via2_n),
		.io_xia_n       (io_xia_n),
		.io_sia_n       (io_sia_n)
	);
	
	
	// Aggregate IRQ signals to the CPU
	irq_aggregator #(.WIDTH(6)) irq_agg (
		.irq_sources_n  ({irq_exp_n, irq_aia_n, irq_via1_n, irq_via2_n, irq_xia_n, irq_sia_n}),
		.irq_out_n      (irq_n)
	);
	
	
	// Bank Address Latch from DBA when PHI2 is low
	always @(*) begin	
	   if (!phi2) begin
			bank_address = dba;
		end
	end


	// Bi-Directional transciever 
	reg [7:0] dba_out;
	reg [7:0] d_out;
	
	
	// Output Direction is set by read_n and write_n as they are already gated by phi2
	assign dba = !read_n  ? dba_out : 8'bZ;
	assign d   = !write_n ? d_out   : 8'bZ;
	
	always @(*) begin
		dba_out = d;
		d_out = dba;
	end
	
endmodule