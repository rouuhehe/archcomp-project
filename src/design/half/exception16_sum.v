module magnitude16_sum (
    output reg [15:0] Q, // result
    output reg exc, // exception flag

    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_B_HALF,
    input wire [4:0] IN_EXP_A_HALF,
    input wire [10:0] IN_MANT_A_HALF,
    input wire [10:0] IN_MANT_B_HALF
    );

    always @(*) begin
        exc = 1'b1; 
        Q = 16'b0;
        // both NaN
        if((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 11'b00000000000) && 
           (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 11'b00000000000)) begin
            Q[15] = SIGN_A;
            Q[14:10] = 5'b11111;
            Q[9:0] = (IN_MANT_A_HALF <= IN_MANT_B_HALF) ? IN_MANT_A_HALF : IN_MANT_B_HALF; 
        end

        // A is NaN
        else if(IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 11'b00000000000) begin
            Q[15] = SIGN_A;
            Q[14:10] = IN_EXP_A_HALF;
            Q[9:0] = IN_MANT_A_HALF;
        end
        
        // B is NaN
        else if(IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 11'b00000000000) begin
            Q[15] = SIGN_B;
            Q[14:10] = IN_EXP_B_HALF;
            Q[9:0] = IN_MANT_B_HALF;
        end
        
        // one is +-inf
        else if((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 11'b00000000000) || 
                (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 11'b00000000000)) begin
            Q[15] = (IN_EXP_A_HALF == 5'b11111) ? SIGN_A : SIGN_B;
            Q[14:10] = 5'b11111;
            Q[9:0] = 11'b00000000000;
        end
        
        // A is zero
        else if(IN_EXP_A_HALF == 5'b00000 && IN_MANT_A_HALF == 11'b00000000000) begin
            Q[15] = SIGN_B;
            Q[14:10] = IN_EXP_B_HALF;
            Q[9:0] = IN_MANT_B_HALF;
        end
        
        // B is zero
        else if(IN_EXP_B_HALF == 5'b00000 && IN_MANT_B_HALF == 11'b00000000000) begin
            Q[15] = SIGN_A;
            Q[14:10] = IN_EXP_A_HALF;
            Q[9:0] = IN_MANT_A_HALF;
        end
        else
            exc = 1'b0;
    end
    

endmodule