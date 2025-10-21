module top(
  input  [7:0] SW,         // Input switches for data byte
  input  [1:0] OP,         // the operation
  input        LOAD_A1_BTN,// Load first 8 bits of A
  input        LOAD_A2_BTN,// Load second 8 bits of A
  input        LOAD_B1_BTN,// Load first 8 bits of B
  input        LOAD_B2_BTN,// Load second 8 bits of B
  input        RESET_BTN,
  input        CLK,
  output [15:0] LEDS       // 16 LEDs to show result
);

  wire [15:0] result;

  fp16_loader_and_calc loader_calc (
    .data_in(SW),
    .op(OP),
    .load_a1(LOAD_A1_BTN),
    .load_a2(LOAD_A2_BTN),
    .load_b1(LOAD_B1_BTN),
    .load_b2(LOAD_B2_BTN),
    .clk(CLK),
    .reset(RESET_BTN),
    .result_out(result)
  );

  assign LEDS = result;

endmodule
