/*

    Test bench (systemverilog part) of the test bench. It is used by
    the cocotb test bench.

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

module SlowTransmitter2_tb(
    input logic clk,                        // clock
    input logic reset,                      // sync. reset
    
    input [31:0] data_i,                // data to be transmitted
    input logic frame_tick_i,               // push data into the FIFO
    
    output logic serial_o                   // serial data output
);


    payload_t payload; 
    assign payload [ 31: 0] = data_i; 
    assign payload [ 63:32] = data_i; 
    assign payload [ 95:64] = data_i; 
    assign payload [127:96] = data_i; 

    SlowTransmitter2 #(
        .bit_clk_divider(5)      // transmit 1 bit every 5 clock cycles
    )transmitter(
        .clk(clk),                        // clock
        .reset(reset),                      // sync. reset
        
        .payload_i(payload),              // data to be transmitted
        .frame_tick_i(frame_tick_i),               // push data into the FIFO
        
        .serial_o(serial_o),                  // serial data output
        .idle()                       // '1' if idle
    );

endmodule
