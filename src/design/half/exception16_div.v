module exception16_div (
    output reg [15:0] Q,
    output reg exc,

    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_A_HALF,
    input wire [4:0] IN_EXP_B_HALF,
    input wire [9:0] IN_MANT_A_HALF,
    input wire [9:0] IN_MANT_B_HALF
);

    always @(*) begin
        exc = 1'b1;
        Q   = 16'b0;

        // NaN / anything
        if (IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0000000000) begin
            Q = {SIGN_A, 5'b11111, IN_MANT_A_HALF};
        end

        // anything / NaN => NaN
        else if (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0000000000) begin
            Q = {SIGN_B, 5'b11111, IN_MANT_B_HALF};
        end

        // ±Inf / ±Inf => NaN
        else if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 0) &&
                 (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 0)) begin
            Q = 16'h7E00; // canonical NaN
        end

        // 0 / 0 => NaN
        else if ((IN_EXP_A_HALF == 5'b00000 && IN_MANT_A_HALF == 0) &&
                 (IN_EXP_B_HALF == 5'b00000 && IN_MANT_B_HALF == 0)) begin
            Q = 16'h7E00; // canonical NaN
        end

        // ±Inf / n => ±Inf
        else if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 0) &&
                 !(IN_EXP_B_HALF == 5'b11111)) begin
            Q = {SIGN_A ^ SIGN_B, 5'b11111, 10'b0000000000};
        end

        // n / ±Inf => 0
        else if ((IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 0) &&
                 !(IN_EXP_A_HALF == 5'b11111)) begin
            Q = {SIGN_A ^ SIGN_B, 5'b00000, 10'b0000000000};
        end

        // n / 0 => ±Inf
        else if (!(IN_EXP_A_HALF == 5'b00000 && IN_MANT_A_HALF == 0) &&
                 (IN_EXP_B_HALF == 5'b00000 && IN_MANT_B_HALF == 0)) begin
            Q = {SIGN_A ^ SIGN_B, 5'b11111, 10'b0000000000};
        end

        // 0 / n => 0
        else if ((IN_EXP_A_HALF == 5'b00000 && IN_MANT_A_HALF == 0) &&
                 !(IN_EXP_B_HALF == 5'b00000 && IN_MANT_B_HALF == 0)) begin
            Q = {SIGN_A ^ SIGN_B, 5'b00000, 10'b0000000000};
        end

        // normal case
        else begin
            exc = 1'b0;
        end
    end

endmodule
