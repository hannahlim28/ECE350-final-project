`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/07/2025 12:54:19 PM
// Design Name: 
// Module Name: wrapper_tb2
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns / 1ps

module Wrapper_tb;

    // ----------------------------------------------------
    // Testbench signals
    // ----------------------------------------------------
    reg clk;
    reg reset;
    reg BTNU;
    reg BTNL;
    reg BTNR;
    reg BTND;
    reg switch;

    wire tx;

    // ----------------------------------------------------
    // DUT: your Wrapper with PLL, full assembly, etc.
    // ----------------------------------------------------
    Wrapper dut (
        .clk   (clk),
        .reset (reset),
        .BTNU  (BTNU),
        .BTNL  (BTNL),
        .BTNR  (BTNR),
        .BTND  (BTND),
        .switch (switch),
        .tx    (tx)
    );

    // ----------------------------------------------------
    // 100 MHz clock into PLL
    // ----------------------------------------------------
    initial begin
        clk   = 0;
    end

    always #5 clk = ~clk;   // 100 MHz (10 ns period)

    // ----------------------------------------------------
    // Reset + buttons
    // ----------------------------------------------------
    initial begin
        reset = 1'b0;
        BTNU  = 1'b0;
        BTNL  = 1'b0;
        BTNR  = 1'b0;
        BTND  = 1'b0;
        switch = 1'b1;

        // hold reset long enough for PLL + CPU
        #100000
        BTNU = 1'b1;
        repeat(5) @(posedge clk);          // 200 ns
        BTNU = 1'b0;
        
//        // buttons stay low for now
    end

    // ----------------------------------------------------
    // Simulation time
    // ----------------------------------------------------
    initial begin
        #5_000_000;   // 5 ms of simulation time
        $finish;
    end

endmodule

