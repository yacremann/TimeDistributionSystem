//https://gist.github.com/wnew/3951509

//============================================================================//
//                                                                            //
//      Binary to Gray code converter                                         //
//                                                                            //
//      Module name: bin2gray                                                 //
//      Desc: parameterised module to convert binary numbers to gray encoded  //
//            numbers                                                         //
//      Date: Aug 2012                                                        //
//      Developer: Wesley New                                                 //
//      Licence: GNU General Public License ver 3                             //
//      Notes:                                                                //
//                                                                            //
//============================================================================//

module bin2gray #(
      //=============
      // Parameters
      //=============
      parameter DATA_WIDTH = 32
   ) (
      //============
      // I/O Ports
      //============
      input  [DATA_WIDTH-1:0] binary_in,
      output [DATA_WIDTH-1:0] gray_out
   );

   //====================
   // FUNC: binary2gray
   //====================
   function [DATA_WIDTH-1:0] binary2gray;
      input [DATA_WIDTH-1:0] value;
      integer i;
      begin 
         binary2gray[DATA_WIDTH-1] = value[DATA_WIDTH-1];
         for (i = DATA_WIDTH-1; i > 0; i = i - 1)
            binary2gray[i - 1] = value[i] ^ value[i - 1];
      end
   endfunction

   assign gray_out = binary2gray(binary_in);
endmodule

//============================================================================//
//                                                                            //
//      Gray code to Binary converter                                         //
//                                                                            //
//      Module name: gray2bin                                                 //
//      Desc: parameterised module to convert gray coded numbers to binary    //
//            numbers                                                         //
//      Date: Aug 2012                                                        //
//      Developer: Wesley New                                                 //
//      Licence: GNU General Public License ver 3                             //
//      Notes:                                                                //
//                                                                            //
//============================================================================//

module gray2bin #(
      //=============
      // Parameters
      //=============
      parameter DATA_WIDTH = 32
   ) (
      //============
      // I/O Ports
      //============
      input  [DATA_WIDTH-1:0] gray_in,
      output [DATA_WIDTH-1:0] binary_out
   );
   
   // gen vars
   genvar i;

   //=====================
   // Generate: gray2bin
   //=====================
   generate 
      for (i=0; i<DATA_WIDTH; i=i+1)
      begin : bin2gray_loop
         assign binary_out[i] = ^ gray_in[DATA_WIDTH-1:i];
      end
   endgenerate

endmodule

//============================================================================//
//                                                                            //
//      Parameterize Gray Counter                                             //
//                                                                            //
//      Module name: gray counter                                             //
//      Desc: parameterized gray counter, counts up to the specified data     //
//            width and repeats indefinitely.                                 //
//      Date: June 2012                                                       //
//      Developer: Wesley New                                                 //
//      Licence: GNU General Public License ver 3                             //
//      Notes:                                                                //
//                                                                            //
//============================================================================//

module gray_counter #(
      //=============
      // parameters
      //=============
      parameter DATA_WIDTH = 32
   ) (
      //===============
      // Input Ports
      //===============
      input wire clk,
      input wire en,
      input wire rst,
   
      //===============
      // Output Ports
      //===============
      output reg [DATA_WIDTH-1:0] count_out  //'Gray' code count output.
   );

   /////////Internal connections & variables///////
   reg [DATA_WIDTH-1:0] binary_count;

   always @ (posedge clk) begin
      if (rst) begin
         binary_count <= {DATA_WIDTH{1'b 0}} + 1;  //Gray count begins @ '1' with
         count_out    <= {DATA_WIDTH{1'b 0}};      // first 'en'.
      end
      else if (en) begin
         binary_count <=  binary_count + 1;
         count_out    <= {binary_count[DATA_WIDTH-1], binary_count[DATA_WIDTH-2:0] ^ binary_count[DATA_WIDTH-1:1]};
      end
   end
endmodule
