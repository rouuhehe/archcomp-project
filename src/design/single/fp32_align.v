`timescale 1ns / 1ns

module fp_align(
        output reg [22:0] aligned_a, // new mantissa 
        output reg [22:0] aligned_b, // new mantissa 
        output reg [7:0] exp,

        input wire [7:0] EXP_A,
        input wire [7:0] EXP_B,
        input wire [22:0] MANT_A,
        input wire [22:0] MANT_B
    );

    reg [7:0] sub;
    always @ (*) begin
        if(EXP_A < EXP_B) begin 
            sub = EXP_B - EXP_A;
            aligned_a = MANT_A >> sub;
            aligned_b = MANT_B;
            exp =  EXP_B;
        end
        else begin 
            sub = EXP_A - EXP_B;
            aligned_b = MANT_B >> sub;
            aligned_a = MANT_A;
            exp = EXP_A;
        end
    end

endmodule
