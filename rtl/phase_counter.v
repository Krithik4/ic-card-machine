`timescale 1ns / 1ps
// Tracks which display phase a mode is on (banner vs entry, or which of the
// 5 Result segments). last_phase does NOT wrap the counter -- once on the
// last phase, further btnc_pulse ticks are absorbed here; it's the parent
// controller's job (via at_last_phase/phase_done) to advance the *mode*
// instead.
module phase_counter #(
    parameter NUM_PHASES = 2
)(
    input  wire clk,
    input  wire reset,       // forces phase to 0
    input  wire pause,       // holds phase
    input  wire enable,      // this block's mode-enable signal
    input  wire mode_entry,  // one-cycle pulse: forces phase to 0 on entry
    input  wire btnc_pulse,  // advances phase by one
    output reg  [$clog2(NUM_PHASES)-1:0] phase,
    output wire last_phase
);
    assign last_phase = (phase == NUM_PHASES - 1);

    always @(posedge clk or posedge reset) begin
        if (reset)
            phase <= 0;
        else if (mode_entry)
            phase <= 0;
        else if (pause)
            phase <= phase; // explicit hold
        else if (enable && btnc_pulse && !last_phase)
            phase <= phase + 1'b1;
        // else: hold (not enabled, or already on last_phase, or no pulse)
    end
endmodule
