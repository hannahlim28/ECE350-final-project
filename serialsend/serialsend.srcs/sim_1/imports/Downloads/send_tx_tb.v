`timescale 1ns/1ps

module send_tx_tb;
    reg clk, reset, BTNU;
    wire tx, rx;

    sending_tx transmitTest(.clk(clk), .reset(reset), .tx(tx), .BTNU(BTNU));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        BTNU = 0;
        repeat(20) @(posedge clk);
        BTNU = 1;
        repeat (5) @(posedge clk);
        BTNU = 0;
    end
    initial begin
        #1000000000;
        $finish;
    end
    initial begin
        $dumpfile("sending_tx.vcd");
        $dumpvars(0, send_tx_tb);
    end

endmodule