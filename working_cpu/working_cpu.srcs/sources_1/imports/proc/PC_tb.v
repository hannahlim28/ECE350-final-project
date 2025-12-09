`timescale 1ns/1ps

module PC_tb; 
    reg clk, reset; 
    wire [31:0] pc_out; 

    PC uut(.clk(clk), .reset(reset), .pc_out(pc_out)); 

    initial begin
        clk = 0; 
        reset = 1; 

        #10 reset = 0; 

        repeat(10) begin 
            #5 clk = 1; 
            #5 clk =0; 
            $display("PC = %d", pc_out); 
        end 
    end 
endmodule
