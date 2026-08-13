`timescale 1ns / 1ps
// 5-digit BCD entry with a 4-digit visible window (win_start = 0 shows
// registers 0-3, win_start = 1 shows registers 1-4) and a blinking cursor
// on the selected digit. digit4 (the ten-thousands place) is capped 0-2;
// when it equals 2, digits 0-3 are locked at 0 (the app's 20000 ceiling).
//
// Priority (see Lab 4b Implementation Plan, Known Risk Areas):
//   reset > msb_lock (d4==2 forcing d0-d3=0) > pause > normal navigation/edit
//
// Physical layout convention: digit0 (leftmost 7-seg) shows the
// higher-index register in the current window, digit3 (rightmost) shows
// the lower-index register -- i.e. reading left-to-right matches reading
// the number's digits most-significant-first, consistent with value's
// {d4,d3,d2,d1,d0} bit ordering. win_start=0 window is {d3,d2,d1,d0} shown
// left-to-right; win_start=1 window is {d4,d3,d2,d1} shown left-to-right.
module digit_entry(
    input  wire clk,
    input  wire reset,
    input  wire pause,
    input  wire enable,
    input  wire mode_entry,
    input  wire blink_tick,
    input  wire btnu_pulse,
    input  wire btnd_pulse,
    input  wire btnl_pulse,
    input  wire btnr_pulse,
    output wire [6:0] digit0,
    output wire [6:0] digit1,
    output wire [6:0] digit2,
    output wire [6:0] digit3,
    output wire [19:0] value
);
    reg [3:0] d0, d1, d2, d3, d4;
    reg [2:0] digit_select;  // 0-4
    reg       win_start;     // 0 or 1
    reg       blink_on;

    assign value = {d4, d3, d2, d1, d0};

    // ---------------------------------------------------------------
    // Next-state combinational logic. d4 is computed first so msb_lock
    // can be derived from the *new* d4 and applied to d0-d3 in the same
    // cycle (this is what makes the d0-d3 snap-to-0 visible immediately,
    // not one cycle late).
    // ---------------------------------------------------------------
    reg [3:0] next_d4;
    always @(*) begin
        next_d4 = d4;
        if (enable && !pause && digit_select == 3'd4) begin
            if (btnu_pulse)      next_d4 = (d4 == 4'd2) ? 4'd0 : d4 + 4'd1;
            else if (btnd_pulse) next_d4 = (d4 == 4'd0) ? 4'd2 : d4 - 4'd1;
        end
    end

    wire next_msb_lock = (next_d4 == 4'd2);

    reg [3:0] next_d0, next_d1, next_d2, next_d3;
    always @(*) begin
        next_d0 = d0; next_d1 = d1; next_d2 = d2; next_d3 = d3;
        if (next_msb_lock) begin
            // Locked at 0 regardless of pause, regardless of digit_select.
            next_d0 = 4'd0; next_d1 = 4'd0; next_d2 = 4'd0; next_d3 = 4'd0;
        end else if (enable && !pause) begin
            case (digit_select)
                3'd0: begin
                    if (btnu_pulse)      next_d0 = (d0 == 4'd9) ? 4'd0 : d0 + 4'd1;
                    else if (btnd_pulse) next_d0 = (d0 == 4'd0) ? 4'd9 : d0 - 4'd1;
                end
                3'd1: begin
                    if (btnu_pulse)      next_d1 = (d1 == 4'd9) ? 4'd0 : d1 + 4'd1;
                    else if (btnd_pulse) next_d1 = (d1 == 4'd0) ? 4'd9 : d1 - 4'd1;
                end
                3'd2: begin
                    if (btnu_pulse)      next_d2 = (d2 == 4'd9) ? 4'd0 : d2 + 4'd1;
                    else if (btnd_pulse) next_d2 = (d2 == 4'd0) ? 4'd9 : d2 - 4'd1;
                end
                3'd3: begin
                    if (btnu_pulse)      next_d3 = (d3 == 4'd9) ? 4'd0 : d3 + 4'd1;
                    else if (btnd_pulse) next_d3 = (d3 == 4'd0) ? 4'd9 : d3 - 4'd1;
                end
                default: ; // digit_select==4: handled by next_d4 above
            endcase
        end
    end

    // Navigation: cursor movement and window hysteresis. Not affected by
    // msb_lock (only value edits are locked); frozen by pause like normal.
    reg [2:0] next_digit_select;
    reg       next_win_start;
    always @(*) begin
        next_digit_select = digit_select;
        next_win_start    = win_start;
        if (enable && !pause) begin
            // BTNR moves the cursor visually RIGHT, which is the LOWER
            // register index (win_idx3 = rightmost slot = win_start+0);
            // BTNL moves visually LEFT, the HIGHER register index
            // (win_idx0 = leftmost slot). This is intentionally opposite
            // to a naive "btnr increments" mapping -- see win_idx0..3
            // below, where index 0 (leftmost slot) holds the HIGHER
            // register index.
            if (btnl_pulse && digit_select < 3'd4)
                next_digit_select = digit_select + 3'd1;
            else if (btnr_pulse && digit_select > 3'd0)
                next_digit_select = digit_select - 3'd1;

            // Hysteresis: shift the window up only when the cursor crosses
            // into digit 4; shift back down only once the cursor actually
            // drops below the window's lower bound (win_start itself).
            if (next_digit_select == 3'd4 && win_start == 1'b0)
                next_win_start = 1'b1;
            else if ({2'b0, next_digit_select} < {2'b0, win_start})
                next_win_start = 1'b0;
        end
    end

    // blink_tick arrives as a raw slow-clock LEVEL (same situation as
    // text_display's rotate_tick -- see its comment). Edge-detect locally.
    reg  blink_tick_prev;
    wire blink_tick_pulse = blink_tick & ~blink_tick_prev;
    always @(posedge clk or posedge reset) begin
        if (reset) blink_tick_prev <= 1'b0;
        else       blink_tick_prev <= blink_tick;
    end

    // Blink toggle: advances on blink_tick, holds during pause, resuming
    // exactly where it left off (register simply doesn't toggle).
    always @(posedge clk or posedge reset) begin
        if (reset)
            blink_on <= 1'b0;
        else if (enable && !pause && blink_tick_pulse)
            blink_on <= ~blink_on;
    end

    // Main register file.
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            d0 <= 4'd0; d1 <= 4'd0; d2 <= 4'd0; d3 <= 4'd0; d4 <= 4'd0;
            digit_select <= 3'd0;
            win_start    <= 1'b0;
        end else if (mode_entry) begin
            // Table 10: mode_entry resets digit_select/win_start only.
            // d0-d4 intentionally carry over -- see chat note on whether a
            // fresh transaction should also clear the balance value.
            digit_select <= 3'd0;
            win_start    <= 1'b0;
        end else begin
            d0 <= next_d0; d1 <= next_d1; d2 <= next_d2; d3 <= next_d3; d4 <= next_d4;
            digit_select <= next_digit_select;
            win_start    <= next_win_start;
        end
    end

    // ---------------------------------------------------------------
    // Windowed, blink-masked display output.
    // ---------------------------------------------------------------
    function [3:0] digit_at;
        input [2:0] idx;
        begin
            case (idx)
                3'd0: digit_at = d0;
                3'd1: digit_at = d1;
                3'd2: digit_at = d2;
                3'd3: digit_at = d3;
                3'd4: digit_at = d4;
                default: digit_at = 4'd0;
            endcase
        end
    endfunction

    wire [2:0] win_idx0 = win_start ? 3'd4 : 3'd3; // slot0 = leftmost
    wire [2:0] win_idx1 = win_start ? 3'd3 : 3'd2;
    wire [2:0] win_idx2 = win_start ? 3'd2 : 3'd1;
    wire [2:0] win_idx3 = win_start ? 3'd1 : 3'd0; // slot3 = rightmost

    wire blank_sel0 = (win_idx0 == digit_select) && !blink_on;
    wire blank_sel1 = (win_idx1 == digit_select) && !blink_on;
    wire blank_sel2 = (win_idx2 == digit_select) && !blink_on;
    wire blank_sel3 = (win_idx3 == digit_select) && !blink_on;

    // 4'hF is out of BCD range -> digit_to_7seg's default case blanks it.
    wire [3:0] disp0 = blank_sel0 ? 4'hF : digit_at(win_idx0);
    wire [3:0] disp1 = blank_sel1 ? 4'hF : digit_at(win_idx1);
    wire [3:0] disp2 = blank_sel2 ? 4'hF : digit_at(win_idx2);
    wire [3:0] disp3 = blank_sel3 ? 4'hF : digit_at(win_idx3);

    digit_to_7seg u_seg0(.digit(disp0), .seg(digit0));
    digit_to_7seg u_seg1(.digit(disp1), .seg(digit1));
    digit_to_7seg u_seg2(.digit(disp2), .seg(digit2));
    digit_to_7seg u_seg3(.digit(disp3), .seg(digit3));
endmodule
