/*

    This module implements a simple pulse extender for the time distribution system.

    Copyright (C) 2025, Yves Acremann, ETH Zurich

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

/*
    Extends an input pulse to 1s. The input can be asynchroneous to the clock.
    This module is designed for driving the status LEDs.
*/

module pulse_extender(
    input  logic clk,           // 80 MHz clock
    input  logic pulse_in,
    output logic pulse_out
);
    
    logic unsigned [25:0] time_counter;
    
    always_ff @(posedge clk) begin
        if (pulse_in == 1)
            time_counter <= 26'd80000000;
        else if (time_counter != 0)
            time_counter <= time_counter - 1;
    end
    
    assign pulse_out = (time_counter != 0);

endmodule
