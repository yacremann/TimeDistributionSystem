library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use IEEE.math_real.all;

-- seven segment driver: ust a lookup table.
-- (modified from https://www.fpga4student.com/2017/09/vhdl-code-for-seven-segment-display.html)
-- Yves Acremann, 17.3.2020
--

entity SevenSegment is
port(
	number   : in  unsigned(3 downto 0);
	LED_out  : out std_logic_vector(6 downto 0)
);
end SevenSegment;


architecture arch of SevenSegment is
begin
    process(number)
    begin
        case number is
            when "0000" => LED_out <= "1000000";   
            when "0001" => LED_out <= "1111001";
            when "0010" => LED_out <= "0100100";
            when "0011" => LED_out <= "0110000"; 
            when "0100" => LED_out <= "0011001"; 
            when "0101" => LED_out <= "0010010"; 
            when "0110" => LED_out <= "0000010"; 
            when "0111" => LED_out <= "1111000"; 
            when "1000" => LED_out <= "0000000";     
            when "1001" => LED_out <= "0010000"; 
            when "1010" => LED_out <= "0100000";
            when "1011" => LED_out <= "0000011";
            when "1100" => LED_out <= "1000110";
            when "1101" => LED_out <= "0100001";
            when "1110" => LED_out <= "0000110";
            when "1111" => LED_out <= "0001110";
        end case;
    end process;

end architecture;