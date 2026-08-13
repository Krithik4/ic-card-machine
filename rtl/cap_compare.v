`timescale 1ns / 1ps
// sum is {d4,d3,d2,d1,d0}, 4 bits/digit, BCD. Cap is exactly 20000
// (d4=2, d3=d2=d1=d0=0). exceeds_cap is high only when sum > 20000
// (sum == 20000 exactly is NOT "exceeds").
module cap_compare(
    input  wire [19:0] sum,
    output wire exceeds_cap
);
    wire [3:0] d4 = sum[19:16];
    wire [3:0] d3 = sum[15:12];
    wire [3:0] d2 = sum[11:8];
    wire [3:0] d1 = sum[7:4];
    wire [3:0] d0 = sum[3:0];

    wire lower_nonzero = |{d3, d2, d1, d0};

    assign exceeds_cap = (d4 > 4'd2) || ((d4 == 4'd2) && lower_nonzero);
endmodule
