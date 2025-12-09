module regfile (
	clock, 
	ctrl_writeEnable, 
	ctrl_reset, 
	ctrl_writeReg, 
	ctrl_readRegA, 
	ctrl_readRegB,
 	data_writeReg,
	data_readRegA, 
	data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	output [31:0] data_readRegA, data_readRegB;

	wire [31:0] wSel; 
	wire [31:0] rSelA; 
	wire [31:0] rSelB; 

	decoder5to32 DEC_W (wSel, ctrl_writeReg, ctrl_writeEnable);
	decoder5to32 DEC_A (rSelA, ctrl_readRegA, 1'b1);
	decoder5to32 DEC_B (rSelB, ctrl_readRegB, 1'b1);


	wire [31:0] r0,  r1,  r2,  r3,  r4,  r5,  r6,  r7, r8,  r9,  r10, r11, r12, r13, r14, r15, r16, r17, r18, r19, r20, r21, r22, r23, r24, r25, r26, r27, r28, r29, r30, r31;

	assign r0 = 32'b0; 

	reg1 REG1  (r1, data_writeReg, clock, wSel[1], ctrl_reset);
    reg1 REG2  (r2 , data_writeReg, clock, wSel[2], ctrl_reset);
    reg1 REG3  (r3 , data_writeReg, clock, wSel[3], ctrl_reset);
    reg1 REG4  (r4 , data_writeReg, clock, wSel[4], ctrl_reset);
    reg1 REG5  (r5 , data_writeReg, clock, wSel[5], ctrl_reset);
    reg1 REG6  (r6 , data_writeReg, clock, wSel[6], ctrl_reset);
    reg1 REG7  (r7 , data_writeReg, clock, wSel[7], ctrl_reset);
    reg1 REG8  (r8 , data_writeReg, clock, wSel[8], ctrl_reset);
    reg1 REG9  (r9 , data_writeReg, clock, wSel[9], ctrl_reset);
    reg1 REG10 (r10 , data_writeReg, clock, wSel[10], ctrl_reset);
    reg1 REG11 (r11 , data_writeReg, clock, wSel[11], ctrl_reset);
    reg1 REG12 (r12 , data_writeReg, clock, wSel[12], ctrl_reset);
    reg1 REG13 (r13 , data_writeReg, clock, wSel[13], ctrl_reset);
    reg1 REG14 (r14 , data_writeReg, clock, wSel[14], ctrl_reset);
    reg1 REG15 (r15 , data_writeReg, clock, wSel[15], ctrl_reset);
    reg1 REG16 (r16 , data_writeReg, clock, wSel[16], ctrl_reset);
    reg1 REG17 (r17 , data_writeReg, clock, wSel[17], ctrl_reset);
    reg1 REG18 (r18 , data_writeReg, clock, wSel[18], ctrl_reset);
    reg1 REG19 (r19 , data_writeReg, clock, wSel[19], ctrl_reset);
    reg1 REG20 (r20 , data_writeReg, clock, wSel[20], ctrl_reset);
    reg1 REG21 (r21 , data_writeReg, clock, wSel[21], ctrl_reset);
    reg1 REG22 (r22 , data_writeReg, clock, wSel[22], ctrl_reset);
    reg1 REG23 (r23 , data_writeReg, clock, wSel[23], ctrl_reset);
    reg1 REG24 (r24 , data_writeReg, clock, wSel[24], ctrl_reset);
    reg1 REG25 (r25 , data_writeReg, clock, wSel[25], ctrl_reset);
    reg1 REG26 (r26 , data_writeReg, clock, wSel[26], ctrl_reset);
    reg1 REG27 (r27 , data_writeReg, clock, wSel[27], ctrl_reset);
    reg1 REG28 (r28 , data_writeReg, clock, wSel[28], ctrl_reset);
    reg1 REG29 (r29 , data_writeReg, clock, wSel[29], ctrl_reset);
    reg1 REG30 (r30 , data_writeReg, clock, wSel[30], ctrl_reset);
    reg1 REG31 (r31 , data_writeReg, clock, wSel[31], ctrl_reset);

    assign data_readRegA = rSelA[0]  ? r0  : 32'bz;
    assign data_readRegA = rSelA[1]  ? r1  : 32'bz;
    assign data_readRegA = rSelA[2]  ? r2  : 32'bz;
    assign data_readRegA = rSelA[3]  ? r3  : 32'bz;
    assign data_readRegA = rSelA[4]  ? r4  : 32'bz;
    assign data_readRegA = rSelA[5]  ? r5  : 32'bz;
    assign data_readRegA = rSelA[6]  ? r6  : 32'bz;
    assign data_readRegA = rSelA[7]  ? r7  : 32'bz;
    assign data_readRegA = rSelA[8]  ? r8  : 32'bz;
    assign data_readRegA = rSelA[9]  ? r9  : 32'bz;
    assign data_readRegA = rSelA[10] ? r10 : 32'bz;
    assign data_readRegA = rSelA[11] ? r11 : 32'bz;
    assign data_readRegA = rSelA[12] ? r12 : 32'bz;
    assign data_readRegA = rSelA[13] ? r13 : 32'bz;
    assign data_readRegA = rSelA[14] ? r14 : 32'bz;
    assign data_readRegA = rSelA[15] ? r15 : 32'bz;
    assign data_readRegA = rSelA[16] ? r16 : 32'bz;
    assign data_readRegA = rSelA[17] ? r17 : 32'bz;
    assign data_readRegA = rSelA[18] ? r18 : 32'bz;
    assign data_readRegA = rSelA[19] ? r19 : 32'bz;
    assign data_readRegA = rSelA[20] ? r20 : 32'bz;
    assign data_readRegA = rSelA[21] ? r21 : 32'bz;
    assign data_readRegA = rSelA[22] ? r22 : 32'bz;
    assign data_readRegA = rSelA[23] ? r23 : 32'bz;
    assign data_readRegA = rSelA[24] ? r24 : 32'bz;
    assign data_readRegA = rSelA[25] ? r25 : 32'bz;
    assign data_readRegA = rSelA[26] ? r26 : 32'bz;
    assign data_readRegA = rSelA[27] ? r27 : 32'bz;
    assign data_readRegA = rSelA[28] ? r28 : 32'bz;
    assign data_readRegA = rSelA[29] ? r29 : 32'bz;
    assign data_readRegA = rSelA[30] ? r30 : 32'bz;
    assign data_readRegA = rSelA[31] ? r31 : 32'bz;

    assign data_readRegB = rSelB[0]  ? r0  : 32'bz;
    assign data_readRegB = rSelB[1]  ? r1  : 32'bz;
    assign data_readRegB = rSelB[2]  ? r2  : 32'bz;
    assign data_readRegB = rSelB[3]  ? r3  : 32'bz;
    assign data_readRegB = rSelB[4]  ? r4  : 32'bz;
    assign data_readRegB = rSelB[5]  ? r5  : 32'bz;
    assign data_readRegB = rSelB[6]  ? r6  : 32'bz;
    assign data_readRegB = rSelB[7]  ? r7  : 32'bz;
    assign data_readRegB = rSelB[8]  ? r8  : 32'bz;
    assign data_readRegB = rSelB[9]  ? r9  : 32'bz;
    assign data_readRegB = rSelB[10] ? r10 : 32'bz;
    assign data_readRegB = rSelB[11] ? r11 : 32'bz;
    assign data_readRegB = rSelB[12] ? r12 : 32'bz;
    assign data_readRegB = rSelB[13] ? r13 : 32'bz;
    assign data_readRegB = rSelB[14] ? r14 : 32'bz;
    assign data_readRegB = rSelB[15] ? r15 : 32'bz;
    assign data_readRegB = rSelB[16] ? r16 : 32'bz;
    assign data_readRegB = rSelB[17] ? r17 : 32'bz;
    assign data_readRegB = rSelB[18] ? r18 : 32'bz;
    assign data_readRegB = rSelB[19] ? r19 : 32'bz;
    assign data_readRegB = rSelB[20] ? r20 : 32'bz;
    assign data_readRegB = rSelB[21] ? r21 : 32'bz;
    assign data_readRegB = rSelB[22] ? r22 : 32'bz;
    assign data_readRegB = rSelB[23] ? r23 : 32'bz;
    assign data_readRegB = rSelB[24] ? r24 : 32'bz;
    assign data_readRegB = rSelB[25] ? r25 : 32'bz;
    assign data_readRegB = rSelB[26] ? r26 : 32'bz;
    assign data_readRegB = rSelB[27] ? r27 : 32'bz;
    assign data_readRegB = rSelB[28] ? r28 : 32'bz;
    assign data_readRegB = rSelB[29] ? r29 : 32'bz;
    assign data_readRegB = rSelB[30] ? r30 : 32'bz;
    assign data_readRegB = rSelB[31] ? r31 : 32'bz;
endmodule