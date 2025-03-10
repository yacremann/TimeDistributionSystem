/*

    Test bench to test the slow transmitter with a slow receiver
    (for getting the PID parameters working)
    This code is used together with the TestTogether.py test bench
    using Cocotb and Verilator

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

module AllConnected(
    input logic clk,                    // clock
    input logic reset,                  // sync. reset
    
    input [31:0] data_i,                // data to be transmitted
    input logic frame_tick_i            // push data into the FIFO
);

    logic serial;
    
    payload_t payload; 
    assign payload [ 31: 0] = data_i; 
    assign payload [ 63:32] = data_i; 
    assign payload [ 95:64] = data_i; 
    assign payload [127:96] = data_i; 

    SlowTransmitter2 #(
        .bit_clk_divider(250)              // transmit 1 bit every 50 clock cycles
    )transmitter(
        .clk(clk),                        // clock
        .reset(reset),                    // sync. reset
        
        .payload_i(payload),              // data to be transmitted
        .frame_tick_i(frame_tick_i),      // push data into the FIFO
        
        .serial_o(serial),                // serial data output
        .idle()                           // '1' if idle
    );
    
    CDR_10b_8b #(
        .Ki(2),                   // parameters for the PI controller of the CDR loop
        .Kp(5000),                // here: optimized for 250 HMz clock
	    .K0(67118)                // offset for the bit clock frequency (1 Mbit/s)
    ) cdr(
        .clk(clk),
        .reset(reset),
    
        .serial_i(serial),
    
        .word_tick_o(),
        .data_o(),
        .comma_o(),
        .error_o(),
        .sampling_clk_o()
    );

endmodule
