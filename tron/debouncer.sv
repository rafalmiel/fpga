module debouncer (
	input clock,
	input button,
	output result
);

parameter counter_size = 8;

reg [1:0] flipflops;
wire counter_set;
reg [counter_size:0] counter_out;

assign counter_set = flipflops[0] ^ flipflops[1];

always @ (posedge clock) begin
	flipflops <= {flipflops[0], button};

	if (counter_set) begin
		counter_out <= 0;
	end else if (counter_out[counter_size] == 1'b0) begin
		counter_out <= counter_out + 1;
	end else begin
		result <= flipflops[1];
	end
end

endmodule