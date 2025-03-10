/*

    This module generates the trigger output signals.

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
    This module implements the trigger output circuit. It can be configured using
    the payload from a received data frame.
    
    The delay consists of two stages for the delay and pulse length. Therefore,
    a longer delay (more than the time between two laser pulses) is possible.
    
    An output pulse is generated if the (pulse_id mod divider) == reminder.
    
    The pulser is configured if the board_number and the channel_number of the
    data frame matches the board_number and the channel_number of the Trigger.
*/
module Trigger #(
        parameter int board_number   = 1,       // board address
        parameter int channel_number = 1        // channel address
    )(
        input logic                         clk,            // clock (determines the delays)
        input logic                         reset,          // active high
                                            
        input logic [$bits(payload_t)-1:0]  payload_i,      // payload for configuration
        input logic                         frame_tick_i,   // start input
        
        output logic                        pulse_o         // output pulse
    );
    
    logic trigger;
    payload_t payload;
    assign payload = payload_i;
    
    
    delay_data_t delay_data, delay_data_reg;
    assign delay_data = payload.data;
    // register for the delay data
    always_ff @(posedge clk) begin
	     if ((frame_tick_i) & (payload.payload_type == 8'd2))
		      if ((delay_data.board == 8'(unsigned'(board_number))) & (delay_data.channel == 8'(unsigned'(channel_number))))
                delay_data_reg <= delay_data;
    end

    logic unsigned [$bits(delay_data_reg.delay)-1:0]  delay1,  delay2;
    logic unsigned [$bits(delay_data_reg.length)-1:0] length1, length2;
    logic unsigned [$bits(delay_data_reg.modulus)-1:0] modulus;
    logic unsigned [$bits(delay_data_reg.divider)-1:0] divider;
    
    logic after_delay1, after_delay2, after_length1, after_length2;
    // calculate half delays. The first one is rounded up, the second down.
    assign delay1 = (delay_data_reg.delay >> 1) + $bits(delay_data_reg.delay)'(delay_data_reg.delay[0]);
    assign delay2 = (delay_data_reg.delay >> 1);
    
    // calculate half lengths. The first one is rounded up, the second down.
    assign length1 = (delay_data_reg.length >> 1) + $bits(delay_data_reg.length)'(delay_data_reg.length[0]);
    assign length2 = (delay_data_reg.length >> 1);
    
    assign modulus = delay_data_reg.modulus;
    assign divider = delay_data_reg.divider;
    
    // generate start tick with delay and modulus
    logic unsigned [63:0] pulse_id;
    assign pulse_id = payload.data[63:0];
	 
    logic pulse_id_tick;
    assign pulse_id_tick = frame_tick_i & (payload.payload_type == 8'h01); 
	
    
    
    // FSM to perform the division
    logic division_done;
    logic unsigned [63:0] reminder;
    logic unsigned [7:0] reminder_reg;
	 logic unsigned [63:0] pulse_id_reg;
	 logic pulse_id_tick_delayed;
	 
	 always_ff @(posedge clk) begin
        if (pulse_id_tick) pulse_id_reg <= pulse_id + 1;
		  pulse_id_tick_delayed <= pulse_id_tick;
    end
    LongDivision #(.WIDTH(64)) division ( // width of numbers in bits
        .clk(clk),
        .rst(reset),             
        .start(pulse_id_tick_delayed),   // start calculation
        .busy(),                 // calculation in progress
        .done(division_done),    // calculation is complete (high for one tick)
        .valid(),                // result is valid
        .dbz(),                  // divide by zero
        .a(pulse_id_reg),            // dividend (numerator)
        .b(64'(divider)),        // divisor (denominator)
        .val(),                  // result value: quotient
        .rem(reminder)           // result: remainder
    );
    // register for the result of the division:
    always_ff @(posedge clk) begin
        // we need to add 1, as the division comes one pulse later.
        if (division_done) reminder_reg <= reminder[7:0];
    end
    
    
    assign trigger = pulse_id_tick & (reminder_reg == modulus);
	 //assign trigger = pulse_id_tick;
	 
    // delay generators
    // use delay_data_reg.status[0] in start
    Delay delay_gen_1(
        .clk_i(clk),
        .reset_i(reset),
        .strobe_i(trigger & delay_data_reg.status[0]),
        .strobe_o(after_delay1),
        .delay(delay1)
    );
    
    Delay delay_gen_2(
        .clk_i(clk),
        .reset_i(reset),
        .strobe_i(after_delay1),
        .strobe_o(after_delay2),
        .delay(delay2)
    );
    
    Delay length_gen_1(
        .clk_i(clk),
        .reset_i(reset),
        .strobe_i(after_delay2),
        .strobe_o(after_length1),
        .delay(length1)
    );
    
    Delay length_gen_2(
        .clk_i(clk),
        .reset_i(reset),
        .strobe_i(after_length1),
        .strobe_o(after_length2),
        .delay(length2)
    );
    
	 
    // sort of RS flipflop to generate the output pulse
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            pulse_o <= 0;
        end else begin
            if (after_delay2  == 1) pulse_o <= 1;
            if (after_length2 == 1) pulse_o <= 0;
        end
    end
	 
	 
	 
    
endmodule
