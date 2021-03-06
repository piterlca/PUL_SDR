--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:53:59 05/15/2016
-- Design Name:   
-- Module Name:   /home/piotr/workspace/PUL/PUL_SDR/ISE/PUL_SDR_r/bypass_tb.vhd
-- Project Name:  PUL_SDR_r
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: bypass
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY bypass_tb IS
END bypass_tb;
 
ARCHITECTURE behavior OF bypass_tb IS 
 
	constant Nbit : integer := 12;
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT bypass
    Port ( rst : in  STD_LOGIC;
           clk : in  STD_LOGIC;
           SPI0_SCK : out std_logic;
			  AD_CONV : out std_logic;
			  SPI0_MISO : in  STD_LOGIC;
			  SPI0_MOSI : out std_Logic;
			  SPI0_SS : out std_logic
			  );
    END COMPONENT;
    

   --Inputs
   signal rst : std_logic := '0';
   signal clk : std_logic := '0';


 	--Outputs
   signal SPI0_SCK, SPI0_MISO, SPI0_MOSI, SPI0_SS : std_logic;
   signal AD_CONV : std_logic := '0';


   -- Clock period definitions
   constant clk_period : time := 0.1 	 ns;
 	constant sample_data : std_logic_vector(0 to 2*Nbit - 1) := 
		"011111111110100000000001";
		
		signal ctr : integer := 0;
		signal dac_out : std_logic_vector(11 downto 0) := (others => '1');
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: bypass PORT MAP (
          rst => rst,
          clk => clk,
          SPI0_SCK => SPI0_SCK,
          AD_CONV => AD_CONV,
          SPI0_MISO => SPI0_MISO,
          SPI0_MOSI => SPI0_MOSI,
          SPI0_SS => SPI0_SS
        );

   -- Clock process definitions
   clk_process :process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
 

   stim_proc: process
   begin		
		wait for 5*clk_period;
		
		rst <= '1';

		wait ;
		
		
   end process;

	adc_process : process(rst, AD_CONV, SPI0_SCK) is
	variable data_ctr : integer := 0;
	begin
		if(rst = '0' or AD_CONV = '1') then data_ctr := 0;ctr <= 0;
		elsif(SPI0_SCK'event and SPI0_SCK = '0' and data_ctr < 2*Nbit) then
			if(ctr > 1 and (ctr < Nbit + 2 or ctr > Nbit + 3))	then
				SPI0_MISO <= sample_data(data_ctr);
				data_ctr := data_ctr + 1;	
			else
				SPI0_MISO <= 'Z';
			end if;
			ctr <= ctr + 1;	

		end if;
	
	end process adc_process;
	
	dac_process : process(rst, SPI0_SCK) is
	variable bit_ctr : integer := 0;
	variable collected_data : std_logic_Vector(31 downto 0);
	begin
		if(rst = '0') then bit_ctr := 0; dac_out <= (others => '0');
		elsif(SPI0_SCK'event and SPI0_SCK = '0' ) then
			if(SPI0_SS = '0' and bit_ctr >= 0) then
				collected_data(bit_ctr) := SPI0_MOSI;
				bit_ctr := bit_ctr - 1;
			else
				bit_ctr := 31;
				dac_out  <= collected_data(15 downto 4);
			end if;
		end if;
	
	end process dac_process;

END;
