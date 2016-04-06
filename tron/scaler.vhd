library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity scaler is
port (
	clock_50mhz: in STD_LOGIC;
	clock_hz: out STD_LOGIC
);
end scaler;

architecture scaler of scaler is
	signal mhz: integer := 0;
begin
	process (clock_50mhz)
	begin
		if (rising_edge(clock_50mhz)) then
			if (mhz = 500000) then
				mhz <= 0;
				clock_hz <= '1';
			else
				mhz <= mhz + 1;
				clock_hz <= '0';
			end if;
		end if;
	end process;
end scaler;