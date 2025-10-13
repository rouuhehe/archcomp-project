`timescale 1ns / 1ns

module fp32_align(
        output reg [22:0] OUT_MANT_A_SINGLE, // new mantissa 
        output reg [22:0] OUT_MANT_B_SINGLE, // new mantissa 
        output reg [7:0] OUT_EXP_SINGLE,
        output reg STICKY_BIT,
        output reg EXCEPTION_ALIGN_SINGLE,

        input wire [7:0] IN_EXP_A_SINGLE,
        input wire [7:0] IN_EXP_B_SINGLE,
        input wire [22:0] IN_MANT_A_SINGLE,
        input wire [22:0] IN_MANT_B_SINGLE
    );

    
    reg [7:0] sub;

    always @ (*) begin

        OUT_MANT_A_SINGLE = IN_MANT_A_SINGLE;
        OUT_MANT_B_SINGLE = IN_MANT_B_SINGLE;
        OUT_EXP_SINGLE = IN_EXP_A_SINGLE;
        EXCEPTION_ALIGN_SINGLE = 0;
        STICKY_BIT = 0;

        // Exception flag sets 1 if either one of the exponents is 31.
        if(( &IN_EXP_A_SINGLE ) | ( &IN_EXP_B_SINGLE )) begin
            EXCEPTION_ALIGN_SINGLE = 1;
            OUT_MANT_A_SINGLE = 0;
            OUT_MANT_B_SINGLE = 0;
            OUT_EXP_SINGLE = 8'd255;
        end
        else if (IN_EXP_A_SINGLE > IN_EXP_B_SINGLE) begin
            sub = IN_EXP_A_SINGLE - IN_EXP_B_SINGLE;
            OUT_EXP_SINGLE = IN_EXP_A_SINGLE;

            if(sum >= 23) begin // if one exp is much bigger than the other
                OUT_MANT_B_SINGLE = 0;
                STICKY_BIT  = |IN_MANT_B_SINGLE;
            end
            else begin
                OUT_MANT_B_SINGLE = IN_MANT_B_SINGLE >> sub;
                STICKY_BIT = |(IN_MANT_B_SINGLE[sub-1:0]);    
            end
        end 
        
        else if (IN_EXP_B_SINGLE > IN_EXP_A_SINGLE) begin
            sub = IN_EXP_A_SINGLE - IN_EXP_B_SINGLE;
            OUT_EXP_SINGLE = IN_EXP_A_SINGLE;

            if(sum >= 23) begin
                OUT_MANT_A_SINGLE = 0;
                STICKY_BIT  = |IN_MANT_A_SINGLE;
            end
            else begin
                OUT_MANT_A_SINGLE = IN_MANT_A_SINGLE >> sub;
                STICKY_BIT = |(IN_MANT_A_SINGLE[sub-1:0]);    
            end
        end
    end

endmodule
