`timescale 1ns / 1ps
// Encoding fixed by the Lab 4a HLSM: OFF=00, BALANCE=01, REFILL=10, RESULT=11.
module mode_decoder(
    input  wire [1:0] mode_sel,
    output wire enable_off,
    output wire enable_bal,
    output wire enable_ref,
    output wire enable_res
);
    assign enable_off = (mode_sel == 2'b00);
    assign enable_bal = (mode_sel == 2'b01);
    assign enable_ref = (mode_sel == 2'b10);
    assign enable_res = (mode_sel == 2'b11);
endmodule
