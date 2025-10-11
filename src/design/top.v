`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/10/2025 05:19:50 PM
// Design Name: 
// Module Name: top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`timescale 1ns / 1ns

module Top_Strokie_Half(
    output [7:0] leds
);
    // Hardcodeamos half
    wire [31:0] OP_A = {16'b0, 16'd100};  
    wire [31:0] OP_B = {16'b0, 16'd71}; 

    wire [2:0] OP_CODE = 3'b000; // suma
    wire MODE_FP = 1'b0;         // half
    wire ROUND_MODE = 0;         
    wire START = 1'b1;           
    wire CLK = 1'b0;             
    wire RESET = 1'b0;

    wire [31:0] RESULT;
    wire VALID_OUT;
    wire [4:0] FLAGS;

    strokie uut (
        .RESULT(RESULT),
        .VALID_OUT(VALID_OUT),
        .FLAGS(FLAGS),
        .CLK(CLK),
        .RESET(RESET),
        .OP_A(OP_A),
        .OP_B(OP_B),
        .OP_CODE(OP_CODE),
        .MODE_FP(MODE_FP),
        .ROUND_MODE(ROUND_MODE),
        .START(START)
    );

    assign leds = RESULT[31:24];
endmodule

