`timescale 1ns / 1ps
// digits_in is {d4,d3,d2,d1,d0}, 4 bits/digit, BCD.
// ascii_out is 5 ASCII bytes, MSB-first: {ascii4,ascii3,ascii2,ascii1,ascii0}
// so it lines up byte-for-byte with digits_in's digit ordering.
module bcd_to_ascii(
    input  wire [19:0] digits_in,
    output wire [39:0] ascii_out
);
    wire [3:0] d0 = digits_in[3:0];
    wire [3:0] d1 = digits_in[7:4];
    wire [3:0] d2 = digits_in[11:8];
    wire [3:0] d3 = digits_in[15:12];
    wire [3:0] d4 = digits_in[19:16];

    assign ascii_out = {8'h30 + d4, 8'h30 + d3, 8'h30 + d2, 8'h30 + d1, 8'h30 + d0};
endmodule
