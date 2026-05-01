module triangle_setup (
    input  logic clk, rst_n, start,

    input  logic [7:0]  x0, y0, x1, y1, x2, y2,
    input  logic [7:0]  color_in,

    output logic signed [9:0]  A0, B0, A1, B1, A2, B2,
    output logic signed [15:0] C0, C1, C2,

    output logic [7:0] color_out,
    output logic setup_done
);

    // ----------------------------
    // Edge coefficient generation
    // ----------------------------
    logic signed [9:0] A0_w, B0_w, A1_w, B1_w, A2_w, B2_w;

    assign A0_w = $signed(y0 - y1);
    assign B0_w = $signed(x1 - x0);

    assign A1_w = $signed(y1 - y2);
    assign B1_w = $signed(x2 - x1);

    assign A2_w = $signed(y2 - y0);
    assign B2_w = $signed(x0 - x2);

    // ----------------------------
    // FSM
    // ----------------------------
    typedef enum logic [2:0] {
        S_IDLE,
        S_A0,
        S_B0,
        S_A1,
        S_B1,
        S_A2,
        S_B2,
        S_DONE
    } state_t;

    state_t state, state_next;

    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= state_next;
    end

    // ----------------------------
    // triangle index counter (THIS replaces "guessing")
    // ----------------------------
    logic [1:0] c_idx;

    always_ff @(posedge clk) begin
        if (!rst_n)
            c_idx <= 0;
        else if (start)
            c_idx <= 0;
        else if (state == S_B0 || state == S_B1 || state == S_B2)
            c_idx <= c_idx + 1;
    end

    // ----------------------------
    // control signals
    // ----------------------------
    logic compute_A, compute_B, store_C, accum_clear;

    always_comb begin
        state_next  = state;

        compute_A   = 0;
        compute_B   = 0;
        store_C     = 0;
        accum_clear = 0;

        case (state)

            S_IDLE: begin
                if (start)
                    state_next = S_A0;
            end

            // ---------------- A*X ----------------
            S_A0: begin
                compute_A = 1;
                accum_clear = 1;
                state_next = S_B0;
            end

            S_A1: begin
                compute_A = 1;
                accum_clear = 1;
                state_next = S_B1;
            end

            S_A2: begin
                compute_A = 1;
                accum_clear = 1;
                state_next = S_B2;
            end

            // ---------------- B*Y + STORE C ----------------
            S_B0: begin
                compute_B = 1;
                store_C   = 1;
                state_next = S_A1;
            end

            S_B1: begin
                compute_B = 1;
                store_C   = 1;
                state_next = S_A2;
            end

            S_B2: begin
                compute_B = 1;
                store_C   = 1;
                state_next = S_DONE;
            end

            S_DONE: begin
                state_next = S_IDLE;
            end

        endcase
    end

    // ----------------------------
    // muxes
    // ----------------------------
    logic signed [9:0] mux_A_out, mux_B_out;

    always_comb begin
        case (state)
            S_A0: mux_A_out = A0_w;
            S_B0: mux_A_out = B0_w;
            S_A1: mux_A_out = A1_w;
            S_B1: mux_A_out = B1_w;
            S_A2: mux_A_out = A2_w;
            S_B2: mux_A_out = B2_w;
            default: mux_A_out = 0;
        endcase
    end

    always_comb begin
        case (state)
            S_A0: mux_B_out = x0;
            S_B0: mux_B_out = y0;
            S_A1: mux_B_out = x1;
            S_B1: mux_B_out = y1;
            S_A2: mux_B_out = x2;
            S_B2: mux_B_out = y2;
            default: mux_B_out = 0;
        endcase
    end

    // ----------------------------
    // multiplier
    // ----------------------------
    logic signed [17:0] mul_result;

    multiplier u_mul (
        .A(mux_A_out),
        .B(mux_B_out),
        .P(mul_result)
    );

    // ----------------------------
    // accumulator (fixed timing)
    // ----------------------------
    logic signed [17:0] acc;

    always_ff @(posedge clk) begin
        if (!rst_n)
            acc <= 0;

        else if (compute_A)
            acc <= mul_result;              // start A*X

        else if (compute_B)
            acc <= acc + mul_result;        // add B*Y
    end

    // ----------------------------
    // C storage (NOW CLEAN + SAFE)
    // ----------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            C0 <= 0;
            C1 <= 0;
            C2 <= 0;
        end
        else if (store_C) begin
            case (c_idx)
                0: C0 <= -(acc + mul_result);
                1: C1 <= -(acc + mul_result);
                2: C2 <= -(acc + mul_result);
            endcase
        end
    end

    // ----------------------------
    // outputs
    // ----------------------------
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            A0 <= 0; B0 <= 0;
            A1 <= 0; B1 <= 0;
            A2 <= 0; B2 <= 0;
        end
        else if (start) begin
            A0 <= A0_w; B0 <= B0_w;
            A1 <= A1_w; B1 <= B1_w;
            A2 <= A2_w; B2 <= B2_w;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n)
            color_out <= 0;
        else if (start)
            color_out <= color_in;
    end

    always_ff @(posedge clk) begin
        if (!rst_n)
            setup_done <= 0;
        else
            setup_done <= (state == S_DONE);
    end

endmodule