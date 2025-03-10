/*

    This module implements the state machine to read and write the MRAM chip 
    MR25H128 (Everspin)

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
    Reads and writes the pulse-ID from / to the MRAM. This hardware is intended to
    store the current pulse-ID in the MRAM for every 100 Hz cycle. On a reboot, the last pulse-id
    is read and used as the new initial value.
    
    After the reset, it configures the MRAM for writing access and becomes ready.
    One clock cycle on "start" causes a read/write operation of 64 bits, starting from address 0.
*/

module MRAM(
    input  logic clk,
    input  logic reset,
    
    input  logic start,
    output logic ready,
    input  logic write,
    
    input  logic [63:0] pulse_id_to_write, // must be valid until not idle
    output logic [63:0] pulse_id_read,     // valid once idle
    
    
    output logic cs,
    output logic sck,
    output logic mosi,
    input  logic miso
);


    localparam max_length = 8+16+64;

    logic spi_ready;
    logic spi_start;
    logic [max_length-1:0] spi_send_data;
    logic [max_length-1:0] spi_receive_data;
    logic unsigned [7:0] spi_num_of_bits;
    
    // the SPI interface:
    SPI_RW spi_rw(
        .clk(clk),
        .reset(reset),
        .start(spi_start),
        .ready(spi_ready),
        .num_of_bits(spi_num_of_bits),
        .data_to_send(spi_send_data),
        .data_received(spi_receive_data),
        .sck(sck),
        .cs(cs),
        .mosi(mosi),
        .miso(miso)
    );

    // FSM:
    // states of the FSM
    typedef enum logic [3:0] {
        RESET,
        SEND_WREN,
        SEND_WREN_WAIT,
        SEND_WRSR,
        SEND_WRSR_WAIT,
        READY,
        READ,
        READ_WAIT,
        WRITE,
        WRITE_WAIT,
        DONE
    } state_t;
    
    state_t state_d, state_q;
    
    always_ff @(posedge clk) begin
        if (reset == 1)
            state_q <= RESET;
        else
            state_q <= state_d;
    end
    
    
    always_comb begin
        state_d = state_q;
        
        case(state_q)
            RESET:
                state_d = SEND_WREN;
                
            SEND_WREN: 
                if (spi_ready == 0) state_d = SEND_WREN_WAIT;
            
            SEND_WREN_WAIT:
                if (spi_ready == 1) state_d = SEND_WRSR;
                
            SEND_WRSR:
                if (spi_ready == 0) state_d = SEND_WRSR_WAIT;
                
            SEND_WRSR_WAIT:
                if (spi_ready == 1) state_d = READY;
                
            READY:
                if (start == 1)
                    if (write == 1) state_d = WRITE;
                    else state_d = READ;
            
            READ:
                if (spi_ready == 0) state_d = READ_WAIT;
                
            READ_WAIT:
                if (spi_ready == 1) state_d = DONE;
                
            WRITE:
                if (spi_ready == 0) state_d = WRITE_WAIT;
                
            WRITE_WAIT:
                if (spi_ready == 1) state_d = DONE;
                
            DONE:
                if (start == 0) state_d = READY;
        
            default: state_d = RESET;
        endcase
    end
    
    
    always_comb begin
        spi_send_data = 0;
        spi_num_of_bits = 0;
        
        case (state_q)
            SEND_WREN, SEND_WREN_WAIT: begin
                // transmit 8 bits, contents: 0x06
                spi_send_data[7:0] = 8'h06;
                spi_send_data[max_length-1:8] = 0;
                spi_num_of_bits = 8;
            end
            
            SEND_WRSR,SEND_WRSR_WAIT: begin
                // transmit 16 bits: 0x01 (write status), contents: 0x02
                spi_send_data[15:0] = 16'h0102; // WEL=1, BP0=BP1=0, SRWD=0
                spi_send_data[max_length-1:16] = 0;
                spi_num_of_bits = 16;
            end
            
            READ,READ_WAIT: begin
                // send read command (0x03) from address 0
                spi_send_data[max_length-1:max_length-24] = 24'h030000;
                spi_send_data[max_length-24-1:0] = 0;
                spi_num_of_bits = max_length;
            end
            
            WRITE,WRITE_WAIT: begin
                // send write command (0x02) from address 0, data: pulse-ID
                spi_send_data[max_length-1:max_length-24] = 24'h020000;
                spi_send_data[max_length-24-1:0] = pulse_id_to_write;
                spi_num_of_bits = max_length;
            end
            
            default: begin
                spi_send_data = 0;
                spi_num_of_bits = 0;
            end
        endcase
    end
    assign spi_start = ((state_q == SEND_WREN) | (state_q == SEND_WRSR)) | ((state_q == READ) | (state_q == WRITE));
    assign pulse_id_read = spi_receive_data[63:0];
    assign ready = (state_q == READY);

endmodule
