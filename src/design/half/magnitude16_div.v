module magnitude16_div(
    output [15:0] Q, // result
    output [4:0] FLAGS, // [4]=, [3]=, [2]=UF, [1]=OF, [0]=INEXACT

    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_A_HALF,
    input wire [4:0] IN_EXP_B_HALF,
    input wire [10:0] IN_MANT_A_HALF,
    input wire [10:0] IN_MANT_B_HALF
);

    wire sign = SIGN_A ^ SIGN_B;
    wire [21:0] mant_div;
    wire [5:0] exp_div;
    wire [4:0] bias = 5'd15;

    assign exp_div = {1'b0, IN_EXP_A_HALF} - {1'b0, IN_EXP_B_HALF} + {1'b0, bias};
    assign mant_div = IN_MANT_A_HALF / IN_MANT_B_HALF;

    wire [10:0] mant_norm;
    wire [4:0] exp_norm;

    fp_normalize #(
        .MB(21),
        .EB(5)
    ) normalize_inst (
        .OUT_MANT(mant_norm),
        .OUT_EXP(exp_norm),
        .IN_MANT(mant_div),
        .IN_EXP(exp_div)
    );

    reg [9:0] mant_rounded;
    reg [4:0] exp_rounded;

    // round

    assign Q = {sign, exp_rounded, mant_rounded};

endmodule
