`timescale 1ns/1ps

module send_tx_tb;
    reg clk, reset;
    wire tx, rx;

    sending_tx transmitTest(.clk(clk), .reset(reset), .tx(tx));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        #1000000;
        $finish;
    end
    initial begin
        $dumpfile("sending_tx.vcd");
        $dumpvars(0, send_tx_tb);
    end

endmodule