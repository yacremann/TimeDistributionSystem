/*

    This module implements the state machine to communicate through an SPI
    interface

    Copyright (C) 2022, Yves Acremann, ETH Zurich

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
    Reads / writes a number of bits from/to the SPI simultaneously.
    This SPI interface is designed to handle the full clock rate and
    to work with various number of bits.
*/

module SPI_RW #(
    parameter max_length = 8+16+64 // we support a 64 bit read cycle
)(
    input  logic clk,
    input  logic reset,
    
    input  logic start,
    output logic ready,
    input  logic unsigned [7:0] num_of_bits,
    
    input  logic [max_length-1:0] data_to_send,  // must stay valid until not idle.
    output logic [max_length-1:0] data_received, // valid once idle
    
    output logic sck,
    output logic mosi,
    input  logic miso,
    output logic cs
);

    // tick generator:
    logic tick;
    logic unsigned [2:0] tick_counter;
    always_ff @(posedge clk) begin
        if (reset == 1)
            tick_counter <= 1;
        else
            tick_counter <= tick_counter + 1;
    end
    assign tick = (tick_counter == 3'b00);

    // data path: Shift registers
    logic[max_length-1:0] rx_reg;
    logic[max_length-1:0] tx_reg;
    logic en;
    logic load;
    logic store;
    
    
    // Reg for TX: update the data at the neg edge:
    always_ff @(posedge clk) begin
    
        if (load == 1) begin
            tx_reg <= data_to_send;
        end
    end
	 logic mosi_int;
    assign mosi_int = tx_reg[num_of_bits-1-bit_counter_q];
    
    
    // Reg for RX:
	 logic miso_int;
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            rx_reg <= 0;
            data_received <= 0;
        //end else if ((en == 1) & (tick == 1)) begin
        end else if ((state_q == COUNT) & (tick == 1)) begin
            rx_reg[num_of_bits-1-bit_counter_q] <= miso_int;
        end
        if ((store == 1) & (tick == 1))
            data_received <= rx_reg;
    end
    
    
    
    // FSM:
    // states of the FSM
    typedef enum logic [2:0] {
        READY,
        CS_DOWN,
        SCK,
        COUNT,
        DONE
    } state_t;
    
    state_t state_d, state_q;
    logic unsigned [7:0] bit_counter_d, bit_counter_q;
    
    
    // next state logic
    always_comb begin
        state_d = state_q;
        bit_counter_d = 0;
        case (state_q)
            READY:
                if (start == 1) begin
                    state_d = CS_DOWN;
                end
                
            CS_DOWN:
                state_d = SCK;
                
            SCK:
                begin
                    state_d = COUNT;
                    bit_counter_d = bit_counter_q;
                end
            
            COUNT:
                if (bit_counter_q < num_of_bits-1) begin
                    bit_counter_d = bit_counter_q + 1;
                    state_d = SCK;
                end else
                    state_d = DONE;
            DONE:
                if (start == 0)
                    state_d = READY;
                    
            default: state_d = READY;
        endcase
    end
    
    // flipflop:
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            state_q <= READY;
            bit_counter_q <= 0;
        end else if (tick == 1) begin
        //end else begin
            state_q <= state_d;
            bit_counter_q <= bit_counter_d;
        end
    end
    
    
    // output decoder:
	 logic cs_int;
	 logic sck_int;
	  
    assign ready = (state_q == READY);
    assign load = ((state_q == READY) & (start == 1));
    //assign en = (state_q == COUNT);
    assign store = (state_q == DONE);
    assign cs_int = !((state_q == COUNT) | (state_q == CS_DOWN) | (state_q == SCK));
    
    
    // output clock gating:
    //assign sck = ((tick_counter[1] == 1)  & (state_q == COUNT));
    //assign sck = clk_int & (state_q == COUNT);
    assign sck_int = (state_q == COUNT);
	 
	 // for stability, we need to re-clock the outputs:
	 always_ff @(posedge clk) begin
		if (reset == 1) begin
			sck <= 0;
			cs <= 1;
			mosi <= 0;
			miso_int <= 0;
		end else begin
			sck <= sck_int;
			cs <= cs_int;
			mosi <= mosi_int;
			miso_int <= miso;
		end
	 end

endmodule
