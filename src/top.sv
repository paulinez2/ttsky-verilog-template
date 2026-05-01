module top (
    input  logic clk, rst_n,
    input  logic [7:0] data_byte,
    input  logic       valid,

    output logic [1:0] red,
    output logic [1:0] green,
    output logic [1:0] blue,
    output logic hsync,
    output logic vsync
);

    // ----------------------------
    // VGA timing
    // ----------------------------
    logic [9:0] px, py;
    logic       in_active;

    vga_timing u_vga (
        .clk     (clk),
        .rst_n   (rst_n),
        .px      (px),
        .py      (py),
        .visible (in_active),
        .hsync   (hsync),
        .vsync   (vsync)
    );

    // ----------------------------
    // Pipeline
    // ----------------------------
    logic [7:0]         x0, y0, x1, y1, x2, y2, color;
    logic               valid_triangle;
    logic signed [9:0]  A0, B0, A1, B1, A2, B2;
    logic signed [15:0] C0, C1, C2;
    logic [7:0]         color_setup;
    logic               setup_done;
    logic               pixel_on;
    logic [7:0]         color_out;

    triangle_receiver u_receiver (
        .clk(clk), .rst_n(rst_n),
        .data_byte(data_byte), .valid(valid),
        .x0(x0), .y0(y0), .x1(x1), .y1(y1), .x2(x2), .y2(y2),
        .color(color), .valid_triangle(valid_triangle)
    );

    triangle_setup u_setup (
        .clk(clk), .rst_n(rst_n), .start(valid_triangle),
        .x0(x0), .y0(y0), .x1(x1), .y1(y1), .x2(x2), .y2(y2),
        .color_in(color),
        .A0(A0), .B0(B0), .A1(A1), .B1(B1), .A2(A2), .B2(B2),
        .C0(C0), .C1(C1), .C2(C2),
        .color_out(color_setup), .setup_done(setup_done)
    );

    // Map screen coords into the 256x256 box centered at (320, 240)
    logic [9:0] px_local, py_local;
    logic       visible_local;
    assign px_local      = px - 10'd192;
    assign py_local      = py - 10'd112;
    assign visible_local = in_active
                         && (px >= 10'd192) && (px < 10'd448)
                         && (py >= 10'd112) && (py < 10'd368);

    rasterizer #(.W(256)) u_rast (
        .clk(clk),
        .rst(~rst_n),
        .px(px_local), .py(py_local),
        .visible(visible_local),
        .setup_done(setup_done),
        .A0(A0), .B0(B0), .A1(A1), .B1(B1), .A2(A2), .B2(B2),
        .C0(C0), .C1(C1), .C2(C2),
        .tri_color(color_setup),
        .pixel_on(pixel_on),
        .color_out(color_out)
    );

    // ----------------------------
    // Output
    // ----------------------------
    logic in_active_d, visible_local_d;
    always_ff @(posedge clk) in_active_d     <= in_active;
    always_ff @(posedge clk) visible_local_d <= visible_local;

    always_comb begin
        if (in_active_d && pixel_on)
            {red, green, blue} = {color_out[7:6], color_out[5:4], color_out[3:2]};
        else if (visible_local_d)
            {red, green, blue} = {2'b11, 2'b01, 2'b10}; // pink background
        else
            {red, green, blue} = 6'b0;
    end

endmodule
