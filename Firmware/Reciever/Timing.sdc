create_clock -name clk_40Mhz -period 25 [get_ports clk_40Mhz] 
derive_clocks -period 25
derive_clock_uncertainty

create_clock -name word_clk -period 12.5 [get_ports word_clk]
derive_clocks -period 12.5
derive_clock_uncertainty

set_input_delay -clock word_clk 0 [get_ports deserialized*]