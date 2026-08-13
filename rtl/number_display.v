`timescale 1ns / 1ps
// Same rotation behavior as text_display (continuous wraparound, 4-character
// window) but the message comes from bcd_to_ascii instead of an internal
// ROM. Same design note as text_display applies: no pause/mode_entry port
// here -- the parent (result_block) is responsible for gating rotate_tick
// with pause and ORing mode_entry into reset.
// ascii_in byte ordering matches bcd_to_ascii: MSB byte = ascii4 (the
// ten-thousands digit), matching text_display's char0-is-MSB convention.
//
// Scrolls only when the value actually has 5 significant digits (ten-
// thousands digit != '0'); otherwise displays the low 4 digits statically,
// with no leading zero and no scrolling. When scrolling, a trailing space
// is inserted after the 5th digit (a virtual 6th position) so the wrap
// point is visibly a gap, not the string running directly into itself.
module number_display(
    input  wire clk,
    input  wire reset,
    input  wire enable,
    input  wire rotate_tick,
    input  wire [39:0] ascii_in,
    output wire [6:0] digit0,
    output wire [6:0] digit1,
    output wire [6:0] digit2,
    output wire [6:0] digit3
);
    localparam LEN = 6; // 5 digits + 1 virtual trailing space

    wire [7:0] ch [0:LEN-1];
    assign ch[0] = ascii_in[39:32];
    assign ch[1] = ascii_in[31:24];
    assign ch[2] = ascii_in[23:16];
    assign ch[3] = ascii_in[15:8];
    assign ch[4] = ascii_in[7:0];
    assign ch[5] = 8'h20; // virtual gap character, not part of ascii_in

    wire scroll_enable = (ascii_in[39:32] != 8'h30); // leading digit != '0'

    reg [2:0] offset; // 0-5 fits in 3 bits

    // rotate_tick arrives as a raw slow-clock LEVEL (clkdiv's direct
    // output), not a pre-made pulse -- edge-detect it here in the 100 MHz
    // domain with a plain 1-cycle synchronizer.
    reg  tick_prev;
    wire tick_pulse = rotate_tick & ~tick_prev;
    always @(posedge clk or posedge reset) begin
        if (reset) tick_prev <= 1'b0;
        else       tick_prev <= rotate_tick;
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            offset <= 0;
        else if (enable && scroll_enable && tick_pulse)
            offset <= (offset == LEN-1) ? 0 : offset + 1'b1;
        // else: hold (not enabled, not scrolling, or no tick) -- when
        // scroll_enable drops, offset just stops advancing; the static
        // path below ignores it entirely anyway.
    end

    function [2:0] wrap_idx;
        input [2:0] base;
        input integer k;
        reg   [3:0] sum;
        begin
            sum = base + k;
            wrap_idx = (sum >= LEN) ? (sum - LEN) : sum[2:0];
        end
    endfunction

    wire [7:0] scroll_ch0 = ch[wrap_idx(offset, 0)];
    wire [7:0] scroll_ch1 = ch[wrap_idx(offset, 1)];
    wire [7:0] scroll_ch2 = ch[wrap_idx(offset, 2)];
    wire [7:0] scroll_ch3 = ch[wrap_idx(offset, 3)];

    // Static path: low 4 digits (ascii_in[31:0]), leading zeros blanked.
    // The ones digit is always shown, even when the whole value is 0.
    wire [7:0] raw_static_ch0 = ascii_in[31:24]; // thousands
    wire [7:0] raw_static_ch1 = ascii_in[23:16]; // hundreds
    wire [7:0] raw_static_ch2 = ascii_in[15:8];  // tens
    wire [7:0] raw_static_ch3 = ascii_in[7:0];   // ones

    wire blank0 = (raw_static_ch0 == 8'h30);
    wire blank1 = blank0 && (raw_static_ch1 == 8'h30);
    wire blank2 = blank1 && (raw_static_ch2 == 8'h30);

    wire [7:0] static_ch0 = blank0 ? 8'h20 : raw_static_ch0;
    wire [7:0] static_ch1 = blank1 ? 8'h20 : raw_static_ch1;
    wire [7:0] static_ch2 = blank2 ? 8'h20 : raw_static_ch2;
    wire [7:0] static_ch3 = raw_static_ch3;

    wire [7:0] ch0 = scroll_enable ? scroll_ch0 : static_ch0;
    wire [7:0] ch1 = scroll_enable ? scroll_ch1 : static_ch1;
    wire [7:0] ch2 = scroll_enable ? scroll_ch2 : static_ch2;
    wire [7:0] ch3 = scroll_enable ? scroll_ch3 : static_ch3;

    letter_to_7seg u0(.ascii(ch0), .seg(digit0));
    letter_to_7seg u1(.ascii(ch1), .seg(digit1));
    letter_to_7seg u2(.ascii(ch2), .seg(digit2));
    letter_to_7seg u3(.ascii(ch3), .seg(digit3));
endmodule