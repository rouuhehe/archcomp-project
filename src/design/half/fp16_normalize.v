module fp16_normalize(
    output reg [11:0] OUT_MANT,
    output reg [4:0] OUT_EXP
    input wire [11:0] IN_MANT,
    input wire [4:0] IN_EXP,
    );

    always @(*) begin
        OUT_MANT = IN_MANT;
        OUT_EXP = IN_EXP;

        // overflow
        if (OUT_MANT[11] && (OUT_EXP < 5'b11111)) begin
            OUT_MANT = OUT_MANT >> 1;
            OUT_EXP  = OUT_EXP + 1;
        end

        // denormal
        else if (!OUT_MANT[10] && (OUT_EXP > 0)) begin
            OUT_MANT = OUT_MANT << 1;
            OUT_EXP  = OUT_EXP - 1;
        end
    end

endmodule