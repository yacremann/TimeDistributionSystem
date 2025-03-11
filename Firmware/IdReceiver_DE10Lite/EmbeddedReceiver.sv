/*
    This programm will process the data from The Receiver board
    and will give out the pulse-id + Trigger.

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
    This programm will process the data from The Receiver board
    and will give out the pulse-id + Trigger.
    
    Make sure that the Boardnumber (parameter int board) has for each 
    board a unique number so the trigger output won't be overlapped 
    with a different board

    (Trigger channel is set to 1)

    Last updated: 17.5.2024

*/

module EmbeddedReceiver #(
        parameter int   board   = 2,       // board number (used to address the pulse generator
		  // parameters for 1MBit/s. 50 MHz
        parameter int Ki =     2,
        parameter int Kp =   500,
        parameter int K0 = 335544
    )(
        input logic         clk_i,        // clk
        input logic         reset_i,      // reset (active high)                     
                                            
        input logic         data_i,       // serial data stream
            
        output logic        error_o,      // error (8b10b or crc)
        
        output logic        trigger_o,    // trigger output
        output logic [63:0] pulse_id_o    // pulse ID. It is registered internally and only changes if a new ID is available.
    );
    
    logic word_tick;
    logic sampling_tick; // debugging
    logic [7:0] data_decoded;
    payload_t payload_frame_receiver;
	 logic error_8b10b;
	 logic error_crc;
    
    // from serialized data to decoded 8b10b output
    CDR_10b_8b #(
        // optimized for 50 MHz clock, 1 MBit/s
        .Ki(Ki),         
        .Kp(Kp),            
		  .K0(K0)   
    ) cdr_10b_8b (
        .clk(clk_i),                // reference clock
        .reset(reset_i),            // sync reset
        
        .serial_i(data_i),          // serial data in
        
        .word_tick_o(word_tick),    // word tick signal ('1' for one clock cycle)
        .data_o(data_decoded),      // decoded data out
        .comma_o(comma),            // 8b/10b comma detected
        .error_o(error_8b10b),       // 8b/10b error detected
		  .sampling_clk_o (sampling_tick)
    );
    
    // the frame receiver
    FrameReceiver FrameReceiver (
        .clk(clk_i),
        .reset(reset_i),
        
        // from the CDR / 8b/10b decoder:
        .word_tick_i(word_tick),        // word tick from the CDR ('1' in case of the high speed link)
        .comma_i(comma),                // 1 if comma
        .data_i(data_decoded),          // data from teh 8b/10b decoder
        .error_i(error_8b10b),          // error from the 8b/10b decoder
        
        .frame_tick_o(frame_tick),      // tick signal indicating reception of a valid frame
        .payload_o(payload_frame_receiver),            // the payload (valid until the next received frame)
        .error_o(error_crc)             // error from the CRC
    );
    
    // the trigger output
    // add the trigger 1
    Trigger #(
        .board_number(board),
        .channel_number(1)
    ) trigger_1 (
        .clk(clk_i),
        .reset(reset_i),
        .frame_tick_i(frame_tick),
        .payload_i(payload_frame_receiver),
        .pulse_o(trigger_o)
    );
	 
    
    
    // output register for the pulse-id:
    payload_t payload_reg;
    
    always_ff @(posedge clk_i) begin
        if (payload_frame_receiver.payload_type == 8'h01)
            payload_reg <= payload_frame_receiver;
    end
    assign pulse_id_o = payload_reg.data[63:0];
	 assign error_o = error_8b10b | error_crc;
	 
    
endmodule


