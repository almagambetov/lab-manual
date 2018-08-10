-- A. Almagambetov and J.M. Pavlina
-- Description: SPI ADXL345 interface

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity spi_axl is
   Port ( CLK, SDO, RESET : in  STD_LOGIC;
          SDI, CS, SCLK : out  STD_LOGIC;
          Xaxis, Yaxis, Zaxis : out STD_LOGIC_VECTOR(9 downto 0));
end entity;

architecture spi_axl_arch of spi_axl is
   component spi_interface 
   Port( txbuffer : in STD_LOGIC_VECTOR (15 downto 0);
         rxbuffer : out STD_LOGIC_VECTOR (7 downto 0);
         transmit, miso, reset, clk : in STD_LOGIC;
         done_out, mosi, sclk : out STD_LOGIC);
   end component;

   component spi_master
   Port ( clk, clk_5hz, reset, done : in STD_LOGIC;
          transmit : out STD_LOGIC;
          txdata : out STD_LOGIC_VECTOR(15 downto 0);
          rxdata : in STD_LOGIC_VECTOR(7 downto 0);
          x_axis_data, y_axis_data, z_axis_data : out STD_LOGIC_VECTOR(9 downto 0));
   end component;

	signal TxBuffer : STD_LOGIC_VECTOR(15 downto 0);
	signal RxBuffer : STD_LOGIC_VECTOR(7 downto 0);
	signal doneConfigure, done, transmit : STD_LOGIC;

	signal clk_5hz : STD_LOGIC := '0';
	signal counter : INTEGER RANGE 0 TO 5000000;
	
	signal xAxis_data_local, yAxis_data_local, zAxis_data_local : STD_LOGIC_VECTOR(9 downto 0);

begin
   -- Divides axis data by 2 (shift right, pad with zero)
   -- Reduces the range from 0-1024 to 0-512 (2's comp)
	xAxis <= '0' & xAxis_data_local(9 downto 1);
	yAxis <= '0' & yAxis_data_local(9 downto 1);
	zAxis <= '0' & zAxis_data_local(9 downto 1);

   -- 5 Hz clock generator to determine capture rate
   clock_5Hz_instance : process (clk)
	begin
		if rising_edge(clk) then
			if counter = 5000000 then counter <= 0;
				clk_5hz <= not clk_5hz;
			else counter <= counter + 1;
			end if;
		end if;
	end process;

	spi_control : process (clk)		-- CS 0 (enabled), 1 (disabled)
	begin 
      if rising_edge( clk ) then 
         if reset = '1' then cs <= '1';
         elsif transmit = '1' then cs <= '0';
         elsif done = '1' then cs <= '1';
         end if;
      end if;
   end process;

   -- SPI interface control, data storage, send data control
   spi_master_instance: spi_master port map ( RESET => RESET,
                                CLK_5HZ => CLK_5HZ,
                                CLK => CLK,
                                transmit => transmit,
                                TxData => txBuffer,
                                RxData => RxBuffer,
                                done => done,
                                x_axis_data => xAxis_data_local,
                                y_axis_data => yAxis_data_local,
                                z_axis_data => zAxis_data_local);

   -- Timing data generation, AXL data read/write
   spi_interface_instance: spi_interface port map ( MISO => SDO,
                                MOSI => SDI,
                                RESET => RESET,
                                CLK => CLK,
                                SCLK => SCLK,
                                TxBuffer => TxBuffer,
                                RxBuffer => RxBuffer,
                                done_out => done,
                                transmit => transmit);
end architecture;