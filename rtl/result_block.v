`timescale 1ns / 1ps
// Phases: 0=UPDATED TOTAL banner, 1=new-total number, 2=CHANGE banner,
// 3=change number, 4=ARIGATO banner (last phase).
module result_block(
    input  wire clk,
    input  wire reset,
    input  wire pause,
    input  wire enable,           // enable_res from mode_decoder
    input  wire btnc_pulse,
    input  wire rotate_tick,
    input  wire [19:0] balance_value,
    input  wire [19:0] refill_value,
    output wire [6:0] digit0,
    output wire [6:0] digit1,
    output wire [6:0] digit2,
    output wire [6:0] digit3,
    output wire phase_done
);
    wire mode_entry_res;
    button_pulse #(.DEBOUNCE_WIDTH(4)) u_entry_det(
        .clk(clk), .reset(reset), .signal(enable), .pulse(mode_entry_res)
    );

    wire [2:0] phase; // NUM_PHASES=5 -> ceil(log2(5))=3 bits
    wire last_phase;
    phase_counter #(.NUM_PHASES(5)) u_phase(
        .clk(clk), .reset(reset), .pause(pause), .enable(enable),
        .mode_entry(mode_entry_res), .btnc_pulse(btnc_pulse),
        .phase(phase), .last_phase(last_phase)
    );

    // --- Arithmetic chain ---
    wire [19:0] raw_sum;
    bcd_adder u_add(.a(balance_value), .b(refill_value), .sum(raw_sum));

    wire exceeds_cap;
    cap_compare u_cap(.sum(raw_sum), .exceeds_cap(exceeds_cap));

    wire [19:0] change;
    bcd_subtractor u_sub(.sum(raw_sum), .exceeds_cap(exceeds_cap), .change(change));

    // Inline clamp (no dedicated module in the hierarchy for this):
    // new_total is capped at 20000, never the raw (possibly overflowed) sum.
    localparam [19:0] CAP_20000 = {4'd2, 4'd0, 4'd0, 4'd0, 4'd0};
    wire [19:0] new_total = exceeds_cap ? CAP_20000 : raw_sum;

    wire [39:0] new_total_ascii, change_ascii;
    bcd_to_ascii u_ascii_total(.digits_in(new_total), .ascii_out(new_total_ascii));
    bcd_to_ascii u_ascii_change(.digits_in(change),    .ascii_out(change_ascii));

    // --- Shared reset/tick gating for all 5 rotating displays ---
    wire disp_reset = reset || mode_entry_res;
    wire disp_tick  = rotate_tick && !pause;

    wire [6:0] lbl_total_d0, lbl_total_d1, lbl_total_d2, lbl_total_d3;
    text_display #(.LEN(14), .MSG("UPDATED TOTAL ")) u_lbl_total(
        .clk(clk), .reset(disp_reset), .enable(enable), .rotate_tick(disp_tick),
        .digit0(lbl_total_d0), .digit1(lbl_total_d1), .digit2(lbl_total_d2), .digit3(lbl_total_d3)
    );

    wire [6:0] num_total_d0, num_total_d1, num_total_d2, num_total_d3;
    number_display u_num_total(
        .clk(clk), .reset(disp_reset), .enable(enable), .rotate_tick(disp_tick),
        .ascii_in(new_total_ascii),
        .digit0(num_total_d0), .digit1(num_total_d1), .digit2(num_total_d2), .digit3(num_total_d3)
    );

    wire [6:0] lbl_change_d0, lbl_change_d1, lbl_change_d2, lbl_change_d3;
    text_display #(.LEN(7), .MSG("CHANGE ")) u_lbl_change(
        .clk(clk), .reset(disp_reset), .enable(enable), .rotate_tick(disp_tick),
        .digit0(lbl_change_d0), .digit1(lbl_change_d1), .digit2(lbl_change_d2), .digit3(lbl_change_d3)
    );

    wire [6:0] num_change_d0, num_change_d1, num_change_d2, num_change_d3;
    number_display u_num_change(
        .clk(clk), .reset(disp_reset), .enable(enable), .rotate_tick(disp_tick),
        .ascii_in(change_ascii),
        .digit0(num_change_d0), .digit1(num_change_d1), .digit2(num_change_d2), .digit3(num_change_d3)
    );

    wire [6:0] arigato_d0, arigato_d1, arigato_d2, arigato_d3;
    text_display #(.LEN(8), .MSG("ARIGATO ")) u_arigato(
        .clk(clk), .reset(disp_reset), .enable(enable), .rotate_tick(disp_tick),
        .digit0(arigato_d0), .digit1(arigato_d1), .digit2(arigato_d2), .digit3(arigato_d3)
    );

    // 5:1 phase mux
    reg [6:0] mux_d0, mux_d1, mux_d2, mux_d3;
    always @(*) begin
        case (phase)
            3'd0: begin mux_d0=lbl_total_d0;  mux_d1=lbl_total_d1;  mux_d2=lbl_total_d2;  mux_d3=lbl_total_d3;  end
            3'd1: begin mux_d0=num_total_d0;  mux_d1=num_total_d1;  mux_d2=num_total_d2;  mux_d3=num_total_d3;  end
            3'd2: begin mux_d0=lbl_change_d0; mux_d1=lbl_change_d1; mux_d2=lbl_change_d2; mux_d3=lbl_change_d3; end
            3'd3: begin mux_d0=num_change_d0; mux_d1=num_change_d1; mux_d2=num_change_d2; mux_d3=num_change_d3; end
            3'd4: begin mux_d0=arigato_d0;    mux_d1=arigato_d1;    mux_d2=arigato_d2;    mux_d3=arigato_d3;    end
            default: begin mux_d0=7'b1111111; mux_d1=7'b1111111; mux_d2=7'b1111111; mux_d3=7'b1111111; end
        endcase
    end
    assign digit0 = mux_d0;
    assign digit1 = mux_d1;
    assign digit2 = mux_d2;
    assign digit3 = mux_d3;

    assign phase_done = last_phase && btnc_pulse && enable && !pause;
endmodule
