`timescale 1ns / 1ps
// DEVIATION FROM TABLE 11 (documented earlier in chat, fix #3):
// The literal port list (btn*_pulse -> custom_active, preset_value, pure
// combinational) can't actually hold custom_active high for the duration
// of custom digit entry, since btnd_pulse is only a one-cycle pulse.
// Adding clk/reset/mode_entry lets both custom_active and preset_value be
// registered: set on the relevant button edge, held until reset or until
// a fresh entry into Input Refill (mode_entry).
//
// Values per your confirmed mapping: BTNL=2000, BTNU=5000, BTNR=1000.
//
// enable gates all button response (added after bring-up: without it, this
// module reacted to btnu/btnd/btnl/btnr even while in Balance or Result
// mode, since those are the same raw button signals shared globally in
// datapath. Since preset_value feeds refill_value combinationally, that
// silently changed the computed total/change shown on the Result screen.
module preset_select(
    input  wire clk,
    input  wire reset,
    input  wire enable,       // enable_ref from mode_decoder
    input  wire mode_entry,   // fresh entry into Input Refill: clear selection
    input  wire btnu_pulse,   // selects preset 5000
    input  wire btnd_pulse,   // selects Custom entry
    input  wire btnl_pulse,   // selects preset 2000
    input  wire btnr_pulse,   // selects preset 1000
    output reg  custom_active,
    output reg  [19:0] preset_value
);
    // BCD constants: {d4,d3,d2,d1,d0}
    localparam [19:0] VAL_2000 = {4'd0, 4'd2, 4'd0, 4'd0, 4'd0};
    localparam [19:0] VAL_5000 = {4'd0, 4'd5, 4'd0, 4'd0, 4'd0};
    localparam [19:0] VAL_1000 = {4'd0, 4'd1, 4'd0, 4'd0, 4'd0};

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            custom_active <= 1'b0;
            preset_value  <= 20'd0;
        end else if (mode_entry) begin
            custom_active <= 1'b0;
            preset_value  <= 20'd0;
        end else if (enable && !custom_active) begin
            // Only listen for the initial amount-selection press. Once
            // custom_active latches, these same raw button pulses belong to
            // entry_ref's navigation/editing -- ignore them here so a BTNU
            // meant to increment a digit doesn't get reinterpreted as
            // "reselect the 5000 preset."
            if (btnl_pulse) begin
                preset_value  <= VAL_2000;
                custom_active <= 1'b0;
            end else if (btnu_pulse) begin
                preset_value  <= VAL_5000;
                custom_active <= 1'b0;
            end else if (btnr_pulse) begin
                preset_value  <= VAL_1000;
                custom_active <= 1'b0;
            end else if (btnd_pulse) begin
                custom_active <= 1'b1;
                // preset_value don't-care while custom_active; refill_block
                // reads entry_ref's value instead when custom_active is high.
            end
        end
        // else: custom_active already latched -- frozen until mode_entry.
    end
endmodule