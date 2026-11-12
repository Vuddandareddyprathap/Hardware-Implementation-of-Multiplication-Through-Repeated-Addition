`timescale 1ns / 1ps

module MUL_datapath (
    output eqz,
    output [7:0] product,
    output [3:0] reg_a_out,
    output [3:0] reg_b_out,
    input LdA, LdB, LdP, clrP, decB,
    input [3:0] data_in,
    input clk, rst
);
    wire [3:0] A, B;
    wire [7:0] P, sum;

    PIPO1 REG_A (
        .dout(A),
        .din(data_in),
        .ld(LdA),
        .clk(clk),
        .rst(rst)
    );

    PIPO2 REG_P (
        .dout(P),
        .din(sum),
        .ld(LdP),
        .clr(clrP),
        .clk(clk),
        .rst(rst)
    );

    CNTR REG_B (
        .dout(B),
        .din(data_in),
        .ld(LdB),
        .dec(decB),
        .clk(clk),
        .rst(rst)
    );

    ADD ADDER (
        .out(sum),
        .in1(A),
        .in2(P)
    );

    EQZ ZERO_CHECK (
        .eqz(eqz),
        .data(B)
    );

    assign product   = P;
    assign reg_a_out = A;
    assign reg_b_out = B;

endmodule

// ==========================================
// Datapath Sub-modules
// ==========================================

module PIPO1 (
    output reg [3:0] dout,
    input [3:0] din,
    input ld, clk, rst
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= 4'b0;
        else if (ld)
            dout <= din;
    end
endmodule

module PIPO2 (
    output reg [7:0] dout,
    input [7:0] din,
    input ld, clr, clk, rst
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= 8'b0;
        else if (clr)
            dout <= 8'b0;
        else if (ld)
            dout <= din;
    end
endmodule

module CNTR (
    output reg [3:0] dout,
    input [3:0] din,
    input ld, dec, clk, rst
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            dout <= 4'b0;
        else if (ld)
            dout <= din;
        else if (dec && (dout != 4'b0))
            dout <= dout - 4'd1;
    end
endmodule

module ADD (
    output [7:0] out,
    input [3:0] in1,
    input [7:0] in2
);
    assign out = in2 + {4'b0000, in1};
endmodule

module EQZ (
    output eqz,
    input [3:0] data
);
    assign eqz = (data == 4'b0000);
endmodule