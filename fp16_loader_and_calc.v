`timescale 1ns/1ns

module fp16_loader_and_calc(
  input [7:0] data_in,
  input load_a1,
  input load_a2,
  input load_b1,
  input load_b2,
  input [1:0] op,
  input clk,
  input reset,
  output [15:0] result_out
);

  reg [15:0] A_reg;
  reg [15:0] B_reg;
  wire [15:0] result_out_1, result_out_2;
  reg [15:0] result_out_temp;

  always @(posedge clk or posedge reset) begin
    if (reset) begin
      A_reg <= 16'b0;
      B_reg <= 16'b0;
    end else begin
      if (load_a1) A_reg[15:8] <= data_in;
      if (load_a2) A_reg[7:0]  <= data_in;
      if (load_b1) B_reg[15:8] <= data_in;
      if (load_b2) B_reg[7:0]  <= data_in;
    end
  end

  strokie_sum_sub calc1(
    .Q(result_out_1),
    .OP_A_HALF(A_reg),
    .OP_B_HALF(B_reg),
    .OP(op)
  );
  
  strokie_mult_div calc2(
    .Q(result_out_2),
    .OP_A_HALF(A_reg),
    .OP_B_HALF(B_reg),
    .OP(op)
  );
  
  always @ (*) begin
    if (op[0] == 0) result_out_temp = result_out_1;
    else result_out_temp = result_out_2;
  end
  
  assign result_out = result_out_temp;

endmodule
