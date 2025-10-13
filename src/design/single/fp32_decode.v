`timescale 1ns / 1ns

module fp32_decode(
    output wire SIGN_A_SINGLE,
    output wire SIGN_B_SINGLE,
    output wire [7:0] EXP_A_SINGLE,
    output wire [7:0] EXP_B_SINGLE,
    output wire [22:0] MANT_A_SINGLE,
    output wire [22:0] MANT_B_SINGLE,

    input [31:0] OP_A_SINGLE,
    input [31:0] OP_B_SINGLE,
    );

    assign SIGN_A_SINGLE = OP_A_SINGLE[31];
    assign SIGN_B_SINGLE = OP_B_SINGLE[31];

    assign [7:0] EXP_A_SINGLE = OP_A_SINGLE[30:23];
    assign [7:0] EXP_B_SINGLE = OP_B_SINGLE[30:23];

    assign [22:0] MANT_A_SINGLE = OP_A_SINGLE[22:0];
    assign [22:0] MANT_B_SINGLE = OP_B_SINGLE[22:0];

endmodule
