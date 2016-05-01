import tron_types::*;

module game_logic (
	input clock,
	input reset,
	input [2:0] reset_player_count,
	input Dir d1,
	input Dir d2,
	input Dir d3,
	input Dir d4,
	input toggle_border,

	output [18:0] ram_address,
	input [2:0] ram_read_data,
	output ram_write_enabled,
	output [2:0] ram_write_data
);

Dir dir[3:0];
State state = RESET;

reg is_border = 1'b1;
reg was_toggle_border = 1'b0;

reg [10:0] xp [3:0];
reg [10:0] yp [3:0];

reg [10:0] xb = 0;
reg [10:0] yb = 0;

reg [31:0] count = 0;

reg write_enabled;
reg [18:0] address;
reg [2:0] write_data;

reg tick = 1'b0;
reg boost_tick = 1'b0;

reg is_tick = 1'b0;
reg is_boost_tick = 1'b0;

reg [2:0] normal_move_countdown = 5;
reg [2:0] boost_move_countdown = 2;

reg reset_done = 1'b0;
reg reset_border_done = 1'b0;

reg [3:0] check_data_done = 4'b0000;

reg [3:0] is_crash = 4'b0000;

reg [3:0] is_lost = 4'b0000;

reg [3:0] is_boost_pressed = 4'b0000;
reg [3:0] is_boost = 4'b0000;

reg [15:0] boost_active_countdown [3:0];
reg [15:0] boost_cooldown_countdown [3:0];

reg [3:0] was_turn = 4'b0000;

reg [3:0] is_player_turn = 4'b0000;

reg reset_line_write = 1'b0;

reg [2:0] player_count = 4;
reg [2:0] current_player;
reg [2:0] player_color [3:0];

typedef enum logic [1:0] {GL_READ_DATA=2'b00, GL_CHECK_DATA=2'b01, GL_UPDATE_POS=2'b10} GameLostState;
GameLostState game_lost_state = GL_READ_DATA;

assign ram_write_enabled = write_enabled;
assign ram_address = address;
assign ram_write_data = write_data;

always @ (*) begin
	integer i;
	for (i = 0; i < 4; i = i + 1) begin
		is_player_turn[i] = ~is_lost[i] & ((is_boost[i] & is_boost_tick) | (~is_boost[i] & is_tick));
	end
end

always write_enabled =
			  ((state == MOVE && ~is_crash[current_player] && is_player_turn[current_player]) || state == RESET || state == RESET_BORDER) ? 1'b1
			: (state == GAME_LOST && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost[current_player]) ? 1'b1 : 1'b0;

always address =
			  (state == CHECK || state == CHECK_DATA || state == MOVE) ? (320*yp[current_player] + xp[current_player])
			: (state == RESET || state == RESET_BORDER || state == GAME_LOST) ? (320*yb + xb)
			: 0;

always write_data =
			  (state == MOVE) ? player_color[current_player]
			: (state == RESET_BORDER && is_border) ? 3'b111
			: 3'b000;

task reset_dirs;
	dir[0] <= RIGHT;
	dir[1] <= LEFT;
	dir[2] <= DOWN;
	dir[3] <= UP;
endtask

task reset_player_pos;
	xp[0] <= 20;
	yp[0] <= 120;

	xp[1] <= 299;
	yp[1] <= 120;

	xp[2] <= 160;
	yp[2] <= 20;

	xp[3] <= 160;
	yp[3] <= 219;
endtask

task reset_boost(input [2:0] i);
	is_boost[i] <= 1'b0;

	boost_active_countdown[i] <= 0;
	boost_cooldown_countdown[i] <= 0;

endtask

initial begin
	reset_dirs;
	reset_player_pos;

	reset_boost(0);
	reset_boost(1);
	reset_boost(2);
	reset_boost(3);

	current_player <= 0;

	player_color[0] <= 3'b100;
	player_color[1] <= 3'b010;
	player_color[2] <= 3'b011;
	player_color[3] <= 3'b110;
end

always @ (posedge clock) begin
	if (toggle_border)
		if (state == GAME_OVER)
			was_toggle_border <= 1'b1;
	
	if (was_toggle_border && state == RESET_POS)
		was_toggle_border <= 1'b0;
end

always @ (posedge clock) begin
	if (count == 250000) begin
		if (boost_move_countdown == 0) begin
			boost_tick = 1'b1;
			boost_move_countdown <= 3;
		end else begin
			boost_tick <= 1'b0;
			boost_move_countdown <= boost_move_countdown - 1'b1;
		end

		if (normal_move_countdown == 0) begin
			tick = 1'b1;
			normal_move_countdown <= 5;
		end else begin
			tick <= 1'b0;
			normal_move_countdown <= normal_move_countdown - 1'b1;
		end

		count <= 0;
	end else begin
		tick <= 1'b0;
		boost_tick <= 1'b0;
		count <= count + 1;
	end
end

always @ (posedge clock or posedge reset) begin
	if (reset) begin
		state <= RESET;
	end else begin
		case (state)
			RESET: begin
				if (reset_done)
					state <= RESET_BORDER;
				else
					state <= RESET;
			end

			RESET_BORDER: begin
				if (reset_border_done)
					state <= RESET_POS;
				else
					state <= RESET_BORDER;
			end

			RESET_POS: begin
				current_player <= 0;
				state <= WAIT;
			end

			WAIT: begin
				if (player_count < 2)
					state <= GAME_OVER;
				else if (tick | boost_tick) begin
					is_tick <= tick;
					is_boost_tick <= boost_tick;
					state <= UPDATE_POS;
				end else begin
					is_tick <= 1'b0;
					is_boost_tick <= 1'b0;
					state <= WAIT;
				end
			end

			UPDATE_POS: begin
				state <= CHECK;
			end

			CHECK: begin
				state <= CHECK_DATA;
			end

			CHECK_DATA: begin
				if (check_data_done[current_player]) begin
					if (current_player == 3) begin
						current_player <= 0;
						state <= MOVE;
					end else begin
						current_player <= current_player + 1;
						state <= CHECK;
					end
				end else
					state <= CHECK_DATA;
			end

			MOVE: begin
				if (is_crash[current_player] && ~is_lost[current_player]) begin
					state <= GAME_LOST;
				end else begin
					if (current_player == 3) begin
						current_player <= 0;
						state <= WAIT;
					end else begin
						current_player <= current_player + 1;
						state <= MOVE;
					end
				end
			end

			GAME_LOST: begin
				if (reset_done) begin
					if (current_player == 3) begin
						current_player <= 0;
						state <= WAIT;
					end else begin
						current_player <= current_player + 1;
						state <= MOVE;
					end
				end else begin
					state <= GAME_LOST;
				end
			end

			GAME_OVER: begin
				if (was_toggle_border) begin
					is_border <= ~is_border;
					state <= RESET_BORDER;
				end else
					state <= GAME_OVER;
			end
		endcase
	end
end

task handle_dir(
	input Dir d,
	input Dir rd,

	inout was_t,
	inout is_b,
	inout is_b_press,
	inout [15:0] boost_ac,
	inout [15:0] boost_cc,
	inout Dir dres
);

	if (is_b && boost_tick) begin
		if (boost_ac > 0) begin
			boost_ac <= boost_ac - 1;
			is_b <= 1'b1;
		end else begin
			boost_cc <= 256;
			is_b <= 1'b0;
		end
	end else if (boost_cc > 0 && boost_tick) begin
		boost_cc <= boost_cc - 1;
		is_b <= 1'b0;
	end else if (is_b_press && boost_cc == 0 && boost_tick) begin
		is_b <= 1'b1;
		boost_ac <= 96;
	end

	if (state == RESET) begin
		dres <= rd;
		was_t <= 1'b0;
	end else if (state == CHECK && current_player == 0 && ((is_b && is_boost_tick) || (~is_b && is_tick))) begin // State after updating the pos
		was_t <= 1'b0;
		is_b_press <= 1'b0;
	end else if (~was_t && ((d == UP && dres != DOWN)
		|| (d == DOWN && dres != UP)
		|| (d == RIGHT && dres != LEFT)
		|| (d == LEFT && dres != RIGHT))) begin
		dres <= d;
		was_t <= 1'b1;
	end else if (d == BOOST) begin
		is_b_press <= 1'b1;
	end
endtask

always @ (posedge clock) begin
	handle_dir(d1, RIGHT, was_turn[0], is_boost[0], is_boost_pressed[0], boost_active_countdown[0], boost_cooldown_countdown[0], dir[0]);

	if (state == RESET) begin
		reset_boost(0);
	end
end

always @ (posedge clock) begin
	handle_dir(d2, LEFT, was_turn[1], is_boost[1], is_boost_pressed[1], boost_active_countdown[1], boost_cooldown_countdown[1], dir[1]);

	if (state == RESET) begin
		reset_boost(1);
	end
end

always @ (posedge clock) begin
	handle_dir(d3, DOWN, was_turn[2], is_boost[2], is_boost_pressed[2], boost_active_countdown[2], boost_cooldown_countdown[2], dir[2]);

	if (state == RESET) begin
		reset_boost(2);
	end
end

always @ (posedge clock) begin
	handle_dir(d4, UP, was_turn[3], is_boost[3], is_boost_pressed[3], boost_active_countdown[3], boost_cooldown_countdown[3], dir[3]);

	if (state == RESET) begin
		reset_boost(3);
	end
end

task automatic handle_update_pos(
	input Dir dir,

	inout [10:0] x,
	inout [10:0] y
);
	if (dir == UP) begin
		if (~is_border && y == 0)
			y <= 239;
		else
			y <= y - 1;
	end else if (dir == RIGHT) begin
		if (~is_border && x == 319)
			x <= 0;
		else
			x <= x + 1;
	end else if (dir == DOWN) begin
		if (~is_border && y == 239)
			y <= 0;
		else
			y <= y + 1;
	end else begin
		if (~is_border && x == 0)
			x <= 319;
		else
			x <= x - 1;
	end

endtask

always @ (posedge clock) begin
	if (state == UPDATE_POS) begin
		for (integer i = 0; i < 4; i = i + 1) begin
			if (is_player_turn[i])
				handle_update_pos(dir[i], xp[i], yp[i]);
		end
	end

	if (state == RESET_POS) begin
		reset_player_pos;
	end
end

task automatic handle_check_data(
	input [10:0] x,
	input [10:0] y,
	input is_l,
	input is_his_turn,

	inout check_data_done,
	inout is_c
);

	if (check_data_done == 1'b0) begin
		if (ram_read_data != 3'b000 && is_his_turn) begin
			is_c <= 1'b1;
			player_count <= player_count - 1;
		end else
			is_c <= 1'b0;

		if (~is_l) begin
			integer i;
			for (i = 0; i < 4; i = i + 1) begin
				if (i != current_player && ~is_lost[i] && x == xp[i] && y == yp[i]) begin
					is_c <= 1'b1;
					player_count <= player_count - 1;
					break;
				end
			end
		end

		check_data_done <= 1'b1;
	end else begin
		check_data_done <= 1'b0;
	end

endtask

always @ (posedge clock) begin
	if (state == RESET) begin
		player_count <= reset_player_count;
		is_crash = 4'b0000;
	end

	if (state == CHECK_DATA) begin
		handle_check_data(
			xp[current_player],
			yp[current_player],
			is_lost[current_player],
			is_player_turn[current_player],
			check_data_done[current_player],
			is_crash[current_player]
		);
	end
end

always @ (posedge clock) begin
	if (state == GAME_LOST) begin
		if (game_lost_state == GL_CHECK_DATA) begin
			if (ram_read_data == player_color[current_player]) begin
				reset_line_write <= 1'b1;
			end else begin
				reset_line_write <= 1'b0;
			end

			game_lost_state <= GL_UPDATE_POS;
		end else
			game_lost_state <= GL_CHECK_DATA;
	end

	if ((state == RESET || (state == GAME_LOST && game_lost_state == GL_UPDATE_POS))
		&& reset_done == 1'b0) begin
		if (xb == 319) begin
			xb <= 0;
			if (yb == 239) begin
				yb <= 0;
				game_lost_state <= GL_READ_DATA;
				reset_line_write <= 1'b0;
				reset_done <= 1'b1;
				if (state == RESET) begin
					is_lost[0] <= 1'b0;
					is_lost[1] <= 1'b0;
					if (reset_player_count > 2)
						is_lost[2] <= 1'b0;
					else
						is_lost[2] <= 1'b1;

					if (reset_player_count > 3)
						is_lost[3] <= 1'b0;
					else
						is_lost[3] <= 1'b1;
				end else if (state == GAME_LOST) begin
					is_lost[current_player] <= 1'b1;
				end
			end else
				yb <= yb + 1;
		end else
			xb <= xb + 1;

		if (state == GAME_LOST)
			game_lost_state <= GL_READ_DATA;
	end else begin
		reset_done <= 1'b0;
	end

	if (state == RESET_BORDER && reset_done == 1'b0) begin
		if (yb == 0 || yb == 239) begin
			if (xb < 319) begin
				xb <= xb + 1;
			end else begin
				if (yb == 0) begin
					yb <= yb + 1;
					xb <= 0;
				end else begin
					yb <= 0;
					xb <= 0;
					reset_border_done <= 1'b1;
				end
			end
		end else begin
			if (xb == 0)
				xb <= 319;
			else begin
				xb <= 0;
				yb <= yb + 1;
			end
		end
	end else begin
		reset_border_done <= 1'b0;
	end
end

endmodule