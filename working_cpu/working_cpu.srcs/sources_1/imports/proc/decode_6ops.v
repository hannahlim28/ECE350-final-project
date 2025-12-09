module decode_6ops(
    input  [4:0] op,
    output       selADD,
    output       selSUB,
    output       selAND,
    output       selOR,
    output       selSLL,
    output       selSRA

);

  assign selADD = ~op[4] & ~op[3] & ~op[2] & ~op[1] & ~op[0]; //00000
  assign selSUB = ~op[4] & ~op[3] & ~op[2] & ~op[1] & op[0]; //00001
  assign selAND = ~op[4] & ~op[3] & ~op[2] & op[1] & ~op[0]; //00010
  assign selOR  = ~op[4] & ~op[3] & ~op[2] & op[1] & op[0]; //00011
  assign selSLL = ~op[4] & ~op[3] & op[2] & ~op[1] & ~op[0]; //00100
  assign selSRA = ~op[4] & ~op[3] & op[2] & ~op[1] & op[0]; //00101

endmodule