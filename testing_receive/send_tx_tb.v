`timescale 1ns/1ps
module send_tx_tb;
task uart_rx_char(input [7:0] c);
    integer i;
    localparam BAUD_PRD = 8680;
    begin
        // Start bit
        rx <= 0;
        #(BAUD_PRD);

        // Data bits (LSB first)
        for (i = 0; i < 8; i = i + 1) begin
            rx <= c[i];
            #(BAUD_PRD);
        end

        // Stop bit
        rx <= 1;
        #(BAUD_PRD);
    end
endtask
    reg clk, reset, BTNU, rx, g_send;
    wire tx, done;
    wire [7:0] rx_data;

    sending_tx transmitTest(.clk(clk), .reset(reset), .tx(tx),.rx(rx), .g_send(g_send));

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    initial begin
        rx <= 1; // idle HIGH
        g_send <= 1'b0;
        @(posedge clk);
        g_send <= 1'b1;
        @(posedge clk);
        g_send <= 1'b0;


        // Wait for your system to send its first G-code line...
        repeat(20000) @(posedge clk);

        // Inject OK response ("ok\n")
        uart_rx_char("o");
        uart_rx_char("k");
        uart_rx_char("\n");

        // Wait and inject next OK later
        repeat(20000) @(posedge clk);
        uart_rx_char("o");
        uart_rx_char("k");
        uart_rx_char("\n");

        #1000000;
        $finish;
    end
    initial begin
        $dumpfile("sending_tx.vcd");
        $dumpvars(0, send_tx_tb);
    end

endmodule