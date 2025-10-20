`timescale 1ns / 1ns

// ----------------------------
// fp32_decode
// ----------------------------
module fp32_decode(
  input [31:0] OP_A_SINGLE, OP_B_SINGLE,
  output SIGN_A_SINGLE, SIGN_B_SINGLE,
  output [7:0] EXP_A_SINGLE, EXP_B_SINGLE,
  output [22:0] MANT_A_SINGLE, MANT_B_SINGLE
);
  assign SIGN_A_SINGLE = OP_A_SINGLE[31];
  assign EXP_A_SINGLE = OP_A_SINGLE[30:23];
  assign MANT_A_SINGLE = OP_A_SINGLE[22:0];
  assign SIGN_B_SINGLE = OP_B_SINGLE[31];
  assign EXP_B_SINGLE = OP_B_SINGLE[30:23];
  assign MANT_B_SINGLE = OP_B_SINGLE[22:0];
endmodule

// ----------------------------
// fp32_exception
// ----------------------------
module fp32_exception(
  output reg [31:0] Q,
  output reg IS_EXCEPTION,
  input wire SIGN_A, SIGN_B,
  input wire [7:0] IN_EXP_A, IN_EXP_B,
  input wire [22:0] IN_MANT_A, IN_MANT_B,
  input wire [1:0] OP // 00 = suma, 01 = resta
);
  always @(*) begin
    IS_EXCEPTION = 1'b1;
    Q = 32'b0;
    // both NaN
    if ((IN_EXP_A == 8'b11111111 && IN_MANT_A != 23'b0) &&
        (IN_EXP_B == 8'b11111111 && IN_MANT_B != 23'b0)) begin
      Q = { 1'b0, 8'b11111111, 
            (IN_MANT_A <= IN_MANT_B) ? IN_MANT_A : IN_MANT_B };
    end
    // A is NaN
    else if (IN_EXP_A == 8'b11111111 && IN_MANT_A != 23'b0) begin
      Q = { SIGN_A, IN_EXP_A, IN_MANT_A };
    end
    // B is NaN
    else if (IN_EXP_B == 8'b11111111 && IN_MANT_B != 23'b0) begin
      Q = { SIGN_B, IN_EXP_B, IN_MANT_B };
    end
    // both are +-inf, OP = sum
    else if ((IN_EXP_A == 8'b11111111 && IN_MANT_A == 23'b0) && 
             (IN_EXP_B == 8'b11111111 && IN_MANT_B == 23'b0) && OP == 2'b00) begin
      Q = { (SIGN_A == SIGN_B) ? SIGN_A : 1'b0,
            8'b11111111,
            (SIGN_A == SIGN_B) ? 23'b0 : 23'h7FFFFF };
    end
    // both are +-inf, OP = sub
    else if ((IN_EXP_A == 8'b11111111 && IN_MANT_A == 23'b0) && 
             (IN_EXP_B == 8'b11111111 && IN_MANT_B == 23'b0) && OP == 2'b01) begin
      Q = { (SIGN_A != SIGN_B) ? SIGN_A : 1'b0,
            8'b11111111,
            (SIGN_A != SIGN_B) ? 23'b0 : 23'h7FFFFF };
    end
    // A is +-inf for sum
    else if (IN_EXP_A == 8'b11111111 && IN_MANT_A == 23'b0 && OP == 2'b00) begin
      Q = { SIGN_A, IN_EXP_A, IN_MANT_A };
    end
    // B is +-inf for sum
    else if (IN_EXP_B == 8'b11111111 && IN_MANT_B == 23'b0 && OP == 2'b00) begin
      Q = { SIGN_B, IN_EXP_B, IN_MANT_B };
    end
    // A is +-inf for sub
    else if (IN_EXP_A == 8'b11111111 && IN_MANT_A == 23'b0 && OP == 2'b01) begin
      Q = { SIGN_A, IN_EXP_A, IN_MANT_A };
    end
    // B is +-inf for sub (note: sign inversion)
    else if (IN_EXP_B == 8'b11111111 && IN_MANT_B == 23'b0 && OP == 2'b01) begin
      Q = { ~SIGN_B, IN_EXP_B, IN_MANT_B };
    end
    // A is zero for sum
    else if (IN_EXP_A == 8'b0 && IN_MANT_A == 23'b0 && OP == 2'b00) begin
      Q = { SIGN_B, IN_EXP_B, IN_MANT_B };
    end
    
    // A is zero for sub
    else if (IN_EXP_A == 8'b0 && IN_MANT_A == 23'b0 && OP == 2'b01) begin
      Q = { ~SIGN_B, IN_EXP_B, IN_MANT_B };
    end
    
    // B is zero
    else if (IN_EXP_B == 8'b0 && IN_MANT_B == 23'b0) begin
      Q = { SIGN_A, IN_EXP_A, IN_MANT_A };
    end
    else IS_EXCEPTION = 1'b0;
  end
endmodule

// ----------------------------
// fp32_align
// ----------------------------
module fp32_align(
  input SIGN_A, SIGN_B,
  input [7:0] EXP_A, EXP_B,
  input [22:0] MANT_A, MANT_B,
  output reg [26:0] OUT_MANT_A_EXT,
  output reg [26:0] OUT_MANT_B_EXT,
  output reg [7:0] OUT_EXP
);
  reg [7:0] EXP_A_FIXED, EXP_B_FIXED;
  reg [26:0] MANT_A_FULL, MANT_B_FULL;
  reg [7:0] DIFF;

  function calc_sticky;
    input [26:0] VEC;
    input [7:0] SHIFT;
    integer i;
    begin
      calc_sticky = 1'b0;
      if (SHIFT == 0) calc_sticky = 1'b0;
      else if (SHIFT >= 27) calc_sticky = |VEC;
      else begin
        calc_sticky = 1'b0;
        for (i = 0; i < SHIFT; i = i + 1)
          if (VEC[i]) calc_sticky = 1'b1;
      end
    end
  endfunction

  always @(*) begin
    EXP_A_FIXED = (EXP_A == 0) ? 8'b00000001 : EXP_A;
    EXP_B_FIXED = (EXP_B == 0) ? 8'b00000001 : EXP_B;
    
    MANT_A_FULL = { (EXP_A == 0 ? 1'b0 : 1'b1), MANT_A, 3'b000 };
    MANT_B_FULL = { (EXP_B == 0 ? 1'b0 : 1'b1), MANT_B, 3'b000 };

    if (EXP_A_FIXED > EXP_B_FIXED) begin
      DIFF = EXP_A_FIXED - EXP_B_FIXED;
      OUT_MANT_A_EXT = MANT_A_FULL;
      if (DIFF >= 27) begin
        OUT_MANT_B_EXT = 27'd0;
        OUT_MANT_B_EXT[0] = calc_sticky(MANT_B_FULL, DIFF);
      end else begin
        OUT_MANT_B_EXT = MANT_B_FULL >> DIFF;
        OUT_MANT_B_EXT[0] = OUT_MANT_B_EXT[0] | calc_sticky(MANT_B_FULL, DIFF);
      end
      OUT_EXP = EXP_A_FIXED;
    end else begin
      DIFF = EXP_B_FIXED - EXP_A_FIXED;
      OUT_MANT_B_EXT = MANT_B_FULL;
      if (DIFF >= 27) begin
        OUT_MANT_A_EXT = 27'd0;
        OUT_MANT_A_EXT[0] = calc_sticky(MANT_A_FULL, DIFF);
      end else begin
        OUT_MANT_A_EXT = MANT_A_FULL >> DIFF;
        OUT_MANT_A_EXT[0] = OUT_MANT_A_EXT[0] | calc_sticky(MANT_A_FULL, DIFF);
      end
      OUT_EXP = EXP_B_FIXED;
    end
  end
endmodule

// ----------------------------
// fp32_sum
// ----------------------------
module fp32_sum(
  output [27:0] OUT_MANT_SUM,
  input [26:0] IN_MANT_A_EXT,
  input [26:0] IN_MANT_B_EXT
);
  assign OUT_MANT_SUM = IN_MANT_A_EXT + IN_MANT_B_EXT;
endmodule

// ----------------------------
// fp32_sub
// ----------------------------
module fp32_sub(
  output reg [27:0] OUT_MANT_SUB,
  input [26:0] IN_MANT_A_HALF_EXT,
  input [26:0] IN_MANT_B_HALF_EXT
);
  always @ (*) begin
    if (IN_MANT_A_HALF_EXT > IN_MANT_B_HALF_EXT)
      OUT_MANT_SUB = IN_MANT_A_HALF_EXT - IN_MANT_B_HALF_EXT;
    else if (IN_MANT_A_HALF_EXT < IN_MANT_B_HALF_EXT)
      OUT_MANT_SUB = IN_MANT_B_HALF_EXT - IN_MANT_A_HALF_EXT;
    else OUT_MANT_SUB = 28'b0;
  end
endmodule
// ----------------------------
// fp32_normalize
// ----------------------------
module fp32_normalize(
  output reg [31:0] Q,
  input [27:0] IN_MANT_SUM,
  input [7:0] IN_EXP,
  input SIGN
);
  reg [27:0] MANT_EXT;
  reg [7:0] EXP;
  reg G, R, S;
  reg [22:0] MANT_ROUNDED;
  reg ROUND_UP;
  integer i, SHIFT;

  always @(*) begin
    MANT_EXT = IN_MANT_SUM;
    EXP = IN_EXP;

    if (MANT_EXT[27]) begin
      MANT_EXT = MANT_EXT >> 1;
      EXP = EXP + 1;
    end 
    else begin
      SHIFT = 0;
      while (MANT_EXT[26] == 0 && MANT_EXT != 0 && SHIFT < 27) begin
        MANT_EXT = MANT_EXT << 1;
        SHIFT = SHIFT + 1;
      end
      if (SHIFT > 0) begin
        if (EXP > SHIFT) EXP = EXP - SHIFT;
        else EXP = 0;
      end
    end

    G = MANT_EXT[2];
    R = MANT_EXT[1];
    S = MANT_EXT[0];
    ROUND_UP = (G && (R || S || MANT_EXT[3]));

    if (ROUND_UP) MANT_EXT = MANT_EXT + 28'd8;

    if (MANT_EXT[27]) begin
      MANT_EXT = MANT_EXT >> 1;
      EXP = EXP + 1;
    end

    if (MANT_EXT == 0) Q = 32'b0;
    else if (EXP >= 255) Q = {SIGN, 8'b11111111, 23'b0}; // +Inf
    else Q = {SIGN, EXP, MANT_EXT[25:3]};
  end
endmodule
// ----------------------------
// fp32_decider
// ----------------------------
module fp32_decider(
  output reg SIGN,
  output reg [27:0] OUT_MANT,
  input [27:0] OUT_MANT_SUM,
  input [27:0] OUT_MANT_SUB,
  input [1:0] OP,
  input SIGN_A,
  input SIGN_B,
  input [26:0] MANT_A_EXT,
  input [26:0] MANT_B_EXT
);
  always @(*) begin
    SIGN = 1'b0;
    OUT_MANT = 28'b0;

    if (OP == 2'b00) begin // sum
      if (SIGN_A == SIGN_B) begin
        OUT_MANT = OUT_MANT_SUM;
        SIGN = SIGN_A;
      end else begin
        OUT_MANT = OUT_MANT_SUB;
        if (MANT_A_EXT >= MANT_B_EXT) SIGN = SIGN_A;
        else SIGN = SIGN_B;
      end
    end 
    else if (OP == 2'b01) begin // sub
      if (SIGN_A == SIGN_B) begin
        OUT_MANT = OUT_MANT_SUB;
        if (MANT_A_EXT >= MANT_B_EXT) SIGN = SIGN_A;
        else SIGN = ~SIGN_A;
      end else begin
        OUT_MANT = OUT_MANT_SUM;
        SIGN = SIGN_A;
      end
    end 
    else begin
      OUT_MANT = 28'b0;
      SIGN = 1'b0;
    end
  end
endmodule

// ----------------------------
// strokie32_sum_sub
// ----------------------------
module strokie32_sum_sub(
  output [31:0] Q,
  input [31:0] OP_A, OP_B,
  input [1:0] OP 
);
  wire [31:0] EXC_Q, CORR_Q;
  wire SIGN_A, SIGN_B, sign_out, IS_EXCEPTION;
  wire [7:0] EXP_A, EXP_B, EXP_COMMON;
  wire [22:0] MANT_A, MANT_B;
  wire [26:0] MANT_A_EXT, MANT_B_EXT;
  wire [27:0] OUT_MANT_SUM, OUT_MANT_SUB, decided_mant;

  fp32_decode DEC(
    .OP_A_SINGLE(OP_A), .OP_B_SINGLE(OP_B),
    .SIGN_A_SINGLE(SIGN_A), .SIGN_B_SINGLE(SIGN_B),
    .EXP_A_SINGLE(EXP_A), .EXP_B_SINGLE(EXP_B),
    .MANT_A_SINGLE(MANT_A), .MANT_B_SINGLE(MANT_B)
  );

  fp32_exception EXCEPTION(
    .SIGN_A(SIGN_A), .SIGN_B(SIGN_B),
    .IN_EXP_A(EXP_A), .IN_EXP_B(EXP_B),
    .IN_MANT_A(MANT_A), .IN_MANT_B(MANT_B),
    .Q(EXC_Q), .IS_EXCEPTION(IS_EXCEPTION),
    .OP(OP)
  );

  fp32_align ALIGN(
    .SIGN_A(SIGN_A), .SIGN_B(SIGN_B),
    .EXP_A(EXP_A), .EXP_B(EXP_B),
    .MANT_A(MANT_A), .MANT_B(MANT_B),
    .OUT_MANT_A_EXT(MANT_A_EXT),
    .OUT_MANT_B_EXT(MANT_B_EXT),
    .OUT_EXP(EXP_COMMON)
  );

  fp32_sum CORE_SUM(
    .OUT_MANT_SUM(OUT_MANT_SUM),
    .IN_MANT_A_EXT(MANT_A_EXT),
    .IN_MANT_B_EXT(MANT_B_EXT)
  );

  fp32_sub CORE_SUB(
    .OUT_MANT_SUB(OUT_MANT_SUB),
    .IN_MANT_A_HALF_EXT(MANT_A_EXT),
    .IN_MANT_B_HALF_EXT(MANT_B_EXT)
  );

  fp32_decider DECIDER(
    .SIGN(sign_out),
    .OUT_MANT(decided_mant),
    .OUT_MANT_SUM(OUT_MANT_SUM),
    .OUT_MANT_SUB(OUT_MANT_SUB),
    .OP(OP),
    .SIGN_A(SIGN_A),
    .SIGN_B(SIGN_B),
    .MANT_A_EXT(MANT_A_EXT),
    .MANT_B_EXT(MANT_B_EXT)
  );
  
  fp32_normalize NORM(
    .Q(CORR_Q),
    .IN_MANT_SUM(decided_mant),
    .IN_EXP(EXP_COMMON),
    .SIGN(sign_out)
  );

  assign Q = IS_EXCEPTION ? EXC_Q : CORR_Q;

endmodule

// ----------------------------
// fp32_exception_mul
// ----------------------------
module fp32_exception_mul (
  output reg [31:0] Q,
  output reg exc,

  input wire SIGN_A,
  input wire SIGN_B,
  input wire [7:0] IN_EXP_A,
  input wire [7:0] IN_EXP_B,
  input wire [22:0] IN_MANT_A,
  input wire [22:0] IN_MANT_B
);

  always @(*) begin
    exc = 1'b1;
    Q = 32'b0;
    // both NaN
    if ((IN_EXP_A == 8'b11111111 && IN_MANT_A != 23'b0) &&
        (IN_EXP_B == 8'b11111111 && IN_MANT_B != 23'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 8'b11111111, 
            (IN_MANT_A <= IN_MANT_B) ? IN_MANT_A : IN_MANT_B };
    end
    // A is NaN
    else if (IN_EXP_A == 8'b11111111 && IN_MANT_A != 23'b0) begin
      Q = { SIGN_A, IN_EXP_A, IN_MANT_A };
    end
    // B is NaN
    else if (IN_EXP_B == 8'b11111111 && IN_MANT_B != 23'b0) begin
      Q = { SIGN_B, IN_EXP_B, IN_MANT_B };
    end
    // A/B is inf, B/A is 0
    else if (((IN_EXP_A == 8'b11111111 && IN_MANT_A == 23'b0) &&
              (IN_EXP_B == 8'b0 && IN_MANT_B == 23'b0)) ||
             ((IN_EXP_B == 8'b11111111 && IN_MANT_B == 23'b0) &&
              (IN_EXP_A == 8'b0 && IN_MANT_A == 23'b0))) begin
      Q = 32'h7FFFFFFF;
    end
    // A/B is inf
    else if ((IN_EXP_A == 8'b11111111 && IN_MANT_A == 23'b0) ||
             (IN_EXP_B == 8'b11111111 && IN_MANT_B == 23'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 8'b11111111, 23'b0 };
    end
    // A/B is zero
    else if ((IN_EXP_A == 8'b0 && IN_MANT_A == 23'b0) ||
             (IN_EXP_B == 8'b0 && IN_MANT_B == 23'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 8'b0, 23'b0 };
    end
    // A is +-1
    else if(IN_EXP_A == 8'b01111111 && IN_MANT_A == 23'b0) begin
      Q = { SIGN_A ^ SIGN_B, IN_EXP_B, IN_MANT_B };
    end
    // B is +-1
    else if(IN_EXP_B == 8'b01111111 && IN_MANT_B == 23'b0) begin
      Q = { SIGN_A ^ SIGN_B, IN_EXP_A, IN_MANT_A };
    end
    else
      exc = 1'b0;
  end
endmodule

// ----------------------------
// fp32_magnitude_mul
// ----------------------------
module fp32_magnitude_mul(
  output wire [31:0] Q,
  output wire [4:0] flags,
  input wire SIGN_A,
  input wire SIGN_B,
  input wire [7:0] IN_EXP_A,
  input wire [7:0] IN_EXP_B,
  input wire [23:0] IN_MANT_A,
  input wire [23:0] IN_MANT_B
);
    wire sign_final = SIGN_A ^ SIGN_B;
    wire [47:0] mant_prod = IN_MANT_A * IN_MANT_B;
    wire normalized = mant_prod[47];
    wire [22:0] mant_truncated;
    wire guard, round, sticky;
    
    assign mant_truncated = normalized ? mant_prod[46:24] : mant_prod[45:23];
    assign guard = normalized ? mant_prod[23] : mant_prod[22];
    assign round = normalized ? mant_prod[22] : mant_prod[21];
    assign sticky = normalized ? |mant_prod[21:0] : |mant_prod[20:0];
    wire round_up = guard & (round | sticky | mant_truncated[0]);
    wire [23:0] mant_rounded_temp = {1'b0, mant_truncated} + round_up;
    wire round_overflow = mant_rounded_temp[23];
    wire [22:0] mant_rounded = round_overflow ? mant_rounded_temp[23:1] : mant_rounded_temp[22:0];
    wire [9:0] exp_sum = {1'b0, IN_EXP_A} + {1'b0, IN_EXP_B};
    wire [9:0] exp_adjusted = exp_sum - 10'd127;
    wire [9:0] exp_normalized = exp_adjusted + (normalized ? 10'd1 : 10'd0);
    wire [9:0] exp_final_calc = exp_normalized + (round_overflow ? 10'd1 : 10'd0);
    
    wire of = (exp_final_calc >= 10'd255);
    wire uf = exp_final_calc[9] | (exp_final_calc == 10'd0);
    
    wire [7:0] exp_final = of ? 8'hFF : (uf ? 8'h00 : exp_final_calc[7:0]);
    wire [22:0] mant_final = (of | uf) ? 23'h0 : mant_rounded;
    
    assign flags = {2'b00, uf, of, 1'b0};
    assign Q = {sign_final, exp_final, mant_final};
endmodule
// ----------------------------
// fp32_mul
// ----------------------------
module fp32_mul(
    output wire [31:0] Q,
    output wire [4:0] flags,
    input wire SIGN_A,
    input wire SIGN_B,
    input wire [7:0] IN_EXP_A,
    input wire [7:0] IN_EXP_B,
    input wire [22:0] IN_MANT_A,
    input wire [22:0] IN_MANT_B
);
  wire [31:0] Q_exc, Q_mag;
  wire [4:0] flags_mag;
  wire [23:0] FULL_MANT_A, FULL_MANT_B;
  wire exc;
  
  // Construir mantisas completas con bit implícito
  assign FULL_MANT_A = {(IN_EXP_A == 8'h00) ? 1'b0 : 1'b1, IN_MANT_A};
  assign FULL_MANT_B = {(IN_EXP_B == 8'h00) ? 1'b0 : 1'b1, IN_MANT_B};
  
  fp32_exception_mul ex_mod(
    .Q(Q_exc),
    .exc(exc),
    .SIGN_A(SIGN_A),
    .SIGN_B(SIGN_B),
    .IN_EXP_A(IN_EXP_A),
    .IN_EXP_B(IN_EXP_B),
    .IN_MANT_A(IN_MANT_A),
    .IN_MANT_B(IN_MANT_B)
  );
  
  fp32_magnitude_mul mag_mod(
    .Q(Q_mag),  
    .flags(flags_mag),
    .SIGN_A(SIGN_A),
    .SIGN_B(SIGN_B),
    .IN_EXP_A(IN_EXP_A),
    .IN_EXP_B(IN_EXP_B),
    .IN_MANT_A(FULL_MANT_A),
    .IN_MANT_B(FULL_MANT_B)
  );
  
  assign Q = exc ? Q_exc : Q_mag;
  assign flags = exc ? 5'b00000 : flags_mag;
endmodule

// ----------------------------
// strokie32_mult
// ----------------------------
module strokie32_mult(
  output [31:0] Q,
  input [31:0] OP_A,
  input [31:0] OP_B
);
  wire SIGN_A, SIGN_B;
  wire [7:0] EXP_A, EXP_B;
  wire [22:0] MANT_A, MANT_B;
  wire [4:0] flags;
  fp32_decode DEC(
    .OP_A_SINGLE(OP_A), .OP_B_SINGLE(OP_B),
    .SIGN_A_SINGLE(SIGN_A), .SIGN_B_SINGLE(SIGN_B),
    .EXP_A_SINGLE(EXP_A), .EXP_B_SINGLE(EXP_B),
    .MANT_A_SINGLE(MANT_A), .MANT_B_SINGLE(MANT_B)
  );
  fp32_mul MULT(
    .Q(Q),
    .flags(flags),
    .SIGN_A(SIGN_A),
    .SIGN_B(SIGN_B),
    .IN_EXP_A(EXP_A),
    .IN_EXP_B(EXP_B),
    .IN_MANT_A(MANT_A),
    .IN_MANT_B(MANT_B)
  );
endmodule

// ----------------------------
// fp32_exception_div
// ----------------------------
module fp32_exception_div(
  output reg [31:0] Q,
  output reg IS_EXCEPTION,
  input wire SIGN_A, SIGN_B,
  input wire [7:0] IN_EXP_A, IN_EXP_B,
  input wire [22:0] IN_MANT_A, IN_MANT_B
);
  always @(*) begin
    IS_EXCEPTION = 1'b1;
    Q = 32'b0;
    // both NaN
    if ((IN_EXP_A == 8'b11111111 && IN_MANT_A != 23'b0) &&
        (IN_EXP_B == 8'b11111111 && IN_MANT_B != 23'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 8'b11111111, (IN_MANT_A < IN_MANT_B) ? IN_MANT_A : IN_MANT_B };
    end
    // A is NaN
    if (IN_EXP_A == 8'b11111111 && IN_MANT_A != 23'b0) begin
      Q = { SIGN_A, IN_EXP_A, IN_MANT_A };
    end
    // B is NaN
    if (IN_EXP_B == 8'b11111111 && IN_MANT_B != 23'b0) begin
      Q = { SIGN_B, IN_EXP_B, IN_MANT_B };
    end
    // both inf
    else if ((IN_EXP_A == 8'b11111111 && IN_MANT_A == 23'b0) &&
             (IN_EXP_B == 8'b11111111 && IN_MANT_B == 23'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 31'b1111111111111111111111111111111 };
    end
    // A is inf, B is normal
    else if ((IN_EXP_A == 8'b11111111 && IN_MANT_A == 23'b0) &&
             (IN_EXP_B != 8'b11111111)) begin
      Q = { SIGN_A ^ SIGN_B, 8'b11111111, 23'b0 };
    end
    // A != 0, B is inf
    else if ((IN_EXP_B == 8'b11111111 && IN_MANT_B == 23'b0) &&
             (IN_EXP_A != 8'b11111111)) begin
      Q = { SIGN_A ^ SIGN_B, 8'b0, 23'b0 };
    end
    // both 0
    else if ((IN_EXP_A == 8'b0 && IN_MANT_A == 23'b0) &&
             (IN_EXP_B == 8'b0 && IN_MANT_B == 23'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 31'b1111111111111111111111111111111 };
    end
    // A = 0, B != 0
    else if ((IN_EXP_A == 8'b0 && IN_MANT_A == 23'b0) &&
             !(IN_EXP_B == 8'b0 && IN_MANT_B == 23'b0)) begin
      Q = { SIGN_A ^ SIGN_B, IN_EXP_A, IN_MANT_A };
    end
    // A != 0, B is 0
    else if (!(IN_EXP_A == 8'b0 && IN_MANT_A == 23'b0) &&
              (IN_EXP_B == 8'b0 && IN_MANT_B == 23'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 31'b1111111111111111111111111111111 };
    end
    else
      IS_EXCEPTION = 1'b0;
  end
endmodule

// ----------------------------
// fp32_div
// ----------------------------
module fp32_div(
  output [31:0] Q,
  input SIGN_A, SIGN_B,
  input [7:0] EXP_A, EXP_B,
  input [22:0] MANT_A, MANT_B
);
  wire [23:0] mantA_full = (EXP_A == 0) ? {1'b0, MANT_A} : {1'b1, MANT_A};
  wire [23:0] mantB_full = (EXP_B == 0) ? {1'b0, MANT_B} : {1'b1, MANT_B};

  wire sign_result = SIGN_A ^ SIGN_B;
  wire signed [8:0] exp_intermediate =
      $signed({1'b0, EXP_A}) - $signed({1'b0, EXP_B}) + 9'd127;

  wire [46:0] dividend = mantA_full << 23; 
  wire [23:0] mant_div = dividend / mantB_full;

  wire need_shift = ~mant_div[23];
  wire [23:0] mant_norm = need_shift ? (mant_div << 1) : mant_div;
  wire signed [8:0] exp_norm = exp_intermediate - (need_shift ? 1 : 0);

  wire overflow = (exp_norm > 8'd254);
  wire underflow = (exp_norm < 8'd1);
  wire [7:0] exp_final = overflow ? 8'b11111111 :
                         underflow ? 8'b00000000 :
                         exp_norm[7:0];
  assign Q = {sign_result, exp_final, mant_norm[22:0]};
endmodule

// ----------------------------
// strokie32_div
// ----------------------------
module strokie32_div(
  output [31:0] Q,
  input [31:0] A, B
);
  wire SIGN_A, SIGN_B;
  wire [7:0] EXP_A, EXP_B;
  wire [22:0] MANT_A, MANT_B;
  wire [31:0] Q_exc, Q_corr;
  wire IS_EXCEPTION;
  fp32_decode DEC (
    .OP_A_SINGLE(A), .OP_B_SINGLE(B),
    .SIGN_A_SINGLE(SIGN_A), .SIGN_B_SINGLE(SIGN_B),
    .EXP_A_SINGLE(EXP_A), .EXP_B_SINGLE(EXP_B),
    .MANT_A_SINGLE(MANT_A), .MANT_B_SINGLE(MANT_B)
  );
  fp32_exception_div EXC (
    .Q(Q_exc),
    .IS_EXCEPTION(IS_EXCEPTION),
    .SIGN_A(SIGN_A), .SIGN_B(SIGN_B),
    .IN_EXP_A(EXP_A), .IN_EXP_B(EXP_B),
    .IN_MANT_A(MANT_A), .IN_MANT_B(MANT_B)
  );
  fp32_div DIV (
    .Q(Q_corr),
    .SIGN_A(SIGN_A), .SIGN_B(SIGN_B),
    .EXP_A(EXP_A), .EXP_B(EXP_B),
    .MANT_A(MANT_A), .MANT_B(MANT_B)
  );	
  assign Q = (IS_EXCEPTION) ? Q_exc : Q_corr;
endmodule

// ----------------------------
// fp32_strokie
// ----------------------------
module fp32_strokie(
  input [31:0] A,
  input [31:0] B,
  input [1:0] op,
  output reg [31:0] result_out,
  output ready
);

  reg [31:0] A_reg;
  reg [31:0] B_reg;
  wire [31:0] result_out_1, result_out_2, result_out_3;
  assign ready = 1'b1;
  
  always @ (*) begin
    A_reg = A;
    B_reg = B;
  end

  strokie32_sum_sub calc1(
    .Q(result_out_1),
    .OP_A(A_reg),
    .OP_B(B_reg),
    .OP(op)
  );
  
  strokie32_mult calc2(
    .Q(result_out_2),
    .OP_A(A_reg),
    .OP_B(B_reg)
  );
  
  strokie32_div calc3(
    .Q(result_out_3),
    .A(A_reg),
    .B(B_reg)
  );

  always @ (*) begin
    casez (op)
      2'b00, 2'b01: result_out = result_out_1;
      2'b10: result_out = result_out_2;  
      2'b11: result_out = result_out_3;  
    endcase
  end
  
endmodule
