/*
    8b10b encoder / decoder for the time distribution system
    It is the source file used by SpinalHDL to generate the verilog files
    Decoder_8b10b.v and
    Encoder_8b10b.v.
    

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

import spinal.core._
import spinal.lib._



// encode 5b6b
class Encode_5b6b extends Component {
    val io = new Bundle{
        val din = in Bits(5 bit)
        val rdNeg = in Bool
        val comma = in Bool
        val dout = out Bits(6 bit)
        val disparity = out SInt(3 bits)
        val needAlternate = out Bool // True if we need to use the alternate pattern from the 3b4b encoder
    }
    
    val result = Bits(6 bit)
    val disp_neutral = Bool
    disp_neutral := False
    result := "000000" // default, not valid, should never happen!
    io.needAlternate := False
    when(!io.comma){
        switch(io.din){
            is(B"00000") {when(io.rdNeg){result := B"100111"}.otherwise{result := B"011000"}}
            is(B"00001") {when(io.rdNeg){result := B"011101"}.otherwise{result := B"100010"}}
            is(B"00010") {when(io.rdNeg){result := B"101101"}.otherwise{result := B"010010"}}
            is(B"00011") {result := B"110001"; disp_neutral := True}
            is(B"00100") {when(io.rdNeg){result := B"110101"}.otherwise{result := B"001010"}}
            is(B"00101") {result := B"101001"; disp_neutral := True}
            is(B"00110") {result := B"011001"; disp_neutral := True}
            is(B"00111") {when(io.rdNeg){result := B"111000"}.otherwise{result := B"000111"}; disp_neutral := True}
            is(B"01000") {when(io.rdNeg){result := B"111001"}.otherwise{result := B"000110"}}
            is(B"01001") {result := B"100101"; disp_neutral := True}
            is(B"01010") {result := B"010101"; disp_neutral := True}
            is(B"01011") {result := B"110100"; disp_neutral := True; when(!io.rdNeg){io.needAlternate := True}}
            is(B"01100") {result := B"001101"; disp_neutral := True}
            is(B"01101") {result := B"101100"; disp_neutral := True; when(!io.rdNeg){io.needAlternate := True}}
            is(B"01110") {result := B"011100"; disp_neutral := True; when(!io.rdNeg){io.needAlternate := True}}
            is(B"01111") {when(io.rdNeg){result := B"010111"}.otherwise{result := B"101000"}}
            
            is(B"10000") {when(io.rdNeg){result := B"011011"}.otherwise{result := B"100100"}}
            is(B"10001") {result := B"100011"; disp_neutral := True; when(io.rdNeg){io.needAlternate := True}}
            is(B"10010") {result := B"010011"; disp_neutral := True; when(io.rdNeg){io.needAlternate := True}}
            is(B"10011") {result := B"110010"; disp_neutral := True}
            is(B"10100") {result := B"001011"; disp_neutral := True; when(io.rdNeg){io.needAlternate := True}}
            is(B"10101") {result := B"101010"; disp_neutral := True}
            is(B"10110") {result := B"011010"; disp_neutral := True}
            is(B"10111") {when(io.rdNeg){result := B"111010"}.otherwise{result := B"000101"}}
            is(B"11000") {when(io.rdNeg){result := B"110011"}.otherwise{result := B"001100"}}
            is(B"11001") {result := B"100110"; disp_neutral := True}
            is(B"11010") {result := B"010110"; disp_neutral := True}
            is(B"11011") {when(io.rdNeg){result := B"110110"}.otherwise{result := B"001001"}}
            is(B"11100") {result := B"001110"; disp_neutral := True}
            is(B"11101") {when(io.rdNeg){result := B"101110"}.otherwise{result := B"010001"}}
            is(B"11110") {when(io.rdNeg){result := B"011110"}.otherwise{result := B"100001"}}
            is(B"11111") {when(io.rdNeg){result := B"101011"}.otherwise{result := B"010100"}}
        }
    }.otherwise{
        when(io.din === B"11100"){when(io.rdNeg){result := B"001111"}.otherwise{result := B"110000"}}
    }
    io.dout := result
    // calculate disparity
    when(disp_neutral){
        io.disparity := 0
    }.otherwise{
        io.disparity := io.rdNeg ? S(2)| S(-2)
    }
}


// decode 5b/6b
class Decode_5b6b extends Component {
    val io = new Bundle{
        val din = in Bits(6 bit)
        val dout = out Bits(5 bit)
        val comma = out Bool
        val error = out Bool
    }
    
    val result = Bits(5 bit)
    result := B"00000"
    val error = Bool
    error := False
    val comma = Bool
    comma := False
    
    switch(io.din){
        is(B"100111"){result := B"00000"}
        is(B"011000"){result := B"00000"}
        
        is(B"011101"){result := B"00001"}
        is(B"100010"){result := B"00001"}
        
        is(B"101101"){result := B"00010"}
        is(B"010010"){result := B"00010"}
        
        is(B"110001"){result := B"00011"}
        
        is(B"110101"){result := B"00100"}
        is(B"001010"){result := B"00100"}
        
        is(B"101001"){result := B"00101"}
        
        is(B"011001"){result := B"00110"}
        
        is(B"111000"){result := B"00111"}
        is(B"000111"){result := B"00111"}
        
        is(B"111001"){result := B"01000"}
        is(B"000110"){result := B"01000"}
        
        is(B"100101"){result := B"01001"}
        
        is(B"010101"){result := B"01010"}
        
        is(B"110100"){result := B"01011"}
        
        is(B"001101"){result := B"01100"}
        
        is(B"101100"){result := B"01101"}
        
        is(B"011100"){result := B"01110"}
        
        is(B"010111"){result := B"01111"}
        is(B"101000"){result := B"01111"}
        
        is(B"011011"){result := B"10000"}
        is(B"100100"){result := B"10000"}
        
        is(B"100011"){result := B"10001"}
        
        is(B"010011"){result := B"10010"}
        
        is(B"110010"){result := B"10011"}
        
        is(B"001011"){result := B"10100"}
        
        is(B"101010"){result := B"10101"}
        
        is(B"011010"){result := B"10110"}
        
        is(B"111010"){result := B"10111"}
        is(B"000101"){result := B"10111"}
        
        is(B"110011"){result := B"11000"}
        is(B"001100"){result := B"11000"}
        
        is(B"100110"){result := B"11001"}
        
        is(B"010110"){result := B"11010"}
        
        is(B"110110"){result := B"11011"}
        is(B"001001"){result := B"11011"}
        
        is(B"001110"){result := B"11100"}
        
        is(B"101110"){result := B"11101"}
        is(B"010001"){result := B"11101"}
        
        is(B"011110"){result := B"11110"}
        is(B"100001"){result := B"11110"}
        
        is(B"101011"){result := B"11111"}
        is(B"010100"){result := B"11111"}
        
        is(B"001111"){result := B"11100"; comma := True}
        is(B"110000"){result := B"11100"; comma := True}
        
        default{error := True}
    }
    io.dout  := result
    io.error := error
    io.comma := comma
}

// encode 3b/4b
class Encode_3b4b extends Component {
    val io = new Bundle{
        val din     = in Bits(3 bit)
        val rdNeg   = in Bool
        val comma   = in Bool
        val p_code  = in Bool
        val dout    = out Bits(4 bit)
        val disparity = out SInt(3 bits)
    }
    val result = Bits(4 bit)
    result := "0000" // default, not valid, should never happen!
    val disp_neutral = Bool
    disp_neutral := False
    when(!io.comma){
        switch(io.din){
            is(B"000") {when(io.rdNeg){result := B"1011"}.otherwise{result := B"0100"}}
            is(B"001") {result := B"1001"; disp_neutral := True}
            is(B"010") {result := B"0101"; disp_neutral := True}
            is(B"011") {when(io.rdNeg){result := B"1100"}.otherwise{result := B"0011"}; disp_neutral := True}
            is(B"100") {when(io.rdNeg){result := B"1101"}.otherwise{result := B"0010"}}
            is(B"101") {result := B"1010"; disp_neutral := True}
            is(B"110") {result := B"0110"; disp_neutral := True}
            is(B"111") {
                when(io.p_code){
                    when(io.rdNeg){
                        result := B"1110"
                    }.otherwise{
                        result := B"0001"
                    }
                }.otherwise{
                    when(io.rdNeg){
                        result :=B"0111"
                    }.otherwise{
                        result := B"1000"
                    }
                }
            } // is(B"111")
        } // switch
    }.otherwise{
        switch(io.din){
            is(B"000") {when(io.rdNeg){result := B"1011"}.otherwise{result := B"0100"}}
            is(B"001") {when(io.rdNeg){result := B"0110"}.otherwise{result := B"1001"}; disp_neutral := True}
            is(B"010") {when(io.rdNeg){result := B"1010"}.otherwise{result := B"0101"}; disp_neutral := True}
            is(B"011") {when(io.rdNeg){result := B"1100"}.otherwise{result := B"0011"}; disp_neutral := True}
            is(B"100") {when(io.rdNeg){result := B"1101"}.otherwise{result := B"0010"}}
            is(B"101") {when(io.rdNeg){result := B"0101"}.otherwise{result := B"1010"}; disp_neutral := True}
            is(B"110") {when(io.rdNeg){result := B"1001"}.otherwise{result := B"0110"}; disp_neutral := True}
            is(B"111") {when(io.rdNeg){result := B"0111"}.otherwise{result := B"1000"}}
        } // switch
    } // otherwise !io.comma
    io.dout := result
    // calculate disparity
    when(disp_neutral){
        io.disparity := 0
    }.otherwise{
        io.disparity := io.rdNeg ? S(2)| S(-2)
    }
}


// decode 3b/4b
class Decode_3b4b extends Component {
    val io = new Bundle{
        val din      = in Bits(4 bit)
        val comma_in = in Bool
        val dout     = out Bits(3 bit)
        val error    = out Bool
    }
    
    val result = Bits(3 bit)
    result := B"000"
    val error = Bool
    error := False
    
    when(!io.comma_in){
        switch(io.din){
            is(B"1011"){result := B"000"}
            is(B"0100"){result := B"000"}
            
            is(B"1001"){result := B"001"}
            
            is(B"0101"){result := B"010"}
            
            is(B"1100"){result := B"011"}
            is(B"0011"){result := B"011"}
            
            is(B"1101"){result := B"100"}
            is(B"0010"){result := B"100"}
            
            is(B"1010"){result := B"101"}
            
            is(B"0110"){result := B"110"}
            
            is(B"1110"){result := B"111"}
            is(B"0001"){result := B"111"}
            is(B"0111"){result := B"111"}
            is(B"1000"){result := B"111"}
            
            default{error := True}
        } // switch
    }.otherwise{
        switch(io.din){
            is(B"1011"){result := B"000"}
            is(B"0100"){result := B"000"}
            
            //is(B"1001"){result := B"001"}
            //is(B"0110"){result := B"001"}
            
            //is(B"0101"){result := B"010"}
            //is(B"1010"){result := B"010"}
            
            is(B"1100"){result := B"011"}
            is(B"0011"){result := B"011"}
            
            is(B"1101"){result := B"100"}
            is(B"0010"){result := B"100"}
            
            is(B"1010"){result := B"101"}
            is(B"0101"){result := B"101"}
            
            is(B"0110"){result := B"110"}
            is(B"1001"){result := B"110"}
            
            
            is(B"0111"){result := B"111"}
            is(B"1000"){result := B"111"}
            default{error := True}
        }
    }
    io.dout   := result
    io.error  := error
}

// the actual 8b/10b encoder:
// For comma: Only encode K28.7
class Encode_8b10b extends Component {
    val io = new Bundle{
        val din     = in Bits(8 bit)
        val comma   = in Bool
        val tick    = in Bool
        val dout    = out Bits(10 bit)
    }
    val rd = RegInit(True)
    val abcdei = Bits(6 bit)
    val fghj = Bits(4 bit)
    val result = Bits(10 bit)
    
    val encode_5b6b = new Encode_5b6b
    val encode_3b4b = new Encode_3b4b
    
    encode_5b6b.io.din := io.din(4 downto 0)
    encode_3b4b.io.din := io.din(7 downto 5)
    encode_3b4b.io.p_code := !encode_5b6b.io.needAlternate
    
    encode_5b6b.io.comma := io.comma
    encode_3b4b.io.comma := io.comma
    
    val new_disp = SInt(3 bit)
    // first try to correct for the RD by the 5b6b encoder:
    encode_5b6b.io.rdNeg := !rd
    // if that did not work: use the 3b4b encoder for disparity
    when(encode_5b6b.io.disparity === 0){
        encode_3b4b.io.rdNeg := !rd
    }.otherwise{
        encode_3b4b.io.rdNeg := rd
    }
    
    result(3 downto 0) := encode_3b4b.io.dout
    result(9 downto 4) := encode_5b6b.io.dout
    new_disp := encode_3b4b.io.disparity + encode_5b6b.io.disparity
    
    
    // update the running disparity:
    when(new_disp =/= 0){
        when (io.tick === True){
            rd := (new_disp > 0)
        }
    }
    
    io.dout := result
}

class Decode_8b10b extends Component {
    val io = new Bundle{
        val din     = in Bits(10 bit)
        val comma   = out Bool
        val dout    = out Bits(8 bit)
        val error   = out Bool
    }
    val decode_3b4b = new Decode_3b4b()
    val decode_5b6b = new Decode_5b6b()
    decode_5b6b.io.din := io.din(9 downto 4)
    io.comma := decode_5b6b.io.comma
    decode_3b4b.io.din := io.din(3 downto 0)
    decode_3b4b.io.comma_in := io.comma
    io.dout(7 downto 5) := decode_3b4b.io.dout
    io.dout(4 downto 0) := decode_5b6b.io.dout
    io.error := decode_5b6b.io.error | decode_3b4b.io.error
}



class test_8b10b extends Component {
    val io = new Bundle{
        val din     = in Bits(8 bit)
        val comma   = in Bool
        val decoded = out Bits(8 bit)
        val rd_total = out SInt(8 bit)
        val encoded  = out Bits(10 bit)
        val error    = out Bool
    }
    
    val encoder = new Encode_8b10b()
    val decoder = new Decode_8b10b()
    encoder.io.din := io.din
    encoder.io.comma := io.comma
    encoder.io.tick := True
    decoder.io.din := encoder.io.dout
    io.decoded := decoder.io.dout
    
    // Update the running disparity (combinational)
    val rd = Reg(SInt(8 bit)) init(0)
    val rd_vec = Vec(SInt(3 bit), 10)
    var i = 0
    val result = Bits(10 bit)
    result := encoder.io.dout

    // measure the RD (and make sure it is not too large!)
    when(result(0)){
            rd_vec(0) := + 1
        }.otherwise{
            rd_vec(0) :=  -1
        }
    for(i <- 1 to 9){
        when(result(i)){
            rd_vec(i) := rd_vec(i-1) + 1
        }.otherwise{
            rd_vec(i) := rd_vec(i-1) -1
        }
    }
    rd := rd + rd_vec(9)
    io.rd_total := rd
    
    io.encoded := encoder.io.dout
    io.error := decoder.io.error
    
}



// Simulate the 8b10b coding:
import spinal.sim._
import spinal.core.sim._


object CodecTester {
    
  // function to check for the longest run in a symbol
  def checkRunLength(value: Int) : Int = {
    var j = 0
    var len = 1
    var maxLen = 1
    var lastBit = ((value >> 0) & 1) == 1
    for (j <- 1 to 9){
        if (lastBit == (((value >> j) & 1) == 1)){
            len = len + 1
        } else{
            // check if we have a new max length:
            if (len > maxLen){maxLen = len}
            len = 1
            lastBit = ((value >> j) & 1) == 1
        }
    }
    return maxLen
  }
  
  
    
  def main(args: Array[String]): Unit = {
    SimConfig
	.withWave.compile(new test_8b10b)
	.doSim{ dut =>
        dut.clockDomain.assertReset()
        dut.clockDomain.fallingEdge()
        sleep(20)
        dut.clockDomain.forkStimulus(period = 20)
        var i = 0
        dut.io.comma #= false
        for (i <- 0 to 255){
            dut.io.din #= i
            dut.clockDomain.waitRisingEdge()
            // check the correct decoded value
            assert(i==dut.io.decoded.toInt)
            // check the running disparity never exceeds +/-2
            assert(dut.io.rd_total.toInt <=  2)
            assert(dut.io.rd_total.toInt >= -2)
            // check for the run length: Here we only transmit bytes, not commas!
            assert(checkRunLength(dut.io.encoded.toInt) < 5)
            // check that no error is reported
            assert(dut.io.error.toBoolean == false)
            dut.clockDomain.waitFallingEdge()
            sleep(11)
        }
        // TODO: test the comma symbol
    }
  }
}



object Encode_8b10bVerilog {
  def main(args: Array[String]) {
    SpinalVerilog(new Encode_8b10b)
  }
}

object Decode_8b10bVerilog {
  def main(args: Array[String]) {
    SpinalVerilog(new Decode_8b10b)
  }
}
