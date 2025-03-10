"""
    
    Test bench for the 8b10b encoder / decoder 
    (using Cocotb and Verilator)
    

    Copyright (C) 2025, Yves Acremann, ETH Zurich

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
async def Test8b10b(dut):
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
    dut.data_i = 0x12
    dut.comma_i = 0
    await FallingEdge(dut.clk)
    dut.data_i = 0x34
    await FallingEdge(dut.clk)
    dut.data_i = 0x57
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    
    # send the K28.1 comma symbol
    dut.data_i = int('0b00111100', 2)
    dut.comma_i = 1
    
    
    await Timer(1000, "ns")
