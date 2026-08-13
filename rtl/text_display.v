`timescale 1ns / 1ps
// Fixed-message banner with continuous wraparound rotation (a ticker, not a
// bounce-and-reverse pan -- "rotates continuously" in the spec, unlike the
// baseline advertisement-sign project's back-and-forth panning).
//
// DESIGN NOTE on the missing pause/mode_entry ports:
// Table 9's port list for text_display has only clk/reset/enable/
// rotate_tick/digit0-3 -- no pause, no mode_entry. But the Implementation
// Plan's Tier 3 test order expects "pause holds the rotation offset" and
// "mode_entry restarts rotation from the banner start ... indirectly via
// the parent block." Taking that "indirectly" literally: this module has
// no pause/mode_entry logic of its own. Instead:
//   - the parent block (balance_block etc.) must gate the rotate_tick it
//     forwards here with pause (rotate_tick_to_child = rotate_tick && !pause)
//   - the parent block must OR mode_entry into the reset it drives here
//     (reset_to_child = system_reset || mode_entry_xxx)
// That keeps this module a pure "rotate on tick, clear on reset" leaf, and
// pushes the pause/mode_entry wiring decision up to whichever block already
// owns those signals per its own port list.
//
// Parameterized by MSG (packed ASCII, char0 = MOST significant byte) and
// LEN (character count). Instantiated as banner_bal, banner_ref,
// label_new_total, label_change, banner_arigato.
module text_display #(
    parameter LEN = 8,
    parameter [8*LEN-1:0] MSG = {LEN{8'h20}}
)(
    input  wire clk,
    input  wire reset,
    input  wire enable,
    input  wire rotate_tick,
    output wire [6:0] digit0,
    output wire [6:0] digit1,
    output wire [6:0] digit2,
    output wire [6:0] digit3
);
    // Unpack MSG into a per-character array so it can be indexed with a
    // runtime (offset-dependent) index.
    wire [7:0] rom_char [0:LEN-1];
    genvar gi;
    generate
        for (gi = 0; gi < LEN; gi = gi + 1) begin : rom_gen
            assign rom_char[gi] = MSG[8*(LEN-gi)-1 -: 8];
        end
    endgenerate

    reg [$clog2(LEN)-1:0] offset;

    // rotate_tick arrives as a raw slow-clock LEVEL (clkdiv's direct
    // output), not a pre-made pulse -- same situation the baseline Lab 4b
    // position_counter skeleton calls out explicitly. Edge-detect it here
    // in the 100 MHz domain with a plain 1-cycle synchronizer; this is a
    // clean synchronous signal already, so the heavier debounced
    // rising_edge_detector (meant for bouncy external buttons) isn't needed.
    reg  tick_prev;
    wire tick_pulse = rotate_tick & ~tick_prev;
    always @(posedge clk or posedge reset) begin
        if (reset) tick_prev <= 1'b0;
        else       tick_prev <= rotate_tick;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            offset <= 0;
        else if (enable && tick_pulse)
            offset <= (offset == LEN-1) ? 0 : offset + 1'b1;
    end

    function [$clog2(LEN)-1:0] wrap_idx;
        input [$clog2(LEN)-1:0] base;
        input integer k;
        reg   [$clog2(LEN):0]   sum;
        begin
            sum = base + k;
            wrap_idx = (sum >= LEN) ? (sum - LEN) : sum[$clog2(LEN)-1:0];
        end
    endfunction

    wire [7:0] ch0 = rom_char[wrap_idx(offset, 0)];
    wire [7:0] ch1 = rom_char[wrap_idx(offset, 1)];
    wire [7:0] ch2 = rom_char[wrap_idx(offset, 2)];
    wire [7:0] ch3 = rom_char[wrap_idx(offset, 3)];

    letter_to_7seg u0(.ascii(ch0), .seg(digit0));
    letter_to_7seg u1(.ascii(ch1), .seg(digit1));
    letter_to_7seg u2(.ascii(ch2), .seg(digit2));
    letter_to_7seg u3(.ascii(ch3), .seg(digit3));
endmodule
