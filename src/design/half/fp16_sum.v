module fp16_sum(Q, flags, A, B);
  input [7:0] A, B;
  output [7:0] Q;
  output [2:0] flags;  // {UF, OF, INEXACT}

  wire [7:0] Q_exc, Q_mag;
  wire [2:0] flags_mag;
  wire exc;

  8_bit_exception_sum ex_mod(Q_exc, exc, A, B);
  8_bit_magnitude_sum mag_mod(Q_mag, flags_mag, A, B);
  
  assign Q = exc ? Q_exc : Q_mag;
  assign flags = exc ? 3'b000 : flags_mag;
endmodule
