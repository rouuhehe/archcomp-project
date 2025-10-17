// Code your design here

`timescale 1ns / 1ns

// ----------------------------
// fp16_decode
// ----------------------------
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

// ----------------------------
// fp16_align
// ----------------------------
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

// ----------------------------
// fp16_sum
// ----------------------------
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

// ----------------------------
// fp16_normalize
// ----------------------------
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

// ----------------------------
// strokie_sum (instrumentado)
// ----------------------------
module strokie_sum(
  output [15:0] Q,
  input [15:0] OP_A_HALF, OP_B_HALF
);
  wire SIGN_A_HALF, SIGN_B_HALF;
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
    .Q(Q),
    .IN_MANT_SUM(OUT_MANT_SUM),
    .IN_EXP_HALF(EXP_COMMON_HALF),
    .SIGN_HALF(SIGN_A_HALF)
  );

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
