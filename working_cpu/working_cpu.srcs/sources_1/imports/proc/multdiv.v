module multdiv(
    data_operandA, data_operandB, 
    ctrl_MULT, ctrl_DIV, 
    clock, 
    data_result, data_exception, data_resultRDY);

    // INPUTS
    input  [31:0] data_operandA, data_operandB;
    input  ctrl_MULT, ctrl_DIV, clock;

    // OUTPUTS
    output [31:0] data_result;
    output data_exception, data_resultRDY;

    // Start pulses 
    wire start_mult = ctrl_MULT & ~ctrl_DIV;  // start multiplying only if MULT is on, not DIV 
    wire start_div  = ctrl_DIV  & ~ctrl_MULT; // Start dividing only if DIV pressed, not MULT

    // Mode latches 
    wire on_mult, on_div;
    dffe_ref mult_mode (on_mult, ctrl_MULT, clock, ctrl_MULT, ctrl_DIV);
    dffe_ref div_mode (on_div , ctrl_DIV , clock, ctrl_DIV , ctrl_MULT);

    // Operand latches
    wire latch_ops = start_mult | start_div;

    wire [31:0] dreg_A, dreg_B;
    reg1 #(32) Areg(.q(dreg_A), .d(data_operandA), .clk(clock), .we(latch_ops), .rst(1'b0));
    reg1 #(32) Breg(.q(dreg_B), .d(data_operandB), .clk(clock), .we(latch_ops), .rst(1'b0));

    // MULTIPLICATION 
    wire [3:0]  mcount;
    wire  done_mult;

    // Count while in mult mode and not done
    count_16 mult_counter(clock, (on_mult & ~done_mult), mcount, ctrl_MULT );

    // Latch done as (&mcount), clear only on new MULT start (mirror friend)
    dffe_ref mdone_ff(done_mult, &mcount, clock, 1'b1, ctrl_MULT);

    // MULTIPLICATION
    wire [65:0] product, add_output, shifted_output;
    
    // Sign-extended multiplicand (A)
    wire [32:0] Mext = {dreg_A[31], dreg_A};
    wire [32:0] Mx1  = Mext;
    wire [32:0] Mx2  = {Mext[31:0], 1'b0};  // 2*A 

    // Initialize on first mult cycle: Q <= B, Qm1 <= 0, ACC <= 0
    wire [65:0] mult_init = {33'b0, dreg_B, 1'b0};
    wire first_mult_cycle = (mcount == 4'b0000);
    wire [65:0] mult_cycle_input = first_mult_cycle ? mult_init : product;

    // Booth select = {Q1,Q0,Qm1}
    wire [2:0] sel = mult_cycle_input[2:0];

    // Magnitude to add (positive table)
    wire [32:0] Ppos;
    mux_8 #(33) booth_mag(.out(Ppos), .select(sel), .in0(33'b0), .in1(Mx1), .in2(Mx1), .in3(Mx2), .in4(Mx2), .in5(Mx1), .in6(Mx1), .in7(33'b0));

    // Negative cases: 100, 101, 110 => two's-complement negate via XOR + Cin=1
    wire negSel = sel[2] & ~(&sel);
    wire [32:0] Pmag  = Ppos ^ {33{negSel}};
    wire addCin = negSel;

    // Add into ACC upper 33 bits (lower 32 via adder + manual MSB)
    wire [31:0] acc_sum_lo;
    wire acc_cout, ov_unused0;
    carry_adder acc_add( .A(mult_cycle_input[64:33]), .B(Pmag[31:0]), .S(acc_sum_lo), .overflow(ov_unused0), .Cin(addCin), .Cout(acc_cout));
    wire acc_msb = mult_cycle_input[65] ^ Pmag[32] ^ acc_cout;

    // Recompose pre-shift
    assign add_output[65]  = acc_msb;
    assign add_output[64:33] = acc_sum_lo;
    assign add_output[32:0]  = mult_cycle_input[32:0];

    // Arithmetic right shift by 2 (radix-4)
    assign shifted_output[65:64] = {add_output[65], add_output[65]};
    assign shifted_output[63:0]  = add_output[65:2];

    // Product register: update while not done (mirror friend: en = ~done_mult)
    wire mult_reg_en = on_mult & ~done_mult;
    register #(66) product_reg( .enable(mult_reg_en), .clock(clock), .data_in(shifted_output), .clear(1'b0), .data_out(product));

    // Final mult outputs (consistent with your & friend’s slice)
    wire [65:0] prod_final = product;
    wire [31:0] mult_data_result = prod_final[32:1];
    wire multdata_exception = |(prod_final[65:33] ^ {33{prod_final[32]}});

    // DIVISION 
    wire [4:0] dcount;
    wire done_div;
    count_32 div_counter(clock, (on_div & ~done_div), dcount, ctrl_DIV);
    dffe_ref ddone_ff(done_div,&dcount,clock, 1'b1,ctrl_DIV);

    // DIVISION (non-restoring) – DATAPATH
    // rq = {R[31:0], Q[31:0]}
    wire [63:0] rq, rq_after_add, rq_shift;

    // abs(A), abs(B)
    wire [31:0] a_xor = dreg_A ^ {32{dreg_A[31]}};
    wire [31:0] b_xor = dreg_B ^ {32{dreg_B[31]}};
    wire [31:0] a_abs, b_abs;
    wire ovu1, ovu2, cou1, cou2;
    carry_adder absA(.A(a_xor), .B(32'b0), .S(a_abs), .overflow(ovu1), .Cin(dreg_A[31]), .Cout(cou1));
    carry_adder absB(.A(b_xor), .B(32'b0), .S(b_abs), .overflow(ovu2), .Cin(dreg_B[31]), .Cout(cou2));

    // Initialize {R,Q} = {0, |A|}
    wire [63:0] rq_init = {32'b0, a_abs};
    wire first_div_cycle = (dcount == 5'b00000);
    wire [63:0] rq_in = first_div_cycle ? rq_init : rq;

    // Shift left by 1
    assign rq_shift = {rq_in[62:0], 1'b0};

    // Non-restoring step: if R<0 then R=R+|B| else R=R-|B|
    wire rem_neg = rq_shift[63];
    wire [31:0] Bsel = rem_neg ? b_abs : ~b_abs;
    wire Cins = rem_neg ? 1'b0 : 1'b1;

    wire [31:0] r_sum; 
    wire cou3, ovu3;
    carry_adder radd(.A(rq_shift[63:32]), .B(Bsel), .S(r_sum), .overflow(ovu3), .Cin(Cins), .Cout(cou3));

    // Build next {R,Q} and set Q0 based on sign of new remainder
    assign rq_after_add[63:32] = r_sum;
    assign rq_after_add[31:1]  = rq_shift[31:1];
    assign rq_after_add[0] = ~r_sum[31];

    // Quotient/remainder register: update while not done (mirror friend)
    register #(64) rq_reg(.enable(on_div & ~done_div), .clock(clock), .data_in(rq_after_add), .clear(1'b0), .data_out(rq));

    // Final sign corrections
    wire q_neg = dreg_A[31] ^ dreg_B[31];
    wire r_neg = dreg_A[31];

    // Quotient 
    wire [31:0] q_xor = rq[31:0] ^ {32{q_neg}};
    wire [31:0] q_fix; wire cou4, ovu4;
    carry_adder qfix(.A(q_xor), .B(32'b0), .S(q_fix), .overflow(ovu4), .Cin(q_neg), .Cout(cou4));

    // remainder 
    wire [31:0] r_xor = rq[63:32] ^ {32{r_neg}};
    wire [31:0] r_fix; wire cou5, ovu5;
    carry_adder rfix(.A(r_xor), .B(32'b0), .S(r_fix), .overflow(ovu5), .Cin(r_neg), .Cout(cou5));

    // Division outputs
    wire [31:0] div_data_result = (|dreg_B) ? q_fix : 32'b0;
    wire  divdata_exception = ~|dreg_B;

    // Final multiplex + ready
    wire [31:0] data_out  = on_div ? div_data_result : mult_data_result;
    wire except_out = on_div ? divdata_exception : multdata_exception;

    assign data_result   = data_out;
    assign data_exception = except_out;

    // Registered ready pulse, cleared by any new start
    wire ready_d = (on_mult & done_mult) | (on_div & done_div);
    //assign data_resultRDY = (ctrl_MULT | ctrl_DIV) ? 1'b0 : ready_d;
    dffe_ref ready_ff(data_resultRDY, ready_d, clock, 1'b1, (ctrl_MULT | ctrl_DIV));

endmodule