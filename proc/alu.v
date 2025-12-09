module alu(data_operandA, data_operandB, ctrl_ALUopcode, 
ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);

  input  [31:0] data_operandA, data_operandB; 
  input  [4:0]  ctrl_ALUopcode, ctrl_shiftamt;
  output [31:0] data_result;
  output        isNotEqual, isLessThan, overflow;

  wire selADD, selSUB, selAND, selOR, selSLL, selSRA;
  decode_6ops DEC(ctrl_ALUopcode, selADD, selSUB, selAND, selOR, selSLL, selSRA);

  wire [31:0] and_res, or_res;
  and32 U_AND(and_res, data_operandA, data_operandB);
  or32  U_OR (or_res,  data_operandA, data_operandB);

  wire [31:0] sll_res, sra_res;
  sll U_SLL(sll_res, data_operandA, ctrl_shiftamt);
  sra U_SRA(sra_res, data_operandA, ctrl_shiftamt);

  wire [31:0] add_sum, sub_sum;
  wire add_cout, sub_cout;
  cla_32 ADD32(add_sum, add_cout, data_operandA, data_operandB, 1'b0);

  wire [31:0] nB;
  not32 N32(nB, data_operandB);
  cla_32 SUB32(sub_sum, sub_cout, data_operandA, nB, 1'b1);

  wire a31_xor_b31, not_a31_xor_b31, add_s31_xor_a31, add_overflow;
  xor X01(a31_xor_b31, data_operandA[31], data_operandB[31]);
  not N01(not_a31_xor_b31, a31_xor_b31);
  xor X02(add_s31_xor_a31, add_sum[31], data_operandA[31]);
  and AOVF(add_overflow, not_a31_xor_b31, add_s31_xor_a31);

  wire sub_s31_xor_a31, sub_overflow;
  xor X03(sub_s31_xor_a31, sub_sum[31], data_operandA[31]);
  and SOVF(sub_overflow, a31_xor_b31, sub_s31_xor_a31);

  wire [31:0] addsub_res, logic_res, shift_res, sum_vs_logic;
  mux_2 M_ADD_SUB(addsub_res, selSUB, add_sum,  sub_sum);
  mux_2 M_AND_OR (logic_res,  selOR,  and_res,  or_res );
  mux_2 M_SLL_SRA(shift_res,  selSRA, sll_res,  sra_res);

  wire selLOGIC, selSHIFT;
  or OSEL1(selLOGIC, selAND, selOR);
  or OSEL2(selSHIFT, selSLL, selSRA);

  mux_2 M_SUM_VS_LOGIC(sum_vs_logic, selLOGIC, addsub_res, logic_res);
  mux_2 M_FINAL (data_result,  selSHIFT,  sum_vs_logic, shift_res);

  wire [15:0] l16;
  or O0 (l16[0],  sub_sum[0],  sub_sum[1]);
  or O1 (l16[1],  sub_sum[2],  sub_sum[3]);
  or O2 (l16[2],  sub_sum[4],  sub_sum[5]);
  or O3 (l16[3],  sub_sum[6],  sub_sum[7]);
  or O4 (l16[4],  sub_sum[8],  sub_sum[9]);
  or O5 (l16[5],  sub_sum[10], sub_sum[11]);
  or O6 (l16[6],  sub_sum[12], sub_sum[13]);
  or O7 (l16[7],  sub_sum[14], sub_sum[15]);
  or O8 (l16[8],  sub_sum[16], sub_sum[17]);
  or O9 (l16[9],  sub_sum[18], sub_sum[19]);
  or O10(l16[10], sub_sum[20], sub_sum[21]);
  or O11(l16[11], sub_sum[22], sub_sum[23]);
  or O12(l16[12], sub_sum[24], sub_sum[25]);
  or O13(l16[13], sub_sum[26], sub_sum[27]);
  or O14(l16[14], sub_sum[28], sub_sum[29]);
  or O15(l16[15], sub_sum[30], sub_sum[31]);

  wire [7:0] l8;
  or O16(l8[0], l16[0], l16[1]);
  or O17(l8[1], l16[2], l16[3]);
  or O18(l8[2], l16[4], l16[5]);
  or O19(l8[3], l16[6], l16[7]);
  or O20(l8[4], l16[8], l16[9]);
  or O21(l8[5], l16[10], l16[11]);
  or O22(l8[6], l16[12], l16[13]);
  or O23(l8[7], l16[14], l16[15]);

  wire [3:0] l4;
  or O24(l4[0], l8[0], l8[1]);
  or O25(l4[1], l8[2], l8[3]);
  or O26(l4[2], l8[4], l8[5]);
  or O27(l4[3], l8[6], l8[7]);

  wire [1:0] l2;
  or O28(l2[0], l4[0], l4[1]);
  or O29(l2[1], l4[2], l4[3]);

  or O30(isNotEqual, l2[0], l2[1]);

  wire n_sub_s31, n_ovf, lt_path1, lt_path2;
  not NLT1(n_sub_s31, sub_sum[31]);
  not NLT2(n_ovf, sub_overflow);
  and ALT1(lt_path1, sub_overflow, n_sub_s31);
  and ALT2(lt_path2, n_ovf, sub_sum[31]);
  or  OLT (isLessThan, lt_path1, lt_path2);

  wire ovf_add_path, ovf_sub_path;
  and AOF(ovf_add_path, selADD, add_overflow);
  and SOF(ovf_sub_path, selSUB, sub_overflow);
  or  OOF(overflow, ovf_add_path, ovf_sub_path);

endmodule
