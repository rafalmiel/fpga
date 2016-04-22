package tron_types;

	typedef enum logic [3:0] {WAIT, UPDATE_POS, CHECK1, CHECK_DATA1, CHECK2, CHECK_DATA2, MOVE1, MOVE2, GAME_OVER, RESET, RESET_POS, RESET_BORDER} State;
	typedef enum logic [1:0] {UP=2'b00, RIGHT=2'b01, DOWN=2'b10, LEFT=2'b11} dir_t;

endpackage