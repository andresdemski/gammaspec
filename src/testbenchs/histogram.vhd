library std;
use std.env.all;

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
USE STD.TEXTIO.ALL;
use ieee.std_logic_textio.all;

use work.functions.all;

use work.RandomBasePkg.all ; 
use work.RandomPkg.all ; 

entity hist_tb is
end entity hist_tb;

architecture RTL of hist_tb is
    constant CLK_PERIOD : time := 20 ns;
    constant DATA_BITS : natural := 8;
    constant HIST_BITS : natural := 33;
    constant HIST_SIZE : natural := 2**12;

    signal sReqData : std_logic := '0';
    signal sDataAddr : std_logic_vector (log2(HIST_SIZE*HIST_BITS/DATA_BITS)-1 downto 0) := (others=>'0');
    signal sData : std_logic_vector (DATA_BITS-1 downto 0) := (others=>'0');
    signal sDataAv : std_logic := '0';
    signal sIE : std_logic := '0';
    signal sInput : std_logic_vector (log2(HIST_SIZE)-1 downto 0) := (others=>'0');
    signal sClr : std_logic := '0';
    signal sClk : std_logic := '0';
    signal sCE : std_logic := '0';
    signal sRst : std_logic := '0';
    signal sReady : std_logic  := '0';

    signal sStart : std_logic :='0';
    signal sStop : std_logic := '0';
    signal sTime : std_logic_vector(2*DATA_BITS-1 downto 0):=(others=>'0');

    FILE output_file : text OPEN WRITE_MODE IS "outputs/histograms.dat";

    type ram_t is array (0 to HIST_SIZE-1) of std_logic_vector (HIST_BITS-1 downto 0);
begin

    DUT: entity work.histogram 
        generic map (
                    DATA_BITS => DATA_BITS,
                    HIST_BITS => HIST_BITS,
                    HIST_SIZE => HIST_SIZE,
                    CORE_CLK => 50000000
                    ) 
        port map (
                pReqData => sReqData ,
                pDataAddr => sDataAddr ,
                pData => sData ,
                pDataAv => sDataAv ,

                pIE => sIE ,
                pInput => sInput ,
                pClr => sClr ,
                pClk => sClk ,
                pCE => sCE ,
                pRst => sRst ,
                pReady => sReady,
                pStart => sStart,
                pStop => sStop,
                pTime => sTime
                 );

    CLK_STIMULUS: process
    begin
        sClk <= '1';
        wait for CLK_PERIOD/2;
        sClk <='0';
        wait for CLK_PERIOD/2;
    end process;


    sCE <= '1';
    sRst <= '0';
    sTime <= std_logic_vector(to_unsigned(8,sTime'length));

    INPUT_STIMULUS: process
        variable RV : RandomPType ; 
        variable Input : std_logic_vector (log2(HIST_SIZE)-1 downto 0):=(others=>'0');
        variable idx : integer := 0 ;
        variable aux : integer := 1234567;
        variable l : line;
        variable hist : ram_t:= (others => (others => '0'));
        variable hist_out : ram_t:= (others => (others => '0'));
    begin
        sClr <= '0';
        RV.InitSeed(RV'instance_name)  ;  -- Initialize Seed.  Typically done one time
        RV.setRandomParm(NORMAL, real(HIST_SIZE)/2.0, real(HIST_SIZE)/4.0);
        sIE <= '0';
        sReqData <= '0';
        wait for CLK_PERIOD*4;  -- Para que no me haga quilombos en el t=0
        
        wait until rising_edge(sClk);
        sStart <= '1';
        wait until rising_edge(sClk);
        sStart <= '0';


        for i in 1 to 1000*HIST_SIZE loop
            Input := RV.RandSlv(0,HIST_SIZE-1,log2(HIST_SIZE));
            report "Hola";
            sInput <= Input;
            sIE <= '1';
            hist(to_integer(unsigned(Input))) := std_logic_vector(unsigned(hist(to_integer(unsigned(Input))))+to_unsigned(1,HIST_BITS));
            wait until rising_edge(sClk);
            sIE <= '0';
            wait for 8*CLK_PERIOD;
            wait until rising_edge(sClk);
            assert sReady='0' report "sReady='1'" severity FAILURE;
        end loop;
        
        wait until rising_edge(sClk);
        sStop <= '1';
        wait until rising_edge(sClk);
        sStop <= '0';

        report "Se termino el ingreso de datos";

        for i in 0 to 4*HIST_SIZE-1 loop--(2**sDataAddr'length)-1 loop
            sDataAddr <= std_logic_vector(to_unsigned(i,sDataAddr'length));
            sReqData <= '1';
            wait until sReady='0';
            sReqData <= '0';
            wait until sReady='1';
            idx := to_integer(unsigned(sDataAddr(1 downto 0)));
            hist_out(to_integer(unsigned(sDataAddr(sDataAddr'length-1 downto 2))))(idx*8+7 downto idx*8 ):=sData;
        end loop;
        
        for i in 0 to HIST_SIZE-1 loop
            report "(" & integer'image(i) & "): " & integer'image(to_integer(unsigned(hist(i)))) & HT & integer'image(to_integer(unsigned(hist_out(i))));
            write(l, integer'image(to_integer(unsigned(hist(i)))) & ".0"  );
            writeline(output_file,l);
            assert hist(i)=hist_out(i) report "ERROR: Missmatch at hist(" & integer'image(i) & ")"severity FAILURE; 
        end loop;
        report "Clear";
        
        sClr<='1';
        wait until sReady='0';
        sClr<='0';
        wait until sReady='1';


        for i in 0 to 4*HIST_SIZE-1 loop--(2**sDataAddr'length)-1 loop
            sDataAddr <= std_logic_vector(to_unsigned(i,sDataAddr'length));
            sReqData <= '1';
            wait until sReady='0';
            sReqData <= '0';
            wait until sReady='1';
            idx := to_integer(unsigned(sDataAddr(1 downto 0)));
            hist_out(to_integer(unsigned(sDataAddr(sDataAddr'length-1 downto 2))))(idx*8+7 downto idx*8 ):=sData;
        end loop;

        hist := (others=>(others=>'0'));

        for i in 0 to HIST_SIZE-1 loop
            assert hist_out(i)=std_logic_vector(to_unsigned(0,HIST_BITS)) report "ERROR (Reset): Missmatch hist_out at " & integer'image(i) severity FAILURE; 
            assert hist(i)=std_logic_vector(to_unsigned(0,HIST_BITS)) report "ERROR (Reset): Missmatch hist at " & integer'image(i) severity FAILURE; 
        end loop;

        wait until rising_edge(sClk);
        sStart <= '1';
        wait until rising_edge(sClk);
        sStart <= '0';

        for i in 1 to 10*HIST_SIZE loop
            Input := RV.RandSlv(0,HIST_SIZE-1,log2(HIST_SIZE));
            sInput <= Input;
            sIE <= '1';
            hist(to_integer(unsigned(Input))) := std_logic_vector(unsigned(hist(to_integer(unsigned(Input))))+to_unsigned(1,HIST_BITS));
            wait until rising_edge(sClk);
            sIE <= '0';
            wait for 8*CLK_PERIOD;
            wait until rising_edge(sClk);
        end loop;

        wait until rising_edge(sClk);
        sStop <= '1';
        wait until rising_edge(sClk);
        sStop <= '0';

        for i in 0 to 4*HIST_SIZE-1 loop--(2**sDataAddr'length)-1 loop
            sDataAddr <= std_logic_vector(to_unsigned(i,sDataAddr'length));
            sReqData <= '1';
            wait until sReady='0';
            sReqData <= '0';
            wait until sReady='1';
            idx := to_integer(unsigned(sDataAddr(1 downto 0)));
            hist_out(to_integer(unsigned(sDataAddr(sDataAddr'length-1 downto 2))))(idx*8+7 downto idx*8 ):=sData;
        end loop;

        for i in 0 to HIST_SIZE-1 loop
            report "(" & integer'image(i) & "): " & integer'image(to_integer(unsigned(hist(i)))) & HT & integer'image(to_integer(unsigned(hist_out(i))));
            assert hist(i)=hist_out(i) report "ERROR after CLEAR: Missmatch at hist(" & integer'image(i) & ")"severity FAILURE; 
        end loop;

        report "SUCCES";
        finish(0);
    end process;
    
    -- hist <= <<signal DUT.pie: std_logic>>;

    -- MONITOR: process
    --     variable prev, post : std_logic_vector (HIST_BITS-1 downto 0);
    -- begin
    --     wait until sInput'event and sIE='1';
        
    -- end process;
end architecture RTL;





