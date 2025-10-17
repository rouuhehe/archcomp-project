module magnitude16_mul(
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
    wire [31:0] mant;
    wire [4:0] bias = 5'd15;
    wire [5:0] exp = {1'b0, EXP_A} + {1'b0, EXP_B} - {1'b0, bias};
    wire mant = IN_MANT_A_HALF * IN_MANT_B_HALF;
    
    // normalize
    fp16_normalize normalize_inst (
        .OUT_MANT(mant_norm),
        .OUT_EXP(exp_norm),
        .IN_MANT(mant),
        .IN_EXP(exp)
    );
    // round

    assign Q = {sign, exp[4:0], mant[9:0]};

endmodule