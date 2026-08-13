`timescale 1ns / 1ps
// Phase 0 = banner ("INPUT REFILL" rotating), Phase 1 = amount selection.
// Within phase 1: if custom_active is low, show the chosen preset's BCD
// digits directly (no cursor -- it's not being edited, just displayed).
// If custom_active is high, hand off display to entry_ref (digit_entry),
// which gets its own mode_entry pulse on the rising edge of custom_active
// so its cursor/window reset exactly when the user switches into custom
// mode, not merely when Input Refill itself is entered.
module refill_block(
    input  wire clk,
    input  wire reset,
    input  wire pause,
    input  wire enable,          // enable_ref from mode_decoder
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
    output wire [19:0] refill_value,
    output wire phase_done
);
    wire mode_entry_ref;
    button_pulse #(.DEBOUNCE_WIDTH(4)) u_entry_det(
        .clk(clk), .reset(reset), .signal(enable), .pulse(mode_entry_ref)
    );

    wire phase;
    wire last_phase;
    phase_counter #(.NUM_PHASES(2)) u_phase(
        .clk(clk), .reset(reset), .pause(pause), .enable(enable),
        .mode_entry(mode_entry_ref), .btnc_pulse(btnc_pulse),
        .phase(phase), .last_phase(last_phase)
    );

    wire [6:0] banner_d0, banner_d1, banner_d2, banner_d3;
    text_display #(
        .LEN(13), .MSG("INPUT REFILL ")
    ) u_banner(
        .clk(clk),
        .reset(reset || mode_entry_ref),
        .enable(enable),
        .rotate_tick(rotate_tick && !pause),
        .digit0(banner_d0), .digit1(banner_d1), .digit2(banner_d2), .digit3(banner_d3)
    );

    wire custom_active;
    wire [19:0] preset_value;
    preset_select u_preset(
        .clk(clk), .reset(reset), .enable(enable), .mode_entry(mode_entry_ref),
        .btnu_pulse(btnu_pulse), .btnd_pulse(btnd_pulse),
        .btnl_pulse(btnl_pulse), .btnr_pulse(btnr_pulse),
        .custom_active(custom_active), .preset_value(preset_value)
    );

    // Fresh mode_entry for entry_ref: fires on the rising edge of
    // custom_active, so digit_select/win_start reset exactly when the user
    // switches into custom entry (not merely on Input Refill entry).
    wire mode_entry_custom;
    button_pulse #(.DEBOUNCE_WIDTH(4)) u_custom_entry_det(
        .clk(clk), .reset(reset), .signal(custom_active), .pulse(mode_entry_custom)
    );

    wire [6:0] entry_d0, entry_d1, entry_d2, entry_d3;
    wire [19:0] entry_value_w;
    digit_entry u_entry(
        .clk(clk), .reset(reset), .pause(pause),
        .enable(enable && custom_active),
        .mode_entry(mode_entry_custom), .blink_tick(blink_tick),
        .btnu_pulse(btnu_pulse), .btnd_pulse(btnd_pulse),
        .btnl_pulse(btnl_pulse), .btnr_pulse(btnr_pulse),
        .digit0(entry_d0), .digit1(entry_d1), .digit2(entry_d2), .digit3(entry_d3),
        .value(entry_value_w)
    );

    // Static (non-blinking) display of the chosen preset's digits.
    // All presets are <=5000, so d4 is always 0 and never shown/needed.
    wire [6:0] preset_d0, preset_d1, preset_d2, preset_d3;
    digit_to_7seg u_pd0(.digit(preset_value[15:12]), .seg(preset_d0));
    digit_to_7seg u_pd1(.digit(preset_value[11:8]),  .seg(preset_d1));
    digit_to_7seg u_pd2(.digit(preset_value[7:4]),   .seg(preset_d2));
    digit_to_7seg u_pd3(.digit(preset_value[3:0]),   .seg(preset_d3));

    wire [6:0] amount_d0 = custom_active ? entry_d0 : preset_d0;
    wire [6:0] amount_d1 = custom_active ? entry_d1 : preset_d1;
    wire [6:0] amount_d2 = custom_active ? entry_d2 : preset_d2;
    wire [6:0] amount_d3 = custom_active ? entry_d3 : preset_d3;

    assign digit0 = phase ? amount_d0 : banner_d0;
    assign digit1 = phase ? amount_d1 : banner_d1;
    assign digit2 = phase ? amount_d2 : banner_d2;
    assign digit3 = phase ? amount_d3 : banner_d3;

    assign refill_value = custom_active ? entry_value_w : preset_value;

    assign phase_done = last_phase && btnc_pulse && enable && !pause;
endmodule