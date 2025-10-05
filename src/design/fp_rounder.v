`timescale 1ns / 1ns

module fp_rounder(
    output reg [7:0] exp,
    output reg [22:0] mant,
    output reg [4:0] FLAGS,
    
    input [8:0] EXP,
    input [48:0] MANT,
    input [4:0] FLAGS_IN,
    input MODE_FP // 0 = half, 1 = single
    );

    reg [23:0] mant_tmp;
    reg G, R, sticky_bit;
    reg [8:0] exp_tmp;

    always @(*) begin
        exp_tmp = EXP;
        FLAGS = FLAGS_IN;

        case (MODE_FP)
            1'b0: begin // half 
                mant_tmp = {1'b0, MANT[48:39]}; // 10 bits + hidden bit + extra for overflow
                G = MANT[38];
                R = MANT[37];
                sticky_bit = |MANT[36:0]; // OR op between all bits in the mantissa

                // Round to nearest even
                if (G && (R || sticky_bit || mant_tmp[0])) begin // formulon
                    mant_tmp = mant_tmp + 1;
                    FLAGS[0] = 1'b1; // INEXACT
                end

                if (mant_tmp[10]) begin // mantissa overflow
                    mant_tmp = mant_tmp >> 1; // normalize
                    exp_tmp = exp_tmp + 1;
                    FLAGS[4] = 1'b1; // OVERFLOW (exp increment)
                end

                if(exp_tmp > 9'd30)
                    FLAGS[4] = 1'b1; // OVERFLOW
                else if(exp_tmp < 9'd1)
                    FLAGS[3] = 1'b1; // UNDERFLOW

                mant = {mant_tmp[9:0], 13'b0};
                exp = {exp_tmp[8:4], 3'b000};
            end

            1'b1: begin
                mant_tmp = {1'b0, MANT[48:26]}; // 23 bits + 1
                G = MANT[25];
                R = MANT[24];
                sticky_bit = |MANT[23:0]; // 1 if there's at least one 1

                if (G && (R || sticky_bit || mant_tmp[0])) begin // formulon
                    mant_tmp = mant_tmp + 1; 
                    FLAGS[0] = 1'b1; // INEXACT
                end

                if (mant_tmp[23]) begin // overflow (mantissa)
                    mant_tmp = mant_tmp >> 1;
                    exp_tmp = exp_tmp + 1;
                    FLAGS[4] = 1'b1; // OVERFLOW (exp increment)
                end

                if(exp_tmp > 9'd254) 
                    FLAGS[4] = 1'b1; // OVERFLOW
                else if(exp_tmp < 9'd1)
                    FLAGS[3] = 1'b1; // UNDERFLOW

                mant = mant_tmp[22:0];
                exp  = exp_tmp[7:0];
            end
        endcase
    end
endmodule
