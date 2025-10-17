module strokie_sum(
  output [15:0] Q,
  input [15:0] OP_A_HALF, OP_B_HALF
);
  
  wire [15:0] EXC_Q, CORR_Q;
  wire SIGN_A_HALF, SIGN_B_HALF, IS_EXCEPTION;
  wire [4:0] EXP_A_HALF, EXP_B_HALF;
  wire [9:0] MANT_A_HALF, MANT_B_HALF;

  wire [13:0] MANT_A_HALF_EXT, MANT_B_HALF_EXT;
  wire [4:0] EXP_COMMON_HALF;
  wire [14:0] IN_MANT_SUM, OUT_MANT_SUM;

  fp16_decode DEC(
    .OP_A_HALF(OP_A_HALF), .OP_B_HALF(OP_B_HALF),
    .SIGN_A_HALF(SIGN_A_HALF), .SIGN_B_HALF(SIGN_B_HALF),
    .EXP_A_HALF(EXP_A_HALF), .EXP_B_HALF(EXP_B_HALF),
    .MANT_A_HALF(MANT_A_HALF), .MANT_B_HALF(MANT_B_HALF)
  );
  
  fp16_exception EXCEPTION(
    .SIGN_A(SIGN_A_HALF), .SIGN_B(SIGN_B_HALF),
    .IN_EXP_A_HALF(EXP_A_HALF), .IN_EXP_B_HALF(EXP_B_HALF),
    .IN_MANT_A_HALF(MANT_A_HALF), .IN_MANT_B_HALF(MANT_B_HALF),
    .Q(EXC_Q), .IS_EXCEPTION(IS_EXCEPTION)
  );

  fp16_align ALIGN(
    .SIGN_A_HALF(SIGN_A_HALF), .SIGN_B_HALF(SIGN_B_HALF),
    .EXP_A_HALF(EXP_A_HALF), .EXP_B_HALF(EXP_B_HALF),
    .MANT_A_HALF(MANT_A_HALF), .MANT_B_HALF(MANT_B_HALF),
    .OUT_MANT_A_HALF_EXT(MANT_A_HALF_EXT),
    .OUT_MANT_B_HALF_EXT(MANT_B_HALF_EXT),
    .OUT_EXP_HALF(EXP_COMMON_HALF)
  );

  fp16_sum CORE(
    .OUT_MANT_SUM(OUT_MANT_SUM),
    .IN_MANT_A_HALF_EXT(MANT_A_HALF_EXT),
    .IN_MANT_B_HALF_EXT(MANT_B_HALF_EXT)
  );
  
  fp16_normalize NORM(
    .Q(CORR_Q),
    .IN_MANT_SUM(OUT_MANT_SUM),
    .IN_EXP_HALF(EXP_COMMON_HALF),
    .SIGN_HALF(SIGN_A_HALF)
  );
  
  assign Q = (IS_EXCEPTION == 1'b0) ? (CORR_Q) : (EXC_Q);

  always @(*) begin
    $display("\n==== DECODE ====");
    $display("A = %h | sign=%b exp=%b mant=%b", OP_A_HALF, SIGN_A_HALF, EXP_A_HALF, MANT_A_HALF);
    $display("B = %h | sign=%b exp=%b mant=%b", OP_B_HALF, SIGN_B_HALF, EXP_B_HALF, MANT_B_HALF);
    $display("==== ALIGN ====");
    $display("EXP_COMMON = %b (%d)", EXP_COMMON_HALF, EXP_COMMON_HALF);
    $display("MANT_A_EXT = %b", MANT_A_HALF_EXT);
    $display("MANT_B_EXT = %b\n", MANT_B_HALF_EXT);
  end
endmodule
