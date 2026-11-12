`timescale 1ns / 1ps

module MUL_test;

    reg [3:0] data_in;
    reg clk, start, rst;
    wire [7:0] product;
    wire done;

    // Instantiate your top module
    MUL_TOP uut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .data_in(data_in),
        .product(product),
        .done(done)
    );

    // Clock generation (10 time units period)
    always #5 clk = ~clk;

    // Clock, Reset, and Start initialization
    initial begin
        clk = 1'b0;
        rst = 1'b1;
        start = 1'b0;
        #10 rst = 1'b0;   // Release reset
        #3 start = 1'b1;  // Assert start pulse
        #1000 $finish;
    end

    // Input data stimulus (Loading operand A then operand B)
    initial begin
        #17 data_in = 4'd6;   // Multiplicand A = 5
        #10 data_in = 4'd5;   // Multiplier B = 6  (Expected Product = 30)
    end

    // Monitor results in console
    initial begin
        $monitor($time, " Product = %d, Done = %b", product, done);
    end

endmodule