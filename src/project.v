/*
 * Copyright (c) 2024 ANNA V
 * SPDX-License-Identifier: Apache-2.0
 */
/*
 * Copyright (c) 2024 Anna V
 * SPDX-License-Identifier: Apache-2.0
 */
`default_nettype none
module tt_um_anna_vee (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
  wire button = ui_in[1];
  wire switch = ui_in[2];
  reg a, b, c, d, e, f, g, dig1, dig2;
  assign uo_out  = {1'b0, g, f, e, d, c, b, a};
  assign uio_out = {6'b0, dig2, dig1};
  assign uio_oe  = 8'b00000011;

  reg [3:0] ones = 0;
  reg [3:0] tens = 0;
  reg [9:0] debounce_cnt = 0;
  reg button_stable = 0;
  reg button_prev = 0;
  reg [9:0] muxswitch = 0;
  reg mux = 0;
  reg [22:0] seconds = 0;

  always @(posedge clk) begin
    button_prev <= button_stable;

    if (button == 1'b1) begin
      if (debounce_cnt == 10'd999)
        button_stable <= 1;
      else
        debounce_cnt <= debounce_cnt + 1;
    end else begin
      debounce_cnt <= 0;
      button_stable <= 0;
    end

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
    end

    muxswitch <= muxswitch + 1;
    if (muxswitch == 0)
      mux <= ~mux;

    if (switch) begin
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
