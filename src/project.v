/*

 * Copyright (c) 2024 Anna V

 * SPDX-License-Identifier: Apache-2.0

 */

`default_nettype none

module tt_um_anna_vee (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_oe,
    output wire [7:0] uio_out,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

  wire _unused = &{ena, uio_in, ui_in[7:3]};

  reg button_sync0, button_sync1;
  reg switch_sync0, switch_sync1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      button_sync0 <= 1'b0;
      button_sync1 <= 1'b0;
      switch_sync0 <= 1'b0;
      switch_sync1 <= 1'b0;
    end else begin
      button_sync0 <= ui_in[1];
      button_sync1 <= button_sync0;
      switch_sync0 <= ui_in[2];
      switch_sync1 <= switch_sync0;
    end
  end

  wire button = button_sync1;
  wire sw     = switch_sync1;

  reg a, b, c, d, e, f, g;
  reg dig1, dig2;

  assign uo_out  = {1'b0, g, f, e, d, c, b, a};
  assign uio_out = {6'b000000, dig2, dig1};
  assign uio_oe  = 8'b00000011;

  reg [3:0]  ones;
  reg [3:0]  tens;
  reg [9:0]  debounce_cnt;
  reg        button_stable;
  reg        button_prev;
  reg [6:0]  muxswitch;
  reg        mux;
  reg [22:0] seconds;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ones          <= 4'd0;
      tens          <= 4'd0;
      debounce_cnt  <= 10'd0;
      button_stable <= 1'b0;
      button_prev   <= 1'b0;
      muxswitch     <= 7'd0;
      mux           <= 1'b0;
      seconds       <= 23'd0;
    end else begin
      button_prev <= button_stable;

      if (button) begin
        if (debounce_cnt == 10'd999) begin
          button_stable <= 1'b1;
        end else begin
          debounce_cnt  <= debounce_cnt + 10'd1;
          button_stable <= 1'b0;
        end
      end else begin
        debounce_cnt  <= 10'd0;
        button_stable <= 1'b0;
      end

      if (button_stable && !button_prev) begin
        if (ones == 4'd9) begin
          ones <= 4'd0;
          tens <= (tens == 4'd9) ? 4'd0 : tens + 4'd1;
        end else begin
          ones <= ones + 4'd1;
        end
      end else if (sw) begin
        if (seconds == 23'd5_999_999) begin
          seconds <= 23'd0;
          if (ones == 4'd0) begin
            if (tens > 4'd0) begin
              tens <= tens - 4'd1;
              ones <= 4'd9;
            end
          end else begin
            ones <= ones - 4'd1;
          end
        end else begin
          seconds <= seconds + 23'd1;
        end
      end else begin
        seconds <= 23'd0;
      end

      muxswitch <= muxswitch + 7'd1;
      if (muxswitch == 7'd0)
        mux <= ~mux;
    end
  end

  function [6:0] seg7;
    input [3:0] digit;
    begin
      case (digit)
        4'd0:    seg7 = 7'b1111110;
        4'd1:    seg7 = 7'b0110000;
        4'd2:    seg7 = 7'b1101101;
        4'd3:    seg7 = 7'b1111001;
        4'd4:    seg7 = 7'b0110011;
        4'd5:    seg7 = 7'b1011011;
        4'd6:    seg7 = 7'b1011111;
        4'd7:    seg7 = 7'b1110000;
        4'd8:    seg7 = 7'b1111111;
        4'd9:    seg7 = 7'b1111011;
        default: seg7 = 7'b0000000;
      endcase
    end
  endfunction

  always @(*) begin
    if (mux == 1'b0) begin
      {a, b, c, d, e, f, g} = seg7(ones);
      dig1 = 1'b1;
      dig2 = 1'b0;
    end else begin
      {a, b, c, d, e, f, g} = seg7(tens);
      dig1 = 1'b0;
      dig2 = 1'b1;
    end
  end

endmodule
