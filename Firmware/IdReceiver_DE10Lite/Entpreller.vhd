-- This is the most simple VHDL example: Nothing will happen


-- Declaration of the libraries used:
library ieee;
-- std_logic and std_logic_vector
use ieee.std_logic_1164.all;
-- signed, unsiged and integer (including the conversion functions)
use IEEE.NUMERIC_STD.all;





-- Here we define the inputs / outputs
-- (these are the only signale we will use for the lecture)
entity Entpreller is
port(
  clk    : in std_logic;       -- 50 HMz clock
  key    : in std_logic;      -- Buttons
  pulse  : out std_logic  
);
end Entpreller;




-- The architecture statement describes the actual functionality
architecture arch of Entpreller is
    type Zustand_t is (warten,puls,count,wait_low,count_low);
    signal zustand : Zustand_t := warten;
    signal zaehlen : integer range 0 to 500001 :=0;
    signal key_sync : std_logic_vector(1 downto 0);

begin

    process(key)
    begin
        if rising_edge(clk) then
            pulse <= '0';
            case zustand is 
                when warten =>
                    if key_sync(1) = '0' then
                        zustand <= puls;
                    end if;
                
                when puls =>
                    pulse <= '1';
                    zustand <= count;
                    zaehlen <= 0;
                
                when count =>
                    zaehlen <= zaehlen + 1;
                    if zaehlen >= 500000 then
                        zaehlen <= 0;
                        zustand <= wait_low;
                    end if;
                
                when wait_low =>
                    if key_sync(1) = '1' then
                        zustand <= count_low;
                    end if;
                    zaehlen <= 0;
                
                when count_low =>
                    zaehlen <= zaehlen + 1;
                    if zaehlen >= 500000 then
                        zaehlen <= 0;
                        zustand <= warten;
                    end if;
            end case;
        end if;
    end process;
    
    process(clk)
    begin
      if rising_edge(clk) then
        key_sync(0) <= key;
        key_sync(1) <= key_sync(0);
      end if;
    end process;

end arch;