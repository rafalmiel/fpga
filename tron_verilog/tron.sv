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
wire [1:0] vga_ram_write_enabled;
wire [1:0] vga_ram_read_data;

// LOGIC
wire [18:0] logic_ram_address;
wire logic_ram_write_enabled;
wire [1:0] logic_ram_read_data;
wire [1:0] logic_ram_write_data;

wire ps2_code_new;
reg [1:0] ps2_code_new_state = 2'b00;
wire ps2_code_new_int;
reg ps2_is_break;
wire [7:0] ps2_code;
dir_t dir1 = RIGHT;
dir_t dir2 = LEFT;

assign VGA_RED = is_drawing & (vga_ram_read_data == 2'b01);
assign VGA_GREEN = is_drawing & (vga_ram_read_data == 2'b10);
assign VGA_BLUE = 1'b0;

wire reset;

assign ps2_code_new_int = (^ps2_code_new_state) & ps2_code_new_state[0];

assign vga_ram_address = (phys_x/2+phys_y/2*320);
assign vga_ram_write_enabled = 1'b0;

assign reset = (ps2_code_new_int && ps2_code == 8'h29 && ps2_is_break != 1'b0);

always @ (posedge CLOCK_50) begin
	ps2_code_new_state = {ps2_code_new_state[0], ps2_code_new};
end

always @ (posedge CLOCK_50) begin
	if (ps2_code_new_int) begin
		if (ps2_code == 8'hF0) begin
			ps2_is_break <= 1'b1;
		end else begin
			if (ps2_is_break) begin
				ps2_is_break <= 1'b0;
			end else begin	
				if (ps2_code == 8'h1D) begin
					dir1 <= UP;
				end else if (ps2_code == 8'h1B) begin
					dir1 <= DOWN;
				end else if (ps2_code == 8'h1C) begin
					dir1 <= LEFT;
				end else if (ps2_code == 8'h23) begin
					dir1 <= RIGHT;
				end else if (ps2_code == 8'h4D) begin
					dir2 <= UP;
				end else if (ps2_code == 8'h4C) begin
					dir2 <= DOWN;
				end else if (ps2_code == 8'h4B) begin
					dir2 <= LEFT;
				end else if (ps2_code == 8'h52) begin
					dir2 <= RIGHT;
				end else if (ps2_code == 8'h29) begin
					dir1 <= RIGHT;
					dir2 <= LEFT;
				end
			end
		end
	end
end

pll p(
	.inclk0(CLOCK_50),
	.c0(ram_clock),
	.c1(vga_clock)
);

game_logic log (
	.clock(CLOCK_50),
	.reset(reset),
	.d1(dir1),
	.d2(dir2),
	.ram_address(logic_ram_address),
	.ram_read_data(logic_ram_read_data),
	.ram_write_enabled(logic_ram_write_enabled),
	.ram_write_data(logic_ram_write_data)
);

bigram ram(
	.clock(ram_clock),
	
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

ps2_keyboard ps2(
	.clock(CLOCK_50),
	.ps2_clock(ps2_clock),
	.ps2_data(ps2_data),
	.ps2_code_new(ps2_code_new),
	.ps2_code(ps2_code)
);

endmodule
