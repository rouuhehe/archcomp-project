module magnitude16_mul (
    output reg [15:0] Q,
    output reg exc,

    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_A_HALF,
    input wire [4:0] IN_EXP_B_HALF,
    input wire [9:0] IN_MANT_A_HALF,
    input wire [9:0] IN_MANT_B_HALF
);
    wire sign_res = SIGN_A ^ SIGN_B;

    always @(*) begin
        exc = 1'b1; 
        Q = 16'b0;

        if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0) &&
            (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0)) begin
            Q[15]   = sign_res;
            Q[14:10]= 5'b11111;
            Q[9:0]  = (IN_MANT_A_HALF <= IN_MANT_B_HALF) ? IN_MANT_A_HALF : IN_MANT_B_HALF;
        end

        else if (((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0) &&
                  (IN_EXP_B_HALF == 5'b00000 && IN_MANT_B_HALF == 10'b0)) ||
                 ((IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0) &&
                  (IN_EXP_A_HALF == 5'b00000 && IN_MANT_A_HALF == 10'b0))) begin
            exc = 1'b1;
            Q = 16'h7E00; // NaN
        end

        else if (IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0) begin
            Q[15]   = SIGN_A;
            Q[14:10]= IN_EXP_A_HALF;
            Q[9:0]  = IN_MANT_A_HALF;
        end

        else if (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0) begin
            Q[15]   = SIGN_B;
            Q[14:10]= IN_EXP_B_HALF;
            Q[9:0]  = IN_MANT_B_HALF;
        end

        else if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0) ||
                 (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0)) begin
            Q[15]   = sign_res;
            Q[14:10]= 5'b11111;
            Q[9:0]  = 10'b0000000000;
        end

        else if ((IN_EXP_A_HALF == 5'b00000 && IN_MANT_A_HALF == 10'b0) ||
                 (IN_EXP_B_HALF == 5'b00000 && IN_MANT_B_HALF == 10'b0)) begin
            Q[15]   = sign_res;
            Q[14:10]= 5'b00000;
            Q[9:0]  = 10'b0000000000;
        end

        else begin
            exc = 1'b0;
            // el cálculo real se hace en otro módulo (la parte normal)
            // acá solo se manejan las excepciones especiales
        end
    end

endmodule
