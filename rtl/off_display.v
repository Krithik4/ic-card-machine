`timescale 1ns / 1ps
// Static OFF display: leftmost digit blank, remaining three spell "OFF".
// No rotation, no animation. Table 7 lists no submodules, so the patterns
// are hardcoded here rather than instantiated through letter_to_7seg.
module off_display(
    input  wire clk,
    input  wire reset,
    input  wire enable,
    output wire [6:0] digit0,
    output wire [6:0] digit1,
    output wire [6:0] digit2,
    output wire [6:0] digit3
);
    // Active-low patterns, matching letter_to_7seg's O/F/space entries.
    assign digit0 = 7'b1111111; // blank
    assign digit1 = 7'b0000001; // O
    assign digit2 = 7'b0111000; // F
    assign digit3 = 7'b0111000; // F
endmodule
