/*

    This is an implementation of the SystemVerilog part of the test
    bench for the APB bus.

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

*/

module BusTester(
    input  logic clk,
    input  logic reset,
    input  logic [16-1:0]   PADDR,
    input  logic [0:0]      PSEL,
    input  logic            PENABLE,
    output logic            PREADY,
    input  logic            PWRITE,
    input  logic [32-1:0]   PWDATA,
    output logic [32-1:0]   PRDATA,
    output logic            PSLVERROR,
    output logic [32-1:0]   result1,
    output logic [32-1:0]   result2
);

    // make a bus and assign all signals to the testbench ports
    ApbBus bus;
    assign bus.PCLK = clk;
    assign bus.PRESETn = !reset;
    assign bus.PADDR = PADDR;
    assign bus.PSEL = PSEL;
    assign bus.PENABLE = PENABLE;
    assign bus.PWRITE = PWRITE;
    assign bus.PWDATA = PWDATA;
    assign PREADY = bus.PREADY;
    assign PRDATA = bus.PRDATA;
    assign PSLVERROR = bus.PSLVERROR;
    
    // define the addresses of the slaves:
    parameter integer numOfSlaves = 3;
    parameter integer addresses [numOfSlaves] = '{
        123,    // write register 1 address
        456,    // write register 2 address
        10      // read register address
    };
    
    // the slave buses:
    ApbBus slave_buses [numOfSlaves];
    
    // the multiplexer:
    ApbMultiplexer #(
        .NumOfSlaves(numOfSlaves), 
        .StartAddresses(addresses),
        .EndAddresses(addresses)
    ) mux(
        .master(bus.Slave),
        .slaves(slave_buses)
    );
    
    // now we can connect our registers to the bus: Two write registers:
    ApbWriteRegister #(.Address(addresses[0])) writeReg1(.bus(slave_buses[0].Slave), .value(result1));
    ApbWriteRegister #(.Address(addresses[1])) writeReg2(.bus(slave_buses[1].Slave), .value(result2));
    
    // and one read register with const. value 255
    ApbReadRegister #(.Address(addresses[2])) readReg(.bus(slave_buses[2].Slave), .value(255));
    
endmodule
