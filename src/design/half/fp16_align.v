`timescale 1ns / 1ns

module fp16_align(
        output reg [9:0] OUT_MANT_A_HALF, // new mantissa 
        output reg [9:0] OUT_MANT_B_HALF, // new mantissa 
        output reg [4:0] OUT_EXP_HALF,
        output reg STICKY_BIT,
        output reg EXCEPTION_ALIGN_HALF,

        input wire [4:0] IN_EXP_A_HALF,
        input wire [4:0] IN_EXP_B_HALF,
        input wire [9:0] IN_MANT_A_HALF,
        input wire [9:0] IN_MANT_B_HALF
    );

    
    reg [4:0] sub;

    always @ (*) begin

        OUT_MANT_A_HALF = IN_MANT_A_HALF;
        OUT_MANT_B_HALF = IN_MANT_B_HALF;
        OUT_EXP_HALF = IN_EXP_A_HALF;
        EXCEPTION_ALIGN_HALF = 0;
        STICKY_BIT = 0;

        // Exception flag sets 1 if either one of the exponents is 31.
        if(( &IN_EXP_A_HALF ) | ( &IN_EXP_B_HALF )) begin
            EXCEPTION_ALIGN_HALF = 1;
            OUT_MANT_A_HALF = 0;
            OUT_MANT_B_HALF = 0;
            OUT_EXP_HALF = 5'b11111;
        end
        else if (IN_EXP_A_HALF > IN_EXP_B_HALF) begin
            sub = IN_EXP_A_HALF - IN_EXP_B_HALF;
            OUT_EXP_HALF = IN_EXP_A_HALF;

            if(sum >= 10) begin // if one exp is much bigger than the other
                OUT_MANT_B_HALF = 0;
                STICKY_BIT  = |IN_MANT_B_HALF;
            end
            else begin
                OUT_MANT_B_HALF = IN_MANT_B_HALF >> sub;
                STICKY_BIT = |(IN_MANT_B_HALF[sub-1:0]);    
            end
        end 
        
        else if (IN_EXP_B_HALF > IN_EXP_A_HALF) begin
            sub = IN_EXP_A_HALF - IN_EXP_B_HALF;
            OUT_EXP_HALF = IN_EXP_A_HALF;

            if(sum >= 10) begin
                OUT_MANT_A_HALF = 0;
                STICKY_BIT  = |IN_MANT_A_HALF;
            end
            else begin
                OUT_MANT_A_HALF = IN_MANT_A_HALF >> sub;
                STICKY_BIT = |(IN_MANT_A_HALF[sub-1:0]);    
            end
        end
    end

endmodule
