module address_decoder(
	input  wire phi2,						// CPU Clock Signal
	input  wire read_write,				// CPU RW Signal (High - Read, Low - Write)
	input  wire valid_address,			// Signal indicating address bus is valid
	input  wire [7:0] bank,
	input  wire [15:0] address,
	
	output wire [3:0] ram_n,			// RAM Chip Selects

	output wire io_exp_n,				// Expansion Slot Select
	output wire io_aia_n,            // AIA Sound Chip Select
	output wire io_via1_n,           // VIA 1 Chip Select
	output wire io_via2_n,           // VIA 2 Chip Select
	output wire io_xia_n,            // XIA Video Chip Select
	output wire io_sia_n             // SIA Interface Chip Select
);

	/*
  ------------------------------------ Address Decode -----------------------------------
    $000000-$00FEFF : Base RAM
    $00FF00-$00FF1F : EXP
    $00FF20-$00FF3F : AIA
    $00FF40-$00FF4F : VIA 1 (SNES Controllers, System Timers)
    $00FF50-$00FF5F : VIA 1 (User)
    $00FF60-$00FF7F : XIA
    $00FF80-$00FFFF : SIA (CPU Speed, Reset, Bootloader, UART, Keyboard)
    $010000-$07FFFF : High RAM (Rest of require single 512K RAM Chip)
    $080000-$1FFFFF : Extended RAM (Optional up to 3 more 512K RAM Chips on motherboard)
    $200000-$FFFFFF : Possible Expanded RAM on expandion bus (req ext decode logic)

    Chip Selects are only active if a valid memory address is present from the CPU.
  ---------------------------------------------------------------------------------------
	*/
		
   wire io_select = (valid_address && bank <= 8'h02 && address >= 16'hFF00) ? 1'b1 : 1'b0;
		
	assign io_exp_n  = (io_select && address >= 16'hFF00 && address <= 16'hFF1F) ? 1'b0 : 1'b1;
	assign io_aia_n  = (io_select && address >= 16'hFF20 && address <= 16'hFF3F) ? 1'b0 : 1'b1;
	assign io_via1_n = (io_select && address >= 16'hFF40 && address <= 16'hFF4F) ? 1'b0 : 1'b1;
	assign io_via2_n = (io_select && address >= 16'hFF50 && address <= 16'hFF5F) ? 1'b0 : 1'b1;
	assign io_xia_n  = (io_select && address >= 16'hFF60 && address <= 16'hFF7F) ? 1'b0 : 1'b1;
	assign io_sia_n  = (io_select && address >= 16'hFF80 && address <= 16'hFFFF) ? 1'b0 : 1'b1;

	assign ram_n[0]  = (valid_address && !io_select && bank <= 8'h07) ? 1'b0  : 1'b1;
	assign ram_n[1]  = (valid_address && bank >= 8'h08 && bank <= 8'h0F) ? 1'b0 : 1'b1;
	assign ram_n[2]  = (valid_address && bank >= 8'h10 && bank <= 8'h17) ? 1'b0 : 1'b1;
	assign ram_n[3]  = (valid_address && bank >= 8'h18 && bank <= 8'h1F) ? 1'b0 : 1'b1;

endmodule