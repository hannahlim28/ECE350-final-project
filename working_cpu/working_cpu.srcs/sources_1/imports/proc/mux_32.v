module mux_32 #(parameter WIDTH = 32)(
    output [WIDTH-1:0] out,
    input  [4:0] select,
    input  [WIDTH-1:0] in0,  in1,  in2,  in3, in4,  in5,  in6,  in7, in8,  in9,  in10, in11, in12, in13, in14, in15, in16, in17, in18, in19,
                       in20, in21, in22, in23, in24, in25, in26, in27, in28, in29, in30, in31 );

    wire [WIDTH-1:0] w0, w1, w2, w3;

    mux_8 #(WIDTH) m0 (w0, select[2:0], in0, in1, in2, in3, in4, in5, in6, in7);
    mux_8 #(WIDTH) m1 (w1, select[2:0], in8, in9, in10, in11, in12, in13, in14, in15);
    mux_8 #(WIDTH) m2 (w2, select[2:0], in16, in17, in18, in19, in20, in21, in22, in23);
    mux_8 #(WIDTH) m3 (w3, select[2:0], in24, in25, in26, in27, in28, in29, in30, in31);

    mux_4 #(WIDTH) final_mux (out, select[4:3], w0, w1, w2, w3);

endmodule