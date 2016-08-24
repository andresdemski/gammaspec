
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_tb is
end entity ;

architecture test of ram_tb is

    signal s1Do : std_logic_vector (7 downto 0):=(others=>'0') ;
    signal s1Raddr : std_logic_vector (11 downto 0):=(others=>'0');
    signal s1En : std_logic :='1';
    signal s1Clk : std_logic :='1';
    signal s2Di : std_logic_vector (31 downto 0):=(others=>'0');
    signal s2We : std_logic :='1';
    signal s2Waddr : std_logic_vector (9 downto 0):=(others=>'0');
    signal s2Raddr: std_logic_vector (9 downto 0):=(others=>'0');
    signal s2Do: std_logic_vector (31 downto 0);
    signal s2En: std_logic :='1';
    signal s2Clk: std_logic :='1';
    signal i : std_logic_vector (9 downto 0):= (others=>'0');
begin
    DUT: entity work.ram 
        generic map(
            PORT1_BITS=> 8 ,  
            PORT2_BITS => 32 ,
            LENGTH =>1024*4
        )
        port map(
            p1Do => s1Do,
            p1Raddr => s1Raddr ,
            p1En => s1En ,
            p1Clk => s1Clk ,
            p2Di => s2Di,
            p2We => s2We,
            p2Waddr => s2Waddr,
            p2Raddr => s2Raddr,
            p2Do => s2Do,
            p2En => s2En,
            p2Clk => s2Clk
        );
    
    process
    begin
        wait for 20 ns;
        s2Clk <= '1';
        wait for 20 ns;
        s2Clk <= '0';
    end process;

    process
    begin
        loop
            s2Di <= (others=>'1');
            s2Waddr <= i;
            i <= std_logic_vector(unsigned(i)+to_unsigned(1,10));
            wait for 40 ns;
        end loop;
    end process;
end architecture ;



