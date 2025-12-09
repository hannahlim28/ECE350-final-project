module mux_2 #(parameter WIDTH = 32) (out, select, in0, in1); 
    input select; 
    input [WIDTH-1:0]in1; 
    input [WIDTH-1:0] in0; 
    output [WIDTH-1:0] out; 

    assign out = select ? in1 : in0; 

endmodule 