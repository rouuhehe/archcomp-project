`timescale 1ns / 1ns

module fp_division(
    output wire [48:0] mant,
    output wire [8:0] exp,
    output wire sign,
    output reg [4:0] flags, // 0000 = overflow, 

    input [7:0] EXP_A,
    input [7:0] EXP_B,
    input [22:0] MANT_A,
    input [22:0] MANT_B,
    input MODE_FP, // 0 = half, 1 = single
    input SIGN_A,
    input SIGN_B
    );

    wire [7:0] bias = (MODE_FP) ? 8'd127 : 8'd15;
    assign exp = {1'b0, EXP_A} - {1'b0, EXP_B} + {1'b0, bias};
    assign sign = SIGN_A ^ SIGN_B;
    
    wire [8:0] max_exp = (MODE_FP) ? 9'd254 : 9'd30;
    wire [8:0] min_exp = 9'd1;

    always @(*) begin
        flags = 5'b00000; // default
        if (MANT_B == 0 && EXP_B == 0) begin // DIVIDE-BY-ZERO
            if (MANT_A == 0 && EXP_A == 0) flags = 5'b01000; // 0/0 = INVALID OP
            else flags = 5'b00010; // X / 0 = DIVIDE-BY-ZERO (X != 0)
        end
        else if ((EXP_A == max_exp+1 && MANT_A == 0) && (EXP_B == max_exp+1 && MANT_B == 0)) flags = 5'b01000;  // inf / inf = INVALID
        else begin
            if (exp == 0 && mant == 0) flags = 5'b00000;       // ZERO
            else if (exp < min_exp && mant != 0) flags = 5'b10000; // DENORMAL
            else if (exp > max_exp && mant == 0) flags = 5'b11111; // INF
            else if (exp > max_exp && mant != 0) flags = 5'b00001; // NaN
            else if (exp > max_exp) flags = 5'b11000;           // OVERFLOW
            else if (exp < min_exp) flags = 5'b00011;           // UNDERFLOW
        end
    end
endmodule
