
library ieee;
use ieee.std_logic_1164.all;
-- use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;

use work.functions.all;
entity ram is
	generic(
		PORT1_BITS : natural :=8;  
        PORT2_BITS : natural := 16;
		LENGTH : natural := 2*1024    
	);
	port (
        -- p1Di : in std_logic_vector (PORT1_BITS-1 downto 0);
        -- p1We : in std_logic;
        p1Do : out std_logic_vector(PORT1_BITS-1 downto 0);
        p1Addr : in std_logic_vector(log2(LENGTH)-1 downto 0);
        p1En : in std_logic;
        p1Clk : in std_logic;

        p2Di : in std_logic_vector(PORT2_BITS-1 downto 0);
        p2We : in std_logic;
        p2Addr : in std_logic_vector(log2(LENGTH*PORT1_BITS/PORT2_BITS)-1 downto 0);
        p2Do : out std_logic_vector(PORT2_BITS-1 downto 0);
        p2En : in std_logic;
        p2Clk : in std_logic
	);
end entity ram;

architecture RTL of ram is
    type ram_t is array (0 to LENGTH-1) of std_logic_vector (PORT1_BITS-1 downto 0);
    signal mem : ram_t:= (others => (others => '0'));
    -- shared variable mem : ram_t:= (others => (others => '0'));
    attribute ram_style: string;
    attribute ram_style of mem : signal is "block";

begin
    -- ANDA EN SPARTAN 6 PERO NO EN SPARTAN 3. Y en distributed no entra :(

    process (p1Clk)
    begin
        if rising_edge(p1Clk) then
            if p1En = '1' then
                -- if p1We = '1' then
                --     mem(conv_integer(p1Addr)) := p1Di;
                -- else
                    p1Do <= mem(conv_integer(p1Addr));
                -- end if;
            end if;
        end if; 
    end process;

    process (p2Clk)
    begin
        if rising_edge(p2Clk) then
            if p2En = '1' then
                for i in 0 to (PORT2_BITS/PORT1_BITS)-1 loop
                    p2Do((i+1)*PORT1_BITS-1 downto i*PORT1_BITS) <= mem(conv_integer(p2Addr & conv_std_logic_vector(i,log2(PORT2_BITS/PORT1_BITS))));
                    if p2We = '1' then 
                        mem(conv_integer(p2Addr & conv_std_logic_vector(i,log2(PORT2_BITS/PORT1_BITS)))) <= p2Di((i+1)*PORT1_BITS-1 downto i*PORT1_BITS);
						  end if;
                    
                end loop;
            end if;
        end if; 
    end process;

end RTL;





    -- process (p2Clk)
    --     variable ridx : std_logic_vector (p1Raddr'length-1 downto 0):= (others=>'0');
    --     variable widx : std_logic_vector (p1Raddr'length-1 downto 0):=(others=>'0');
    -- begin
    --     if rising_edge(p2Clk) then
    --         if p2En = '1' then
    --             for i in 0 to PORT2_BITS/PORT1_BITS-1 loop
    --                 ridx := p2Raddr & std_logic_vector(to_unsigned(i,p1Raddr'length-p2Raddr'length));
    --                 p2Do((i+1)*PORT1_BITS-1 downto (i*PORT1_BITS)  ) <= mem(to_integer(unsigned(ridx)));
    --                 if p2We = '1' then 
    --                     widx := p2Waddr & std_logic_vector(to_unsigned(i,p1Raddr'length-p2Raddr'length));
    --                     mem(to_integer(unsigned(widx))) <= p2Di((i+1)*PORT1_BITS-1 downto (i*PORT1_BITS)  );
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


