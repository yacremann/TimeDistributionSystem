// Generator : SpinalHDL v1.3.1    git head : 9fe87c98746a5306cb1d5a828db7af3137723649
// Date      : 06/09/2021, 14:30:00
// Component : Encode_8b10b


module Encode_5b6b (
      input  [4:0] io_din,
      input   io_rdNeg,
      input   io_comma,
      output [5:0] io_dout,
      output reg [2:0] io_disparity,
      output reg  io_needAlternate);
  wire [2:0] _zz_1_;
  wire [2:0] _zz_2_;
  reg [5:0] result;
  reg  disp_neutral;
  assign _zz_1_ = (3'b010);
  assign _zz_2_ = (3'b110);
  always @ (*) begin
    disp_neutral = 1'b0;
    result = (6'b000000);
    io_needAlternate = 1'b0;
    if((! io_comma))begin
      case(io_din)
        5'b00000 : begin
          if(io_rdNeg)begin
            result = (6'b100111);
          end else begin
            result = (6'b011000);
          end
        end
        5'b00001 : begin
          if(io_rdNeg)begin
            result = (6'b011101);
          end else begin
            result = (6'b100010);
          end
        end
        5'b00010 : begin
          if(io_rdNeg)begin
            result = (6'b101101);
          end else begin
            result = (6'b010010);
          end
        end
        5'b00011 : begin
          result = (6'b110001);
          disp_neutral = 1'b1;
        end
        5'b00100 : begin
          if(io_rdNeg)begin
            result = (6'b110101);
          end else begin
            result = (6'b001010);
          end
        end
        5'b00101 : begin
          result = (6'b101001);
          disp_neutral = 1'b1;
        end
        5'b00110 : begin
          result = (6'b011001);
          disp_neutral = 1'b1;
        end
        5'b00111 : begin
          if(io_rdNeg)begin
            result = (6'b111000);
          end else begin
            result = (6'b000111);
          end
          disp_neutral = 1'b1;
        end
        5'b01000 : begin
          if(io_rdNeg)begin
            result = (6'b111001);
          end else begin
            result = (6'b000110);
          end
        end
        5'b01001 : begin
          result = (6'b100101);
          disp_neutral = 1'b1;
        end
        5'b01010 : begin
          result = (6'b010101);
          disp_neutral = 1'b1;
        end
        5'b01011 : begin
          result = (6'b110100);
          disp_neutral = 1'b1;
          if((! io_rdNeg))begin
            io_needAlternate = 1'b1;
          end
        end
        5'b01100 : begin
          result = (6'b001101);
          disp_neutral = 1'b1;
        end
        5'b01101 : begin
          result = (6'b101100);
          disp_neutral = 1'b1;
          if((! io_rdNeg))begin
            io_needAlternate = 1'b1;
          end
        end
        5'b01110 : begin
          result = (6'b011100);
          disp_neutral = 1'b1;
          if((! io_rdNeg))begin
            io_needAlternate = 1'b1;
          end
        end
        5'b01111 : begin
          if(io_rdNeg)begin
            result = (6'b010111);
          end else begin
            result = (6'b101000);
          end
        end
        5'b10000 : begin
          if(io_rdNeg)begin
            result = (6'b011011);
          end else begin
            result = (6'b100100);
          end
        end
        5'b10001 : begin
          result = (6'b100011);
          disp_neutral = 1'b1;
          if(io_rdNeg)begin
            io_needAlternate = 1'b1;
          end
        end
        5'b10010 : begin
          result = (6'b010011);
          disp_neutral = 1'b1;
          if(io_rdNeg)begin
            io_needAlternate = 1'b1;
          end
        end
        5'b10011 : begin
          result = (6'b110010);
          disp_neutral = 1'b1;
        end
        5'b10100 : begin
          result = (6'b001011);
          disp_neutral = 1'b1;
          if(io_rdNeg)begin
            io_needAlternate = 1'b1;
          end
        end
        5'b10101 : begin
          result = (6'b101010);
          disp_neutral = 1'b1;
        end
        5'b10110 : begin
          result = (6'b011010);
          disp_neutral = 1'b1;
        end
        5'b10111 : begin
          if(io_rdNeg)begin
            result = (6'b111010);
          end else begin
            result = (6'b000101);
          end
        end
        5'b11000 : begin
          if(io_rdNeg)begin
            result = (6'b110011);
          end else begin
            result = (6'b001100);
          end
        end
        5'b11001 : begin
          result = (6'b100110);
          disp_neutral = 1'b1;
        end
        5'b11010 : begin
          result = (6'b010110);
          disp_neutral = 1'b1;
        end
        5'b11011 : begin
          if(io_rdNeg)begin
            result = (6'b110110);
          end else begin
            result = (6'b001001);
          end
        end
        5'b11100 : begin
          result = (6'b001110);
          disp_neutral = 1'b1;
        end
        5'b11101 : begin
          if(io_rdNeg)begin
            result = (6'b101110);
          end else begin
            result = (6'b010001);
          end
        end
        5'b11110 : begin
          if(io_rdNeg)begin
            result = (6'b011110);
          end else begin
            result = (6'b100001);
          end
        end
        default : begin
          if(io_rdNeg)begin
            result = (6'b101011);
          end else begin
            result = (6'b010100);
          end
        end
      endcase
    end else begin
      if((io_din == (5'b11100)))begin
        if(io_rdNeg)begin
          result = (6'b001111);
        end else begin
          result = (6'b110000);
        end
      end
    end
  end

  assign io_dout = result;
  always @ (*) begin
    if(disp_neutral)begin
      io_disparity = (3'b000);
    end else begin
      io_disparity = (io_rdNeg ? _zz_1_ : _zz_2_);
    end
  end

endmodule

module Encode_3b4b (
      input  [2:0] io_din,
      input   io_rdNeg,
      input   io_comma,
      input   io_p_code,
      output [3:0] io_dout,
      output reg [2:0] io_disparity);
  wire [2:0] _zz_1_;
  wire [2:0] _zz_2_;
  reg [3:0] result;
  reg  disp_neutral;
  assign _zz_1_ = (3'b010);
  assign _zz_2_ = (3'b110);
  always @ (*) begin
    result = (4'b0000);
    disp_neutral = 1'b0;
    if((! io_comma))begin
      case(io_din)
        3'b000 : begin
          if(io_rdNeg)begin
            result = (4'b1011);
          end else begin
            result = (4'b0100);
          end
        end
        3'b001 : begin
          result = (4'b1001);
          disp_neutral = 1'b1;
        end
        3'b010 : begin
          result = (4'b0101);
          disp_neutral = 1'b1;
        end
        3'b011 : begin
          if(io_rdNeg)begin
            result = (4'b1100);
          end else begin
            result = (4'b0011);
          end
          disp_neutral = 1'b1;
        end
        3'b100 : begin
          if(io_rdNeg)begin
            result = (4'b1101);
          end else begin
            result = (4'b0010);
          end
        end
        3'b101 : begin
          result = (4'b1010);
          disp_neutral = 1'b1;
        end
        3'b110 : begin
          result = (4'b0110);
          disp_neutral = 1'b1;
        end
        default : begin
          if(io_p_code)begin
            if(io_rdNeg)begin
              result = (4'b1110);
            end else begin
              result = (4'b0001);
            end
          end else begin
            if(io_rdNeg)begin
              result = (4'b0111);
            end else begin
              result = (4'b1000);
            end
          end
        end
      endcase
    end else begin
      case(io_din)
        3'b000 : begin
          if(io_rdNeg)begin
            result = (4'b1011);
          end else begin
            result = (4'b0100);
          end
        end
        3'b001 : begin
          if(io_rdNeg)begin
            result = (4'b0110);
          end else begin
            result = (4'b1001);
          end
          disp_neutral = 1'b1;
        end
        3'b010 : begin
          if(io_rdNeg)begin
            result = (4'b1010);
          end else begin
            result = (4'b0101);
          end
          disp_neutral = 1'b1;
        end
        3'b011 : begin
          if(io_rdNeg)begin
            result = (4'b1100);
          end else begin
            result = (4'b0011);
          end
          disp_neutral = 1'b1;
        end
        3'b100 : begin
          if(io_rdNeg)begin
            result = (4'b1101);
          end else begin
            result = (4'b0010);
          end
        end
        3'b101 : begin
          if(io_rdNeg)begin
            result = (4'b0101);
          end else begin
            result = (4'b1010);
          end
          disp_neutral = 1'b1;
        end
        3'b110 : begin
          if(io_rdNeg)begin
            result = (4'b1001);
          end else begin
            result = (4'b0110);
          end
          disp_neutral = 1'b1;
        end
        default : begin
          if(io_rdNeg)begin
            result = (4'b0111);
          end else begin
            result = (4'b1000);
          end
        end
      endcase
    end
  end

  assign io_dout = result;
  always @ (*) begin
    if(disp_neutral)begin
      io_disparity = (3'b000);
    end else begin
      io_disparity = (io_rdNeg ? _zz_1_ : _zz_2_);
    end
  end

endmodule

module Encode_8b10b (
      input  [7:0] io_din,
      input   io_comma,
      input   io_tick,
      output [9:0] io_dout,
      input   clk,
      input   reset);
  wire [4:0] _zz_1_;
  wire  _zz_2_;
  wire [2:0] _zz_3_;
  reg  _zz_4_;
  wire  _zz_5_;
  wire [5:0] encode_5b6b_1__io_dout;
  wire [2:0] encode_5b6b_1__io_disparity;
  wire  encode_5b6b_1__io_needAlternate;
  wire [3:0] encode_3b4b_1__io_dout;
  wire [2:0] encode_3b4b_1__io_disparity;
  wire [2:0] _zz_6_;
  wire [2:0] _zz_7_;
  wire [2:0] _zz_8_;
  reg  rd;
  wire [5:0] abcdei;
  wire [3:0] fghj;
  reg [9:0] result;
  wire [2:0] new_disp;
  assign _zz_6_ = (3'b000);
  assign _zz_7_ = (3'b000);
  assign _zz_8_ = (3'b000);
  Encode_5b6b encode_5b6b_1_ ( 
    .io_din(_zz_1_),
    .io_rdNeg(_zz_2_),
    .io_comma(io_comma),
    .io_dout(encode_5b6b_1__io_dout),
    .io_disparity(encode_5b6b_1__io_disparity),
    .io_needAlternate(encode_5b6b_1__io_needAlternate) 
  );
  Encode_3b4b encode_3b4b_1_ ( 
    .io_din(_zz_3_),
    .io_rdNeg(_zz_4_),
    .io_comma(io_comma),
    .io_p_code(_zz_5_),
    .io_dout(encode_3b4b_1__io_dout),
    .io_disparity(encode_3b4b_1__io_disparity) 
  );
  assign _zz_1_ = io_din[4 : 0];
  assign _zz_3_ = io_din[7 : 5];
  assign _zz_5_ = (! encode_5b6b_1__io_needAlternate);
  assign _zz_2_ = (! rd);
  always @ (*) begin
    if(($signed(encode_5b6b_1__io_disparity) == $signed(_zz_6_)))begin
      _zz_4_ = (! rd);
    end else begin
      _zz_4_ = rd;
    end
  end

  always @ (*) begin
    result[3 : 0] = encode_3b4b_1__io_dout;
    result[9 : 4] = encode_5b6b_1__io_dout;
  end

  assign new_disp = ($signed(encode_3b4b_1__io_disparity) + $signed(encode_5b6b_1__io_disparity));
  assign io_dout = result;
  always @ (posedge clk or posedge reset) begin
    if (reset) begin
      rd <= 1'b1;
    end else begin
      if(($signed(new_disp) != $signed(_zz_7_)))begin
        if((io_tick == 1'b1))begin
          rd <= ($signed(_zz_8_) < $signed(new_disp));
        end
      end
    end
  end

endmodule

