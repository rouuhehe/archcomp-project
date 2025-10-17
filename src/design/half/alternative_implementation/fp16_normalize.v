module fp16_normalize(
  output [15:0] Q,
  input [14:0] IN_MANT_SUM,
  input [4:0] IN_EXP_HALF,
  input SIGN_HALF
);
  reg [13:0] NORM_MANT;
  reg [4:0] NORM_EXP;

  always @(*) begin
    $display("EXP  = %b (%d)", IN_EXP_HALF, IN_EXP_HALF);
    if (IN_MANT_SUM[14]) begin
      NORM_EXP  = IN_EXP_HALF + 1;
      NORM_MANT = IN_MANT_SUM[14:1];
    end else begin
      NORM_EXP  = IN_EXP_HALF;
      NORM_MANT = IN_MANT_SUM[13:0];
    end
    $display("NORM_MANT = %b", NORM_MANT);
    $display("NORM_EXP  = %b (%d)", NORM_EXP, NORM_EXP);
  end

  reg [4:0] FINAL_EXP;
  reg [9:0] FINAL_MANT;

  always @(*) begin
    FINAL_EXP = NORM_EXP;
    FINAL_MANT = NORM_MANT[12:3];
  end

  assign Q = {SIGN_HALF, FINAL_EXP, FINAL_MANT};

  always @(*) begin
    $display("FINAL_EXP=%b FINAL_MANT=%b", FINAL_EXP, FINAL_MANT);
    $display("Q = %h\n", Q);
  end
endmodule
