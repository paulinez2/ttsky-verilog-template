// ============================================================
//  vga_timing.sv
//  Standard 640x480 @ 60 Hz  (25.175 MHz pixel clock)
//
//  Horizontal totals  (pixels):
//    Visible: 640   Front porch: 16   Sync: 96   Back porch: 48  → 800
//  Vertical totals  (lines):
//    Visible: 480   Front porch: 10   Sync: 2    Back porch: 33  → 525
//
//  hsync / vsync are active-LOW (standard VGA polarity)
// ============================================================
module vga_timing (
    input  logic        clk,        // 25.175 MHz pixel clock
    input  logic        rst_n,

    output logic [9:0]  px,         // current pixel x  (0..639 in visible area)
    output logic [9:0]  py,         // current pixel y  (0..479 in visible area)
    output logic        visible,    // high when px/py are in the active region
    output logic        hsync,      // active-low horizontal sync
    output logic        vsync       // active-low vertical sync
);

    // -------------------------------------------------------
    // Horizontal counter  0..799
    // -------------------------------------------------------
    localparam H_VISIBLE    = 10'd640;
    localparam H_FP         = 10'd16;
    localparam H_SYNC       = 10'd96;
    localparam H_BP         = 10'd48;
    localparam H_TOTAL      = H_VISIBLE + H_FP + H_SYNC + H_BP; // 800

    localparam H_SYNC_START = H_VISIBLE + H_FP;           // 656
    localparam H_SYNC_END   = H_VISIBLE + H_FP + H_SYNC;  // 752

    // -------------------------------------------------------
    // Vertical counter  0..524
    // -------------------------------------------------------
    localparam V_VISIBLE    = 10'd480;
    localparam V_FP         = 10'd10;
    localparam V_SYNC       = 10'd2;
    localparam V_BP         = 10'd33;
    localparam V_TOTAL      = V_VISIBLE + V_FP + V_SYNC + V_BP; // 525

    localparam V_SYNC_START = V_VISIBLE + V_FP;           // 490
    localparam V_SYNC_END   = V_VISIBLE + V_FP + V_SYNC;  // 492

    // -------------------------------------------------------
    logic [9:0] h_cnt, v_cnt;

    // Horizontal counter
    always_ff @(posedge clk) begin
        if (!rst_n)
            h_cnt <= '0;
        else if (h_cnt == H_TOTAL - 1)
            h_cnt <= '0;
        else
            h_cnt <= h_cnt + 1'b1;
    end

    // Vertical counter — increments at end of each horizontal line
    always_ff @(posedge clk) begin
        if (!rst_n)
            v_cnt <= '0;
        else if (h_cnt == H_TOTAL - 1) begin
            if (v_cnt == V_TOTAL - 1)
                v_cnt <= '0;
            else
                v_cnt <= v_cnt + 1'b1;
        end
    end

    // -------------------------------------------------------
    // Outputs (registered — one cycle latency, fine for VGA)
    // -------------------------------------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            px      <= '0;
            py      <= '0;
            visible <= 1'b0;
            hsync   <= 1'b1;
            vsync   <= 1'b1;
        end else begin
            px      <= h_cnt;
            py      <= v_cnt;
            visible <= (h_cnt < H_VISIBLE) && (v_cnt < V_VISIBLE);
            hsync   <= ~((h_cnt >= H_SYNC_START) && (h_cnt < H_SYNC_END));
            vsync   <= ~((v_cnt >= V_SYNC_START) && (v_cnt < V_SYNC_END));
        end
    end

endmodule