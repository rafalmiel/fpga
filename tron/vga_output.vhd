library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

entity vga_output is
port(
	clock: 	in STD_LOGIC;
	px: 		out unsigned(10 downto 0);
	py: 		out unsigned(10 downto 0);
	vga_hs: 	out STD_LOGIC;
	vga_vs: 	out STD_LOGIC
);
end entity vga_output;

architecture arch of vga_output is
	signal x: unsigned(10 downto 0) := to_unsigned(0, 11);
	signal y: unsigned(10 downto 0) := to_unsigned(0, 11);
	signal hs: STD_LOGIC := '0';
	signal vs: STD_LOGIC := '0';
	signal hmax: STD_LOGIC := '0';
	signal vmax: STD_LOGIC := '0';
begin

	hmax <= '1' when (x = to_unsigned(1039, 11)) else '0';
	vmax <= '1' when (y = to_unsigned(665, 11)) else '0';
	vga_hs <= not hs;
	vga_vs <= not vs;
	px <= x;
	py <= y;

	process (clock)
	begin
		if (rising_edge(clock)) then
			if (hmax = '1') then
				x <= to_unsigned(0, 11);

				if (vmax = '1') then
					y <= to_unsigned(0, 11);
				else
					y <= y + 1;
				end if;

			else
				x <= x + 1;
			end if;
		end if;
	end process;

	process (clock)
	begin
		if (rising_edge(clock)) then
			if (x = to_unsigned(856, 11)) then
				hs <= '1';
			elsif (x = to_unsigned(976, 11)) then
				hs <= '0';
			end if;

			if (y = to_unsigned(637, 11)) then
				vs <= '1';
			elsif (y = to_unsigned(643, 11)) then
				vs <= '0';
			end if;
		end if;
	end process;

end architecture arch;