module ps2_keyboard (
	input clock,
	input ps2_clock,
	input ps2_data,

	output ps2_code_new,
	output [7:0] ps2_code
);

parameter clk_freq = 50000000;

reg [1:0] sync_ffs;
wire ps2_clock_int;
wire ps2_data_int;

reg [10:0] ps2_word;
wire error;

reg [31:0] count_idle;

always @ (posedge clock) begin
	sync_ffs[0] <= ps2_clock;
	sync_ffs[1] <= ps2_data;
end

debouncer d1(
	.clock(clock),
	.button(sync_ffs[0]),
	.result(ps2_clock_int)
);

debouncer d2(
	.clock(clock),
	.button(sync_ffs[1]),
	.result(ps2_data_int)
);

assign error = ~((~ps2_word[0]) & ps2_word[10] & (ps2_word[9] ^ ps2_word[8] ^ ps2_word[7] ^ ps2_word[6] ^ ps2_word[5] ^ ps2_word[4] ^ ps2_word[3] ^ ps2_word[2] ^ ps2_word[1]));

always @ (negedge ps2_clock_int) begin
	ps2_word <= {ps2_data_int, ps2_word[10:1]};
end

always @ (posedge clock) begin
	if (ps2_clock_int == 1'b0)
		count_idle <= 0;
	else if (count_idle != (clk_freq / 18000))
		count_idle <= count_idle + 1;

	if ((count_idle == clk_freq / 18000) & (~error)) begin
		ps2_code_new <= 1'b1;
		ps2_code <= ps2_word[8:1];
	end else begin
		ps2_code_new <= 1'b0;
	end
end

endmodule