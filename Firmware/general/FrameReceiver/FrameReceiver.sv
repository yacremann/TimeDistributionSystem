/*

    This code describes the pulse-id receiver of the time distribution system.

    Copyright (C) 2025  Yves Acremann, ETH Zurich

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

// `include "data_frames.sv"

/*
    Pulse-ID reciever:
    
    This module recieves the data frame and checks the CRC
        
    The CRC uses the polynom 0x8005, no inversion, init 0
    ("CRC-16/BUYPASS")
        
    The data frames are separated by comma symbols (K28.1)
    
    Yves Acremann, 15.7.2021
*/
module FrameReceiver (
    input logic                         clk,
    input logic                         reset,
    
    // from the CDR / 8b/10b decoder:
    input logic                         word_tick_i, // word tick from the CDR ('1' in case of the high speed link)
    input logic                         comma_i,     // 1 if comma
    input logic [7:0]                   data_i,      // data from teh 8b/10b decoder
    input logic                         error_i,     // error from the 8b/10b decoder
    
    output logic                        frame_tick_o, // tick signal indicating reception of a valid frame
    output logic [$bits(payload_t)-1:0] payload_o,    // the payload (valid until the next received frame)
    output logic                        error_o       // error from the CRC
);

    // DATA PATH:
    /////////////
    
    // the input is valid if we don't have a comma or an error
    logic  input_valid;
    assign input_valid = !comma_i & !error_i;
    
    frame_t frame;
    localparam NUM_BITS_COUNTER = $clog2($bits(frame_t)/8); //6;
    logic unsigned [NUM_BITS_COUNTER-1:0] byte_counter;
    logic enable_frame_register;         // enable receiving data (when data is valid)
    logic reset_frame_register;
    logic frame_ready;                   // true after the frame has been received
    
    always_ff @(posedge clk) begin
        if (reset_frame_register == 1) begin     // when idle: reset the byte counter
            byte_counter <= 0;
        end else if ((enable_frame_register == 1) & (word_tick_i == 1)) begin
            byte_counter <= byte_counter + 1;   
            frame[($bits(frame_t)-byte_counter*8-1)-:8] <= data_i;  // record the data byte
        end
    end
    assign frame_ready = (byte_counter >= NUM_BITS_COUNTER'($bits(frame_t)/8));

    // CRC generator: It is directly connected to the data input
    logic [15:0] crc;
    crc_calc #(
        .POLY(64'h8005),
        .CRC_SIZE(16),
        .DATA_WIDTH(8),
        .INIT(64'h0000),
        .REF_IN(0),
        .REF_OUT(0),
        .XOR_OUT(64'h0)
    ) crc_calculator(
		  .clk_i(clk),
        .rst_i(reset),
        .soft_reset_i(reset_frame_register),
		  .valid_i(enable_frame_register & word_tick_i),
        .data_i(data_i),
        .crc_o(crc)
    );
    
    // determine if the frame is valid:
    logic frame_valid;
    assign frame_valid = (crc == 0);
    
    // output register for the pulse-id:
    payload_t payload_reg;
    logic register_payload;
    always_ff @(posedge clk) begin
        if (register_payload == 1)
            payload_reg <= frame.payload;
    end
    assign payload_o = payload_reg;
    
    
    // CONTROLLER:
    //////////////
    typedef enum logic [2:0] {
        CLEAR,          // reset the byte counter and CRC
        WAIT_FREAME,    // wait for a frame to be received
        VALIDATE,       // validate the frame (check frame type and CRC)
        ACCEPT,         // Store the pulse-id and trigger the pulser
        FRAME_TICK,     // generate the frame tick signal
        WAIT_COMMA      // wait for the next comma
    } state_t;
    state_t state_d, state_q;
    
    always_comb begin
        state_d = state_q;
        
        
        case (state_q)
        
            CLEAR:
                if (input_valid == 1)
                    state_d = WAIT_FREAME;
        
            WAIT_FREAME: 
                if (frame_ready == 1) 
                    state_d = VALIDATE;
                
            VALIDATE: 
                if (frame_valid == 1)
                    state_d = ACCEPT;
                else 
                    state_d = CLEAR;
                    
            ACCEPT:
                
                state_d = FRAME_TICK;
                
            FRAME_TICK:
                state_d = WAIT_COMMA;
                
            WAIT_COMMA:
                if (input_valid == 0)
                    state_d = CLEAR;
                
            default: state_d = CLEAR;
            
        endcase
    end
    
    
    
    always_ff @(posedge clk) begin
        if (reset == 1)
            state_q <= CLEAR;
        else
            state_q <= state_d;
    end
    
    // output decoder
    assign reset_frame_register  = (state_q == CLEAR) & (input_valid == 0);
    assign enable_frame_register = ((state_q == WAIT_FREAME) | (state_q == CLEAR)) & (input_valid == 1);
    assign frame_tick_o          = (state_q == FRAME_TICK);
    assign register_payload      = (state_q == ACCEPT);
    assign error_o               = (state_q == VALIDATE) & (frame_valid == 0);

endmodule
