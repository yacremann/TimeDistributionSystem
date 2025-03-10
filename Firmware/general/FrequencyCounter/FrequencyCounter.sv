/*

    This module implements a frequency counter used to monitor the
    frequency of the laser oscillator.

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

module FrequencyCounter #(
        parameter int WAIT_TIME = 40000000
    )(
        input logic clk_80MHz,    // laser oscillator frequency
        input logic clk_40MHz,    // fixed crystal oscillator
        input logic reset,        // reset (active high, in 40 MHz clock domain)
        output logic unsigned [31:0] frequency // output frequency in Hz, in 40 MHz clock domain
    );
    
    // data path
    
    logic [31:0] gray_value;
    logic enable_reg;
    logic [31:0] gray_value_40;
    logic [31:0] gray_value_40_reg;
    
    logic reset_counter_80;
    logic reset_counter_40;
    
    gray_counter #(
        .DATA_WIDTH(32)
    ) freq_counter (
        .clk(clk_80MHz),
        .en(1),
        .rst(reset_counter_80),
        .count_out(gray_value)
    );
   
    // sync. the gray counter
    
    synchronizer#(
        .DATA_WIDTH(32)
    ) gray_synchronizer (
        .clk_src(clk_80MHz),
        .clk_dst(clk_40MHz),
        .data_i(gray_value),
        .data_o(gray_value_40)
    );
    
    // register of the counter
    always_ff @(posedge clk_40MHz) begin
        if (enable_reg)
             gray_value_40_reg <= gray_value_40;
    end
    
    // convert to binary:
    gray2bin #(
        .DATA_WIDTH(32)
    ) gray_to_bin (
        .gray_in(gray_value_40_reg),
        .binary_out(frequency)
    );
    
    // clock domain crossing for the reset of the counter:
    synchronizer #(
        .DATA_WIDTH(1)
    ) sync_reset (
        .clk_src(clk_40MHz),
        .clk_dst(clk_80MHz),
        .data_i(reset_counter_40),
        .data_o(reset_counter_80)
    );
    
    // CONTROLLER (40 MHz domain)
    
    logic unsigned [31:0] counter_40Mhz;
    
    typedef enum logic [1:0] {
        IDLE,
        RESET,
        WAIT,
        READ
    } state_t;
    state_t state_d, state_q;
    
    always_comb begin
        state_d = state_q;
        
        case (state_q)
        
            IDLE:
                state_d = RESET;
        
            RESET: 
                state_d = WAIT;
                
            WAIT: 
                if (unsigned'(WAIT_TIME) <= counter_40Mhz)
                    state_d = READ;
                    
            READ:
                state_d = IDLE;
                    
            default: state_d = IDLE;
            
        endcase
    end
    
    always_ff @(posedge clk_40MHz) begin
        if (reset == 1)
            state_q <= IDLE;
        else
            state_q <= state_d;
    end
    
    always_ff @(posedge clk_40MHz) begin
        if (state_q == WAIT) begin
            counter_40Mhz <= counter_40Mhz + 1;
        end else begin
            counter_40Mhz <= 0;
        end
    end
    
    assign reset_counter_40 = (state_q == RESET);
    assign enable_reg = (state_q == READ);
    
endmodule


// for testing:
module TestFrequencyCounter(
    input logic clk_80MHz,
    input logic clk_40MHz,
    input logic reset,
    output logic unsigned [31:0] frequency
);

    FrequencyCounter#(.WAIT_TIME(100)) the_counter (
        .clk_80MHz(clk_80MHz),
        .clk_40MHz(clk_40MHz),
        .reset(reset),
        .frequency(frequency)
    );

endmodule

