// Width-N register with enable + async clear (high), built from dffe_ref.
module register #(parameter WIDTH = 1) (
    output [WIDTH-1:0] data_out,
    input  [WIDTH-1:0] data_in,
    input               clock,
    input               enable,
    input               clear
);
    genvar i;
    generate
        for (i = 0; i < WIDTH; i = i + 1) begin : g
            dffe_ref ff_i( .q (data_out[i]), .d (data_in[i]), .clk (clock), .en (enable), .clr (clear));
        end
    endgenerate
endmodule
