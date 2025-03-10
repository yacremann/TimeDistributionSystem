"""

    This is the Cocotb test bench of the APB-bus.

    Copyright (C) 2021, Yves Acremann, ETH Zurich

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
from cocotb.triggers import FallingEdge,ClockCycles,RisingEdge
from cocotb.result import TestFailure
import math as m
import numpy as np
#import mpmath as m

async def write(dut, addr, data):
    await FallingEdge(dut.clk)
    # setup a transfer to the register:
    dut.PADDR = addr
    dut.PSEL = 1
    dut.PWRITE = 1
    dut.PWDATA = data
    await FallingEdge(dut.clk)
    dut.PENABLE = 1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.PADDR = 0
    dut.PSEL = 0
    dut.PENABLE = 0
    dut.PWRITE = 0
    dut.PWDATA = 0
    
async def read(dut, addr, assert_value):
    await FallingEdge(dut.clk)
    # perform a read access:
    dut.PADDR = addr
    dut.PSEL = 1
    dut.PWRITE = 0
    await FallingEdge(dut.clk)
    dut.PENABLE = 1
    await FallingEdge(dut.clk)
    await RisingEdge(dut.clk)
    assert(dut.PRDATA == assert_value)
    await FallingEdge(dut.clk)
    dut.PADDR = 0
    dut.PSEL = 0
    dut.PENABLE = 0
    dut.PWRITE = 0
    dut.PWDATA = 0

    

@cocotb.test()
async def Testbench(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk, 20, units="ns")  # Create a 20ns period clock on port clk_i
    cocotb.fork(clock.start())  # Start the clock
    # Synchronize with the clock
    await FallingEdge(dut.clk)
    
    # set up the input signals and do a reset
    dut.PADDR = 0
    dut.PSEL = 0
    dut.PENABLE = 0
    dut.PWRITE = 0
    dut.PWDATA = 0
    dut.reset = 1
    
    await FallingEdge(dut.clk)
    dut.reset = 0
    
    await Timer(100, "ns")
    await write(dut, 123, 12345)
    
    await Timer(100, "ns")
    await (read(dut, 123, 12345))
    
    await Timer(100, "ns")
    await write(dut, 456, 9876)
    
    await Timer(100, "ns")
    await (read(dut, 456, 9876))
    
    await (read(dut, 10, 255))
        
    # lets see what happens...
    await Timer(100, "ns")
    
