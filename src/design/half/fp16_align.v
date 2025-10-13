`timescale 1ns / 1ns

module fp16_align(
    output reg [10:0] OUT_MANT_A_HALF, // aligned mantissa A
    output reg [10:0] OUT_MANT_B_HALF, // aligned mantissa B
    output reg [4:0] OUT_EXP_HALF,    // common exponent
    output reg STICKY_BIT,
    output reg EXCEPTION_ALIGN_HALF,

    input wire [4:0] IN_EXP_A_HALF,
    input wire [4:0] IN_EXP_B_HALF,
    input wire [9:0] IN_MANT_A_HALF,
    input wire [9:0] IN_MANT_B_HALF
);

    reg [10:0] mant_a, mant_b; // with hidden bit
    reg [4:0] exp_a, exp_b;
    reg [4:0] sub;

    always @(*) begin
        // handle denormals
        if (IN_EXP_A_HALF == 0)
            {exp_a, mant_a} = {5'd1, {1'b0, IN_MANT_A_HALF}}; // denormal
        else
            {exp_a, mant_a} = {IN_EXP_A_HALF, {1'b1, IN_MANT_A_HALF}}; // normal

        if (IN_EXP_B_HALF == 0)
            {exp_b, mant_b} = {5'd1, {1'b0, IN_MANT_B_HALF}};
        else
            {exp_b, mant_b} = {IN_EXP_B_HALF, {1'b1, IN_MANT_B_HALF}};
    end

    always @(*) begin
        // default outputs
        OUT_MANT_A_HALF = mant_a;
        OUT_MANT_B_HALF = mant_b;
        OUT_EXP_HALF = exp_a;
        EXCEPTION_ALIGN_HALF = 0;
        STICKY_BIT = 0;
        sub = 0;

        // exception handling (NaN / Inf)
        if ((&IN_EXP_A_HALF) | (&IN_EXP_B_HALF)) begin
            EXCEPTION_ALIGN_HALF = 1;
            OUT_MANT_A_HALF = 0;
            OUT_MANT_B_HALF = 0;
            OUT_EXP_HALF = 5'b11111;
        end
        
        else if (exp_a > exp_b) begin
            sub = exp_a - exp_b;
            OUT_EXP_HALF = exp_a;

            if (sub >= 10) begin
                OUT_MANT_B_HALF = 0;
                STICKY_BIT = |mant_b; // any 1 lost to right shift
            end else begin
                OUT_MANT_B_HALF = mant_b >> sub;
                STICKY_BIT = |(mant_b[sub-1:0]);
            end
        end
        
        else if (exp_b > exp_a) begin
            sub = exp_b - exp_a;
            OUT_EXP_HALF = exp_b;

            if (sub >= 10) begin
                OUT_MANT_A_HALF = 0;
                STICKY_BIT = |mant_a;
            end else begin
                OUT_MANT_A_HALF = mant_a >> sub;
                STICKY_BIT = |(mant_a[sub-1:0]);
            end
        end

        else begin
            OUT_MANT_A_HALF = mant_a;
            OUT_MANT_B_HALF = mant_b;
            OUT_EXP_HALF = exp_a;
        end

    end

endmodule
