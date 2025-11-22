module sending_tx(
    input wire clk,
    input wire reset,
    output wire tx
);

    wire uart_tx_busy;
    wire tx_valid;
    
    wire[7:0] test_letter;

    uart_tx transmitter(.clk(clk), 
            .resetn(~reset), 
            .uart_txd(tx), 
            .uart_tx_busy(uart_tx_busy), 
            .uart_tx_en(tx_valid), 
            .uart_tx_data(test_letter));

    gcode_sender getting_gcode(.clk(clk),
            .reset(reset),
            .tx_ready(!uart_tx_busy),
            .tx_valid(tx_valid),
            .tx_data(test_letter));


endmodule