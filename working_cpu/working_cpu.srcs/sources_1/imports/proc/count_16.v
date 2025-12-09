module count_16(
    input        clock,
    input        enable,
    output [3:0] count,
    input        ctrl     // async reset-to-zero, active-high
);
    wire [3:0] next_count;
    
    
    // Bit 0: toggle on every enable
    wire bit0_next = enable ? ~count[0] : count[0];
    
    // Bit 1: toggle when bit0 is 1 and enable is 1
    wire bit1_enable = enable & count[0];
    wire bit1_next = bit1_enable ? ~count[1] : count[1];
    
    // Bit 2: toggle when bits [1:0] are 11 and enable is 1
    wire bit2_enable = enable & count[0] & count[1];
    wire bit2_next = bit2_enable ? ~count[2] : count[2];
    
    // Bit 3: toggle when bits [2:0] are 111 and enable is 1
    wire bit3_enable = enable & count[0] & count[1] & count[2];
    wire bit3_next = bit3_enable ? ~count[3] : count[3];
    
    assign next_count = {bit3_next, bit2_next, bit1_next, bit0_next};
    
    dffe_ref dff0 (.q(count[0]), .d(bit0_next), .clk(clock), .en(enable), .clr(ctrl));
    dffe_ref dff1 (.q(count[1]), .d(bit1_next), .clk(clock), .en(enable), .clr(ctrl));
    dffe_ref dff2 (.q(count[2]), .d(bit2_next), .clk(clock), .en(enable), .clr(ctrl));
    dffe_ref dff3 (.q(count[3]), .d(bit3_next), .clk(clock), .en(enable), .clr(ctrl));
    
endmodule