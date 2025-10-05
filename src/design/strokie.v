`timescale 1ns / 1ns

module strokie(output reg [31:0] RESULT,
           output reg VALID_OUT,
           //output reg [4:0] FLAGS, 
           input CLK, 
           input RESET, 
           input [31:0] OP_A, 
           input [31:0] OP_B, 
           input [2:0] OP_CODE, 
           input MODE_FP, 
           input ROUND_MODE, 
           input START);
           
    // for OP_A:
    wire sign_a = OP_A[31]; // 1 bit
    wire [7:0] exp_a = OP_A[30:23]; // 8 bits
    wire [23:0] mantissa = {1'b1, OP_A[22:0]}; // 24 bits
     
    // for OP_B:
    wire sign_b = OP_B[31]; // 1 bit
    wire [7:0] exp_b = OP_B[30:23]; // 8 bits
    wire [23:0] mantissa = {1'b1, OP_B[22:0]}; // 24 bits

    always @(posedge CLK) begin
        if(RESET) 
    end
     
     
endmodule
