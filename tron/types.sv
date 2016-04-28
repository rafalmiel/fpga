package tron_types;

	typedef enum logic [4:0] {
		WAIT, UPDATE_POS,
		CHECK, CHECK_DATA, MOVE, GAME_LOST,
		GAME_OVER, RESET, RESET_POS, RESET_BORDER} State;

	typedef enum logic [2:0] {UP=3'b000, RIGHT=3'b001, DOWN=3'b010, LEFT=3'b011, BOOST=3'b100, NONE=3'b101} Dir;

endpackage