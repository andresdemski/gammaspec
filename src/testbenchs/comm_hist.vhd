library std;
use std.env.all;
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.functions.all;
use work.constants.all;
use std.textio.all;
use ieee.std_logic_textio.all;


entity comm_hist_tb is
end entity comm_hist_tb;

architecture RTL of comm_hist_tb is

    constant CLK_PERIOD : time := 40 ns;
    constant DATA_BITS : natural := 8;
    constant OSC_BITS : natural := 16;
    constant LENGTH : natural := 2**10;
    constant DEPTH : natural := 2**9-1;
    
    constant HIST_BITS : natural := 32;
    constant HIST_SIZE : natural := 2**12;
    constant CORE_CLK : natural := 25000000;

    signal sRst  : std_logic  := '0';
    signal sClk  : std_logic  := '0';
    signal sCE  : std_logic  := '0';
    signal sIE : std_logic := '0';
    signal sInput : std_logic_vector (OSC_BITS-1 downto 0) := (others=>'0');

    signal sOsc_TStart  : std_logic :='0';
    signal sOsc_TLevel  : std_logic_vector(OSC_BITS-1 downto 0):=(others=>'0');
    signal sOsc_Tedge  : std_logic :='0';
    signal sOsc_Data  :std_logic_vector(DATA_BITS-1 downto 0):=(others=>'0');
    signal sOsc_DataAv  :std_logic   :='0';
    signal sOsc_DataAddr  :std_logic_vector(log2(LENGTH*OSC_BITS/DATA_BITS)-1 downto 0) :=(others=>'0');
    signal sOsc_ReqData  :std_logic   :='0';
    signal sOsc_Ready  :std_logic   :='0';
    signal sHist_ReqData : std_logic := '0';
    signal sHist_DataAddr : std_logic_vector (log2(HIST_SIZE*HIST_BITS/DATA_BITS)-1 downto 0):= (others=>'0');
    signal sHist_Data : std_logic_vector (DATA_BITS-1 downto 0):=(others=>'0');
    signal sHist_DataAv : std_logic:='0';
    signal sHist_Clr : std_logic:='0';
    signal sHist_Start : std_logic:='0';
    signal sHist_Stop : std_logic:='0';
    signal sHist_Time : std_logic_vector(2*DATA_BITS-1 downto 0):=(others=>'0');
    signal sHist_Ready : std_logic:='0';
    signal sHist_Input: std_logic_vector(11 downto 0):=(others=>'0');

    signal sTx  : std_logic_vector(DATA_BITS-1 downto 0):=(others=>'0');
    signal sTx_le  : std_logic  :='0';
    signal sTx_busy  : std_logic  :='0';
    signal sRx_av  :std_logic   :='0';
    signal sRx : std_logic_vector(DATA_BITS-1 downto 0):=(others=>'0');

    signal sTx_out : std_logic := '0';
begin
    COMM: entity work.commCore generic map(  
            DATA_BITS => 8,
            OSC_DATA_ADDR_BITS=> log2(LENGTH*OSC_BITS/DATA_BITS),
            OSC_BITS => 16,
            OSC_DEPTH => 512
           )
        port map(  
            pRx => sRx,
            pRx_av => sRx_av,
            pTx_busy => sTx_busy,
            pTx_le => sTx_le,
            pTx => sTx,
            pOsc_Ready => sOsc_Ready,
            pOsc_ReqData => sOsc_ReqData,
            pOsc_DataAddr => sOsc_DataAddr,
            pOsc_DataAv => sOsc_DataAv,
            pOsc_Data => sOsc_Data,
            pOsc_Tedge => sOsc_Tedge,
            pOsc_TLevel => sOsc_TLevel,
            pOsc_TStart => sOsc_TStart,
            pHist_ReqData => sHist_ReqData,
            pHist_DataAddr => sHist_DataAddr,
            pHist_Data => sHist_Data,
            pHist_DataAv => sHist_DataAv,
            pHist_Clr => sHist_Clr,
            pHist_Start => sHist_Start,
            pHist_Stop => sHist_Stop,
            pHist_Time => sHist_Time,
            pHist_Ready => sHist_Ready,
            pClk => sClk,
            pRst => sRst
        );
    OSC: entity work.oscope 
    generic map(
        DATA_BITS=> DATA_BITS,
        OSC_BITS => OSC_BITS,
        LENGTH => LENGTH,
        DEPTH => DEPTH
    )
	port map(
        pReqData => sOsc_ReqData,
        pDataAddr => sOsc_DataAddr,
        pData => sOsc_Data,
        pDataAv => sOsc_DataAv,
        pIE => sIE,
        pInput => sInput,
        pTStart => sOsc_TStart,
        pTLevel => sOsc_TLevel,
        pTedge => sOsc_Tedge,
        pClk => sClk,
        pCE => sCE,
        pRst => sRst,
        pReady => sOsc_Ready 
    );
    HIST: entity work.histogram
    generic map(
        DATA_BITS => 8,
        HIST_BITS => 32,
        HIST_SIZE => 2**12,
        CORE_CLK => 25000000
    )
	port map(
        pReqData => sHist_ReqData,
        pDataAddr =>sHist_DataAddr,
        pData => sHist_Data,
        pDataAv => sHist_DataAv,
        pIE =>'1',
        pInput => sHist_Input,
        pStart => sHist_Start,
        pStop => sHist_Stop,
        pTime => sHist_Time,
        pClr => sHist_Clr,
        pClk => sClk,
        pCE => sCE,
        pRst => sRst,
        pReady => sHist_Ready
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

    OSC_INPUT_STIMULUS: process
        file fh : text;
        variable lv : line;
        variable input : integer;
    begin
        file_open(fh,"testbenchs/input.dat",READ_MODE);
        sIE <= '1';
        while not endfile(fh) loop
            readline(fh,lv);
            read(lv,input);
            wait until rising_edge(sClk);
            sInput <= std_logic_vector(to_unsigned(input,sInput'length));
        end loop;
        file_close(fh);
    end process;

    HIST_INPUT_STIMULUS : process
        file fh : text;
        variable lv : line;
        variable input : integer;
    begin
        file_open(fh,"testbenchs/hist.dat",READ_MODE);
        while not endfile(fh) loop
            readline(fh,lv);
            read(lv,input);
            wait for 3*CLK_PERIOD;
            wait until rising_edge(sClk);
            sHist_input <= std_logic_vector(to_unsigned(input,sHist_Input'length));
        end loop;
        file_close(fh);
    end process;


    RX_STIMULUS: process
    begin

        wait for 100 ns;
        wait until rising_edge(sClk);
        sRx <= std_logic_vector(to_unsigned(COMMAND_HIST_STATUS,sRx'length));
        sRx_av <= '1';
        wait until rising_edge(sClk);
        sRx_av <= '0';

        wait for 10*CLK_PERIOD;
        wait until rising_edge(sClk);
        sRx <= std_logic_vector(to_unsigned(COMMAND_HIST_TIME,sRx'length));
        sRx_av <= '1';
        wait until rising_edge(sClk);
        sRx_av <= '0';
        wait for 100 ns;
        wait until rising_edge(sClk);
        sRx <= "00000001";
        sRx_av <= '1';
        wait until rising_edge(sClk);
        sRx_av <= '0';
        wait for 100 ns;
        wait until rising_edge(sClk);
        sRx <= "00000000";
        sRx_av <= '1';
        wait until rising_edge(sClk);
        sRx_av <= '0';


        wait for 10*CLK_PERIOD;
        wait until rising_edge(sClk);
        sRx <= std_logic_vector(to_unsigned(COMMAND_HIST_START,sRx'length));
        sRx_av <= '1';
        wait until rising_edge(sClk);
        sRx_av <= '0';

        wait for 20*CLK_PERIOD;
        wait until rising_edge(sClk);
        sRx <= std_logic_vector(to_unsigned(COMMAND_HIST_STATUS,sRx'length));
        sRx_av <= '1';
        wait until rising_edge(sClk);
        sRx_av <= '0';

        wait for 1400 us;--1 us  ;


        wait until rising_edge(sClk);
        sRx <= std_logic_vector(to_unsigned(COMMAND_HIST_STOP,sRx'length));
        sRx_av <= '1';
        wait until rising_edge(sClk);
        sRx_av <= '0';

        wait for 10*CLK_PERIOD;

        wait until rising_edge(sClk);
        sRx <= std_logic_vector(to_unsigned(COMMAND_HIST_DATA,sRx'length));
        sRx_av <= '1';
        wait until rising_edge(sClk);
        sRx_av <= '0';
        
        wait for 4* (2**12) * 160 ns;--1 us  ;
        wait for 100 * 160 ns;
        finish(0);
    end process;

    -- TX: entity work.Tx_uart	
    --     generic map(
	    	-- BITS => 8,
	    	-- CORE => 25000000,
	    	-- BAUDRATE => 912600 
	    -- )
	    -- port map (
		    -- Tx => sTx_out,
		    -- Input=> sTx,
		    -- LE => sTx_le,
		    -- Tx_busy => sTx_busy,
		    -- clk => sClk,
		    -- rst => sRst);
    TX_SIM: process
    begin
        wait until rising_edge(sTx_le);
        sTx_busy <= '1';
        wait for 2*CLK_PERIOD;
        wait until rising_edge(sClk); sTx_busy <= '0';
    end process;

end architecture RTL;





