`timescale 1ns / 1ps

module controller (
    input clk, rst, start, eqz,
    output reg LdA, LdB, LdP, clrP, decB, done
);

    localparam S0 = 3'b000, 
               S1 = 3'b001,  
               S2 = 3'b010,  
               S3 = 3'b011,  
               S4 = 3'b100;  

    reg [2:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            S0: if (start) next_state = S1;
            S1: next_state = S2;
            S2: next_state = S3;
            S3: if (eqz)   next_state = S4;
                else       next_state = S3;
            S4: next_state = S4; // Hold in DONE until reset
            default: next_state = S0;
        endcase
    end

    always @(*) begin
        LdA  = 1'b0;
        LdB  = 1'b0;
        LdP  = 1'b0;
        clrP = 1'b0;
        decB = 1'b0;
        done = 1'b0;

        case (state)
            S0: ;
            S1: LdA = 1'b1;
            S2: begin
                LdB  = 1'b1;
                clrP = 1'b1;
            end
            S3: begin
                if (!eqz) begin
                    LdP  = 1'b1;
                    decB = 1'b1;
                end
            end
            S4: done = 1'b1;
            default: ;
        endcase
    end

endmodule