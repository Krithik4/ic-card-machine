`timescale 1ns / 1ps
// NOTE ON DEBOUNCE_WIDTH: the original Lab 2 version of this module hardwired
// its internal clkdiv to WIDTH=27, i.e. it only samples `signal` about once
// every 1.34s at 100 MHz. That's fine for nothing at human timescales -- a
// real button press comes and goes well within that window, so outedge would
// never fire at all (verified: held high 50ms, zero pulses). This module is
// reused throughout the hierarchy both for real buttons and for internal
// signal-transition detection (mode_entry, custom_active), neither of which
// can tolerate that. Adding this parameter changes no behavior for an
// unmodified instantiation (default still matches the original 27-bit
// counter); it just lets callers ask for a sane sampling rate.
module rising_edge_detector #(
    parameter DEBOUNCE_WIDTH = 27
)(
    input wire clk,
    input wire signal,
    input wire reset,
    output reg outedge
);
    wire slow_clk;
    reg [1:0] state, next_state;
    
    clkdiv #(.WIDTH(DEBOUNCE_WIDTH)) c1(.clk(clk), .reset(reset), .clk_out(slow_clk));

    // Combinational logic: next state + output.
    always @(*) begin
        next_state = state;
        outedge = 1'b0;
        case(state)
            2'b00: begin
                if (signal) next_state = 2'b01;
            end
            2'b01: begin
                if (signal) next_state = 2'b10;
                else next_state = 2'b00;
                outedge = 1'b1;
            end
            2'b10: begin
                if (!signal) next_state = 2'b00;
            end
            2'b11: begin
                next_state = 2'b00;
            end
        endcase
    end
    
    // Sequential logic on the slow clock with asynchronous reset.
    always @(posedge slow_clk or posedge reset) begin
        if(reset) state <= 2'b00;
        else state <= next_state;
    end
endmodule