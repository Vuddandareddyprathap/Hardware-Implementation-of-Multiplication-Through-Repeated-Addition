`timescale 1ns / 1ps

module MUL_TOP (
    input clk, rst, start,
    input [3:0] data_in,
    output [7:0] product,
    output [3:0] reg_a_out,
    output [3:0] reg_b_out,
    output done
);
    wire LdA, LdB, LdP, clrP, decB;
    wire eqz;

    controller CTRL (
        .clk(clk),
        .rst(rst),
        .start(start),
        .eqz(eqz),
        .LdA(LdA),
        .LdB(LdB),
        .LdP(LdP),
        .clrP(clrP),
        .decB(decB),
        .done(done)
    );

    MUL_datapath DP (
        .eqz(eqz),
        .product(product),
        .reg_a_out(reg_a_out),
        .reg_b_out(reg_b_out),
        .LdA(LdA),
        .LdB(LdB),
        .LdP(LdP),
        .clrP(clrP),
        .decB(decB),
        .data_in(data_in),
        .clk(clk),
        .rst(rst)
    );

endmodule