`timescale 1ns / 1ps
// change = sum - 20000 if exceeds_cap, else exactly 0 (regardless of what
// sum happens to be). Mirrors bcd_adder's per-digit structure but with a
// borrow chain instead of a carry chain.
// CAP = {2,0,0,0,0} (d4,d3,d2,d1,d0).
module bcd_subtractor(
    input  wire [19:0] sum,
    input  wire        exceeds_cap,
    output wire [19:0] change
);
    wire [3:0] s0 = sum[3:0];
    wire [3:0] s1 = sum[7:4];
    wire [3:0] s2 = sum[11:8];
    wire [3:0] s3 = sum[15:12];
    wire [3:0] s4 = sum[19:16];

    // CAP digits: cap0=0, cap1=0, cap2=0, cap3=0, cap4=2

    wire signed [4:0] raw0, raw1, raw2, raw3, raw4;
    wire b0, b1, b2, b3;
    wire [3:0] r0, r1, r2, r3, r4;

    // Stage 0: s0 - 0
    assign raw0 = $signed({1'b0, s0}) - 5'sd0;
    assign b0   = (raw0 < 0);
    assign r0   = b0 ? (raw0 + 5'sd10) : raw0;

    // Stage 1: s1 - 0 - borrow_in
    assign raw1 = $signed({1'b0, s1}) - 5'sd0 - b0;
    assign b1   = (raw1 < 0);
    assign r1   = b1 ? (raw1 + 5'sd10) : raw1;

    // Stage 2: s2 - 0 - borrow_in
    assign raw2 = $signed({1'b0, s2}) - 5'sd0 - b1;
    assign b2   = (raw2 < 0);
    assign r2   = b2 ? (raw2 + 5'sd10) : raw2;

    // Stage 3: s3 - 0 - borrow_in
    assign raw3 = $signed({1'b0, s3}) - 5'sd0 - b2;
    assign b3   = (raw3 < 0);
    assign r3   = b3 ? (raw3 + 5'sd10) : raw3;

    // Stage 4: s4 - 2 - borrow_in (no further correction needed; result
    // stays in range since sum is capped well under 40000 in practice, and
    // exceeds_cap gates whether this result is even used).
    assign raw4 = $signed({1'b0, s4}) - 5'sd2 - b3;
    assign r4   = raw4[3:0];

    assign change = exceeds_cap ? {r4, r3, r2, r1, r0} : 20'd0;
endmodule
