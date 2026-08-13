`timescale 1ns / 1ps
// a, b, sum are each {d4,d3,d2,d1,d0}, 4 bits/digit, BCD.
// d0-d3 are correcting-adder stages (ripple carry via the BCD +6 trick).
// d4 is a plain 4-bit adder stage (no correction) -- see Lab 4b module notes.
// Correctness is independent of the app's actual value range: this handles
// cascading carries (e.g. 09999+00001=10000) even though the app never
// drives values that high.
module bcd_adder(
    input  wire [19:0] a,
    input  wire [19:0] b,
    output wire [19:0] sum
);
    wire [3:0] a0 = a[3:0],   b0 = b[3:0];
    wire [3:0] a1 = a[7:4],   b1 = b[7:4];
    wire [3:0] a2 = a[11:8],  b2 = b[11:8];
    wire [3:0] a3 = a[15:12], b3 = b[15:12];
    wire [3:0] a4 = a[19:16], b4 = b[19:16];

    wire [4:0] raw0, raw1, raw2, raw3;
    wire       c0, c1, c2, c3;
    wire [3:0] d0, d1, d2, d3, d4;

    // Stage 0 (no carry in)
    assign raw0 = a0 + b0;
    assign c0   = (raw0 > 5'd9);
    assign d0   = c0 ? (raw0 + 5'd6) : raw0;

    // Stage 1
    assign raw1 = a1 + b1 + c0;
    assign c1   = (raw1 > 5'd9);
    assign d1   = c1 ? (raw1 + 5'd6) : raw1;

    // Stage 2
    assign raw2 = a2 + b2 + c1;
    assign c2   = (raw2 > 5'd9);
    assign d2   = c2 ? (raw2 + 5'd6) : raw2;

    // Stage 3
    assign raw3 = a3 + b3 + c2;
    assign c3   = (raw3 > 5'd9);
    assign d3   = c3 ? (raw3 + 5'd6) : raw3;

    // Stage 4: plain adder, no BCD correction
    assign d4 = a4 + b4 + c3;

    assign sum = {d4, d3, d2, d1, d0};
endmodule
