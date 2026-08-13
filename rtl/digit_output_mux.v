`timescale 1ns / 1ps
// Each *_digits bus is {digit0,digit1,digit2,digit3}, 7 bits each, MSB-first
// (digit0 in the top 7 bits), matching how each source block's own
// digit0..digit3 ports are ordered.
module digit_output_mux(
    input  wire [1:0] mode_sel,
    input  wire [27:0] off_digits,
    input  wire [27:0] bal_digits,
    input  wire [27:0] ref_digits,
    input  wire [27:0] res_digits,
    output reg  [6:0] digit0,
    output reg  [6:0] digit1,
    output reg  [6:0] digit2,
    output reg  [6:0] digit3
);
    reg [27:0] sel_digits;
    always @(*) begin
        case (mode_sel)
            2'b00: sel_digits = off_digits;
            2'b01: sel_digits = bal_digits;
            2'b10: sel_digits = ref_digits;
            2'b11: sel_digits = res_digits;
            default: sel_digits = off_digits;
        endcase
        digit0 = sel_digits[27:21];
        digit1 = sel_digits[20:14];
        digit2 = sel_digits[13:7];
        digit3 = sel_digits[6:0];
    end
endmodule
