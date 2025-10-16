module fp16_sum(
    output reg [15:0] Q, 
    output reg [4:0] FLAGS, 
    
    input wire SIGN_A,
    input wire SIGN_B,
    input wire [4:0] IN_EXP_HALF,
    input wire [4:0] IN_EXP_B_HALF,
    input wire [4:0] IN_EXP_A_HALF,
    input wire [9:0] IN_MANT_A_HALF,
    input wire [9:0] IN_MANT_B_HALF,

    input wire [9:0] MANTISSA_DECODE_A,
    input wire [9:0] MANTISSA_DECODE_B
  );

  wire [15:0] Q_exc, Q_mag;
  wire [4:0] flags_mag;
  
  wire exc;

  exception16_sum ex_mod(
    .Q(Q_exc), 
    .exc(exc), 
    .SIGN_A(SIGN_A), 
    .SIGN_B(SIGN_B),
    .IN_EXP_B_HALF(IN_EXP_B_HALF),
    .IN_EXP_A_HALF(IN_EXP_A_HALF),
    .IN_MANT_A_HALF(MANTISSA_DECODE_A),
    .IN_MANT_B_HALF(MANTISSA_DECODE_B)
  );
  
  magnitude16_sum mag_mod(
    .Q(Q_mag), 
    .SIGN_A(SIGN_A),
    .SIGN_B(SIGN_B),
    .IN_EXP_HALF(IN_EXP_HALF),
    .IN_MANT_A_HALF(IN_MANT_A_HALF),
    .IN_MANT_B_HALF(IN_MANT_B_HALF)
   );
  
  assign Q = exc ? Q_exc : Q_mag;
  assign flags = exc ? 5'b00000 : flags_mag;
endmodule
