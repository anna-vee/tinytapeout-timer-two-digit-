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

  // FIX 2: 2-flop synchronizers for async inputs
  reg button_sync0, button_sync1;
  reg switch_sync0, switch_sync1;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      button_sync0 <= 0;
      button_sync1 <= 0;
      switch_sync0 <= 0;
      switch_sync1 <= 0;
    end else begin
      button_sync0 <= ui_in[1];
      button_sync1 <= button_sync0;
      switch_sync0 <= ui_in[2];
      switch_sync1 <= switch_sync0;
    end
  end

  wire button = button_sync1;
  wire switch = switch_sync1;

  reg a, b, c, d, e, f, g, dig1, dig2;
  assign uo_out  = {1'b0, g, f, e, d, c, b, a};
  assign uio_out = {6'b0, dig2, dig1};
  assign uio_oe  = 8'b00000011;

  // FIX 1: removed inline = 0 initializers, not guaranteed in ASIC
  reg [3:0] ones;
  reg [3:0] tens;
  reg [9:0] debounce_cnt;
  reg       button_stable;
  reg       button_prev;
  reg [9:0] muxswitch;
  reg       mux;
  reg [22:0] seconds;

  // FIX 1: proper async reset + FIX 3: priority structure
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      ones          <= 0;
      tens          <= 0;
      debounce_cnt  <= 0;
      button_stable <= 0;
      button_prev   <= 0;
      muxswitch     <= 0;
      mux           <= 0;
      seconds       <= 0;
    end else begin

      button_prev <= button_stable;

      // debounce
      if (button == 1) begin
        if (debounce_cnt == 999)
          button_stable <= 1;
        else
          debounce_cnt <= debounce_cnt + 1;
      end else begin
        debounce_cnt  <= 0;
        button_stable <= 0;
      end

      // FIX 3: priority — button increment wins over countdown
      if (button_stable && !button_prev) begin
        if (ones == 9) begin
          ones <= 0;
          if (tens == 9)
            tens <= 0;
          else
            tens <= tens + 1;
        end else begin
          ones <= ones + 1;
        end
      end else if (switch) begin
        seconds <= seconds + 1;
        if (seconds == 6000000) begin
          seconds <= 0;
          if (ones == 0) begin
            if (tens > 0) begin
              tens <= tens - 1;
              ones <= 9;
            end
          end else begin
            ones <= ones - 1;
          end
        end
      end else begin
        seconds <= 0;
      end

      // mux clock divider
      muxswitch <= muxswitch + 1;
      if (muxswitch == 0)
        mux <= ~mux;

    end
  end

  function [6:0] seg7;
    input [3:0] digit;
    begin
      case (digit)
        0: seg7 = 7'b1111110;
        1: seg7 = 7'b0110000;
        2: seg7 = 7'b1101101;
        3: seg7 = 7'b1111001;
        4: seg7 = 7'b0110011;
        5: seg7 = 7'b1011011;
        6: seg7 = 7'b1011111;
        7: seg7 = 7'b1110000;
        8: seg7 = 7'b1111111;
        9: seg7 = 7'b1111011;
        default: seg7 = 7'b0000000;
      endcase
    end
  endfunction

  always @(*) begin
    if (mux == 0) begin
      {a,b,c,d,e,f,g} = seg7(ones);
      dig1 = 1;
      dig2 = 0;
    end else begin
      {a,b,c,d,e,f,g} = seg7(tens);
      dig1 = 0;
      dig2 = 1;
    end
  end

endmodule
