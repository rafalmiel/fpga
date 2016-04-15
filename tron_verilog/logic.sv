module game_logic (
	input clock,
	input turn_left,
	input turn_right,
	
	output [18:0] ram_write_address,
	output ram_write_data,
	output ram_write_enabled
);

typedef enum {LEFT,RIGHT,UP,DOWN} Dirs;
typedef enum {WAIT, MOVE, CHECK} State;

Dirs dir1 = RIGHT;
State state = WAIT;

reg [10:0] x1 = 10;
reg [10:0] y1 = 400;
reg [31:0] count = 0;

reg [1:0] turn_left_buf = 2'b11;
reg [1:0] turn_right_buf = 2'b11;

wire turn_left_int;
wire turn_right_int;

assign turn_left_int = (^turn_left_buf & ~turn_left_buf[0]) ? 1'b1 : 1'b0;
assign turn_right_int = (^turn_right_buf & ~turn_right_buf[0]) ? 1'b1 : 1'b0;

always @ (posedge clock) begin
	turn_left_buf <= {turn_left_buf[0], turn_left};
	turn_right_buf <= {turn_right_buf[0], turn_right};
end

always @ (posedge clock) begin
	if (turn_left_int) begin
		if (dir1 == RIGHT) dir1 <= UP;
		else if (dir1 == DOWN) dir1 <= RIGHT;
		else if (dir1 == LEFT) dir1 <= DOWN;
		else dir1 <= LEFT;
	end else if (turn_right_int) begin
		if (dir1 == RIGHT) dir1 <= DOWN;
		else if (dir1 == DOWN) dir1 <= LEFT;
		else if (dir1 == LEFT) dir1 <= UP;
		else dir1 <= RIGHT;
	end
end

always @ (posedge clock) begin
	case (state)
		MOVE: begin
			if (dir1 == RIGHT)
				x1 <= x1 + 1;
			else if (dir1 == UP)
				y1 <= y1 - 1;
			else if (dir1 == LEFT)
				x1 <= x1 - 1;
			else
				y1 <= y1 + 1;
				
			ram_write_address <= (y1*640 + x1);
			ram_write_data <= 1'b1;
			ram_write_enabled <= 1'b1;

			state <= CHECK;
		end
		CHECK: begin
			
			state <= WAIT;
		end
		WAIT: begin
			ram_write_enabled <= 1'b0;
			count <= count + 1;
			
			if (count == 500000)
				state <= MOVE;
				count <= 0;
			else
				state <= WAIT;
		end
	endcase
end

endmodule