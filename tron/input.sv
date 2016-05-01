import tron_types::*;

module kb_input(
	input clock,
	input ps2_clock,
	input ps2_data,

	output Dir d1,
	output Dir d2,
	output Dir d3,
	output Dir d4,

	output reset,
	output [2:0] reset_player_count,
	output toggle_border
);

wire ps2_code_new;
reg [1:0] ps2_code_new_state = 2'b00;
wire ps2_code_new_int;
reg ps2_is_break;
reg ps2_is_ext;
wire [7:0] ps2_code;
Dir dir1 = NONE;
Dir dir2 = NONE;
Dir dir3 = NONE;
Dir dir4 = NONE;

reg [2:0] rpc = 4;

reg toggle_border_int = 1'b0;
reg reset_int = 1'b0;

assign d1 = dir1;
assign d2 = dir2;
assign d3 = dir3;
assign d4 = dir4;

assign ps2_code_new_int = (^ps2_code_new_state) & ps2_code_new_state[0];

assign reset = reset_int;

assign reset_player_count = rpc;

assign toggle_border = toggle_border_int;

always @ (posedge clock) begin
	ps2_code_new_state = {ps2_code_new_state[0], ps2_code_new};
end

task reset_dirs;
	dir1 <= NONE;
	dir2 <= NONE;
	dir3 <= NONE;
	dir4 <= NONE;
endtask

always @ (posedge clock) begin
	if (ps2_code_new_int) begin
		if (ps2_code == 8'hF0) begin
			ps2_is_break <= 1'b1;
		end else if (ps2_code == 8'hE0) begin
			ps2_is_ext <= 1'b1;
		end else begin
			ps2_is_ext <= 1'b0;
			ps2_is_break <= 1'b0;

			if (~ps2_is_break) begin
				if (ps2_code == 8'h1D && ~ps2_is_ext) begin				//W
					dir1 <= UP;
				end else if (ps2_code == 8'h1B && ~ps2_is_ext) begin	//S
					dir1 <= DOWN;
				end else if (ps2_code == 8'h1C && ~ps2_is_ext) begin	//A
					dir1 <= LEFT;
				end else if (ps2_code == 8'h23 && ~ps2_is_ext) begin	//D
					dir1 <= RIGHT;

				end else if (ps2_code == 8'h75 && ps2_is_ext) begin	//ARROR UP
					dir2 <= UP;
				end else if (ps2_code == 8'h72 && ps2_is_ext) begin   //ARROW DOWN
					dir2 <= DOWN;
				end else if (ps2_code == 8'h6B && ps2_is_ext) begin	//ARROW LEFT
					dir2 <= LEFT;
				end else if (ps2_code == 8'h74 && ps2_is_ext) begin 	//ARROW RIGHT
					dir2 <= RIGHT;

				end else if (ps2_code == 8'h43 && ~ps2_is_ext) begin	//I
					dir3 <= UP;
				end else if (ps2_code == 8'h42 && ~ps2_is_ext) begin	//K
					dir3 <= DOWN;
				end else if (ps2_code == 8'h3B && ~ps2_is_ext) begin	//J
					dir3 <= LEFT;
				end else if (ps2_code == 8'h4B && ~ps2_is_ext) begin	//L
					dir3 <= RIGHT;

				end else if (ps2_code == 8'h2C && ~ps2_is_ext) begin	//T
					dir4 <= UP;
				end else if (ps2_code == 8'h34 && ~ps2_is_ext) begin	//G
					dir4 <= DOWN;
				end else if (ps2_code == 8'h2B && ~ps2_is_ext) begin	//F
					dir4 <= LEFT;
				end else if (ps2_code == 8'h33 && ~ps2_is_ext) begin	//H
					dir4 <= RIGHT;

				end else if (ps2_code == 8'h1E && ~ps2_is_ext) begin	//2
					reset_int <= 1'b1;
					rpc <= 2;
					reset_dirs;
				end else if (ps2_code == 8'h26 && ~ps2_is_ext) begin	//3
					reset_int <= 1'b1;
					rpc <= 3;
					reset_dirs;
				end else if (ps2_code == 8'h25 && ~ps2_is_ext) begin	//4
					reset_int <= 1'b1;
					rpc <= 4;
					reset_dirs;
				end else if (ps2_code == 8'h29 && ~ps2_is_ext) begin	//SPACE
					reset_int <= 1'b1;
					reset_dirs;
				end else if (ps2_code == 8'h32 && ~ps2_is_ext) begin //B
					toggle_border_int <= 1'b1;
				end
			end

			if (ps2_code == 8'h24 && ~ps2_is_ext) begin	//E
				dir1 <= (ps2_is_break) ? NONE : BOOST;
			end else if (ps2_code == 8'h70 && ~ps2_is_ext) begin 	//NUM 0
				dir2 <= (ps2_is_break) ? NONE : BOOST;
			end else if (ps2_code == 8'h44 && ~ps2_is_ext) begin	//O
				dir3 <= (ps2_is_break) ? NONE : BOOST;
			end else if (ps2_code == 8'h35 && ~ps2_is_ext) begin	//Y
				dir4 <= (ps2_is_break) ? NONE : BOOST;
			end
		end
	end
	
	if (toggle_border_int)
		toggle_border_int <= 1'b0;

	if (reset_int)
		reset_int <= 1'b0;
end

ps2_keyboard ps2(
	.clock(clock),
	.ps2_clock(ps2_clock),
	.ps2_data(ps2_data),
	.ps2_code_new(ps2_code_new),
	.ps2_code(ps2_code)
);

endmodule
