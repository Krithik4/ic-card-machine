//Reused from previous lab exactly - module helps to display all digits accurately
`timescale 1ns / 1ps
module time_mux_state_machine(
    input wire clk,
    input wire reset,
    input wire [6:0] in0, in1, in2, in3,
    output reg [3:0] an,
    output reg [6:0] sseg
);
    reg [1:0] state, next_state;
    
    // State transition.
    always @(*) begin
        case (state)
            2'b00: next_state = 2'b01;
            2'b01: next_state = 2'b10;
            2'b10: next_state = 2'b11;
            2'b11: next_state = 2'b00;
            default: next_state = 2'b00;
        endcase
    end
    
    // Output multiplexer (segments).
    always @(*) begin
        case (state)
            2'b00: sseg = in0;
            2'b01: sseg = in1;
            2'b10: sseg = in2;
            2'b11: sseg = in3;
            default: sseg = 7'b1111111; // all segments off (active-low)
        endcase
    end
    
    // Output decoder (active-low anodes).
    always @(*) begin
        case (state)
            2'b00: an = 4'b1110;
            2'b01: an = 4'b1101;
            2'b10: an = 4'b1011;
            2'b11: an = 4'b0111;
            default: an = 4'b1111;
        endcase
    end
    
    // State register with async reset.
    always @(posedge clk or posedge reset) begin
        if (reset) state <= 2'b00;
        else state <= next_state;
        // Hint: don't forget about the reset signal, which can be handled with an ifstatement.
    end
endmodule