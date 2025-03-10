/*
    Pulse-ID generator:
    
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
    Pulse-ID generator:
    
    This module generateds the pulse-ID data frame and transmits it using the
    PayloadTransmitter. After transmission, the current pulse-ID is
    stored in MRAM.
    
    After the pulse ID, settings of the delay generators are broadcasted as well.
    These are stored in a FIFO and provided by the CPU. The FIFO separates the clock domains.
    
    After a reset, the pulse-ID counter is initialized by the last value
    stored in MRAM.
    
    The data frame is defined in general/data_frames.sv.
    
    The output data is 8b10b encoded.
    
    Yves Acremann, 2.7.2021
*/

module pulse_id_gen(
    input logic clk,                 // 80 MHz word clock
    input logic reset,
    input logic trigger,             // 100 Hz laser trigger (can be async)
    output logic [9:0] data_10b,     // data 8b/10b encoded
    
    output logic [63:0] current_id,  // the current pulse-ID for monitoring
    
    input logic [63:0] new_pulse_id, // new pulse-ID to set from the CPU:
    input logic set_pulse_id,        // triggers setting a new pulse-ID from the CPU
    
    output logic mram_cs,            // MRAM SPI signals
    output logic mram_sck,
    output logic mram_mosi,
    input  logic mram_miso,
    
    
    // signals for the FIFO (CPU clock domain!)
    input  logic fifo_src_clk_i,
    input  logic fifo_src_rst_i,
    input  logic [$bits(payload_t)-1:0] fifo_data_i,
    input  logic fifo_write_i,
    output logic fifo_full_o
);

    // synchronization of the trigger and set_pulse_id with the clock and 
    // generate a one-cycle long pulse from it:
    logic [1:0] trigger_sync;         // synchronization chain trigger
    logic trigger_delayed;            // delayed trigger for the one-shot
    logic trigger_singleshot;         // output of the trigger clean-up circuit
    logic [1:0] set_pulse_id_resync;  // synchronization chain set_pulse_id
    logic set_pulse_id_singleshot;    // output for the new_pulse_id signal
    logic set_pulse_id_delayed;       // delayed new_pulse_id for one-shot
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            trigger_sync <= 2'b00;
            trigger_delayed <= 0;
            set_pulse_id_resync <= 2'b00;
            set_pulse_id_delayed <= 0;
        end else begin
            trigger_sync[1] <= trigger;
            trigger_sync[0] <= trigger_sync[1];
            trigger_delayed <= trigger_sync[0];
            set_pulse_id_resync[1] <= set_pulse_id;
            set_pulse_id_resync[0] <= set_pulse_id_resync[1];
            set_pulse_id_delayed <= set_pulse_id_resync[0];
        end
    end
    assign trigger_singleshot      = trigger_sync[0]        & !trigger_delayed;
    assign set_pulse_id_singleshot = set_pulse_id_resync[0] & !set_pulse_id_delayed;
 
    

    /* DATA PATH 
    *************/
    
    // pulse-id signals
    logic unsigned [63:0] current_pulse_id;
    logic unsigned [63:0] mram_read_pulse_id;
    
    
    logic init;                                   // init the current pulse-id from mram
    logic increment;                              // increment the current pulse-id
    logic set_id;                                 // set the pulse-ID from the CPU
    logic payload_valid;                          // payload valid to transmit
    logic transmitter_ready;                       // transmitter is ready
    logic pulse_id_valid;                         // the pulse-ID is valid for transmission (from FSM)
    
    
    
    // The pulse-ID counter
    always_ff @(posedge clk) begin
        if (init == 1)
            current_pulse_id <= mram_read_pulse_id;
        else if (increment == 1)
            current_pulse_id <= current_pulse_id + 64'd1;
            else if (set_id == 1)
                current_pulse_id <= new_pulse_id;
    end
    
    
    // the mram (stores the last pulse-ID):
    logic mram_write;
    logic mram_ready;
    logic mram_start;
    MRAM mram(
        .clk(clk),
        .reset(reset),
        .start(mram_start),
        .ready(mram_ready),
        .write(mram_write),
        .pulse_id_to_write(current_pulse_id),
        .pulse_id_read(mram_read_pulse_id),
        .cs(mram_cs),
        .sck(mram_sck),
        .miso(mram_miso),
        .mosi(mram_mosi)
    );
    
    // FIFO
    payload_t fifo_out;
    logic fetch_fifo;
    logic fifo_empty;
    async_fifo #(
        .DSIZE($bits(payload_t)),
        .ASIZE(4),
        .FALLTHROUGH("FALSE")
    ) fifo (
        .wclk(fifo_src_clk_i),
        .wrst_n(!fifo_src_rst_i),
        .winc(fifo_write_i),
        .wdata(fifo_data_i),
        .wfull(fifo_full_o),
        .awfull(),
        
        .rclk(clk),
        .rrst_n(!reset),
        .rinc(fetch_fifo),
        .rdata(fifo_out),
        .rempty(fifo_empty),
        .arempty()
    );
    
    
    
    
    // prepare the payload for the pulse id
    payload_t payload_pulse_id;
    assign payload_pulse_id.payload_type = 8'h01;
    assign payload_pulse_id.data = $size(payload_pulse_id.data)'(current_pulse_id);
    
    // MUX for the payload data (pulse-ID or FIFO)
    logic send_fifo;
    payload_t current_payload;
    assign current_payload = (send_fifo == 0)? payload_pulse_id : fifo_out;
    assign payload_valid   = (send_fifo == 0)? pulse_id_valid   : !fifo_empty;
    assign fetch_fifo =       send_fifo & transmitter_ready;
    
    
    
    // the transmitter:
    PayloadTransmitter payload_transmitter(
        .clk(clk),
        .reset(reset),
        .valid(payload_valid),
        .ready(transmitter_ready),
        .payload(current_payload),
		  .output_tick(1),
        .data_10b(data_10b)
    );
    
    

    
    /* CONTROLLER
    **************/
    
    typedef enum logic [3:0] {
        RESET,
        WAIT_MRAM_INIT,     // wait for the MRAM to finish initialization
        READ_MRAM,          // start reading the last pulse-id from MRAM
        READ_MRAM_WAIT,     // wait for reading to complete
        READY,              // ready for a trigger or pulse-id write request from the CPU
        INCREMENT_ID,       // increment the pulse-ID
        SET_ID,             // set the pulse-ID from the CPU
        SEND_PAYLOAD,       // send the ID, incl. the frame indicator
        WRITE_MRAM,         // write the current pulse-ID to MRAM
        WRITE_MRAM_WAIT,    // wait for the MRAM writing to finist
        SEND_FIFO           // send the contents of the FIFO
    } state_t;
    state_t state_d, state_q;
    
    
    always_ff @(posedge clk) begin
        if (reset == 1) begin
            state_q <= RESET;
        end else begin
            state_q <= state_d;
        end
    end
    
    // next state logic
    always_comb begin
        state_d = state_q;
        
        case (state_q)
            RESET:           state_d = WAIT_MRAM_INIT;
            
            WAIT_MRAM_INIT:  if (mram_ready == 1) state_d = READ_MRAM;
            
            READ_MRAM:       if (mram_ready == 0) state_d = READ_MRAM_WAIT;
            
            READ_MRAM_WAIT:  if (mram_ready == 1) state_d = READY;
            
            READY:           if (trigger_singleshot == 1) state_d = INCREMENT_ID; // wait for the trigger
                             else if (set_pulse_id_singleshot == 1) state_d = SET_ID;
            
            INCREMENT_ID:    state_d = SEND_PAYLOAD;                     // increment the pulse-ID and start transmission
            
            SEND_PAYLOAD:    if (transmitter_ready == 1) state_d = WRITE_MRAM;  // wait for the transmission to finish
            
            WRITE_MRAM:      if (mram_ready == 0) state_d = WRITE_MRAM_WAIT;
            
            WRITE_MRAM_WAIT: if (mram_ready == 1) state_d = SEND_FIFO;
            
            SEND_FIFO:       if ((fifo_empty == 1) & (transmitter_ready == 1)) state_d = READY; // was fifo_valid == 0
            
            
            SET_ID:          state_d = WRITE_MRAM;
            
            default:         state_d = RESET;
        endcase
    end
    
    // output decoder:
    assign init = (state_q == READ_MRAM_WAIT) & (mram_ready == 1);  // init the pulse-ID counter once the MRAM is read
    assign mram_write = (state_q == WRITE_MRAM);
    assign mram_start = (state_q == READ_MRAM) | (state_q == WRITE_MRAM);
    
    assign increment = (state_q == INCREMENT_ID);
    assign pulse_id_valid = (state_q == INCREMENT_ID);
    assign set_id    = (state_q == SET_ID);
    assign send_fifo = (state_q == SEND_FIFO);

    assign current_id = current_pulse_id;
endmodule
