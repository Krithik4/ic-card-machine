`timescale 1ns / 1ps
module phase_done_mux(
    input  wire [1:0] mode_sel,
    input  wire bal_phase_done,
    input  wire ref_phase_done,
    input  wire res_phase_done,
    output reg  at_last_phase
);
    always @(*) begin
        case (mode_sel)
            2'b00: at_last_phase = 1'b0;         // OFF: no phases
            2'b01: at_last_phase = bal_phase_done;
            2'b10: at_last_phase = ref_phase_done;
            2'b11: at_last_phase = res_phase_done;
            default: at_last_phase = 1'b0;
        endcase
    end
endmodule
