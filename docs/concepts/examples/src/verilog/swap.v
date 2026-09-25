`timescale 1ns/1ps
module swap;
  reg clk = 0;
  reg [7:0] a = 1, b = 2;
  reg [7:0] x = 1, y = 2;

  always @(posedge clk) begin
    a <= b;
    b <= a;
    x = y;
    y = x;
    $display("active: a=%0d b=%0d x=%0d y=%0d", a, b, x, y);
    $strobe("settled: a=%0d b=%0d x=%0d y=%0d", a, b, x, y);
  end

  initial begin
    #1 clk = 1;
    #1 $finish;
  end
endmodule
