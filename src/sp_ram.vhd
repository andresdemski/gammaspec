
library ieee;
use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.functions.all;
entity sp_ram is
	generic(
		PORT_BITS : natural :=32;  
		LENGTH : natural := 4*1024    
	);
	port (
        pDi : in std_logic_vector(PORT_BITS-1 downto 0);
        pWe : in std_logic;
        pAddr : in std_logic_vector(log2(LENGTH)-1 downto 0);
        pDo : out std_logic_vector(PORT_BITS-1 downto 0);
        pEn : in std_logic;
        pClk : in std_logic
	);
end entity sp_ram;

architecture RTL of sp_ram is
    type ram_t is array (0 to LENGTH-1) of std_logic_vector (PORT_BITS-1 downto 0);
    signal mem : ram_t:= (others => (others => '0'));
    signal rDo : std_logic_vector (PORT_BITS-1 downto 0):= (others =>'0');
    -- attribute ram_style: string;
    -- attribute ram_style of mem : signal is "block";

begin
    pDo <= rDo;
    process (pClk)
    begin
        if rising_edge(pClk) then
            if pEn = '1' then
                rDo <= mem(conv_integer(pAddr));
                if pWe = '1' then 
                    mem(conv_integer(pAddr)) <= pDi;
			    end if;
            end if;
        end if; 
    end process;

end RTL;





    -- process (pClk)
    --     variable ridx : std_logic_vector (p1Raddr'length-1 downto 0):= (others=>'0');
    --     variable widx : std_logic_vector (p1Raddr'length-1 downto 0):=(others=>'0');
    -- begin
    --     if rising_edge(pClk) then
    --         if pEn = '1' then
    --             for i in 0 to PORT2_BITS/PORT1_BITS-1 loop
    --                 ridx := pRaddr & std_logic_vector(to_unsigned(i,p1Raddr'length-pRaddr'length));
    --                 pDo((i+1)*PORT1_BITS-1 downto (i*PORT1_BITS)  ) <= mem(to_integer(unsigned(ridx)));
    --                 if pWe = '1' then 
    --                     widx := pWaddr & std_logic_vector(to_unsigned(i,p1Raddr'length-pRaddr'length));
    --                     mem(to_integer(unsigned(widx))) <= pDi((i+1)*PORT1_BITS-1 downto (i*PORT1_BITS)  );
    --                 end if;
    --             end loop;
    --         end if;
    --     end if; -- Pasar esto a como dice el xst y dejarme de joder con unsigned. warning: Index value(s) does not match array range, simulation mismatch. y no termina la sintesis
    -- end process;

    -- process (p1Clk)
    -- begin
    --     if rising_edge(p1Clk) then
    --         if p1En = '1' then
    --             p1Do <= mem(to_integer(unsigned(p1Raddr)));
    --         end if;
    --     end if;
    -- end process;


