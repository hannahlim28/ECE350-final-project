module reg1 #(parameter WIDTH = 32)(q, d, clk, we, rst);
    input [WIDTH-1:0] d;
    output [WIDTH-1:0] q;
    input clk, we, rst; 

    dffe_ref ff0  (.q(q[0]),  .d(d[0]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff1  (.q(q[1]),  .d(d[1]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff2  (.q(q[2]),  .d(d[2]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff3  (.q(q[3]),  .d(d[3]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff4  (.q(q[4]),  .d(d[4]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff5  (.q(q[5]),  .d(d[5]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff6  (.q(q[6]),  .d(d[6]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff7  (.q(q[7]),  .d(d[7]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff8  (.q(q[8]),  .d(d[8]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff9  (.q(q[9]),  .d(d[9]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff10 (.q(q[10]),  .d(d[10]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff11 (.q(q[11]),  .d(d[11]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff12 (.q(q[12]),  .d(d[12]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff13 (.q(q[13]),  .d(d[13]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff14 (.q(q[14]),  .d(d[14]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff15 (.q(q[15]),  .d(d[15]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff16 (.q(q[16]),  .d(d[16]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff17 (.q(q[17]),  .d(d[17]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff18 (.q(q[18]),  .d(d[18]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff19 (.q(q[19]),  .d(d[19]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff20 (.q(q[20]),  .d(d[20]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff21 (.q(q[21]),  .d(d[21]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff22 (.q(q[22]),  .d(d[22]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff23 (.q(q[23]),  .d(d[23]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff24 (.q(q[24]),  .d(d[24]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff25 (.q(q[25]),  .d(d[25]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff26 (.q(q[26]),  .d(d[26]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff27 (.q(q[27]),  .d(d[27]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff28 (.q(q[28]),  .d(d[28]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff29 (.q(q[29]),  .d(d[29]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff30 (.q(q[30]),  .d(d[30]),  .clk(clk), .en(we), .clr(rst));
    dffe_ref ff31 (.q(q[31]),  .d(d[31]),  .clk(clk), .en(we), .clr(rst));

endmodule
