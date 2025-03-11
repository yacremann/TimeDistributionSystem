"""

    Test bench of the trgger circuit (using Cocotb and Verilator)

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
async def TestTrigger(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk, 25, units="ns")  # Create a 25ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    # Synchronize with the clock
    await FallingEdge(dut.clk)
    
    # reset
    dut.reset = 1
    await FallingEdge(dut.clk)
    dut.reset = 0
    await FallingEdge(dut.clk)
    
    # set delay
    # set board 1, channel 1, pulser ON, delay 10, length 5
    dut.delay_i = 10
    dut.length_i = 5
    dut.mod_i = 2
    dut.div_i = 5
    dut.frame_type_i = 2
    dut.frame_tick_i = 1
    await FallingEdge(dut.clk)
    dut.frame_tick_i = 0
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    
    for i in range(0, 20):
        # trigger
        await FallingEdge(dut.clk)
        dut.pulse_id_i = i
        dut.frame_type_i = 1
        dut.frame_tick_i = 1
        await FallingEdge(dut.clk)
        dut.frame_tick_i = 0
        await FallingEdge(dut.clk)
        await Timer(10000, "ns")
    
    
