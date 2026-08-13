`timescale 1ns / 1ps
// Mode IS the state -- no separate mode register needed (per Addendum B).
// Encoding: OFF=00, BALANCE=01, REFILL=10, RESULT=11.
// Cycle: OFF -> BAL -> REF -> RES -> OFF -> ... (RES's final confirm
// returns to OFF, not back into BAL -- each transaction starts fresh from
// OFF; update the Lab 4a HLSM/proposal diagrams to match if they still show
// RES looping back to BAL).
//
// FIX (documented earlier in chat, item #1): the general advance rule is
// "btnc_pulse && !pause && at_last_phase", but at_last_phase is hardwired
// low for OFF (it has no phase counter -- see phase_done_mux). Applying the
// general rule literally would mean OFF can never be left. OFF is therefore
// a special case: it advances on btnc_pulse && !pause alone, unconditional
// on at_last_phase. Every other state uses the full rule.
module controller(
    input  wire clk,
    input  wire reset,
    input  wire pause,
    input  wire btnc,            // raw confirm/advance button
    input  wire at_last_phase,   // from datapath's phase_done_mux
    output reg  [1:0] mode_sel,
    output wire btnc_pulse,
    output wire [3:0] led_pattern
);
    localparam MODE_OFF = 2'b00;
    localparam MODE_BAL = 2'b01;
    localparam MODE_REF = 2'b10;
    localparam MODE_RES = 2'b11;

    // ~1.3ms debounce (2^17 cycles @ 100MHz) for the physical button --
    // the module's own default (2^27, ~1.3s) is unusable for a real press.
    // button_pulse (not raw rising_edge_detector) is required here: outedge
    // stays high for roughly half a debounce period, not one fast-clk
    // cycle, so feeding it straight into next-state logic causes a single
    // press to cascade through multiple mode transitions. See button_pulse.v.
    // Tune DEBOUNCE_WIDTH here if bring-up shows missed/double presses.
    button_pulse #(.DEBOUNCE_WIDTH(17)) u_btnc_det(
        .clk(clk), .reset(reset), .signal(btnc), .pulse(btnc_pulse)
    );

    reg [1:0] next_mode_sel;
    always @(*) begin
        case (mode_sel)
            MODE_OFF: next_mode_sel = (btnc_pulse && !pause) ? MODE_BAL : MODE_OFF;
            MODE_BAL: next_mode_sel = (btnc_pulse && !pause && at_last_phase) ? MODE_REF : MODE_BAL;
            MODE_REF: next_mode_sel = (btnc_pulse && !pause && at_last_phase) ? MODE_RES : MODE_REF;
            MODE_RES: next_mode_sel = (btnc_pulse && !pause && at_last_phase) ? MODE_OFF : MODE_RES;
            default:  next_mode_sel = MODE_OFF;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset)
            mode_sel <= MODE_OFF;
        else
            mode_sel <= next_mode_sel;
    end

    reg [3:0] led_comb;
    always @(*) begin
        case (mode_sel)
            MODE_OFF: led_comb = 4'b0001;
            MODE_BAL: led_comb = 4'b0010;
            MODE_REF: led_comb = 4'b0100;
            MODE_RES: led_comb = 4'b1000;
            default:  led_comb = 4'b0001;
        endcase
    end
    assign led_pattern = led_comb;
endmodule
