`timescale 1ns / 1ps
// Clock rate choices:
//   rotate_clk_div: WIDTH=25 -> 100MHz/2^25 ~= 2.98 Hz, inside the spec's
//     2-4Hz range. This single ~3Hz tick drives BOTH banner rotation AND
//     digit-entry cursor blink (the hierarchy only shows one rotate_clk_div
//     feeding "rotate_tick"; balance_block/refill_block's separate
//     rotate_tick/blink_tick ports are simply tied to the same wire here).
//   refresh_clk_div: WIDTH=17 -> 100MHz/2^17 ~= 763 Hz, inside the spec's
//     ~500Hz-1kHz display-refresh range. Feeds time_mux_state_machine's clk
//     directly (matching the original Lab 2 pattern, not the level+edge-
//     detect pattern used for rotate_tick/blink_tick -- time_mux_state_
//     machine is a self-contained round-robin FSM, not an accumulating
//     counter, so this doesn't hit the Vivado derived-clock-domain warning
//     the way a counter would).
module datapath(
    input  wire clk,
    input  wire reset,
    input  wire pause,
    input  wire [1:0] mode_sel,
    input  wire btnc_pulse,
    input  wire btnu,
    input  wire btnd,
    input  wire btnl,
    input  wire btnr,
    output wire at_last_phase,
    output wire [6:0] seg,
    output wire [3:0] an
);
    // --- Raw button edge detection (DEBOUNCE_WIDTH=20, matches controller's
    // btnc debounce -- see controller.v comment for rationale) ---
    wire btnu_pulse, btnd_pulse, btnl_pulse, btnr_pulse;
    button_pulse #(.DEBOUNCE_WIDTH(20)) u_btnu_det(.clk(clk), .reset(reset), .signal(btnu), .pulse(btnu_pulse));
    button_pulse #(.DEBOUNCE_WIDTH(20)) u_btnd_det(.clk(clk), .reset(reset), .signal(btnd), .pulse(btnd_pulse));
    button_pulse #(.DEBOUNCE_WIDTH(20)) u_btnl_det(.clk(clk), .reset(reset), .signal(btnl), .pulse(btnl_pulse));
    button_pulse #(.DEBOUNCE_WIDTH(20)) u_btnr_det(.clk(clk), .reset(reset), .signal(btnr), .pulse(btnr_pulse));

    // --- Clock dividers ---
    wire rotate_clk, refresh_clk;
    // refresh_clk must keep ticking even while reset is held (it's a
    // level-held switch in this design) -- otherwise the display
    // multiplexer never gets a clock edge and freezes on one digit.
    // rotate_clk_div stays tied to system reset (fine: nothing needs it to
    // run during reset, and each block restarts its own rotation via
    // mode_entry once reset releases).
    clkdiv #(.WIDTH(25)) u_rotate_div(.clk(clk), .reset(reset), .clk_out(rotate_clk));
    clkdiv #(.WIDTH(17)) u_refresh_div(.clk(clk), .reset(1'b0), .clk_out(refresh_clk));

    // --- Mode decode ---
    wire enable_off, enable_bal, enable_ref, enable_res;
    mode_decoder u_mode_dec(
        .mode_sel(mode_sel),
        .enable_off(enable_off), .enable_bal(enable_bal),
        .enable_ref(enable_ref), .enable_res(enable_res)
    );

    // --- OFF ---
    wire [6:0] off_d0, off_d1, off_d2, off_d3;
    off_display u_off(
        .clk(clk), .reset(reset), .enable(enable_off),
        .digit0(off_d0), .digit1(off_d1), .digit2(off_d2), .digit3(off_d3)
    );

    // --- Input Balance ---
    wire [6:0] bal_d0, bal_d1, bal_d2, bal_d3;
    wire [19:0] balance_value;
    wire bal_phase_done;
    balance_block u_balance(
        .clk(clk), .reset(reset), .pause(pause), .enable(enable_bal),
        .btnc_pulse(btnc_pulse),
        .btnu_pulse(btnu_pulse), .btnd_pulse(btnd_pulse),
        .btnl_pulse(btnl_pulse), .btnr_pulse(btnr_pulse),
        .rotate_tick(rotate_clk), .blink_tick(rotate_clk),
        .digit0(bal_d0), .digit1(bal_d1), .digit2(bal_d2), .digit3(bal_d3),
        .balance_value(balance_value), .phase_done(bal_phase_done)
    );

    // --- Input Refill ---
    wire [6:0] ref_d0, ref_d1, ref_d2, ref_d3;
    wire [19:0] refill_value;
    wire ref_phase_done;
    refill_block u_refill(
        .clk(clk), .reset(reset), .pause(pause), .enable(enable_ref),
        .btnc_pulse(btnc_pulse),
        .btnu_pulse(btnu_pulse), .btnd_pulse(btnd_pulse),
        .btnl_pulse(btnl_pulse), .btnr_pulse(btnr_pulse),
        .rotate_tick(rotate_clk), .blink_tick(rotate_clk),
        .digit0(ref_d0), .digit1(ref_d1), .digit2(ref_d2), .digit3(ref_d3),
        .refill_value(refill_value), .phase_done(ref_phase_done)
    );

    // --- Display Result ---
    wire [6:0] res_d0, res_d1, res_d2, res_d3;
    wire res_phase_done;
    result_block u_result(
        .clk(clk), .reset(reset), .pause(pause), .enable(enable_res),
        .btnc_pulse(btnc_pulse), .rotate_tick(rotate_clk),
        .balance_value(balance_value), .refill_value(refill_value),
        .digit0(res_d0), .digit1(res_d1), .digit2(res_d2), .digit3(res_d3),
        .phase_done(res_phase_done)
    );

    // --- Output muxes ---
    wire [6:0] sel_d0, sel_d1, sel_d2, sel_d3;
    digit_output_mux u_digit_mux(
        .mode_sel(mode_sel),
        .off_digits({off_d0, off_d1, off_d2, off_d3}),
        .bal_digits({bal_d0, bal_d1, bal_d2, bal_d3}),
        .ref_digits({ref_d0, ref_d1, ref_d2, ref_d3}),
        .res_digits({res_d0, res_d1, res_d2, res_d3}),
        .digit0(sel_d0), .digit1(sel_d1), .digit2(sel_d2), .digit3(sel_d3)
    );

    phase_done_mux u_phase_mux(
        .mode_sel(mode_sel),
        .bal_phase_done(bal_phase_done),
        .ref_phase_done(ref_phase_done),
        .res_phase_done(res_phase_done),
        .at_last_phase(at_last_phase)
    );

    // --- Display multiplexer (clocked directly by refresh_clk, matching
    // the original Lab 2 pattern) ---
    // NOTE: in0 drives an[0], and an[0] is the Basys3's RIGHTMOST physical
    // digit (standard board wiring). Every block in this design defines
    // digit0 as the LEFTMOST digit (see digit_entry.v's convention note),
    // so the connection order below is deliberately reversed -- without
    // this, "OFF" displays mirrored as "FFO". digit0 (leftmost) -> in3 ->
    // an[3] (physical leftmost); digit3 (rightmost) -> in0 -> an[0]
    // (physical rightmost).
    // One-shot power-on reset for the display multiplexer, independent of
    // the system reset switch (see note below). Asserted briefly after
    // configuration/simulation start, then never again.
    // Must stay asserted longer than one refresh_clk period (~655us at
    // WIDTH=17 for refresh_clk_div) so time_mux_state_machine's slow clock
    // actually samples reset=1 at least once before it drops. A too-short
    // pulse clears before refresh_clk's first edge ever arrives, leaving
    // state permanently uninitialized.
    localparam POR_CYCLES = 18'd200000; // ~2ms at 100MHz
    reg [17:0] por_count = 18'd0;
    reg        por_reset = 1'b1;
    always @(posedge clk) begin
        if (por_count < POR_CYCLES) begin
            por_count <= por_count + 1'b1;
            por_reset <= 1'b1;
        end else begin
            por_reset <= 1'b0;
        end
    end

    // NOTE: reset is intentionally tied to the one-shot por_reset above,
    // NOT to the system reset. This state machine only decides which of
    // the 4 anodes to light right now -- it has no bearing on displayed
    // content or user data. reset is a level-held switch in this design;
    // wiring the system reset here would pin the multiplexer at digit
    // slot 0 for as long as reset stays up, so only one physical digit
    // would ever light (visible as e.g. a single "F" instead of the full
    // "OFF"). Free-running keeps all 4 digits cycling regardless of
    // system reset state.
    time_mux_state_machine u_time_mux(
        .clk(refresh_clk), .reset(por_reset),
        .in0(sel_d3), .in1(sel_d2), .in2(sel_d1), .in3(sel_d0),
        .an(an), .sseg(seg)
    );
endmodule
