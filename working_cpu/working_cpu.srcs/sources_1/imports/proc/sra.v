module sra(
  output [31:0] y,
  input  [31:0] a,
  input  [4:0]  shamt
);
  wire sign = a[31];
  wire [31:0] s1, s2, s3, s4;

  wire [31:0] a_sh1 = {sign, a[31:1]};
  mux_2 M1(s1, shamt[0], a, a_sh1);

  wire [31:0] s1_sh2 = {{2{sign}}, s1[31:2]};
  mux_2 M2(s2, shamt[1], s1, s1_sh2);

  wire [31:0] s2_sh4 = {{4{sign}}, s2[31:4]};
  mux_2 M3(s3,shamt[2], s2, s2_sh4);

  wire [31:0] s3_sh8 = {{8{sign}}, s3[31:8]};
  mux_2 M4(s4,shamt[3], s3, s3_sh8);

  wire [31:0] s4_sh16 = {{16{sign}}, s4[31:16]};
  mux_2 M5(y,shamt[4],s4, s4_sh16);
endmodule
