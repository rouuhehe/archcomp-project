module strokie_alu(
  output [31:0] Q,
  output ready,
  input [31:0] A,
  input [31:0] B,
  input [1:0] op,
  input mode_fp
);
  wire [15:0] A_16 = A[31:16];
  wire [15:0] B_16 = B[31:16];
  wire [15:0] Q_16;
  wire [31:0] Q_32;
  wire ready_16, ready_32;
  fp16_strokie fp16(.ready(ready_16), .A(A_16), .B(B_16), .result_out(Q_16), .op(op));
  fp32_strokie fp32(.ready(ready_32), .A(A), .B(B), .result_out(Q_32), .op(op));
  assign Q = (mode_fp) ? (Q_32) : ({Q_16, 16'b0});
  assign ready = (mode_fp) ? (ready_32) : (ready_16);
endmodule