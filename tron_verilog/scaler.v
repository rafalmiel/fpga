module scaler (
	input clock_50mhz,
	output clock_hz
);

parameter reset_cnt = 1500000;

reg [31:0] mhz = 0;
reg clock = 1'b0;

assign clock_hz = (mhz == reset_cnt-1) ? ~clock : clock;

always @(posedge clock_50mhz) begin
	if (mhz == reset_cnt) begin
		mhz <= 0;
	end else begin
		mhz <= mhz + 1;
	end
end

endmodule