module exception16_sum(
    input [15:0] Q, 
    output reg exc, 
    input wire A, B
    );
  input [7:0] A, B;
  output reg [7:0] Q;
  output reg exc;
  
  wire sign_a = A[7];
  wire sign_b = B[7];
  wire [3:0] exp_a = A[6:3];
  wire [3:0] exp_b = B[6:3];
  wire [2:0] mts_a = A[2:0];
  wire [2:0] mts_b = B[2:0];  
  
  always @(*) begin
    exc = 1'b1;
    // Both NaN
    if ((exp_a == 4'b1111 && mts_a != 3'b000) && (exp_b == 4'b1111 && mts_b != 3'b000)) begin
      Q[7] = sign_a;
      Q[6:3] = 4'b1111;
      Q[2:0] = (mts_a <= mts_b) ? mts_a : mts_b;
    end
    // A is NaN
    else if ((exp_a == 4'b1111 && mts_a != 3'b000)) begin
      Q[7] = sign_a;
      Q[6:3] = exp_a;
      Q[2:0] = mts_a;
    end
    // B is NaN
    else if ((exp_b == 4'b1111 && mts_b != 3'b000)) begin
      Q[7] = sign_b;
      Q[6:3] = exp_b;
      Q[2:0] = mts_b;
    end
    // One is +-inf
    else if ((exp_a == 4'b1111 && mts_a == 3'b000) || (exp_b == 4'b1111 && mts_b == 3'b000)) begin
      Q[7] = (exp_a == 4'b1111) ? sign_a : sign_b;
      Q[6:3] = 4'b1111;
      Q[2:0] = 3'b000;
    end
    // A is zero
    else if (exp_a == 4'b0000 && mts_a == 3'b000) begin
      Q[7] = sign_b;
      Q[6:3] = exp_b;
      Q[2:0] = mts_b;
    end
    // B is zero
    else if (exp_b == 4'b0000 && mts_b == 3'b000) begin
      Q[7] = sign_a;
      Q[6:3] = exp_a;
      Q[2:0] = mts_a;
    end
    else
      exc = 1'b0;
  end
endmodule
