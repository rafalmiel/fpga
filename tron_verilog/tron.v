module tron (
	input CLOCK_50,
	input TURN_LEFT,
	input TURN_RIGHT,
	output VGA_RED,
	output VGA_GREEN,
	output VGA_BLUE,
	output VGA_HS,
	output VGA_VS
);

// CLOCKS
wire ram_clock;
wire vga_clock;

// VGA DATA
wire [10:0] phys_x;
wire [10:0] phys_y;
wire is_drawing;

// RAM DATA
wire [18:0] ram_read_address;
wire [18:0] ram_write_address;
wire ram_write_enabled;
wire ram_write_data;
wire ram_read_data;

assign ram_read_address = (phys_x+phys_y*640);

assign VGA_RED = is_drawing & ram_read_data;
assign VGA_GREEN = is_drawing & ram_read_data;
assign VGA_BLUE = is_drawing & ram_read_data;

pll p(
	.inclk0(CLOCK_50),
	.c0(ram_clock),
	.c1(vga_clock)
);

game_logic log (
	.clock(CLOCK_50),
	.turn_left(TURN_LEFT),
	.turn_right(TURN_RIGHT),
	.ram_write_address(ram_write_address),
	.ram_write_data(ram_write_data),
	.ram_write_enabled(ram_write_enabled)
);

bigram ram(
	.clock(ram_clock),
	.data(ram_write_data),
	.rdaddress(ram_read_address),
	.wraddress(ram_write_address),
	.wren(ram_write_enabled),
	.q(ram_read_data)
); 

vga_verilog vga(
	.CLOCK(vga_clock),
	.PX(phys_x),
	.PY(phys_y),
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.IS_DRAWING(is_drawing)
);

endmodule
