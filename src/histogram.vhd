
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.functions.all;

entity histogram is
    generic (
        DATA_BITS : natural := 8;
        HIST_BITS : natural := 32;
        HIST_SIZE : natural := 2**12
    );
	port (
        pReqData : in std_logic;
        pDataAddr : in std_logic_vector (log2(HIST_SIZE*HIST_BITS/DATA_BITS)-1 downto 0);
        pData : out std_logic_vector (DATA_BITS-1 downto 0);
        pDataAv : out std_logic;
        
        pIE : in std_logic;
        pInput : in std_logic_vector (log2(HIST_SIZE)-1 downto 0);  -- No esta registrada, no modificar si pReady no esta en 1
        pClk : in std_logic;
        pCE : in std_logic;
        pRst : in std_logic;
        pReady : out  std_logic 
    );
end histogram;

architecture Behavioral of histogram is
    type state_type is (IDLE,INCREMENTING,READING, R_SENDING, SENDING, RESET); 
    signal state, next_state : state_type:= IDLE; 

    signal rDi ,rDi_i : std_logic_vector (HIST_BITS-1 downto 0):= (others=>'0');
    signal rWe ,rWe_i : std_logic := '0';
    signal rAddr ,rAddr_i : std_logic_vector (log2(HIST_SIZE) downto 0):= (others=>'0');
    signal rDo : std_logic_vector (HIST_BITS-1 downto 0):= (others=>'0');
    signal rEn ,rEn_i : std_logic :='0';
    signal rReady, rReady_i : std_logic :='0';
    signal rDataAv, rDataAv_i : std_logic :='0';
    
    signal rData, rData_i : std_logic_vector (DATA_BITS-1 downto 0):=(others=>'0');

    type mux_t is array (0 to HIST_BITS/DATA_BITS-1) of std_logic_vector (DATA_BITS-1 downto 0);
    signal sDataMux : mux_t:= (others => (others => '0'));

begin
    pReady <= rReady;
    pData <= rData;
    pDataAv <= rDataAv;

    MEM: entity work.sp_ram
        generic map (
            PORT_BITS => HIST_BITS,
            LENGTH => HIST_SIZE
        )
        port map (
            pDo => rDo , 
            pAddr => rAddr(log2(HIST_SIZE)-1 downto 0) , 
            pEn  => rEn  , 
            pClk => pClk,
            pDi => rDi , 
            pWe => rWe 
        );

    process (pClk)
    begin
        if rising_edge(pClk) then    
            if (pCE='1') then
                state <=  next_state;
                rDi <= rDi_i ;
                rWe <= rWe_i ;
                rAddr <= rAddr_i ;
                rEn <= rEn_i ;
                rData <= rData_i;
                rReady <= rReady_i;
                rDataAv <= rDataAv_i;
            end if;
        end if;
    end process;

    process(state,rWe,rAddr,rEn,rReady,pReqData,pDataAddr,pIE ,pInput,rDo,pRst,rDi,rData,sDataMux)
    begin
        next_state <= state;
        rDi_i <= rDi;
        rWe_i <= rWe;
        rAddr_i <= rAddr;
        rEn_i <= rEn;
        rReady_i <= rReady;
        rData_i <= rData;
        rDataAv_i <= '0';
        case (state) is
            when IDLE =>
                rReady_i <= '1';
                rEn_i<= '0';
                rWe_i<= '0';
                if pReqData='1' then
                    next_state <= R_SENDING;
                    rEn_i <= '1';
                    rReady_i <= '0';
                    rWe_i <= '0';
                    rAddr_i(rAddr_i'length-1 downto 0) <= pDataAddr(pDataAddr'length-1 downto log2(HIST_BITS/DATA_BITS));
                elsif pIE = '1' then
                    next_state <= READING; 
                    rReady_i <= '0';
                    rEn_i <= '1';
                    rAddr_i(pInput'length-1 downto 0) <= pInput; 
                end if;
            when READING =>
                next_state <= INCREMENTING;
                rReady_i <= '0';
                rWe_i <= '0';
            when INCREMENTING=>
                next_state <= IDLE;
                rReady_i <= '1';
                rWe_i <= '1';
                rDi_i <= std_logic_vector(unsigned(rDo)+to_unsigned(1,rDo'length));
            when R_SENDING =>
                next_state <= SENDING;
            when SENDING=>
                rData_i <= sDataMux(to_integer(unsigned(pDataAddr(log2(HIST_BITS/DATA_BITS)-1 downto 0))));
                rDataAv_i <= '1';
                rReady_i <= '1';
                next_state <= IDLE;
                rEn_i <='0';
            when RESET =>
                rAddr_i<= std_logic_vector(unsigned(rAddr)+to_unsigned(1,rAddr'length));
                if (unsigned(rAddr)=to_unsigned(HIST_SIZE,rAddr'length)) then
                    next_state <= IDLE;
                    rWe_i <= '0';
                    rEn_i <= '0';
                    rReady_i <= '1';
                end if;


        end case; 
        
        if pRst='1' then
            next_state <= RESET;
            rReady_i <= '0';
            rWe_i <= '1';
            rEn_i <= '1';
            rDi_i <= (others=>'0');
            rAddr_i <= (others=>'0');
        end if;

    end process;

    MUX_DATA:for i in 0 to HIST_BITS/DATA_BITS-1 generate
      begin
          sDataMux(i) <= rDo((i+1)*DATA_BITS-1 downto i*DATA_BITS);
    end generate;
			


end architecture Behavioral; 
