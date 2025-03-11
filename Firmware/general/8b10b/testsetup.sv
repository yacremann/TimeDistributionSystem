/*
    Test bench for the 8b10b encoder / decoder (SystemVerilog part
    used by the Cocotb test bench Test8b10b.py)
    

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


module testsetup(
    input logic clk,
    input logic reset,
    input logic comma_i,
    input logic [7:0] data_i,
    output logic [7:0] data_o,
    output logic comma_o,
    output logic error
);

    logic [9:0] line_data;
    
    
    
    Encode_8b10b my_encoder(
        .clk(clk),
        .reset(reset),
        .io_comma(comma_i),
        .io_din(data_i),
        .io_dout(line_data)
    );
    
    
    Decode_8b10b my_decoder(
        .io_din(line_data),
        .io_comma(comma_o),
        .io_error(error),
        .io_dout(data_o)
    );
    
    
    
    

endmodule
