-- Copyright (c) 2012, A. Skreen, J. Sackos, Digilent, Inc.
-- Modified 9 Aug 2018 by A. Almagambetov

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_master is
   Port ( clk, clk_5hz, reset, done : in STD_LOGIC;
          transmit : out STD_LOGIC;
          txdata : out STD_LOGIC_VECTOR(15 downto 0);
          rxdata : in STD_LOGIC_VECTOR(7 downto 0);
          x_axis_data, y_axis_data, z_axis_data : out STD_LOGIC_VECTOR(9 downto 0));
end entity;

architecture spi_master_arch of spi_master is
   type state_type is (IDLE, CONF, TXG, RXG, FIN, BRK, HOLD);
   signal STATE : state_type;

   type data_type is (x_axis, y_axis, z_axis);
   signal DATA : data_type;

   type CONF_type is (powerCtl , bwRate , dataFormat);
   signal CONFsel : CONF_type;

   -- Configuration registers
   constant POWER_CTL : STD_LOGIC_VECTOR(15 downto 0) := X"2D08";		
   constant BW_RATE : STD_LOGIC_VECTOR(15 downto 0) := X"2C08";		
   constant DATA_FORMAT : STD_LOGIC_VECTOR(15 downto 0) := X"3100";	

   -- Read only for axis registers, single-byte increments
   constant XAXIS0 : STD_LOGIC_VECTOR(15 downto 0) := X"B200"; --10110010;
   constant XAXIS1 : STD_LOGIC_VECTOR(15 downto 0) := X"B300"; --10110011;
   constant YAXIS0 : STD_LOGIC_VECTOR(15 downto 0) := X"B400"; --10110100;
   constant YAXIS1 : STD_LOGIC_VECTOR(15 downto 0) := X"B500"; --10110101;
   constant ZAXIS0 : STD_LOGIC_VECTOR(15 downto 0) := X"B600"; --10110110;
   constant ZAXIS1 : STD_LOGIC_VECTOR(15 downto 0) := X"B700"; --10110111;

   signal BRK_count : STD_LOGIC_VECTOR(11 downto 0);
   signal hold_count : STD_LOGIC_VECTOR(20 downto 0);
   signal end_CONF : STD_LOGIC;
   signal done_CONF : STD_LOGIC;
   signal register_select : STD_LOGIC;
   signal finish : STD_LOGIC;
   signal sample_done : STD_LOGIC;
   signal prevstart : STD_LOGIC_VECTOR(3 downto 0);

begin

   spi_masterProcess : process (clk)
	begin
      if rising_edge(clk) then 
         prevstart <= prevstart(2 downto 0) & clk_5hz;    -- Debounce start button
         if reset = '1' then 
            transmit <= '0';
            STATE <= IDLE;
            DATA <= x_axis;
            BRK_count <= (others => '0');
            hold_count <= (others => '0');
            done_CONF <= '0';
            CONFsel <= powerCtl;
            txdata <= (others => '0');
            register_select <= '0';
            sample_done <= '0';
            finish <= '0';
            x_axis_data <= (others => '0');
            y_axis_data <= (others => '0');
            z_axis_data <= (others => '0');
            end_CONF <= '0';
         else 
            case STATE is
               when IDLE =>
                  if done_CONF = '0' then
                     STATE <= CONF;
                     txdata <= POWER_CTL;
                     Transmit <= '1';
                  elsif (prevstart = "0011" and clk_5hz = '1' and done_CONF = '1') then
                     STATE <= TXG;
                     finish <= '0';
                     txdata <= xAxis0;
                     sample_done <= '0';
                  end if;
               when CONF =>
                  case CONFsel is
                     when powerCtl =>
                        STATE <= FIN;
                        CONFsel <= bwRate;
                        transmit <= '1';
                     when bwRate =>
                        txdata <= BW_RATE;
                        STATE <= FIN;
                        CONFsel <= dataFormat;
                        transmit <= '1';
                     when dataFormat =>
                        txdata <= DATA_FORMAT;
                        STATE <= FIN;
                        transmit <= '1';
                        finish <= '1';
                        end_CONF <= '1';
                     when others => null;
                  end case;
               when TXG =>
                  case DATA is
                     when x_axis =>
							   transmit <= '1';
								STATE <= RXG;
                     when y_axis =>
                        transmit <= '1';
								STATE <= RXG;
                     when z_axis =>
                        transmit <= '1';
								STATE <= RXG;
                     when others => null;
                  end case;
               when RXG =>
                  case DATA is
                     when x_axis =>
                        case register_select is
                           when '0' =>
                              transmit <= '0';
											if done = '1' then
                                    txdata <= xAxis1;
                                    x_axis_data(7 downto 0) <= rxdata(7 downto 0);
                                    STATE <= FIN;
                                    register_select <= '1';
                                 end if;
                           when others =>
                              transmit <= '0';
                              if done = '1' then
                                 txdata <= yAxis0;
                                 x_axis_data(9 downto 8) <= rxdata(1 downto 0);
                                 txdata <= yAxis0;
                                 register_select <= '0';
                                 DATA <= y_axis;
                                 STATE <= FIN;
                              end if;
                        end case;
                     when y_axis =>
                        case register_select is
                           when '0' =>
                              transmit <= '0';
                              if done = '1' then
                                 txdata <= yAxis1;
                                 y_axis_data(7 downto 0) <= rxdata(7 downto 0);
                                 txdata <= yAxis1;
                                 register_select <='1';
                                 STATE <= FIN;
                              end if;
                           when others =>
                              transmit <= '0';
                              if done = '1' then
                                 txdata <= zAxis0;
                                 y_axis_data(9 downto 8) <= rxdata(1 downto 0);
                                 txdata <= zAxis0;
                                 register_select <= '0';
                                 DATA <= z_axis;
                                 STATE <= FIN;
                              end if;
                        end case;
                     when z_axis =>
                        case register_select is
                           when '0' =>
                              transmit <= '0';
                              if done = '1' then
                                 txdata <= zAxis1;
                                 z_axis_data(7 downto 0) <= rxdata(7 downto 0);
                                 txdata <= zAxis1;
                                 register_select <='1';
                                 STATE <= FIN;
                              end if;
                           when others =>
                              transmit<= '0';
                              if done = '1' then
                                 txdata <= xAxis0;
                                 z_axis_data(9 downto 8) <= rxdata(1 downto 0);
                                 txdata <= xAxis0;
                                 register_select <= '0';
                                 DATA <= x_axis;
                                 STATE <= FIN;
                                 sample_done <= '1';
                              end if;
                        end case;
                     when others => null;
                  end case;
               when FIN =>
                  transmit<= '0';
                  if done = '1' then			
                     STATE <= BRK;
                     if end_CONF = '1' then done_CONF <='1';
                     end if;
                  end if;
               when BRK =>
                  if BRK_count = X"FFF" then 
                     BRK_count<= ( others => '0' );
                     if (finish = '1' or sample_done = '1') and clk_5hz = '0' then 
                        STATE <= IDLE;
                        txdata <= xAxis0;
                     elsif (sample_done = '1' and clk_5hz = '1') then
                        STATE <= HOLD;
                     elsif (done_CONF = '1' and sample_done = '0') then 
                        STATE <= TXG;
                        transmit <= '1';
                     elsif done_CONF = '0' then
                        STATE <= CONF;
                     end if;
                  else BRK_count <= BRK_count + 1;
                  end if;
               when HOLD =>
                  if hold_count = X"1FFFFF" then
                     hold_count <= (others => '0');
                     STATE <= TXG;
                     sample_done <= '0';
                  elsif clk_5hz <= '0' then
                     STATE <= IDLE;
                     hold_count <= (others => '0');
                  else hold_count <= hold_count + 1;
                  end if;
               when others => null;
            end case;
         end if;
      end if;
   end process;
end architecture;