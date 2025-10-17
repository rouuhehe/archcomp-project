module fp16_align(
  input SIGN_A_HALF, SIGN_B_HALF,
  input [4:0] EXP_A_HALF, EXP_B_HALF,
  input [9:0] MANT_A_HALF, MANT_B_HALF,
  output reg [13:0] OUT_MANT_A_HALF_EXT,
  output reg [13:0] OUT_MANT_B_HALF_EXT,
  output reg [4:0] OUT_EXP_HALF
);
  reg [4:0] EXP_A_FIXED, EXP_B_FIXED;
  reg [13:0] MANT_A_FULL, MANT_B_FULL;
  reg [4:0] DIFF;

  function automatic calc_sticky;
    input [13:0] VEC;
    input [4:0] SHIFT;
    integer i;
    begin
      calc_sticky = 1'b0;
      if (SHIFT == 0) begin
        calc_sticky = 1'b0;
      end else if (SHIFT >= 14) begin
        calc_sticky = |VEC;
      end else begin
        calc_sticky = 1'b0;
        for (i = 0; i < SHIFT; i = i + 1)
          if (VEC[i]) calc_sticky = 1'b1;
      end
    end
  endfunction

  always @(*) begin
    EXP_A_FIXED = (EXP_A_HALF == 0) ? 5'b00001 : EXP_A_HALF;
    EXP_B_FIXED = (EXP_B_HALF == 0) ? 5'b00001 : EXP_B_HALF;

    MANT_A_FULL = { (EXP_A_HALF == 0 ? 1'b0 : 1'b1), MANT_A_HALF, 3'b000 };
    MANT_B_FULL = { (EXP_B_HALF == 0 ? 1'b0 : 1'b1), MANT_B_HALF, 3'b000 };

    if (EXP_A_FIXED > EXP_B_FIXED) begin
      DIFF = EXP_A_FIXED - EXP_B_FIXED;
      OUT_MANT_A_HALF_EXT = MANT_A_FULL;
      if (DIFF >= 14) begin
        OUT_MANT_B_HALF_EXT = 14'd0;
      end else begin
        OUT_MANT_B_HALF_EXT = MANT_B_FULL >> DIFF;
        OUT_MANT_B_HALF_EXT[0] = OUT_MANT_B_HALF_EXT[0] | calc_sticky(MANT_B_FULL, DIFF);
      end
      OUT_EXP_HALF = EXP_A_FIXED;
    end else begin
      DIFF = EXP_B_FIXED - EXP_A_FIXED;
      OUT_MANT_B_HALF_EXT = MANT_B_FULL;
      if (DIFF >= 14) begin
        OUT_MANT_A_HALF_EXT = 14'd0;
      end else begin
        OUT_MANT_A_HALF_EXT = MANT_A_FULL >> DIFF;
        OUT_MANT_A_HALF_EXT[0] = OUT_MANT_A_HALF_EXT[0] | calc_sticky(MANT_A_FULL, DIFF);
      end
      OUT_EXP_HALF = EXP_B_FIXED;
    end
  end
endmodule
