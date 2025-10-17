module fp16_sum(
  output [14:0] OUT_MANT_SUM,
  input [13:0] IN_MANT_A_HALF_EXT,
  input [13:0] IN_MANT_B_HALF_EXT
);
  assign OUT_MANT_SUM = IN_MANT_A_HALF_EXT + IN_MANT_B_HALF_EXT;
  always @ (*) begin
    $display("A_EXT = %b (%d)", IN_MANT_A_HALF_EXT, IN_MANT_A_HALF_EXT);
    $display("B_EXT = %b (%d)", IN_MANT_B_HALF_EXT, IN_MANT_B_HALF_EXT);
    $display("SUM  = %b (%d)", OUT_MANT_SUM, OUT_MANT_SUM);
  end
endmodule
