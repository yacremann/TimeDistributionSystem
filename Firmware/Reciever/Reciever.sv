/*

    This module implements the top level of the receiver.

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

*/

module Reciever(
	input  logic clk_40Mhz,
	input  logic clk_40Mhz_2,
	output logic RESETn,
	
	
	// ft2232
   output logic TX,
   input  logic RX,
	
	// SPI to AD9544
	input  logic SPI_Timer_SDO,
	output logic SPI_Timer_SCLK,
	output logic SPI_Timer_SDI,
	output logic SPI_Timer_CSB,
	
	// status PLL
	input  logic pll_locked,
	
	output logic [10:0] GPIO,
	
	input  logic word_clk,
	
	input  logic [9:0] deserialized,
	input  logic LOCKn,
	output logic RCLKRf,
	
	input logic slow_data,
	
	// the triger outputs
	output logic trigger1,
	output logic trigger2,
	output logic trigger3,
	output logic trigger4,
	
	// LEDs
	output logic led1,
	output logic led2,
	output logic led3,
	
	output logic serial_o1,
   output logic serial_o2,
   output logic serial_o3,
   output logic serial_o4
);

   ////////////////////////////
   localparam int board = 1;
   ////////////////////////////

   // Microcontroller
	
	logic unsigned [4:0] resetCounter;
	logic reset;
	always_ff @(posedge clk_40Mhz) begin
	    if (resetCounter < 10)
			resetCounter <= resetCounter + 1;
	end
	assign reset = (resetCounter < 10);
	
	logic tms;
   logic tdi;
   logic tdo;
   logic tck;
   assign tms = 0;
   assign tdi = 0;
   assign tck = 0;
	
	// This is our APB master bus from the controller
   ApbBus bus();
   assign bus.PCLK    = clk_40Mhz;
   assign bus.PRESETn = !reset; //!reset_quartus;
	
	
	
	// the processor:
   VexRISCVSoftcore processor(
      .externalInterrupt(0),
      .jtag_tms(tms),
      .jtag_tdi(tdi),
      .jtag_tdo(tdo),
      .jtag_tck(tck),
      .uart_txd(TX),
      .uart_rxd(RX),
      
		.asyncReset(reset),
      .mainClk(clk_40Mhz),
      .apbBus_PADDR(bus.PADDR),
		.apbBus_PSEL(bus.PSEL),
		.apbBus_PENABLE(bus.PENABLE),
		.apbBus_PREADY(bus.PREADY),
		.apbBus_PWRITE(bus.PWRITE),
		.apbBus_PWDATA(bus.PWDATA),
		.apbBus_PRDATA(bus.PRDATA),
		.apbBus_PSLVERROR(bus.PSLVERROR)
   );
	
	// Addresses:
	 parameter integer numOfSlaves = 2;
	 parameter integer addresses [numOfSlaves] = '{
		  0,     // GPIO register
		  4	   // status reg
	 };
	 
	 // the slave buses:
	 ApbBus slave_buses [numOfSlaves] () ;
	 
	 
	 // the multiplexer:
	 ApbMultiplexer #(
		  .NumOfSlaves(numOfSlaves), 
		  .StartAddresses(addresses),
		  .EndAddresses(addresses)
	 ) mux(
		  .master(bus),
		  .slaves(slave_buses)
	 );
		
	 // control register (also used for SPI communication with the AD9544 using bitbangign)
	 logic [31:0] control;
    ApbWriteRegister #(.Address(addresses[0])) controlReg(.bus(slave_buses[0]), .value(control));
    
    
	 // status register (also used for SPI communication with the AD9544 using bitbangign)
	 logic [31:0] status;
	 ApbReadRegister #(.Address(addresses[1])) statusReg(.bus(slave_buses[1]), .value(status));
	 
	 // SPI bitbanging:
	 assign SPI_Timer_SCLK = control[0];
	 assign SPI_Timer_CSB  = control[1];
    assign SPI_Timer_SDI  = control[2];
	 assign status[0] = SPI_Timer_SDO;
	 
	 // reset of the AD9544:
	 assign RESETn = (control[3]== 1) ? 0 : 1'bz;
	
	
	
	// get some test signals to the GPIO pins:
	assign GPIO[0] = LOCKn;
	assign RCLKRf = 1;
	assign GPIO[1] = comma_reg;
	assign GPIO[2] = frame_error;
	
	
	// data input register (very important!)
	logic [9:0] deserialized_reg0;
	logic [9:0] deserialized_reg;
	always_ff @(posedge word_clk) begin
	   deserialized_reg0 <= deserialized;
		deserialized_reg <= deserialized_reg0;
	end
	
    
	// try to decode the deserialized data:
	logic error;
	logic comma;
	logic [7:0] data;
	Decode_8b10b decoder(
      .io_din(deserialized_reg),
      .io_comma(comma),
      .io_dout(data),
      .io_error(error)
	);
    
	
	// register the data after the 8b10b decoder:
	logic comma_reg;
	logic error_reg;
	logic [7:0] data_reg;
	always_ff @(posedge word_clk) begin
		comma_reg <= comma;
		error_reg <= error;
		data_reg  <= data;
	end
	
	// the frame receiver
	payload_t payload;
	logic frame_tick;
	logic frame_error;
	logic reset_frame_receiver;
	FrameReceiver frameReceiver(
		.clk(word_clk),
		.reset(reset_frame_receiver),
		.word_tick_i(1),
		.comma_i(comma_reg),
		.data_i(data_reg),
		.error_i(error_reg),
    
		.frame_tick_o(frame_tick),
		.payload_o(payload),
		.error_o(frame_error)
		); 
	 // watchdog: if there are errors for 1s: cause a reset
	 Watchdog #(
	     .WAIT_CYCLES(800000000)
	 ) watchdog (
	     .clk_i(word_clk),
		  .reset_i(reset),
		  .error_i(frame_error),
		  .reset_o(reset_frame_receiver)
	 );
        
    // add the trigger 1
    Trigger #(
        .board_number(board),
        .channel_number(1)
    ) trigger_gen_1(
        .clk(word_clk),
        .reset(0),
        .frame_tick_i(frame_tick),
        .payload_i(payload),
        .pulse_o(trigger1)
    ); 
	 
    
    // add the trigger 2
    Trigger #(
        .board_number(board),
        .channel_number(2)
    ) trigger_gen_2(
        .clk(word_clk),
        .reset(0),
        .frame_tick_i(frame_tick),
        .payload_i(payload),
        .pulse_o(trigger2)
    );
    
    // add the trigger 3
    Trigger #(
        .board_number(board),
        .channel_number(3)
    ) trigger_gen_3(
        .clk(word_clk),
        .reset(0),
        .frame_tick_i(frame_tick),
        .payload_i(payload),
        .pulse_o(trigger3)
    );
    
    // add the trigger 4
    Trigger #(
        .board_number(board),
        .channel_number(4)
    ) trigger_gen_4(
        .clk(word_clk),
        .reset(0),
        .frame_tick_i(frame_tick),
        .payload_i(payload),
        .pulse_o(trigger4)
    );
        
    // here we add the transmitter for the pulse-ID to the frame grabber / digitizer:
    // We send the data frame as received, without any checks.
    logic serial;
	 SlowTransmitter2 #(
        .bit_clk_divider(80) // we run the slow link at 1 MBit/s
    ) slowTransmitter(
        .clk(word_clk),
        .reset(0),
        .payload_i(payload),
        .frame_tick_i(frame_tick),
        .serial_o(serial),
        .idle()
    );
	 
    assign serial_o1 = serial;
    assign serial_o2 = serial;
    assign serial_o3 = serial;
    assign serial_o4 = serial;
    
	
	assign GPIO[9:4] = payload.data[5:0];
	
	// try to see if there is a good comma signal (make long pulses for monitoring on the scope):
	logic unsigned [31:0] comma_counter;
	always_ff @(posedge word_clk) begin
		if (frame_tick == 1)
			comma_counter <= 100000;
		else if (comma_counter > 0)
			comma_counter <= comma_counter - 1;
	end
	assign GPIO[3] = (comma_counter > 0);
	
	// test the slow pulse-id connection:
	assign GPIO[10] = slow_data;
	
	
	
	
	// LEDs:
	
	// LED 1 indicates errors (frame errors as well as invalid 8b/10b codes)
	pulse_extender extender_led1(
		.clk(word_clk),
		.pulse_in(frame_error | error_reg),
		//.pulse_in(error_reg),
		.pulse_out(led1)
	);
	
	// LED 2 is on once the PLLs are locked.
	assign led3 = pll_locked;
	
	// LED 3 indicates reception of the 100 Hz pulses
	pulse_extender extender_led2(
		.clk(word_clk),
		.pulse_in(frame_tick),
		.pulse_out(led2)
	);
	
	
	
	

endmodule
