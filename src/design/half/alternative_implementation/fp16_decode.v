module fp16_decode(
  input [15:0] OP_A_HALF, OP_B_HALF,
  output SIGN_A_HALF, SIGN_B_HALF,
  output [4:0] EXP_A_HALF, EXP_B_HALF,
  output [9:0] MANT_A_HALF, MANT_B_HALF
);
  assign SIGN_A_HALF = OP_A_HALF[15];
  assign EXP_A_HALF = OP_A_HALF[14:10];
  assign MANT_A_HALF = OP_A_HALF[9:0];
  assign SIGN_B_HALF = OP_B_HALF[15];
  assign EXP_B_HALF = OP_B_HALF[14:10];
  assign MANT_B_HALF = OP_B_HALF[9:0];
endmodule
