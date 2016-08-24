library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;



entity toplevel is
	port (
	    CK40_IN : in std_logic;
        NLED1_PIN : out std_logic;
        NLED2_PIN : out std_logic;
        NLED3_PIN : out std_logic;
        TxD : out std_logic;
        RxD : in std_logic;
        Reset_in : in std_logic;
        CK40_ADC :out std_logic;
        ADC_Port : in std_logic_vector(9 downto 0) ;
        PARAPROBAR: out std_logic_vector (7 downto 0)
    );
end toplevel;

architecture Behavioral of toplevel is
	signal CNT : std_logic_vector (25-1 downto 0):= (others=>'0');
    signal sRxOe : std_logic := '0'; 
    signal sRxOut : std_logic_vector (7 downto 0) := (others=>'0');
    signal sTxIn : std_logic_vector (7 downto 0) := (others=>'0');
    signal sTxIe : std_logic := '0';
    signal sOutADC : std_logic_vector (9 downto 0):= (others=>'0');
    signal sOaADC : std_logic := '0';
    signal rWaddrMEM : std_logic_vector (9 downto 0):= (others=>'0');
    signal sP8out : std_logic_vector (7 downto 0):=(others=>'0');
    signal rDiMEM : std_logic_vector(31 downto 0):=(others=>'0');
    signal rDoMEM : std_logic_vector(31 downto 0):=(others=>'0');
    signal rRaddrByteMEM : std_logic_vector(11 downto 0) := (others=>'0');
begin
    
    sTxIe <= sRxOe;
    sTxIn <= sRxOut;

    process (CK40_IN,Reset_in)
    begin
        if (rising_edge(CK40_IN)) then
            if Reset_in = '1' then
               CNT <= (others=> '0');
               rRaddrByteMEM <= (others=>'0');
            else
               CNT <= std_logic_vector(unsigned(CNT)+to_unsigned(1,CNT'length));
            end if;
		  end if;
    end process;

	NLED1_PIN <= CNT(24);
	NLED2_PIN <= CNT(23);

    TX: entity work.Tx_uart
        generic map(
            BITS => 8,
            CORE => 40000000,
            BAUDRATE => 921600
        )
        port map(
            Tx => TxD,
            Load => sP8out,
            LE => sTxIe,
            Tx_busy => NLED3_PIN,
            clk => CK40_IN,
            rst => Reset_in
        );

    RX: entity work.Rx_uart 
        generic map(
            BITS =>8,
            CORE => 40000000,
            BAUDRATE=> 921600
        )
        port map(
            rx => RxD,
            oe => sRxOe,
            output => open,--sRxOut,
            clk => CK40_IN,
            rst => Reset_in
        );
    HIST: entity work.histogram
        generic map(
            DATA_BITS => 8,
            HIST_BITS => 32,
            HIST_SIZE => 2**10
        )
	    port map(  
            pReqData => CNT(22),
            pDataAddr => CNT(11 downto 0),
            pData => PARAPROBAR ,
            pDataAv => open,
            pIE => sOaADC,
            pInput => sOutADC,
            pClk => CK40_IN,
            pCE => '1',
            pRst => Reset_in,
            pReady => open
        );
    AD: entity work.adc
        generic map( BITS => 10 )
        port map(
            pRst => Reset_in ,
            pClk_in => CK40_IN,
            pClk_out => CK40_ADC,
            pInput=> ADC_Port,
            pOutput=> sOutADC,
            pOa => sOaADC
        );
end Behavioral;
