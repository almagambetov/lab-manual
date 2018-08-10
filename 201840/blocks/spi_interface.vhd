-- Copyright (c) 2012, A. Skreen, J. Sackos, Digilent, Inc.
-- Modified 9 Aug 2018 by A. Almagambetov

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity spi_interface is
   Port( txbuffer : in STD_LOGIC_VECTOR (15 downto 0);
         rxbuffer : out STD_LOGIC_VECTOR (7 downto 0);
         transmit, miso, reset, clk : in STD_LOGIC;
         done_out, mosi, sclk : out STD_LOGIC);
end entity;

architecture spi_interface_arch of spi_interface is
   constant CLKDIVIDER : STD_LOGIC_VECTOR(7 downto 0) := X"FF"; -- 100/50 kHz
   signal clk_count : STD_LOGIC_VECTOR(7 downto 0);
   signal clk_edge_buffer, sck_previous, sck_buffer, done : STD_LOGIC;
   signal tx_shift_register : STD_LOGIC_VECTOR(15 downto 0);
   signal rx_shift_register : STD_LOGIC_VECTOR(7 downto 0);
   signal tx_count, rx_count : STD_LOGIC_VECTOR(3 downto 0);
	
   type TxType is (IDLE, TXG);
   signal TxSTATE : TxType;
	
   type RxType is (IDLE, RXG);
   signal RxSTATE : RxType;
	
   type SCLKType is (IDLE, RUN);
   signal SCLKSTATE : SCLKType;
begin
   sclk <= sck_buffer;
	rxbuffer <= rx_shift_register;
   done_out <= done;

   TxProcess : process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then 
            tx_shift_register <= (others => '0');
            tx_count <= (others => '0');
            mosi <= '1';
            TxSTATE <= IDLE;
         else
            case TxSTATE is
               when IDLE =>
                  tx_shift_register <= txbuffer;
                  if transmit = '1' then 
                     TxSTATE <= TXG;
                  elsif done = '1' then 
                     mosi <= '1';
                  end if;
               when TXG =>
                  if (sck_previous = '1' and sck_buffer = '0') then 
                     if tx_count = "1111" then 
                        TxSTATE <= IDLE;
                        tx_count <= (others => '0');
                        mosi <= tx_shift_register(15);
                     else
                        tx_count<= tx_count + "0001";
                        mosi<= tx_shift_register(15);
                        tx_shift_register<= tx_shift_register( 14 downto 0 ) & '0';
                     end if;
                  end if;
               when others => null;
            end case;
         end if;
      end if;
   end process;

   RxProcess : process (clk)
   begin
      if rising_edge(clk) then 
         if reset = '1' then 
            rx_shift_register <= (others => '0');
            rx_count <= (others => '0');
            done <= '0';
         else
            case RxSTATE is
               when IDLE =>
                  if transmit = '1' then 
                     RxSTATE<= RXG;
                     rx_shift_register <= (others => '0');
                  elsif SCLKSTATE = IDLE then done <= '0';
                  end if;
               when RXG =>
                  if (sck_previous = '0' and sck_buffer = '1') then 
                     if rx_count = "1111" then 
                        RxSTATE <= IDLE;
                        rx_count <= (others => '0');
                        rx_shift_register <= rx_shift_register (6 downto 0) & miso;
                        done <= '1';
                     else
                        rx_count<= rx_count + "0001";
                        rx_shift_register<= rx_shift_register ( 6 downto 0 ) & miso;
                     end if;
                  end if;
               when others => null;
            end case;
         end if;
      end if;
   end process;

   sclk_generator : process (clk)
   begin
      if rising_edge(clk) then
         if reset = '1' then 
            clk_count <= (others => '0');
            SCLKSTATE <= IDLE;
            sck_previous <= '1';
            sck_buffer <= '1';
         else
            case SCLKSTATE is
               when IDLE =>
                  sck_previous <= '1';
                  sck_buffer <='1';
                  if transmit = '1' then
                     SCLKSTATE <= RUN;
                     clk_count <= (others => '0');
                     clk_edge_buffer <= '0';
                     sck_previous <= '1';
                     sck_buffer <= '1';
                  end if;
               when RUN =>
                  if done = '1' then SCLKSTATE <= IDLE;
                  elsif clk_count = CLKDIVIDER then
                     if clk_edge_buffer = '0' then
                        sck_buffer <= '1';
                        clk_edge_buffer <= '1';
                     else
                        sck_buffer <= not sck_buffer;
                        clk_count <= (others => '0');
                     end if;
                  else
                     sck_previous<= sck_buffer;
                     clk_count<= clk_count + 1;
                  end if;
               when others =>	null;
            end case;
         end if;
      end if;
   end process;
end architecture;