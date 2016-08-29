library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.functions.all;
use work.constants.all;

entity commCore is
	generic(  
            DATA_BITS : natural := 8;
            DATA_ADDR_BITS: natural := 10;
            OSC_BITS : natural := 16;
            OSC_DEPTH : natural := 512
           );
	port(  
            pRx : in std_logic_vector (DATA_BITS-1 downto 0);
            pRx_av : in std_logic;
            pTx_busy : in std_logic;
            pTx_le : out std_logic;
            pTx : out std_logic_vector (DATA_BITS-1 downto 0);
            
            pOsc_Ready : in std_logic;
            pOsc_ReqData : out std_logic;
            pOsc_DataAddr : out std_logic_vector(DATA_ADDR_BITS-1 downto 0);
            pOsc_DataAv : in std_logic;
            pOsc_Data : in std_logic_vector(DATA_BITS-1 downto 0);
            pOsc_Tedge : out std_logic;
            pOsc_TLevel : out std_logic_vector(OSC_BITS-1 downto 0);
            pOsc_TStart : out std_logic;

            pClk : in std_logic;
            pRst : in std_logic
        );
end entity commCore;

architecture RTL of commCore is
    signal rTx_le, rTx_le_i : std_logic := '0' ;
    signal rTx, rTx_i : std_logic_vector(DATA_BITS-1 downto 0) := (others=>'0') ;
    signal rOsc_ReqData, rOsc_ReqData_i : std_logic := '0' ;
    signal rOsc_DataAddr, rOsc_DataAddr_i : std_logic_vector(DATA_ADDR_BITS-1 downto 0) := (others=>'0') ;
    signal rOsc_Tedge, rOsc_Tedge_i : std_logic := '0' ;
    signal rOsc_TLevel, rOsc_TLevel_i : std_logic_vector(OSC_BITS-1 downto 0) := (others=>'0') ;
    signal rOsc_TStart, rOsc_TStart_i : std_logic := '0' ;

    type state_type is (IDLE, OSC_TLEVEL, OSC_TEDGE, OSC_DATA_INIT,OSC_DATA,OSC_DATA_READY, OSC_RESP, OSC_STATUS ); 
    signal state, next_state : state_type:= IDLE; 
    


    constant  SLV_DEPTH : std_logic_vector(2*DATA_BITS-1 downto 0):= std_logic_vector(to_unsigned(2*OSC_DEPTH,2*DATA_BITS));

    signal pipe1: std_logic_vector(DATA_BITS-1 downto 0) := (others=>'0');
    signal cnt_aux,cnt_aux_i : std_logic_vector(DATA_ADDR_BITS downto 0) := (others=>'0');
begin
    pTx_le  <= rTx_le;
    pTx <= rTx;
    pOsc_ReqData <= rOsc_ReqData;
    pOsc_DataAddr <= rOsc_DataAddr;
    pOsc_Tedge <= rOsc_Tedge;
    pOsc_TLevel <= rOsc_TLevel;
    pOsc_TStart <= rOsc_TStart;

    OSC_FF: process (pClk)
    begin
        if rising_edge(pClk) then
            if pRst='1' then
                state <= IDLE;
                rTx_le <= '0' ;
                rTx <= (others=>'0') ;
                rOsc_ReqData <= '0' ;
                rOsc_DataAddr <= (others=>'0') ;
                rOsc_Tedge <= '0' ;
                rOsc_TLevel <= (others=>'0') ;
                rOsc_TStart <= '0' ;
            else
                state <= next_state;
                rTx_le <= rTx_le_i ;
                rTx <= rTx_i ;
                rOsc_ReqData <= rOsc_ReqData_i ;
                rOsc_DataAddr <= rOsc_DataAddr_i ;
                rOsc_Tedge <= rOsc_Tedge_i ;
                rOsc_TLevel <= rOsc_TLevel_i ;
                rOsc_TStart <= rOsc_TStart_i ;
                cnt_aux <= cnt_aux_i;
            end if;
        end if;
    end process;

    COMM_PIPE: process(pClk)
    begin
        if rising_edge(pClk) then
            if pRst = '1' then
                pipe1 <= (others=>'0');
            else
                if pRx_av='1' then
                    pipe1 <= pRx;
                end if;
            end if;
        end if;
    end process;

    INPUT_PROC: process (state,pRx_av,cnt_aux,pTx_busy, pOsc_DataAv, pOsc_Data,pRx,
                         rOsc_TLevel, rOsc_Tedge, rOsc_DataAddr, rTx, pipe1, pOsc_Ready)
    begin
        next_state <= state;
        cnt_aux_i <= cnt_aux;
        rOsc_TLevel_i <= rOsc_TLevel;
        rOsc_Tedge_i <= rOsc_Tedge;
        rOsc_TStart_i <= '0';
        rOsc_ReqData_i <= '0';
        rOsc_DataAddr_i <= rOsc_DataAddr;
        rTx_i <= rTx;
        rTx_le_i <= '0';

        case (state) is
            when IDLE =>
                if pRx_av = '1' then
                    rTx_i <= pRx;  -- Preparo la respuesta pero no la latcheo
                    case to_integer(unsigned(pRx)) is
                        when COMMAND_OSC_TLEVEL =>
                            cnt_aux_i <= (others=>'0');
                            next_state <= OSC_TLEVEL;
                        when COMMAND_OSC_TEDGE =>
                            next_state <= OSC_TEDGE;
                        when COMMAND_OSC_DATA =>
                            if pOsc_Ready = '1' then
                                cnt_aux_i <= (others=>'0');
                                next_state <= OSC_DATA_INIT;
                            else
                                rTx_i <= std_logic_vector(to_unsigned(COMMAND_OSC_FAIL, rTx_i'length));
                                rTx_le_i <= '1';
                                if (pTx_busy = '1') then
                                    rTx_le_i <= '0';
                                    next_state <= OSC_RESP;
                                end if;
                            end if;
                        when COMMAND_OSC_START =>
                            rTx_le_i <= '1';
                            rOsc_TStart_i <= '1';
                            if (pTx_busy = '1') then
                                rTx_le_i <= '0';
                                next_state <= OSC_RESP;
                            end if;
                        when COMMAND_OSC_STATUS =>
                            cnt_aux_i <= (others=>'0');
                            next_state <= OSC_STATUS;
                        when others =>
                            rTx_i <= std_logic_vector(to_unsigned(COMMAND_OSC_FAIL, rTx_i'length));
                            rTx_le_i <= '1';
                            if (pTx_busy = '1') then
                                rTx_le_i <= '0';
                                next_state <= OSC_RESP;
                            end if;
                    end case;
                end if;
            when OSC_TLEVEL =>
                if pRx_av = '1' then
                    cnt_aux_i(0) <= '1'; 
                    if cnt_aux(0) = '1' then
                        cnt_aux_i(0) <= '0'; 
                        rOsc_TLevel_i(OSC_BITS-1 downto DATA_BITS) <= pRx;
                        rOsc_TLevel_i(DATA_BITS-1 downto 0) <= pipe1;
                        next_state <= IDLE;
                        rTx_le_i <= '1';
                        if (pTx_busy = '1') then
                            rTx_le_i <= '0';
                            next_state <= OSC_RESP;
                        end if;
                    end if;
                end if;
            when OSC_TEDGE =>  
                if pRx_av = '1' then
                    next_state <= IDLE;
                    rOsc_Tedge_i <= pRx(0);
                    rTx_le_i <= '1';
                    if (pTx_busy = '1') then
                        rTx_le_i <= '0';
                        next_state <= OSC_RESP;
                    end if;
                end if;

            when OSC_DATA_INIT =>        -- Envia COMMAND_OSC_DATA - 2*DEPTH_L - 2*DEPTH_H 
                if pTx_busy='0' then
                    rTx_le_i <= '1';
                    cnt_aux_i <= std_logic_vector(unsigned(cnt_aux)+to_unsigned(1,cnt_aux'length));
                    if unsigned(cnt_aux)=to_unsigned(1,cnt_aux'length) then
                        rTx_i <= SLV_DEPTH(DATA_BITS-1 downto 0);
                    elsif unsigned(cnt_aux)=to_unsigned(2,cnt_aux'length) then
                        rTx_i <= SLV_DEPTH(2*DATA_BITS-1 downto DATA_BITS);
                        next_state <= OSC_DATA;
                        cnt_aux_i <= std_logic_vector(to_unsigned(1,cnt_aux'length));
                        rOsc_DataAddr_i <= (others=>'0');
                        rOsc_ReqData_i <= '1';
                    end if;
                end if;

            when OSC_DATA =>            -- Envia las muestras
                if unsigned(cnt_aux) < to_unsigned(2*OSC_DEPTH+1,cnt_aux'length) then
                    if pOsc_DataAv = '1' then
                        rTx_i <= pOsc_Data;
                        if pTx_busy='0' then
                            rTx_le_i <= '1';
                            rOsc_DataAddr_i <= cnt_aux(cnt_aux'length-2 downto 0);
                            rOsc_ReqData_i <= '1';
                            cnt_aux_i <= std_logic_vector(unsigned(cnt_aux)+to_unsigned(1,cnt_aux'length));
                        else
                            next_state <= OSC_DATA_READY;
                        end if;
                    end if;
                else 
                    next_state <= IDLE;
                end if;

            when OSC_DATA_READY =>
                if pTx_busy='0' then
                    rTx_le_i <= '1';
                    rOsc_DataAddr_i <= cnt_aux(cnt_aux'length-2 downto 0);
                    rOsc_ReqData_i <= '1';
                    cnt_aux_i <= std_logic_vector(unsigned(cnt_aux)+to_unsigned(1,cnt_aux'length));
                    next_state <= OSC_DATA;
                end if;
                
            when OSC_RESP =>
                if pTx_busy='0' then
                    rTx_le_i <= '1';
                    next_state <= IDLE;
                end if;
            when OSC_STATUS =>
                if pTx_busy='0' then
                    rTx_le_i <= '1';
                    if cnt_aux(0)='0' then
                        cnt_aux_i(0)<='1';
                    else
                        rTx_i(0) <= pOsc_Ready;
                        rTx_i(rTx'length -1 downto 1) <= (others=>'0');
                        next_state <= IDLE;
                    end if;
                end if;
        end case;
    end process;

end architecture RTL;





