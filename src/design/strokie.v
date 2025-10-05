`timescale 1ns / 1ns

module strokie(output reg [31:0] RESULT,
           output reg VALID_OUT,
           output reg [4:0] FLAGS, 
           input CLK, 
           input RESET, 
           input [31:0] OP_A, 
           input [31:0] OP_B, 
           input [2:0] OP_CODE, 
           input MODE_FP, 
           input ROUND_MODE, 
           input START);   
     
endmodule
