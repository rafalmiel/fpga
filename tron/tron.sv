import tron_types::*;

module tron (
	input CLOCK_50,
	input ps2_clock,
	input ps2_data,
	input btn,
	output VGA_RED,
	output VGA_GREEN,
	output VGA_BLUE,
	output VGA_HS,
	output VGA_VS,
	output led
);

// CLOCKS
wire ram_clock;
wire vga_clock;

// VGA DATA
wire [10:0] phys_x;
wire [10:0] phys_y;
wire is_drawing;
wire [18:0] vga_ram_address;
wire vga_ram_write_enabled;
wire [2:0] vga_ram_read_data;

// LOGIC
wire [18:0] logic_ram_address;
wire logic_ram_write_enabled;
wire [2:0] logic_ram_read_data;
wire [2:0] logic_ram_write_data;

assign VGA_RED = is_drawing & vga_ram_read_data[2];
assign VGA_GREEN = is_drawing & vga_ram_read_data[1];
assign VGA_BLUE = is_drawing & vga_ram_read_data[0];

wire reset;
wire [2:0] reset_player_count;
Dir dir1;
Dir dir2;
Dir dir3;
Dir dir4;

assign vga_ram_address = (phys_x/2+phys_y/2*320);
assign vga_ram_write_enabled = 1'b0;

pll p(
	.inclk0(CLOCK_50),
	.c0(ram_clock),
	.c1(vga_clock)
);

kb_input kb(
	.clock(CLOCK_50),
	.ps2_clock(ps2_clock),
	.ps2_data(ps2_data),

	.d1(dir1),
	.d2(dir2),
	.d3(dir3),
	.d4(dir4),

	.reset(reset),
	.reset_player_count(reset_player_count)
);

game_logic log (
	.clock(CLOCK_50),
	.reset(reset),
	.reset_player_count(reset_player_count),
	.d1(dir1),
	.d2(dir2),
	.d3(dir3),
	.d4(dir4),
	.ram_address(logic_ram_address),
	.ram_read_data(logic_ram_read_data),
	.ram_write_enabled(logic_ram_write_enabled),
	.ram_write_data(logic_ram_write_data)
);

bigram ram(
	.inclock(CLOCK_50),
	.outclock(ram_clock),

	.address_a(vga_ram_address),
	.wren_a(vga_ram_write_enabled),
	.q_a(vga_ram_read_data),

	.data_b(logic_ram_write_data),
	.address_b(logic_ram_address),
	.wren_b(logic_ram_write_enabled),
	.q_b(logic_ram_read_data)
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
