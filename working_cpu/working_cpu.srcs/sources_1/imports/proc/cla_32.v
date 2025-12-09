module cla_32(
  output [31:0] sum,
  output        Cout,
  input  [31:0] a, b,
  input         Cin
);
  wire [7:0] P, G;

  wire c0 = Cin;
  wire c4, c8, c12, c16, c20, c24, c28, c32;

  cla_4 U0(.sum(sum[3:0]), .Cout (), .P(P[0]), .G(G[0]), .a(a[3:0]), .b(b[3:0]), .Cin(c0));
  cla_4 U1(.sum(sum[7:4]), .Cout (), .P(P[1]), .G(G[1]), .a(a[7:4]), .b(b[7:4]), .Cin(c4));
  cla_4 U2(.sum(sum[11:8]), .Cout(), .P(P[2]), .G(G[2]), .a(a[11:8]), .b(b[11:8]), .Cin(c8));
  cla_4 U3(.sum(sum[15:12]), .Cout (), .P(P[3]), .G(G[3]), .a(a[15:12]), .b(b[15:12]), .Cin(c12));
  cla_4 U4(.sum(sum[19:16]), .Cout(), .P (P[4]), .G (G[4]), .a (a[19:16]), .b (b[19:16]), .Cin (c16));
  cla_4 U5(.sum(sum[23:20]), .Cout(), .P(P[5]), .G(G[5]), .a(a[23:20]), .b(b[23:20]), .Cin(c20));
  cla_4 U6(.sum(sum[27:24]), .Cout (), .P(P[6]), .G(G[6]), .a(a[27:24]),.b(b[27:24]), .Cin(c24));
  cla_4 U7(.sum(sum[31:28]), .Cout (), .P(P[7]), .G(G[7]), .a(a[31:28]), .b(b[31:28]), .Cin(c28));

  wire P0c0; 
  and a40(P0c0, P[0], c0);  
  or  o40(c4,  G[0], P0c0);

  wire P1G0, P1P0, P1P0c0;
  and a81(P1G0, P[1], G[0]); 
  and a82(P1P0, P[1], P[0]);  
  and a83(P1P0c0, P1P0, c0);
  or  o80(c8, G[1], P1G0, P1P0c0);

  wire P2G1, P2P1, P2P1G0, P2P1P0, P2P1P0c0;
  and a120(P2G1, P[2], G[1]); 
  and a121(P2P1, P[2], P[1]);
  and a122(P2P1G0, P2P1, G[0]); 
  and a123(P2P1P0, P2P1, P[0]);
  and a124(P2P1P0c0, P2P1P0, c0);
  or  o120(c12, G[2], P2G1, P2P1G0, P2P1P0c0);

  wire P3G2, P3P2, P3P2G1, P3P2P1, P3P2P1G0, P3P2P1P0, P3P2P1P0c0, t16;
  and a160(P3G2, P[3], G[2]); 
  and a161(P3P2, P[3], P[2]); 
  and a162(P3P2G1, P3P2, G[1]);
  and a163(P3P2P1, P3P2, P[1]); 
  and a164(P3P2P1G0, P3P2P1, G[0]);
  and a165(P3P2P1P0, P3P2P1, P[0]); 
  and a166(P3P2P1P0c0, P3P2P1P0, c0);
  or  o161(t16, G[3], P3G2, P3P2G1, P3P2P1G0); 
  or  o162(c16, t16, P3P2P1P0c0);

  wire P4G3,P4P3,P4P3G2,P4P3P2,P4P3P2G1,P4P3P2P1,P4P3P2P1G0,P4P3P2P1P0,P4P3P2P1P0c0;
  and a200(P4G3,P[4],G[3]); 
  and a201(P4P3,P[4],P[3]); 
  and a202(P4P3G2,P4P3,G[2]);
  and a203(P4P3P2,P4P3,P[2]); 
  and a204(P4P3P2G1,P4P3P2,G[1]);
  and a205(P4P3P2P1,P4P3P2,P[1]); 
  and a206(P4P3P2P1G0,P4P3P2P1,G[0]);
  and a207(P4P3P2P1P0,P4P3P2P1,P[0]); 
  and a208(P4P3P2P1P0c0,P4P3P2P1P0,c0);
  wire t20a,t20b;
  or  o201(t20a, G[4], P4G3, P4P3G2, P4P3P2G1);
  or  o202(t20b, P4P3P2P1G0, P4P3P2P1P0c0);
  or  o203(c20, t20a, t20b);

  wire P5G4,P5P4,P5P4G3,P5P4P3,P5P4P3G2,P5P4P3P2,P5P4P3P2G1,P5P4P3P2P1,P5P4P3P2P1G0,P5P4P3P2P1P0,P5P4P3P2P1P0c0;
  and a240(P5G4,P[5],G[4]); 
  and a241(P5P4,P[5],P[4]); 
  and a242(P5P4G3,P5P4,G[3]);
  and a243(P5P4P3,P5P4,P[3]); 
  and a244(P5P4P3G2,P5P4P3,G[2]);
  and a245(P5P4P3P2,P5P4P3,P[2]); 
  and a246(P5P4P3P2G1,P5P4P3P2,G[1]);
  and a247(P5P4P3P2P1,P5P4P3P2,P[1]); 
  and a248(P5P4P3P2P1G0,P5P4P3P2P1,G[0]);
  and a249(P5P4P3P2P1P0,P5P4P3P2P1,P[0]); 
  and a24A(P5P4P3P2P1P0c0,P5P4P3P2P1P0,c0);
  wire t24a,t24b; 
  or  o241(t24a, G[5], P5G4, P5P4G3, P5P4P3G2);
  or  o242(t24b, P5P4P3P2G1, P5P4P3P2P1G0, P5P4P3P2P1P0c0);
  or  o243(c24, t24a, t24b);

  wire P6G5,P6P5,P6P5G4,P6P5P4,P6P5P4G3,P6P5P4P3,P6P5P4P3G2,P6P5P4P3P2,P6P5P4P3P2G1,P6P5P4P3P2P1,P6P5P4P3P2P1G0,P6P5P4P3P2P1P0,P6P5P4P3P2P1P0c0;
  and a280(P6G5,P[6],G[5]); 
  and a281(P6P5,P[6],P[5]); 
  and a282(P6P5G4,P6P5,G[4]);
  and a283(P6P5P4,P6P5,P[4]); 
  and a284(P6P5P4G3,P6P5P4,G[3]);
  and a285(P6P5P4P3,P6P5P4,P[3]); 
  and a286(P6P5P4P3G2,P6P5P4P3,G[2]);
  and a287(P6P5P4P3P2,P6P5P4P3,P[2]); 
  and a288(P6P5P4P3P2G1,P6P5P4P3P2,G[1]);
  and a289(P6P5P4P3P2P1,P6P5P4P3P2,P[1]); 
  and a28A(P6P5P4P3P2P1G0,P6P5P4P3P2P1,G[0]);
  and a28B(P6P5P4P3P2P1P0,P6P5P4P3P2P1,P[0]); 
  and a28C(P6P5P4P3P2P1P0c0,P6P5P4P3P2P1P0,c0);
  wire t28a,t28b;
  or  o281(t28a, G[6], P6G5, P6P5G4, P6P5P4G3);
  or  o282(t28b, P6P5P4P3G2, P6P5P4P3P2G1, P6P5P4P3P2P1G0, P6P5P4P3P2P1P0c0);
  or  o283(c28, t28a, t28b);

  wire P7G6,P7P6,P7P6G5,P7P6P5,P7P6P5G4,P7P6P5P4,P7P6P5P4G3,P7P6P5P4P3,P7P6P5P4P3G2,P7P6P5P4P3P2,P7P6P5P4P3P2G1,P7P6P5P4P3P2P1,P7P6P5P4P3P2P1G0,P7P6P5P4P3P2P1P0,P7P6P5P4P3P2P1P0c0;
  and a320(P7G6,P[7],G[6]); 
  and a321(P7P6,P[7],P[6]); 
  and a322(P7P6G5,P7P6,G[5]);
  and a323(P7P6P5,P7P6,P[5]); 
  and a324(P7P6P5G4,P7P6P5,G[4]);
  and a325(P7P6P5P4,P7P6P5,P[4]); 
  and a326(P7P6P5P4G3,P7P6P5P4,G[3]);
  and a327(P7P6P5P4P3,P7P6P5P4,P[3]); 
  and a328(P7P6P5P4P3G2,P7P6P5P4P3,G[2]);
  and a329(P7P6P5P4P3P2,P7P6P5P4P3,P[2]); 
  and a32A(P7P6P5P4P3P2G1,P7P6P5P4P3P2,G[1]);
  and a32B(P7P6P5P4P3P2P1,P7P6P5P4P3P2,P[1]); 
  and a32C(P7P6P5P4P3P2P1G0,P7P6P5P4P3P2P1,G[0]);
  and a32D(P7P6P5P4P3P2P1P0,P7P6P5P4P3P2P1,P[0]); 
  and a32E(P7P6P5P4P3P2P1P0c0,P7P6P5P4P3P2P1P0,c0);

  wire t32a,t32b,t32c,t32d;
  or  o321(t32a, G[7], P7G6, P7P6G5, P7P6P5G4);
  or  o322(t32b, P7P6P5P4G3, P7P6P5P4P3G2, P7P6P5P4P3P2G1, P7P6P5P4P3P2P1G0);
  or  o323(t32c, P7P6P5P4P3P2P1P0c0);
  or  o324(t32d, t32a, t32b);
  or  o325(c32, t32d, t32c);

  assign Cout = c32;
endmodule
