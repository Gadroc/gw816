module irq_aggregator #(parameter WIDTH=7)
(
	input  [WIDTH-1:0] irq_sources_n,
	output             irq_out_n
);

assign irq_out_n = |(~irq_sources_n) ? 1'b0 : 1'b1;

endmodule