module sending_tx(
    input wire clk,
    input wire reset,
    input wire BTNU,
    output wire tx
);

    wire uart_tx_busy;
    wire tx_valid;
    wire baud_clk;
    reg [31:0] xo, xt, yo, yt;
    reg [1:0] intensity;
    reg g_send;
    wire g_busy;

    wire[7:0] test_letter;
    reg bup;
    always @(posedge clk) begin
        bup = BTNU;
    end
    always @(posedge bup) begin
        if(!g_busy)begin
            xo = 0;
            xt = 0;
            yo = 0;
            yt = 10;
            intensity = 0;
            g_send <=0;
        end
    end

    uart_transmit uut(.clk(clk), 
            .reset(reset), 
            .tx_send(tx), 
            .tx_busy(uart_tx_busy), 
            .tx_start(tx_valid), 
            .tx_data(test_letter));

    gcode_sender getting_gcode(
        .xo(xo),
        .xt(xt),
        .yo(yo),
        .yt(yt),
        .intensity(intensity),
        .g_send(g_send),
        .g_busy(g_busy),
        .clk(clk),
        .reset(reset),
        .tx_ready(!uart_tx_busy),
        .tx_valid(tx_valid),
        .tx_data(test_letter));
endmodule