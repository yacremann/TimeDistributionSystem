/*

    Synchronous version (using a clock signal) of the 
    Alexander phase detector

    Copyright (C) 2025, ETH Zurich, Yves Acremann, D-PHYS; Laboratory for Solid State Physics; Eduphys

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.

*/

module AlexanderDetectorSync(
    input  logic clk,
    input  logic bit_clk,
    
    input  logic din,       // serial data stream
    output logic early,    // '1' if the sampling clock is early
    output logic late,     // '1' if the sampling clock is late
    output logic dout      // the re-sampled data stream
);
    logic ff1;
    logic ff2;
    logic ff3;
    logic ff4;
    
    // generate single shot signas for the rising and fallind edges of
    // the bit clk:
    logic bit_clk_delayed;
    logic bit_tick_rise;
    logic bit_tick_fall;
    always_ff @(posedge clk) begin
        bit_clk_delayed <= bit_clk;
    end
    assign bit_tick_rise = bit_clk & !bit_clk_delayed;
    assign bit_tick_fall = !bit_clk & bit_clk_delayed;
    
    // the actual phase detector:
    always_ff @(posedge clk) begin
        if (bit_tick_rise == 1) begin
            ff1 <= din;
            ff2 <= ff1;
            ff4 <= ff3; 
        end
        
        if (bit_tick_fall == 1)
            ff3 <= din; 
    end

    assign late  = ff2 ^ ff4;
    assign early = ff1 ^ ff4;
    assign dout  = ff2;
endmodule
