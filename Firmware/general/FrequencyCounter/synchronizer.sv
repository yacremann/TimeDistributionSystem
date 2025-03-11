/*

    Synchronizer (only two flipflops), needs to be used with a gray counter.

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

module synchronizer#(
    parameter DATA_WIDTH = 32
    ) (
    input  logic clk_src,
    input  logic clk_dst,
    input  logic [DATA_WIDTH-1:0] data_i,
    output logic [DATA_WIDTH-1:0] data_o
);

    logic [DATA_WIDTH-1:0] stage1, stage2;
    
    always_ff @(posedge clk_src) begin
        stage1 <= data_i;
    end
    
    always_ff @(posedge clk_dst) begin
        stage2 <= stage1;
        data_o <= stage2;
    end

endmodule
