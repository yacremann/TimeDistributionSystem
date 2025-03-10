package cpu

import vexriscv.plugin._
import vexriscv._
import vexriscv.{plugin, VexRiscv, VexRiscvConfig}
import vexriscv.ip.{DataCacheConfig, InstructionCacheConfig}
import spinal.core._
import spinal.lib._
import spinal.lib.bus.misc.SizeMapping
import spinal.lib.bus.amba3.apb._
import spinal.lib.bus.amba4.axi._
import spinal.lib.com.jtag.Jtag
import spinal.lib.com.uart.{Apb3UartCtrl, Uart, UartCtrlGenerics, UartCtrlMemoryMappedConfig}
import spinal.lib.io.TriStateArray
import spinal.lib.misc.{InterruptCtrl, Timer, Prescaler, HexTools}
import spinal.lib.soc.pinsec.{PinsecTimerCtrl, PinsecTimerCtrlExternal}
import spinal.lib.system.debugger.{JtagAxi4SharedDebugger, JtagBridge, SystemDebugger, SystemDebuggerConfig}
import scala.collection.mutable.ArrayBuffer
import spinal.lib.bus.avalon.{AvalonMM, AvalonMMConfig}
import spinal.lib.com.spi.{SpiMaster, Apb3SpiMasterCtrl, SpiMasterCtrlMemoryMappedConfig, SpiMasterCtrlGenerics}
import spinal.lib.com.spi.ddr.{SpiXdrMasterCtrl,Apb3SpiXdrMasterCtrl,SpiXdrParameter,SpiXdrMaster}


object Apb3Default {
  def getApb3Config() = Apb3Config(addressWidth = 16,dataWidth = 32)
}

class VexRISCVSoftcore extends Component {

  val io = new Bundle {
    val externalInterrupt = in Bool
    val jtag = slave(Jtag())
    val uart = master(Uart())
    val asyncReset = in Bool
    val mainClk = in Bool
    val apbBus = master(Apb3(Apb3Default.getApb3Config()))
    /* val spi = master(SpiXdrMaster(SpiXdrParameter(
          dataWidth = 2,
          ioRate = 1,
          ssWidth = 1
        ))) */
  }
  noIoPrefix()

  // Clock domain for reset controller
  val resetCtrlClockDomain = ClockDomain(
    clock = io.mainClk,
    config = ClockDomainConfig(
      resetKind = BOOT
    )
  )

  val resetCtrl = new ClockingArea(resetCtrlClockDomain) {
    val systemResetUnbuffered  = False

    // Implement a counter to keep the reset axiResetOrder high 64 cycles
    // Also this counter will automaticly do a reset when the system boot.
    val systemResetCounter = Reg(UInt(6 bits)) init(0)
    when(systemResetCounter =/= U(systemResetCounter.range -> true)){
      systemResetCounter := systemResetCounter + 1
      systemResetUnbuffered := True
    }
    when(BufferCC(io.asyncReset)){
      systemResetCounter := 0
    }

    //Create all reset used later in the design
    val systemReset  = RegNext(systemResetUnbuffered)
    val axiReset     = RegNext(systemResetUnbuffered)
  }

  // Clock domain for complete system (except jtag controller)
  val axiClockDomain = ClockDomain(
    clock = io.mainClk,
    reset = resetCtrl.axiReset,
    frequency = FixedFrequency(40 MHz)
  )

  // Clock domain for JTag (different reset)
  val debugClockDomain = ClockDomain(
    clock = io.mainClk,
    reset = resetCtrl.systemReset,
    frequency = FixedFrequency(40 MHz)
  )

  // Configurations for VexRISCV core
  val cpuConfig = VexRiscvConfig(
    plugins = List(
      new IBusSimplePlugin(
        //resetVector = 0x80000000l,
        resetVector = 0x00000000l,   // use the FLASH!
        //relaxedPcCalculation = false,
        prediction = NONE,
        catchAccessFault = false,
        compressedGen = false,
        cmdForkPersistence = true,
        cmdForkOnSecondStage = false
      ),
      new DBusSimplePlugin(
        catchAddressMisaligned = false,
        catchAccessFault = false
      ),
      new DecoderSimplePlugin(
        catchIllegalInstruction = false
      ),
      new RegFilePlugin(
        regFileReadyKind = plugin.SYNC,
        zeroBoot = false, // needed for the cheaper FPGAs!
        x0Init = true
      ),
      new IntAluPlugin,
      new MulPlugin,
      new DivPlugin,
      new SrcPlugin(
        separatedAddSub = false,
        executeInsertion = false
      ),
      new LightShifterPlugin,
      new HazardSimplePlugin(
        bypassExecute           = false,
        bypassMemory            = false,
        bypassWriteBack         = false,
        bypassWriteBackBuffer   = false,
        pessimisticUseSrc       = false,
        pessimisticWriteRegFile = false,
        pessimisticAddressMatch = false
      ),
      new BranchPlugin(
        earlyBranch = false,
        catchAddressMisaligned = false
      ),
      new CsrPlugin(
        config = CsrPluginConfig(
          catchIllegalAccess = false,
          mvendorid      = null,
          marchid        = null,
          mimpid         = null,
          mhartid        = null,
          misaExtensionsInit = 66,
          misaAccess     = CsrAccess.NONE,
          mtvecAccess    = CsrAccess.READ_WRITE,
          mtvecInit      = 0x80000000l,
          mepcAccess     = CsrAccess.READ_WRITE,
          mscratchGen    = false,
          mcauseAccess   = CsrAccess.READ_ONLY,
          mbadaddrAccess = CsrAccess.READ_ONLY,
          mcycleAccess   = CsrAccess.NONE,
          minstretAccess = CsrAccess.NONE,
          ecallGen       = false,
          wfiGenAsWait   = false,
          ucycleAccess   = CsrAccess.NONE
        )
      ),
      new DebugPlugin(
        debugClockDomain = debugClockDomain,
        hardwareBreakpointCount = 4
      ),
      new YamlPlugin("cpu0.yaml")
    )
  )
  
  

  // Configuration for UART implementation
  val uartCtrlConfig = UartCtrlMemoryMappedConfig(
    uartCtrlConfig = UartCtrlGenerics(
      dataWidthMax      = 8,
      clockDividerWidth = 20,
      preSamplingSize   = 1,
      samplingSize      = 5,
      postSamplingSize  = 2
    ),
    txFifoDepth = 16,
    rxFifoDepth = 16
  )
  
  
  
    
    


  // Clocking area for system (connected by axi)
  val axi = new ClockingArea(axiClockDomain) {

    val externalInterrupt = Bool
    externalInterrupt := io.externalInterrupt

    // BRAM implementation
    val ram = Axi4SharedOnChipRam(
      dataWidth = 32,
      byteCount = 32 kB,
      idWidth = 4
    )
    
    // create the Flasm memory on the axi bus:
    val flash = new Axi4ToIntelFlash(
        addressAxiWidth = 32, 
        addressFlashWidth = 14,
        dataWidth = 32,
        idWidth = 4);

    // APB bridge connection
    val apbBridge = Axi4SharedToApb3Bridge(
      addressWidth = 20,
      dataWidth    = 32,
      idWidth      = 4
    )

    // Timer connection
    val timerCtrl = PinsecTimerCtrl()
    timerCtrl.io.external.clear <> False
    timerCtrl.io.external.tick <> True

    // UART connection
    val uartCtrl = Apb3UartCtrl(uartCtrlConfig)
    io.uart <> uartCtrl.io.uart
    externalInterrupt setWhen(uartCtrl.io.interrupt)


    // SPI interface
    //val spiCtrl = Apb3SpiXdrMasterCtrl(spiConfig)
    //io.spi <> spiCtrl.io.spi
    

    // Main CPU Core
    val cpu = new VexRiscv(cpuConfig)
    

    // now we make connections to the CPU plugins:
    var iBus : Axi4ReadOnly = null
    var dBus : Axi4Shared   = null
    // optional: use the Avalon bus for the FLASH memory:
    //var iBus : AvalonMM = null
    for(plugin <- cpuConfig.plugins) plugin match{
      case plugin : IBusSimplePlugin => iBus = plugin.iBus.toAxi4ReadOnly()
      case plugin : DBusSimplePlugin => dBus = plugin.dBus.toAxi4Shared()
      case plugin : CsrPlugin        => {
        plugin.externalInterrupt := BufferCC(externalInterrupt)
        plugin.timerInterrupt := timerCtrl.io.interrupt
      }
      case plugin : DebugPlugin      => debugClockDomain{
        resetCtrl.axiReset setWhen(RegNext(plugin.io.resetOut))
        io.jtag <> plugin.io.bus.fromJtag()
      }
      case _ =>
    }
    

    // AXI4 bus interconnect
    val axiCrossbar = Axi4CrossbarFactory()

    axiCrossbar.addSlaves(
      ram.io.axi       -> (0x80000000L,  32 kB),
      apbBridge.io.axi -> (0xF0000000L,   1 MB),
      flash.io.axi     -> (0x00000000L,  32 kB)
    )

    axiCrossbar.addConnections(
      iBus            -> List(ram.io.axi, flash.io.axi),
      dBus            -> List(ram.io.axi, flash.io.axi, apbBridge.io.axi)
    )

    axiCrossbar.addPipelining(apbBridge.io.axi) ((crossbar,bridge) => {
      crossbar.sharedCmd.halfPipe() >> bridge.sharedCmd
      crossbar.writeData.halfPipe() >> bridge.writeData
      crossbar.writeRsp             << bridge.writeRsp
      crossbar.readRsp              << bridge.readRsp
    })


    axiCrossbar.addPipelining(ram.io.axi) ((crossbar,ctrl) => {
      crossbar.sharedCmd.halfPipe()  >>  ctrl.sharedCmd
      crossbar.writeData            >/-> ctrl.writeData
      crossbar.writeRsp              <<  ctrl.writeRsp
      crossbar.readRsp               <<  ctrl.readRsp
    })
   
     
    axiCrossbar.addPipelining(flash.io.axi) ((crossbar,ctrl) => {
      crossbar.readCmd.halfPipe()    >>  ctrl.readCmd
      crossbar.readRsp               <<  ctrl.readRsp
    })

    axiCrossbar.addPipelining(dBus)((cpu,crossbar) => {
      cpu.sharedCmd             >>  crossbar.sharedCmd
      cpu.writeData             >>  crossbar.writeData
      cpu.writeRsp              <<  crossbar.writeRsp
      cpu.readRsp               <-< crossbar.readRsp
    })

    axiCrossbar.build()
    

    // APB decoder
    val apbDecoder = Apb3Decoder(
      master = apbBridge.io.apb,
      slaves = List(
        io.apbBus        -> (0x00000, 64 kB),
        uartCtrl.io.apb  -> (0x10000,  4 kB),
        timerCtrl.io.apb -> (0x20000,  4 kB)
        //spiCtrl.io.apb   -> (0x30000,  4 kB)
      )
    )
  }
}


object VexRISCVSoftcoreVerilog {
  def main(args: Array[String]) {
    SpinalVerilog(new VexRISCVSoftcore)
  }
}

