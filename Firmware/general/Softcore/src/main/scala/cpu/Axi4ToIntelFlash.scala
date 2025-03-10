/*                                                                           *\
**        _____ ____  _____   _____    __                                    **
**       / ___// __ \/  _/ | / /   |  / /   HDL Lib                          **
**       \__ \/ /_/ // //  |/ / /| | / /    (c) Dolu, All rights reserved    **
**      ___/ / ____// // /|  / ___ |/ /___                                   **
**     /____/_/   /___/_/ |_/_/  |_/_____/  MIT Licence                      **
**                                                                           **
** Permission is hereby granted, free of charge, to any person obtaining a   **
** copy of this software and associated documentation files (the "Software"),**
** to deal in the Software without restriction, including without limitation **
** the rights to use, copy, modify, merge, publish, distribute, sublicense,  **
** and/or sell copies of the Software, and to permit persons to whom the     **
** Software is furnished to do so, subject to the following conditions:      **
**                                                                           **
** The above copyright notice and this permission notice shall be included   **
** in all copies or substantial portions of the Software.                    **
**                                                                           **
** THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS   **
** OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF                **
** MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.    **
** IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY      **
** CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT **
** OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR  **
** THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                **
\*                                                                           */

// taken from SpinalHDL library and modified bu Yves Acremann, 2021
// This is certainly not the most efficient way; the FLASH memory needs
// a lot of time for reading; burst mode (using the FLASH) would help a lot!
// TODO: Use "real" burst mode provided by the flash memory!

package spinal.lib.bus.amba4.axi
import spinal.core._
import spinal.lib._


/**
  * State of the state machine of the wrapper
  */
object Axi4ToIntelFlashPhase extends SpinalEnum{
  val SETUP, ACCESS, READ, RESPONSE = newElement
}


// the Intel UFM flash memory:
class ROM (addressWidth: Int, dataWidth: Int) extends BlackBox {

  // Define IO of the Verilog module
  val io = new Bundle {
    val clock = in Bool
    val avmm_data_addr = in Bits(addressWidth bit)
    val avmm_data_read = in Bool
    val avmm_data_readdata = out Bits(dataWidth bit)
    val avmm_data_waitrequest = out Bool
    val avmm_data_readdatavalid = out Bool
    val avmm_data_burstcount = in Bits(4 bit)
    val reset_n = in Bool
  }
  noIoPrefix()
  mapCurrentClockDomain(io.clock)

  // Add all rtl dependencies
  addRTLPath("ROM.v") 
}



class Axi4ToIntelFlash(addressAxiWidth: Int, addressFlashWidth: Int, dataWidth: Int, idWidth: Int) extends Component {
  import Axi4ToIntelFlashPhase._

  assert(addressAxiWidth >= addressFlashWidth, "Address of the Flash bus can be bigger than the Axi address")

  val axiConfig = Axi4Config(
        addressWidth = addressAxiWidth,
        dataWidth    = dataWidth,
        idWidth      = idWidth,
        useLock      = false, 
        useRegion    = false,
        useCache     = false,
        useProt      = false,
        useQos       = false
      )

  val io = new Bundle{
    val axi  = slave(Axi4ReadOnly(axiConfig))
  }

  val phase      = RegInit(SETUP)
  val lenBurst   = Reg(cloneOf(io.axi.ar.len))
  val ar         = Reg(cloneOf(io.axi.ar.payload))
  val readData   = Reg(cloneOf(io.axi.r.data))

  def isEndBurst = lenBurst === 0
  
  // the flash:
  val flash = new ROM(addressFlashWidth, dataWidth)
  flash.io.reset_n  := True

  io.axi.ar.ready   := False
  io.axi.r.valid    := False
  io.axi.r.resp     := Axi4.resp.OKAY
  io.axi.r.id       := ar.id
  io.axi.r.data     := readData
  io.axi.r.last     := isEndBurst

  flash.io.avmm_data_read        := False
  flash.io.avmm_data_addr        := ar.addr.asBits(addressFlashWidth-1+2 downto 2)
  flash.io.avmm_data_burstcount  := 1 // we only support burst on the axi bus so far...
  
  /**
    * Main state machine
    */
  val sm = new Area {
    switch(phase){
        
      // Initialize a transfer (can also be a burst)
      is(SETUP){
        ar        := io.axi.ar
        lenBurst  := io.axi.ar.len

        when(io.axi.ar.valid){
          io.axi.ar.ready  := True
          phase            := READ
        }
      }
      
      // Create a new address and give the read command
      is(ACCESS){
        flash.io.avmm_data_read := False
        ar.addr := Axi4.incr(ar.addr , ar.burst, ar.len, ar.size, 4)
        phase := READ
      }
      
      /*
      is (READ_EN){
            flash.io.avmm_data_read := True
            phase := READ
      } */
      
      // Wait for the flash memory to have valid data; give the response
      is(READ){
        flash.io.avmm_data_read := True
        
        when (flash.io.avmm_data_readdatavalid){
            phase    := RESPONSE
            readData := flash.io.avmm_data_readdata
        }
      }
      
      
      
      // Provide the valid signal to the bus;
      // decrement the burst counter and either go to access of setup
      default{ // RESPONSE
          //flash.io.avmm_data_read := True // was commented out
          flash.io.avmm_data_read := False
          io.axi.r.valid   := True
          when(io.axi.r.ready){
            when(isEndBurst){
              phase    := SETUP
            }otherwise{
              lenBurst := lenBurst - 1
              phase    := ACCESS
            }
          }
      } // default
      
    } // switch
  } // Area
}
