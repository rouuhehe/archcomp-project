module magnitude16_sum(
    output [4:0] FLAGS, // [4]=, [3]=, [2]=UF, [1]=OF, [0]=INEXACT
    output [15:0] Q, // result

    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_HALF,
    input wire [10:0] IN_MANT_A_HALF,
    input wire [10:0] IN_MANT_B_HALF,
    input wire STICKY_BIT
    );

    wire [11:0] sum_mts = IN_MANT_A_HALF + IN_MANT_B_HALF;

/*
    reg [11:0] normalized;
    reg [4:0] final_exp;

    always @(*) begin
        final_exp = IN_EXP_HALF;
        normalized = sum_mts;
        if (!normalized[10] && (final_exp > 0)) begin
            normalized = normalized << 1;
            final_exp = final_exp - 1;
        end
        else if (normalized[11] && (final_exp < 5'b11111)) begin 
            normalized = normalized >> 1;
            final_exp = final_exp + 1;
        end  
    end

    // --- rounding ---

    reg [2:0] M;
    reg G, R, S;
    always @(*) begin
    M = normalized[6:4];
    G = normalized[3];
    R = normalized[2];
    end

    reg [3:0] rounded_mts, final_exp_out;
    always @(*) begin
    if (G & (R | STICKY_BIT | M[0]))
        rounded_mts = M + 1;
    else
        rounded_mts = M;

    final_exp_out = final_exp;

    if (rounded_mts[3] == 1) begin
        rounded_mts = rounded_mts >> 1;
        final_exp_out = final_exp_out + 1;
    end
    end


    assign Q[7] = sign_a;
    assign Q[6:3] = (denormal != 2'b00) ? final_exp_out : 4'b0000;
    assign Q[2:0] = rounded_mts[2:0];

    */
endmodule