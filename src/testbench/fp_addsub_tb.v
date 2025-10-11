`timescale 1ns / 1ns
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/04/2025 04:09:49 PM
// Design Name: 
// Module Name: fp_addsub_tb
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


module fp_addsub_tb;

    // Inputs
    reg [2:0] OP_CODE;
    reg SIGN_A;
    reg SIGN_B;
    reg [22:0] MANT_A;
    reg [22:0] MANT_B;

    // Outputs
    wire sign;
    wire [24:0] mant;

    // DUT
    fp_addsub uut (
        .sign(sign),
        .mant(mant),
        .OP_CODE(OP_CODE),
        .SIGN_A(SIGN_A),
        .SIGN_B(SIGN_B),
        .MANT_A(MANT_A),
        .MANT_B(MANT_B)
    );

    initial begin
        $display("=== TEST FP_ADDSUB ===");
        $monitor("t=%0t | OP=%b | A(sign=%b, mant=%d) | B(sign=%b, mant=%d) | => RES(sign=%b, mant=%d)",
                 $time, OP_CODE, SIGN_A, MANT_A, SIGN_B, MANT_B, sign, mant);

        // Caso 1: ADD (positivos)
        OP_CODE = 3'b000;
        SIGN_A = 0; SIGN_B = 0;
        MANT_A = 23'd5; MANT_B = 23'd3;
        #10;

        // Caso 2: ADD (uno negativo)
        OP_CODE = 3'b000;
        SIGN_A = 0; SIGN_B = 1;
        MANT_A = 23'd8; MANT_B = 23'd2;
        #10;

        // Caso 3: SUB (positivos)
        OP_CODE = 3'b001;
        SIGN_A = 0; SIGN_B = 0;
        MANT_A = 23'd9; MANT_B = 23'd4;
        #10;

        // Caso 4: SUB (negativos)
        OP_CODE = 3'b001;
        SIGN_A = 1; SIGN_B = 1;
        MANT_A = 23'd4; MANT_B = 23'd6;
        #10;

        // Caso 5: SUB con signos distintos
        OP_CODE = 3'b001;
        SIGN_A = 1; SIGN_B = 0;
        MANT_A = 23'd5; MANT_B = 23'd3;
        #10;

        $finish;
    end

endmodule
