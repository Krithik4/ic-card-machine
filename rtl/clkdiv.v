`timescale 1ns / 1ps
module clkdiv #(
    parameter WIDTH = 27   // clk_out = COUNT[WIDTH-1], larger width decreases clk frequency and slows down output
)(
    input  wire clk,
    input  wire reset,
    output wire clk_out
);
    reg [WIDTH-1:0] COUNT = {WIDTH{1'b0}};
    assign clk_out = COUNT[WIDTH-1];

    always @(posedge clk) begin
        if (reset) COUNT <= 0;
        else COUNT <= COUNT + 1;
    end
endmodule
