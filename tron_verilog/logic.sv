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

dir_t dir1 = RIGHT;
dir_t dir2 = LEFT;
dir_t dir3 = DOWN;
dir_t dir4 = UP;
State state = RESET;

reg [10:0] x1 = 20;
reg [10:0] y1 = 120;

reg [10:0] x2 = 299;
reg [10:0] y2 = 120;

reg [10:0] x3 = 160;
reg [10:0] y3 = 20;

reg [10:0] x4 = 160;
reg [10:0] y4 = 219;

reg [10:0] xb = 0;
reg [10:0] yb = 0;

reg [31:0] count = 0;

reg write_enabled;
reg [18:0] address;
reg [2:0] write_data;

reg tick = 1'b0;

reg reset_done = 1'b0;
reg reset_border_done = 1'b0;

reg check_data1_done = 1'b0;
reg check_data2_done = 1'b0;
reg check_data3_done = 1'b0;
reg check_data4_done = 1'b0;

reg is_crash1 = 1'b0;
reg is_crash2 = 1'b0;
reg is_crash3 = 1'b0;
reg is_crash4 = 1'b0;

reg is_lost1 = 1'b0;
reg is_lost2 = 1'b0;
reg is_lost3 = 1'b0;
reg is_lost4 = 1'b0;

reg was_turn1 = 1'b0;
reg was_turn2 = 1'b0;
reg was_turn3 = 1'b0;
reg was_turn4 = 1'b0;

reg reset_line_read = 1'b1;
reg reset_line_write = 1'b0;

reg [2:0] player_count = 4;

typedef enum logic [1:0] {GL_READ_DATA=2'b00, GL_CHECK_DATA=2'b01, GL_UPDATE_POS=2'b10} GameLostState;
GameLostState game_lost_state = GL_READ_DATA;


assign ram_write_enabled = write_enabled;
assign ram_address = address;
assign ram_write_data = write_data;

always write_enabled =    ((state == MOVE1 && ~is_crash1 && ~is_lost1) || (state == MOVE2 && ~is_crash2 && ~is_lost2) || 
										(state == MOVE3 && ~is_crash3 && ~is_lost3) || (state == MOVE4 && ~is_crash4 && ~is_lost4) || state == RESET || state == RESET_BORDER) ? 1'b1 
								: (state == GAME_LOST1 && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost1) ? 1'b1
								: (state == GAME_LOST2 && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost2) ? 1'b1
								: (state == GAME_LOST3 && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost3) ? 1'b1
								: (state == GAME_LOST4 && game_lost_state == GL_UPDATE_POS && reset_line_write && ~is_lost4) ? 1'b1 : 1'b0;
always address = 
			  (state == CHECK1 || state == CHECK_DATA1 || state == MOVE1) ? (320*y1 + x1)
			: (state == CHECK2 || state == CHECK_DATA2 || state == MOVE2) ? (320*y2 + x2)
			: (state == CHECK3 || state == CHECK_DATA3 || state == MOVE3) ? (320*y3 + x3)
			: (state == CHECK4 || state == CHECK_DATA4 || state == MOVE4) ? (320*y4 + x4)	
			: (state == RESET || state == RESET_BORDER || state == GAME_LOST1 || state == GAME_LOST2 || 
					state == GAME_LOST3 || state == GAME_LOST4) ? (320*yb + xb) 
			: 0;

always write_data = 
			  (state == MOVE1) ? 3'b100 
			: (state == MOVE2) ? 3'b010
			: (state == MOVE3) ? 3'b011
			: (state == MOVE4) ? 3'b110
			: (state == RESET_BORDER) ? 3'b111
			: 3'b000;

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
				if (check_data1_done) begin
					state <= CHECK2;
				end else
					state <= CHECK_DATA1;
			end
			CHECK2: begin
				state <= CHECK_DATA2;
			end
			CHECK_DATA2: begin
				if (check_data2_done) begin
						state <= CHECK3;
				end else
					state <= CHECK_DATA2;
			end
			CHECK3: begin
				state <= CHECK_DATA3;
			end
			CHECK_DATA3: begin
				if (check_data3_done) begin
						state <= CHECK4;
				end else
					state <= CHECK_DATA3;
			end
			
			CHECK4: begin
				state <= CHECK_DATA4;
			end
			CHECK_DATA4: begin
				if (check_data4_done) begin
						state <= MOVE1;
				end else
					state <= CHECK_DATA4;
			end
			

			MOVE1: begin
				if (is_crash1 && ~is_lost1)
					state <= GAME_LOST1;
				else
					state <= MOVE2;
			end
			MOVE2: begin
				if (is_crash2 && ~is_lost2)
					state <= GAME_LOST2;
				else
					state <= MOVE3;
			end
			MOVE3: begin
				if (is_crash3 && ~is_lost3)
					state <= GAME_LOST3;
				else
					state <= MOVE4;
			end
			MOVE4: begin
				if (is_crash4 && ~is_lost4)
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

always @ (posedge clock) begin
	if (tick)
		was_turn1 <= 1'b0;

	if (state == RESET) begin
		dir1 <= RIGHT;
		was_turn1 <= 1'b0;
	end else if (~was_turn1 && ((dir1 == UP && d1 != DOWN) 
		|| (dir1 == DOWN && d1 != UP) 
		|| (dir1 == RIGHT && d1 != LEFT) 
		|| (dir1 == LEFT && d1 != RIGHT))) begin
		dir1 <= d1;
		was_turn1 <= 1'b1;
	end
end

always @ (posedge clock) begin
	if (tick)
		was_turn2 <= 1'b0;

	if (state == RESET) begin
		dir2 <= LEFT;
		was_turn2 <= 1'b0;
	end else if (~was_turn2 && ((dir2 == UP && d2 != DOWN) 
		|| (dir2 == DOWN && d2 != UP) 
		|| (dir2 == RIGHT && d2 != LEFT) 
		|| (dir2 == LEFT && d2 != RIGHT))) begin
		dir2 <= d2;
		was_turn2 <= 1'b1;
	end
end

always @ (posedge clock) begin
	if (tick)
		was_turn3 <= 1'b0;

	if (state == RESET) begin
		dir3 <= DOWN;
		was_turn3 <= 1'b0;
	end else if (~was_turn3 && ((dir3 == UP && d3 != DOWN) 
		|| (dir3 == DOWN && d3 != UP) 
		|| (dir3 == RIGHT && d3 != LEFT) 
		|| (dir3 == LEFT && d3 != RIGHT))) begin
		dir3 <= d3;
		was_turn3 <= 1'b1;
	end
end

always @ (posedge clock) begin
	if (tick)
		was_turn4 <= 1'b0;

	if (state == RESET) begin
		dir4 <= UP;
		was_turn4 <= 1'b0;
	end else if (~was_turn4 && ((dir4 == UP && d4 != DOWN) 
		|| (dir4 == DOWN && d4 != UP) 
		|| (dir4 == RIGHT && d4 != LEFT) 
		|| (dir4 == LEFT && d4 != RIGHT))) begin
		dir4 <= d4;
		was_turn4 <= 1'b1;
	end
end

always @ (posedge clock) begin
	if (count == 1500000) begin
		tick <= 1'b1;
		count <= 0;
	end else begin
		tick <= 1'b0;
		count <= count + 1;
	end
end

always @ (posedge clock) begin
	if (state == UPDATE_POS) begin
		if (dir1 == UP)
			y1 <= y1 - 1;
		else if (dir1 == RIGHT)
			x1 <= x1 + 1;
		else if (dir1 == DOWN)
			y1 <= y1 + 1;
		else
			x1 <= x1 - 1;

		if (dir2 == UP)
			y2 <= y2 - 1;
		else if (dir2 == RIGHT)
			x2 <= x2 + 1;
		else if (dir2 == DOWN)
			y2 <= y2 + 1;
		else
			x2 <= x2 - 1;

		if (dir3 == UP)
			y3 <= y3 - 1;
		else if (dir3 == RIGHT)
			x3 <= x3 + 1;
		else if (dir3 == DOWN)
			y3 <= y3 + 1;
		else
			x3 <= x3 - 1;
			
		if (dir4 == UP)
			y4 <= y4 - 1;
		else if (dir4 == RIGHT)
			x4 <= x4 + 1;
		else if (dir4 == DOWN)
			y4 <= y4 + 1;
		else
			x4 <= x4 - 1;
	end
	
	if (state == RESET_POS) begin
		x1 <= 20;
		y1 <= 120;
		x2 <= 299;
		y2 <= 120;
		x3 <= 160;
		y3 <= 20;
		x4 <= 160;
		y4 <= 219;
	end
end

always @ (posedge clock) begin
	if (state == RESET) begin
		player_count <= reset_player_count;
		is_crash1 <= 1'b0;
		is_crash2 <= 1'b0;
		is_crash3 <= 1'b0;
		is_crash4 <= 1'b0;
	end

	if (state == CHECK_DATA1 && check_data1_done == 1'b0) begin
		if (ram_read_data != 3'b000 && ~is_lost1) begin
			is_crash1 <= 1'b1;
			player_count <= player_count - 1;
		end else
			is_crash1 <= 1'b0;
		
		if (((x1 == x2 && y1 == y2) || (x1 == x3 && y1 == y3) || (x1 == x4 && y1 == y4)) && ~is_lost1) begin
			is_crash1 <= 1'b1;
			player_count <= player_count - 1;
		end

		check_data1_done <= 1'b1;
	end else begin
		check_data1_done <= 1'b0;
	end
	
	if (state == CHECK_DATA2 && check_data2_done == 1'b0) begin
		if (ram_read_data != 3'b000 && ~is_lost2) begin
			is_crash2 <= 1'b1;
			player_count <= player_count - 1;
		end else
			is_crash2 <= 1'b0;

		if (((x2 == x1 && y2 == y1) || (x2 == x3 && y2 == y3) || (x2 == x4 && y2 == y4)) && ~is_lost2) begin
			is_crash2 <= 1'b1;
			player_count <= player_count - 1;
		end

		check_data2_done <= 1'b1;
	end else begin
		check_data2_done <= 1'b0;
	end
	
	if (state == CHECK_DATA3 && check_data3_done == 1'b0) begin
		if (ram_read_data != 3'b000 && ~is_lost3) begin
			is_crash3 <= 1'b1;
			player_count <= player_count - 1;
		end else
			is_crash3 <= 1'b0;

		if (((x3 == x1 && y3 == y1) || (x3 == x2 && y3 == y2) || (x3 == x4 && y3 == y4)) && ~is_lost3) begin
			is_crash3 <= 1'b1;
			player_count <= player_count - 1;
		end

		check_data3_done <= 1'b1;
	end else begin
		check_data3_done <= 1'b0;
	end
	
	if (state == CHECK_DATA4 && check_data4_done == 1'b0) begin
		if (ram_read_data != 3'b000 && ~is_lost4) begin
			is_crash4 <= 1'b1;
			player_count <= player_count - 1;
		end else
			is_crash4 <= 1'b0;

		if (((x4 == x1 && y4 == y1) || (x4 == x2 && y4 == y2) || (x4 == x3 && y4 == y3)) && ~is_lost4) begin
			is_crash4 <= 1'b1;
			player_count <= player_count - 1;
		end

		check_data4_done <= 1'b1;
	end else begin
		check_data4_done <= 1'b0;
	end
end

always @ (posedge clock) begin
	if (state == GAME_LOST1 || state == GAME_LOST2 || state == GAME_LOST3 || state == GAME_LOST4) begin				
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

	if ((state == RESET || ((state == GAME_LOST1 || state == GAME_LOST2 || state == GAME_LOST3 || state == GAME_LOST4) && game_lost_state == GL_UPDATE_POS)) 
		&& reset_done == 1'b0) begin
		if (xb == 319) begin
			xb <= 0;
			if (yb == 239) begin
				yb <= 0;
				game_lost_state <= GL_READ_DATA;
				reset_line_write <= 1'b0;
				reset_done <= 1'b1;
				if (state == RESET) begin
					is_lost1 <= 1'b0;
					is_lost2 <= 1'b0;
					if (reset_player_count > 2)
						is_lost3 <= 1'b0;
					else
						is_lost3 <= 1'b1;

					if (reset_player_count > 3)
						is_lost4 <= 1'b0;
					else
						is_lost4 <= 1'b1;
				end else if (state == GAME_LOST1 || state == GAME_LOST2 || state == GAME_LOST3 || state == GAME_LOST4) begin
					case (state)
						GAME_LOST1: is_lost1 <= 1'b1;
						GAME_LOST2: is_lost2 <= 1'b1;
						GAME_LOST3: is_lost3 <= 1'b1;
						GAME_LOST4: is_lost4 <= 1'b1;
					endcase
				end
			end else
				yb <= yb + 1;
		end else
			xb <= xb + 1;
			
		if (state == GAME_LOST1 || state == GAME_LOST2 || state == GAME_LOST3 || state == GAME_LOST4)
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