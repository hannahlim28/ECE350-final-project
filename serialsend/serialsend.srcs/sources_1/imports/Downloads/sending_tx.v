module sending_tx(
    input wire clk,
    input wire reset,
    input wire BTNU,
    input wire BTNL,
    input wire BTNR,
    input wire BTND,
    output wire tx
);
    wire uart_tx_busy;
    wire tx_valid, button_valid, g_valid;
    wire baud_clk;
    reg [31:0] xo, xt,yo,yt;
    reg [1:0] intensity;
    reg g_send = 0;

    wire g_busy, b_busy;

    wire[7:0] test_letter, g_letter, b_letter;
    
    assign tx_valid = (g_busy) ? g_valid : b_valid;
    assign test_letter = (g_busy) ? g_letter : b_letter;
    
    button_send sending_button(
        .clk(clk),
        .reset(reset),
        .BTNU(BTNU), 
        .BTNL(BTNL),
        .BTNR(BTNR),
        .BTND(BTND),
        .tx_ready(!uart_tx_busy && !g_busy),
        .tx_valid(b_valid),
        .tx_data(b_letter)
);


    uart_transmit uut(
        .clk(clk), 
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
        .tx_valid(g_valid),
        .tx_data(g_letter));
endmodule