`timescale 1ns / 1ns

// TODO REMOVE FLAGS

module fp_division(
    output wire [47:0] mant,
    output wire [8:0] exp,
    output wire sign,
    output reg [4:0] FLAGS,

    input [7:0] EXP_A,
    input [7:0] EXP_B,
    input [22:0] MANT_A,
    input [22:0] MANT_B,
    input MODE_FP, // 0 = half, 1 = single
    input SIGN_A,
    input SIGN_B
    );

    wire [7:0] bias = (MODE_FP) ? 9'd127 : 9'd15;
    assign exp = {1'b0, EXP_A} - {1'b0, EXP_B} + {1'b0, bias};
    assign sign = SIGN_A ^ SIGN_B;
    
    wire [8:0] MAX_EXP = (MODE_FP) ? 9'd254 : 9'd30;
    wire [8:0] MIN_EXP = 9'd1;

    always @(*) begin
        FLAGS = 5'b00000; 

        if (MANT_B == 0 && EXP_B == 0) begin 
            if (MANT_A == 0 && EXP_A == 0) FLAGS[1] = 1'b1; // INVALID (0 / 0)
            else FLAGS[2] = 1'b1; // DIVIDE-BY-ZERO
        end
        else if ((EXP_A == MAX_EXP+1 && MANT_A == 0) && (EXP_B == MAX_EXP+1 && MANT_B == 0)) FLAGS[1] = 1'b1;  // inf / inf = INVALID
        else if (exp > MAX_EXP) FLAGS[4] = 1'b1; // OVERFLOW
        else if (exp < MIN_EXP) FLAGS[3] = 1'b1; // UNDERFLOW
    end
endmodule
