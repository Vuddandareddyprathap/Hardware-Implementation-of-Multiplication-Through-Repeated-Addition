`timescale 1ns / 1ps

module edge_zynq_top (
    input clk,               // 50 MHz Pin U18
    input rst_btn,           // SW5 (Pin V15)
    input clk_step_btn,      // SW7 (Pin W15)
    input [3:0] sw,          // Slide Switches SW8, SW6, SW4, SW3
    output [3:0] led,        // Diagnostic LEDs D4 - D7
    output [3:0] an,         // 4-Digit Display Anodes (Active-High)
    output [6:0] seg,        // 7 Segments a-g (Active-Low)
    output dp                // Decimal Point (Active-Low)
);

    assign led = sw;         // Mirror switches to diagnostic LEDs
    assign dp  = 1'b1;       // Decimal point OFF

    // -------------------------------------------------------------
    // 1. Debounce SW7 Button
    // -------------------------------------------------------------
    reg [19:0] btn_cnt = 0;
    reg btn_sync_0 = 0, btn_sync_1 = 0;
    reg btn_state = 0;
    reg step_pulse = 0;

    always @(posedge clk) begin
        btn_sync_0 <= clk_step_btn;
        btn_sync_1 <= btn_sync_0;

        if (btn_sync_1 != btn_state) begin
            btn_cnt <= btn_cnt + 1'b1;
            if (btn_cnt == 20'd1_000_000) begin // 20ms debounce
                btn_state <= btn_sync_1;
                btn_cnt <= 0;
                if (btn_sync_1 == 1'b1)
                    step_pulse <= 1'b1;
            end
        end else begin
            btn_cnt <= 0;
            step_pulse <= 1'b0;
        end
    end

    // -------------------------------------------------------------
    // 2. Instantiate Verified MUL_TOP Core
    // -------------------------------------------------------------
    wire [7:0] product;
    wire [3:0] reg_a_out;
    wire [3:0] reg_b_out;
    wire done;

    // Automatic start trigger: High on first button tap, then stays high
    reg started = 0;
    always @(posedge clk or posedge rst_btn) begin
        if (rst_btn)
            started <= 1'b0;
        else if (step_pulse)
            started <= 1'b1;
    end

    MUL_TOP multiplier_unit (
        .clk(step_pulse),
        .rst(rst_btn),
        .start(started | step_pulse),
        .data_in(sw),
        .product(product),
        .reg_a_out(reg_a_out),
        .reg_b_out(reg_b_out),
        .done(done)
    );

    // -------------------------------------------------------------
    // 3. Display Routing (Inputs on Left, Outputs on Right)
    // -------------------------------------------------------------
    wire [3:0] hex0 = product[3:0];  // Digit 0: Product LSB
    wire [3:0] hex1 = product[7:4];  // Digit 1: Product MSB
    wire [3:0] hex2 = (reg_b_out == 4'b0 && !done) ? sw : reg_b_out; // Digit 2: Input B
    wire [3:0] hex3 = (reg_a_out == 4'b0 && !started) ? sw : reg_a_out; // Digit 3: Input A

    // -------------------------------------------------------------
    // 4. Multiplexing Refresh Engine (~1 kHz)
    // -------------------------------------------------------------
    reg [16:0] refresh_cnt = 0;
    always @(posedge clk) begin
        refresh_cnt <= refresh_cnt + 1'b1;
    end

    wire [1:0] digit_sel = refresh_cnt[16:15];
    reg [3:0] cur_hex;
    reg [3:0] an_reg;

    always @(*) begin
        case (digit_sel)
            2'b00: begin an_reg = 4'b0001; cur_hex = hex0; end // Digit 0
            2'b01: begin an_reg = 4'b0010; cur_hex = hex1; end // Digit 1
            2'b10: begin an_reg = 4'b0100; cur_hex = hex2; end // Digit 2
            2'b11: begin an_reg = 4'b1000; cur_hex = hex3; end // Digit 3
            default: begin an_reg = 4'b0000; cur_hex = 4'h0; end
        endcase
    end
    assign an = an_reg;

    // Segment Decoder (Active-Low)
    reg [6:0] seg_reg;
    always @(*) begin
        case (cur_hex)
            4'h0: seg_reg = 7'b1000000;
            4'h1: seg_reg = 7'b1111001;
            4'h2: seg_reg = 7'b0100100;
            4'h3: seg_reg = 7'b0110000;
            4'h4: seg_reg = 7'b0011001;
            4'h5: seg_reg = 7'b0010010;
            4'h6: seg_reg = 7'b0000010;
            4'h7: seg_reg = 7'b1111000;
            4'h8: seg_reg = 7'b0000000;
            4'h9: seg_reg = 7'b0010000;
            4'hA: seg_reg = 7'b0001000;
            4'hB: seg_reg = 7'b0000011;
            4'hC: seg_reg = 7'b1000110;
            4'hD: seg_reg = 7'b0100001;
            4'hE: seg_reg = 7'b0000110;
            4'hF: seg_reg = 7'b0001110;
            default: seg_reg = 7'b1111111;
        endcase
    end
    assign seg = seg_reg;

endmodule