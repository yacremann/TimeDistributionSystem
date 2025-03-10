"""
    Testbench for the MRAM interface (Cococtb)


    Copyright (C) 2022, Yves Acremann, ETH Zurich

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

"""

import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.result import TestFailure


@cocotb.test()
async def TestMram(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk, 25, units="ns")  # Create a 25ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    # Synchronize with the clock
    await FallingEdge(dut.clk)
    
    # set up the input signals and do a reset
    dut.reset = 1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    
    # switch off the reset
    dut.reset = 0
    dut.start = 0
    await FallingEdge(dut.clk)
    
    dut.pulse_id_to_write = 0xdeadbeefbeefdead
    dut.write = 1
    
    await Timer(10000, "ns")
    # start the transmission
    dut.start = 1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.start = 0
    
    await Timer(20000, "ns")
    
   # Test the readback:
    rx_data = 0xdeadbeefbeef1234
    dut.write = 0
    dut.start = 1
    
    
    await FallingEdge(dut.cs)
    for i in range(0, 8+16):
        await FallingEdge(dut.sck)
        
    dut.start = 0
    for i in range(0, 64):
        dut.miso = ((rx_data >> (63-i)) & 0x01) == 1
        await FallingEdge(dut.sck)
        
    await Timer(20000, "ns")
    
    
        
    
