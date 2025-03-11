/*

    This module implements a simple watchdog to reset the
    receiver if errors persist for a number of clock cycles.

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

module Watchdog #(
    parameter int WAIT_CYCLES = 10000
)(
     input  logic clk_i,    // clock (reference for the number of cycles)
	 input  logic reset_i,  // active high
	 input  logic error_i,  // indicates a receiver error
	 output logic reset_o   // reset output, active high
);

    typedef enum logic [2:0] {
        OK,     // normal operation
        ERR,    // wait for the error to clear
        RESET   // generate a reset signal
    } state_t;
    state_t state_d;
	 state_t state_q = RESET;
	 logic unsigned [31:0] time_counter_d, time_counter_q;
	 
	 always_ff @(posedge clk_i) begin
	     if (reset_i) begin
		      state_q <= RESET;
				time_counter_q <= 'd0;
		  end else begin
		      state_q        <= state_d;
				time_counter_q <= time_counter_d;
		  end
	 end
	 
	 always_comb begin
	     state_d        = state_q;
		  time_counter_d = 'd0;
		  
		  case(state_q)
		      OK: if (error_i) state_d = ERR;
				ERR:
				    if (!error_i)
					     state_d = OK;
				    else 
					     if (time_counter_q < $bits(time_counter_q)'(WAIT_CYCLES))
					         time_counter_d = time_counter_q + 'd1;
						  else
						      state_d = RESET;
				RESET:   state_d = OK;
		      default: state_d = RESET;
		  endcase
	 end
	 
	 // output decoder:
	 assign reset_o = state_q == RESET;

endmodule
