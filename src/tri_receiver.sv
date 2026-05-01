module triangle_receiver (
    input  logic        clk, rst_n,
    input  logic [7:0]  data_byte,
    input  logic        valid,
    output logic [7:0]  x0, y0, x1, y1, x2, y2,
    output logic [7:0]  color,
    output logic        valid_triangle
);

    logic [2:0] count;
    logic       clear;

    assign clear = valid && (count == 3'd6);

    counter #(3) c1 (
        .clk   (clk),
        .rst_n (rst_n),
        .en    (valid),
        .clear (clear),
        .Q     (count),
        .D     (count)
    );

    always_ff @(posedge clk) begin
        if (~rst_n) begin
            x0    <= '0;
            y0    <= '0;
            x1    <= '0;
            y1    <= '0;
            x2    <= '0;
            y2    <= '0;
            color <= '0;
        end else if (valid) begin
            case (count)
                3'd0: x0    <= data_byte;
                3'd1: y0    <= data_byte;
                3'd2: x1    <= data_byte;
                3'd3: y1    <= data_byte;
                3'd4: x2    <= data_byte;
                3'd5: y2    <= data_byte;
                3'd6: color <= data_byte;
            endcase
        end
    end

    always_ff @(posedge clk) begin
        if (~rst_n) 
            valid_triangle <= 1'b0;
        else        
            valid_triangle <= clear;
    end

endmodule