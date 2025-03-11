/*
    Test setup for the trigger

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

module TriggerTb (
        input logic                         clk,
        input logic                         reset,
                                            
        input logic unsigned [31:0]         delay_i,
        input logic unsigned [31:0]         length_i,
        input logic unsigned [ 7:0]         div_i,
        input logic unsigned [ 7:0]         mod_i,
        input logic unsigned [ 7:0]         frame_type_i,
        input logic                         frame_tick_i,
        input logic unsigned [31:0]         pulse_id_i,
        
        output logic                        pulse_o
    );
    
    payload_t payload;
    delay_data_t delay_data;
    
    always_comb begin
        payload = '0;
        delay_data = '0;
        payload.payload_type = frame_type_i;
        if (frame_type_i == 2) begin
            delay_data.board     = 1;
            delay_data.channel   = 1;
            delay_data.delay     = delay_i;
            delay_data.length    = length_i;
            delay_data.divider   = div_i;
            delay_data.modulus   = mod_i;
            delay_data.status    = 1;
            payload.data = delay_data;
        end else if (frame_type_i == 1) begin
            payload.data = 128'(pulse_id_i);
        end
    end
    
    Trigger trigger
    (
        .clk(clk),
        .reset(reset),
                                            
        .payload_i(payload),
        .frame_tick_i(frame_tick_i),
        
        .pulse_o(pulse_o)
    );


endmodule
