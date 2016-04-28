module vga_verilog (
	input CLOCK,
	output [10:0] PX,
	output [10:0] PY,
	output VGA_HS,
	output VGA_VS,
	output IS_DRAWING
);

reg [10:0] hor_reg;
reg hor_sync;
wire hor_max = (hor_reg == 799);

reg [10:0] ver_reg;
reg ver_sync;
wire ver_max = (ver_reg == 524);

//reg vga_clock = 1'b0;
//
//always @ (posedge CLOCK) begin
//	vga_clock <= ~vga_clock;
//end

always @ (posedge CLOCK) begin

	if (hor_max) begin
		hor_reg <= 0;

		if (ver_max)
			ver_reg <= 0;
		else
			ver_reg <= ver_reg + 1;

	end else
		hor_reg <= hor_reg + 1;

end

always @ (posedge CLOCK) begin

	if (hor_reg == 656)
		hor_sync <= 0;
	else if (hor_reg == 752)
		hor_sync <= 1;

	if (ver_reg == 490)
		ver_sync <= 0;
	else if (ver_reg == 492)
		ver_sync <= 1;

end

assign VGA_HS = ~hor_sync;
assign VGA_VS = ~ver_sync;
assign PX = hor_reg;
assign PY = ver_reg;
assign IS_DRAWING = (hor_reg < 640) && (ver_reg < 480);

endmodule
