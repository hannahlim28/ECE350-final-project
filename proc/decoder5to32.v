module decoder5to32 (
    output [31:0] out,
    input  [4:0]  sel,
    input         en
);
    assign out = en ? (32'b1 << sel) : 32'b0;
endmodule