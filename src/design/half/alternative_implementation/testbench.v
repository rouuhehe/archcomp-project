`timescale 1ns/1ns

module my_tb();
  
  reg [15:0] A, B;
  wire [15:0] Q;
  
  strokie_sum test(.Q(Q), .OP_A_HALF(A), .OP_B_HALF(B));
  
  initial begin
    $dumpvars();
    $dumpfile("test.vcd");
    
    A = 16'h028B;
    B = 16'h0373;
    #20;
  end
endmodule
