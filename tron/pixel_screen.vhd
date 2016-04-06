library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;
use work.screen_types.all;

entity pixel_screen is
port (
	clock:	  in STD_LOGIC;
	screen_px: in unsigned(10 downto 0);
	screen_py: in unsigned(10 downto 0);
	color:	  out unsigned(2 downto 0);
	
--	get_color: in STD_LOGIC;
	set_color: in STD_LOGIC;
--	
	ask_x:	  in unsigned(10 downto 0);
	ask_y:	  in unsigned(10 downto 0);
--	
--	res_color: out unsigned(2 downto 0);
	in_color:  in unsigned(2 downto 0)
);
end pixel_screen;

architecture arch of pixel_screen is
	signal screen: T_SCREEN := (others=> (others=> (others => '0')));
begin

	color <= screen(to_integer(screen_px) / 100)(to_integer(screen_py) / 100) when (screen_px < 800 and screen_py < 600) else "000";
	
--	process (get_color)
--	begin
--		if (rising_edge(get_color)) then
--			res_color <= screen(to_integer(ask_x))(to_integer(ask_y));
--		end if;
--	end process;
--	
	process (clock)
	begin
		if (rising_edge(clock)) then
			if (set_color = '1') then
				screen(to_integer(ask_x))(to_integer(ask_y)) <= in_color;
			end if;
		end if;
	end process;

end arch;