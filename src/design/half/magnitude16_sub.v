module magnitude16_sub (
    output [15:0] Q, // result
    output [4:0] FLAGS, // [4]=, [3]=, [2]=UF, [1]=OF, [0]=INEXACT

    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_HALF,
    input wire [10:0] IN_MANT_A_HALF,
    input wire [10:0] IN_MANT_B_HALF
    );
    
    reg [12:0] mant;
    reg sign;

    always @(*) begin
        if(SIGN_A == SIGN_B) begin
            if(IN_MANT_A_HALF >= IN_MANT_B_HALF) begin
                mant = IN_MANT_A_HALF - IN_MANT_B_HALF;
                sign = SIGN_A;
            end
            else begin
                mant = IN_MANT_B_HALF - IN_MANT_A_HALF;
                sign = SIGN_B;
            end
        end
        else begin
            if (IN_MANT_A_HALF >= IN_MANT_B_HALF) begin
                mant = IN_MANT_A_HALF - IN_MANT_B_HALF;
                sign = SIGN_A;
            end else begin
                mant = IN_MANT_B_HALF - IN_MANT_A_HALF;
                sign = SIGN_B;
            end
        end
    end

    wire [9:0] mant_norm;
    wire [4:0] exp_norm;

    // normalize
    fp_normalize norm_mod #(
        .MB(13),
        .EB(5)
    )(
        .OUT_MANT(mant_norm),
        .OUT_EXP(exp_norm),
        .IN_MANT(mant),
        .IN_EXP(IN_EXP_HALF)
    );

    // round
 
    assign Q = {sign, exp_norm, mant_norm};
    // flags

endmodule