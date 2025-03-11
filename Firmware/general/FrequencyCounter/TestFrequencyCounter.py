"""

    Testbench fot the frequency counter (using Cocotb and Verilator)

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

"""


import cocotb
from cocotb.triggers import Timer
from cocotb.clock import Clock
from cocotb.triggers import FallingEdge, RisingEdge
from cocotb.result import TestFailure


@cocotb.test()
async def TestFrequencyCounter(dut):
    """Try accessing the design."""

    
    # set up the clock
    clock = Clock(dut.clk_40MHz, 25, units="ns")  # Create a 25ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    clock2 = Clock(dut.clk_80MHz, 12.5, units="ns")  # Create a 25ns period clock on port clk
    cocotb.fork(clock2.start())  # Start the clock
    
    # Synchronize with the clock
    await FallingEdge(dut.clk_40MHz)
    
    # reset
    dut.reset = 1
    await FallingEdge(dut.clk_40MHz)
    dut.reset = 0
    await FallingEdge(dut.clk_40MHz)
    
    
    await Timer(10000, "ns")
    
    
