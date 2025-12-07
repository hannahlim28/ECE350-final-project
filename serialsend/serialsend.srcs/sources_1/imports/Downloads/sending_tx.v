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
        .BTNU(1'b0), 
        .BTNL(BTNL),
        .BTNR(BTNR),
        .BTND(BTND),
        .tx_ready(!uart_tx_busy && !g_busy),
        .tx_valid(b_valid),
        .tx_data(b_letter)
);
    reg bup, see_bup, prev_bup;
    always @(posedge clk)begin
        bup <= BTNU
    end
    always @(posedge clk)begin
        prev_bup <= bup;
        see_bup <= ~prev_bup & bup;
    end
    always @(posedge clk)begin
        if(see_bup && !g_busy) begin
            xo <= 5;
            xt <= 10;
            yo <= 2;
            yt <= 2;
            intensity <= 2'b11;
        end
    end
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
        .g_send(see_bup),
        .g_busy(g_busy),
        .clk(clk),
        .reset(reset),
        .tx_ready(!uart_tx_busy),
        .tx_valid(g_valid),
        .tx_data(g_letter));
endmodule