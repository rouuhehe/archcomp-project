`timescale 1ns / 1ns

module fp_decode(
    output wire sign_a,
    output wire sign_b,
    output wire [7:0] exp_a,
    output wire [7:0] exp_b,
    output wire [22:0] mant_a,
    output wire [22:0] mant_b,

    input [31:0] OP_A,
    input [31:0] OP_B,
    input MODE_FP // 0 = half, 1 = single
    );

    // half (16 bits): 1 sign, 5 exponent, 10 mantissa

    wire sign_a_half = OP_A[15];
    wire sign_b_half = OP_B[15];

    wire [4:0] exp_a_half = OP_A[14:10];
    wire [4:0] exp_b_half = OP_B[14:10];

    wire [9:0] mant_a_half = OP_A[9:0];
    wire [9:0] mant_b_half = OP_B[9:0];

    
    // single (32 bits): 1 sign, 8 exponent, 23 mantissa

    wire sign_a_single = OP_A[31];
    wire sign_b_single = OP_B[31];

    wire [7:0] exp_a_single = OP_A[30:23];
    wire [7:0] exp_b_single = OP_B[30:23];

    wire [22:0] mant_a_single = OP_A[22:0];
    wire [22:0] mant_b_single = OP_B[22:0];
    

    // MUX based on MODE_FP

    assign sign_a = MODE_FP ? sign_a_single : sign_a_half;
    assign sign_b = MODE_FP ? sign_b_single : sign_b_half;
    assign exp_a = MODE_FP ? exp_a_single : {3'b000, exp_a_half}; 
    assign exp_b = MODE_FP ? exp_b_single : {3'b000, exp_b_half};
    assign mant_a = MODE_FP ? mant_a_single : {13'b0, mant_a_half};
    assign mant_b = MODE_FP ? mant_b_single : {13'b0, mant_b_half};

endmodule
