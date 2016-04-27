import tron_types::*;

module game_logic (
	input clock,
	input reset,
	input [2:0] reset_player_count,
	input dir_t d1,
	input dir_t d2,
	input dir_t d3,
	input dir_t d4,
	
	output [18:0] ram_address,
	input [2:0] ram_read_data,
	output ram_write_enabled,
	output [2:0] ram_write_data
);

dir_t dir[3:0];
State state = RESET;

reg is_border = 1'b0;

reg [10:0] xp [3:0];
reg [10:0] yp [3:0];

reg [10:0] xb = 0;
reg [10:0] yb = 0;

reg [31:0] count = 0;

reg write_enabled;
reg [18:0] address;
reg [2:0] write_data;

reg tick = 1'b0;

reg reset_done = 1'b0;
reg reset_border_done = 1'b0;

reg [3:0] check_data_done = 4'b0000;

reg [3:0] is_crash = 4'b0000;

reg [3:0] is_lost = 4'b0000;

reg [3:0] was_turn = 4'b0000;

reg reset_line_write = 1'b0;

reg [2:0] player_count = 4;

typedef enum logic [1:0] {GL_READ_DATA=2'b00, GL_CHECK_DATA=2'b01, GL_UPDATE_POS=2'b10} GameLostState;
GameLostState game_lost_state = GL_READ_DATA;

assign ram_write_enabled = write_enabled;
assign ram_address = address;
assign ram_write_data = write_data;

wire state_is_game_lost;
assign state_is_game_lost = (state == GAME_LOST1 || state == GAME_LOST2 || state == GAME_LOST3 || state == GAME_LOST4);

always write_enabled =    
				((state == MOVE1 && ~is_crash[0] && ~is_lost[0]) || (state == MOVE2 && ~is_crash[1] && ~is_lost[1]) || 
					(state == MOVE3 && ~is_crash[2] && ~is_lost[2]) || (state == MOVE4 && ~is_crash[3] && ~is_lost[3]) || state == RESET || state == RESET_BORDER) ? 1'b1 
			: (state == GAME_LOST1 && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost[0]) ? 1'b1
			: (state == GAME_LOST2 && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost[1]) ? 1'b1
			: (state == GAME_LOST3 && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost[2]) ? 1'b1
			: (state == GAME_LOST4 && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost[3]) ? 1'b1 : 1'b0;
always address = 
			  (state == CHECK1 || state == CHECK_DATA1 || state == MOVE1) ? (320*yp[0] + xp[0])
			: (state == CHECK2 || state == CHECK_DATA2 || state == MOVE2) ? (320*yp[1] + xp[1])
			: (state == CHECK3 || state == CHECK_DATA3 || state == MOVE3) ? (320*yp[2] + xp[2])
			: (state == CHECK4 || state == CHECK_DATA4 || state == MOVE4) ? (320*yp[3] + xp[3])	
			: (state == RESET || state == RESET_BORDER || state_is_game_lost) ? (320*yb + xb) 
			: 0;

always write_data = 
			  (state == MOVE1) ? 3'b100 
			: (state == MOVE2) ? 3'b010
			: (state == MOVE3) ? 3'b011
			: (state == MOVE4) ? 3'b110
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

initial begin
	reset_dirs;
	reset_player_pos;
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
				state <= WAIT;
			end
			WAIT: begin
				if (player_count < 2)
					state <= GAME_OVER;
				else if (tick == 1'b1)
					state <= UPDATE_POS;
				else
					state <= WAIT;
			end
			UPDATE_POS: begin
				state <= CHECK1;
			end

			CHECK1: begin
				state <= CHECK_DATA1;
			end
			CHECK_DATA1: begin
				if (check_data_done[0]) begin
					state <= CHECK2;
				end else
					state <= CHECK_DATA1;
			end
			CHECK2: begin
				state <= CHECK_DATA2;
			end
			CHECK_DATA2: begin
				if (check_data_done[1]) begin
						state <= CHECK3;
				end else
					state <= CHECK_DATA2;
			end
			CHECK3: begin
				state <= CHECK_DATA3;
			end
			CHECK_DATA3: begin
				if (check_data_done[2]) begin
						state <= CHECK4;
				end else
					state <= CHECK_DATA3;
			end
			
			CHECK4: begin
				state <= CHECK_DATA4;
			end
			CHECK_DATA4: begin
				if (check_data_done[3]) begin
						state <= MOVE1;
				end else
					state <= CHECK_DATA4;
			end
			

			MOVE1: begin
				if (is_crash[0] && ~is_lost[0])
					state <= GAME_LOST1;
				else
					state <= MOVE2;
			end
			MOVE2: begin
				if (is_crash[1] && ~is_lost[1])
					state <= GAME_LOST2;
				else
					state <= MOVE3;
			end
			MOVE3: begin
				if (is_crash[2] && ~is_lost[2])
					state <= GAME_LOST3;
				else
					state <= MOVE4;
			end
			MOVE4: begin
				if (is_crash[3] && ~is_lost[3])
					state <= GAME_LOST4;
				else
					state <= WAIT;
			end


			GAME_LOST1: begin
				if (reset_done) 
					state <= MOVE2;
				else 
					state <= GAME_LOST1;
			end
			GAME_LOST2: begin
				if (reset_done) 
					state <= MOVE3;
				else 
					state <= GAME_LOST2;
			end
			GAME_LOST3: begin
				if (reset_done) 
					state <= MOVE4;
				else 
					state <= GAME_LOST3;
			end
			GAME_LOST4: begin
				if (reset_done) 
					state <= WAIT;
				else 
					state <= GAME_LOST4;
			end
			GAME_OVER: begin
				state <= GAME_OVER;
			end
		endcase
	end
end

task handle_dir(
	input dir_t d,
	input dir_t rd,	
	
	inout was_turn,
	inout dir_t dir
);
	if (state == RESET) begin
		dir <= rd;
		was_turn <= 1'b0;
	end else if (state == CHECK1) // State after updating the pos
		was_turn <= 1'b0;
	else if (~was_turn && ((dir == UP && d != DOWN) 
		|| (dir == DOWN && d != UP) 
		|| (dir == RIGHT && d != LEFT) 
		|| (dir == LEFT && d != RIGHT))) begin
		dir <= d;
		was_turn <= 1'b1;
	end
endtask

always @ (posedge clock) begin
	handle_dir(d1, RIGHT, was_turn[0], dir[0]);
end

always @ (posedge clock) begin
	handle_dir(d2, LEFT, was_turn[1], dir[1]);
end

always @ (posedge clock) begin
	handle_dir(d3, DOWN, was_turn[2], dir[2]);
end

always @ (posedge clock) begin
	handle_dir(d4, UP, was_turn[3], dir[3]);
end

always @ (posedge clock) begin
	if (count == 1250000) begin
		tick <= 1'b1;
		count <= 0;
	end else begin
		tick <= 1'b0;
		count <= count + 1;
	end
end

task automatic handle_update_post(
	input dir_t dir,
	
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
		handle_update_post(dir[0], xp[0], yp[0]);
		handle_update_post(dir[1], xp[1], yp[1]);
		handle_update_post(dir[2], xp[2], yp[2]);
		handle_update_post(dir[3], xp[3], yp[3]);
	end
	
	if (state == RESET_POS) begin
		reset_player_pos;
	end
end

task automatic handle_check_data(
	input [10:0] x, input [10:0] y, input [10:0] x1, input [10:0] y1, input [10:0] x2, input [10:0] y2, input [10:0] x3, input [10:0] y3,
	input State s,
	input is_lost,
	
	inout check_data_done,
	inout is_crash
);

	if (state == s && check_data_done == 1'b0) begin
		if (ram_read_data != 3'b000 && ~is_lost) begin
			is_crash <= 1'b1;
			player_count <= player_count - 1;
		end else
			is_crash <= 1'b0;
		
		if (((x == x1 && y == y1) || (x == x2 && y == y2) || (x == x3 && y == y3)) && ~is_lost) begin
			is_crash <= 1'b1;
			player_count <= player_count - 1;
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

	handle_check_data(xp[0], yp[0], xp[1], yp[1], xp[2], yp[2], xp[3], yp[3], CHECK_DATA1, is_lost[0], check_data_done[0], is_crash[0]);
	handle_check_data(xp[1], yp[1], xp[0], yp[0], xp[2], yp[2], xp[3], yp[3], CHECK_DATA2, is_lost[1], check_data_done[1], is_crash[1]);
	handle_check_data(xp[2], yp[2], xp[1], yp[1], xp[0], yp[0], xp[3], yp[3], CHECK_DATA3, is_lost[2], check_data_done[2], is_crash[2]);
	handle_check_data(xp[3], yp[3], xp[1], yp[1], xp[2], yp[2], xp[0], yp[0], CHECK_DATA4, is_lost[3], check_data_done[3], is_crash[3]);
end

always @ (posedge clock) begin
	if (state_is_game_lost) begin				
		if (game_lost_state == GL_CHECK_DATA) begin 
			case (state)
				GAME_LOST1: begin
					if (ram_read_data == 3'b100) begin
						reset_line_write <= 1'b1;
					end else begin
						reset_line_write <= 1'b0;
					end
				end
				GAME_LOST2: begin
					if (ram_read_data == 3'b010) begin
						reset_line_write <= 1'b1;
					end else begin
						reset_line_write <= 1'b0;
					end
				end
				GAME_LOST3: begin
					if (ram_read_data == 3'b011) begin
						reset_line_write <= 1'b1;
					end else begin
						reset_line_write <= 1'b0;
					end
				end
				GAME_LOST4: begin
					if (ram_read_data == 3'b110) begin
						reset_line_write <= 1'b1;
					end else begin
						reset_line_write <= 1'b0;
					end
				end
			endcase
			
			game_lost_state <= GL_UPDATE_POS;
		end else
			game_lost_state <= GL_CHECK_DATA;
	end

	if ((state == RESET || ((state_is_game_lost) && game_lost_state == GL_UPDATE_POS)) 
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
				end else if (state_is_game_lost) begin
					case (state)
						GAME_LOST1: is_lost[0] <= 1'b1;
						GAME_LOST2: is_lost[1] <= 1'b1;
						GAME_LOST3: is_lost[2] <= 1'b1;
						GAME_LOST4: is_lost[3] <= 1'b1;
					endcase
				end
			end else
				yb <= yb + 1;
		end else
			xb <= xb + 1;
			
		if (state_is_game_lost)
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