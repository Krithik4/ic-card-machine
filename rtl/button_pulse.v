`timescale 1ns / 1ps
// See chat note: rising_edge_detector's outedge is asserted for roughly half
// a debounce period (its internal state only updates on its own derived
// slow_clk), NOT a single 100MHz-domain cycle. Every consumer in this
// design (phase_counter's btnc_pulse, digit_entry's btnu/btnd/btnl/btnr,
// mode_entry detection, etc.) needs a genuine one-cycle pulse or a single
// button press causes multiple synchronous advances in one held window
// (verified this exact failure: one btnc press cascaded OFF->BAL->REF).
// This wraps rising_edge_detector with a second, fast-domain edge detector
// on its own output to produce a clean single-cycle pulse, without
// modifying rising_edge_detector.v itself.
module button_pulse #(
    parameter DEBOUNCE_WIDTH = 20
)(
    input  wire clk,
    input  wire reset,
    input  wire signal,
    output wire pulse
);
    wire outedge;
    rising_edge_detector #(.DEBOUNCE_WIDTH(DEBOUNCE_WIDTH)) u_det(
        .clk(clk), .reset(reset), .signal(signal), .outedge(outedge)
    );

    reg outedge_prev;
    always @(posedge clk or posedge reset) begin
        if (reset) outedge_prev <= 1'b0;
        else       outedge_prev <= outedge;
    end

    assign pulse = outedge & ~outedge_prev;
endmodule
