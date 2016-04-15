import tron_types::*;

module game_logic (
	input clock,
	input dir_change,
	input dir_t dir,
	
	output [18:0] ram_write_address,
	output ram_write_data,
	output ram_write_enabled
);

typedef enum {WAIT, MOVE, CHECK} State;

dir_t dir1 = RIGHT;
State state = WAIT;

reg [10:0] x1 = 10;
reg [10:0] y1 = 400;
reg [31:0] count = 0;

always @ (posedge clock) begin
	if (dir_change) begin
		if ((dir1 == UP && dir != DOWN) 
			|| (dir1 == DOWN && dir != UP) 
			|| (dir1 == RIGHT && dir != LEFT) 
			|| (dir1 == LEFT && dir != RIGHT))
			dir1 <= dir;
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
			
			if (count == 500000) begin
				state <= MOVE;
				count <= 0;
			end else
				state <= WAIT;
		end
	endcase
end

endmodule