"""
    Test bench to test the slow transmitter with a slow receiver
    (for getting the PID parameters working)
    This code is used Cocotb and Verilator

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
async def TestTogether(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk, 25, units="ns")  # Create a 25ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    # Synchronize with the clock
    await FallingEdge(dut.clk)
    
    # set up the input signals and do a reset
    dut.reset = 1
    dut.frame_tick_i = 0
    dut.data_i = 0
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    
    # switch off the reset
    dut.reset = 0
    await FallingEdge(dut.clk)
    await Timer(1000000, "ns")
    await FallingEdge(dut.clk)
    # put data into the FIFO:
    
    dut.data_i = 0xdeadbeef
    dut.frame_tick_i = 1
    await FallingEdge(dut.clk)
    dut.frame_tick_i = 0
    
    await Timer(400000, "ns")
    
