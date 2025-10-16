module magnitude16_sub (
    output [15:0] Q, // result
    output [4:0] FLAGS, // [4]=, [3]=, [2]=UF, [1]=OF, [0]=INEXACT

    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_HALF,
    input wire [10:0] IN_MANT_A_HALF,
    input wire [10:0] IN_MANT_B_HALF,
    );
    
    reg [11:0] mant;
    reg sign;

    always @(*) begin
        if(SIGN_A == SIGN_B) begin
            if(IN_MANT_A_HALF >= IN_MANT_B_HALF) begin
                mant = {1'b0, IN_MANT_A_HALF} - {1'b0, IN_MANT_B_HALF};
                sign = SIGN_A;
            end
            else begin
                mant = {1'b0, IN_MANT_B_HALF} - {1'b0, IN_MANT_A_HALF};
                sign = SIGN_B;
            end
        end
        else begin 
            mant = IN_MANT_A_HALF +  IN_MANT_B_HALF;
            sign = SIGN_A;
        end
    end


    // normalize
    // round
    // flags



endmodule