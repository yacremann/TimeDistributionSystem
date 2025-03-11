/*

    Slow transmitter (between the receiver and the frame grabber / digitizer) of the 
    time distribution system

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


module SlowTransmitter2 #(
    parameter int bit_clk_divider = 80      // transmit 1 bit every 80 clock cycles
)(
    input logic clk,                        // clock
    input logic reset,                      // sync. reset
    
    input [$bits(payload_t)-1:0] payload_i, // data to be transmitted
    input logic frame_tick_i,               // push data into the FIFO
    
    output logic serial_o,                  // serial data output
    output logic idle                       // '1' if idle
);


    payload_t data_from_fifo, data_from_fifo_reg;
    logic pop_fifo;
    logic fifo_empty;
    logic transmitter_ready;
	 
	 logic word_tick;
	 
	 logic [9:0] data_10b;
	 logic unsigned [3:0] bit_select;
    
    // the fifo at the input
    fifo_v3 #(
        .DATA_WIDTH($bits(payload_t)),
		  .DEPTH(16)
    ) input_fifo (
        .clk_i(clk),
        .rst_ni(!reset),
        .flush_i(0),
        .testmode_i(0),
        // status flags
        .full_o(),
        .empty_o(fifo_empty),
        .usage_o(),
        // as long as the queue is not full we can push new data
        .data_i(payload_i),
        .push_i(frame_tick_i),
        // as long as the queue is not empty we can pop new elements
        .data_o(data_from_fifo),
        .pop_i(pop_fifo)
    );
    assign pop_fifo = transmitter_ready & (!fifo_empty);
    
    
    logic start_transmission;
    always_ff @(posedge clk) begin
        if (pop_fifo) begin
            data_from_fifo_reg <= data_from_fifo;
        end
        start_transmission <= pop_fifo;
    end
	 
	 
	 

    PayloadTransmitter payloadTransmitter(
        .clk(clk),
        .reset(reset),
        
        .valid(start_transmission),
        .ready(transmitter_ready),
        .payload(data_from_fifo_reg),       // the payload to be transmitted
		  
        .output_tick(word_tick),
        .data_10b(data_10b)     // data 8b/10b encoded, to the serializer
    );
	 
	 // the serializer:
	 // bit tick generator
    logic unsigned [15:0] tick_counter;
    always_ff @(posedge clk) begin
        if (reset == 1)
            tick_counter <= 0;
        else if (tick_counter < 16'(bit_clk_divider-1))
            tick_counter <= tick_counter + 1;
        else
            tick_counter <= 0;
    end
    
    // bit select counter (also generates the byte tick)
    logic [9:0] data_10b_reg;
    always_ff @(posedge clk) begin
        if (reset == 1)
            bit_select <= 0;
        else if (tick_counter == 0)
            if (bit_select < 9)
                bit_select <= bit_select + 1;
            else begin
                bit_select <= 0;
                data_10b_reg <= data_10b;
            end
    end
    assign word_tick = bit_select == 9 & tick_counter == 0;
	 
	 // output mux & register (before we go onto the wire!)
    logic transmit_reg;
    always_ff @(posedge clk) begin
        transmit_reg <= data_10b_reg[bit_select];
    end
    assign serial_o = transmit_reg;
	 
	 
	 

endmodule
