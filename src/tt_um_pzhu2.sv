// SPDX-License-Identifier: Apache-2.0
// Triangle rasterizer with VGA output

`default_nettype none

module tt_um_pzhu2 (
    input  wire [7:0] ui_in,    // Dedicated inputs  — ui_in[7:0] = data_byte
    output wire [7:0] uo_out,   // Dedicated outputs — VGA: {R1,G1,B1,vsync,R0,G0,B0,hsync}
    input  wire [7:0] uio_in,   // IOs: Input path   — uio_in[0] = valid strobe
    output wire [7:0] uio_out,  // IOs: Output path  — unused, tied 0
    output wire [7:0] uio_oe,   // IOs: Enable path  — all inputs (0)
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);

    wire [1:0] red, green, blue;
    wire       hsync, vsync;

    top u_top (
        .clk       (clk),
        .rst_n     (rst_n),
        .data_byte (ui_in),
        .valid     (uio_in[0]),
        .red       (red),
        .green     (green),
        .blue      (blue),
        .hsync     (hsync),
        .vsync     (vsync)
    );

    // Standard TinyTapeout VGA PMOD pinout: {R1,G1,B1,vsync,R0,G0,B0,hsync}
    assign uo_out = {red[1], green[1], blue[1], vsync, red[0], green[0], blue[0], hsync};

    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;

    wire _unused = &{ena, uio_in[7:1], 1'b0};

endmodule
