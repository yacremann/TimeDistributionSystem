/*

    This module implements the delay generator.

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

/*
    Delay generator for the time distribution system. It implements a one-stage delay
    based on a counter. The delay is set by the delay input in clock cycles. A start
    signal at the strobe_i input causes the counter to wait for a specified number of
    cycles. It then generates one clock cycle pulse at the strobe_o output.
*/

module Delay(
    input  logic clk_i,     // reference clock
    input  logic reset_i,   // reset input (active high)
    
    input  strobe_i,        // strobe input (start pulse)
    output strobe_o,        // pulse output
        
    input logic unsigned [31:0] delay // delay in clock cycles
);

    typedef enum logic{
        READY,
        COUNT
    } state_t;
    
    state_t state_d, state_q;
    logic unsigned [31:0] counter_d, counter_q;
    
    // state flipflop
    always_ff @(posedge clk_i) begin
        if (reset_i == 1) begin
            state_q   <= READY;
            counter_q <= 'd0;
        end else begin
            state_q   <= state_d;
            counter_q <= counter_d;
        end
    end
    
    // next state logic:
    always_comb begin
        state_d   = state_q;
        counter_d = 'd0;
        
        case (state_q)
            READY: if (strobe_i == 1) state_d = COUNT;
            
            COUNT: 
                if (counter_q < delay) begin
                    counter_d = counter_q + 'd1;
                end else begin
                    state_d = READY;
                end
        endcase
    end
    
    assign strobe_o = (counter_q == delay);

endmodule
