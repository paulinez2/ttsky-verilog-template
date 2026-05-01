module rasterizer #(parameter W = 32) (
    input  logic clk, rst,
    input  logic [9:0] px, py,
    input  logic [7:0] tri_color,
    input  logic signed [9:0]  A0, B0, A1, B1, A2, B2,
    input  logic signed [15:0] C0, C1, C2,
    input  logic visible, setup_done,
    output logic pixel_on,
    output logic [7:0] color_out
);
    logic signed [15:0] e0, e1, e2;
    logic signed [15:0] e0_row, e1_row, e2_row;
    logic signed [15:0] e0_next, e1_next, e2_next;
    logic [7:0] color_latched;
    logic locked;

    // Combinational next-cycle edge values (fix bug 2)
    always_comb begin
        if (px == 0) begin
            e0_next = e0_row;
            e1_next = e1_row;
            e2_next = e2_row;
        end else begin
            e0_next = e0 + A0;
            e1_next = e1 + A1;
            e2_next = e2 + A2;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            e0_row        <= 0; e1_row <= 0; e2_row <= 0;
            e0            <= 0; e1     <= 0; e2     <= 0;
            pixel_on      <= 0;
            color_out     <= 0;
            color_latched <= 0;
            locked        <= 0;
        end
        else if (setup_done && !locked) begin
            e0_row        <= C0; e1_row <= C1; e2_row <= C2;
            e0            <= C0; e1     <= C1; e2     <= C2;
            color_latched <= tri_color;
            locked        <= 1;
        end
        else if (visible && locked) begin
            if (py == 0 && px == 0) begin
                // Frame start: re-sync row accumulators so triangle doesn't drift each frame
                e0_row <= C0; e1_row <= C1; e2_row <= C2;
                e0     <= C0; e1     <= C1; e2     <= C2;
            end else begin
                e0 <= e0_next;
                e1 <= e1_next;
                e2 <= e2_next;

                if (px == W - 1) begin
                    e0_row <= e0_row + B0;
                    e1_row <= e1_row + B1;
                    e2_row <= e2_row + B2;
                end
            end

            pixel_on  <= (e0_next >= 0) && (e1_next >= 0) && (e2_next >= 0);
            color_out <= ((e0_next >= 0) && (e1_next >= 0) && (e2_next >= 0))
                          ? color_latched : 8'h00;
        end
        else begin
            pixel_on  <= 0;
            color_out <= 0;
        end
    end
endmodule