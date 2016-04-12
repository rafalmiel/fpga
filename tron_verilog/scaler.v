module scaler (
	input clock_50mhz,
	output reg clock_hz
);

parameter reset_cnt = 150000;

reg [31:0] mhz;

initial begin
	mhz <= 0;
end

always @(posedge clock_50mhz) begin
	if (mhz == reset_cnt) begin
		mhz <= 0;
	end else begin
		mhz <= mhz + 1;
	end
end

always @(posedge clock_50mhz) begin
	if (mhz == reset_cnt-1) begin
		clock_hz <= ~clock_hz;
	end else begin
		clock_hz <= clock_hz;
	end
end

endmodule