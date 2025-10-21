`timescale 1ns / 1ns

module tb_fp16_normal();

  reg [31:0] A, B;
  reg [1:0] op;
  reg mode_fp;
  wire [31:0] Q;
  wire ready;

  strokie_alu uut (.Q(Q), .ready(ready), .A(A), .B(B), .op(op), .mode_fp(mode_fp)
  );

  initial begin
    op = 2'b00;
    mode_fp = 1'b0;

    A = 32'h3C000000; B = 32'h3C000000; #20; // 1 y 1
    A = 32'h40000000; B = 32'hC0000000; #20; // 2 y (-2)
    A = 32'h42480000; B = 32'h416F0000; #20; // pi y e
    A = 32'h02000000; B = 32'h3C000000; #20; // subnormal y 1
    A = 32'h02000000; B = 32'h02000000; #20; // subnormal y subnormal
    A = 32'h2E660000; B = 32'h32660000; #20; // 0.1 y 0.2
    A = 32'h2E660000; B = 32'hB2660000; #20; // 0.1 y (-0.2)
    A = 32'h7BFE0000; B = 32'h7BFF0000; #20; // second y first

    #20;
    $finish;
  end

endmodule

module tb_fp16_normal();

  reg [31:0] A, B;
  reg [1:0] op;
  reg mode_fp;
  wire [31:0] Q;
  wire ready;

  strokie_alu uut (.Q(Q), .ready(ready), .A(A), .B(B), .op(op), .mode_fp(mode_fp)
  );

  initial begin
    op = 2'b00;
    mode_fp = 1'b1;

    A = 32'h3F800000; B = 32'h3F800000; #20; // 1 - 1
    A = 32'h40000000; B = 32'hC0000000; #20; // 2 - (-2)
    A = 32'h40490FD8; B = 32'h402DF854; #20; // pi - e
    A = 32'h00400000; B = 32'h3F800000; #20; // subnormal - 1
    A = 32'h00400000; B = 32'h00400000; #20; // subnormal - subnormal
    A = 32'h3DCCCCCD; B = 32'h3E4CCCCD; #20; // 0.1 - 0.2
    A = 32'h3DCCCCCD; B = 32'hBE4CCCCD; #20; // 0.1 - (-0.2)
    A = 32'hFF7FFFFE; B = 32'hFF7FFFFF; #20; // second - first

    #20;
    $finish;
  end

endmodule


module tb_fp16_exc();

  reg [31:0] A, B;
  reg [1:0] op;
  reg mode_fp;
  wire [31:0] Q;
  wire ready;

  strokie_alu uut (.Q(Q), .ready(ready), .A(A), .B(B), .op(op), .mode_fp(mode_fp)
  );

  initial begin
    op = 2'b00;
    mode_fp = 1'b0;

    A = 32'h00000000; B = 32'h00000000; #20; // 0 y 0
    A = 32'h00000000; B = 32'h3C000000; #20; // 0 y 1
    A = 32'h3C000000; B = 32'h00000000; #20; // 1 y 0
    A = 32'h7C000000; B = 32'h00000000; #20; // inf y 0
    A = 32'h00000000; B = 32'hFC000000; #20; // 0 y -inf
    A = 32'h7C000000; B = 32'hFC000000; #20; // inf y -inf
    A = 32'h7C000000; B = 32'h7C000000; #20; // inf y inf
    A = 32'h1A3B0000; B = 32'h7C000000; #20; // n y inf
    A = 32'h7E000000; B = 32'h40000000; #20; // nan y 16
    A = 32'h7C000000; B = 32'h7E000000; #20; // inf y nan
    A = 32'h7E000000; B = 32'h7FFF000; #20; // nan y NAN

    #20;
    $finish;
  end

endmodule


module tb_fp32_exc();

  reg [31:0] A, B;
  reg [1:0] op;
  reg mode_fp;
  wire [31:0] Q;
  wire ready;

  strokie_alu uut (.Q(Q), .ready(ready), .A(A), .B(B), .op(op), .mode_fp(mode_fp)
  );

  initial begin
    op = 2'b00;
    mode_fp = 1'b1;

    A = 32'h00000000; B = 32'h00000000; #20; // 0 y 0
    A = 32'h00000000; B = 32'h3F800000; #20; // 0 y 1
    A = 32'h3F800000; B = 32'h00000000; #20; // 1 y 0
    A = 32'h7F800000; B = 32'h00000000; #20; // inf y 0
    A = 32'h00000000; B = 32'hFF800000; #20; // 0 y -inf
    A = 32'h7F800000; B = 32'hFF800000; #20; // inf y -inf
    A = 32'h7F800000; B = 32'h7F800000; #20; // inf y inf
    A = 32'h1A3B5C7D; B = 32'h7F800000; #20; // n y inf
    A = 32'h7FC00000; B = 32'h41800000; #20; // nan y 16
    A = 32'h7F800000; B = 32'h7FC00000; #20; // inf y nan
    A = 32'h7FC00000; B = 32'h7FFFFFFF; #20; // nan y NAN

    #20;
    $finish;
  end

endmodule

