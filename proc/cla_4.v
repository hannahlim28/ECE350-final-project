module cla_4(output [3:0] sum, output Cout, output P, output G, 
input  [3:0] a, b,input Cin);

    wire [3:0] p, g;

    xor XP0(p[0], a[0], b[0]);  
    and XG0(g[0], a[0], b[0]);
    xor XP1(p[1], a[1], b[1]); 
    and XG1(g[1], a[1], b[1]);
    xor XP2(p[2], a[2], b[2]);  
    and XG2(g[2], a[2], b[2]);
    xor XP3(p[3], a[3], b[3]); 
    and XG3(g[3], a[3], b[3]);

    wire c1, c2, c3;

    wire p0Cin;  

    and A10(p0Cin, p[0], Cin);
    or  O10(c1, g[0], p0Cin);

    wire p1g0, p1p0, p1p0Cin;

    and A20(p1g0, p[1], g[0]);
    and A21(p1p0, p[1], p[0]);
    and A22(p1p0Cin, p1p0, Cin);
    or  O20(c2, g[1], p1g0, p1p0Cin);

    wire p2g1, p2p1, p2p1g0, p2p1p0, p2p1p0Cin;
    and A30(p2g1, p[2], g[1]);
    and A31(p2p1, p[2], p[1]);
    and A32(p2p1g0, p2p1, g[0]);
    and A33(p2p1p0, p2p1, p[0]);
    and A34(p2p1p0Cin, p2p1p0, Cin);
    or  O30(c3, g[2], p2g1, p2p1g0, p2p1p0Cin);

    wire p3g2, p3p2, p3p2g1, p3p2p1, p3p2p1g0, p3p2p1p0, p3p2p1p0Cin;
    and A40(p3g2, p[3], g[2]);
    and A41(p3p2,  p[3], p[2]);
    and A42(p3p2g1, p3p2, g[1]);
    and A43(p3p2p1, p3p2, p[1]);
    and A44(p3p2p1g0, p3p2p1, g[0]);
    and A45(p3p2p1p0, p3p2p1, p[0]);
    and A46(p3p2p1p0Cin, p3p2p1p0, Cin);
    or  O40(Cout, g[3], p3g2, p3p2g1, p3p2p1g0, p3p2p1p0Cin);

    xor S0(sum[0], p[0], Cin);
    xor S1(sum[1], p[1], c1);
    xor S2(sum[2], p[2], c2);
    xor S3(sum[3], p[3], c3);

    wire p01, p23;
    and AP1(p01, p[0], p[1]);
    and AP2(p23, p[2], p[3]);
    and AP3(P,   p01,  p23);

    wire t_p3g2, t_p3p2g1, t_p3p2p1g0, t_or1;
    and AG1(t_p3g2,       p[3],     g[2]);
    and AG2(t_p3p2g1,     p3p2,     g[1]);   
    and AG3(t_p3p2p1g0,   p3p2p1,   g[0]);   
    or  OG1(t_or1, g[3], t_p3g2, t_p3p2g1);
    or  OG2(G, t_or1, t_p3p2p1g0);
    endmodule









    