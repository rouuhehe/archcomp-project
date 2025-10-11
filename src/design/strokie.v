`timescale 1ns / 1ns

module strokie(
    output reg [31:0] RESULT,
    output VALID_OUT,
    output [4:0] FLAGS, 
    input CLK, 
    input RESET, 
    input [31:0] OP_A, 
    input [31:0] OP_B, 
    input [2:0] OP_CODE, 
    input MODE_FP, 
    input ROUND_MODE, 
    input START
);

    // -------- signs -------

    wire sign_a, sign_b;
    wire [7:0] exp_a, exp_b;
    wire [22:0] mant_a, mant_b;

    wire [22:0] aligned_a, aligned_b;
    wire [7:0] aligned_exp;

    wire addsum_sign;
    wire [24:0] addsum_mantissa;

    wire [48:0] mantissa_normalized;
    wire [8:0] exp_normalized;

    wire [7:0] exp_rounded;
    wire [22:0] mant_rounded;
    wire [4:0] flags_internal;

    reg valid_out_reg;

    
    // -------- modules -------
    
    fp_decode decoder (
        .sign_a(sign_a),
        .sign_b(sign_b),
        .exp_a(exp_a),
        .exp_b(exp_b),
        .mant_a(mant_a),
        .mant_b(mant_b),
        .OP_A(OP_A),
        .OP_B(OP_B),
        .MODE_FP(MODE_FP)
    );

    fp_align alignsub (
        .aligned_a(aligned_a),
        .aligned_b(aligned_b),
        .exp(aligned_exp),
        .EXP_A(exp_a),
        .EXP_B(exp_b),
        .MANT_A(mant_a),
        .MANT_B(mant_b)
    );

    fp_addsub addsub (
        .sign(addsum_sign),
        .mant(addsum_mantissa),
        .SIGN_A(sign_a),
        .SIGN_B(sign_b),
        .MODE_FP(MODE_FP),
        .OP_CODE(OP_CODE),
        .MANT_A(aligned_a),
        .MANT_B(aligned_b)
    );

    fp_normalize normalize_stage (
        .mant(mantissa_normalized),
        .exp(exp_normalized),
        .FLAGS(flags_internal),
        .MODE_FP(MODE_FP),
        .MANT({24'b0, addsum_mantissa}),
        .EXP({1'b0, aligned_exp})
    );

    fp_rounder round_stage (
        .exp(exp_rounded),
        .mant(mant_rounded),
        .FLAGS(flags_internal), 
        .EXP(exp_normalized),
        .MANT(mantissa_normalized),
        .FLAGS_IN(flags_internal),
        .MODE_FP(MODE_FP)
    );


    assign VALID_OUT = START;
    assign FLAGS = flags_internal;

    always @(*) begin
        if (MODE_FP) begin
            // single 
            RESULT = {addsum_sign, exp_rounded, mant_rounded};
        end else begin
            // half 
            RESULT = {16'b0, addsum_sign, exp_rounded[7:3], mant_rounded[22:13]};
        end
    end

endmodule
