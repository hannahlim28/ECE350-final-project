module control(
    input  [31:0] instruction,

    output [4:0] rd,
    output [4:0] rs,
    output [4:0] rt,
    output [4:0] shamt,
    output [4:0] alu_op,          // ALU control for R-type ops
    output [31:0] immediate,      // sign-extended imm[16:0]
    output [31:0] target_addr,    // zero-extended target[26:0] (j/jal/bex/setx)

    output is_r_type,
    output is_i_type,     // "non-R format" tag if you still want it
    output is_immediate,  // should EX stage use imm instead of rt?
    output write_enable,  // should this instr write a GPR at WB?
    
    output is_branch,     // any conditional control-flow (bne/blt/bex)
    output is_bne,
    output is_blt,
    output is_bex,

    output is_jump,       // any PC = something (j/jal/jr/bex)
    output is_j,
    output is_jal,
    output is_jr,

    // memory
    output is_memory,     // lw or sw
    output is_load,       // lw
    output is_store,      // sw

    // mult/div
    output is_multdiv,
    output is_mul,
    output is_div,

    output is_setx,       // setx
    output write_status,  // write to $rstatus / $r30 ?
    output write_ra       // write to $r31 ? (jal)
);


    wire [4:0] opcode         = instruction[31:27];
    wire [4:0] alu_op_r_type  = instruction[6:2];
    wire [16:0] imm_raw       = instruction[16:0];
    wire [26:0] tgt_raw       = instruction[26:0];

    assign rd    = instruction[26:22];
    assign rs    = instruction[21:17];
    assign rt    = instruction[16:12];
    assign shamt = instruction[11:7];

    // sign-extend imm[16:0] → 32
    assign immediate   = {{15{imm_raw[16]}}, imm_raw};

    // zero-extend target[26:0] → 32
    assign target_addr = {5'b00000, tgt_raw};

    // R-type: 00000
    assign is_r_type = (opcode == 5'b00000);

    // j   00001
    assign is_j   = (opcode == 5'b00001);

    // bne 00010
    assign is_bne = (opcode == 5'b00010);

    // jal 00011
    assign is_jal = (opcode == 5'b00011);

    // jr  00100
    assign is_jr  = (opcode == 5'b00100);

    // addi 00101
    wire is_addi  = (opcode == 5'b00101);

    // blt  00110
    assign is_blt = (opcode == 5'b00110);

    // sw   00111
    wire is_sw    = (opcode == 5'b00111);

    // lw   01000
    wire is_lw    = (opcode == 5'b01000);

    // setx 10101
    assign is_setx = (opcode == 5'b10101);

    // bex  10110
    assign is_bex  = (opcode == 5'b10110);

    // mul = 00110
    assign is_mul = is_r_type & (alu_op_r_type == 5'b00110);

    // div = 00111
    assign is_div = is_r_type & (alu_op_r_type == 5'b00111);

    assign is_multdiv = is_mul | is_div;

    assign alu_op = is_r_type ? alu_op_r_type : 5'b00000;

    assign is_jump   = is_j | is_jal | is_jr | is_bex;

    assign is_load   = is_lw;
    assign is_store  = is_sw;
    assign is_memory = is_lw | is_sw;

    assign is_immediate = is_addi | is_lw | is_sw;

    assign write_ra = is_jal;
    assign write_status = is_setx;

    assign write_enable = is_r_type | is_addi | is_lw | is_jal | is_setx;
    assign is_i_type = ~is_r_type;

endmodule
