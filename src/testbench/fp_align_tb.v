/*
`timescale 1ns / 1ps

module tb_fp_align;

    reg [7:0] EXP_A, EXP_B;
    reg [22:0] MANT_A, MANT_B;
    reg IS_DENORMAL_A, IS_DENORMAL_B;

    wire [22:0] aligned_a, aligned_b;
    wire [7:0] exp;

    fp_align uut (
        .aligned_a(aligned_a),
        .aligned_b(aligned_b),
        .exp(exp),
        .EXP_A(EXP_A),
        .EXP_B(EXP_B),
        .MANT_A(MANT_A),
        .MANT_B(MANT_B),
        .IS_DENORMAL_A(IS_DENORMAL_A),
        .IS_DENORMAL_B(IS_DENORMAL_B)
    );

    initial begin
        $monitor("t=%0t | EXP_A=%0d EXP_B=%0d | MANT_A=%b MANT_B=%b | aligned_a=%b aligned_b=%b | exp=%0d",
                 $time, EXP_A, EXP_B, MANT_A[7:0], MANT_B[7:0], aligned_a[7:0], aligned_b[7:0], exp);

        // Caso 1: EXP_A < EXP_B
        EXP_A = 3; EXP_B = 5;
        MANT_A = 23'b00000000000000000010101; // 0b10101
        MANT_B = 23'b00000000000000000011110; // 0b11110
        IS_DENORMAL_A = 0; IS_DENORMAL_B = 0;
        #10;

        // Caso 2: EXP_A > EXP_B
        EXP_A = 7; EXP_B = 4;
        MANT_A = 23'b00000000000000000011000; // 0b11000
        MANT_B = 23'b00000000000000000000111; // 0b00111
        #10;

        // Caso 3: EXP_A == EXP_B
        EXP_A = 6; EXP_B = 6;
        MANT_A = 23'b00000000000000000010000; // 0b10000
        MANT_B = 23'b00000000000000000001000; // 0b01000
        #10;

        $finish;
    end

endmodule
*/