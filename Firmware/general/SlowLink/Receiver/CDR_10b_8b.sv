/*
    Receiver of the serial data using its own CRD and 8b10b decoder.
    It is used in the slow decoder for the time distribution system.

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
    Receiver of the serial data signal including 
        CDR,
        de-serializer,
        coma-synchronization (word sync),
        8b/10b decoder
        
    The CDR is realized with an Alexander phase detector, an NCO and
    a PI loop filter.
    
    The base frequency of the NCO must be configured to match the 
    bit rate of the transitter.
        
    The data (data_o, comma_o and error_o) can be further processed on
    word_tick_o == 1.
    
    Yves Acremann, 6.9.2021
	 Modified and cleaned up, 17.5.2024, YA
*/

module CDR_10b_8b #(
    // parameters for 1MBit/s. 50 MHz
    parameter int Ki =     2,
    parameter int Kp =   500,
    parameter int K0 = 335544
)(
    input logic clk,                // reference clock
    input logic reset,              // sync reset
    
    input logic serial_i,           // serial data in
    
    output logic word_tick_o,       // word tick signal ('1' for one clock cycle)
    output logic [7:0] data_o,      // decoded data out
    output logic comma_o,           // 8b/10b comma detected
    output logic error_o,           // 8b/10b error detected
	 
	 output logic sampling_clk_o     // for debugging
);

    
    assign sampling_clk_o = sampling_clk;
    

    // first let's re-synchronize the input signal to the clock:
    logic [1:0] data_sync;
    always_ff @(posedge clk) begin
        data_sync[0] <= serial_i;
        data_sync[1] <= data_sync[0]; 
    end

    // phase detector
    logic sampling_clk;
    logic early;
    logic late;
    logic bits;
	 logic phase_det_ref;
    AlexanderDetectorSync alexanderDetector(
        .clk(clk),
        .bit_clk(sampling_clk),
        .din(data_sync[1]),
        .early(early),
        .late(late),
        .dout(bits)
    );
    
    // NCO (generates the sampling clock
    logic unsigned [23:0] phase;
    logic unsigned [23:0] frequency;
    always_ff @(posedge clk) begin
        if(reset == 1)
            phase <= 0;
        else
            phase <= phase + frequency;
    end
	 logic sampling_tick;
	 assign sampling_clk = phase[23];
    
    
    // loop filter:
    // register for the integral part
    logic signed [23:0] integral_reg;
    always_ff @(posedge clk) begin
        if (reset == 1)
            integral_reg <= 0;
        else begin
            if (early == 1)
                integral_reg <= integral_reg - 24'(Ki);
            else if (late == 1)
                integral_reg <= integral_reg + 24'(Ki);
        end
    end
     
    // combinational part for the loop filter: calculate the frequency
    always_comb begin
        frequency = unsigned'(24'(K0)+integral_reg);
        if (early == 1)
            frequency = unsigned'(24'(24'(K0) - 24'(Kp) + integral_reg));
        else if (late == 1)
            frequency = unsigned'(24'(24'(K0) + 24'(Kp) + integral_reg));
    end
	 
	 // rising edge detector of sampling clock
	 logic sampling_clk_delayed;
	 always_ff @(posedge clk) begin
    
        // flipflop for sync. rising edge detector of the sampling clk
        if (reset == 1)
            sampling_clk_delayed <= 0;
        else
            sampling_clk_delayed <= sampling_clk;
	 end
	 assign sampling_tick = sampling_clk & (! sampling_clk_delayed);
	 
	 //////////////////////////////////////////////////////////////////////
	 // shift register and comma detection
	 //////////////////////////////////////////////////////////////////////
	 logic [9:0] shift_reg_d, shift_reg_q, result_d, result_q;
	 logic unsigned [3:0] bit_counter_d, bit_counter_q;
	 logic comma_detected;
	 
	 // fipflop
	 always_ff @(posedge clk) begin
	     if (reset == 1) begin
		      shift_reg_q   <= 'd0;
				result_q      <= 'd0;
				bit_counter_q <= 'd0;
		  end else begin
		      shift_reg_q   <= shift_reg_d;
				bit_counter_q <= bit_counter_d;
				result_q      <= result_d;
		  end
	 end
	 
	 // combinational logic of shift register
	 always_comb begin
	     bit_counter_d  = bit_counter_q;
		  result_d       = result_q;
		  shift_reg_d    = shift_reg_q;
		  if (sampling_tick) begin
		      if ((bit_counter_q == 9) | (shift_reg_q == 10'h0f9) | (shift_reg_q == 10'h306)) begin
                bit_counter_d  = 0;
                result_d  = shift_reg_q;
            end else begin
                bit_counter_d  = bit_counter_q + 1;
			   end
				shift_reg_d[9]     = bits;
            shift_reg_d[8:0]   = shift_reg_q[9:1];
		  end
	 end
    //////////////////////////////////////////////////////////////////////
	
    
    // generate word tick signal of 1 clock cycle length
    logic word_tick_delayed;
    logic word_tick;
    always_ff @(posedge clk) begin
        word_tick_delayed <= (bit_counter_q == 0);
    end
    assign word_tick = (bit_counter_q == 0) & !word_tick_delayed;
    
	 
    
    // now we can send the data to the 8b10b decoder:
    logic error;
    logic comma;
	 logic [7:0] data;
    Decode_8b10b decoder(
      .io_din(result_q),
      .io_comma(comma),
      .io_dout(data),
      .io_error(error)
    );
	 
	 always_ff @(posedge clk) begin
	     word_tick_o <= word_tick;
	     error_o <= error;
		  data_o <= data;
		  comma_o <= comma;
	 end
	 
	 
endmodule
