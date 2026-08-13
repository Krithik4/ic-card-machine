`timescale 1ns / 1ps
// Combinational ASCII-character decoder. Covers: space (blank), digits
// '0'-'9' (so number_display's bcd_to_ascii output can be decoded the same
// way as text_display's ROM output), and every letter actually used in the
// project's banners:
//   CURRENT BALANCE, INPUT REFILL, UPDATED TOTAL, CHANGE, ARIGATO, OFF
//   -> A B C D E F G H I L N O P R T U
// seg = {a,b,c,d,e,f,g}, active-low, wired directly to the Basys3 seg pins.
//
// 'W' is kept in the table below (harmless, unused) in case a future string
// needs it, but is no longer required by any current banner.
module letter_to_7seg(
    input  wire [7:0] ascii,
    output reg  [6:0] seg
);
    always @(*) begin
        case (ascii)
            " "    : seg = 7'b1111111;
            "0"    : seg = 7'b0000001;
            "1"    : seg = 7'b1001111;
            "2"    : seg = 7'b0010010;
            "3"    : seg = 7'b0000110;
            "4"    : seg = 7'b1001100;
            "5"    : seg = 7'b0100100;
            "6"    : seg = 7'b0100000;
            "7"    : seg = 7'b0001111;
            "8"    : seg = 7'b0000000;
            "9"    : seg = 7'b0000100;
            "A"    : seg = 7'b0001000;
            "B"    : seg = 7'b1100000; // lowercase b glyph
            "C"    : seg = 7'b0110001;
            "D"    : seg = 7'b1000010; // lowercase d glyph
            "E"    : seg = 7'b0110000;
            "F"    : seg = 7'b0111000;
            "G"    : seg = 7'b0100001;
            "H"    : seg = 7'b1001000;
            "I"    : seg = 7'b1001111; // same as digit 1
            "L"    : seg = 7'b1110001;
            "N"    : seg = 7'b1101010; // lowercase n glyph
            "O"    : seg = 7'b0000001; // same as digit 0
            "P"    : seg = 7'b0011000;
            "R"    : seg = 7'b1111010; // lowercase r glyph
            "T"    : seg = 7'b1110000; // lowercase t glyph
            "U"    : seg = 7'b1000001;
            "W"    : seg = 7'b1100010; // approximation, see note above
            default: seg = 7'b1111111; // blank for anything unmapped
        endcase
    end
endmodule
