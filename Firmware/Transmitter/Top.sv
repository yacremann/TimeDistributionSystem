/*

    This module implements the top level of the transmitter.

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

*/

module Top(
    input logic clk,
    inout logic reset_n,
    
    // ft2232
    output logic TX,
    input  logic RX,
    
    // SPI to AD9543
	 input  logic SPI_Timer_SDO,
	 output logic SPI_Timer_SCLK,
	 output logic SPI_Timer_SDI,
	 output logic SPI_Timer_CSB,
	 
	 // M0 .. M2 of the AD9543
	 input logic M0, // PLLs locked
	 input logic M1, // REFA active
	 input logic M2,
	 
    
    inout [11:0] GPIO,
	 
	 output MRAM_WPn,
	 input  MRAM_SO,
	 output MRAM_CSn,
	 output MRAM_HOLDn,
	 output MRAM_SCK,
	 output MRAM_SI,
	 
	 // timing singals (80MHz clock domain):
	 input logic clk_80_Mhz,
	 input logic trigger_100_hz_i,
	 output logic tclkr,                     // serializer: select the phase of the tclk
	 output logic sync,                      // sync signal for the serializer
	 
	 output logic [9:0 ] to_serializer,
     
     // the slow data chanel:
     output logic slow_pulse_id,
	  
	  output logic led1,
	  output logic led2,
	  output logic led3
    
);
	 
	 logic trigger_100_hz;
    logic inhibit_trigger;
	 assign trigger_100_hz = trigger_100_hz_i & !inhibit_trigger;
	
	 
	 // artificial 100 Hz test trigger
	 logic unsigned [23:0] counter_100_hz;
	 always_ff @(posedge clk_80_Mhz) begin
	     if (counter_100_hz < 'd800000) begin
		      counter_100_hz <= counter_100_hz + 'd1;
		  end else begin
		      counter_100_hz <= 0;
		  end
	 end
	 //assign trigger_100_hz = (counter_100_hz < 1000);
	 
	 
	 logic unsigned [4:0] resetCounter;
	 logic reset;
	 always_ff @(posedge clk) begin
		if (resetCounter < 10)
			resetCounter <= resetCounter + 1;
	 end
	 assign reset = (resetCounter < 10);

    logic tms;
    logic tdi;
    logic tdo;
    logic tck;
    assign tms = 0; //GPIO[11];
    assign tdi = 0; //GPIO[10];
    assign tck = 0; //GPIO[ 9];
    
	 
    
    // This is our APB master bus from the controller
    ApbBus bus();
    assign bus.PCLK    = clk;
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
      .mainClk(clk),
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
    parameter integer numOfSlaves = 13;
    parameter integer addresses [numOfSlaves] = '{
          0,        // GPIO register
		  4,	    // status reg
		  8,		// control register pulse-id
		 12,		// lower pulse-id write
		 16,		// upper pulse-id write
		 20,		// lower pulse-id read
		 24,		// upper pulse-id read
		 // registers for setting the delays
		 28,		// control, board, channel, status register
		 32,		// delay register
		 36,		// pulse length register
		 48,        // modulus and divider (added later)
		 40,        // full flag of the fifo
		 
         44         // frequency counter register
		 
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
	 
	 
    
    // GPIO register
	 logic [31:0] control;
    ApbWriteRegister #(.Address(addresses[0])) controlReg(.bus(slave_buses[0]), .value(control));
    
    assign GPIO[2:0] = control[2:0];
	 assign GPIO[3] = 1;
	 
	 logic [31:0] status;
	 ApbReadRegister #(.Address(addresses[1])) statusReg(.bus(slave_buses[1]), .value(status));
	 
	 // SPI bitbang:
	 assign SPI_Timer_SCLK = control[0];
	 assign SPI_Timer_CSB = control[1];
    assign SPI_Timer_SDI = control[2];
	 assign status[0] = SPI_Timer_SDO;
	 
	 
	 // reset of the AD9543:
	 assign reset_n = (control[3]== 1) ? 0 : 1'bz;
	 
	 
	 
	 
	 
	 // registers for reading / writing the pulse-id
	 logic [31:0] pulse_id_control;
	 logic [63:0] pulse_id_read;
	 logic [63:0] pulse_id_to_write;
	 ApbWriteRegister #(.Address(addresses[2])) pulseIdControlReg(.bus(slave_buses[2]), .value(pulse_id_control));
	 ApbWriteRegister #(.Address(addresses[3])) pulseidWrite1Reg (.bus(slave_buses[3]), .value(pulse_id_to_write[31:0]));
	 ApbWriteRegister #(.Address(addresses[4])) pulseidWrite2Reg (.bus(slave_buses[4]), .value(pulse_id_to_write[63:32]));
	 ApbReadRegister  #(.Address(addresses[5])) pulseidRead1Reg  (.bus(slave_buses[5]), .value(pulse_id_read[31:0]));
	 ApbReadRegister  #(.Address(addresses[6])) pulseidRead2Reg  (.bus(slave_buses[6]), .value(pulse_id_read[63:32]));
	 
	 // CAUTION: THIS RUNS IN THE 80MHZ CLOCK DOMAIN!
	 // reset generator for the pulse-id generator (wait for the 80 MHz clock to stabilize!):
	 logic reset_pulseid;
	 logic unsigned[31:0] reset_counter_80mhz;
	 always_ff @(posedge clk_80_Mhz) begin
	     if (reset_counter_80mhz < 800000000)
            reset_counter_80mhz <= reset_counter_80mhz + 1;
	 end
	 assign reset_pulseid = (reset_counter_80mhz < 800000000);
	 
     // inhibit the 100 Hz trigger
	 assign inhibit_trigger = control[15];
	 
	 // registers to set the delays:
	 // GPIO register
	 logic [31:0] control_board_channel_status;
    ApbWriteRegister #(.Address(addresses[7])) control_board_channel_status_reg (.bus(slave_buses[7]), .value(control_board_channel_status));
	 logic [31:0] delay;
    ApbWriteRegister #(.Address(addresses[8])) delay_reg (.bus(slave_buses[8]), .value(delay));
	 logic [31:0] pulse_length;
    ApbWriteRegister #(.Address(addresses[9])) pulse_length_reg (.bus(slave_buses[9]), .value(pulse_length));
	 logic [31:0] modulus_divider;
    ApbWriteRegister #(.Address(addresses[10])) modulus_divider_reg (.bus(slave_buses[10]), .value(modulus_divider));
	 
	 logic [31:0] fifo_status;
	 ApbReadRegister #(.Address(addresses[11])) fifo_status_reg(.bus(slave_buses[11]), .value(fifo_status));
	 
	 // assemble the payload:
	 payload_t delay_setting;
	 assign delay_setting.payload_type = 2;
	 delay_data_t delay_data;
	 assign delay_data.board   = control_board_channel_status[23:16];
	 assign delay_data.channel = control_board_channel_status[15: 8];
	 assign delay_data.status  = control_board_channel_status[ 7: 0];
	 assign delay_data.delay   = delay;
	 assign delay_data.length  = pulse_length;
	 assign delay_data.modulus = modulus_divider[15:8];
	 assign delay_data.divider = modulus_divider[ 7:0];
	 assign delay_data.empty   = 'd0; 
	 assign delay_setting.data = delay_data;
	 
	 // single shot to generate the fifo write signal:
	 logic fifo_write_delayed;
	 logic fifo_write;
	 always_ff @(posedge clk) begin
	     if (reset == 1)
		      fifo_write_delayed <= 0;
		  else
	         fifo_write_delayed <= control_board_channel_status[31];
	 end
	 assign fifo_write = control_board_channel_status[31] & !fifo_write_delayed;
	 
	 logic fifo_full;
	 assign fifo_status[0] = fifo_full;
	 assign fifo_status[31:1] = 0;
	 // The Pulse-ID generator: CAUTION: THIS RUNS (PARTIALLY) IN THE 80MHZ CLOCK DOMAIN!
	 logic [9:0] data_10b;
	 pulse_id_gen pulseIdGenerator(
        .clk(clk_80_Mhz),
		  .reset(reset_pulseid),
		  .trigger(trigger_100_hz & !reset_pulseid),
		  .data_10b(data_10b),
		  
		  .set_pulse_id(pulse_id_control[0]),
		  .new_pulse_id(pulse_id_to_write),
		  .current_id(pulse_id_read),
		  
		  .mram_cs(MRAM_CSn),
		  .mram_sck(MRAM_SCK),
		  .mram_mosi(MRAM_SI),
		  .mram_miso(MRAM_SO),
		  
		  // signals for the FIFO (CPU clock domain!)
		  .fifo_src_clk_i(clk),
        .fifo_src_rst_i(reset),
        .fifo_data_i(delay_setting),
		  .fifo_write_i(fifo_write),
		  .fifo_full_o(fifo_full)
	 );
	 
	// output register for the 10b encoded data:
	logic [9:0] data_10b_reg;
	always_ff @(posedge clk_80_Mhz) begin
		if (reset_pulseid == 1)
			data_10b_reg <= 0;
		else
			data_10b_reg <= data_10b;
	end
	assign to_serializer = data_10b_reg;
	 
	assign tclkr = 1;
	assign sync  = 0;
	assign MRAM_HOLDn = !reset;
	assign MRAM_WPn = 1;
	
	 // testing the slow data link: run a 5 MHz signal on these lines
     logic unsigned [2:0] slow_counter;
     always_ff @(posedge clk) begin
        slow_counter <= slow_counter + 1;
     end
     //assign slow_pulse_id = slow_counter[2];
	  assign slow_pulse_id = 0;
	  
	  // LEDs:
	  assign led1 = M0; // PLLs locked
	  assign led2 = M1; // 80 MHz present
	  // 100 Hz present
	  logic trigger_100hz_present;
	  pulse_extender extender_100_Hz(
	      .clk(clk),
			.pulse_in(trigger_100_hz),
			.pulse_out(trigger_100hz_present)
	  );
	  assign led3 = trigger_100hz_present;
	  
	  // status bits (beyond SPI input)
	  assign status[1] = M0; // PLLs locked
	  assign status[2] = M1; // 80 MHz present
	  assign status[3] = trigger_100hz_present; // 100 Hz clock present
      
      //FrequencyCounter
      logic [31:0] frequency;
      FrequencyCounter #(
            .WAIT_TIME(40000000)
        ) frequencyCounter (
            .clk_80MHz(clk_80_Mhz),
            .clk_40MHz(clk),
            .reset(reset),
            .frequency(frequency)
        );
      ApbReadRegister  #(.Address(addresses[12])) freqReadReg  (.bus(slave_buses[12]), .value(frequency));
      
endmodule



