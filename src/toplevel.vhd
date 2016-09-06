library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.functions.all;


entity toplevel is
	port (
	    pClk : in std_logic;
        pLed : out std_logic;
        -- NLED2_PIN : out std_logic;
        -- NLED3_PIN : out std_logic;
        pTx : out std_logic;
        pRx : in std_logic
        -- Reset_in : in std_logic
        -- CK40_ADC :out std_logic;
        -- ADC_Port : in std_logic_vector(9 downto 0) ;
        -- PARAPROBAR: out std_logic_vector (7 downto 0)
    );
end toplevel;

architecture Behavioral of toplevel is

    constant DATA_BITS : natural := 8;
    constant OSC_BITS : natural := 16;
    constant LENGTH : natural := 2**10;
    constant DEPTH : natural := 2**9-1;
    
    constant HIST_BITS : natural := 32;
    constant HIST_SIZE : natural := 2**12;
    constant CORE_CLK : natural := 50000000;


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
    -- signal rReqData : std_logic := '1';
    -- signal rDataAddr : std_logic_vector (10 downto 0) := (others=>'0');
    -- signal rData : std_logic_vector (7 downto 0) := (others=>'0');
    -- signal rDataAv : std_logic := '1' ;
    -- signal rIE : std_logic := '1' ;
    -- signal rInput : std_logic_vector (15 downto 0) := (others=>'0');
    -- signal rTStart : std_logic := '0'; -- Start Trigger
    -- signal rTLevel : std_logic_vector(15 downto 0) := std_logic_vector(to_unsigned(2**15,16));
    -- signal rTedge : std_logic := '1'; -- 1:rissing 0: falling
    -- signal rCE : std_logic := '1' ;
    -- signal rRst : std_logic :='0' ;
    -- signal rReady : std_logic := '0';


	signal CNT : std_logic_vector (25-1 downto 0):= (others=>'0');
begin
    sClk <= pClk;
    sRst <= '0';
    sCE <= '1';
    sIE <= '1';

    sHist_Input <= sInput(15 downto 4);

    SIG_GEN: entity work.sigGen generic map( BITS => 16)
	                            port map( pOut => sInput, pClk =>sClk);

    COMM: entity work.commCore generic map(  
            DATA_BITS => 8,
            OSC_DATA_ADDR_BITS=> log2(LENGTH*OSC_BITS/DATA_BITS),
            OSC_BITS => 16,
            OSC_DEPTH => 512
            -- HIST_DATA_ADDR_BITS => 14,
            -- HIST_BITS => 32,
            -- HIST_LENGTH => 2**12
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
        pIE => '1',
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

    TX: entity work.Tx_uart	
        generic map(
	    	BITS => 8,
	    	CORE => 50000000,
	    	BAUDRATE => 921600 
	    )
	    port map (
		    Tx => pTx,
		    Input=> sTx,
		    LE => sTx_le,
		    Tx_busy => sTx_busy,
		    clk => sClk,
		    rst => sRst);

    RX: entity work.Rx_uart
        generic map (
            BITS=>8,
            CORE => 50000000,
            BAUDRATE => 921600
        )
        port map (
            Rx => pRx,
            oe => sRx_av,
            output => sRx,
            clk => sClk,
            rst => sRst
        );



    process (sClk)
    begin
        if (rising_edge(sClk)) then
            CNT <= std_logic_vector(unsigned(CNT)+to_unsigned(1,CNT'length));
        end if;
    end process;

	pLed <= CNT(24);

    -- TX: entity work.Tx_uart
    --     generic map(
    --         BITS => 8,
    --         CORE => 40000000,
    --         BAUDRATE => 921600
    --     )
    --     port map(
    --         Tx => TxD,
    --         Load => sP8out,
    --         LE => sTxIe,
    --         Tx_busy => NLED3_PIN,
    --         clk => CK40_IN,
    --         rst => Reset_in
    --     );

    -- OSC: entity work.oscope 
    -- generic map(
    --     DATA_BITS => 8,
    --     OSC_BITS => 16,
    --     LENGTH => 2**10,
    --     DEPTH => 2**9
    -- )
	-- port map (
    --     pReqData => rReqData,
    --     pDataAddr => rDataAddr,
    --     pData => rData,
    --     pDataAv => rDataAv,
    --     pIE => rIE,
    --     pInput => rInput,
    --     pTStart => rTStart, -- Start Trigger
    --     pTLevel => rTLevel,
    --     pTedge => rTedge, -- 1:rissing 0: falling
    --     pClk => rClk,
    --     pCE => rCE,
    --     pRst => rRst,
    --     pReady => rReady
    -- );



    -- RX: entity work.Rx_uart 
    --     generic map(
    --         BITS =>8,
    --         CORE => 40000000,
    --         BAUDRATE=> 921600
    --     )
    --     port map(
    --         rx => RxD,
    --         oe => sRxOe,
    --         output => open,--sRxOut,
    --         clk => CK40_IN,
    --         rst => Reset_in
    --     );


    -- HIST: entity work.histogram
    --     generic map(
    --         DATA_BITS => 8,
    --         HIST_BITS => 32,
    --         HIST_SIZE => 2**10
    --     )
	    -- port map(  
    --         pReqData => CNT(22),
    --         pDataAddr => CNT(11 downto 0),
    --         pData => PARAPROBAR ,
    --         pDataAv => open,
    --         pIE => sOaADC,
    --         pInput => sOutADC,
    --         pClk => CK40_IN,
    --         pCE => '1',
    --         pRst => Reset_in,
    --         pReady => open
    --     );
    -- AD: entity work.adc
    --     generic map( BITS => 10 )
    --     port map(
    --         pRst => Reset_in ,
    --         pClk_in => CK40_IN,
    --         pClk_out => CK40_ADC,
    --         pInput=> ADC_Port,
    --         pOutput=> sOutADC,
    --         pOa => sOaADC
    --     );
end Behavioral;
