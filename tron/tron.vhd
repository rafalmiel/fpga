library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity tron is
port (
	clock: 		in STD_LOGIC;
	
	vga_red: 	out STD_LOGIC;
	vga_green: 	out STD_LOGIC;
	vga_blue: 	out STD_LOGIC;
	vga_hs: 		out STD_LOGIC;
	vga_vs: 		out STD_LOGIC
);
end entity tron;


architecture arch of tron is
	signal px: 		unsigned(10 downto 0) := to_unsigned(0, 11);
	signal py: 		unsigned(10 downto 0) := to_unsigned(0, 11);
	signal color: 	unsigned(2 downto 0) := to_unsigned(0, 3);
	
	signal set_color: STD_LOGIC := '0';
	signal ask_x: unsigned(10 downto 0) := to_unsigned(0, 11);
	signal ask_y: unsigned(10 downto 0) := to_unsigned(0, 11);
	signal in_color: unsigned(2 downto 0) := "000";
	
	signal scaled_clock: STD_LOGIC := '0';
	
	signal sx: 		unsigned(10 downto 0) := to_unsigned(0, 11);
	signal sy: 		unsigned(10 downto 0) := to_unsigned(0, 11);
begin	
	vga_red <= color(0);
	vga_green <= color(1);
	vga_blue <= color(2);
	
	process (scaled_clock)
	begin
		if (rising_edge(scaled_clock)) then
			if (sx < 7) then
				sx <= sx + 1;
			else
				if (sy < 5) then
					sy <= sy + 1;
				else
					sy <= to_unsigned(0, 11);
				end if;

				sx <= to_unsigned(0, 11);
			end if;
			
			if (sx = to_unsigned(0, 11) and sy = to_unsigned(0, 11)) then
				in_color <= in_color + 1;
			end if;

			ask_x <= sx;
			ask_y <= sy;
			set_color <= '1';
		end if;
	end process;
	
	scaler: entity work.scaler
		port map (
			clock_50mhz => clock,
			clock_hz => scaled_clock
		);
	
	vga_output: entity work.vga_output
		port map (
			clock => clock,
			px => px,
			py => py,
			vga_hs => vga_hs,
			vga_vs => vga_vs
		);
	
	px_screen: entity work.pixel_screen
		port map(
			clock => clock,
			screen_px => px,
			screen_py => py,
			color => color,
			
			set_color => set_color,
			ask_x => ask_x,
			ask_y => ask_y,
			in_color => in_color
		);

end architecture arch;