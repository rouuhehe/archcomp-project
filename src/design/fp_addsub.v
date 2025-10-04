`timescale 1ns / 1ps
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
    input [2:0] OP_CODE, // 000 = add, 001 = sub
    input SIGN_A,
    input SIGN_B,
    input [22:0] MANT_A,
    input [22:0] MANT_B
    );

    assign sign_res = SIGN_A ^ SIGN_B;  // 0 = pos, 1 = neg

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

endmodule
