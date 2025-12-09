module PC(
    input clk, 
    input reset, 
    output [31:0] pc_out
); 

    wire [31:0] pc_current;
    wire [31:0] pc_next;
    wire [31:0] carry;

    xor xor0(pc_next[0], pc_current[0], 1'b1);
    and and0(carry[0], pc_current[0], 1'b1);
    
    genvar i;
    generate
        for (i = 1; i < 32; i = i + 1) begin : carry_chain
            xor xor_i(pc_next[i], pc_current[i], carry[i-1]);
            and and_i(carry[i], pc_current[i], carry[i-1]);
        end
    endgenerate

    assign pc_out = pc_current;

endmodule