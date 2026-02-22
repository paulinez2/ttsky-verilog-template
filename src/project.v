/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_example (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);

  wire [7:0] range_wire;
  wire error_wire;

  RangeFinder #(.WIDTH(8)) rf_inst (.data_in(ui_in),        
                                    .clock(clk),
                                    .reset(~rst_n),         
                                    .go(uio_in[0]),         
                                    .finish(uio_in[1]),    
                                    .range(range_wire),
                                    .error(error_wire));

  // All output pins must be assigned. If not used, assign to 0.
  // assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
  // assign uio_out = 0;
  // assign uio_oe  = 0;

  assign uo_out = range_wire;
  assign uio_out[2] = error_wire;
  assign uio_oe[2]  = 1'b1;  
  assign uio_out[7:3] = 5'b00000;
  assign uio_oe[7:3]  = 5'b00000;
  assign uio_oe[1:0] = 2'b00;

  // List all unused inputs to prevent warnings
  wire _unused = &{ena, 1'b0};

endmodule
