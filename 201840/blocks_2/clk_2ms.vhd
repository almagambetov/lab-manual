-- A. Almagambetov and J.M. Pavlina
-- Description: Clock scaler 50 MHz to 2ms period

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity clk_2ms is
   Port ( clk_in : in STD_LOGIC;
          clk_out : out STD_LOGIC );
end entity;

architecture clk_2ms_arch of clk_2ms is
   signal counter : INTEGER RANGE 0 TO 50000 := 0;
   signal clk_buf : STD_LOGIC := '0';
begin
   clk_out <= clk_buf;

   clock : process (clk_in)
   begin
		if rising_edge(clk_in) then
         if counter = 50000 then
            counter <= 0;
            clk_buf <= not clk_buf;
         else
            counter <= counter + 1;
         end if;
		end if;
   end process;

end architecture;