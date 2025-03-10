/*
    Extends an input pulse.
    This module is designed for driving the status LEDs.
*/

module pulse_extender #(
    parameter int NUM_CYCLES = 50000000
)
(
    input  logic clk,           // 50 MHz clock
    input  logic pulse_in,
    output logic pulse_out
);
    
    logic unsigned [25:0] time_counter;
    
    always_ff @(posedge clk) begin
        if (pulse_in == 1)
            time_counter <= 26'(NUM_CYCLES);
        else if (time_counter != 0)
            time_counter <= time_counter - 1;
    end
    
    assign pulse_out = (time_counter != 0);

endmodule
