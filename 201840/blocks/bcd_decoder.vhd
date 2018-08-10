-- A. Almagambetov and J.M. Pavlina
-- Description: Binary-to-BCD decoder (supports 0-2048)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity bcd_decoder is
   Port ( inputs : in STD_LOGIC_VECTOR (9 downto 0);
          outputs : out STD_LOGIC_VECTOR (11 downto 0));
end entity;

architecture bcd_decoder_arch of bcd_decoder is
	signal decimal : INTEGER RANGE 0 TO 2048 := 0;
	signal hundreds, tens, ones : INTEGER RANGE 0 TO 9 := 0;
	signal hundreds_bus, tens_bus, ones_bus : STD_LOGIC_VECTOR(3 downto 0) := X"0";
begin
	decimal <= CONV_INTEGER(inputs);
	
	hundreds <= decimal / 100;
	tens <= (decimal - hundreds * 100) / 10;
	ones <= decimal - hundreds * 100 - tens * 10;
	
	hundreds_bus <= CONV_STD_LOGIC_VECTOR(hundreds,4);
	tens_bus <= CONV_STD_LOGIC_VECTOR(tens,4);
	ones_bus <= CONV_STD_LOGIC_VECTOR(ones,4);
	
	outputs <= hundreds_bus & tens_bus & ones_bus;
end architecture;