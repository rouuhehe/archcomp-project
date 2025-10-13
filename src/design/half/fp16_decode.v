`timescale 1ns / 1ns

module fp16_decode(
    output wire SIGN_A_HALF,
    output wire SIGN_B_HALF,
    output wire [4:0] EXP_A_HALF,
    output wire [4:0] EXP_B_HALF,
    output wire [9:0] MANT_A_HALF,
    output wire [9:0] MANT_B_HALF,

    input [15:0] OP_A_HALF,
    input [15:0] OP_B_HALF
    );

    assign SIGN_A_HALF = OP_A_HALF[15];
    assign SIGN_B_HALF = OP_B_HALF[15];

    assign [4:0] EXP_A_HALF = OP_A_HALF[14:10];
    assign [4:0] EXP_B_HALF = OP_B_HALF[14:10];

    assign [9:0] MANT_A_HALF = OP_A_HALF[9:0];
    assign [9:0] MANT_B_HALF = OP_B_HALF[9:0];

endmodule
