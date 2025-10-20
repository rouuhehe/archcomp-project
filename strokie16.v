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
// fp16_exception_sum
// ----------------------------
module fp16_exception(
  output reg [15:0] Q,
  output reg IS_EXCEPTION,
  input wire SIGN_A, SIGN_B,
  input wire [4:0] IN_EXP_A_HALF, IN_EXP_B_HALF,
  input wire [9:0] IN_MANT_A_HALF, IN_MANT_B_HALF,
  input wire [1:0] OP
);
  always @(*) begin
    IS_EXCEPTION = 1'b1;
    Q = 16'b0;
    // both NaN
    if((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0) && 
       (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0)) begin
      Q = { 1'b0, 5'b11111, (IN_MANT_A_HALF <= IN_MANT_B_HALF) ? IN_MANT_A_HALF : IN_MANT_B_HALF };
    end

    // A is NaN
    else if(IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0) begin
      Q = { SIGN_A, IN_EXP_A_HALF, IN_MANT_A_HALF };
    end

    // B is NaN
    else if(IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0) begin
      Q = { SIGN_B, IN_EXP_B_HALF, IN_MANT_B_HALF };
    end

    // both are +-inf
    else if((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0) && 
            (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0) && OP == 2'b00) begin
      Q = { (SIGN_A == SIGN_B) ? SIGN_A : 1'b0, 5'b11111, (SIGN_A == SIGN_B) ? 10'b0 : 10'b1111111111 };
    end
    
    else if((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0) && 
            (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0) && OP == 2'b01) begin
      Q = { (SIGN_A != SIGN_B) ? SIGN_A : 1'b0, 5'b11111, (SIGN_A != SIGN_B) ? 10'b0 : 10'b1111111111 };
    end

    // A is +-inf for sum
    else if(IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0 && OP == 2'b00) begin
      Q = { SIGN_A, IN_EXP_A_HALF, IN_MANT_A_HALF };
    end

    // B is +-inf for sum
    else if(IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0 && OP == 2'b00) begin
      Q = { SIGN_B, IN_EXP_B_HALF, IN_MANT_B_HALF };
    end
    
    // A is +-inf for sub
    else if(IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0 && OP == 2'b01) begin
      Q = { SIGN_A, IN_EXP_A_HALF, IN_MANT_A_HALF };
    end

    // B is +-inf for sub
    else if(IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0 && OP == 2'b01) begin
      Q = { ~SIGN_B, IN_EXP_B_HALF, IN_MANT_B_HALF };
    end

    // A is zero for sum
    else if(IN_EXP_A_HALF == 5'b0 && IN_MANT_A_HALF == 10'b0 && OP == 2'b00) begin
      Q = { SIGN_B, IN_EXP_B_HALF, IN_MANT_B_HALF };
    end

    // A is zero for sub
    else if(IN_EXP_A_HALF == 5'b0 && IN_MANT_A_HALF == 10'b0 && OP == 2'b01) begin
      Q = { ~SIGN_B, IN_EXP_B_HALF, IN_MANT_B_HALF };
    end

    // B is zero
    else if(IN_EXP_B_HALF == 5'b0 && IN_MANT_B_HALF == 10'b0) begin
      Q = { SIGN_A, IN_EXP_A_HALF, IN_MANT_A_HALF };
    end
    else IS_EXCEPTION = 1'b0;
  end
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

  function calc_sticky;
    input [13:0] VEC;
    input [4:0] SHIFT;
    integer i;
    begin
      calc_sticky = 1'b0;
      if (SHIFT == 0) calc_sticky = 1'b0;
      else if (SHIFT >= 14) calc_sticky = |VEC;
      else begin
        calc_sticky = 1'b0;
        for (i=0; i<SHIFT; i=i+1)
          if (VEC[i]) calc_sticky = 1'b1;
      end
    end
  endfunction

  always @(*) begin
    EXP_A_FIXED = (EXP_A_HALF == 0) ? 5'b00001 : EXP_A_HALF;
    EXP_B_FIXED = (EXP_B_HALF == 0) ? 5'b00001 : EXP_B_HALF;
    
    MANT_A_FULL = { (EXP_A_HALF == 0 ? 1'b0 : 1'b1), MANT_A_HALF, 3'b0 };
    MANT_B_FULL = { (EXP_B_HALF == 0 ? 1'b0 : 1'b1), MANT_B_HALF, 3'b0 };

    if (EXP_A_FIXED > EXP_B_FIXED) begin
      DIFF = EXP_A_FIXED - EXP_B_FIXED;
      OUT_MANT_A_HALF_EXT = MANT_A_FULL;
      if (DIFF >= 14) begin
        OUT_MANT_B_HALF_EXT = 14'd0;
        OUT_MANT_B_HALF_EXT[0] = calc_sticky(MANT_B_FULL, DIFF);
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
        OUT_MANT_A_HALF_EXT[0] = calc_sticky(MANT_A_FULL, DIFF);
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
endmodule

// ----------------------------
// fp16_sub
// ----------------------------
module fp16_sub(
  output reg [14:0] OUT_MANT_SUB,
  input [13:0] IN_MANT_A_HALF_EXT,
  input [13:0] IN_MANT_B_HALF_EXT
);
  always @ (*) begin
    if (IN_MANT_A_HALF_EXT > IN_MANT_B_HALF_EXT)
      OUT_MANT_SUB = IN_MANT_A_HALF_EXT - IN_MANT_B_HALF_EXT;
    else if (IN_MANT_A_HALF_EXT < IN_MANT_B_HALF_EXT)
      OUT_MANT_SUB = IN_MANT_B_HALF_EXT - IN_MANT_A_HALF_EXT;
    else OUT_MANT_SUB = 15'b0;
  end
endmodule

// ----------------------------
// fp16_normalize
// ----------------------------
module fp16_normalize(
  output reg [15:0] Q,
  input [14:0] IN_MANT_SUM,
  input [4:0] IN_EXP_HALF,
  input SIGN_HALF
);
  reg [15:0] MANT_EXT;
  reg [4:0] EXP;
  reg G, R, S;
  reg [10:0] MANT_ROUNDED;
  reg ROUND_UP;
  integer i, SHIFT;

  always @(*) begin
    MANT_EXT = {IN_MANT_SUM, 1'b0};
    EXP = IN_EXP_HALF;
    if (MANT_EXT[15]) begin
      MANT_EXT = MANT_EXT >> 1;
      EXP = EXP + 1;
    end else begin
      SHIFT = 0;
      while (MANT_EXT[14] == 0 && MANT_EXT != 0 && SHIFT < 14) begin
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

    if (ROUND_UP) MANT_EXT = MANT_EXT + 16'd8;

    if (MANT_EXT[15]) begin
      MANT_EXT = MANT_EXT >> 1;
      EXP = EXP + 1;
    end

    if (MANT_EXT == 0) Q = 16'b0;
    else if (EXP >= 31) Q = {SIGN_HALF, 5'b11111, 10'b0};
    else Q = {SIGN_HALF, EXP, MANT_EXT[13:4]};
  end
endmodule



// ----------------------------
// fp16_decider
// ----------------------------
module fp16_decider(
  output reg SIGN_HALF,
  output reg [14:0] OUT_MANT,
  input [14:0] OUT_MANT_SUM,
  input [14:0] OUT_MANT_SUB,
  input [1:0] OP,
  input SIGN_A_HALF,
  input SIGN_B_HALF,
  input [13:0] MANT_A_HALF_EXT,
  input [13:0] MANT_B_HALF_EXT
);
  always @(*) begin
    SIGN_HALF = 1'b0;
    OUT_MANT  = 15'b0;
    if (OP == 2'b00) begin
      if (SIGN_A_HALF == SIGN_B_HALF) begin
        OUT_MANT  = OUT_MANT_SUM;
        SIGN_HALF = SIGN_A_HALF;
      end else begin
        OUT_MANT = OUT_MANT_SUB;
        if (MANT_A_HALF_EXT >= MANT_B_HALF_EXT) SIGN_HALF = SIGN_A_HALF;
        else SIGN_HALF = SIGN_B_HALF;
      end
    end else if (OP == 2'b01) begin
      if (SIGN_A_HALF == SIGN_B_HALF) begin
        OUT_MANT = OUT_MANT_SUB;
        if (MANT_A_HALF_EXT >= MANT_B_HALF_EXT) SIGN_HALF = SIGN_A_HALF;
        else SIGN_HALF = ~SIGN_A_HALF;
      end else begin
        OUT_MANT  = OUT_MANT_SUM;
        SIGN_HALF = SIGN_A_HALF;
      end
    end else begin
      OUT_MANT = 15'b0;
      SIGN_HALF = 1'b0;
    end
  end
endmodule

// ----------------------------
// strokie_sum_sub
// ----------------------------
module strokie_sum_sub(
  output [15:0] Q,
  input [15:0] OP_A_HALF, OP_B_HALF,
  input [1:0] OP
);
  wire [15:0] EXC_Q, CORR_Q;
  wire SIGN_A_HALF, SIGN_B_HALF, sign_out, IS_EXCEPTION;
  wire [4:0] EXP_A_HALF, EXP_B_HALF, EXP_COMMON_HALF;
  wire [9:0] MANT_A_HALF, MANT_B_HALF;
  wire [13:0] MANT_A_HALF_EXT, MANT_B_HALF_EXT;
  wire [14:0] OUT_MANT_SUM, OUT_MANT_SUB, decided_mant;

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
    .Q(EXC_Q), .IS_EXCEPTION(IS_EXCEPTION),
    .OP(OP)
  );

  fp16_align ALIGN(
    .SIGN_A_HALF(SIGN_A_HALF), .SIGN_B_HALF(SIGN_B_HALF),
    .EXP_A_HALF(EXP_A_HALF), .EXP_B_HALF(EXP_B_HALF),
    .MANT_A_HALF(MANT_A_HALF), .MANT_B_HALF(MANT_B_HALF),
    .OUT_MANT_A_HALF_EXT(MANT_A_HALF_EXT),
    .OUT_MANT_B_HALF_EXT(MANT_B_HALF_EXT),
    .OUT_EXP_HALF(EXP_COMMON_HALF)
  );

  fp16_sum CORE_SUM(
    .OUT_MANT_SUM(OUT_MANT_SUM),
    .IN_MANT_A_HALF_EXT(MANT_A_HALF_EXT),
    .IN_MANT_B_HALF_EXT(MANT_B_HALF_EXT)
  );

  fp16_sub CORE_SUB(
    .OUT_MANT_SUB(OUT_MANT_SUB),
    .IN_MANT_A_HALF_EXT(MANT_A_HALF_EXT),
    .IN_MANT_B_HALF_EXT(MANT_B_HALF_EXT)
  );

  fp16_decider DECIDER(
    .SIGN_HALF(sign_out),
    .OUT_MANT(decided_mant),
    .OUT_MANT_SUM(OUT_MANT_SUM),
    .OUT_MANT_SUB(OUT_MANT_SUB),
    .OP(OP),
    .SIGN_A_HALF(SIGN_A_HALF),
    .SIGN_B_HALF(SIGN_B_HALF),
    .MANT_A_HALF_EXT(MANT_A_HALF_EXT),
    .MANT_B_HALF_EXT(MANT_B_HALF_EXT)
  );
  
  fp16_normalize NORM(
    .Q(CORR_Q),
    .IN_MANT_SUM(decided_mant),
    .IN_EXP_HALF(EXP_COMMON_HALF),
    .SIGN_HALF(sign_out)
  );

  assign Q = IS_EXCEPTION ? EXC_Q : CORR_Q;

endmodule

// ----------------------------
// fp16_exception_mul
// ----------------------------
module fp16_exception_mul (
  output reg [15:0] Q,
  output reg exc,

  input wire SIGN_A,
  input wire SIGN_B,
  input wire [4:0] IN_EXP_A_HALF,
  input wire [4:0] IN_EXP_B_HALF,
  input wire [9:0] IN_MANT_A_HALF,
  input wire [9:0] IN_MANT_B_HALF
);

  always @(*) begin
    exc = 1'b1;
    Q = 16'b0;

    // both NaN
    if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0) &&
        (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 5'b11111, (IN_MANT_A_HALF <= IN_MANT_B_HALF) ? IN_MANT_A_HALF : IN_MANT_B_HALF };
    end
    
    // A is NaN
    else if (IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0) begin
      Q = { SIGN_A, IN_EXP_A_HALF, IN_MANT_A_HALF };
    end

    // B is NaN
    else if (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0) begin
      Q = { SIGN_B, IN_EXP_B_HALF, IN_MANT_B_HALF };
    end

    // A/B is inf, B/A is 0
    else if (((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0) &&
              (IN_EXP_B_HALF == 5'b00000 && IN_MANT_B_HALF == 10'b0)) ||
             ((IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0) &&
              (IN_EXP_A_HALF == 5'b00000 && IN_MANT_A_HALF == 10'b0))) begin
      Q = 16'h7FFF;
    end

    // A/B is inf
    else if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0) ||
             (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 5'b11111, 10'b0000000000 };
    end

    // A/B is zero
    else if ((IN_EXP_A_HALF == 5'b00000 && IN_MANT_A_HALF == 10'b0) ||
             (IN_EXP_B_HALF == 5'b00000 && IN_MANT_B_HALF == 10'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 5'b00000, 10'b0000000000 };
    end
    
    // A is +-1
    else if(IN_EXP_A_HALF == 5'b01111 && IN_MANT_A_HALF == 10'b0) begin
      Q = { SIGN_A ^ SIGN_B, IN_EXP_B_HALF, IN_MANT_B_HALF };
    end

    // B is +-1
    else if(IN_EXP_B_HALF == 5'b01111 && IN_MANT_B_HALF == 10'b0) begin
      Q = { SIGN_A ^ SIGN_B, IN_EXP_A_HALF, IN_MANT_A_HALF };
    end

    else
      exc = 1'b0;
  end

endmodule

// ----------------------------
// fp16_magnitude_mul
// ----------------------------
module fp16_magnitude_mul(
  output wire [15:0] Q,
  output wire [4:0] flags,
  input wire SIGN_A,
  input wire SIGN_B,
  input wire [4:0] IN_EXP_A_HALF,
  input wire [4:0] IN_EXP_B_HALF,
  input wire [10:0] IN_MANT_A_HALF,
  input wire [10:0] IN_MANT_B_HALF
);
    wire sign_final = SIGN_A ^ SIGN_B;
    wire [21:0] mant_prod = IN_MANT_A_HALF * IN_MANT_B_HALF;
    wire normalized = mant_prod[21];
    wire [21:0] mant_norm = normalized ? mant_prod : mant_prod << 1;
    wire [9:0] mant_rounded = mant_norm[20:11] + (mant_norm[10] & |mant_norm[9:0]);
    wire [5:0] exp_sum = IN_EXP_A_HALF + IN_EXP_B_HALF;
    wire [4:0] exp_calc = exp_sum - 5'd15 + normalized;
    wire of = (exp_sum >= 6'd46);  // 31 + 15 = overflow
    wire uf = (exp_sum < 6'd15);   // < 15 = underflow
    wire [4:0] exp_final = of ? 5'b11111 : (uf ? 5'b00000 : exp_calc);
    wire [9:0] mant_final = (of | uf) ? 10'b0 : mant_rounded;
    assign flags = {2'b00, uf, of, 1'b0};
    assign Q = {sign_final, exp_final, mant_final};
endmodule

// ----------------------------
// fp16_mul
// ----------------------------
module fp16_mul(
    output wire [15:0] Q,
    output wire [4:0] flags,
    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_A_HALF,
    input wire [4:0] IN_EXP_B_HALF,
  	input wire [9:0] IN_MANT_A_HALF,
  	input wire [9:0] IN_MANT_B_HALF
);
   
  wire [15:0] Q_exc, Q_mag;
  wire [4:0] flags_mag;
  wire [10:0] FULL_MANT_A, FULL_MANT_B;
  wire exc;
  
  assign FULL_MANT_A = { (IN_EXP_A_HALF == 0 ? 1'b0 : 1'b1), IN_MANT_A_HALF};
  assign FULL_MANT_B = { (IN_EXP_B_HALF == 0 ? 1'b0 : 1'b1), IN_MANT_B_HALF};

  fp16_exception_mul ex_mod(
    .Q(Q_exc),
    .exc(exc),
    .SIGN_A(SIGN_A),
    .SIGN_B(SIGN_B),
    .IN_EXP_A_HALF(IN_EXP_A_HALF),
    .IN_EXP_B_HALF(IN_EXP_B_HALF),
    .IN_MANT_A_HALF(IN_MANT_A_HALF),
    .IN_MANT_B_HALF(IN_MANT_B_HALF)
  );

  fp16_magnitude_mul mag_mod(
    .Q(Q_mag),  
    .flags(flags_mag),
    .SIGN_A(SIGN_A),
    .SIGN_B(SIGN_B),
    .IN_EXP_A_HALF(IN_EXP_A_HALF),
    .IN_EXP_B_HALF(IN_EXP_B_HALF),
    .IN_MANT_A_HALF(FULL_MANT_A),
    .IN_MANT_B_HALF(FULL_MANT_B)
  );

  assign Q = exc ? Q_exc : Q_mag;
  assign flags = exc ? 5'b00000 : flags_mag;
   
endmodule

// ----------------------------
// strokie_mult
// ----------------------------
module strokie_mult(
  output [15:0] Q,
  input [15:0] OP_A_HALF, OP_B_HALF
);

  wire SIGN_A_HALF, SIGN_B_HALF;
  wire [4:0] EXP_A_HALF, EXP_B_HALF;
  wire [9:0] MANT_A_HALF, MANT_B_HALF;
  wire [4:0] flags;

  fp16_decode DEC(
    .OP_A_HALF(OP_A_HALF), .OP_B_HALF(OP_B_HALF),
    .SIGN_A_HALF(SIGN_A_HALF), .SIGN_B_HALF(SIGN_B_HALF),
    .EXP_A_HALF(EXP_A_HALF), .EXP_B_HALF(EXP_B_HALF),
    .MANT_A_HALF(MANT_A_HALF), .MANT_B_HALF(MANT_B_HALF)
  );
  
  fp16_mul MULT(
    .Q(Q),
    .flags(flags),
    .SIGN_A(SIGN_A_HALF),
    .SIGN_B(SIGN_B_HALF),
    .IN_EXP_A_HALF(EXP_A_HALF),
    .IN_EXP_B_HALF(EXP_B_HALF),
    .IN_MANT_A_HALF(MANT_A_HALF),
    .IN_MANT_B_HALF(MANT_B_HALF)
  );
  
endmodule

// ----------------------------
// fp16_exception_div
// ----------------------------
module fp16_exception_div(
  output reg [15:0] Q,
  output reg IS_EXCEPTION,
  input wire SIGN_A, SIGN_B,
  input wire [4:0] IN_EXP_A_HALF, IN_EXP_B_HALF,
  input wire [9:0] IN_MANT_A_HALF, IN_MANT_B_HALF
);

  reg UF, OF, DIV0, INVALID, INEXACT;
  always @(*) begin
    IS_EXCEPTION = 1'b1;
    Q = 16'b0;

    // both NaN
    if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0) &&
        (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 5'b11111, (IN_MANT_A_HALF < IN_MANT_B_HALF) ? IN_MANT_A_HALF : IN_MANT_B_HALF };
    end
    
    // A is NaN
    if (IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF != 10'b0) begin
      Q = { SIGN_A, IN_EXP_A_HALF, IN_MANT_A_HALF };
    end
    
    // B is NaN
    if (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF != 10'b0) begin
      Q = { SIGN_B, IN_EXP_B_HALF, IN_MANT_B_HALF };
    end

    // both inf
    else if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0) &&
             (IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 15'b111111111111111 };
    end

    // A is inf, B is normal
    else if ((IN_EXP_A_HALF == 5'b11111 && IN_MANT_A_HALF == 10'b0) &&
             (IN_EXP_B_HALF != 5'b11111)) begin
      Q = { SIGN_A ^ SIGN_B, 5'b11111, 10'b0 };
    end

    // A != 0, B is inf
    else if ((IN_EXP_B_HALF == 5'b11111 && IN_MANT_B_HALF == 10'b0) &&
             (IN_EXP_A_HALF != 5'b11111)) begin
      Q = { SIGN_A ^ SIGN_B, 5'b0, 10'b0 };
    end

    // both 0
    else if ((IN_EXP_A_HALF == 5'b0 && IN_MANT_A_HALF == 10'b0) &&
             (IN_EXP_B_HALF == 5'b0 && IN_MANT_B_HALF == 10'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 15'b111111111111111 };
    end

    // A = 0, B != 0
    else if ((IN_EXP_A_HALF == 5'b0 && IN_MANT_A_HALF == 10'b0) &&
             !(IN_EXP_B_HALF == 5'b0 && IN_MANT_B_HALF == 10'b0)) begin
      Q = { SIGN_A ^ SIGN_B, IN_EXP_A_HALF, IN_MANT_A_HALF };
    end

    // A != 0, B is 0
    else if (!(IN_EXP_A_HALF == 5'b0 && IN_MANT_A_HALF == 10'b0) &&
              (IN_EXP_B_HALF == 5'b0 && IN_MANT_B_HALF == 10'b0)) begin
      Q = { SIGN_A ^ SIGN_B, 15'b111111111111111 };
    end

    else
      IS_EXCEPTION = 1'b0;
  end
endmodule

// ----------------------------
// fp16_div
// ----------------------------
module fp16_div(
  output [15:0] Q,
  input SIGN_A_HALF, SIGN_B_HALF,
  input [4:0] EXP_A_HALF, EXP_B_HALF,
  input [9:0] MANT_A_HALF, MANT_B_HALF
);
  wire [10:0] mantA_full = (EXP_A_HALF == 0) ? {1'b0, MANT_A_HALF} : {1'b1, MANT_A_HALF};
  wire [10:0] mantB_full = (EXP_B_HALF == 0) ? {1'b0, MANT_B_HALF} : {1'b1, MANT_B_HALF};

  wire sign_result = SIGN_A_HALF ^ SIGN_B_HALF;
  wire signed [6:0] exp_intermediate =
      $signed({1'b0, EXP_A_HALF}) - $signed({1'b0, EXP_B_HALF}) + 7'd15;

  wire [21:0] dividend = mantA_full << 10;
  wire [21:0] mant_div = dividend / mantB_full;

  wire need_shift = ~mant_div[10];
  wire [21:0] mant_norm = need_shift ? (mant_div << 1) : mant_div;
  wire signed [6:0] exp_norm = exp_intermediate - (need_shift ? 1 : 0);

  wire [9:0] mantissa_final = mant_norm[9:0];

  wire overflow = (exp_norm > 7'd30);
  wire underflow = (exp_norm < 7'd1);
  wire [4:0] exp_final = overflow ? 5'b11110 :
                         underflow ? 5'b00001 :
                         exp_norm[4:0];
  
  assign Q = {sign_result, exp_final, mantissa_final};
  
endmodule

// ----------------------------
// strokie_div
// ----------------------------
module strokie_div(
  output [15:0] Q,
  input [15:0] A, B
);
  
  wire SIGN_A_HALF, SIGN_B_HALF;
  wire [4:0] EXP_A_HALF, EXP_B_HALF;
  wire [9:0] MANT_A_HALF, MANT_B_HALF;
  wire [15:0] Q_exc, Q_corr;
  wire IS_EXCEPTION;
  wire OF, UF, DIV0, INEXACT, INVALID;
  
  fp16_decode DEC (.OP_A_HALF(A), .OP_B_HALF(B),
     .SIGN_A_HALF(SIGN_A_HALF), .SIGN_B_HALF(SIGN_B_HALF),
     .EXP_A_HALF(EXP_A_HALF), .EXP_B_HALF(EXP_B_HALF),
     .MANT_A_HALF(MANT_A_HALF), .MANT_B_HALF(MANT_B_HALF)
  );
  
  fp16_exception_div EXC (.Q(Q_exc),
     .IS_EXCEPTION(IS_EXCEPTION),
     .SIGN_A(SIGN_A_HALF), .SIGN_B(SIGN_B_HALF),
     .IN_EXP_A_HALF(EXP_A_HALF), .IN_EXP_B_HALF(EXP_B_HALF),
     .IN_MANT_A_HALF(MANT_A_HALF), .IN_MANT_B_HALF(MANT_B_HALF)
  );
  
  fp16_div DIV (.Q(Q_corr),
     .SIGN_A_HALF(SIGN_A_HALF), .SIGN_B_HALF(SIGN_B_HALF),
     .EXP_A_HALF(EXP_A_HALF), .EXP_B_HALF(EXP_B_HALF),
     .MANT_A_HALF(MANT_A_HALF), .MANT_B_HALF(MANT_B_HALF)
  );	
  
  assign Q = (IS_EXCEPTION) ? (Q_exc) : (Q_corr);
  
endmodule

// ----------------------------
// fp16_strokie
// ----------------------------
module fp16_strokie(
  input [15:0] A,
  input [15:0] B,
  input [1:0] op,
  output reg [15:0] result_out,
  output ready
);

  reg [15:0] A_reg;
  reg [15:0] B_reg;
  wire [15:0] result_out_1, result_out_2, result_out_3;
  assign ready = 1'b1;
  
  always @ (*) begin
    A_reg = A;
    B_reg = B;
  end

  strokie_sum_sub calc1(
    .Q(result_out_1),
    .OP_A_HALF(A_reg),
    .OP_B_HALF(B_reg),
    .OP(op)
  );
  
  strokie_mult calc2(
    .Q(result_out_2),
    .OP_A_HALF(A_reg),
    .OP_B_HALF(B_reg)
  );
  
  strokie_div calc3(
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