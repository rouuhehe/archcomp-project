module magnitude16_sum(
    output [4:0] FLAGS, // [4]=, [3]=, [2]=UF, [1]=OF, [0]=INEXACT
    output [15:0] Q, // result

    input wire [4:0] IN_EXP_HALF,
    input wire [9:0] IN_MANT_A_HALF,
    input wire [9:0] IN_MANT_B_HALF
    );
  
  wire is_denorm = (IN_EXP_HALF == 5'b00000);
  
  wire [6:0] extra_mts_a = is_denorm_a ? {1'b0, IN_MANT_A_HALF, 3'b000} : {1'b1, IN_MANT_A_HALF, 3'b000};
  wire [6:0] extra_mts_b = is_denorm_b ? {1'b0, IN_MANT_B_HALF, 3'b000} : {1'b1, IN_MANT_B_HALF, 3'b000};
  
  wire [7:0] sum_mts = IN_MANT_A_HALF + IN_MANT_B_HALF;

  wire [1:0] denormal = sum_mts[7:6];
  
  reg [15:0] normalized;
  reg [4:0] final_exp;
  
  always @(*) begin
    final_exp = (exp_a >= exp_b) ? exp_a : exp_b;
    normalized = sum_mts;
    if (normalized[7] == 0)
      normalized = normalized << 1;
    else
      final_exp = final_exp + 1;
  end

  reg [2:0] M;
  reg G, R, S;
  always @(*) begin
    M = normalized[6:4];
    G = normalized[3];
    R = normalized[2];
    S = |normalized[1:0];
  end

  reg [3:0] rounded_mts, final_exp_out;
  always @(*) begin
    if (G & (R | S | M[0]))
      rounded_mts = M + 1;
    else
      rounded_mts = M;

    final_exp_out = final_exp;

    if (rounded_mts[3] == 1) begin
      rounded_mts = rounded_mts >> 1;
      final_exp_out = final_exp_out + 1;
    end
  end

  // --- FLAGS ---
  always @(*) begin
    flags = 3'b000;  // default
    // Inexact if any guard, round, or sticky bits set
    if (G | R | S)
      flags[0] = 1'b1;
    // Overflow if exponent exceeds maximum normal
    if (final_exp_out > 4'b1110)
      flags[1] = 1'b1;
    // Underflow if result denormal + inexact
    if ((final_exp_out == 4'b0001) && (G | R | S))
      flags[2] = 1'b1;
  end

  assign Q[7] = sign_a;
  assign Q[6:3] = (denormal != 2'b00) ? final_exp_out : 4'b0000;
  assign Q[2:0] = rounded_mts[2:0];
endmodule