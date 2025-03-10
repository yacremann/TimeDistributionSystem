"""

    Testbench for the pulse-id receiver of the time distribution system.
    We use cocotb as well as verilator for sinulation.

    Copyright (C) 2025  Yves Acremann, ETH Zurich

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

async def put_byte(dut, data, comma):
    dut.comma_i = comma
    dut.error_i = 0
    dut.data_i = data
    await FallingEdge(dut.clk)
    dut.word_tick_i = 1
    await FallingEdge(dut.clk)
    dut.word_tick_i = 0
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)

@cocotb.test()
async def TestPulseIdGenerator(dut):
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
    dut.comma_i = 0
    dut.error_i = 0
    dut.word_tick_i = 0
    await FallingEdge(dut.clk)
    await FallingEdge(dut.clk)
    
    # send commas
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    
    pulse_id_to_send = 0xdeadbeefbeefdead
    
    # receive a frame:
    await put_byte(dut, 0x01, 0)
    for i in range (0, 8):
        await put_byte(dut, 0x00, 0)
    for i in range (0, 8):
        await put_byte(dut, pulse_id_to_send >> (8-i-1)*8 & 0xff, 0)
    
    # send crc
    await put_byte(dut, 0x6e, 0)
    await put_byte(dut, 0xa9, 0)
    
    # send commas:
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    
    await Timer(1000, "ns")
    
    await FallingEdge(dut.clk)
    
    pulse_id_to_send = 0x1234567887654321
    
    # receive a frame:
    await put_byte(dut, 0x01, 0)
    for i in range (0, 8):
        await put_byte(dut, 0x00, 0)
    for i in range (0, 8):
        await put_byte(dut, pulse_id_to_send >> (8-i-1)*8 & 0xff, 0)
    
    # send crc
    await put_byte(dut, 0xf5, 0)
    await put_byte(dut, 0x15, 0)

    # send commas:
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await put_byte(dut, 0x00, 1)
    await Timer(1000, "ns")
