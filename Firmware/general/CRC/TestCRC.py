import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.result import TestFailure


@cocotb.test()
async def TestCRC(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk_i, 25, units="ns")  # Create a 25ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    # Synchronize with the clock
    await FallingEdge(dut.clk_i)
    
    # set up the input signals and do a reset
    dut.rst_i = 1
    await FallingEdge(dut.clk_i)
    await FallingEdge(dut.clk_i)
    dut.rst_i = 0
    dut.soft_reset_i = 0
    await FallingEdge(dut.clk_i)
    await FallingEdge(dut.clk_i)
    dut.data_i = 0x12
    dut.valid_i = 1
    await FallingEdge(dut.clk_i)
    dut.data_i = 0x34
    await FallingEdge(dut.clk_i)
    dut.data_i = 0x56
    await FallingEdge(dut.clk_i)
    dut.data_i = 0x78
    await FallingEdge(dut.clk_i)
    
    # test if 0:
    
    dut.data_i = 0x1e
    await FallingEdge(dut.clk_i)
    dut.data_i = 0x83
    await FallingEdge(dut.clk_i)
    
    
    dut.valid_i = 0
    await Timer(100, "ns")
