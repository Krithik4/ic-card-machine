`timescale 1ns / 1ps
module refill_top(
    input  wire clk,
    input  wire reset,
    input  wire pause,
    input  wire btnc,
    input  wire btnu,
    input  wire btnd,
    input  wire btnl,
    input  wire btnr,
    output wire [3:0] led,
    output wire [6:0] seg,
    output wire [3:0] an
);
    wire [1:0] mode_sel;
    wire btnc_pulse;
    wire at_last_phase;

    controller u_controller(
        .clk(clk), .reset(reset), .pause(pause), .btnc(btnc),
        .at_last_phase(at_last_phase),
        .mode_sel(mode_sel), .btnc_pulse(btnc_pulse), .led_pattern(led)
    );

    datapath u_datapath(
        .clk(clk), .reset(reset), .pause(pause),
        .mode_sel(mode_sel), .btnc_pulse(btnc_pulse),
        .btnu(btnu), .btnd(btnd), .btnl(btnl), .btnr(btnr),
        .at_last_phase(at_last_phase),
        .seg(seg), .an(an)
    );
endmodule
