module fp16_normalize #(
    parameter MB = 11; // mantissa bits
    parameter EB = 5; // exponent bits
    )
    (
    output reg [MB:0] OUT_MANT,
    output reg [EB:0] OUT_EXP
    input wire [MB:0] IN_MANT,
    input wire [EB:0] IN_EXP,
    );

    always @(*) begin
        OUT_MANT = IN_MANT;
        OUT_EXP = IN_EXP;

        // overflow
        if (OUT_MANT[MB] && (OUT_EXP < {EXP_BITS{1'b1}})) begin
            OUT_MANT = OUT_MANT >> 1;
            OUT_EXP  = OUT_EXP + 1;
        end

        // denormal
        else if (!OUT_MANT[MB -1] && (OUT_EXP > 0)) begin
            OUT_MANT = OUT_MANT << 1;
            OUT_EXP  = 0;
        end
    end

endmodule
