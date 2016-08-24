
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.floor;


entity adc is
    generic (
        BITS : natural := 8
    );
	port (
        pRst : in std_logic;
        pClk_in : in std_logic;
        pClk_out : out std_logic;
        pInput : in std_logic_vector (BITS-1 downto 0);
        pOutput : out std_logic_vector( BITS-1 downto 0);
        pOa : out std_logic
	);
end entity adc;

architecture RTL of adc is

begin
    
    pClk_out <= pClk_in;
    
    process (pClk_in,pRst) 
    begin
        if (rising_edge(pClk_in)) then
            if pRst = '1' then
                pOutput <= (others=>'0');
                pOa <= '0';
            else
                pOutput <= pInput;
                pOa <= '1';
            end if;
        end if; 
    end process;


end architecture RTL;
