// Generator : SpinalHDL v1.3.1    git head : 9fe87c98746a5306cb1d5a828db7af3137723649
// Date      : 06/09/2021, 14:30:07
// Component : Decode_8b10b


module Decode_3b4b (
      input  [3:0] io_din,
      input   io_comma_in,
      output [2:0] io_dout,
      output  io_error);
  reg [2:0] result;
  reg  error;
  always @ (*) begin
    result = (3'b000);
    error = 1'b0;
    if((! io_comma_in))begin
      case(io_din)
        4'b1011 : begin
          result = (3'b000);
        end
        4'b0100 : begin
          result = (3'b000);
        end
        4'b1001 : begin
          result = (3'b001);
        end
        4'b0101 : begin
          result = (3'b010);
        end
        4'b1100 : begin
          result = (3'b011);
        end
        4'b0011 : begin
          result = (3'b011);
        end
        4'b1101 : begin
          result = (3'b100);
        end
        4'b0010 : begin
          result = (3'b100);
        end
        4'b1010 : begin
          result = (3'b101);
        end
        4'b0110 : begin
          result = (3'b110);
        end
        4'b1110 : begin
          result = (3'b111);
        end
        4'b0001 : begin
          result = (3'b111);
        end
        4'b0111 : begin
          result = (3'b111);
        end
        4'b1000 : begin
          result = (3'b111);
        end
        default : begin
          error = 1'b1;
        end
      endcase
    end else begin
      case(io_din)
        4'b1011 : begin
          result = (3'b000);
        end
        4'b0100 : begin
          result = (3'b000);
        end
        4'b1100 : begin
          result = (3'b011);
        end
        4'b0011 : begin
          result = (3'b011);
        end
        4'b1101 : begin
          result = (3'b100);
        end
        4'b0010 : begin
          result = (3'b100);
        end
        4'b1010 : begin
          result = (3'b101);
        end
        4'b0101 : begin
          result = (3'b101);
        end
        4'b0110 : begin
          result = (3'b110);
        end
        4'b1001 : begin
          result = (3'b110);
        end
        4'b0111 : begin
          result = (3'b111);
        end
        4'b1000 : begin
          result = (3'b111);
        end
        default : begin
          error = 1'b1;
        end
      endcase
    end
  end

  assign io_dout = result;
  assign io_error = error;
endmodule

module Decode_5b6b (
      input  [5:0] io_din,
      output [4:0] io_dout,
      output  io_comma,
      output  io_error);
  reg [4:0] result;
  reg  error;
  reg  comma;
  always @ (*) begin
    result = (5'b00000);
    error = 1'b0;
    comma = 1'b0;
    case(io_din)
      6'b100111 : begin
        result = (5'b00000);
      end
      6'b011000 : begin
        result = (5'b00000);
      end
      6'b011101 : begin
        result = (5'b00001);
      end
      6'b100010 : begin
        result = (5'b00001);
      end
      6'b101101 : begin
        result = (5'b00010);
      end
      6'b010010 : begin
        result = (5'b00010);
      end
      6'b110001 : begin
        result = (5'b00011);
      end
      6'b110101 : begin
        result = (5'b00100);
      end
      6'b001010 : begin
        result = (5'b00100);
      end
      6'b101001 : begin
        result = (5'b00101);
      end
      6'b011001 : begin
        result = (5'b00110);
      end
      6'b111000 : begin
        result = (5'b00111);
      end
      6'b000111 : begin
        result = (5'b00111);
      end
      6'b111001 : begin
        result = (5'b01000);
      end
      6'b000110 : begin
        result = (5'b01000);
      end
      6'b100101 : begin
        result = (5'b01001);
      end
      6'b010101 : begin
        result = (5'b01010);
      end
      6'b110100 : begin
        result = (5'b01011);
      end
      6'b001101 : begin
        result = (5'b01100);
      end
      6'b101100 : begin
        result = (5'b01101);
      end
      6'b011100 : begin
        result = (5'b01110);
      end
      6'b010111 : begin
        result = (5'b01111);
      end
      6'b101000 : begin
        result = (5'b01111);
      end
      6'b011011 : begin
        result = (5'b10000);
      end
      6'b100100 : begin
        result = (5'b10000);
      end
      6'b100011 : begin
        result = (5'b10001);
      end
      6'b010011 : begin
        result = (5'b10010);
      end
      6'b110010 : begin
        result = (5'b10011);
      end
      6'b001011 : begin
        result = (5'b10100);
      end
      6'b101010 : begin
        result = (5'b10101);
      end
      6'b011010 : begin
        result = (5'b10110);
      end
      6'b111010 : begin
        result = (5'b10111);
      end
      6'b000101 : begin
        result = (5'b10111);
      end
      6'b110011 : begin
        result = (5'b11000);
      end
      6'b001100 : begin
        result = (5'b11000);
      end
      6'b100110 : begin
        result = (5'b11001);
      end
      6'b010110 : begin
        result = (5'b11010);
      end
      6'b110110 : begin
        result = (5'b11011);
      end
      6'b001001 : begin
        result = (5'b11011);
      end
      6'b001110 : begin
        result = (5'b11100);
      end
      6'b101110 : begin
        result = (5'b11101);
      end
      6'b010001 : begin
        result = (5'b11101);
      end
      6'b011110 : begin
        result = (5'b11110);
      end
      6'b100001 : begin
        result = (5'b11110);
      end
      6'b101011 : begin
        result = (5'b11111);
      end
      6'b010100 : begin
        result = (5'b11111);
      end
      6'b001111 : begin
        result = (5'b11100);
        comma = 1'b1;
      end
      6'b110000 : begin
        result = (5'b11100);
        comma = 1'b1;
      end
      default : begin
        error = 1'b1;
      end
    endcase
  end

  assign io_dout = result;
  assign io_error = error;
  assign io_comma = comma;
endmodule

module Decode_8b10b (
      input  [9:0] io_din,
      output  io_comma,
      output reg [7:0] io_dout,
      output  io_error);
  wire [3:0] _zz_1_;
  wire [5:0] _zz_2_;
  wire [2:0] decode_3b4b_1__io_dout;
  wire  decode_3b4b_1__io_error;
  wire [4:0] decode_5b6b_1__io_dout;
  wire  decode_5b6b_1__io_comma;
  wire  decode_5b6b_1__io_error;
  Decode_3b4b decode_3b4b_1_ ( 
    .io_din(_zz_1_),
    .io_comma_in(io_comma),
    .io_dout(decode_3b4b_1__io_dout),
    .io_error(decode_3b4b_1__io_error) 
  );
  Decode_5b6b decode_5b6b_1_ ( 
    .io_din(_zz_2_),
    .io_dout(decode_5b6b_1__io_dout),
    .io_comma(decode_5b6b_1__io_comma),
    .io_error(decode_5b6b_1__io_error) 
  );
  assign _zz_2_ = io_din[9 : 4];
  assign io_comma = decode_5b6b_1__io_comma;
  assign _zz_1_ = io_din[3 : 0];
  always @ (*) begin
    io_dout[7 : 5] = decode_3b4b_1__io_dout;
    io_dout[4 : 0] = decode_5b6b_1__io_dout;
  end

  assign io_error = (decode_5b6b_1__io_error || decode_3b4b_1__io_error);
endmodule

