package tron_types;

	typedef enum logic [4:0] {
		WAIT, UPDATE_POS,
		CHECK, CHECK_DATA, MOVE, GAME_LOST,  
		GAME_OVER, RESET, RESET_POS, RESET_BORDER} State;

	typedef enum logic [1:0] {UP=2'b00, RIGHT=2'b01, DOWN=2'b10, LEFT=2'b11} dir_t;

endpackage