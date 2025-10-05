`timescale 1ns / 1ps

module fp_normalize(
    output reg [48:0] mant, // normalized mantissa
    output reg [8:0] exp, // adjusted exp
    output reg [4:0] FLAGS,

    input MODE_FP, // 0 = half, 1 = single
    input [48:0] MANT,
    input [8:0] EXP
    );

    wire [8:0] MAX_EXP = (MODE_FP) ? 9'd254 : 9'd30;
    wire [8:0] MIN_EXP = 9'd1;

    reg [48:0] mant_tmp;
    reg [8:0] exp_tmp;

    integer i;
    
    always @ (*) begin 
        mant_tmp = MANT;
        exp_tmp = EXP;

        if(mant_tmp[48] == 1'b1) begin
            mant_tmp = mant_tmp >> 1;
            exp_tmp = exp_tmp + 1;
        end
        else begin 
            normalize_loop: for (i = 0; i < 49; i = i + 1) begin
                if (mant_tmp[47] == 1'b0 && exp_tmp > MIN_EXP) begin
                    mant_tmp = mant_tmp << 1;
                    exp_tmp = exp_tmp - 1;
                end else begin
                    disable normalize_loop;
                end
            end
        end

        // flag handling
        if (exp_tmp > MAX_EXP) FLAGS[4] = 1'b1; // overflow
        else if (exp_tmp < MIN_EXP) FLAGS[3] = 1'b1; // underflow
        if (mant_tmp == 0) FLAGS[2:0] = 3'b000;

        mant = mant_tmp;
        exp  = exp_tmp;
    end
endmodule
