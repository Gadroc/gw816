module synchronizer #(parameter WIDTH=1)
(
	input  wire dest_clk,
	input  wire [WIDTH-1:0] sync_in,
	output reg  [WIDTH-1:0] sync_out 
);

	reg [WIDTH-1:0] sync_ms;
	
	always @(posedge dest_clk) begin
		sync_ms  <= sync_in;
		sync_out <= sync_ms;
	end

endmodule