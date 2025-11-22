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
            .uart_tx_en(send), 
            .uart_tx_data(test_byte));

    reg [7:0] test_byte = "H";
    reg send = 0;

    always @(posedge clk) begin
        if (!uart_tx_busy) begin
            send <= 1;
        end else begin
            send <= 0;
        end
    end
    // gcode_sender getting_gcode(.clk(clk),
    //         .reset(reset),
    //         .tx_ready(!uart_tx_busy),
    //         .tx_valid(tx_valid),
    //         .tx_data(test_letter));


endmodule