module counter
   #(parameter WIDTH=0)
    (input  logic clk, en, rst_n, clear,
     input  logic [WIDTH-1:0] D,
     output logic [WIDTH-1:0] Q);

     always_ff @(posedge clk) begin
         if (~rst_n)
             Q <= 'd0;
         else if (clear)
             Q <= 'd0;
         else if (en)
             Q <= D + 1;
     end
endmodule : counter

module multiplier #(parameter WIDTH = 8)(
    input  logic signed [WIDTH-1:0]   A,
    input  logic signed [WIDTH-1:0]   B,
    output logic signed [2*WIDTH-1:0] P);
    assign P = A * B;   
endmodule
 