module RangeFinder
   #(parameter WIDTH=16)
    (input  logic [WIDTH-1:0] data_in,
     input  logic             clock, reset,
     input  logic             go, finish,
     output logic [WIDTH-1:0] range,
     output logic             error);

   // Put your code here

   logic [WIDTH-1:0] smallest, largest;
   logic go_asserted;
   
   assign range = largest - smallest;

   always_ff @(posedge clock, posedge reset) begin
      if (reset) begin
         go_asserted <= 'b0;
         smallest <= 'd0;
         largest <= 'd0;
         error <= 1'b0;
      end
      else if (go && finish) begin
         go_asserted <= 'b0;
         error <= 1'b1;
      end 
      else if (go && ~finish && ~go_asserted) begin //  initial value storing 
         smallest <= data_in;
         largest <= data_in;
         go_asserted <= 'b1;
         error <= 1'b0;
      end 
      else if (go_asserted) begin
         if (finish) begin
            error <= 1'b0; 
            go_asserted <= 'b0;
         end 
         else begin
            if (data_in > largest) largest <= data_in;
            if (data_in < smallest) smallest <= data_in;
         end
      end
   end
endmodule: RangeFinder