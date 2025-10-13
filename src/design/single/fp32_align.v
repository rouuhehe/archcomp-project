`timescale 1ns / 1ns

module fp32_align(
    output reg [23:0] OUT_MANT_A_SINGLE, // aligned mantissa A (sin hidden bit)
    output reg [23:0] OUT_MANT_B_SINGLE, // aligned mantissa B (sin hidden bit)
    output reg [7:0]  OUT_EXP_SINGLE,    // common exponent
    output reg STICKY_BIT,
    output reg EXCEPTION_ALIGN_SINGLE,

    input wire [7:0] IN_EXP_A_SINGLE,
    input wire [7:0] IN_EXP_B_SINGLE,
    input wire [22:0] IN_MANT_A_SINGLE,
    input wire [22:0] IN_MANT_B_SINGLE
);

    reg [23:0] mant_a, mant_b;  // with hidden bit
    reg [7:0] exp_a, exp_b;
    reg [7:0] sub;

    // handle denormals
    always @(*) begin
        if (IN_EXP_A_SINGLE == 0)
            {exp_a, mant_a} = {8'd1, {1'b0, IN_MANT_A_SINGLE}}; // no hidden 1
        else
            {exp_a, mant_a} = {IN_EXP_A_SINGLE, {1'b1, IN_MANT_A_SINGLE}}; // normal

        if (IN_EXP_B_SINGLE == 0)
            {exp_b, mant_b} = {8'd1, {1'b0, IN_MANT_B_SINGLE}};
        else
            {exp_b, mant_b} = {IN_EXP_B_SINGLE, {1'b1, IN_MANT_B_SINGLE}};
    end

    always @(*) begin
        // default outputs
        OUT_MANT_A_SINGLE = mant_a;
        OUT_MANT_B_SINGLE = mant_b;
        OUT_EXP_SINGLE = exp_a;
        EXCEPTION_ALIGN_SINGLE = 0;
        STICKY_BIT = 0;
        sub = 0;

        // exception handling (NaN / Inf)
        if ((&IN_EXP_A_SINGLE) | (&IN_EXP_B_SINGLE)) begin
            EXCEPTION_ALIGN_SINGLE = 1;
            OUT_MANT_A_SINGLE = 0;
            OUT_MANT_B_SINGLE = 0;
            OUT_EXP_SINGLE = 8'd255;
        end 
        
        else if (exp_a > exp_b) begin
            sub = exp_a - exp_b;
            OUT_EXP_SINGLE = exp_a;

            if (sub >= 24) begin 
                OUT_MANT_B_SINGLE = 0;
                STICKY_BIT = |mant_b; // any 1 lost to right shift
            end else begin
                OUT_MANT_B_SINGLE = mant_b >> sub;
                STICKY_BIT = (sub == 0) ? 0 : |mant_b[sub-1:0];
            end
        end 
        
        else if (exp_b > exp_a) begin
            sub = exp_b - exp_a;
            OUT_EXP_SINGLE = exp_b;

            if (sub >= 24) begin
                OUT_MANT_A_SINGLE = 0;
                STICKY_BIT = |mant_a;
            end else begin
                OUT_MANT_A_SINGLE = mant_a >> sub;
                STICKY_BIT = (sub == 0) ? 0 : |mant_a[sub-1:0];
            end
        end

        else begin
            OUT_MANT_A_SINGLE = mant_a;
            OUT_MANT_B_SINGLE = mant_b;
            OUT_EXP_SINGLE = exp_a;
        end
    end

endmodule
