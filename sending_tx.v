module sending_tx(
    input wire clk,
    input wire reset,
    output wire tx,
    output wire ledone,
    output wire ledtwo
);
    assign ledone = reset;
    assign ledtwo = clk;
    wire uart_tx_busy;
    wire tx_valid;
    wire baud_clk;
    // reg [7:0] test_byte = "H";
    // reg send = 0;
    wire[7:0] test_letter;

    uart_transmit uut(.clk(clk), 
            .reset(reset), 
            .tx_send(tx), 
            .tx_busy(uart_tx_busy), 
            .tx_start(tx_valid), 
            .tx_data(test_letter));

    // always @(posedge clk) begin
    //     if (!uart_tx_busy) begin
    //         send <= 1;
    //     end else begin
    //         send <= 0;
    //     end
    // end
    gcode_sender getting_gcode(.clk(clk), 
            .reset(reset),
            .tx_ready(!uart_tx_busy),
            .tx_valid(tx_valid),
            .tx_data(test_letter));
endmodule