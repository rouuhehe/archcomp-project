`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2025 01:02:42 PM
// Design Name: 
// Module Name: fp_addsub
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module fp_addsub(
    output reg sign, // 0 = pos, 1 = neg
    output reg [24:0] mant,
    output reg [4:0] flags,

    input SIGN_A,
    input SIGN_B,
    input MODE_FP, // 0 = half, 1 = single
    input [2:0] OP_CODE, // 000 = add, 001 = sub
    input [22:0] MANT_A,
    input [22:0] MANT_B,
    input [8:0] EXP
    );

    always @ (*) begin
        case(OP_CODE)
            3'b000: begin // addition
                if(SIGN_A == SIGN_B) begin // if eq then sum
                    mant = MANT_A + MANT_B;
                    sign = SIGN_A;
                end
                else begin // if diff then sub
                    if(MANT_A >= MANT_B) begin
                        mant = MANT_A - MANT_B;
                        sign = SIGN_A;
                    end
                    else begin
                        mant = MANT_B - MANT_A;
                        sign = SIGN_B;
                    end
                end
            end
            3'b001: begin //substraction
                if(SIGN_A == SIGN_B) begin
                    if(MANT_A >= MANT_B) begin
                        mant = MANT_A - MANT_B;
                        sign = SIGN_A;
                    end
                    else begin
                        mant = MANT_B - MANT_A;
                        sign = ~SIGN_A;
                    end
                end
                else begin 
                    mant = MANT_A +  MANT_B;
                    sign = SIGN_A;
                end
            end
        endcase
    end

    wire [8:0] max_exp  = (MODE_FP) ? 9'd254 : 9'd30; 
    wire [8:0] min_exp  = 9'd1;  
    always @(*) begin
        flags = 5'b00000;
        if (EXP == 8'b0 && mant == 0) flags = 5'b00000; // ZERO
        else if (EXP < min_exp && mant != 0) flags = 5'b10000; // DENORMAL
        else if (EXP == (max_exp + 1) && mant == 0) flags = 5'b11111; // INF
        else if (EXP == (max_exp + 1) && mant != 0) flags = 5'b00001; // NaN
        else if (EXP > max_exp + 1) flags = 5'b00010;  // OVERFLOW
        else if (EXP < min_exp) flags = 5'b00011;  // UNDERFLOW
    end
endmodule
