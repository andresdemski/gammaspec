library std;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use std.textio.all;
use ieee.std_logic_textio.all;

use work.functions.all;

use work.RandomBasePkg.all ; 
use work.RandomPkg.all ; 


entity sigGen_tb is
end entity sigGen_tb;

architecture RTL of sigGen_tb is
    constant CLK_PERIOD : time := 20 ns; 

    signal sClk : std_logic := '0';
    signal sOut : std_logic_vector (15 downto 0) := (others=>'0');


begin


    DUT: entity work.sigGen
    generic map( BITS=>16 )
	port map( pOut => sOut, pClk => sClk );

    CLK_STIMULUS: process
    begin
        sClk <= '1';
        wait for CLK_PERIOD/2;
        sClk <='0';
        wait for CLK_PERIOD/2;
    end process;


    STIMULUS: process
    begin
        wait for 1024*CLK_PERIOD;
        finish(0);
    end process;

    
end architecture RTL;





