"""
    Testbench for the PulseIdGenerator (using Cococtb)


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
async def TestPulseIdGenerator(dut):
    """Try accessing the design."""

    # set up the clock
    clock = Clock(dut.clk, 25, units="ns")  # Create a 25ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    
    # also create a clock for the cpu clock domain
    clock = Clock(dut.fifo_src_clk_i, 25, units="ns")  # Create a 25ns period clock on port clk
    cocotb.fork(clock.start())  # Start the clock
    
    # Synchronize with the clock
    await FallingEdge(dut.clk)
    
    # set up the input signals and do a reset
    dut.reset = 1
    dut.fifo_src_rst_i = 1
    dut.fifo_write_i = 0
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    
    # switch off the reset
    dut.reset = 0
    dut.fifo_src_rst_i = 0
    dut.trigger = 0
    dut.set_pulse_id = 0;
    dut.new_pulse_id = 0x12345678
    await FallingEdge(dut.clk)
    
    # Test the readback of the last pulse-id:
    rx_data = 0x01
    dut.mram_miso = 0
    
    # wait for the first two MRAM operations:
    await FallingEdge(dut.mram_cs)
    await FallingEdge(dut.mram_cs)
    # Now we can start transmission of the initial value (3rd mram operation)
    await FallingEdge(dut.mram_cs)
    for i in range(0, 8+16):
        await FallingEdge(dut.mram_sck)
    
    for i in range(0, 64):
        dut.mram_miso = ((rx_data >> (63-i)) & 0x01) == 1
        await FallingEdge(dut.mram_sck)
    await Timer(1000, "ns")
    
    # now let's trigger:
    await FallingEdge(dut.clk)
    dut.trigger = 1
    await FallingEdge(dut.clk)
    dut.trigger = 0
    await Timer(5000, "ns")
    
    # and again:
    await FallingEdge(dut.clk)
    dut.trigger = 1
    await FallingEdge(dut.clk)
    dut.trigger = 0
    await Timer(10000, "ns")
    
    # test setting the pulse-id from the CPU:
    dut.new_pulse_id = 10
    dut.set_pulse_id = 1
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    dut.set_pulse_id = 0
    await Timer(10000, "ns")
    
    # put some data into the FIFO:
    await FallingEdge(dut.clk)
    dut.fifo_data_i = 0xdeadbeefbeefdead
    dut.fifo_write_i = 1
    await FallingEdge(dut.clk)
    dut.fifo_data_i = 0x1234567887654321
    await FallingEdge(dut.clk)
    dut.fifo_write_i = 0
    
    # and again a trigger:
    await FallingEdge(dut.clk)
    dut.trigger = 1
    await FallingEdge(dut.clk)
    dut.trigger = 0
    await Timer(20000, "ns")
