`timescale 1ns/1ps

module send_tx_tb;
    reg clk, reset, BTNU, BTNR, BTNL, BTND;
    wire tx, rx;

    sending_tx transmitTest(.clk(clk), .reset(reset), .tx(tx), .BTNU(BTNU), .BTNL(BTNL), .BTNR(BTNR), .BTND(BTND));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        BTNU = 0;
        BTNL = 0;
        BTNR = 0;
        BTND = 0;
        reset = 0;
        repeat(20) @(posedge clk);
        reset = 1;
        repeat(5) @(posedge clk);
        reset = 0;

    end
    initial begin
        #10000000;
        $finish;
    end
    initial begin
        $dumpfile("sending_tx.vcd");
        $dumpvars(0, send_tx_tb);
    end

endmodule