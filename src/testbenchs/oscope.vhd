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


entity oscope_tb is
end entity oscope_tb;

architecture RTL of oscope_tb is

    constant CLK_PERIOD : time := 40 ns;
    constant DATA_BITS : natural := 12;
    constant OSC_BITS : natural := 12;
    constant LENGTH : natural := 2**10;
    constant DEPTH : natural := 2**9-1;

    signal sReqData : std_logic := '0';
    signal sDataAddr : std_logic_vector (log2(LENGTH*OSC_BITS/DATA_BITS)-1 downto 0) := (others=>'0');
    signal sData : std_logic_vector (DATA_BITS-1 downto 0) := (others=>'0');
    signal sDataAv : std_logic := '0';
    signal sIE : std_logic := '0';
    signal sInput : std_logic_vector (OSC_BITS-1 downto 0) := (others=>'0');
    signal sTStart : std_logic := '0'; 
    signal sTLevel : std_logic_vector(OSC_BITS-1 downto 0) := (others=>'0');
    signal sTedge : std_logic := '0'; 
    signal sClk : std_logic := '0';
    signal sCE : std_logic := '0';
    signal sRst : std_logic := '0';
    signal sReady : std_logic := '0';


begin


    DUT: entity work.oscope 
    generic map(
        DATA_BITS => DATA_BITS,
        OSC_BITS => OSC_BITS,
        LENGTH => LENGTH,
        DEPTH => DEPTH
    )
	port map(
        pReqData => sReqData,
        pDataAddr => sDataAddr,
        pData => sData,
        pDataAv => sDataAv,
        pIE => sIE,
        pInput => sInput,
        pTStart => sTStart,
        pTLevel => sTLevel,
        pTedge => sTedge,
        pClk => sClk,
        pCE => sCE,
        pRst => sRst,
        pReady => sReady 
    );

    sRst <= '0';
    sCE <= '1';
    CLK_STIMULUS: process
    begin
        sClk <= '1';
        wait for CLK_PERIOD/2;
        sClk <='0';
        wait for CLK_PERIOD/2;
    end process;

    INPUT_STIMULUS: process
        file fh : text;
        variable lv : line;
        variable input : integer;
    begin
        file_open(fh,"testbenchs/input.dat",READ_MODE);
        while not endfile(fh) loop
            readline(fh,lv);
            read(lv,input);
            wait until rising_edge(sClk);
            sInput <= std_logic_vector(to_unsigned(input,sInput'length));
        end loop;
        file_close(fh);
    end process;

    TRIG_STIMULUS: process
        variable RV : RandomPType ; 
    begin
        RV.InitSeed(RV'instance_name)  ;  -- Initialize Seed.  Typically done one time
        RV.setRandomParm(NORMAL, real(2**OSC_BITS)/2.0, real(2**OSC_BITS)/4.0);
        sTedge <= '1';
        sTLevel <= std_logic_vector(to_unsigned(2048,OSC_BITS));

        wait for 40 ns;

        for j in 1 to 10 loop
            sTedge <= not sTedge;
            sTStart <= '1';
            sTlevel <= RV.RandSlv(0,2**OSC_BITS-1,OSC_BITS);
            wait until sReady='0';
            sTStart <= '0';
            wait until sReady='1';
            wait for 10*CLK_PERIOD;

            for i in 0 to DEPTH loop
                sDataAddr <= std_logic_vector(to_unsigned(i,sDataAddr'length));
                sReqData <= '1';
                wait until sReady='0';
                sReqData <= '0';
                wait until sReady='1';
            end loop;

            wait for 10*CLK_PERIOD;
        end loop;

        finish(0);
    end process;

    
end architecture RTL;





