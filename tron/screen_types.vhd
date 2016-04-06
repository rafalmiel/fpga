library IEEE;
use IEEE.STD_LOGIC_1164.all;
use ieee.numeric_std.all;

package screen_types is
	type T_ROW is array(5 downto 0) of unsigned(2 downto 0);
	type T_SCREEN is array(7 downto 0) of T_ROW;
end package screen_types;