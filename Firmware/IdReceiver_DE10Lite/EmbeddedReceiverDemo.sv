
module EmbeddedReceiverDemo(
    input           MAX10_CLK1_50,  // 50 HMz clock
    input  [1:0]    KEY,            // Buttons
    inout  [9:0]    ARDUINO_IO,     // Header pins
    output [9:0]    LEDR,           // LEDs
    input  [9:0]    SW,             // Switches
    output [7:0]    HEX0,           // 7-segment dieplay
    output [7:0]    HEX1,           // 7-segment dieplay
    output [7:0]    HEX2,           // 7-segment dieplay
    output [7:0]    HEX3,           // 7-segment dieplay
    output [7:0]    HEX4            // 7-segment dieplay
);
    /////////////////////////////////////////////////////////////
    logic reset;
	 // EmbeddedReceiver is configured for 50 MHz
    logic pulse;
    logic data;
    logic error;
    logic [63:0] pulse_id;
    logic reset_receiver;
	 
	 assign data = ARDUINO_IO[0];
	 
	 // recommended usage of the embedded receiver:
    EmbeddedReceiver #(
        .board(2),		          // listen to board ID 2
		  .Ki(2),                   // parameters for the PI controller of the CDR loop
          .Kp(500),                 // here: optimized for 50 HMz clock
		  .K0(335544)               // offset for the bit clock frequency (1 Mbit/s)
    ) EmbeddedReceiver (   
        .clk_i(MAX10_CLK1_50),    // clock
        .reset_i(reset_receiver), // reset (active high)                               
        .data_i(data),            // serial data
        .error_o(error),          // indicate an error
        .trigger_o(pulse),        // trigger output
        .pulse_id_o(pulse_id)     // current pulse-ID
    );
	 
	 // watchdog: If there are errors for 1s: cause a reset
	 Watchdog #(
        .WAIT_CYCLES(50000000)
    ) watchdog (
        .clk_i(MAX10_CLK1_50),
	     .reset_i(reset),
	     .error_i(error),
	     .reset_o(reset_receiver)
    );
	 /////////////////////////////////////////////////////////

	 // display result on LEDs, key to trigger a reset
	 
    Entpreller KEY0 (
        .clk(MAX10_CLK1_50),
        .key(KEY[0]),
        .pulse(reset)
    );
    
    
    
    
    pulse_extender extender_error(
		.clk(MAX10_CLK1_50),
		.pulse_in(error),
		.pulse_out(LEDR[8])
	);
	
        
    
    
    assign ARDUINO_IO[9] = pulse;
	 assign LEDR[3] = pulse;
    assign LEDR[0] = reset_receiver;
    assign LEDR[4] = data;
    
    
    //showing the last 5 pulse-id digit on 7-segment (in hex)
    SevenSegment Digit1 (
        .number(pulse_id[3:0]),
        .LED_out(HEX0[6:0])
    );
    
    SevenSegment Digit2 (
        .number(pulse_id[7:4]),
        .LED_out(HEX1[6:0])
    );
    
    SevenSegment Digit3 (
        .number(pulse_id[11:8]),
        .LED_out(HEX2[6:0])
    );
    
    SevenSegment Digit4 (
        .number(pulse_id[15:12]),
        .LED_out(HEX3[6:0])
    );
    
    SevenSegment Digit5 (
        .number(pulse_id[19:16]),
        .LED_out(HEX4[6:0])
    );
    
    assign HEX0[7] = 1;
    assign HEX1[7] = 1;
    assign HEX2[7] = 1;
    assign HEX3[7] = 1;
    assign HEX4[7] = 1;
    
	 
    
endmodule
