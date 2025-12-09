/**
 * READ THIS DESCRIPTION!
 *
 * This is your processor module that will contain the bulk of your code submission. You are to implement
 * a 5-stage pipelined processor in this module, accounting for hazards and implementing bypasses as
 * necessary.
 *
 * Ultimately, your processor will be tested by a master skeleton, so the
 * testbench can see which controls signal you active when. Therefore, there needs to be a way to
 * "inject" imem, dmem, and regfile interfaces from some external controller module. The skeleton
 * file, Wrapper.v, acts as a small wrapper around your processor for this purpose. Refer to Wrapper.v
 * for more details.
 *
 * As a result, this module will NOT contain the RegFile nor the memory modules. Study the inputs 
 * very carefully - the RegFile-related I/Os are merely signals to be sent to the RegFile instantiated
 * in your Wrapper module. This is the same for your memory elements. 
 *
 *
 */
module processor(
    // Control signals
    clock, reset, gcode_stall, 
    // Imem
    address_imem, q_imem,
    // Dmem
    address_dmem, data,wren,q_dmem,
    // Regfile
    ctrl_writeEnable, ctrl_writeReg, ctrl_readRegA, ctrl_readRegB, data_writeReg, data_readRegA, data_readRegB);

    input  clock, reset;
    input gcode_stall; 
    // Imem
    output [31:0] address_imem;
    input  [31:0] q_imem;
    // Dmem
    output [31:0] address_dmem, data;
    output  wren;
    input  [31:0] q_dmem;
    // Regfile
    output  ctrl_writeEnable;
    output [4:0]  ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
    output [31:0] data_writeReg;
    input  [31:0] data_readRegA, data_readRegB;
    
    wire clk_inverted;
    not NOT_CLK(clk_inverted, clock);

    wire front_en; 
    wire xm_en;   
    wire stall; 
    wire md_stall; 

// STAGE 1: FETCH 
    wire [31:0] pc; //current PC values
    wire [31:0] pc_next; //next PC value
    wire [31:0] pc_plus_1; //pc + 1 sequential 
    alu pc_incrementer(.data_operandA(pc), .data_operandB(32'd1), .ctrl_ALUopcode(5'b00000), .ctrl_shiftamt(5'b00000), .data_result(pc_plus_1), .isNotEqual(), .isLessThan(), .overflow());
    dffe_ref pc_reg[31:0](.q(pc), .d(pc_next), .clk(clock), .en(front_en  & md_stall), .clr(reset));
    assign address_imem = pc;

// (F/D LATCH) FETCH -> DECODE 
    wire [31:0] fd_insn;
    wire [31:0] fd_pc;
    dffe_ref fd_insn_reg[31:0](.q(fd_insn), .d(q_imem), .clk(clk_inverted), .en(front_en & md_stall), .clr(1'b0));
    dffe_ref fd_pc_reg[31:0](.q(fd_pc), .d(pc), .clk(clk_inverted), .en(front_en & md_stall), .clr(1'b0));
    // F/D PC + 1 Calculation for branches 
    wire [31:0] fd_pc_plus_1;
    alu fd_pc_incrementer(.data_operandA(fd_pc), .data_operandB(32'd1), .ctrl_ALUopcode(5'b00000), .ctrl_shiftamt(5'b00000), .data_result(fd_pc_plus_1), .isNotEqual(), .isLessThan(), .overflow());

    wire fd_reads_rs = is_r_type | is_addi | is_bne | is_blt | is_lw | is_sw | is_jr;  // bex uses r30 via mux
    wire fd_reads_rt = is_r_type | is_bne | is_blt | is_sw;     // addi/lw dont read rt

// STAGE 2: DECODE 
    wire [4:0] opcode; 
    assign opcode = fd_insn[31:27];
    wire [4:0] rd; 
    assign rd = fd_insn[26:22];
    wire [4:0] rs; 
    assign rs = fd_insn[21:17];
    wire [4:0] rt; 
    assign rt = fd_insn[16:12];
    wire [4:0] shamt; 
    assign shamt = fd_insn[11:7];
    wire [4:0] alu_op; 
    assign alu_op = fd_insn[6:2];
    wire [16:0] imm_raw; 
    assign imm_raw = fd_insn[16:0];
    wire [31:0] immediate; 
    assign immediate = {{15{imm_raw[16]}}, imm_raw};
    wire [31:0] jump_target; 
    assign jump_target = {5'b00000, fd_insn[26:0]};

// opcode decodes
    wire is_r_type = (~opcode[4] & ~opcode[3] & ~opcode[2] & ~opcode[1] & ~opcode[0]); // 00000
    wire is_j = (~opcode[4] & ~opcode[3] & ~opcode[2] & ~opcode[1] &  opcode[0]); // 00001
    wire is_bne = (~opcode[4] & ~opcode[3] & ~opcode[2] &  opcode[1] & ~opcode[0]); // 00010
    wire is_jal = (~opcode[4] & ~opcode[3] & ~opcode[2] &  opcode[1] &  opcode[0]); // 00011
    wire is_jr = (~opcode[4] & ~opcode[3] &  opcode[2] & ~opcode[1] & ~opcode[0]); // 00100
    wire is_addi = (~opcode[4] & ~opcode[3] &  opcode[2] & ~opcode[1] &  opcode[0]); // 00101
    wire is_blt = (~opcode[4] & ~opcode[3] &  opcode[2] &  opcode[1] & ~opcode[0]); // 00110
    wire is_sw  = (~opcode[4] & ~opcode[3] &  opcode[2] &  opcode[1] &  opcode[0]); // 00111
    wire is_lw = (~opcode[4] &  opcode[3] & ~opcode[2] & ~opcode[1] & ~opcode[0]); // 01000
    wire is_setx = (opcode[4] & ~opcode[3] &  opcode[2] & ~opcode[1] &  opcode[0]); // 10101
    wire is_bex = (opcode[4] & ~opcode[3] &  opcode[2] &  opcode[1] & ~opcode[0]); // 10110 
    wire is_mult_op = is_r_type & (~alu_op[4] & ~alu_op[3] &  alu_op[2] &  alu_op[1] & ~alu_op[0]); // 00110
    wire is_div_op = is_r_type & (~alu_op[4] & ~alu_op[3] &  alu_op[2] &  alu_op[1] &  alu_op[0]); // 00111

 //register read mux (which register should I read) 
    assign ctrl_readRegA = is_bex ? 5'd30 : (is_bne | is_blt | is_jr) ? rd  : rs ;
    assign ctrl_readRegB = (is_bne | is_blt) ? rs : (is_sw) ? rd : (is_lw) ? rs : rt ;
    
    // branch target calculation (PC + immediate)
    wire [31:0] branch_target;
    alu branch_target_adder( .data_operandA(pc), .data_operandB(immediate), .ctrl_ALUopcode(5'b00000), .ctrl_shiftamt(5'b00000), .data_result(branch_target), .isNotEqual(), .isLessThan(), .overflow());
    // branch condiiton comparison
    wire cmp_isNotEqual, cmp_isLessThan;
    wire [31:0] readA_value, readB_value; 
    alu branch_cmp_alu( .data_operandA(readA_value), .data_operandB(readB_value), .ctrl_ALUopcode(5'b00001), .ctrl_shiftamt(5'b00000), .data_result(), .isNotEqual(cmp_isNotEqual), .isLessThan(cmp_isLessThan), .overflow());
    // branch jump decisions 
    wire take_bne; // Should we take BNE branch?
    assign take_bne = is_bne & cmp_isNotEqual;
    wire take_blt; // Should we take BLT branch?
    assign take_blt = is_blt & cmp_isLessThan;
    wire branch_taken;  // Any branch taken?
    assign branch_taken = take_bne | take_blt;
    wire bex_taken; // Is BEX branch taken?
    assign bex_taken = is_bex & (readA_value != 32'b0);
    wire [31:0] jr_target; // Target for JR instruction
    assign jr_target = readA_value;
    // PC next selection (MUX for control flow)
    assign pc_next = fd_valid ? (is_jr ? jr_target : (is_j | is_jal) ? jump_target : bex_taken ? jump_target : branch_taken ? branch_target : pc_plus_1) : pc_plus_1;

// kill Fetch signal 
    wire dx_is_branch_or_bex = dx_is_bne | dx_is_blt | dx_is_bex;

    wire kill_fetch; // When true, the next F/D instruction becomes a NOP
    assign kill_fetch = (is_jr | is_j | is_jal | bex_taken | branch_taken) & ~dx_is_branch_or_bex;

    wire fd_valid;
    dffe_ref fd_valid_reg( .q(fd_valid), .d(~kill_fetch & front_en), .clk(clk_inverted), .en(front_en & md_stall), .clr(reset)); 
    // When kill_fetch = 1 (branching), dx_valid gets 0 (NOP)
    // When kill_fetch = 0 (normal), dx_valid gets 1 (valid) 

// DECODE -> EXECUTE (DX latch)  
    wire [31:0] dx_rs_value;
    wire [31:0] dx_rt_value;
    wire [4:0]  dx_rd;
    wire [4:0]  dx_rs;      
    wire [4:0]  dx_rt; 
    // wire[14:0] dx_rdrsrt_input;
    // assign dx_rdrsrt_input = stall ? 15'b0 : {rd, rs, rt};     
    wire [4:0]  dx_alu_op;
    wire [4:0]  dx_shamt;
    wire [31:0] dx_immediate;
    wire [31:0] dx_link_addr;
    wire [31:0] dx_setx_val;

    wire dx_is_r_type;
    wire dx_is_addi;
    wire dx_is_lw;
    wire dx_is_sw;
    wire dx_is_jal;
    wire dx_is_jr; 
    wire dx_is_mult;
    wire dx_is_div;
    wire dx_is_setx;

    wire dx_is_bne;
    wire dx_is_blt;
    wire dx_is_bex;

    // Latch exception flags into DX for forwarding
    wire [31:0] ex_rstatus_code; /* What exception code? */ 
    wire dx_set_rstatus;
    wire [31:0] dx_rstatus_code;
    wire ex_set_rstatus; /* Should we write to R30? */ 

    wire dx_valid; //is valid instruction (not NOP)?
    dffe_ref dx_valid_reg(.q(dx_valid), .d(stall ? 1'b0 : fd_valid), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(reset));
    dffe_ref dx_rs_val_reg[31:0](.q(dx_rs_value), .d(stall ? 32'b0 : readA_value), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_rt_val_reg[31:0](.q(dx_rt_value), .d(stall ? 32'b0 : readB_value), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_rd_reg[4:0](.q(dx_rd), .d(stall ? 5'b0 : rd), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0) );
    dffe_ref dx_rs_reg[4:0](.q(dx_rs), .d(stall ? 5'b0 : rs), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0) );  
    dffe_ref dx_rt_reg[4:0](.q(dx_rt), .d(stall ? 5'b0 : rt), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0) );  
    dffe_ref dx_alu_op_reg[4:0](.q(dx_alu_op), .d(stall ? 5'b0 : alu_op), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_shamt_reg[4:0](.q(dx_shamt), .d(stall ? 5'b0 : shamt), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0) );
    dffe_ref dx_imm_reg[31:0](.q(dx_immediate),.d(stall ? 32'b0 : immediate),.clk(clk_inverted),.en((front_en | stall) & md_stall),.clr(1'b0));
    dffe_ref dx_link_addr_reg[31:0]( .q(dx_link_addr), .d(stall ? 32'b0 : fd_pc_plus_1), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_setx_val_reg[31:0]( .q(dx_setx_val), .d(stall ? 32'b0 : jump_target), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_is_r_type_reg(.q(dx_is_r_type),.d(stall ? 1'b0 : is_r_type),.clk(clk_inverted),.en(front_en &  md_stall),.clr(1'b0));
    dffe_ref dx_is_addi_reg(.q(dx_is_addi), .d(stall ? 1'b0 : is_addi), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_is_lw_reg(.q(dx_is_lw),.d(stall ? 1'b0 : is_lw),.clk(clk_inverted),.en((front_en | stall) & md_stall),.clr(1'b0));
    dffe_ref dx_is_sw_reg(.q(dx_is_sw),.d(stall ? 1'b0 : is_sw),.clk(clk_inverted),.en((front_en | stall) & md_stall),.clr(1'b0));
    dffe_ref dx_is_JR_reg(.q(dx_is_jr),.d(stall ? 1'b0 : is_jr),.clk(clk_inverted),.en((front_en | stall) & md_stall),.clr(1'b0));
    dffe_ref dx_is_jal_reg( .q(dx_is_jal), .d(stall ? 1'b0 : is_jal), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_is_mult_reg( .q(dx_is_mult), .d(stall ? 1'b0 : is_mult_op), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_is_div_reg( .q(dx_is_div), .d(stall ? 1'b0 : is_div_op), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_is_setx_reg( .q(dx_is_setx),.d(stall ? 1'b0 : is_setx), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_set_rstatus_reg(.q(dx_set_rstatus), .d(stall ? 1'b0 : ex_set_rstatus), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_rstatus_code_reg[31:0](.q(dx_rstatus_code), .d(stall ? 32'b0 : ex_rstatus_code), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_is_bne_reg(.q(dx_is_bne), .d(stall ? 1'b0 : is_bne), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_is_blt_reg(.q(dx_is_blt), .d(stall ? 1'b0 : is_blt), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));
    dffe_ref dx_is_bex_reg(.q(dx_is_bex), .d(stall ? 1'b0 : bex_taken), .clk(clk_inverted), .en((front_en | stall) & md_stall), .clr(1'b0));

    wire dx_writes = dx_valid & (dx_is_r_type | dx_is_addi | dx_is_lw) & (dx_rd != 5'b0);

    // MULT/DIV result available in DX when ready
    wire dx_writes_now = dx_valid & (dx_is_r_type | dx_is_addi | dx_is_mult | dx_is_div) & (dx_rd != 5'b0) & (dx_is_mult | dx_is_div ? md_rdy : 1'b1);
    wire [31:0] dx_result_now = (dx_is_mult | dx_is_div) ? md_result : alu_result;

    // DX STAGE R30 Forwarding Logic (includes both SETX and exceptions)
    wire dx_pending_r30;
    assign dx_pending_r30 = dx_valid & (dx_is_setx | ex_set_rstatus);

    wire [31:0] dx_pending_r30_val;
    assign dx_pending_r30_val = dx_is_setx ? dx_setx_val : ex_set_rstatus ? ex_rstatus_code : 32'b0;

// STAGE 3: EXECUTE + Memory Bypass 
    // ALU input MUX 
    wire use_immediate = dx_is_addi | dx_is_lw | dx_is_sw;
    wire xm_reg_write = (xm_is_r_type | xm_is_lw | xm_is_addi | xm_is_mult | xm_is_div) & (xm_rd != 5'b0); 
    wire mw_reg_write = (mw_is_r_type | mw_is_lw | mw_is_addi | mw_is_mult | mw_is_div) & (mw_rd != 5'b0); 
    
    wire [31:0] alu_in_a; 
    assign alu_in_a = ((xm_rd == dx_rs) & xm_reg_write) ? xm_alu_result : ((mw_rd == dx_rs) & mw_reg_write & mw_valid) ? mw_write_data :  dx_rs_value;
    
    wire [31:0] alu_in_b;
    wire [31:0] alu_in_b_no_imm = ((xm_rd == dx_rt) & (xm_reg_write)) ? xm_alu_result : ((mw_rd == dx_rt) & mw_reg_write & mw_valid) ? mw_write_data : dx_rt_value;
    assign alu_in_b = use_immediate ? dx_immediate : alu_in_b_no_imm;

    wire [4:0] store_src_reg = dx_is_sw ? dx_rd : dx_rt;
    wire [31:0] xm_write_data = xm_is_lw ? q_dmem : xm_alu_result;
    wire [31:0] store_data_bypass = ((xm_rd == store_src_reg) & (xm_reg_write)) ? xm_write_data : 
            ((mw_rd == store_src_reg) & mw_reg_write && mw_valid) ? mw_write_data : dx_rt_value;

    // load hazard
    assign stall = (dx_valid & dx_is_lw & ((ctrl_readRegA == dx_rd & fd_reads_rs) | (ctrl_readRegB == dx_rd & fd_reads_rt & ~is_sw))) |
           (xm_valid & (xm_is_lw | xm_is_mult | xm_is_div) & ((ctrl_readRegA  & fd_reads_rs) | (ctrl_readRegB == xm_rd & fd_reads_rt & ~is_sw))) | 
           // Stall for BRANCHES/JUMPS that need values from DX stage
           (dx_valid & (dx_is_r_type | dx_is_addi) & (dx_rd != 5'b0) & ((is_bne | is_blt | is_bex | is_jr | is_jal) & ((ctrl_readRegA == dx_rd) | (ctrl_readRegB == dx_rd)))) |
           // Stall if FD needs MULT/DIV result that's not ready yet
           (dx_valid & (dx_is_mult | dx_is_div) & (dx_rd != 5'b0) & ~md_rdy & ((ctrl_readRegA == dx_rd) | (ctrl_readRegB == dx_rd)) | gcode_stall); 


    // ALU Execution  
    wire [31:0] alu_result;
    wire alu_overflow;
    alu alu_unit(.data_operandA(alu_in_a), .data_operandB(alu_in_b), .ctrl_ALUopcode(dx_is_r_type ? dx_alu_op : 5'b00000), 
        .ctrl_shiftamt(dx_shamt), .data_result(alu_result), .isNotEqual(), .isLessThan(), .overflow(alu_overflow));

// MULT/DIV UNIT 
    wire ex_is_multdiv; 
    assign ex_is_multdiv = dx_is_mult | dx_is_div; //is this MULT or DIV?

    wire [31:0] md_result;  // result from MULT/DIV unit 
    wire md_exc; // Exception from MULT/DIV
    wire md_rdy; // Result Ready? 

    wire start_mult = dx_is_mult & ~m_busy;
    wire start_div = dx_is_div & ~d_busy;

    multdiv multdiv_unit(.data_operandA(dx_rs_value), .data_operandB(dx_rt_value), .ctrl_MULT(start_mult),
        .ctrl_DIV (start_div), .clock(clock), .data_result(md_result), .data_exception(md_exc), .data_resultRDY(md_rdy));

    // wire [31:0] md_result_hold; //hold the md redult across cycles 
    // dffe_ref mdres_ff[31:0] (.q(md_result_hold), .d(md_result), .clk(clock), .en(md_rdy), .clr(reset));

    wire [31:0] ex_result; //final excuted result 
    assign ex_result = ex_is_multdiv ? md_result: alu_result; // Choose MULT/DIV hold or ALU

// EXCEPTION/ OVERFLOW DETECTION 
    wire [31:0] md_exc_now; /* Exception code from MULT/DIV */ 
    assign md_exc_now = dx_is_mult ? 32'd4 : dx_is_div ? 32'd5 : 32'd0; // 4=MULT exception, 5=DIV exception
    wire is_add_ex; 
    assign is_add_ex = dx_is_r_type & (dx_alu_op == 5'b00000);
    wire is_sub_ex; 
    assign is_sub_ex = dx_is_r_type & (dx_alu_op == 5'b00001);
    wire is_addi_ex;
    assign is_addi_ex = dx_is_addi;
    wire set_rstatus_from_alu; /* ALU overflow? */ 
    assign set_rstatus_from_alu = alu_overflow & (is_add_ex | is_sub_ex | is_addi_ex) & dx_valid;
    wire [31:0] rstatus_code_alu; /* Exception code from ALU */
    assign rstatus_code_alu = is_add_ex  ? 32'd1 : is_addi_ex ? 32'd2 : is_sub_ex  ? 32'd3 : 32'd0 ; // 1=ADD overflow, 2=ADDI overflow, 3=SUB overflow
    wire set_rstatus_from_md; /* MULT/DIV exception? */ 
    assign set_rstatus_from_md = md_exc & ex_is_multdiv & dx_valid;
    assign ex_set_rstatus = set_rstatus_from_alu | set_rstatus_from_md;
    assign ex_rstatus_code = set_rstatus_from_md ? md_exc_now : rstatus_code_alu;

//MULT/DIV BUSY logic
    wire m_busy;
    wire d_busy; 
    dffe_ref m_busy_reg(.q(m_busy), .d(dx_is_mult), .clk(clock), .en(1'b1), .clr(reset));
    dffe_ref d_busy_reg(.q(d_busy), .d(dx_is_div), .clk(clock), .en(1'b1), .clr(reset));

    //STALL control
    assign front_en =  ~stall;
    assign xm_en = md_stall | dx_valid; 
    assign md_stall = ~(~md_rdy & (dx_is_mult | dx_is_div));


// EXECUTE -> MEMORY (XM latch) 
    //DATA
    wire [31:0] xm_alu_result; //data 
    wire [31:0] xm_link_addr; // link address for jal (data)
    wire [31:0] xm_setx_val; //setx value for R30
    wire [31:0] xm_rstatus_code; //exception code for R30 
    //CONTROL
    wire [4:0] xm_rd; //dest reg 
    wire xm_is_r_type; 
    wire xm_is_addi;
    wire xm_is_lw;
    wire xm_is_sw;
    wire xm_is_jal;
    wire xm_is_setx;
    wire xm_set_rstatus; //should write to R30? 
    wire xm_is_mult, xm_is_div;
    
    wire xm_valid;  
    dffe_ref xm_valid_reg(.q(xm_valid), .d(dx_valid), .clk(clk_inverted), .en(xm_en), .clr(reset));

    dffe_ref xm_alu_result_reg[31:0](.q(xm_alu_result), .d(ex_result), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_store_data_reg[31:0]( .q(data), .d(store_data_bypass), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_link_addr_reg[31:0]( .q(xm_link_addr), .d(dx_link_addr), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_setx_val_reg[31:0]( .q(xm_setx_val), .d(dx_setx_val), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_rstatus_code_reg[31:0]( .q(xm_rstatus_code), .d(ex_rstatus_code), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_rd_reg[4:0](.q(xm_rd), .d(dx_rd), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_is_r_type_reg(.q(xm_is_r_type),.d(dx_is_r_type),.clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_is_addi_reg( .q(xm_is_addi), .d(dx_is_addi), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_is_lw_reg(.q(xm_is_lw), .d(dx_is_lw), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_is_sw_reg(.q(xm_is_sw), .d(dx_is_sw), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_is_jal_reg(.q(xm_is_jal), .d(dx_is_jal), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_is_setx_reg(.q(xm_is_setx), .d(dx_is_setx), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_set_rstatus_reg( .q(xm_set_rstatus), .d(ex_set_rstatus), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_is_mult_reg (.q(xm_is_mult), .d(dx_is_mult), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref xm_is_div_reg  (.q(xm_is_div ), .d(dx_is_div), .clk(clk_inverted), .en(xm_en), .clr(1'b0));

    wire xm_writes = xm_valid & (xm_is_r_type | xm_is_addi | xm_is_lw | xm_is_mult | xm_is_div); // & (xm_rd != 5'b0);
    wire [31:0] xm_result_data = xm_is_lw ? q_dmem : xm_alu_result;

    // X/M R30 Forwarding Logic (for RSTATUS register)
    wire xm_pending_r30; //XM will write to R30 
    assign xm_pending_r30 = xm_valid & (xm_set_rstatus | xm_is_setx);
    
    wire [31:0] xm_pending_r30_val; //what values will XM write 
    assign xm_pending_r30_val = xm_set_rstatus ? xm_rstatus_code : xm_is_setx ? xm_setx_val : 32'b0;

// STAGE 4: MEMORY  
    assign address_dmem = xm_alu_result;
    assign wren = xm_is_sw & xm_valid;

    //  MEMORY -> WRITEBACK (MW latch) 
    // MW stage R30 
    wire mw_valid;              // Is MW instruction valid?
    dffe_ref mw_valid_reg(.q(mw_valid), .d(xm_valid), .clk(clk_inverted), .en(1'b1), .clr(reset));   
    wire mw_is_setx;            // Is MW doing SETX?
    wire mw_set_rstatus;        // Is MW writing to R30?
    wire [31:0] mw_setx_val;     // Value being set in R30
    wire [31:0] mw_rstatus_code;    // Exception code for R30

    wire mw_pending_r30; // MW is about to write R30
    assign mw_pending_r30 = mw_valid & (mw_set_rstatus | mw_is_setx);

    wire [31:0] mw_pending_r30_val; // What value MW will write
    assign mw_pending_r30_val = mw_set_rstatus ? mw_rstatus_code : mw_is_setx ? mw_setx_val : 32'b0;

    wire pending_r30_valid; // Is there ANY pending R30 write?
    assign pending_r30_valid = dx_pending_r30 | xm_pending_r30 | mw_pending_r30;

    wire [31:0] pending_r30_value;  //which value to forward? 
    assign pending_r30_value = dx_pending_r30 ? dx_pending_r30_val : xm_pending_r30 ? xm_pending_r30_val : mw_pending_r30 ? mw_pending_r30_val : 32'b0;
    
    //Data
    wire [31:0] mw_load_data;
    wire [31:0] mw_alu_result;
    wire [31:0] mw_link_addr;
    //Control 
    wire [4:0]  mw_rd;
    wire mw_is_r_type;
    wire mw_is_addi;
    wire mw_is_lw;
    wire mw_is_sw_dummy; // (not used in WB)
    wire mw_is_jal;
    wire mw_is_mult; 
    wire mw_is_div;

    dffe_ref mw_load_data_reg[31:0]( .q(mw_load_data), .d(q_dmem), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_alu_result_reg[31:0]( .q(mw_alu_result), .d(xm_alu_result), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_link_addr_reg[31:0]( .q(mw_link_addr), .d(xm_link_addr), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_setx_val_reg[31:0]( .q(mw_setx_val), .d(xm_setx_val), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_rstatus_code_reg[31:0]( .q(mw_rstatus_code), .d(xm_rstatus_code), .clk(clk_inverted), .en(xm_en), .clr(1'b0) );
    dffe_ref mw_rd_reg[4:0]( .q(mw_rd), .d(xm_rd), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_is_r_type_reg( .q(mw_is_r_type), .d(xm_is_r_type), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_is_addi_reg(.q(mw_is_addi), .d(xm_is_addi), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_is_lw_reg( .q(mw_is_lw), .d(xm_is_lw), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_is_sw_reg( .q(mw_is_sw_dummy), .d(xm_is_sw), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_is_jal_reg( .q(mw_is_jal), .d(xm_is_jal), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_is_setx_reg( .q(mw_is_setx), .d(xm_is_setx), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_is_mult_reg( .q(mw_is_mult), .d(xm_is_mult), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_is_div_reg( .q(mw_is_div), .d(xm_is_div), .clk(clk_inverted), .en(xm_en), .clr(1'b0));
    dffe_ref mw_set_rstatus_reg( .q(mw_set_rstatus), .d(xm_set_rstatus), .clk(clk_inverted), .en(xm_en), .clr(1'b0));

// STAGE 5: WRITEBACK  
    wire [31:0] jal_link_addr; // PC + 1 - 1 = PC (for JAL)
    alu jal_link_addr_calc( .data_operandA(mw_link_addr), .data_operandB(32'hFFFFFFFF), .ctrl_ALUopcode(5'b00000), .ctrl_shiftamt(5'b00000), .data_result(jal_link_addr), .isNotEqual(), .isLessThan(), .overflow());

    wire [31:0] xm_jal_link_value;
    alu xm_jal_calc(.data_operandA(xm_link_addr), .data_operandB(32'hFFFFFFFF), .ctrl_ALUopcode(5'b00000), .ctrl_shiftamt(5'b00000), .data_result(xm_jal_link_value), .isNotEqual(), .isLessThan(), .overflow());

    wire mw_writes = mw_valid & (mw_is_r_type | mw_is_addi | mw_is_lw | mw_is_mult | mw_is_div) & (mw_rd != 5'b0); 
    wire [31:0] mw_write_data = mw_is_lw ? mw_load_data : mw_alu_result;  
    wire jal_writes = mw_valid & mw_is_jal;

    // If reading R30 and there's a pending write, use forwarded value
    assign readA_value = (ctrl_readRegA == 5'd30 & pending_r30_valid) ? pending_r30_value : 
        (ctrl_readRegA == 5'd31 & jal_writes) ? jal_link_addr :
        (ctrl_readRegA == 5'd31 & xm_valid & xm_is_jal) ? xm_jal_link_value :
        (ctrl_readRegA == 5'd30 & xm_valid & xm_is_setx) ? xm_setx_val :
        ((ctrl_readRegA == mw_rd) & mw_writes) ? mw_write_data :
        ((ctrl_readRegA == xm_rd) & xm_writes) ? xm_result_data : 
        ((ctrl_readRegA == dx_rd) & dx_writes_now) ? dx_result_now : data_readRegA;

    assign readB_value = (ctrl_readRegB == 5'd30 && pending_r30_valid) ? pending_r30_value : 
        (ctrl_readRegB == 5'd31 & jal_writes) ? jal_link_addr :
        (ctrl_readRegB == 5'd31 & xm_valid & xm_is_jal) ? xm_jal_link_value :
        (ctrl_readRegB == 5'd30 & xm_valid & xm_is_setx) ? xm_setx_val :
        ((ctrl_readRegB == mw_rd) & mw_writes) ? mw_write_data :
       ((ctrl_readRegB == xm_rd) & xm_writes) ? xm_result_data : 
        ((ctrl_readRegB == dx_rd) & dx_writes_now) ? dx_result_now : data_readRegB;

    // regfile write decision 
    wire wb_we_base; //should we write to register file? 
    assign wb_we_base = (mw_is_r_type | mw_is_addi | mw_is_lw | mw_is_jal | mw_is_setx | mw_set_rstatus);
    assign ctrl_writeEnable = wb_we_base & mw_valid; // Write only if instruction type allows AND instruction is valid
    assign ctrl_writeReg = mw_set_rstatus ? 5'd30 : mw_is_setx ? 5'd30 : mw_is_jal ? 5'd31 : mw_rd; // Which register to write?
    assign data_writeReg = mw_set_rstatus ? mw_rstatus_code : mw_is_setx ? mw_setx_val : mw_is_jal ? jal_link_addr : mw_is_lw ? mw_load_data : mw_alu_result;
    // What value to write?

endmodule