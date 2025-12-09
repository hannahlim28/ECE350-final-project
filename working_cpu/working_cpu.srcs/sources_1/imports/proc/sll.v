module sll(
  output [31:0] y,
  input  [31:0] a,
  input  [4:0]  shamt
);
  wire [31:0] s1, s2, s3, s4;

  wire [31:0] a_sh1   = {a[30:0], 1'b0};
  mux_2 #(32) M1(s1, shamt[0], a,  a_sh1);

  wire [31:0] s1_sh2  = {s1[29:0], 2'b00};
  mux_2 #(32) M2(s2, shamt[1], s1, s1_sh2);

  wire [31:0] s2_sh4  = {s2[27:0], 4'b0000};
  mux_2 #(32) M3(s3, shamt[2], s2, s2_sh4);

  wire [31:0] s3_sh8  = {s3[23:0], 8'h00};
  mux_2 #(32) M4(s4, shamt[3], s3, s3_sh8);

  wire [31:0] s4_sh16 = {s4[15:0], 16'h0000};
  mux_2 #(32) M5(y,  shamt[4], s4, s4_sh16);
endmodule
