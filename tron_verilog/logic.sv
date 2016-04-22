import tron_types::*;

module game_logic (
	input clock,
	input reset,
	input dir_t d1,
	input dir_t d2,
	
	output [18:0] ram_address,
	input [1:0] ram_read_data,
	output ram_write_enabled,
	output [1:0] ram_write_data
);

dir_t dir1 = RIGHT;
dir_t dir2 = LEFT;
State state = RESET;

reg [10:0] x1 = 20;
reg [10:0] y1 = 120;
reg [10:0] x2 = 300;
reg [10:0] y2 = 120;
reg [10:0] xb = 0;
reg [10:0] yb = 0;
reg [18:0] reset_address = 0;
reg [31:0] count = 0;

reg write_enabled;
reg [18:0] address;
reg [1:0] write_data;

reg tick = 1'b0;

reg reset_done = 1'b0;
reg reset_pos_done = 1'b0;
reg reset_border_done = 1'b0;
reg update_pos_done = 1'b0;

reg check_data1_done = 1'b0;
reg check_data2_done = 1'b0;

reg is_crash = 1'b0;

reg was_turn1 = 1'b0;
reg was_turn2 = 1'b0;

assign ram_write_enabled = write_enabled;
assign ram_address = address;
assign ram_write_data = write_data;

always write_enabled = (state == MOVE1 || state == MOVE2 || state == RESET || state == RESET_BORDER) ? 1'b1 : 1'b0;
always address = (state == CHECK1 || state == CHECK_DATA1 || state == MOVE1) ? (320*y1 + x1) 
			: (state == RESET) ? reset_address 
			: (state == RESET_BORDER) ? (320*yb + xb) 
			: (320*y2 + x2);

always write_data = (state == MOVE1) ? 2'b01 : (state == MOVE2) ? 2'b10 : (state == RESET_BORDER) ? 2'b11 : 2'b00;

always @ (posedge clock) begin
	if (reset && state != RESET) begin
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
				if (reset_pos_done) 
					state <= WAIT;
				else 
					state <= RESET_POS;
			end
			WAIT: begin
				if (tick == 1'b1)
					state <= UPDATE_POS;
				else
					state <= WAIT;
			end
			UPDATE_POS: begin
				if (update_pos_done)
					state <= CHECK1;
				else
					state <= UPDATE_POS;
			end
			CHECK1: begin
				state <= CHECK_DATA1;
			end
			CHECK_DATA1: begin
				if (check_data1_done) begin
					if (is_crash)
						state <= GAME_OVER;
					else
						state <= MOVE1;
				end else
					state <= CHECK_DATA1;
			end
			MOVE1: begin
				state <= CHECK2;
			end
			CHECK2: begin
				state <= CHECK_DATA2;
			end
			CHECK_DATA2: begin
				if (check_data2_done) begin
					if (is_crash)
						state <= GAME_OVER;
					else
						state <= MOVE2;
				end else
					state <= CHECK_DATA2;
			end
			MOVE2: begin
				state <= WAIT;
			end
			GAME_OVER: begin
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
	end else if (~was_turn2 && ((dir2 == UP && d2 != DOWN) 
		|| (dir2 == DOWN && d2 != UP) 
		|| (dir2 == RIGHT && d2 != LEFT) 
		|| (dir2 == LEFT && d2 != RIGHT))) begin
		dir2 <= d2;
		was_turn2 <= 1'b1;
	end
end

always @ (posedge clock) begin
	if (count == 1500000) begin
		tick <= 1'b1;
		count = 0;
	end else begin
		tick <= 1'b0;
		count = count + 1;
	end
end

always @ (posedge clock) begin
	if (state == UPDATE_POS && update_pos_done == 1'b0) begin
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

		update_pos_done <= 1'b1;
	end else begin
		update_pos_done <= 1'b0;
	end
	
	if (state == RESET_POS && reset_pos_done == 1'b0) begin
		x1 <= 20;
		y1 <= 120;
		x2 <= 300;
		y2 <= 120;
		reset_pos_done <= 1'b1;
	end else begin
		reset_pos_done <= 1'b0;
	end
end

always @ (posedge clock) begin
	if (state == CHECK_DATA1 && check_data1_done == 1'b0) begin
		if (ram_read_data != 2'b00/* || x1 == 0 || x1 == 320 || y1 == 0 || y1 == 240*/)
			is_crash <= 1'b1;
		else
			is_crash <= 1'b0;

		check_data1_done <= 1'b1;
	end else begin
		check_data1_done <= 1'b0;
	end
	
	if (state == CHECK_DATA2 && check_data2_done == 1'b0) begin
		if (ram_read_data != 2'b00/* || x2 == 0 || x2 == 320 || y2 == 0 || y2 == 240*/)
			is_crash <= 1'b1;
		else
			is_crash <= 1'b0;

		check_data2_done <= 1'b1;
	end else begin
		check_data2_done <= 1'b0;
	end
end

always @ (posedge clock) begin
	if (state == RESET && reset_done == 1'b0) begin
		if (reset_address == 76800-1) begin
			reset_address <= 0;
			reset_done <= 1'b1;
		end else 
			reset_address <= reset_address + 1;
	end else begin
		reset_done <= 1'b0;
	end
	
	if (state == RESET_BORDER) begin
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