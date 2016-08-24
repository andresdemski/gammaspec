
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.functions.all;

entity oscope is
    generic (
        DATA_BITS : natural := 12;
        OSC_BITS : natural := 12;
        LENGTH : natural := 2**10;
        DEPTH : natural := 2**9
    );
	port (
        pReqData : in std_logic;
        pDataAddr : in std_logic_vector (log2(LENGTH*OSC_BITS/DATA_BITS)-1 downto 0);
        pData : out std_logic_vector (DATA_BITS-1 downto 0);
        pDataAv : out std_logic;
        
        pIE : in std_logic;
        pInput : in std_logic_vector (OSC_BITS-1 downto 0);
        pTStart : in std_logic; -- Start Trigger
        pTLevel : in std_logic_vector(OSC_BITS-1 downto 0);
        pTedge : in std_logic; -- 1:rissing 0: falling
        pClk : in std_logic;
        pCE : in std_logic;
        pRst : in std_logic;
        pReady : out  std_logic 
    );
end oscope;

architecture Behavioral of oscope is

    type state_type is (IDLE,PRETRIGGER,TRIGGERING,POSTRIGGER,R_SENDING,SENDING, RESET); 
    signal state, next_state : state_type:= IDLE; 

    signal rDi ,rDi_i : std_logic_vector (OSC_BITS-1 downto 0):= (others=>'0');
    signal rWe ,rWe_i : std_logic := '0';
    signal rAddr ,rAddr_i : std_logic_vector (log2(LENGTH)-1 downto 0):= (others=>'0');
    signal rDo : std_logic_vector (OSC_BITS-1 downto 0):= (others=>'0');
    signal rEn ,rEn_i : std_logic :='0';
    signal rReady, rReady_i : std_logic :='0';
    signal rDataAv, rDataAv_i : std_logic :='0';
    
    signal rData, rData_i : std_logic_vector (DATA_BITS-1 downto 0):=(others=>'0');

    signal rTidx,rTidx_i,rMidx,rMidx_i : std_logic_vector(log2(LENGTH)-1 downto 0):=(others=>'0');
    signal rCNT, rCNT_i : std_logic_vector(log2(DEPTH) downto 0):= (others=>'0');

    signal rTrigger: std_logic := '0';

    signal pipe_s1, pipe_s2: std_logic_vector(OSC_BITS-1 downto 0):=(others=>'0');

    type mux_t is array (0 to OSC_BITS/DATA_BITS-1) of std_logic_vector (DATA_BITS-1 downto 0);
    signal sDataMux : mux_t:= (others => (others => '0'));

begin

    pReady <= rReady;
    pData <= rData;
    pDataAv <= rDataAv;

    MEM: entity work.sp_ram
        generic map (
            PORT_BITS => OSC_BITS,
            LENGTH => LENGTH
        )
        port map (
            pDo => rDo , 
            pAddr => rAddr , 
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
                rCNT <= rCNT_i;
                rTidx <= rTidx_i;
                rMidx <= rMidx_i;
            end if;
        end if;
    end process;

    TRIGGER_DET : process (pClk)
    begin
        if rising_edge(pClk) then
            if (pCE='1') then
                pipe_s1 <= pInput;
                pipe_s2 <= pipe_s1;
                if (pTedge='1') then
                    if unsigned(pipe_s1)>unsigned(pTLevel) and unsigned(pipe_s2)<unsigned(pTLevel) then
                        rTrigger <= '1';
                    else
                        rTrigger <= '0';
                    end if;
                else
                    if unsigned(pipe_s1)<unsigned(pTLevel) and unsigned(pipe_s2)>unsigned(pTLevel) then
                        rTrigger <= '1';
                    else
                        rTrigger <= '0';
                    end if;
                end if;
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
        rDi_i <= pInput;
        rCNT_i <= rCNT;
        rTidx_i<= rTidx;
        rDataAv_i <= '0';
        rMidx_i <= rMidx;


        case (state) is
            when IDLE =>
                rEn_i <= '0';
                rWe_i <= '0';
                rReady_i <= '1';
                if pReqData='1' then
                    next_state <= R_SENDING;
                    rEn_i <= '1';
                    rAddr_i <= std_logic_vector(unsigned(rMidx)+unsigned(pDataAddr)); 
                    rReady_i <= '0';
                elsif pTStart='1' then
                    next_state <= PRETRIGGER;
                    rEn_i <='1';
                    rReady_i <= '0';
                    rWE_i <='1';
                    rAddr_i <= (others=>'0');
                    rCNT_i <= (others=>'0');
                end if;


            when PRETRIGGER =>
                rCNT_i <= std_logic_vector(unsigned(rCNT)+to_unsigned(1,rCNT'length));
                rAddr_i <= std_logic_vector(unsigned(rAddr)+to_unsigned(1,rAddr'length)); 
                if unsigned(rCNT)=to_unsigned(DEPTH/2+2,rCNT'length) then
                    next_state <= TRIGGERING;
                end if;

            when TRIGGERING =>
                rAddr_i <= std_logic_vector(unsigned(rAddr)+to_unsigned(1,rAddr'length)); 
                rReady_i <= '0';
                if (rTrigger='1') then
                    next_state <= POSTRIGGER;
                    rCNT_i <= (others=>'0');
                    rTidx_i<= rAddr;
                end if;

            when POSTRIGGER =>
                rCNT_i <= std_logic_vector(unsigned(rCNT)+to_unsigned(1,rCNT'length));
                rAddr_i <= std_logic_vector(unsigned(rAddr)+to_unsigned(1,rAddr'length)); 
                if unsigned(rCNT)=to_unsigned(DEPTH/2,rCNT'length) then
                    rMidx_i <= std_logic_vector(unsigned(rTidx)-to_unsigned(DEPTH/2+2,rTidx'length));
                    next_state <= IDLE;
                    rEn_i <= '0';
                    rWe_i <= '0';
                    rReady_i <= '1';
                end if;


            when R_SENDING =>
                next_state <= SENDING;
            when SENDING =>
                next_state <= IDLE;
                rDataAv_i <= '1';
                rData_i <= rDo;
                rReady_i <= '1';
                rEn_i <='0';
            
            when RESET =>
                rAddr_i<= std_logic_vector(unsigned(rAddr)+to_unsigned(1,rAddr'length));
                if (unsigned(rAddr)=to_unsigned(LENGTH,rAddr'length)) then
                    next_state <= IDLE;
                    rWe_i <= '0';
                    rEn_i <= '0';
                    rReady_i <= '1';
                end if;
        end case; 
    end process;

    MUX_DATA:for i in 0 to OSC_BITS/DATA_BITS-1 generate
      begin
          sDataMux(i) <= rDo((i+1)*DATA_BITS-1 downto i*DATA_BITS);
    end generate;
			



end architecture Behavioral; 
