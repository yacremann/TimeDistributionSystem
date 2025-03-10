create_clock -period 25 clk 
derive_clocks -period 25
derive_clock_uncertainty

create_clock -period 12.5 clk_80_Mhz
derive_clocks -period 12.5
derive_clock_uncertainty