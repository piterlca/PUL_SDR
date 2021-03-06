----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:35:11 05/15/2016 
-- Design Name: 
-- Module Name:    bypass - bypass_a 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity bypass is
	Generic(Nbit_data : integer := 12);
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           SPI0_SCK : out std_logic;
			  AD_CONV : out std_logic;
			  SPI0_MISO : in  STD_LOGIC;
			  SPI0_MOSI : out std_Logic;
			  DAC_CS : out std_logic;
			  AMP_CS : out std_logic
			  );
end bypass;

architecture bypass_a of bypass is

	component ADC_TOP is
		Generic(Nbit : integer := 12;
					ADC_speed : integer range 0 to 2**4 - 1);
		 Port ( rst : in  STD_LOGIC;
				  clk : in  STD_LOGIC;
				  start_conv : in std_logic;
				  SPI_SCK : in  STD_LOGIC;
				  SPI_MISO : in  STD_LOGIC;
				  AD_CONV : out  STD_LOGIC;
				  ADC_dataout : out  STD_LOGIC_VECTOR(2*Nbit-1 downto 0));
	end component ADC_TOP;
	
	component DAC_TOP is
		Generic(SPI_SPEED: integer := 4);
    Port ( CLK : in  STD_LOGIC;
           RST : in  STD_LOGIC;
           DAC_MOSI : out  STD_LOGIC;
           DAC_CLR : out  STD_LOGIC;
           DAC_SCK : out  STD_LOGIC;
           DAC_CS : out  STD_LOGIC;
			  DAC_outval : in std_logic_vector(11 downto 0)
		   );
	end component	DAC_TOP;
	
	signal cs : std_logic_vector;
	signal concatenated_data : std_logic_vector(2*Nbit_data-1 downto 0);
	shared variable init_done : std_logic := '0';
begin

	initialize_amp : process(rst, dac_sck) is
	
	constant amp_init_value : std_logic_vector(7 downto 0) := "00010001";
	type stany is (rdy, send, done);
	variable stan_amp : stany := rdy;
	variable sck_ctr : interger range 0 to 7 := 7;
	
	
	begin
		if(dac_sck'event and dac_sck = '1' and init_done = '0') then
			if(stan = rdy) then
				stan := send;
			elsif(stan = send) then
				SPI0_MOSI <= amp_init_value(sck_ctr);
				sck_ctr := sck_ctr - 1;
				if(sck_ctr <= 0) then
					stan := done;
					init_done := '1';
				end if;
			end if;
		end if;
			
		if(stan = send) then AMP_CS <= '0';
		elsif(stan = done) then AMP_CS <= '1'; end if;
		
	end process initialize_amp;
	
	adc: adc_top generic map(Nbit => Nbit_data, ADC_Speed => 2)
					port map(rst => rst, clk => clk,
					start_conv => '1',
					SPI_SCK => dac_sck,
					SPI_MISO => SPI0_MISO,
					AD_CONV => AD_CONV,
					ADC_Dataout => concatenated_data
					);
							
	dac: dac_top 
					generic map(SPI_SPEED => 4)
					port map(clk=>clk ,rst => rst,
					DAC_MOSI => SPI0_MOSI,
					DAC_CLR => open,
					DAC_SCK => SPI0_SCK,
					DAC_CS => cs,
					DAC_outval => concatenated_data(Nbit_data-1 downto 0)
					);
	
	DAC_CS <= cs when init_done = '1' else '1';
end bypass_a;

