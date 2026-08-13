`timescale 1ns / 1ps
// Phase 0 = banner ("CURRENT BALANCE" rotating), Phase 1 = digit entry.
// phase_done pulses for exactly one cycle: the confirm click on the LAST
// phase (phase 1), not the first click that just moves banner->entry.
//
// Per the text_display design note: this block owns pause/mode_entry, so
// it gates rotate_tick with pause and ORs mode_entry_bal into the reset it
// feeds its banner_bal instance, restarting the rotation at each fresh
// entry into Input Balance.
module balance_block(
    input  wire clk,
    input  wire reset,
    input  wire pause,
    input  wire enable,          // enable_bal from mode_decoder
    input  wire btnc_pulse,
    input  wire btnu_pulse,
    input  wire btnd_pulse,
    input  wire btnl_pulse,
    input  wire btnr_pulse,
    input  wire rotate_tick,
    input  wire blink_tick,
    output wire [6:0] digit0,
    output wire [6:0] digit1,
    output wire [6:0] digit2,
    output wire [6:0] digit3,
    output wire [19:0] balance_value,
    output wire phase_done
);
    wire mode_entry_bal;
    button_pulse #(.DEBOUNCE_WIDTH(4)) u_entry_det(
        .clk(clk), .reset(reset), .signal(enable), .pulse(mode_entry_bal)
    );

    wire phase; // NUM_PHASES=2 -> 1 bit
    wire last_phase;
    phase_counter #(.NUM_PHASES(2)) u_phase(
        .clk(clk), .reset(reset), .pause(pause), .enable(enable),
        .mode_entry(mode_entry_bal), .btnc_pulse(btnc_pulse),
        .phase(phase), .last_phase(last_phase)
    );

    wire [6:0] banner_d0, banner_d1, banner_d2, banner_d3;
    text_display #(
        .LEN(16), .MSG("CURRENT BALANCE ")
    ) u_banner(
        .clk(clk),
        .reset(reset || mode_entry_bal),
        .enable(enable),
        .rotate_tick(rotate_tick && !pause),
        .digit0(banner_d0), .digit1(banner_d1), .digit2(banner_d2), .digit3(banner_d3)
    );

    wire [6:0] entry_d0, entry_d1, entry_d2, entry_d3;
    digit_entry u_entry(
        .clk(clk), .reset(reset), .pause(pause), .enable(enable),
        .mode_entry(mode_entry_bal), .blink_tick(blink_tick),
        .btnu_pulse(btnu_pulse), .btnd_pulse(btnd_pulse),
        .btnl_pulse(btnl_pulse), .btnr_pulse(btnr_pulse),
        .digit0(entry_d0), .digit1(entry_d1), .digit2(entry_d2), .digit3(entry_d3),
        .value(balance_value)
    );

    // Phase 0 = banner, Phase 1 = entry.
    assign digit0 = phase ? entry_d0 : banner_d0;
    assign digit1 = phase ? entry_d1 : banner_d1;
    assign digit2 = phase ? entry_d2 : banner_d2;
    assign digit3 = phase ? entry_d3 : banner_d3;

    assign phase_done = last_phase && btnc_pulse && enable && !pause;
endmodule
