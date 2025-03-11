/*

    This module implements the state machine to transmit one data frame over
    the serial link (part of the time distribution system)

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
    Transmits a data frame (defined in general/data_frames.sv).
    It uses a ready/valid hand shaking interface and can transmit any
    payload described in general/data_rames.sv.

    The CRC uses the polynom 0x8005, no inversion, init 0
    ("CRC-16/BUYPASS")
        
    The data frames are separated by comma symbols (K28.1)
*/
module PayloadTransmitter(
        input  logic clk,
        input  logic reset,
        
        input  logic valid,
        output logic ready,
        input  logic [$bits(payload_t)-1:0] payload,   // the payload to be transmitted
		  
        input  logic output_tick,       // '1' for one clock cycle 
        output logic [9:0] data_10b     // data 8b/10b encoded, to the serializer
    );
    
    // DATA PATH
    ////////////
    
    // data to be sent for transmitting the K28.1 comma symbol
    localparam K28_1_data = 8'b00111100;
    localparam NUM_BYTES_BITCOUNTER = $clog2($bits(frame_t)/8); //6;

    // type for selecting the output bytes:
    typedef enum logic [1:0] {
        COMMA,
        DATA,
        CRC_H,
        CRC_L
    } select_frame_data_t;
    
    logic clear_crc;                              // clear the crc calculator
    logic run_crc;                                // run the crc calculation
    select_frame_data_t select_frame_byte;        // select the output data (comma, data, crc)
    logic unsigned [NUM_BYTES_BITCOUNTER-1:0] select_pulseid_byte_q;   // select the byte of the payload (before crc)
    logic unsigned [NUM_BYTES_BITCOUNTER-1:0] select_pulseid_byte_d;   // (used by the controller FSM)
    
    logic [7:0] payload_byte;     // the frame byte without crc
    // select the payload byte:
    assign payload_byte = payload[$bits(payload_t)-select_pulseid_byte_q*8-1 -:8];
    
    // CRC generator: It is directly connected to the output of the payload mux
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
        .soft_reset_i(clear_crc),
        .valid_i(run_crc),
        .data_i(payload_byte),
        .crc_o(crc)
    );
    
    logic [7:0] data;
    logic comma;
    // output mux (selects comma, data bytes and CRC bytes)
    always_comb begin
        data = K28_1_data;
        comma = 0;
        case (select_frame_byte)
            COMMA: begin
                    data = K28_1_data;
                    comma = 1;
                end
            DATA : data = payload_byte;
            CRC_H: data = crc[15:8];
            CRC_L: data = crc[7:0];
            default:  begin
                    data = K28_1_data;
                    comma = 0;
                end
        endcase
    end
	 
	 // very important: the tick needs to be aligned with the data!
    logic output_tick_q;
	 always_ff @(posedge clk) begin
	     output_tick_q <= output_tick;
	 end
    // 8b/10b encoding
    Encode_8b10b encoder8b10b(
        .clk(clk),
        .reset(reset),
        .io_tick(output_tick_q),
        .io_comma(comma),
        .io_din(data),
        .io_dout(data_10b)
    );
    
    
    // CONTROLLER
    /////////////
    
    typedef enum logic [3:0] {
        READY,           
        SEND_PAYLOAD,       // send the payload
        SEND_CRC_H,         // send the MSB of the CRC
        SEND_CRC_L,         // send the LSB of the CRC
        SEND_COMMA          // send a comma
    } state_t;
    state_t state_d, state_q;
    
    
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            state_q <= READY;
            select_pulseid_byte_q <= 0;
        end else begin
            state_q <= state_d;
            select_pulseid_byte_q <= select_pulseid_byte_d;
        end
    end
    
    // next state logic
    always_comb begin
        state_d = state_q;
        select_pulseid_byte_d = select_pulseid_byte_q;
        
        case (state_q)
            
            READY:
                begin           
				    if (valid == 1) state_d = SEND_PAYLOAD; // wait for valid data
                    select_pulseid_byte_d = 0;
                end
            
            SEND_PAYLOAD:    
				    if (output_tick)
				        if (select_pulseid_byte_q < NUM_BYTES_BITCOUNTER'($bits(payload_t)/8-1))   // send the data bytes and calculate the CRC
                        select_pulseid_byte_d = select_pulseid_byte_q+1;
                    else
                        state_d = SEND_CRC_H;
                                
            SEND_CRC_H:      
				    if (output_tick)
					     state_d = SEND_CRC_L;
            
            SEND_CRC_L:      
				    if (output_tick) 
					     state_d = SEND_COMMA;
            
            SEND_COMMA:      
				    if (output_tick)
					     state_d = READY;
            
            default: 
				    state_d = READY;
        endcase
    end
    
    // output decoder:
    always_comb begin
        case (state_q)
            SEND_PAYLOAD: select_frame_byte = DATA;
            SEND_CRC_H:   select_frame_byte = CRC_H;
            SEND_CRC_L:   select_frame_byte = CRC_L;
            default:      select_frame_byte = COMMA;
        endcase
    end
    assign clear_crc = (state_q == READY);
    assign run_crc   = (state_q == SEND_PAYLOAD) & (output_tick);
    assign ready     = (state_q == READY);

endmodule
