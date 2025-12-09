`timescale 1ns/1ps

module send_tx_tb;
    reg clk, reset, BTNU;
    wire tx, done;
    wire [7:0] rx_data;

    sending_tx transmitTest(.clk(clk), .reset(reset), .tx(tx), .BTNU(BTNU));
    uart_receive receiveTest(.clk(clk), .reset(reset), .rx(tx), .rx_done(done), .rx_data(rx_data));

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
        #1000000;
        $finish;
    end
    initial begin
        $dumpfile("sending_tx.vcd");
        $dumpvars(0, send_tx_tb);
    end

endmodule